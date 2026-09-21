import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:gv_chat_app/models/mock_service_category.dart';
import 'package:gv_chat_app/screens/mock_service_screen.dart';

void main() {
  testWidgets('hotel flow shows free rooms and check-in time', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const MockServiceScreen(category: MockServiceCategory.hotel),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A380酒店1'), findsOneWidget);
    await tester.tap(find.text('A380酒店1'));
    await tester.pumpAndSettle();

    expect(find.text('房型与价格'), findsOneWidget);
    expect(find.text('雅致大床房'), findsOneWidget);
    expect(find.text('免费'), findsWidgets);
    expect(find.textContaining('¥'), findsNothing);
    expect(find.textContaining('积分兑换'), findsNothing);
    expect(find.text('入住时间'), findsNothing);

    await tester.tap(find.text('雅致大床房'));
    await tester.pump();

    expect(find.text('入住时间'), findsOneWidget);
    expect(find.text('选择日期和时间'), findsOneWidget);
  });

  testWidgets('ktv flow shows packages and reveals arrival time after choice',
      (tester) async {
    await tester.pumpWidget(
      _testApp(
        const MockServiceScreen(category: MockServiceCategory.ktv),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A380KTV1'), findsOneWidget);
    await tester.tap(find.text('A380KTV1'));
    await tester.pumpAndSettle();

    expect(find.text('套餐与价格'), findsOneWidget);
    expect(find.text('双人欢唱套餐'), findsOneWidget);
    expect(find.text('免费'), findsWidgets);
    expect(find.textContaining('¥'), findsNothing);
    expect(find.text('到场时间'), findsNothing);

    await tester.tap(find.text('双人欢唱套餐'));
    await tester.pump();

    expect(find.text('到场时间'), findsOneWidget);
    expect(find.text('选择日期和时间'), findsOneWidget);
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
