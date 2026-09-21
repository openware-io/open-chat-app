import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/local_storage.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:gv_chat_app/providers/mini_app_services_provider.dart';
import 'package:gv_chat_app/repositories/mini_app_services_repository.dart';
import 'package:gv_chat_app/screens/services_screen.dart';
import 'package:gv_core/gv_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('normalizes the A380 directory URL for WebView relative assets', () {
    expect(
      normalizeMiniProgramUrl('https://miniservice.dev.example.com/a380'),
      'https://miniservice.dev.example.com/a380/',
    );
    expect(
      normalizeMiniProgramUrl('https://miniservice.dev.example.com/a380/'),
      'https://miniservice.dev.example.com/a380/',
    );
    expect(
      normalizeMiniProgramUrl('https://www.miniservice.dev.example.com/a380'),
      'https://miniservice.dev.example.com/a380/',
    );
    expect(
      normalizeMiniProgramUrl('https://admin.dev.example.com/a380'),
      'https://miniservice.dev.example.com/a380/',
    );
    expect(
      normalizeMiniProgramUrl('https://admin.dev.example.com/b'),
      'https://miniservice.dev.example.com/b/',
    );
  });

  test('restores each category order and appends newly available services',
      () async {
    final repository = _FakeMiniAppServicesRepository(
      cachedCategories: [
        _category(['a', 'b', 'c'])
      ],
      refreshedCategories: [
        _category(['c', 'a', 'b', 'd'])
      ],
      savedOrders: const {
        '常用服务': ['c', 'a'],
      },
    );
    final provider = MiniAppServicesProvider(repository);

    provider.hydrateServiceOrdersFromCache();
    provider.hydrateFromCache();

    expect(_ids(provider), ['c', 'a', 'b']);

    await provider.refresh();

    expect(_ids(provider), ['c', 'a', 'b', 'd']);
  });

  test('reorders a category and persists the complete service id order',
      () async {
    final repository = _FakeMiniAppServicesRepository(
      cachedCategories: [
        _category(['a', 'b', 'c'])
      ],
    );
    final provider = MiniAppServicesProvider(repository)..hydrateFromCache();

    await provider.reorderCategoryItem('常用服务', 0, 2);

    expect(_ids(provider), ['b', 'c', 'a']);
    expect(repository.lastSavedOrders, {
      '常用服务': ['b', 'c', 'a'],
    });
  });

  testWidgets('long-press dragging a service icon reorders its category',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      LocalStorage.userKey: '{"id":7}',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final repository = _FakeMiniAppServicesRepository(
      refreshedCategories: [
        _category(['a', 'b', 'c'])
      ],
    );
    final provider = MiniAppServicesProvider(repository);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<LocalStorage>.value(value: storage),
          ChangeNotifierProvider<MiniAppServicesProvider>.value(
            value: provider,
          ),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ServicesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('服务 a')),
    );
    await tester.pump(const Duration(milliseconds: 700));
    await gesture.moveTo(tester.getCenter(find.text('服务 c')));
    await tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_ids(provider), ['b', 'c', 'a']);
  });
}

List<String> _ids(MiniAppServicesProvider provider) =>
    provider.categories.single.items.map((item) => item.id).toList();

MiniAppServiceCategory _category(List<String> ids) => MiniAppServiceCategory(
      typeName: '常用服务',
      items: [
        for (final id in ids)
          MiniAppServiceItem(
            id: id,
            name: '服务 $id',
            iconPath: '',
          ),
      ],
    );

class _FakeMiniAppServicesRepository implements MiniAppServicesRepository {
  _FakeMiniAppServicesRepository({
    this.cachedCategories = const [],
    this.refreshedCategories = const [],
    this.savedOrders = const {},
  });

  final List<MiniAppServiceCategory> cachedCategories;
  final List<MiniAppServiceCategory> refreshedCategories;
  final Map<String, List<String>> savedOrders;
  Map<String, List<String>>? lastSavedOrders;

  @override
  String errorMessage(Object error) => error.toString();

  @override
  List<MiniAppServiceCategory> loadCachedCategories() => cachedCategories;

  @override
  List<MiniAppServiceItem> loadPinnedItems() => const [];

  @override
  Map<String, List<String>> loadServiceOrders() => savedOrders;

  @override
  Future<List<MiniAppServiceCategory>> refreshCategories() async =>
      refreshedCategories;

  @override
  Future<void> savePinnedItems(List<MiniAppServiceItem> items) async {}

  @override
  Future<void> saveServiceOrders(Map<String, List<String>> orders) async {
    lastSavedOrders = {
      for (final entry in orders.entries) entry.key: [...entry.value],
    };
  }

  @override
  Future<List<MiniAppServiceItem>> searchServices(String keyword) async =>
      const [];
}
