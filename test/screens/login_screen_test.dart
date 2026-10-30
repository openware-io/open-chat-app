import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:open_chat_app/screens/login_screen.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, {String? initialUsername}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: LoginScreen(initialUsername: initialUsername),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('login form validates agreement and credentials', (tester) async {
    await pumpLogin(tester);

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.text('登录'), findsOneWidget);

    final loginButton =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, '登录'));
    expect(loginButton.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pump();

    expect(find.text('请先阅读并同意用户协议和隐私政策'), findsOneWidget);
    expect(find.text('请输入用户名'), findsWidgets);
    expect(find.text('请输入密码'), findsWidgets);

    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.widgetWithText(FilledButton, '登录'));
    await tester.pump();

    expect(find.text('请输入用户名'), findsWidgets);
    expect(find.text('请输入密码'), findsWidgets);
  });

  testWidgets('prefills the registered username but leaves password empty',
      (tester) async {
    await pumpLogin(tester, initialUsername: 'new-user');

    final fields =
        tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(fields[0].controller?.text, 'new-user');
    expect(fields[1].controller?.text, isEmpty);
  });

  testWidgets('password visibility can be toggled', (tester) async {
    await pumpLogin(tester);

    final passwordField = tester.widget<TextField>(
      find.byType(TextField).at(1),
    );
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byTooltip('显示密码'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).obscureText,
      isFalse,
    );
  });
}
