import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:open_chat_app/models/mock_service_category.dart';
import 'package:open_chat_app/screens/mock_service_screen.dart';

void main() {
  testWidgets('flight mock flow reaches passenger form and success',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const MockServiceScreen(category: MockServiceCategory.flights),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('飞机票查询'), findsOneWidget);
    await tester.tap(find.text('飞机票查询'));
    await tester.pumpAndSettle();

    expect(find.text('航班列表'), findsOneWidget);
    expect(find.text('免费'), findsWidgets);
    expect(find.textContaining('¥'), findsNothing);
    await tester.tap(find.text('ZH9327 · Airbus A320'));
    await tester.pumpAndSettle();

    expect(find.text('选择价格方案'), findsOneWidget);
    expect(find.text('免费'), findsWidgets);
    await tester.tap(find.text('订').first);
    await tester.pumpAndSettle();

    expect(find.text('乘机人信息'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '测试乘机人');
    await tester.enterText(fields.at(1), '440300199001011234');
    await tester.enterText(fields.at(2), '13800138000');
    await tester.tap(find.textContaining('提交订单'));
    await tester.pumpAndSettle();

    expect(find.text('提交成功'), findsWidgets);
    expect(find.text('测试乘机人'), findsOneWidget);
  });

  testWidgets('taxi mock flow reaches booker form and success', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const MockServiceScreen(category: MockServiceCategory.taxi),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('查询车辆'), findsOneWidget);
    await tester.tap(find.text('查询车辆'));
    await tester.pumpAndSettle();

    expect(find.text('可选车辆'), findsOneWidget);
    expect(find.text('免费'), findsWidgets);
    expect(find.textContaining('¥'), findsNothing);
    await tester.tap(find.text('BYD Han EV'));
    await tester.pumpAndSettle();

    expect(find.text('用车详情'), findsOneWidget);
    await tester.tap(find.textContaining('订 · 免费'));
    await tester.pumpAndSettle();

    expect(find.text('预订人信息'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '测试预订人');
    await tester.enterText(fields.at(1), '13800138000');
    await tester.tap(find.textContaining('提交订单'));
    await tester.pumpAndSettle();

    expect(find.text('提交成功'), findsWidgets);
    expect(find.text('测试预订人'), findsOneWidget);
  });
}

Widget _testApp(Widget child) => MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
