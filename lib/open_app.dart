import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';

import 'core/app_colors.dart';
import 'core/app_theme.dart';
import 'core/immersive_system_ui.dart';
import 'widgets/in_app_new_message_banner.dart';
import 'widgets/incoming_call_overlay.dart';
import 'widgets/active_call_overlay.dart';
import 'providers/app_locale_provider.dart';
import 'providers/app_theme_mode_provider.dart';
import 'providers/client_remote_config_provider.dart';
import 'providers/client_release_coordinator.dart';
import 'widgets/client_release_blocker.dart';

class GvChatApp extends StatelessWidget {
  const GvChatApp({
    super.key,
    required this.router,
    this.showGlobalOverlays = true,
  });

  final GoRouter router;

  /// 生产环境保持开启；Widget 测试可关闭依赖通话/聊天 Provider 的全局浮层，
  /// 只验证应用根组件、主题、本地化和路由是否能够正常装配。
  final bool showGlobalOverlays;

  @override
  Widget build(BuildContext context) {
    final remote = context.watch<ClientRemoteConfigProvider>();
    final clientRelease = context.watch<ClientReleaseCoordinator?>();
    final appLocale = context.watch<AppLocaleController>();
    final appThemeMode = context.watch<AppThemeModeController>();
    return MaterialApp.router(
      title: remote.appDisplayName,
      debugShowCheckedModeBanner: false,
      locale: appLocale.materialLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('zh'),
      ],
      localeResolutionCallback: (deviceLocale, supportedLocales) {
        if (appLocale.materialLocale != null) {
          return appLocale.materialLocale!;
        }
        final lang = deviceLocale?.languageCode ?? '';
        if (lang.startsWith('zh')) return const Locale('zh');
        return const Locale('en');
      },
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(
        brightness: Brightness.light,
      ),
      darkTheme: buildAppTheme(
        brightness: Brightness.dark,
      ),
      themeMode: appThemeMode.themeMode,
      routerConfig: router,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        GvShadows.updateBrightness(brightness);
        return GvImmersiveSystemUi(
          brightness: brightness,
          child: CupertinoTheme(
            data: CupertinoThemeData(
              brightness: brightness,
              primaryColor: AppColors.primary,
              scaffoldBackgroundColor: AppColors.bgPage,
              barBackgroundColor: AppColors.bgWhite,
              applyThemeToAll: true,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                GvUnfocusOnTapOutside(
                  child: child ?? const SizedBox.shrink(),
                ),
                if (showGlobalOverlays) const InAppNewMessageBanner(),
                if (showGlobalOverlays) const IncomingCallOverlay(),
                if (showGlobalOverlays) ActiveCallOverlay(router: router),
                if (clientRelease != null)
                  ClientReleaseBlocker(coordinator: clientRelease),
              ],
            ),
          ),
        );
      },
    );
  }
}
