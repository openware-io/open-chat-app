import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/call_surface_ready.dart';
import '../core/gv_toast.dart';
import '../l10n/app_localizations.dart';
import '../providers/call_provider.dart';
import '../widgets/gv_avatar.dart';
import '../widgets/gv_rtc_video_view.dart';

class CallScreen extends StatefulWidget {
  const CallScreen({super.key, this.answerIncoming = false});

  /// Only an explicit tap on the in-app Answer button sets this. Opening a
  /// push notification or restoring a route is not consent to answer a call.
  final bool answerIncoming;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  /// [dispose] 时勿再依赖失效的 context；缓存 Provider 以解除监听并把仍在
  /// 进行的通话切换为最小化状态。
  CallProvider? _call;

  late final RTCVideoRenderer _local;
  late final RTCVideoRenderer _remote;
  String? _mediaError;
  bool _muted = false;
  bool _camOff = false;
  Timer? _timeout;
  int _appliedRemoteEpoch = -1;
  bool _exitScheduled = false;
  bool _answerInProgress = false;
  late final Future<void> _renderersReady;

  /// 远端绑定串行化，避免并发 await setSrcObject 时 epoch 交错导致黑屏。
  Future<void> _remoteBindChain = Future<void>.value();

  @override
  void initState() {
    super.initState();
    _local = RTCVideoRenderer();
    _remote = RTCVideoRenderer();
    _renderersReady = _initializeRenderers();
    _bootstrap();
  }

  Future<void> _initializeRenderers() async {
    await _local.initialize();
    await _remote.initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _call ??= context.read<CallProvider>();
  }

  Future<void> _bootstrap() async {
    await _renderersReady;
    void onVideoFrame() {
      if (mounted) setState(() {});
    }

    _remote.onFirstFrameRendered = onVideoFrame;
    _local.onFirstFrameRendered = onVideoFrame;
    if (!mounted) return;
    final call = context.read<CallProvider>();
    if (call.isIncoming) {
      call.suppressIncomingCallBanner(stopRingtone: false);
    }
    call.restoreCall();
    call.addListener(_sync);
    _sync();

    if (!call.inCall) {
      _exit();
      return;
    }

    if (call.isOutgoing && call.localStream == null) {
      await waitForCallSurfacePipelineReady();
      final outcome = await call.initMedia();
      if (!mounted) return;
      if (outcome != CallInitMediaOutcome.success) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _mediaError = switch (outcome) {
            CallInitMediaOutcome.signalingDisconnected =>
              l10n.callErrorSocketForCall,
            _ => l10n.callErrorMediaPermission,
          };
        });
        return;
      }
    } else if (call.isIncoming && widget.answerIncoming) {
      await _answerIncomingCall();
    }
  }

  Future<void> _answerIncomingCall() async {
    final call = context.read<CallProvider>();
    if (!call.isIncoming || _answerInProgress) return;
    final callId = call.callId;
    setState(() {
      _answerInProgress = true;
      _mediaError = null;
    });
    try {
      // Web media access must remain inside the explicit user gesture.
      if (kIsWeb) {
        final outcome = await call.prepareWebLocalMediaInUserGesture();
        if (outcome != CallInitMediaOutcome.success) {
          if (call.callId == callId && call.isIncoming) await call.rejectCall();
          return;
        }
      }
      await _renderersReady;
      await waitForCallSurfacePipelineReady();
      if (!mounted || call.callId != callId || !call.isIncoming) return;
      await call.acceptCall();
    } catch (e, st) {
      debugPrint('CallScreen acceptCall failed: $e\n$st');
      if (mounted) {
        setState(() =>
            _mediaError = AppLocalizations.of(context)!.callErrorAcceptFailed);
      }
    } finally {
      if (mounted) setState(() => _answerInProgress = false);
    }
  }

  void _syncConnectionTimeout(CallProvider call) {
    // Waiting for the user to answer is not a connection attempt.
    if (call.status != 'ringing' && call.status != 'connecting') {
      _timeout?.cancel();
      _timeout = null;
      return;
    }
    if (_timeout != null) return;
    _timeout = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      final c = context.read<CallProvider>();
      if (c.status != 'connected') {
        final l10n = AppLocalizations.of(context)!;
        setState(() => _mediaError ??= l10n.callErrorTimeout);
      }
    });
  }

  void _sync() {
    final call = context.read<CallProvider>();
    _syncConnectionTimeout(call);
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        call.isSystemPictureInPicture) {
      _local.srcObject = null;
      _remote.srcObject = null;
      _appliedRemoteEpoch = -1;
      if (!call.isMinimized) {
        _finishMinimize(call);
      }
      setState(() {});
      return;
    }
    unawaited(_bindLocalVideo(call));

    _enqueueRemoteBind();

    if (call.status == 'idle') {
      _exit();
      return;
    }
    setState(() {});
  }

  Future<void> _bindLocalVideo(CallProvider call) async {
    final stream = call.localStream;
    if (stream == null) {
      _local.srcObject = null;
      return;
    }
    if (call.mediaType != 'video') {
      _local.srcObject = stream;
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      _local.srcObject = stream;
      if (mounted) setState(() {});
      return;
    }
    final vids = stream.getVideoTracks();
    if (vids.isEmpty) {
      _local.srcObject = stream;
      return;
    }
    final tid = vids.first.id;
    if (tid != null && tid.isNotEmpty) {
      try {
        await _local.setSrcObject(stream: stream, trackId: tid);
      } catch (e) {
        debugPrint('CallScreen local setSrcObject fallback: $e');
        _local.srcObject = stream;
      }
    } else {
      _local.srcObject = stream;
    }
    if (mounted) setState(() {});
  }

  /// 与 [CallProvider] 一致：getVideoTracks 偶发滞后时用 getTracks(kind==video) 兜底。
  List<MediaStreamTrack> _remoteVideoTracks(MediaStream rs) {
    final v = rs.getVideoTracks();
    if (v.isNotEmpty) return v;
    return rs
        .getTracks()
        .where((t) => (t.kind ?? '').toLowerCase() == 'video')
        .toList();
  }

  void _enqueueRemoteBind() {
    _remoteBindChain = _remoteBindChain.then((_) async {
      if (!mounted) return;
      await _bindRemoteVideoSerialized();
    }).catchError((Object e, StackTrace st) {
      debugPrint('CallScreen remote bind chain: $e\n$st');
    });
  }

  /// 使用 setSrcObject(trackId: 视频轨 id)，避免 Android 上多轨流未选中视频轨导致黑屏。
  /// 必须串行：禁止多处 unawaited 并发，否则 await 期间 epoch 变化会产生过期绑定覆盖新轨道。
  Future<void> _bindRemoteVideoSerialized() async {
    while (mounted) {
      final call = context.read<CallProvider>();
      final rs = call.remoteStream;
      final ep = call.remoteStreamEpoch;

      if (rs == null) {
        _remote.srcObject = null;
        _appliedRemoteEpoch = -1;
        return;
      }

      if (ep == _appliedRemoteEpoch) {
        return;
      }

      _remote.srcObject = null;
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;

      if (context.read<CallProvider>().remoteStreamEpoch != ep) {
        continue;
      }

      final latest = context.read<CallProvider>().remoteStream;
      if (latest == null) return;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        _remote.srcObject = latest;
        _appliedRemoteEpoch = ep;
        if (mounted) setState(() {});
        return;
      }

      final vids = _remoteVideoTracks(latest);
      // 视频通话但尚未收到视频轨：仍绑定流，否则 WebRTC 远端音频不会出声。
      // Android：不要把「仅含音频轨」的流绑给视频 Texture。部分机型上后续 addTrack 视频后
      // Renderer 不刷新，表现为间歇性远端黑屏（尤其 iOS 主叫 → Android 被叫、音频轨常先到）。
      if (call.mediaType == 'video' && vids.isEmpty) {
        if (defaultTargetPlatform == TargetPlatform.android) {
          _remote.srcObject = null;
          // 不写 _appliedRemoteEpoch：Provider 可能在视频轨 add 完成前就先递增 epoch，
          // 若此处把 applied 锁在同一 ep 上，视频加入后 notify 会因 ep==applied 直接跳过 → 永久黑屏。
        } else {
          _remote.srcObject = latest;
          _appliedRemoteEpoch = ep;
        }
        if (mounted) setState(() {});
        return;
      }

      try {
        if (vids.isNotEmpty) {
          final tid = vids.first.id;
          // 单路远端视频：与 iOS 一致整流绑定，避免部分 MTK/Android 上 setSrcObject(trackId) 已返回但纹理永不 renderVideo。
          if (vids.length == 1) {
            _remote.srcObject = latest;
          } else if (tid != null && tid.isNotEmpty) {
            await _remote.setSrcObject(stream: latest, trackId: tid);
          } else {
            _remote.srcObject = latest;
          }
        } else {
          _remote.srcObject = latest;
        }
      } catch (e) {
        debugPrint(
            'CallScreen remote bind setSrcObject failed, use srcObject: $e');
        _remote.srcObject = latest;
      }

      if (!mounted) return;
      if (context.read<CallProvider>().remoteStreamEpoch != ep) {
        continue;
      }

      _appliedRemoteEpoch = ep;
      if (mounted) setState(() {});
      return;
    }
  }

  void _exit() {
    if (_exitScheduled) return;
    _exitScheduled = true;
    _timeout?.cancel();
    final call = context.read<CallProvider>();
    call.removeListener(_sync);
    final loc = call.takeReturnAfterCallLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.of(context);
      // 资料页 / 聊天室等用 push('/call') 进入时，必须 pop 才能保留底层返回栈。
      // 若用 go(returnLocation) 会整栈替换，资料页顶栏返回会失效（canPop 恒为 false）。
      if (router.canPop()) {
        router.pop();
        return;
      }
      if (loc != null && loc.isNotEmpty) {
        router.go(loc);
        return;
      }
      router.go('/chats');
    });
  }

  Future<void> _minimize(CallProvider call) async {
    if (_exitScheduled || !call.inCall) return;
    _exitScheduled = true;
    _timeout?.cancel();
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        call.mediaType == 'video') {
      await call.enterSystemPictureInPicture();
    }
    _finishMinimize(call, alreadyScheduled: true);
  }

  void _finishMinimize(
    CallProvider call, {
    bool alreadyScheduled = false,
  }) {
    if (!alreadyScheduled) {
      if (_exitScheduled || !call.inCall) return;
      _exitScheduled = true;
      _timeout?.cancel();
    }
    call.minimizeCall();
    call.removeListener(_sync);
    final loc = call.returnAfterCallLocation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else if (loc != null && loc.isNotEmpty) {
        router.go(loc);
      } else {
        router.go('/chats');
      }
      call.requestSystemOverlayPermission();
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    final call = _call;
    if (call != null) {
      call.removeListener(_sync);
      if (call.inCall && !call.isMinimized) call.minimizeCall();
    } else {
      try {
        final c = context.read<CallProvider>();
        c.removeListener(_sync);
        if (c.inCall && !c.isMinimized) c.minimizeCall();
      } catch (_) {}
    }
    _local.dispose();
    _remote.dispose();
    super.dispose();
  }

  String _statusText(CallProvider call, AppLocalizations l10n) {
    switch (call.status) {
      case 'ringing':
        return call.isOutgoing
            ? l10n.callStatusWaitingForAnswer
            : l10n.callStatusRinging;
      case 'incoming':
        if (widget.answerIncoming || _answerInProgress) {
          return l10n.callStatusConnecting;
        }
        final type = call.mediaType == 'video'
            ? l10n.contactVideoCall
            : l10n.contactVoiceCall;
        return '$type · ${l10n.callStatusIncoming}';
      case 'connecting':
        return l10n.callStatusConnecting;
      case 'connected':
        return l10n.callStatusInCall;
      case 'failed':
        return l10n.callErrorTimeout;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final call = context.watch<CallProvider>();
    final l10n = AppLocalizations.of(context)!;
    final isVideo = call.mediaType == 'video';
    final showRemoteVideo = isVideo &&
        call.status == 'connected' &&
        call.remoteStream != null &&
        _remote.renderVideo;
    // Audio calls keep the remote avatar, name, and status visible. Only hide
    // those overlays once a video call is actually rendering the remote frame.
    final hideRemoteVideoDetails = showRemoteVideo;

    final callSurface = Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(call, showRemoteVideo: showRemoteVideo),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compactHeight = constraints.maxHeight < 620;
                final profileTop =
                    compactHeight ? GvSpacing.lg : constraints.maxHeight * 0.18;
                final statusBottom = isVideo
                    ? (compactHeight ? 214.0 : 260.0)
                    : (compactHeight ? 132.0 : 174.0);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!call.isIncoming)
                      Positioned(
                        top: GvSpacing.sm,
                        left: GvSpacing.sm,
                        child: _buildMinimizeButton(call, l10n),
                      ),
                    if (!hideRemoteVideoDetails)
                      Positioned(
                        top: profileTop,
                        left: GvSpacing.lg,
                        right: GvSpacing.lg,
                        child: _buildRemoteIdentity(
                          call,
                          l10n,
                          compact: compactHeight,
                        ),
                      ),
                    if (!hideRemoteVideoDetails || _mediaError != null)
                      Positioned(
                        left: GvSpacing.lg,
                        right: GvSpacing.lg,
                        bottom: statusBottom,
                        child: _buildStatus(call, l10n),
                      ),
                    Positioned(
                      left: GvSpacing.page,
                      right: GvSpacing.page,
                      bottom: GvSpacing.lg,
                      child: _buildControls(call, l10n),
                    ),
                    if (showRemoteVideo && call.localStream != null)
                      Positioned(
                        top: GvSpacing.lg,
                        right: GvSpacing.lg,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(GvRadii.button),
                          child: SizedBox(
                            width: 92,
                            height: 128,
                            child: GvRtcVideoView(
                              renderer: _local,
                              mirror: call.localCameraFacingFront,
                              objectFit: RTCVideoViewObjectFit
                                  .RTCVideoViewObjectFitCover,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );

    return PopScope(
      // 系统返回键与侧滑返回都必须先把通话切为最小化；否则路由先被移除，
      // 全局悬浮窗可能收不到稳定的状态变更，用户也就无法恢复通话页面。
      canPop: !call.inCall || call.isMinimized,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && call.inCall) _minimize(call);
      },
      child: callSurface,
    );
  }

  Widget _buildBackground(
    CallProvider call, {
    required bool showRemoteVideo,
  }) {
    if (call.mediaType == 'video') {
      final renderer = showRemoteVideo ? _remote : _local;
      final hasVideo = showRemoteVideo || call.localStream != null;
      return Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF343434), Color(0xFF111111)],
              ),
            ),
          ),
          if (hasVideo)
            Positioned.fill(
              key: ValueKey<int>(call.rtcSurfaceSession),
              child: GvRtcVideoView(
                renderer: renderer,
                mirror: !showRemoteVideo && call.localCameraFacingFront,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                filterQuality: FilterQuality.medium,
              ),
            ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0x73000000)],
                  stops: [0.35, 1],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final backgroundSize = MediaQuery.sizeOf(context).longestSide * 1.25;
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Center(
              child: GvAvatar(
                name: call.remoteUsername ?? '',
                uid: call.remoteUserId ?? 0,
                src: call.remoteAvatar,
                size: backgroundSize,
                square: true,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB3000000), Color(0xE6000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemoteIdentity(
    CallProvider call,
    AppLocalizations l10n, {
    required bool compact,
  }) {
    final name = call.remoteUsername ?? l10n.callScreenUnknownRemote;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GvAvatar(
          name: call.remoteUsername ?? '',
          uid: call.remoteUserId ?? 0,
          src: call.remoteAvatar,
          size: compact ? 76 : 96,
          square: true,
        ),
        SizedBox(height: compact ? GvSpacing.sm : GvSpacing.lg),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: GvTypography.headline(Colors.white).copyWith(
            fontSize: compact ? GvTypographyScale.title : 28,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatus(CallProvider call, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _statusText(call, l10n),
          textAlign: TextAlign.center,
          style: GvTypography.title(
            Colors.white.withValues(alpha: 0.58),
          ).copyWith(fontWeight: FontWeight.w400),
        ),
        if (_mediaError != null) ...[
          const SizedBox(height: GvSpacing.lg),
          Text(
            _mediaError!,
            textAlign: TextAlign.center,
            style: GvTypography.bodySmall(Colors.white70),
          ),
          const SizedBox(height: GvSpacing.sm),
          OutlinedButton(
            onPressed: () {
              unawaited(call.hangup());
              _exit();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            child: Text(l10n.callActionBack),
          ),
        ],
      ],
    );
  }

  Widget _buildMinimizeButton(
    CallProvider call,
    AppLocalizations l10n,
  ) {
    return Semantics(
      button: true,
      label: l10n.callActionMinimize,
      child: Material(
        color: Colors.black.withValues(alpha: 0.30),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: () => _minimize(call),
          tooltip: l10n.callActionMinimize,
          icon: const Icon(
            Icons.picture_in_picture_alt_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildControls(CallProvider call, AppLocalizations l10n) {
    if (call.isIncoming && !widget.answerIncoming && !_answerInProgress) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _incomingAction(
            icon: Icons.call_end,
            label: l10n.callActionReject,
            color: const Color(0xFFFF3B30),
            onTap: () => call.rejectCall(),
          ),
          _incomingAction(
            icon: call.mediaType == 'video' ? Icons.videocam : Icons.call,
            label: l10n.callActionAnswer,
            color: const Color(0xFF34C759),
            onTap: _answerInProgress ? null : _answerIncomingCall,
          ),
        ],
      );
    }
    final canControlMedia = call.localStream != null;
    final hangupLabel = call.isOutgoing && call.status != 'connected'
        ? l10n.callActionCancel
        : l10n.callActionHangUp;
    final micButton = _callActionButton(
      icon: _muted ? Icons.mic_off : Icons.mic,
      label:
          _muted ? l10n.callActionMicrophoneOff : l10n.callActionMicrophoneOn,
      enabled: !_muted,
      onTap: canControlMedia
          ? () async {
              final v = await call.toggleMute();
              if (v != null && mounted) setState(() => _muted = !v);
            }
          : null,
    );
    final speakerButton = _callActionButton(
      icon: call.speakerOn ? Icons.volume_up : Icons.volume_off,
      label:
          call.speakerOn ? l10n.callActionSpeakerOn : l10n.callActionSpeakerOff,
      enabled: call.speakerOn,
      onTap: canControlMedia && !kIsWeb
          ? () async {
              await call.toggleSpeaker();
            }
          : null,
    );

    if (call.mediaType != 'video') {
      return Row(
        children: [
          Expanded(child: micButton),
          Expanded(
            child: _callActionButton(
              icon: Icons.call_end,
              label: hangupLabel,
              danger: true,
              onTap: () => _hangUp(call),
            ),
          ),
          Expanded(child: speakerButton),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: micButton),
            Expanded(child: speakerButton),
            Expanded(
              child: _callActionButton(
                icon: _camOff ? Icons.videocam_off : Icons.videocam,
                label: _camOff
                    ? l10n.callActionCameraDisabled
                    : l10n.callActionCameraEnabled,
                enabled: !_camOff,
                onTap: canControlMedia
                    ? () async {
                        final v = await call.toggleCamera();
                        if (v != null && mounted) {
                          setState(() => _camOff = !v);
                        }
                      }
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
                child: _buildBackgroundBlurButton(call, l10n, canControlMedia)),
            Expanded(
              child: _callActionButton(
                icon: Icons.call_end,
                label: hangupLabel,
                danger: true,
                showLabel: false,
                onTap: () => _hangUp(call),
              ),
            ),
            Expanded(
              child: kIsWeb
                  ? const SizedBox()
                  : _compactActionButton(
                      icon: Icons.cameraswitch,
                      tooltip: l10n.callActionSwitchCamera,
                      onTap: canControlMedia
                          ? () async {
                              await call.switchCameraFacing();
                            }
                          : null,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBackgroundBlurButton(
    CallProvider call,
    AppLocalizations l10n,
    bool canControlMedia,
  ) {
    if (call.usesSystemVideoEffects) {
      return _compactActionButton(
        icon: Icons.blur_on,
        tooltip: l10n.callActionBackgroundBlurSettings,
        onTap: canControlMedia
            ? () async {
                final opened = await call.showSystemVideoEffects();
                if (!opened && mounted) {
                  GvToast.show(
                    context,
                    l10n.callErrorBackgroundBlurUnavailable,
                  );
                }
              }
            : null,
      );
    }

    return _compactActionButton(
      icon: Icons.blur_on,
      tooltip: call.backgroundBlurEnabled
          ? l10n.callActionBackgroundBlurEnabled
          : l10n.callActionBackgroundBlurDisabled,
      active: call.backgroundBlurEnabled,
      onTap: canControlMedia &&
              call.backgroundBlurSupported &&
              !call.backgroundBlurChanging
          ? () async {
              final applied = await call.toggleBackgroundBlur();
              if (!applied && mounted) {
                GvToast.show(
                  context,
                  l10n.callErrorBackgroundBlurUnavailable,
                );
              }
            }
          : null,
    );
  }

  Future<void> _hangUp(CallProvider call) async {
    await call.hangup();
    if (mounted) _exit();
  }

  Widget _incomingAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: label,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: ValueKey(icon == Icons.call_end
                  ? 'incoming-decline'
                  : 'incoming-answer'),
              onTap: onTap,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Icon(icon, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      ],
    );
  }

  Widget _callActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool enabled = false,
    bool danger = false,
    bool showLabel = true,
  }) {
    final backgroundColor = danger
        ? const Color(0xFFE54B4B)
        : enabled
            ? Colors.white
            : Colors.black.withValues(alpha: 0.28);
    final foregroundColor = enabled && !danger ? Colors.black : Colors.white;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: backgroundColor,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkResponse(
              onTap: onTap,
              radius: 38,
              child: SizedBox.square(
                dimension: 72,
                child: Icon(icon, color: foregroundColor, size: 32),
              ),
            ),
          ),
          if (showLabel) ...[
            const SizedBox(height: GvSpacing.sm),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GvTypography.caption(Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _compactActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    bool active = false,
  }) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: tooltip,
      child: Material(
        color: active ? Colors.white : Colors.transparent,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          icon: Icon(
            icon,
            color: onTap == null
                ? Colors.white38
                : active
                    ? Colors.black
                    : Colors.white,
            size: 34,
          ),
        ),
      ),
    );
  }
}
