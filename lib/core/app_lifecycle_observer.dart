import 'dart:async';

import 'package:flutter/widgets.dart';

import '../services/socket_service.dart';

/// 监听应用前后台切换，协调 WebSocket 连接与推送。
class AppLifecycleObserver with WidgetsBindingObserver {
  AppLifecycleObserver(this._socket);

  final SocketService _socket;
  Future<void> Function()? onResumed;
  VoidCallback? onBackgrounded;

  /// 当前正在查看的会话 id（用于上报设备状态）。
  String? Function()? activeConversationId;

  /// 当前应用是否处于前台。
  bool _isForeground = true;
  bool get isForeground => _isForeground;

  void register() {
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isForeground = true;
        debugPrint('[Lifecycle] App resumed — ensuring WS connection');
        // Even a socket still marked connected can be half-open after a
        // network change or suspension. The service sends an immediate health
        // probe and reconnects if the server does not answer in time.
        _socket.reconnectIfNeeded();
        _reportState('foreground');
        final callback = onResumed;
        if (callback != null) unawaited(callback());
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        final wasForeground = _isForeground;
        _isForeground = false;
        debugPrint('[Lifecycle] App backgrounded');
        _reportState('background');
        if (wasForeground) onBackgrounded?.call();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isForeground = false;
        break;
    }
  }

  void _reportState(String appState) {
    _socket.emitAppState(appState,
        activeConversationId: activeConversationId?.call());
  }
}
