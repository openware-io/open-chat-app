import 'package:flutter/services.dart';

/// 私密聊天 / 私密群聊的防截图、防录屏控制。
///
/// - Android：`WindowManager.LayoutParams.FLAG_SECURE` 真正阻止（截图失败、录屏黑屏）。
/// - iOS：系统不允许真正阻止，只能检测到截图/录屏后通过 [captureListener] 通知端侧提醒。
class SecureScreen {
  SecureScreen._();

  static const MethodChannel _channel =
      MethodChannel('com.gv.chat/secure_screen');

  /// 截图/录屏检测回调：`type` 为 `screenshot` 或 `recording`（仅 iOS 触发）。
  static void Function(String type)? captureListener;

  static bool _handlerInstalled = false;

  static void _ensureHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onCaptureDetected') {
        final args = call.arguments;
        final type = (args is Map) ? (args['type']?.toString() ?? '') : '';
        captureListener?.call(type);
      }
      return null;
    });
  }

  /// 注册/注销截图录屏检测回调。
  static void setCaptureListener(void Function(String type)? listener) {
    captureListener = listener;
    if (listener != null) _ensureHandler();
  }

  /// 开启/关闭防截图（私密会话进入时开启、离开时关闭）。
  static Future<void> setSecure(bool secure) async {
    _ensureHandler();
    try {
      await _channel.invokeMethod<void>('setSecure', {'secure': secure});
    } on MissingPluginException {
      // 平台未注册该通道（如桌面/测试环境）：忽略。
    } catch (_) {
      // 调用失败不影响主流程。
    }
  }
}
