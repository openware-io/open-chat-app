import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:open_core/open_core.dart';
import '../core/playback_audio_context.dart';
import '../models/outgoing_call_trace.dart';
import '../repositories/call_repository.dart';
import '../repositories/friend_repository.dart';
import '../services/call_platform_service.dart';

/// [CallProvider.initMedia] 在主叫拨号时的结果（用于区分「权限/设备」与「信令未连上」，避免 Web 上误提示）。
enum CallInitMediaOutcome {
  success,
  mediaAcquireFailed,
  signalingDisconnected,
}

/// WebRTC 通话（对齐 H5 `stores/call.js`）。`status == connected` 表示 SDP 信令完成，不保证 ICE 已通。
class CallProvider extends ChangeNotifier {
  CallProvider(this._calls, this._friends, this._platform) {
    _platform.onHangUpRequested = () {
      if (inCall) unawaited(hangup());
    };
    _platform.onAnswerRequested = () {
      if (status == 'incoming') unawaited(acceptCall());
    };
    _platform.onRestoreCallRequested = requestFullCallSurface;
    _platform.onPreparePictureInPicture = _preparePictureInPicture;
    _platform.onPictureInPictureModeChanged = _onPictureInPictureModeChanged;
  }

  /// 客户端固定的 TURN 入口。语音和视频通话共用同一份 ICE 配置。
  ///
  /// 后端下发的 iceServers（包括 username/credential）仍会保留；这里只
  /// 作为客户端兜底并确保该 TURN 入口始终参与 ICE 候选收集。
  static const String _clientTurnServerUrl =
      'turn:turn.dev.example.com:3478?transport=udp';
  static const Map<String, dynamic> _clientTurnIceServer = <String, dynamic>{
    'urls': _clientTurnServerUrl,
  };

  final CallRepository _calls;
  final FriendRepository _friends;
  final CallPlatformService _platform;

  /// Used to register accepted iOS calls with native background controls.
  /// Pending incoming calls use JPush and the in-app answer UI instead.
  bool Function()? isAppForeground;

  String status = 'idle';
  String? callId;
  String mediaType = 'video';
  int? remoteUserId;
  String? remoteUsername;
  String? remoteAvatar;

  /// 与 [ChatRoomScreen.peerId] 一致的字符串，用于通话结束写会话记录时的 `messageMap` key。
  String? _outgoingChatPeerId;

  /// 发起通话的会话类型（`private`/`secret`），用于通话结束写会话记录时走对应通道。
  String _outgoingChatType = 'private';
  bool isOutgoing = false;
  String? returnAfterCallLocation;

  /// The call remains connected when its full-screen route is removed.
  bool _isMinimized = false;
  bool get isMinimized => _isMinimized;

  /// True while Android or iOS is preparing/hosting the system video-call PiP.
  bool _isSystemPictureInPicture = false;
  bool get isSystemPictureInPicture => _isSystemPictureInPicture;

  /// Incremented when expanding system PiP should restore the full call page.
  int fullSurfaceRequestEpoch = 0;

  MediaStream? localStream;
  MediaStream? remoteStream;

  /// 本地预览是否前置摄像头（小窗镜像用）；切镜头后由原生返回值更新。
  bool _localCameraFacingFront = true;
  bool get localCameraFacingFront => _localCameraFacingFront;

  /// 当前是否使用扬声器外放。视频通话默认外放，语音通话默认听筒。
  bool _speakerOn = false;
  bool get speakerOn => _speakerOn;

  bool _backgroundBlurEnabled = false;
  bool get backgroundBlurEnabled => _backgroundBlurEnabled;

  bool _backgroundBlurChanging = false;
  bool get backgroundBlurChanging => _backgroundBlurChanging;

  int _backgroundBlurOperation = 0;

  bool get backgroundBlurSupported =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      mediaType == 'video' &&
      localStream?.getVideoTracks().isNotEmpty == true;

  bool get usesSystemVideoEffects =>
      !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.iOS &&
      mediaType == 'video';

  /// 避免并发/嵌套 [reset] 对同一次通话重复写入会话「通话记录」。
  String? _callTraceEmittedForCallId;

  /// 只有本机执行结束动作时才赋值，确保气泡归属结束动作的执行方。
  String? _localCallTraceKind;

  /// 远端流更新次数，用于强制重建 RTCVideoView / 重新绑定 renderer
  int remoteStreamEpoch = 0;

  /// 每次新建 PC / 结束通话递增，避免第二次通话 remoteStreamEpoch 又从 1 开始导致 ValueKey 与上一通相同、Texture 子树错误复用。
  int rtcSurfaceSession = 0;

  /// 通话代次；reset 时递增，丢弃上一通 PeerConnection 晚到的 onTrack 异步任务。
  int _rtcSession = 0;

  RTCPeerConnection? _pc;

  /// 合并多路 onTrack，避免后一次覆盖前一次导致无视频轨。
  MediaStream? _remoteComposite;

  /// 串行处理 onTrack，避免音视频两路同时到达时重复 createLocalMediaStream 竞态。
  Future<void> _remoteTrackChain = Future<void>.value();

  /// 来电信令中的 rtcIceConfig，接听时优先使用。
  Map<String, dynamic>? _incomingRtcIceConfig;

  /// 接听后先打开 `/call` 时置 true，隐藏全局 IncomingCallOverlay（否则 Stack 里遮罩盖在通话页面上）。
  bool _incomingBannerSuppressed = false;

  AudioPlayer? _incomingRingPlayer;

  /// 主叫方拨出后的「呼叫中」回铃音（参考微信：拨出即响，接通/挂断/拒接即停）。
  AudioPlayer? _outgoingRingPlayer;

  /// 接通时刻，用于计算通话时长摘要。
  DateTime? _connectedAt;
  DateTime? get connectedAt => _connectedAt;

  /// 本机结束通话（[reset]）时写入会话一条 `call` 消息；由 [main] 接到 [ChatProvider]。
  void Function(OutgoingCallTrace trace)? onOutgoingCallEndedTrace;

  /// 被叫侧：`answer_sdp` 早于 `acceptCall` 建完 PC 时先缓存，建链后再 setRemote。
  RTCSessionDescription? _pendingRemoteAnswer;

  /// setRemote 前到达的 ICE 与 H5 一致先入队，避免 addCandidate 被静默丢弃。
  final List<dynamic> _icePending = [];
  bool _remoteDescApplied = false;

  /// 与 [ClientRemoteConfigProvider] 同步的采集分辨率 / 最长通话（分钟，0 表示不自动挂断）。
  int _idealVideoWidth = 1280;
  int _idealVideoHeight = 720;
  int _maxCallDurationMinutes = 120;
  Timer? _maxCallDurationTimer;
  Timer? _iceDisconnectedTimer;

  static const Duration _icePrefetchTtl = Duration(minutes: 10);
  Map<String, dynamic>? _prefetchedIceConfig;
  DateTime? _prefetchedIceAt;

  bool get _prefetchedIceFresh =>
      _prefetchedIceConfig != null &&
      _prefetchedIceAt != null &&
      DateTime.now().difference(_prefetchedIceAt!) < _icePrefetchTtl &&
      !_iceServersEmpty(_prefetchedIceConfig!);

  bool get inCall => status != 'idle';
  bool get isRinging => status == 'ringing';
  bool get isIncoming => status == 'incoming';

  bool get showIncomingCallBanner =>
      status == 'incoming' && !_incomingBannerSuppressed;

  bool get showMinimizedCall =>
      inCall && (_isMinimized || _isSystemPictureInPicture);

  bool get _appIsForeground => isAppForeground?.call() ?? true;

  /// Sync background state for ongoing native call controls. Pending incoming
  /// calls stay app-owned; returning to the app can still show the answer card.
  void handleAppBackgrounded() {
    if (!inCall) return;
    _syncPlatformCallState();
  }

  void minimizeCall() {
    if (!inCall || _isMinimized) return;
    _isMinimized = true;
    notifyListeners();
  }

  void requestSystemOverlayPermission() {
    if (!inCall || mediaType != 'audio') return;
    unawaited(_platform.ensureSystemOverlayPermission());
  }

  Future<bool> enterSystemPictureInPicture() {
    if (!inCall || mediaType != 'video') return Future<bool>.value(false);
    return _platform.enterPictureInPicture();
  }

  void restoreCall() {
    if (!_isMinimized && !_isSystemPictureInPicture) return;
    _isMinimized = false;
    _isSystemPictureInPicture = false;
    notifyListeners();
  }

  /// 系统悬浮窗点按后，请求全局通话浮层恢复 `/call` 页面。
  ///
  /// 如果用户直接从全屏通话页按 Home，该路由仍在栈顶，只需唤醒 Activity，
  /// 不再重复 push 一层通话页。
  void requestFullCallSurface() {
    if (!inCall || !_isMinimized) return;
    fullSurfaceRequestEpoch++;
    notifyListeners();
  }

  void _preparePictureInPicture() {
    if (!inCall || mediaType != 'video') return;
    _isSystemPictureInPicture = true;
    notifyListeners();
  }

  void _onPictureInPictureModeChanged(bool inPictureInPicture) {
    final wasInPictureInPicture = _isSystemPictureInPicture;
    _isSystemPictureInPicture = inPictureInPicture;
    // Android PiP expansion should restore the full call route. iOS AVKit PiP
    // returns to the underlying chat and hands rendering back to the app-owned
    // compact overlay instead.
    final restoresFullCall = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        !inPictureInPicture &&
        wasInPictureInPicture &&
        _isMinimized;
    if (restoresFullCall) {
      fullSurfaceRequestEpoch++;
    }
    notifyListeners();
  }

  void _syncPlatformCallState() {
    final remoteVideoTracks = remoteStream?.getVideoTracks() ?? const [];
    final localVideoTracks = localStream?.getVideoTracks() ?? const [];
    unawaited(
      _platform.updateCallState(
        active: inCall && localStream != null,
        video: mediaType == 'video',
        callPresent: inCall,
        outgoing: isOutgoing,
        phase: status,
        callId: callId,
        remoteName: remoteUsername,
        remoteVideoTrackId:
            remoteVideoTracks.isEmpty ? null : remoteVideoTracks.first.id,
        localVideoTrackId:
            localVideoTracks.isEmpty ? null : localVideoTracks.first.id,
        connectedAt: _connectedAt,
        appForeground: _appIsForeground,
      ),
    );
  }

  /// Immediately clears every native call surface before WebRTC teardown.
  ///
  /// Closing peer connections and media tracks can take long enough for the
  /// app to enter the background. Sending the terminal state first prevents
  /// CallKit, iOS PiP, and Android's foreground overlay from treating that
  /// teardown window as an active call.
  Future<void> _deactivatePlatformCall() {
    return _platform.updateCallState(
      active: false,
      video: mediaType == 'video',
      callPresent: false,
      outgoing: isOutgoing,
      phase: 'idle',
      callId: callId,
      remoteName: remoteUsername,
      connectedAt: _connectedAt,
      appForeground: _appIsForeground,
    );
  }

  /// 接听按钮：先隐藏顶层来电条再导航，避免盖住通话页。
  void suppressIncomingCallBanner({bool stopRingtone = true}) {
    _incomingBannerSuppressed = true;
    if (stopRingtone) unawaited(_stopIncomingRingtone());
    notifyListeners();
  }

  Future<void> _ensureIncomingRingPlayer() async {
    _incomingRingPlayer ??= AudioPlayer();
  }

  /// 来电顶栏展示时循环播放提示音；接听/拒绝/挂断或离开 idle 时停止。
  Future<void> _startIncomingRingtone() async {
    try {
      await _ensureIncomingRingPlayer();
      final p = _incomingRingPlayer!;
      await p.stop();
      await applyPlaybackSpeakerRoute(p);
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(1.0);
      await p.play(AssetSource('sounds/incoming_call.mp3'));
    } catch (e) {
      debugPrint('CallProvider incoming ringtone: $e');
    }
  }

  Future<void> _stopIncomingRingtone() async {
    final p = _incomingRingPlayer;
    if (p == null) return;
    try {
      await p.stop();
    } catch (e) {
      debugPrint('CallProvider stop incoming ringtone: $e');
    }
  }

  /// 主叫方拨出后循环播放「呼叫中」回铃音（复用来电提示音；接入专用回铃音可替换资源）。
  Future<void> _startOutgoingRingtone() async {
    try {
      _outgoingRingPlayer ??= AudioPlayer();
      final p = _outgoingRingPlayer!;
      await p.stop();
      await applyPlaybackSpeakerRoute(p);
      await p.setReleaseMode(ReleaseMode.loop);
      await p.setVolume(1.0);
      await p.play(AssetSource('sounds/incoming_call.mp3'));
    } catch (e) {
      debugPrint('CallProvider outgoing ringtone: $e');
    }
  }

  Future<void> _stopOutgoingRingtone() async {
    final p = _outgoingRingPlayer;
    if (p == null) return;
    try {
      await p.stop();
    } catch (e) {
      debugPrint('CallProvider stop outgoing ringtone: $e');
    }
  }

  /// 登出或 401 时清除，避免下一账号误用上一账号的 TURN 凭证缓存。
  void clearIcePrefetch() {
    _prefetchedIceConfig = null;
    _prefetchedIceAt = null;
  }

  /// 冷启动预拉取 ICE，缩短首通建连；与 [initMedia] 内等待 Socket 配合使用。
  Future<void> prefetchRtcIceConfig() async {
    if (_prefetchedIceFresh) return;
    try {
      final raw = await _calls.rtcIceConfig();
      final n = _normalizeRtcIceConfig(raw);
      if (n != null && !_iceServersEmpty(n)) {
        _prefetchedIceConfig = Map<String, dynamic>.from(n);
        _prefetchedIceAt = DateTime.now();
      }
    } catch (_) {
      /* 首次失败可依赖信令内 rtcIceConfig 或后续重试 */
    }
  }

  void _markConnected() {
    _connectedAt = DateTime.now();
  }

  void _onMediaConnected() {
    if (!inCall || status == 'connected') return;
    _markConnected();
    unawaited(_stopOutgoingRingtone());
    status = 'connected';
    _syncPlatformCallState();
    notifyListeners();
    _armMaxCallDurationTimerIfNeeded();
    _scheduleRemoteTrackReconciliation();
  }

  void _onMediaConnectionFailed(String source) {
    if (!inCall || status == 'idle' || status == 'failed') return;
    debugPrint('CallProvider media connection failed: $source');
    unawaited(_stopOutgoingRingtone());
    if (isOutgoing) _localCallTraceKind = 'failed';
    status = 'failed';
    notifyListeners();
  }

  void _emitLocalCallTraceIfNeeded() {
    if (_localCallTraceKind == null || remoteUserId == null) return;
    if (status == 'idle') return;
    final cid = callId;
    if (cid != null && cid == _callTraceEmittedForCallId) return;
    final kind = _localCallTraceKind!;
    var durationSec = 0;
    if (kind == 'completed') {
      if (_connectedAt != null) {
        durationSec = DateTime.now().difference(_connectedAt!).inSeconds;
        if (durationSec < 0) durationSec = 0;
      }
    }
    final peerKey = _outgoingChatPeerId ?? '${remoteUserId!}';
    final trace = OutgoingCallTrace(
      peerId: peerKey,
      chatType: _outgoingChatType,
      media: mediaType,
      kind: kind,
      durationSec: durationSec,
      callId: cid,
    );
    final fn = onOutgoingCallEndedTrace;
    if (fn != null) {
      fn(trace);
      if (cid != null) {
        _callTraceEmittedForCallId = cid;
      }
    }
  }

  Future<void> reset() async {
    _iceDisconnectedTimer?.cancel();
    _iceDisconnectedTimer = null;
    _emitLocalCallTraceIfNeeded();
    _localCallTraceKind = null;
    _connectedAt = null;
    _isMinimized = false;
    _isSystemPictureInPicture = false;
    notifyListeners();
    await _deactivatePlatformCall();
    await _stopIncomingRingtone();
    await _stopOutgoingRingtone();
    try {
      await _pc?.close();
    } catch (e) {
      debugPrint('CallProvider reset close pc: $e');
    }
    _pc = null;
    try {
      await _stopLocal();
    } catch (e) {
      debugPrint('CallProvider reset stop local: $e');
    }
    try {
      if (_remoteComposite != null) {
        await _remoteComposite!.dispose();
      }
    } catch (e) {
      debugPrint('CallProvider reset remote composite: $e');
    }
    _remoteComposite = null;
    _remoteTrackChain = Future<void>.value();
    remoteStream = null;
    remoteStreamEpoch = 0;
    _maxCallDurationTimer?.cancel();
    _maxCallDurationTimer = null;
    status = 'idle';
    callId = null;
    remoteUserId = null;
    remoteUsername = null;
    remoteAvatar = null;
    _outgoingChatPeerId = null;
    _outgoingChatType = 'private';
    _callTraceEmittedForCallId = null;
    _localCameraFacingFront = true;
    _speakerOn = false;
    isOutgoing = false;
    _isMinimized = false;
    _isSystemPictureInPicture = false;
    _incomingRtcIceConfig = null;
    _incomingBannerSuppressed = false;
    _pendingRemoteAnswer = null;
    _icePending.clear();
    _remoteDescApplied = false;
    // 必须在关闭 PC、清空队列之后再递增，否则 close() 过程中晚到的 onTrack 会拿到「新代次」、与旧连接混淆，导致一直丢弃远端轨。
    _rtcSession++;
    rtcSurfaceSession++;
    _syncPlatformCallState();
    notifyListeners();
  }

  /// 登录后拉取 `GET /config/client` 后调用，用于采集分辨率与自动挂断时长。
  void applyClientRtc(ClientRtcBlock rtc) {
    _maxCallDurationTimer?.cancel();
    _maxCallDurationTimer = null;
    final q = rtc.videoQuality.toLowerCase();
    if (q.contains('1080')) {
      _idealVideoWidth = 1920;
      _idealVideoHeight = 1080;
    } else if (q.contains('480')) {
      _idealVideoWidth = 854;
      _idealVideoHeight = 480;
    } else {
      _idealVideoWidth = 1280;
      _idealVideoHeight = 720;
    }
    _maxCallDurationMinutes = rtc.maxCallDuration;
  }

  void _armMaxCallDurationTimerIfNeeded() {
    _maxCallDurationTimer?.cancel();
    _maxCallDurationTimer = null;
    final min = _maxCallDurationMinutes;
    if (min <= 0 || status != 'connected') return;
    _maxCallDurationTimer = Timer(Duration(minutes: min), () async {
      if (status == 'connected') {
        await hangup();
      }
    });
  }

  Future<void> _stopLocal() async {
    final s = localStream;
    await _resetBackgroundBlur(s);
    localStream = null;
    if (s != null) {
      for (final t in s.getTracks()) {
        await t.stop();
      }
      await s.dispose();
    }
  }

  Future<void> _resetBackgroundBlur(MediaStream? stream) async {
    _backgroundBlurOperation++;
    _backgroundBlurChanging = false;
    _backgroundBlurEnabled = false;
    final trackId = stream?.getVideoTracks().firstOrNull?.id;
    if (trackId == null || trackId.isEmpty) return;
    await _platform.setBackgroundBlur(trackId: trackId, enabled: false);
  }

  bool _iceServersEmpty(Map<String, dynamic> cfg) {
    final s = cfg['iceServers'];
    return s is! List || s.isEmpty;
  }

  Map<String, dynamic>? _normalizeRtcIceConfig(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final rawServers = m['iceServers'];
    if (rawServers is! List || rawServers.isEmpty) return null;
    final servers = _withTcpTurnFallbacks(rawServers);
    if (!_containsClientTurnServer(servers)) {
      servers.add(_clientTurnIceServer);
    }
    return {
      'iceServers': servers,
      'iceTransportPolicy': m['iceTransportPolicy'] ?? 'all',
    };
  }

  bool _containsClientTurnServer(List<dynamic> servers) {
    for (final server in servers) {
      if (server is String && server == _clientTurnServerUrl) return true;
      if (server is! Map) continue;
      final urls = server['urls'];
      if (urls is String && urls == _clientTurnServerUrl) return true;
      if (urls is List &&
          urls.any((url) => url.toString() == _clientTurnServerUrl)) {
        return true;
      }
    }
    return false;
  }

  /// 移动网络或企业 Wi-Fi 可能阻断 UDP。为后端已鉴权的 UDP TURN URL
  /// 补充同一入口的 TCP URL，复用原始 username/credential，避免把凭证
  /// 写死在客户端。TLS (`turns:`) 则由服务端显式下发，不能在这里猜测。
  List<dynamic> _withTcpTurnFallbacks(List<dynamic> rawServers) {
    final servers = <dynamic>[];
    final knownUrls = <String>{};

    void addServer(dynamic server) {
      if (server is! Map) {
        servers.add(server);
        return;
      }
      final copy = Map<String, dynamic>.from(server);
      final rawUrls = copy['urls'];
      final urls = rawUrls is List
          ? rawUrls.map((url) => url.toString()).toList()
          : rawUrls is String
              ? <String>[rawUrls]
              : <String>[];
      if (urls.isEmpty) {
        servers.add(copy);
        return;
      }

      final expandedUrls = <String>[];
      for (final url in urls) {
        if (knownUrls.add(url)) expandedUrls.add(url);
        final tcpUrl = _tcpFallbackForTurnUrl(url);
        if (tcpUrl != null && knownUrls.add(tcpUrl)) {
          expandedUrls.add(tcpUrl);
        }
      }
      copy['urls'] = expandedUrls;
      servers.add(copy);
    }

    for (final server in rawServers) {
      addServer(server);
    }
    return servers;
  }

  String? _tcpFallbackForTurnUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || uri.scheme.toLowerCase() != 'turn') return null;
    if (uri.queryParameters['transport']?.toLowerCase() != 'udp') return null;
    return uri.replace(queryParameters: {
      ...uri.queryParameters,
      'transport': 'tcp',
    }).toString();
  }

  /// Android libwebrtc 期望 mandatory/optional 结构；用错会出现 MediaConstraintsUtils 告警并可能影响协商。
  Map<String, dynamic> _nativeSdpConstraints() {
    return <String, dynamic>{
      'mandatory': <String, dynamic>{
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': mediaType == 'video',
      },
      'optional': <dynamic>[],
    };
  }

  Future<Map<String, dynamic>> _resolvePeerConnectionConfig(
      {Map<String, dynamic>? rtcIceConfigFromSignal}) async {
    var cfg = _normalizeRtcIceConfig(rtcIceConfigFromSignal);
    if (cfg == null || _iceServersEmpty(cfg)) {
      cfg = _normalizeRtcIceConfig(_incomingRtcIceConfig);
      if (cfg != null && !_iceServersEmpty(cfg)) {
        _incomingRtcIceConfig = null;
      }
    }
    if (cfg == null || _iceServersEmpty(cfg)) {
      if (_prefetchedIceFresh) {
        cfg = Map<String, dynamic>.from(_prefetchedIceConfig!);
      }
    }
    if (cfg == null || _iceServersEmpty(cfg)) {
      try {
        final raw = await _calls.rtcIceConfig();
        cfg = _normalizeRtcIceConfig(raw);
        if (cfg != null && !_iceServersEmpty(cfg)) {
          _prefetchedIceConfig = Map<String, dynamic>.from(cfg);
          _prefetchedIceAt = DateTime.now();
        }
      } catch (_) {
        cfg = null;
      }
    }
    cfg ??= {
      'iceTransportPolicy': 'all',
      'iceServers': <dynamic>[_clientTurnIceServer],
    };
    final pol = cfg['iceTransportPolicy'];
    if (pol is! String || pol.isEmpty) {
      cfg['iceTransportPolicy'] = 'all';
    }
    cfg['bundlePolicy'] = 'balanced';
    cfg['rtcpMuxPolicy'] = 'require';
    // 0 + trickle：避免 iceCandidatePool>0 与双端 Flutter 时序组合导致 ICE 长期不连通。
    cfg['iceCandidatePoolSize'] = 0;
    return cfg;
  }

  Future<void> _applyRemoteDescription(RTCSessionDescription desc) async {
    final pc = _pc;
    if (pc == null) return;
    await pc.setRemoteDescription(desc);
    _remoteDescApplied = true;
    await _drainIcePending();
  }

  Future<void> _drainIcePending() async {
    final pc = _pc;
    if (pc == null || !_remoteDescApplied) return;
    final batch = List<dynamic>.from(_icePending);
    _icePending.clear();
    for (final raw in batch) {
      final cand = _candidateFrom(raw);
      if (cand == null) continue;
      try {
        await pc.addCandidate(cand);
      } catch (e) {
        debugPrint('CallProvider drain addCandidate: $e');
      }
    }
  }

  Future<void> _queueOrAddIce(dynamic raw) async {
    if (raw == null) {
      return;
    }
    final cand = _candidateFrom(raw);
    if (cand == null) return;
    final pc = _pc;
    if (pc == null || !_remoteDescApplied) {
      _icePending.add(raw);
      return;
    }
    try {
      await pc.addCandidate(cand);
    } catch (e) {
      debugPrint('CallProvider addCandidate: $e');
    }
  }

  void _enqueueRemoteTrack(RTCTrackEvent e) {
    final session = _rtcSession;
    _remoteTrackChain = _remoteTrackChain.then((_) async {
      if (session != _rtcSession) return;
      await _handleRemoteTrack(e, session);
    }).catchError((Object err, StackTrace st) {
      debugPrint('CallProvider onTrack chain: $err');
    });
  }

  Future<void> _handleRemoteTrack(RTCTrackEvent e, int session) async {
    try {
      if (session != _rtcSession) return;
      final t = e.track;
      try {
        t.enabled = true;
      } catch (_) {
        /* ignore */
      }

      // 非 Web：合并远端轨到独立 MediaStream（localStreams）。ownerTag 勿用 `local`，避免与摄像头流标签冲突。
      final useEventStreams = kIsWeb && e.streams.isNotEmpty;
      if (useEventStreams) {
        if (_remoteComposite != null) {
          await _remoteComposite!.dispose();
          _remoteComposite = null;
        }
        if (session != _rtcSession) return;
        remoteStream = e.streams.first;
        remoteStreamEpoch++;
        _syncPlatformCallState();
        notifyListeners();
        return;
      }

      _remoteComposite ??= await createLocalMediaStream('open_remote');
      if (session != _rtcSession) return;
      final ids = _remoteComposite!.getTracks().map((x) => x.id).toSet();
      if (ids.contains(t.id)) {
        remoteStream = _remoteComposite;
        _syncPlatformCallState();
        notifyListeners();
        return;
      }

      // 须在 await addTrack 之前递增 epoch，避免微任务插队时 composite 已有轨而 epoch 未更新导致远端绑定错乱。
      remoteStreamEpoch++;
      await _remoteComposite!.addTrack(t);
      if (session != _rtcSession) return;
      remoteStream = _remoteComposite;
      // 必须先通知 UI：若先只收到音频轨却不 notify，CallScreen 永远不绑远端流 → 无声音且可能长期黑屏。
      final kind = (t.kind ?? '').toLowerCase();
      final hasRemoteVideo = kind == 'video' ||
          _remoteComposite!.getVideoTracks().isNotEmpty ||
          _remoteComposite!
              .getTracks()
              .any((x) => (x.kind ?? '').toLowerCase() == 'video');
      _syncPlatformCallState();
      notifyListeners();
      if (mediaType == 'video' && !hasRemoteVideo) {
        return;
      }
    } catch (err) {
      debugPrint('CallProvider onTrack: $err');
    }
  }

  Future<RTCPeerConnection> _createPeerConnection({
    Map<String, dynamic>? rtcIceConfigFromSignal,
    bool attachLocalTracks = true,
  }) async {
    rtcSurfaceSession++;
    _remoteDescApplied = false;
    final configuration = await _resolvePeerConnectionConfig(
        rtcIceConfigFromSignal: rtcIceConfigFromSignal);
    final pc = await createPeerConnection(configuration);
    pc.onIceCandidate = (RTCIceCandidate? c) {
      if (remoteUserId == null || callId == null || c == null) return;
      _calls.emitRtcSignal({
        'action': 'candidate',
        'targetUserId': remoteUserId,
        'callId': callId,
        'candidate': c.toMap(),
      });
    };
    pc.onTrack = _enqueueRemoteTrack;
    pc.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('CallProvider ICE connection state: $state');
      switch (state) {
        case RTCIceConnectionState.RTCIceConnectionStateConnected:
        case RTCIceConnectionState.RTCIceConnectionStateCompleted:
          _onMediaConnected();
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          _onMediaConnectionFailed('ICE failed');
          break;
        default:
          break;
      }
    };
    pc.onConnectionState = (RTCPeerConnectionState state) {
      debugPrint('CallProvider peer connection state: $state');
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _onMediaConnected();
          break;
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _onMediaConnectionFailed('peer connection failed');
          break;
        default:
          break;
      }
    };
    if (attachLocalTracks && localStream != null) {
      for (final t in localStream!.getTracks()) {
        await pc.addTrack(t, localStream!);
      }
    }
    _pc = pc;
    return pc;
  }

  Future<bool> _ensureCallCapturePermissions(String type) async {
    if (kIsWeb) return true;
    var mic = await Permission.microphone.status;
    if (!mic.isGranted) {
      mic = await Permission.microphone.request();
    }
    if (!mic.isGranted) return false;
    if (type == 'video') {
      var cam = await Permission.camera.status;
      if (!cam.isGranted) {
        cam = await Permission.camera.request();
      }
      if (!cam.isGranted) return false;
    }
    return true;
  }

  Future<void> _getMedia(String type) async {
    if (!await _ensureCallCapturePermissions(type)) {
      throw StateError('camera_or_mic_permission_denied');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.communication,
        );
      } catch (e) {
        debugPrint('CallProvider setAndroidAudioConfiguration: $e');
      }
    }
    await _stopLocal();
    const audio = true;
    final video = type == 'video';
    try {
      // iOS WebRTC 对 facingMode / 理想分辨率等约束支持差，易在无明确权限错误时 getUserMedia 失败
      final Object videoSpec = !video
          ? false
          : (defaultTargetPlatform == TargetPlatform.iOS
              ? true
              : <String, dynamic>{
                  'facingMode': 'user',
                  'width': {'ideal': _idealVideoWidth},
                  'height': {'ideal': _idealVideoHeight},
                  'frameRate': {'ideal': 24, 'max': 30},
                });
      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': audio,
        'video': videoSpec,
      });
      if (video) {
        _localCameraFacingFront = true;
      }
    } catch (e) {
      if (video) {
        mediaType = 'audio';
        localStream = await navigator.mediaDevices.getUserMedia({
          'audio': audio,
          'video': false,
        });
      } else {
        rethrow;
      }
    }
    _speakerOn = video;
    if (!kIsWeb) {
      try {
        await Helper.setSpeakerphoneOn(_speakerOn);
      } catch (e) {
        debugPrint('CallProvider setSpeakerphoneOn: $e');
      }
    }
    _syncPlatformCallState();
    notifyListeners();
  }

  /// 已在任意通话状态中（振铃/来电/连接）时返回 false，避免并发多路通话。
  ///
  /// [peerIdStr] 须与 [ChatRoomScreen.peerId] 一致，否则通话结束写入的会话记录会落到错误的 `messageMap` key。
  bool startCall(
    int targetId,
    String targetName, {
    String type = 'video',
    String? returnLocation,
    String? peerIdStr,
    String chatType = 'private',
  }) {
    if (status != 'idle') {
      return false;
    }
    mediaType = type;
    remoteUserId = targetId;
    remoteUsername = targetName;
    remoteAvatar = null;
    _outgoingChatPeerId = peerIdStr ?? '$targetId';
    _outgoingChatType = chatType;
    isOutgoing = true;
    callId =
        '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 20)}';
    _callTraceEmittedForCallId = null;
    _localCallTraceKind = null;
    status = 'ringing';
    returnAfterCallLocation = returnLocation;
    _isMinimized = false;
    _isSystemPictureInPicture = false;
    _syncPlatformCallState();
    notifyListeners();
    unawaited(_refreshRemoteProfile(targetId, callId));
    unawaited(_startOutgoingRingtone());
    return true;
  }

  Future<void> _refreshRemoteProfile(int userId, String? expectedCallId) async {
    try {
      final user = await _friends.loadUserProfile(userId);
      if (!inCall ||
          remoteUserId != userId ||
          callId?.toString() != expectedCallId?.toString()) {
        return;
      }
      final resolvedName = user.displayName.trim();
      if (resolvedName.isNotEmpty) {
        remoteUsername = resolvedName;
      }
      remoteAvatar = user.avatar?.trim();
      _syncPlatformCallState();
      notifyListeners();
    } catch (e) {
      debugPrint('CallProvider load remote profile: $e');
    }
  }

  String? takeReturnAfterCallLocation() {
    final p = returnAfterCallLocation;
    returnAfterCallLocation = null;
    return p;
  }

  bool _shouldUseWebPrefetchedLocalStream() => kIsWeb && localStream != null;

  /// Web：在「拨打 / 接听」的 [onTap] 内、`go`/`push` 进通话页**之前**调用，
  /// 使 [navigator.mediaDevices.getUserMedia] 落在用户手势内，从而正常弹出权限条（与 H5 一致）。
  ///
  /// 非 Web 恒为 [CallInitMediaOutcome.success]。已成功则 [localStream] 已就绪，[initMedia]/[acceptCall] 内会跳过重复采集。
  Future<CallInitMediaOutcome> prepareWebLocalMediaInUserGesture() async {
    if (!kIsWeb) return CallInitMediaOutcome.success;
    if (localStream != null) return CallInitMediaOutcome.success;
    try {
      await _getMedia(mediaType);
    } catch (e) {
      debugPrint('CallProvider prepareWebLocalMediaInUserGesture: $e');
      return CallInitMediaOutcome.mediaAcquireFailed;
    }
    return CallInitMediaOutcome.success;
  }

  Future<CallInitMediaOutcome> initMedia() async {
    if (!_shouldUseWebPrefetchedLocalStream()) {
      try {
        await _getMedia(mediaType);
      } catch (e) {
        debugPrint('CallProvider initMedia getUserMedia failed: $e');
        return CallInitMediaOutcome.mediaAcquireFailed;
      }
    }

    // 先拿本地媒体再等与信令通道，避免 Web 上 Socket 短暂未连全时误报「麦克风/摄像头」。
    _calls.reconnectSignalingIfNeeded();
    const wait = kIsWeb ? Duration(seconds: 20) : Duration(seconds: 12);
    final deadline = DateTime.now().add(wait);
    if (!_calls.signalingConnected) {
      while (!_calls.signalingConnected && DateTime.now().isBefore(deadline)) {
        _calls.reconnectSignalingIfNeeded();
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
    }
    if (!_calls.signalingConnected) {
      debugPrint('CallProvider initMedia: socket not connected after wait');
      await _stopLocal();
      return CallInitMediaOutcome.signalingDisconnected;
    }

    await prefetchRtcIceConfig();
    _calls.emitRtcSignal({
      'action': 'call',
      'targetUserId': remoteUserId,
      'mediaType': mediaType,
      'callId': callId,
    });
    return CallInitMediaOutcome.success;
  }

  void onIncomingCall(Map<String, dynamic> data, {bool showBanner = true}) {
    final cid = data['callId']?.toString();
    if (inCall && callId == cid) {
      if (!showBanner) suppressIncomingCallBanner(stopRingtone: false);
      return;
    }

    if (inCall) {
      _calls.emitRtcSignal({
        'action': 'busy',
        'targetUserId': data['fromUserId'],
        'callId': data['callId'],
      });
      return;
    }

    callId = cid;
    _callTraceEmittedForCallId = null;
    _localCallTraceKind = null;
    remoteUserId = jsonInt(data['fromUserId']);
    final signalName = data['fromUsername']?.toString().trim();
    remoteUsername =
        signalName == null || signalName.isEmpty ? null : signalName;
    final signalAvatar = data['fromAvatar']?.toString().trim();
    remoteAvatar =
        signalAvatar == null || signalAvatar.isEmpty ? null : signalAvatar;
    mediaType = (data['mediaType'] as String?) ?? 'video';
    isOutgoing = false;
    status = 'incoming';
    _incomingBannerSuppressed = !showBanner;
    _isMinimized = false;
    _isSystemPictureInPicture = false;
    final ric = data['rtcIceConfig'];
    if (ric is Map) {
      _incomingRtcIceConfig = Map<String, dynamic>.from(ric);
    }
    _syncPlatformCallState();
    notifyListeners();
    final incomingUserId = remoteUserId;
    if (incomingUserId != null) {
      unawaited(_refreshRemoteProfile(incomingUserId, callId));
    }
    unawaited(_startIncomingRingtone());
  }

  bool _acceptingCall = false;

  Future<void> acceptCall() async {
    if (status != 'incoming' || _acceptingCall) return;
    _acceptingCall = true;
    final answeringCallId = callId;
    final session = _rtcSession;
    try {
      await _acceptIncomingCall(answeringCallId, session);
    } finally {
      _acceptingCall = false;
    }
  }

  Future<void> _acceptIncomingCall(String? answeringCallId, int session) async {
    await _stopIncomingRingtone();
    if (callId != answeringCallId || _rtcSession != session || !isIncoming) {
      return;
    }
    if (!_shouldUseWebPrefetchedLocalStream()) {
      try {
        await _getMedia(mediaType);
      } catch (_) {
        if (callId == answeringCallId && _rtcSession == session && isIncoming) {
          await rejectCall();
        }
        return;
      }
    }

    await prefetchRtcIceConfig();

    if (callId != answeringCallId || _rtcSession != session || !isIncoming) {
      return;
    }

    status = 'connecting';
    _syncPlatformCallState();
    notifyListeners();

    final pc = await _createPeerConnection();
    final offer = await pc.createOffer(_nativeSdpConstraints());
    await pc.setLocalDescription(offer);
    _calls.emitRtcSignal({
      'action': 'answer',
      'targetUserId': remoteUserId,
      'callId': callId,
      'sdp': {'type': offer.type, 'sdp': offer.sdp},
    });
    await _applyPendingRemoteAnswerIfAny();
  }

  Future<void> _applyPendingRemoteAnswerIfAny() async {
    final pending = _pendingRemoteAnswer;
    final pc = _pc;
    if (pending == null || pc == null) return;
    try {
      await _applyRemoteDescription(pending);
      _pendingRemoteAnswer = null;
    } catch (e) {
      debugPrint('CallProvider apply pending answer SDP: $e');
    }
  }

  /// 个别 Android 上 onTrack 与解码器就绪顺序不稳定；从 PC 的 receiver 补挂遗漏的轨，减轻黑屏。
  void _scheduleRemoteTrackReconciliation() {
    if (kIsWeb) return;
    final session = _rtcSession;
    for (final d in const [
      Duration(milliseconds: 350),
      Duration(milliseconds: 1400)
    ]) {
      Future<void>.delayed(d, () {
        unawaited(_reconcileRemoteTracksFromReceivers(session));
      });
    }
  }

  Future<void> _reconcileRemoteTracksFromReceivers(int session) async {
    if (session != _rtcSession || status != 'connected' || _pc == null) {
      return;
    }
    try {
      final receivers = await _pc!.getReceivers();
      if (session != _rtcSession || _pc == null) return;
      var added = false;
      _remoteComposite ??= await createLocalMediaStream('open_remote');
      if (session != _rtcSession) return;
      final ids = _remoteComposite!.getTracks().map((x) => x.id).toSet();
      for (final r in receivers) {
        final t = r.track;
        if (t == null) continue;
        if (ids.contains(t.id)) continue;
        await _remoteComposite!.addTrack(t);
        added = true;
        ids.add(t.id);
        if (session != _rtcSession) return;
      }
      if (added && session == _rtcSession) {
        remoteStream = _remoteComposite;
        remoteStreamEpoch++;
        _syncPlatformCallState();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('CallProvider reconcile receivers: $e');
    }
  }

  Future<void> rejectCall() async {
    _localCallTraceKind = 'rejected';
    if (remoteUserId != null) {
      _calls.emitRtcSignal({
        'action': 'reject',
        'targetUserId': remoteUserId,
        'callId': callId,
      });
    }
    await reset();
  }

  Future<void> hangup() async {
    _localCallTraceKind = status == 'connected' ? 'completed' : 'cancelled';
    if (remoteUserId != null) {
      _calls.emitRtcSignal({
        'action': 'hangup',
        'targetUserId': remoteUserId,
        'callId': callId,
      });
    }
    await reset();
  }

  RTCSessionDescription? _sdpFrom(dynamic raw) {
    if (raw is Map) {
      final type = raw['type'] as String?;
      final sdp = raw['sdp'] as String?;
      if (type != null && sdp != null) return RTCSessionDescription(sdp, type);
    }
    return null;
  }

  RTCIceCandidate? _candidateFrom(dynamic raw) {
    if (raw is Map) {
      final c = raw['candidate'] as String?;
      final mid = raw['sdpMid'] as String?;
      final idxRaw = raw['sdpMLineIndex'];
      int? idx;
      if (idxRaw is int) {
        idx = idxRaw;
      } else if (idxRaw is num) {
        idx = idxRaw.toInt();
      } else if (idxRaw is String) {
        idx = int.tryParse(idxRaw.trim());
      }
      if (c != null && c.trim().isNotEmpty) {
        return RTCIceCandidate(c, mid, idx);
      }
    }
    return null;
  }

  /// SDP 类信令：未带 callId / 空字符串时仍处理（网关或 socket 可能省略）；带了则与当前通话比对。
  bool _signalBelongsToThisCall(Map<String, dynamic> map) {
    final raw = map['callId'];
    if (raw == null) return true;
    final cid = raw.toString();
    if (cid.isEmpty) return true;
    return cid == callId?.toString();
  }

  /// ICE candidate：若未带 callId 则视为当前连接（兼容旧信令）；带了则必须与当前通话一致。
  bool _signalMatchesCandidate(Map<String, dynamic> map) {
    final raw = map['callId'];
    if (raw == null) return true;
    final cid = raw.toString();
    if (cid.isEmpty) return true;
    return cid == callId?.toString();
  }

  /// 挂断类：未带 callId 时仍处理（兼容旧信令）；带了但与当前通话不一致则忽略。
  bool _signalMatchesHangup(Map<String, dynamic> map) {
    final raw = map['callId'];
    if (raw == null) return true;
    final cid = raw.toString();
    if (cid.isEmpty) return true;
    return cid == callId?.toString();
  }

  bool _strictCallIdMatch(Map<String, dynamic> map) {
    final raw = map['callId'];
    if (raw == null || callId == null) return false;
    return raw.toString() == callId.toString();
  }

  /// 对方挂断/拒接/忙：callId 偶发不一致时，用 fromUserId 与 remoteUserId 对齐仍可结束通话并退出页面。
  bool _shouldApplyRemoteHangup(Map<String, dynamic> map) {
    if (_signalMatchesHangup(map)) return true;
    final from = jsonInt(map['fromUserId']);
    return from != null && remoteUserId != null && from == remoteUserId;
  }

  Future<void> onSignal(dynamic data) async {
    final map = Map<String, dynamic>.from(data as Map);
    final action = map['action'] as String?;

    switch (action) {
      case 'call':
        onIncomingCall(map);
        break;

      case 'answer':
        if (status != 'ringing') return;
        if (!_signalBelongsToThisCall(map)) return;
        unawaited(_stopOutgoingRingtone());
        status = 'connecting';
        _syncPlatformCallState();
        notifyListeners();

        // 主叫：与浏览器(H5) 协商时，先应用远端 offer 再 addTrack，再 createAnswer。
        // 若先 addTrack 再 setRemote，部分 Android/WebRTC 与 H5 的 Unified Plan offer 组合后，
        // 远端视频轨无法正确协商，出现主叫端大图黑屏（被叫 H5→Flutter 仍正常）。
        for (var i = 0; i < 40 && localStream == null; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }
        if (localStream == null) {
          debugPrint('CallProvider answer: localStream is null');
          status = 'ringing';
          _syncPlatformCallState();
          notifyListeners();
          return;
        }

        final ric = map['rtcIceConfig'];
        final rtcCfg = ric is Map ? Map<String, dynamic>.from(ric) : null;
        final pc = await _createPeerConnection(
          rtcIceConfigFromSignal: rtcCfg,
          attachLocalTracks: false,
        );
        final remote = _sdpFrom(map['sdp']);
        if (remote != null) {
          await _applyRemoteDescription(remote);
        }
        for (final t in localStream!.getTracks()) {
          await pc.addTrack(t, localStream!);
        }
        final answer = await pc.createAnswer(_nativeSdpConstraints());
        await pc.setLocalDescription(answer);
        _calls.emitRtcSignal({
          'action': 'answer_sdp',
          'targetUserId': remoteUserId,
          'callId': callId,
          'sdp': {'type': answer.type, 'sdp': answer.sdp},
        });
        break;

      case 'answer_sdp':
        if (!_signalBelongsToThisCall(map)) return;
        final remoteAns = _sdpFrom(map['sdp']);
        if (remoteAns == null) break;
        final pcAns = _pc;
        if (pcAns == null) {
          _pendingRemoteAnswer = remoteAns;
          break;
        }
        await _applyRemoteDescription(remoteAns);
        _pendingRemoteAnswer = null;
        break;

      case 'candidate':
        if (!_signalMatchesCandidate(map)) return;
        await _queueOrAddIce(map['candidate']);
        break;

      /// 同账号其它端已接听/拒接/忙，本端仅关闭来电 UI，不再向对端发信令
      case 'incoming_resolved':
        if (status != 'incoming') return;
        if (!_strictCallIdMatch(map)) return;
        await reset();
        break;

      /// 服务端拒绝发起（例如主叫已在通话中）
      case 'call_failed':
        if (status != 'ringing') return;
        if (!_strictCallIdMatch(map)) return;
        _localCallTraceKind = 'failed';
        await reset();
        break;

      case 'hangup':
      case 'reject':
      case 'busy':
        if (!_shouldApplyRemoteHangup(map)) return;
        await reset();
        break;
    }
  }

  Future<bool?> toggleMute() async {
    final s = localStream;
    if (s == null) return null;
    final t = s.getAudioTracks().firstOrNull;
    if (t == null) return null;
    t.enabled = !t.enabled;
    notifyListeners();
    return t.enabled;
  }

  /// 在听筒与扬声器之间切换（Web 由浏览器/系统决定输出设备）。
  Future<bool?> toggleSpeaker() async {
    if (kIsWeb) return null;
    final next = !_speakerOn;
    try {
      await Helper.setSpeakerphoneOn(next);
      _speakerOn = next;
      notifyListeners();
      return _speakerOn;
    } catch (e, st) {
      debugPrint('CallProvider toggleSpeaker: $e\n$st');
      return null;
    }
  }

  Future<bool?> toggleCamera() async {
    final s = localStream;
    if (s == null) return null;
    final t = s.getVideoTracks().firstOrNull;
    if (t == null) return null;
    t.enabled = !t.enabled;
    notifyListeners();
    return t.enabled;
  }

  /// Enables/disables native person segmentation on the local video track.
  /// Failures leave the original camera frame untouched so the call continues.
  Future<bool> toggleBackgroundBlur() async {
    if (!backgroundBlurSupported || _backgroundBlurChanging) return false;
    final trackId = localStream?.getVideoTracks().firstOrNull?.id;
    if (trackId == null || trackId.isEmpty) return false;

    final requested = !_backgroundBlurEnabled;
    final operation = ++_backgroundBlurOperation;
    _backgroundBlurChanging = true;
    notifyListeners();
    final applied = await _platform.setBackgroundBlur(
      trackId: trackId,
      enabled: requested,
    );
    if (operation != _backgroundBlurOperation) {
      if (requested && applied) {
        await _platform.setBackgroundBlur(trackId: trackId, enabled: false);
      }
      return false;
    }

    if (applied) _backgroundBlurEnabled = requested;
    _backgroundBlurChanging = false;
    notifyListeners();
    return applied;
  }

  /// iOS does not let apps toggle Portrait Effect directly. It provides a
  /// system video-effects panel where the user can enable/disable Portrait.
  Future<bool> showSystemVideoEffects() async {
    if (!usesSystemVideoEffects || localStream == null) return false;
    return _platform.showSystemVideoEffects();
  }

  /// 切换前置/后置摄像头（仅原生；Web 需枚举设备后另行实现）。
  Future<bool?> switchCameraFacing() async {
    if (kIsWeb) return null;
    final s = localStream;
    if (s == null) return null;
    if (mediaType != 'video') return null;
    final t = s.getVideoTracks().firstOrNull;
    if (t == null) return null;
    try {
      final front = await Helper.switchCamera(t);
      _localCameraFacingFront = front;
      notifyListeners();
      return true;
    } catch (e, st) {
      debugPrint('CallProvider switchCameraFacing: $e\n$st');
      return false;
    }
  }
}

extension on List<MediaStreamTrack> {
  MediaStreamTrack? get firstOrNull => isEmpty ? null : first;
}
