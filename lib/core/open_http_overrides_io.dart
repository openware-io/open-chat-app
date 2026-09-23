import 'dart:io';

import 'package:flutter/foundation.dart';

import 'config.dart';

/// 在调试模式下，对与 [AppConfig.apiBase] **同主机** 的 HTTPS 自签名证书放行；
/// 若需在 profile/release 连内网 HTTPS，请使用：
/// `--dart-define=OPEN_TRUST_SELF_SIGNED=true`（会信任所有主机，仅建议内测）。
void gvSetupHttpOverrides() {
  HttpOverrides.global = _GvHttpOverrides();
}

final class _GvHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (cert, host, port) => _trustHost(host);
    return client;
  }

  bool _trustHost(String host) {
    const trustAll =
        bool.fromEnvironment('OPEN_TRUST_SELF_SIGNED', defaultValue: false);
    if (trustAll) return true;

    final api = Uri.tryParse(AppConfig.apiBase);
    if (api != null && api.host.isNotEmpty && host == api.host && kDebugMode) {
      return true;
    }
    return false;
  }
}
