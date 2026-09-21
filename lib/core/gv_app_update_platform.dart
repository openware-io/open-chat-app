import 'package:flutter/foundation.dart';

import 'env_config.dart';

/// 仅返回已纳入发布治理的平台；Web/Fuchsia 不发送 release-check。
String? gvClientReleasePlatformKey() {
  if (kIsWeb) return null;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'android';
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      return null;
    case TargetPlatform.fuchsia:
      return null;
  }
}

/// 发布渠道：正式构建查 stable，测试/开发构建查 internal。
/// 与 admin 后台「客户端发布」的渠道对齐，避免 App 查 stable 而后台发布到
/// internal 导致永远无更新提示。
String gvClientReleaseChannelKey() => EnvConfig.isProduction ? 'stable' : 'internal';
