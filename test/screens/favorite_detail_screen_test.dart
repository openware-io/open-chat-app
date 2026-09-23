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
import 'package:open_chat_app/screens/favorite_detail_screen.dart';

/// 收藏详情页行为：内容自渲染 +「查看原消息」按服务端状态决定是否跳转（fail closed）。
class _FakeFavoriteRepository implements FavoriteRepository {
  _FakeFavoriteRepository(this.source);

  FavoriteSource source;
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
      const <ChatMessage>[];

  @override
  Future<FavoriteSource> lookupSource(String msgId) async => source;
}

ChatMessage _favorite({
  String msgType = 'text',
  String content = '收藏时保存的内容',
  String chatType = 'group',
  String toId = 'g1',
  int from = 7,
}) {
  return ChatMessage(
    msgId: 'm1',
    from: from,
    fromUsername: '张三',
    toId: toId,
    chatType: chatType,
    msgType: msgType,
    content: content,
    timestamp: DateTime.utc(2024, 5, 1, 10),
  );
}

/// 挂载「列表页 → 收藏详情页」的最小路由，可选捕获详情页 pop 的返回值。
Future<void> _pumpDetail(
  WidgetTester tester, {
  required ChatMessage message,
  required _FakeFavoriteRepository repository,
  void Function(FavoriteDetailResult?)? onResult,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorage(prefs);

  final router = GoRouter(
    initialLocation: '/favorites',
    routes: [
      GoRoute(
        path: '/favorites',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Builder(
              builder: (ctx) => TextButton(
                onPressed: () async {
                  final result = await ctx.push<FavoriteDetailResult>(
                    '/favorites/detail',
                    extra: message,
                  );
                  onResult?.call(result);
                },
                child: const Text('打开收藏详情'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/favorites/detail',
        builder: (context, state) =>
            FavoriteDetailScreen(message: state.extra! as ChatMessage),
      ),
      GoRoute(
        path: '/chat/:chatType/:peerId',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('chat-room-page')),
        ),
      ),
      GoRoute(
        path: '/forward-message',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('forward-page')),
        ),
      ),
    ],
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<FavoriteRepository>.value(value: repository),
        Provider<LocalStorage>.value(value: storage),
      ],
      child: MaterialApp.router(
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    ),
  );
  await tester.tap(find.text('打开收藏详情'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('详情页渲染收藏自身保存的内容（不依赖原消息）', (tester) async {
    final repository =
        _FakeFavoriteRepository(FavoriteSource.unavailable);
    await _pumpDetail(
      tester,
      message: _favorite(),
      repository: repository,
    );

    expect(find.text('收藏详情'), findsOneWidget);
    expect(find.text('收藏时保存的内容'), findsOneWidget);
    expect(find.text('文本'), findsOneWidget);
    expect(find.text('查看原消息'), findsOneWidget);
    expect(find.text('转发'), findsOneWidget);
    expect(find.text('多选'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);
  });

  testWidgets('AVAILABLE 才跳转原会话', (tester) async {
    final repository = _FakeFavoriteRepository(
      const FavoriteSource(
        state: FavoriteSourceState.available,
        conversationId: 'conv:group:g1',
        messageId: 'm1',
      ),
    );
    await _pumpDetail(tester, message: _favorite(), repository: repository);

    await tester.tap(find.text('查看原消息'));
    await tester.pumpAndSettle();

    expect(find.text('chat-room-page'), findsOneWidget);
  });

  testWidgets('MESSAGE_DELETED 留在本页并给出中文说明', (tester) async {
    final repository = _FakeFavoriteRepository(
      const FavoriteSource(state: FavoriteSourceState.messageDeleted),
    );
    await _pumpDetail(tester, message: _favorite(), repository: repository);

    await tester.tap(find.text('查看原消息'));
    await tester.pumpAndSettle();

    expect(find.text('chat-room-page'), findsNothing);
    expect(find.text('收藏时保存的内容'), findsOneWidget);
    expect(find.text('原消息已被删除，只能查看收藏内容'), findsWidgets);

    // 放掉 toast 计时器，避免测试结束时仍有 pending timer。
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('CONVERSATION_UNAVAILABLE / NO_PERMISSION 留在本页并给出中文说明',
      (tester) async {
    for (final entry in const {
      FavoriteSourceState.conversationUnavailable: '原会话已不可用，只能查看收藏内容',
      FavoriteSourceState.noPermission: '你已没有权限查看原消息，只能查看收藏内容',
    }.entries) {
      final repository = _FakeFavoriteRepository(
        FavoriteSource(state: entry.key),
      );
      await _pumpDetail(tester, message: _favorite(), repository: repository);

      await tester.tap(find.text('查看原消息'));
      await tester.pumpAndSettle();

      expect(find.text('chat-room-page'), findsNothing);
      expect(find.text(entry.value), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
    }
  });

  testWidgets('LOOKUP_UNAVAILABLE（查询失败）留在本页且绝不盲跳', (tester) async {
    final repository = _FakeFavoriteRepository(FavoriteSource.unavailable);
    await _pumpDetail(tester, message: _favorite(), repository: repository);

    await tester.tap(find.text('查看原消息'));
    await tester.pumpAndSettle();

    expect(find.text('chat-room-page'), findsNothing);
    expect(find.text('暂时无法确认原消息是否可查看，请稍后重试'), findsWidgets);
    expect(find.text('收藏时保存的内容'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('详情页「多选」回传 FavoriteDetailResult.enterMultiSelect', (tester) async {
    FavoriteDetailResult? popped;
    final repository = _FakeFavoriteRepository(FavoriteSource.unavailable);
    await _pumpDetail(
      tester,
      message: _favorite(),
      repository: repository,
      onResult: (result) => popped = result,
    );

    await tester.tap(find.text('多选'));
    await tester.pumpAndSettle();

    expect(popped, FavoriteDetailResult.enterMultiSelect);
  });

  testWidgets('详情页「删除」确认后调服务端并回传 removed', (tester) async {
    FavoriteDetailResult? popped;
    final repository = _FakeFavoriteRepository(FavoriteSource.unavailable);
    await _pumpDetail(
      tester,
      message: _favorite(),
      repository: repository,
      onResult: (result) => popped = result,
    );

    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();
    expect(find.text('确定删除该收藏？'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('删除'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.removed, ['m1']);
    expect(popped, FavoriteDetailResult.removed);

    await tester.pump(const Duration(seconds: 3));
  });
}
