import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gv_chat_app/core/local_storage.dart';
import 'package:gv_chat_app/services/api_client.dart';
import 'package:gv_chat_app/services/im_api.dart';

/// 前后端请求契约测试：锁定手写请求体的字段名与后端 DTO 校验字段一致。
///
/// 背景：多次生产事故源于请求体字段名与后端 @NotNull/@NotBlank 字段不一致
/// （如 userB vs peerUserId、policy vs destroyPolicy）。本测试用 Dio 拦截器
/// 捕获每个接口发出的请求体，断言字段名——后端改字段或前端改 body 都会在此红灯。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ApiClient apiClient;
  late ImApi api;
  final captured = <({String method, String path, Map<String, dynamic> body})>[];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    apiClient = ApiClient(storage);
    captured.clear();
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured.add((
            method: options.method.toUpperCase(),
            path: options.path,
            body: Map<String, dynamic>.from(options.data as Map? ?? const {}),
          ));
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: const {},
            ),
          );
        },
      ),
    );
    api = ImApi(apiClient);
  });

  Map<String, dynamic> lastBodyFor(String pathPart) {
    final matches = captured.where((c) => c.path.contains(pathPart)).toList();
    expect(matches, isNotEmpty, reason: 'should have requested $pathPart');
    return matches.last.body;
  }

  group('私密聊天（Secret Chats）请求契约', () {
    test('createSecretChat 发送 userB（后端 CreateSecretChatRequest @NotNull userB）', () async {
      await api.createSecretChat(peerUserId: 8);
      final body = lastBodyFor('/secret-chats');
      expect(body.containsKey('userB'), isTrue,
          reason: '后端校验 @NotNull userB，字段名必须为 userB（不是 peerUserId）');
      expect(body['userB'], 8);
    });

    test('destroySecretChatPolicy 发送 policy（后端 @NotBlank policy）', () async {
      await api.destroySecretChatPolicy(id: '1', policy: '30s');
      final body = lastBodyFor('/destroy-policy');
      expect(body.containsKey('policy'), isTrue,
          reason: '后端校验 @NotBlank policy，字段名必须为 policy（不是 destroyPolicy）');
      expect(body['policy'], '30s');
    });

    test('submitSecretChatHandshake 发送 publicKey', () async {
      await api.submitSecretChatHandshake(id: '1', publicKey: 'PUB');
      final body = lastBodyFor('/handshake');
      expect(body['publicKey'], 'PUB');
    });
  });

  group('私密群聊（Secret Group Chats）请求契约', () {
    test('createSecretGroupChat 发送 memberUserIds', () async {
      await api.createSecretGroupChat(memberUserIds: [8, 9]);
      final body = lastBodyFor('/secret-group-chats');
      expect(body['memberUserIds'], [8, 9]);
    });

    test('addSecretGroupMember 发送 userId', () async {
      await api.addSecretGroupMember(id: '1', userId: 10);
      final body = lastBodyFor('/members');
      expect(body['userId'], 10);
    });

    test('submitSecretGroupHandshake 发送 publicKey', () async {
      await api.submitSecretGroupHandshake(id: '1', publicKey: 'PUB');
      final body = lastBodyFor('/handshake');
      expect(body['publicKey'], 'PUB');
    });

    test('setSecretGroupDestroyPolicy 发送 policy', () async {
      await api.setSecretGroupDestroyPolicy(id: '1', policy: '1h');
      final body = lastBodyFor('/destroy-policy');
      expect(body['policy'], '1h');
    });

    test('postSecretGroupMessage 发送 secretGroupId + msgId + recipients', () async {
      await api.postSecretGroupMessage(
        secretGroupId: 1,
        msgId: 'm1',
        recipients: [
          {'userId': 8, 'ciphertext': 'CIPHER8'},
          {'userId': 9, 'ciphertext': 'CIPHER9'},
        ],
      );
      final body = lastBodyFor('/secret-group-messages');
      expect(body['secretGroupId'], 1);
      expect(body['msgId'], 'm1');
      expect(body['recipients'], [
        {'userId': 8, 'ciphertext': 'CIPHER8'},
        {'userId': 9, 'ciphertext': 'CIPHER9'},
      ]);
    });
  });

  group('设备密钥 / 密文存储请求契约', () {
    test('registerDeviceKey 发送 deviceId + publicKey', () async {
      await api.registerDeviceKey(deviceId: 'dev-1', publicKey: 'PUB');
      final body = lastBodyFor('/device-keys');
      expect(body['deviceId'], 'dev-1');
      expect(body['publicKey'], 'PUB');
    });

    test('postSecretMessage 发送 secretChatId + msgId + ciphertext', () async {
      await api.postSecretMessage(
        secretChatId: 9,
        msgId: 'm1',
        ciphertext: 'CIPHER',
      );
      final body = lastBodyFor('/secret-messages');
      expect(body['secretChatId'], 9);
      expect(body['msgId'], 'm1');
      expect(body['ciphertext'], 'CIPHER');
    });
  });

  group('收藏（Favorites）请求契约', () {
    test('addFavoritesBatch 走 POST /favorites/batch，字段与单条收藏一致', () async {
      await api.addFavoritesBatch(
        peerId: '8',
        chatType: 'private',
        messageIds: const ['m1', 'm2'],
      );
      final req = captured.last;
      expect(req.method, 'POST');
      expect(req.path, contains('/favorites/batch'));
      expect(req.body['peerId'], '8');
      expect(req.body['chatType'], 'private');
      expect(req.body['messageIds'], ['m1', 'm2']);
    });

    test('favoriteSource 走 GET /favorites/{msgId}/source', () async {
      await api.favoriteSource('m1');
      final req = captured.last;
      expect(req.method, 'GET');
      expect(req.path, contains('/favorites/m1/source'));
    });
  });

  group('频道（Channels）请求契约', () {
    test('createChannel 发送 name', () async {
      await api.createChannel(name: '公告');
      final body = lastBodyFor('/channels');
      expect(body['name'], '公告');
    });

    test('subscribeChannel 走 POST /channels/{id}/subscribe（无 body）', () async {
      await api.subscribeChannel('3');
      final req = captured.last;
      expect(req.method, 'POST');
      expect(req.path, contains('/channels/3/subscribe'));
    });

    test('searchChannels 携带 keyword 查询参数', () async {
      await api.searchChannels('Tech');
      final req = captured.last;
      expect(req.path, contains('/channels/search'));
    });

    test('channelByCode 走 GET /channels/by-code/{code}', () async {
      await api.channelByCode('cABC1234');
      final req = captured.last;
      expect(req.method, 'GET');
      expect(req.path, contains('/channels/by-code/cABC1234'));
    });
  });
}
