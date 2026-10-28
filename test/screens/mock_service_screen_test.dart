import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:open_chat_app/models/mock_service_category.dart';
import 'package:open_chat_app/screens/mock_service_screen.dart';

void main() {
  test('mock service category parses route values with a safe fallback', () {
    expect(
      MockServiceCategory.fromWireName('flashSale'),
      MockServiceCategory.flashSale,
    );
    expect(
      MockServiceCategory.fromWireName('unsupported'),
      MockServiceCategory.food,
    );
  });

  testWidgets('mock service action completes a local demo order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MockServiceScreen(category: MockServiceCategory.food),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Free'), findsWidgets);
    final action = find.text('Try now').first;
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();

    expect(find.text('Confirm demo'), findsOneWidget);
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('Completed'), findsWidgets);
    expect(find.textContaining('completed'), findsOneWidget);
  });

  testWidgets('bar mock follows list, venue, deal, checkout and success', (
    tester,
  ) async {
    // Mock 目录已统一为中性演示商户名（OpenChat + 品类 + 序号，见
    // `_buildVenueCatalog`）；跟随 l10n 品类名，避免文案调整后断言过期。
    final l10n = lookupAppLocalizations(const Locale('en'));
    final barName = 'OpenChat${l10n.servicesBar}1';
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MockServiceScreen(category: MockServiceCategory.bar),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(barName), findsOneWidget);
    await tester.tap(find.text(barName));
    await tester.pumpAndSettle();

    final buyNow = find.text('Buy now').first;
    await tester.ensureVisible(buyNow);
    await tester.tap(buyNow);
    await tester.pumpAndSettle();

    expect(find.text('Deal details'), findsOneWidget);
    await tester.tap(find.text('Order now'));
    await tester.pumpAndSettle();

    expect(find.text('Submit order'), findsOneWidget);
    await tester.tap(find.text('Place free order'));
    await tester.pumpAndSettle();

    expect(find.text('Order successful'), findsWidgets);
    expect(find.text('Free'), findsOneWidget);
  });

  testWidgets('foot bath mock uses the bar venue flow and assets', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('zh'));
    final footBathName = 'OpenChat${l10n.servicesMassage}1';
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MockServiceScreen(category: MockServiceCategory.massage),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(footBathName), findsOneWidget);
    await tester.tap(find.text(footBathName));
    await tester.pumpAndSettle();

    await tester.tap(find.text('抢购').first);
    await tester.pumpAndSettle();
    expect(find.text('套餐详情'), findsWidgets);

    await tester.tap(find.text('立即下单'));
    await tester.pumpAndSettle();
    expect(find.text('提交订单'), findsOneWidget);

    await tester.tap(find.text('免费下单'));
    await tester.pumpAndSettle();
    expect(find.text('下单成功'), findsWidgets);
  });
}
