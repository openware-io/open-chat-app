import 'dart:async';

import '../../core/app_lifecycle_observer.dart';

/// 应用内新消息顶栏提示控制器。
///
/// 只处理“应用在前台但用户不在对应会话”时的短时提示、节流和自动隐藏。
class ChatInAppBannerController {
  ChatInAppBannerController({required void Function() notifyChanged})
      : _notifyChanged = notifyChanged;

  static const Duration _visibleDuration = Duration(seconds: 3);
  static const Duration _throttleDuration = Duration(minutes: 1);

  final void Function() _notifyChanged;

  AppLifecycleObserver? _appLifecycle;
  Timer? _hideTimer;
  DateTime? _lastShownAt;
  bool _visible = false;

  bool get visible => _visible;

  void bindAppLifecycle(AppLifecycleObserver observer) {
    _appLifecycle = observer;
  }

  void trigger() {
    final lifecycle = _appLifecycle;
    if (lifecycle == null || !lifecycle.isForeground) return;

    final now = DateTime.now();
    final last = _lastShownAt;
    if (last != null && now.difference(last) < _throttleDuration) return;
    _lastShownAt = now;

    _hideTimer?.cancel();
    _visible = true;
    _notifyChanged();

    _hideTimer = Timer(_visibleDuration, () {
      _hideTimer = null;
      if (!_visible) return;
      _visible = false;
      _notifyChanged();
    });
  }

  void reset() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _lastShownAt = null;
    _visible = false;
  }
}
