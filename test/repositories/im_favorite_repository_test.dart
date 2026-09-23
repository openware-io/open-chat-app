import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:open_chat_app/core/local_storage.dart';
import 'package:open_chat_app/models/favorite_models.dart';
import 'package:open_chat_app/repositories/im_favorite_repository.dart';
import 'package:open_chat_app/services/api_client.dart';
import 'package:open_chat_app/services/im_api.dart';

/// 收藏仓库契约：批量收藏请求体 / 原消息可用性解析 / 查询失败 fail closed。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient apiClient;
  late ImFavoriteRepository repository;
  final captured = <({String method, String path, Map<String, dynamic> body})>[];

  /// 每个用例自定义响应：返回 null 表示按 500 失败。
  Map<String, dynamic>? Function(RequestOptions options) respond =
      (_) => const <String, dynamic>{};

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    apiClient = ApiClient(LocalStorage(prefs));
    captured.clear();
    respond = (_) => const <String, dynamic>{};
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured.add((
            method: options.method.toUpperCase(),
            path: options.path,
            body: Map<String, dynamic>.from(options.data as Map? ?? const {}),
          ));
          final data = respond(options);
          if (data == null) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.badResponse,
                response: Response<dynamic>(
                  requestOptions: options,
                  statusCode: 500,
                ),
              ),
            );
            return;
          }
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              statusCode: 200,
              data: data,
            ),
          );
        },
      ),
    );
    repository = ImFavoriteRepository(ImApi(apiClient));
  });

  test('addFavorites 走 POST /favorites/batch 且请求体与单条收藏同字段', () async {
    respond = (_) => const {
          'created': 2,
          'skipped': 1,
          'items': [
            {'messageId': 'm1', 'created': true},
            {'messageId': 'm2', 'created': true},
            {'messageId': 'm3', 'created': false},
          ],
        };

    final result = await repository.addFavorites(
      peerId: '8',
      chatType: 'private',
      messageIds: const ['m1', 'm2', 'm3'],
    );

    final request = captured.single;
    expect(request.method, 'POST');
    expect(request.path, contains('/favorites/batch'));
    expect(request.body['peerId'], '8');
    expect(request.body['chatType'], 'private');
    expect(request.body['messageIds'], ['m1', 'm2', 'm3']);
    expect(result.created, 2);
    expect(result.skipped, 1);
  });

  test('lookupSource 按 msgId 查询并解析 AVAILABLE', () async {
    respond = (_) => const {
          'state': 'AVAILABLE',
          'conversationId': 'conv:private:1:8',
          'messageId': 'm1',
        };

    final source = await repository.lookupSource('m1');

    final request = captured.single;
    expect(request.method, 'GET');
    expect(request.path, contains('/favorites/m1/source'));
    expect(source.state, FavoriteSourceState.available);
    expect(source.canOpenOriginal, isTrue);
    expect(source.conversationId, 'conv:private:1:8');
    expect(source.messageId, 'm1');
  });

  test('lookupSource 解析 MESSAGE_DELETED / CONVERSATION_UNAVAILABLE / NO_PERMISSION 均不可跳转', () async {
    for (final entry in const {
      'MESSAGE_DELETED': FavoriteSourceState.messageDeleted,
      'CONVERSATION_UNAVAILABLE': FavoriteSourceState.conversationUnavailable,
      'NO_PERMISSION': FavoriteSourceState.noPermission,
    }.entries) {
      captured.clear();
      respond = (_) => {'state': entry.key};
      final source = await repository.lookupSource('m1');
      expect(source.state, entry.value);
      expect(source.canOpenOriginal, isFalse);
    }
  });

  test('lookupSource 请求失败时返回 LOOKUP_UNAVAILABLE（fail closed，不抛异常）', () async {
    respond = (_) => null;

    final source = await repository.lookupSource('m1');

    expect(source.state, FavoriteSourceState.lookupUnavailable);
    expect(source.canOpenOriginal, isFalse);
    expect(source.conversationId, isNull);
    expect(source.messageId, isNull);
  });

  test('lookupSource 遇到未知 state 也按 LOOKUP_UNAVAILABLE 处理', () async {
    respond = (_) => const {'state': 'WHATEVER'};

    final source = await repository.lookupSource('m1');

    expect(source.state, FavoriteSourceState.lookupUnavailable);
    expect(source.canOpenOriginal, isFalse);
  });

  test('listFavorites 用列表响应里自带的收藏内容解析（无需 favoriteId）', () async {
    respond = (_) => const {
          'items': [
            {
              'msgId': 'm1',
              'senderId': 7,
              'senderUsername': '张三',
              'msgType': 'text',
              'content': '收藏时保存的内容',
              'peerId': '9',
              'chatType': 'private',
              'timestamp': '2024-05-01T10:00:00Z',
            },
          ],
        };

    final items = await repository.listFavorites();

    expect(items, hasLength(1));
    expect(items.first.msgId, 'm1');
    expect(items.first.from, 7);
    expect(items.first.fromUsername, '张三');
    expect(items.first.content, '收藏时保存的内容');
    // 收藏记录存的是会话 peerId，归一化到 toId 供跳转使用。
    expect(items.first.toId, '9');
    expect(items.first.chatType, 'private');
  });
}
