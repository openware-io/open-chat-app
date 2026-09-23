import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:open_chat_app/core/local_storage.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:open_chat_app/models/chat_message.dart';
import 'package:open_chat_app/models/favorite_models.dart';
import 'package:open_chat_app/repositories/favorite_repository.dart';
import 'package:open_chat_app/screens/favorites_screen.dart';

/// 收藏列表页：类型筛选、点击进详情、长按进入多选。
class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository(this.items);

  final List<ChatMessage> items;
  final List<String> removed = <String>[];

  @override
  Future<void> addFavorite({
    required String msgId,
    required String peerId,
    required String chatType,
  }) async {}

  @override
  Future<FavoriteBatchResult> addFavorites({
    required String peerId,
    required String chatType,
    required List<String> messageIds,
  }) async =>
      FavoriteBatchResult(created: messageIds.length, skipped: 0);

  @override
  Future<void> removeFavorite(String msgId) async => removed.add(msgId);

  @override
  Future<List<ChatMessage>> listFavorites({
    int page = 1,
    int pageSize = 20,
  }) async =>
      page == 1 ? items : const <ChatMessage>[];

  @override
  Future<FavoriteSource> lookupSource(String msgId) async =>
      FavoriteSource.unavailable;
}

ChatMessage _favorite(String msgId, String msgType, String content) {
  return ChatMessage(
    msgId: msgId,
    from: 7,
    fromUsername: '张三',
    toId: 'g1',
    chatType: 'group',
    msgType: msgType,
    content: content,
    timestamp: DateTime.utc(2024, 5, 1, 10),
  );
}

Future<void> _pumpList(
  WidgetTester tester, {
  required _FakeFavoriteRepository repository,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: '/favorites',
    routes: [
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/favorites/detail',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('favorite-detail-page')),
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<FavoriteRepository>.value(value: repository),
        Provider<LocalStorage>.value(value: LocalStorage(prefs)),
      ],
      child: MaterialApp.router(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('列表加载收藏并支持类型筛选', (tester) async {
    final repository = _FakeFavoriteRepository([
      _favorite('m1', 'text', '第一条文本收藏'),
      _favorite('m2', 'image', '{"url":"https://cdn.example.com/a.png"}'),
      _favorite('m3', 'file', '{"name":"报告.pdf","url":""}'),
    ]);
    await _pumpList(tester, repository: repository);

    expect(find.text('第一条文本收藏'), findsOneWidget);
    expect(find.text('[图片]'), findsOneWidget);
    expect(find.text('[文件] 报告.pdf'), findsOneWidget);

    // 类型筛选：只看图片。
    await tester.tap(find.text('图片'));
    await tester.pumpAndSettle();
    expect(find.text('[图片]'), findsOneWidget);
    expect(find.text('第一条文本收藏'), findsNothing);
    expect(find.text('[文件] 报告.pdf'), findsNothing);

    // 切回全部。
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(find.text('第一条文本收藏'), findsOneWidget);
  });

  testWidgets('点击收藏进入收藏详情页（不再跳原会话）', (tester) async {
    final repository = _FakeFavoriteRepository([
      _favorite('m1', 'text', '第一条文本收藏'),
    ]);
    await _pumpList(tester, repository: repository);

    await tester.tap(find.text('第一条文本收藏'));
    await tester.pumpAndSettle();

    expect(find.text('favorite-detail-page'), findsOneWidget);
  });

  testWidgets('长按进入多选，底部提供转发/删除', (tester) async {
    final repository = _FakeFavoriteRepository([
      _favorite('m1', 'text', '第一条文本收藏'),
      _favorite('m2', 'text', '第二条文本收藏'),
    ]);
    await _pumpList(tester, repository: repository);

    await tester.longPress(find.text('第一条文本收藏'));
    await tester.pumpAndSettle();

    expect(find.text('已选 1 条'), findsOneWidget);
    expect(find.text('转发'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);

    // 再点第二条 → 选中 2 条。
    await tester.tap(find.text('第二条文本收藏'));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 条'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('收藏'), findsOneWidget);
  });
}
