import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/gv_automation_keys.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:open_chat_app/screens/points_account_binding_screen.dart';

void main() {
  testWidgets('binds a phone points account with the mock code', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: PointsAccountBindingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('选择账号类型'), findsOneWidget);
    await tester.enterText(
      find.byKey(GvAutomationKeys.pointsAccountInput),
      '13800125689',
    );
    await tester.tap(
      find.byKey(GvAutomationKeys.pointsAccountRequestCode),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('输入验证码'), findsOneWidget);
    expect(find.textContaining('+86 138****5689'), findsOneWidget);

    await tester.enterText(
      find.byKey(GvAutomationKeys.pointsAccountOtpInput),
      '000000',
    );
    await tester.pump();
    await tester.tap(find.byKey(GvAutomationKeys.pointsAccountConfirm));
    await tester.pump();
    expect(find.text('验证码错误，请重新输入'), findsOneWidget);

    await tester.enterText(
      find.byKey(GvAutomationKeys.pointsAccountOtpInput),
      '548682',
    );
    await tester.pump();
    await tester.tap(find.byKey(GvAutomationKeys.pointsAccountConfirm));
    await tester.pumpAndSettle();

    expect(find.text('积分账号绑定成功'), findsOneWidget);
    expect(
      find.byKey(GvAutomationKeys.pointsAccountSuccessReturn),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('shows validation before requesting a code', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: PointsAccountBindingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(GvAutomationKeys.pointsAccountInput),
      '1234',
    );
    await tester.tap(
      find.byKey(GvAutomationKeys.pointsAccountRequestCode),
    );
    await tester.pump();

    expect(
      find.text('请输入有效的中国大陆手机号（11位数字）'),
      findsOneWidget,
    );
    expect(find.text('输入验证码'), findsNothing);
  });

  testWidgets('member number uses password verification instead of OTP', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: PointsAccountBindingScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('points-account-type-account')));
    await tester.pump();
    await tester.enterText(
      find.byKey(GvAutomationKeys.pointsAccountInput),
      '12456789',
    );
    expect(find.text('输入密码'), findsOneWidget);

    await tester.tap(
      find.byKey(GvAutomationKeys.pointsAccountRequestCode),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('输入密码验证'), findsOneWidget);
    expect(
      find.byKey(GvAutomationKeys.pointsAccountPasswordInput),
      findsOneWidget,
    );
    expect(find.byKey(GvAutomationKeys.pointsAccountOtpInput), findsNothing);

    await tester.enterText(
      find.byKey(GvAutomationKeys.pointsAccountPasswordInput),
      '654321',
    );
    await tester.pump();
    await tester.tap(find.byKey(GvAutomationKeys.pointsAccountConfirm));
    await tester.pump();
    expect(find.text('密码错误，请重新输入'), findsOneWidget);

    await tester.enterText(
      find.byKey(GvAutomationKeys.pointsAccountPasswordInput),
      '123456',
    );
    await tester.pump();
    await tester.tap(find.byKey(GvAutomationKeys.pointsAccountConfirm));
    await tester.pumpAndSettle();

    expect(find.text('积分账号绑定成功'), findsOneWidget);
  });
}
