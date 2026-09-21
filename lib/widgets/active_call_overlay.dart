import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../l10n/app_localizations.dart';
import '../providers/call_provider.dart';
import 'gv_avatar.dart';
import 'gv_rtc_video_view.dart';

const Size _videoOverlaySize = Size(112, 156);
const Size _audioOverlaySize = Size(72, 88);

/// App-owned active-call surface shown after the full-screen call route is
/// minimized. It deliberately reuses [CallProvider]'s existing media streams;
/// restoring the route never creates a second WebRTC call.
class ActiveCallOverlay extends StatefulWidget {
  const ActiveCallOverlay({super.key, required this.router});

  final GoRouter router;

  @override
  State<ActiveCallOverlay> createState() => _ActiveCallOverlayState();
}

class _ActiveCallOverlayState extends State<ActiveCallOverlay> {
  late final RTCVideoRenderer _renderer;
  CallProvider? _call;
  bool _rendererReady = false;
  MediaStream? _boundStream;
  int _boundRemoteEpoch = -1;
  int _handledFullSurfaceRequestEpoch = 0;
  Offset? _position;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _renderer = RTCVideoRenderer();
    unawaited(_initializeRenderer());
  }

  Future<void> _initializeRenderer() async {
    try {
      await _renderer.initialize();
      if (!mounted) return;
      _rendererReady = true;
      _renderer.onFirstFrameRendered = () {
        if (mounted) setState(() {});
      };
      await _syncRenderer();
    } catch (error, stackTrace) {
      debugPrint('ActiveCallOverlay renderer initialize: $error\n$stackTrace');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final call = context.read<CallProvider>();
    if (identical(call, _call)) return;
    _call?.removeListener(_onCallChanged);
    _call = call;
    _handledFullSurfaceRequestEpoch = call.fullSurfaceRequestEpoch;
    call.addListener(_onCallChanged);
    _onCallChanged();
  }

  void _onCallChanged() {
    final call = _call;
    if (call == null) return;
    _syncElapsedTimer(call);
    unawaited(_syncRenderer());
    if (call.fullSurfaceRequestEpoch != _handledFullSurfaceRequestEpoch) {
      _handledFullSurfaceRequestEpoch = call.fullSurfaceRequestEpoch;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && call.inCall && call.isMinimized) {
          _restoreFullCall(call);
        }
      });
    }
    if (mounted) setState(() {});
  }

  void _syncElapsedTimer(CallProvider call) {
    final shouldTick = call.showMinimizedCall && call.mediaType == 'audio';
    if (shouldTick && _elapsedTimer == null) {
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else if (!shouldTick && _elapsedTimer != null) {
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
    }
  }

  Future<void> _syncRenderer() async {
    if (!_rendererReady) return;
    final call = _call;
    final nativeIosPictureInPicture = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        call?.isSystemPictureInPicture == true;
    if (call == null ||
        !call.isMinimized ||
        call.mediaType != 'video' ||
        nativeIosPictureInPicture) {
      if (_boundStream != null) {
        _renderer.srcObject = null;
        _boundStream = null;
        _boundRemoteEpoch = -1;
      }
      return;
    }
    final stream = call.remoteStream ?? call.localStream;
    final epoch = call.remoteStream == null ? -1 : call.remoteStreamEpoch;
    if (identical(stream, _boundStream) && epoch == _boundRemoteEpoch) return;
    _renderer.srcObject = stream;
    _boundStream = stream;
    _boundRemoteEpoch = epoch;
    if (mounted) setState(() {});
  }

  void _restoreFullCall(CallProvider call) {
    if (!call.inCall) return;
    widget.router.push(AppRoutes.call);
    call.restoreCall();
  }

  Offset _clampPosition(Offset candidate, Size viewport, Size overlaySize) {
    final safeTop = MediaQuery.viewPaddingOf(context).top + GvSpacing.sm;
    final maxX = (viewport.width - overlaySize.width - GvSpacing.sm)
        .clamp(GvSpacing.sm, double.infinity);
    final maxY = (viewport.height -
            overlaySize.height -
            MediaQuery.viewPaddingOf(context).bottom -
            GvSpacing.sm)
        .clamp(safeTop, double.infinity);
    return Offset(
      candidate.dx.clamp(GvSpacing.sm, maxX),
      candidate.dy.clamp(safeTop, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final call = _call;
    if (call == null || !call.showMinimizedCall) {
      return const SizedBox.shrink();
    }
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        call.isSystemPictureInPicture) {
      return const SizedBox.shrink();
    }
    // 全屏通话页进入系统 PiP 时继续复用 CallScreen 的 renderer，避免同一
    // WebRTC 流同时向两个 SurfaceProducer 送帧。只有本来就在 App 内小窗
    // 状态时，才由全局 overlay 承载系统 PiP。
    if (call.isSystemPictureInPicture && !call.isMinimized) {
      return const SizedBox.shrink();
    }
    if (call.isSystemPictureInPicture) {
      // iOS PiP is rendered by AVKit in its own system window. Rendering the
      // Android capture surface here as well would cover the underlying chat
      // with a second full-screen copy of the remote video.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return const SizedBox.shrink();
      }
      return Positioned.fill(child: _buildPictureInPictureSurface(call));
    }

    final viewport = MediaQuery.sizeOf(context);
    final video = call.mediaType == 'video';
    final overlaySize = video ? _videoOverlaySize : _audioOverlaySize;
    final initial = Offset(
      viewport.width - overlaySize.width - GvSpacing.page,
      MediaQuery.viewPaddingOf(context).top + GvSpacing.lg,
    );
    final position =
        _clampPosition(_position ?? initial, viewport, overlaySize);
    final l10n = AppLocalizations.of(context)!;

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: overlaySize.width,
      height: overlaySize.height,
      child: Semantics(
        button: true,
        label: l10n.callActionReturnToCall,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _restoreFullCall(call),
          onPanUpdate: (details) {
            setState(() {
              _position = _clampPosition(
                position + details.delta,
                viewport,
                overlaySize,
              );
            });
          },
          child: Material(
            color: video ? Colors.black : Colors.transparent,
            elevation: video ? GvSpacing.sm : 0,
            borderRadius: BorderRadius.circular(
              video ? GvRadii.card : _audioOverlaySize.width / 2,
            ),
            clipBehavior: video ? Clip.antiAlias : Clip.none,
            child: video ? _buildVideo(call, cover: true) : _buildAudio(call),
          ),
        ),
      ),
    );
  }

  Widget _buildPictureInPictureSurface(CallProvider call) {
    return ColoredBox(
      color: Colors.black,
      child: _buildVideo(call, cover: true),
    );
  }

  Widget _buildVideo(CallProvider call, {required bool cover}) {
    final hasVideo = _boundStream != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasVideo)
          GvRtcVideoView(
            renderer: _renderer,
            mirror: call.remoteStream == null && call.localCameraFacingFront,
            objectFit: cover
                ? RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                : RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
          )
        else
          _buildAvatar(call),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Color(0x66000000)],
            ),
          ),
        ),
        const Positioned(
          left: GvSpacing.sm,
          bottom: GvSpacing.sm,
          child: Icon(Icons.videocam, color: Colors.white, size: 18),
        ),
      ],
    );
  }

  Widget _buildAudio(CallProvider call) {
    final connectedAt = call.connectedAt;
    final elapsed = connectedAt == null
        ? Duration.zero
        : DateTime.now().difference(connectedAt);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1EC268),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.24),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.call, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 4),
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xD2181818),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            _formatElapsed(elapsed),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  String _formatElapsed(Duration elapsed) {
    final seconds = elapsed.inSeconds < 0 ? 0 : elapsed.inSeconds;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(remainder)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(remainder)}';
  }

  Widget _buildAvatar(CallProvider call) {
    return GvAvatar(
      name: call.remoteUsername ?? '',
      uid: call.remoteUserId ?? 0,
      src: call.remoteAvatar,
      size: _videoOverlaySize.height,
      square: true,
    );
  }

  @override
  void dispose() {
    _call?.removeListener(_onCallChanged);
    _elapsedTimer?.cancel();
    _renderer.dispose();
    super.dispose();
  }
}
