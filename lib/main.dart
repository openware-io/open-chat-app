import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';

import 'app/app_dependencies.dart';
import 'core/gv_http_overrides.dart';
import 'core/immersive_system_ui.dart';
import 'gv_app.dart';
import 'services/local_network_preflight.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    final webrtcOptions = <String, dynamic>{};
    if (defaultTargetPlatform == TargetPlatform.android) {
      webrtcOptions['androidAudioConfiguration'] =
          AndroidAudioConfiguration.communication.toMap();
    }
    await WebRTC.initialize(options: webrtcOptions);
  }

  gvSetupHttpOverrides();
  await ImmersiveSystemUi.enable();
  final dependencies = await AppDependencies.create();

  runApp(
    MultiProvider(
      providers: dependencies.providers,
      child: GvChatApp(router: dependencies.router),
    ),
  );

  WidgetsBinding.instance.addPostFrameCallback((_) {
    // 首帧后立即触发 iOS 首次网络授权；登录/注册会复用同一个 pending。
    unawaited(LocalNetworkPreflight.requestIfNeeded());
    // 冷启动「分享」进 App：把排队中的分享内容带进「发送给」页。
    dependencies.openPendingSharedMedia();
  });
}
