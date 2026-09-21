import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridges the active WebRTC session to platform call surfaces.
///
/// Android uses this to keep an ongoing call in a foreground service and to
/// enter system picture-in-picture when the user leaves the app during video
/// calls. iOS uses the same state for CallKit, the call audio session, and
/// native video-call picture-in-picture.
class CallPlatformService {
  static const MethodChannel _channel =
      MethodChannel('com.gv.chat/call_platform');

  CallPlatformService() {
    if (_supportsNativeBridge) {
      _channel.setMethodCallHandler(_handlePlatformCall);
    }
  }

  VoidCallback? onHangUpRequested;
  VoidCallback? onAnswerRequested;
  VoidCallback? onRestoreCallRequested;
  VoidCallback? onPreparePictureInPicture;
  ValueChanged<bool>? onPictureInPictureModeChanged;

  bool get _supportsNativeBridge =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> updateCallState({
    required bool active,
    required bool video,
    required bool callPresent,
    required bool outgoing,
    required String phase,
    String? callId,
    String? remoteName,
    String? remoteVideoTrackId,
    String? localVideoTrackId,
    DateTime? connectedAt,
    bool appForeground = true,
  }) async {
    if (!_supportsNativeBridge) return;
    try {
      await _channel.invokeMethod<void>('setCallState', <String, dynamic>{
        'active': active,
        'video': video,
        'callPresent': callPresent,
        'outgoing': outgoing,
        'phase': phase,
        'callId': callId ?? '',
        'remoteName': remoteName ?? '',
        'remoteVideoTrackId': remoteVideoTrackId ?? '',
        'localVideoTrackId': localVideoTrackId ?? '',
        'connectedAtMillis': connectedAt?.millisecondsSinceEpoch ?? 0,
        'appForeground': appForeground,
      });
    } on PlatformException catch (error) {
      debugPrint('CallPlatformService setCallState: $error');
    } on MissingPluginException catch (error) {
      debugPrint('CallPlatformService setCallState unavailable: $error');
    }
  }

  /// Requests Android's "display over other apps" permission when needed.
  ///
  /// The settings page is only opened from the user's explicit minimize
  /// action. Once granted, the native foreground service can keep the compact
  /// voice-call timer visible while Flutter is in the background.
  Future<bool> ensureSystemOverlayPermission() async {
    if (!_supportsNativeBridge ||
        defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>(
            'ensureSystemOverlayPermission',
          ) ??
          false;
    } on PlatformException catch (error) {
      debugPrint('CallPlatformService ensureSystemOverlayPermission: $error');
      return false;
    } on MissingPluginException catch (error) {
      debugPrint(
        'CallPlatformService ensureSystemOverlayPermission unavailable: $error',
      );
      return false;
    }
  }

  Future<bool> enterPictureInPicture() async {
    if (!_supportsNativeBridge) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('enterPictureInPicture') ??
          false;
    } on PlatformException catch (error) {
      debugPrint('CallPlatformService enterPictureInPicture: $error');
      return false;
    } on MissingPluginException catch (error) {
      debugPrint(
          'CallPlatformService enterPictureInPicture unavailable: $error');
      return false;
    }
  }

  Future<bool> setBackgroundBlur({
    required String trackId,
    required bool enabled,
  }) async {
    if (!_supportsNativeBridge ||
        defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>(
            'setBackgroundBlur',
            <String, dynamic>{
              'trackId': trackId,
              'enabled': enabled,
            },
          ) ??
          false;
    } on PlatformException catch (error) {
      debugPrint('CallPlatformService setBackgroundBlur: $error');
      return false;
    } on MissingPluginException catch (error) {
      debugPrint('CallPlatformService setBackgroundBlur unavailable: $error');
      return false;
    }
  }

  Future<bool> showSystemVideoEffects() async {
    if (!_supportsNativeBridge || defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>('showSystemVideoEffects') ??
          false;
    } on PlatformException catch (error) {
      debugPrint('CallPlatformService showSystemVideoEffects: $error');
      return false;
    } on MissingPluginException catch (error) {
      debugPrint(
        'CallPlatformService showSystemVideoEffects unavailable: $error',
      );
      return false;
    }
  }

  Future<dynamic> _handlePlatformCall(MethodCall call) async {
    switch (call.method) {
      case 'hangUp':
        onHangUpRequested?.call();
        return null;
      case 'answerCall':
        onAnswerRequested?.call();
        return null;
      case 'restoreCall':
        onRestoreCallRequested?.call();
        return null;
      case 'preparePictureInPicture':
        onPreparePictureInPicture?.call();
        return null;
      case 'pictureInPictureModeChanged':
        final arguments = call.arguments;
        final inPictureInPicture = arguments is Map
            ? arguments['inPictureInPicture'] == true
            : arguments == true;
        onPictureInPictureModeChanged?.call(inPictureInPicture);
        return null;
      default:
        throw MissingPluginException('Unsupported call method: ${call.method}');
    }
  }
}
