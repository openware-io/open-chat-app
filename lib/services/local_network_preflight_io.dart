import 'dart:async';
import 'dart:io' show Platform, Socket;

import 'package:flutter/services.dart';

import '../core/config.dart';

const MethodChannel _channel = MethodChannel('com.gv.chat/local_network');

Future<void>? _pending;
bool _completed = false;

Future<void> requestLocalNetworkPreflightIfNeeded() async {
  if (!Platform.isIOS) return;
  if (_completed) return;
  final pending = _pending;
  if (pending != null) {
    await pending;
    return;
  }

  final request = _request();
  _pending = request;
  await request;
}

Future<void> _request() async {
  try {
    // 不论服务器是公网还是局域网，都在启动后先触发 iOS 网络权限预检。
    // Bonjour 用于触发 iOS 14+ 的「本地网络」系统授权框。
    try {
      await _channel.invokeMethod<void>('preflight');
    } catch (_) {
      // 继续底层网络握手；真实请求会给出可操作的网络错误。
    }

    // iOS 没有主动申请公网权限的 API。启动后只建立到服务器
    // 端口的 DNS/TCP 连接，不发送 HTTP，也不调用任何业务接口。
    // 首次系统弹窗中断连接时会在这里重试，避免中断登录 POST。
    if (await _prepareNetworkAccess()) {
      _completed = true;
    }
  } finally {
    _pending = null;
  }
}

Future<bool> _prepareNetworkAccess() async {
  final uri = Uri.tryParse(AppConfig.apiBase);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
  final port = uri.hasPort
      ? uri.port
      : uri.scheme.toLowerCase() == 'https'
          ? 443
          : 80;

  const attempts = 5;
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    if (await _openTransportOnce(uri.host, port)) return true;
  }
  return false;
}

Future<bool> _openTransportOnce(String host, int port) async {
  Socket? socket;
  try {
    socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 4),
    );
    return true;
  } catch (_) {
    return false;
  } finally {
    socket?.destroy();
  }
}
