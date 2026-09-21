import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/gv_app.dart';
import 'package:gv_chat_app/models/client_remote_settings.dart';
import 'package:gv_chat_app/providers/app_locale_provider.dart';
import 'package:gv_chat_app/providers/app_theme_mode_provider.dart';
import 'package:gv_chat_app/providers/client_remote_config_provider.dart';
import 'package:gv_chat_app/repositories/app_preferences_repository.dart';
import 'package:gv_chat_app/repositories/client_config_repository.dart';

void main() {
  testWidgets('smoke: real app root renders its initial route', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('GV Chat ready')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    final preferences = _FakeAppPreferencesRepository();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AppLocaleController(preferences),
          ),
          ChangeNotifierProvider(
            create: (_) => AppThemeModeController(preferences),
          ),
          ChangeNotifierProvider(
            create: (_) => ClientRemoteConfigProvider(
              _FakeClientConfigRepository(),
            ),
          ),
        ],
        child: GvChatApp(
          router: router,
          showGlobalOverlays: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('GV Chat ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAppPreferencesRepository implements AppPreferencesRepository {
  String? localeCode;
  String? themeModeCode;
  bool notifications = true;

  @override
  String? get appLocaleCode => localeCode;

  @override
  String? get appThemeModeCode => themeModeCode;

  @override
  bool get notificationsEnabled => notifications;

  @override
  Future<void> setAppLocaleCode(String? code) async => localeCode = code;

  @override
  Future<void> setAppThemeModeCode(String? code) async => themeModeCode = code;

  @override
  Future<void> setNotificationsEnabled(bool enabled) async =>
      notifications = enabled;
}

class _FakeClientConfigRepository implements ClientConfigRepository {
  @override
  Future<ClientRemoteSettings> fetchClientSettings() async =>
      ClientRemoteSettings.defaults;
}
