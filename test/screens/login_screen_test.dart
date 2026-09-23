import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:open_chat_app/screens/login_screen.dart';

void main() {
  testWidgets('login form requires agreement and credentials', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: LoginScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('登录'), findsOneWidget);

    var loginButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '登录'),
    );
    expect(loginButton.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    loginButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '登录'),
    );
    expect(loginButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pump();

    expect(find.text('请输入用户名和密码'), findsOneWidget);
  });

  testWidgets('prefills the registered username but leaves password empty',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: LoginScreen(initialUsername: 'new-user'),
      ),
    );
    await tester.pumpAndSettle();

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller?.text, 'new-user');
    expect(fields[1].controller?.text, isEmpty);
  });
}
