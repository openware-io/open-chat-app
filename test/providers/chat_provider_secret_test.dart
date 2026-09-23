import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:open_chat_app/core/local_storage.dart';
import 'package:open_chat_app/database/chat_database.dart';
import 'package:open_chat_app/models/channel_models.dart';
import 'package:open_chat_app/models/friend_models.dart';
import 'package:open_chat_app/models/group_models.dart';
import 'package:open_chat_app/models/im_user.dart';
import 'package:open_chat_app/models/message_sync.dart';
import 'package:open_chat_app/models/secret_chat_models.dart';
import 'package:open_chat_app/models/secret_group_chat_models.dart';
import 'package:open_chat_app/providers/chat/chat_local_store.dart';
import 'package:open_chat_app/providers/chat_provider.dart';
import 'package:open_chat_app/providers/friend_provider.dart';
import 'package:open_chat_app/providers/group_provider.dart';
import 'package:open_chat_app/repositories/chat_repository.dart';
import 'package:open_chat_app/repositories/friend_repository.dart';
import 'package:open_chat_app/repositories/group_repository.dart';
import 'package:open_chat_app/services/api_client.dart';
import 'package:open_chat_app/services/e2ee/e2ee_manager.dart';
import 'package:open_chat_app/services/im_api.dart';
import 'package:open_core/open_core.dart' show GvSocketClient;

/// ChatProvider 私密聊天服务层测试（本地可重复，不依赖生产）。
///
/// 覆盖：未握手等待、握手后加密发送、本地插入不带 sending、
/// 解密合并、定时销毁等核心业务行为。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatProvider provider;
  late ChatDatabase database;
  late _FakeChatRepository chatRepo;
  late _SecretWireServer server;
  late E2eeManager e2ee;
  late String peerPublicKeyB64;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'im_user': '{"id": 100, "username": "sender"}',
      'client_release_installation_id': 'test-device-1',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    database = ChatDatabase.forTesting(NativeDatabase.memory());
    final local = ChatLocalStore(storage, database);

    // 服务端模拟：握手双方公钥 + 密文存储（真实加密闭环）。
    // 对方（接收方）的真实 X25519 公钥。
    final peerKeyPair = await X25519().newKeyPair();
    final peerPub = await peerKeyPair.extractPublicKey();
    peerPublicKeyB64 = base64Encode(peerPub.bytes);

    server = _SecretWireServer();
    final apiClient = ApiClient(storage);
    apiClient.dio.interceptors.add(server.interceptor);
    final imApi = ImApi(apiClient);
    e2ee = E2eeManager(imApi: imApi, preferences: prefs);

    chatRepo = _FakeChatRepository(imApi);
    final friend = FriendProvider(_FakeFriendRepository());
    final group = GroupProvider(_FakeGroupRepository());
    provider = ChatProvider(
      local,
      chatRepo,
      _FakeSocket(),
      friend,
      group,
      e2ee,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('sendSecretText', () {
    test('对方未握手（无公钥）时本地乐观展示并入队（不再返回 waitingForPeer）', () async {
      final result = await provider.sendSecretText(
        secretChatId: '1',
        text: 'hello',
      );
      expect(result, SecretSendResult.success);
      final messages = provider.messagesFor('1', 'secret');
      expect(messages, hasLength(1));
      expect(messages.single.status, 'pending');
    });

    test('双方握手后加密发送：密文不含明文，本地插入明文且非 sending', () async {
      server.setPeerPublicKey('1', peerPublicKeyB64);
      await provider.ensureSecretChatHandshake('1');

      final result = await provider.sendSecretText(
        secretChatId: '1',
        text: '机密消息内容',
      );

      expect(result, SecretSendResult.success);
      expect(server.ciphertexts, hasLength(1));
      expect(server.ciphertexts.single, isNot(contains('机密消息内容')),
          reason: '服务端只存密文，不得含明文');

      final messages = provider.messagesFor('1', 'secret');
      expect(messages, hasLength(1));
      expect(messages.single.content, '机密消息内容');
      expect(messages.single.status, isNot('sending'),
          reason: '私密消息走加密通道，不应出现普通通道的 sending 状态');
    });

    test('图片消息发送不产生 sending 占位，且载荷含媒体对象 id（媒体发送中事故回归）',
        () async {
      server.setPeerPublicKey('1', peerPublicKeyB64);
      await provider.ensureSecretChatHandshake('1');

      final result = await provider.sendSecretText(
        secretChatId: '1',
        text: '{"url":"http://img/1.jpg"}',
        msgType: 'image',
        mediaObjectIds: const ['obj-1'],
      );

      expect(result, SecretSendResult.success);
      final messages = provider.messagesFor('1', 'secret');
      expect(messages, hasLength(1));
      expect(messages.single.status, isNot('sending'),
          reason: '私密图片消息不得出现普通通道的 sending 占位');
      expect(messages.single.msgType, 'image');
      expect(messages.single.mediaObjectIds, ['obj-1']);
      // 服务端密文不含明文图片 JSON
      expect(server.ciphertexts.single, isNot(contains('http://img/1.jpg')));
    });
  });

  group('pullSecretMessages', () {
    test('发送方乐观消息与服务端拉取同 msgId 不重复（发两遍事故回归）', () async {
      server.setPeerPublicKey('1', peerPublicKeyB64);
      await provider.ensureSecretChatHandshake('1');
      await provider.sendSecretText(secretChatId: '1', text: '我的消息');
      final sent = server.ciphertexts.single;
      // 服务端返回刚发的这条（发送方轮询拉到自己）
      server.messages['1'] = [
        {
          'msgId': provider.messagesFor('1', 'secret').single.msgId,
          'fromUserId': 100,
          'seq': 1,
          'ciphertext': sent,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00Z',
        },
      ];

      await provider.pullSecretMessages('1', forceFull: true);

      expect(provider.messagesFor('1', 'secret'), hasLength(1),
          reason: '发送方乐观插入与轮询拉取同一条消息不得重复');
      expect(server.readAfterSeq['1'], isNull,
          reason: '拉取自己的消息不触发已读上报（不计时）');
    });

    test('接收方真正解密看到对方消息后才上报已读，销毁计时由已读触发', () async {
      server.setPeerPublicKey('1', peerPublicKeyB64);
      await provider.ensureSecretChatHandshake('1');
      provider.openChat('1', 'secret');
      // 用真实共享密钥生成一条「对方发来」的密文（同一共享密钥可解密）。
      await provider.sendSecretText(secretChatId: '1', text: '对方消息内容');
      final sent = server.ciphertexts.single;
      server.messages['1'] = [
        {
          'msgId': 'peer-msg-1',
          'fromUserId': 200,
          'seq': 7,
          'ciphertext': sent,
          'status': 'active',
          // 服务端实际返回无时区后缀的 UTC 时间串（LocalDateTime 序列化）：
          // 必须按 UTC 解析，裸 tryParse 会当本地时间导致 8 小时偏移。
          'createdAt': '2026-08-19T00:00:00',
        },
      ];

      await provider.pullSecretMessages('1', forceFull: true);
      // markSecretMessagesRead 是 unawaited 异步上报，等待其完成。
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // 本地 2 条：sendSecretText 的乐观消息 + 拉取到的对方消息。
      expect(provider.messagesFor('1', 'secret'), hasLength(2));
      expect(server.readAfterSeq['1'], 7,
          reason: '解密看到对方消息后应上报已读以开始销毁计时');
      final peerMsg = provider
          .messagesFor('1', 'secret')
          .firstWhere((m) => m.msgId == 'peer-msg-1');
      expect(peerMsg.timestamp.isUtc, isTrue,
          reason: '无时区时间串必须按 UTC 解析（否则本地时区偏移 8 小时）');
      expect(peerMsg.timestamp.hour, 0,
          reason: '2026-08-19T00:00:00 按 UTC 解析应为当天 0 点');
    });

    test('解密失败的消息不推进游标、不上报已读（未查阅不销毁、不丢失）', () async {
      server.setPeerPublicKey('1', peerPublicKeyB64);
      await provider.ensureSecretChatHandshake('1');
      provider.openChat('1', 'secret');
      await provider.sendSecretText(secretChatId: '1', text: '第一条');
      final good = server.ciphertexts.single;
      // 坏密文（本端无法解密）：seq=6；好密文 seq=7。
      final badCipher = base64Encode(utf8.encode('cannot-decrypt-this'));
      server.messages['1'] = [
        {
          'msgId': 'peer-msg-6',
          'fromUserId': 200,
          'seq': 6,
          'ciphertext': badCipher,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00Z',
        },
        {
          'msgId': 'peer-msg-7',
          'fromUserId': 200,
          'seq': 7,
          'ciphertext': good,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00Z',
        },
      ];

      await provider.pullSecretMessages('1', forceFull: true);

      // seq=6 解密失败：游标卡住，不上报已读；本地只有乐观插入的「第一条」。
      expect(server.readAfterSeq['1'], isNull,
          reason: '解密失败（未真正查阅）不得上报已读、不得开始销毁计时');
      expect(provider.messagesFor('1', 'secret'), hasLength(1),
          reason: '解密失败的消息暂不展示，等待密钥就绪后重试');
      // 再次拉取仍可重试（游标未越过失败消息），密钥就绪后解密成功并上报已读。
      server.messages['1']![0]['ciphertext'] = good;
      await provider.pullSecretMessages('1');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(provider.messagesFor('1', 'secret'), hasLength(3),
          reason: '密钥就绪后重试应能拉到之前失败的消息（不丢失）');
      expect(server.readAfterSeq['1'], 7,
          reason: '解密成功后上报已读，开始销毁计时');
    });

    test('服务端权威销毁：states 增量同步后本地移除（无需端侧定时器/无需重进）', () async {
      server.setPeerPublicKey('1', peerPublicKeyB64);
      await provider.ensureSecretChatHandshake('1');
      await provider.sendSecretText(secretChatId: '1', text: '对方消息');
      final sent = server.ciphertexts.single;
      const peerMsgId = 'peer-msg-1';
      server.messages['1'] = [
        {
          'msgId': peerMsgId,
          'fromUserId': 200,
          'seq': 7,
          'ciphertext': sent,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00',
        },
      ];

      // 1) 首次拉取：active 消息解密展示（服务端尚未销毁）。
      await provider.pullSecretMessages('1', forceFull: true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        provider.messagesFor('1', 'secret').any((m) => m.msgId == peerMsgId),
        isTrue,
        reason: '销毁前消息应展示',
      );

      // 2) 服务端调度器销毁（模拟）：销毁状态对端可达。
      server.destroyedAt[peerMsgId] = DateTime.now().toUtc();

      // 3) 轮询（pullSecretMessages 内联 states 增量同步）→ 本地移除。
      await provider.pullSecretMessages('1');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        provider.messagesFor('1', 'secret').any((m) => m.msgId == peerMsgId),
        isFalse,
        reason: '服务端权威销毁状态同步后本地应移除（不依赖端侧定时器）',
      );
    });

    test('销毁状态增量同步：已处理过的销毁不重复、离线重连可全量对齐', () async {
      server.setPeerPublicKey('1', peerPublicKeyB64);
      await provider.ensureSecretChatHandshake('1');
      await provider.sendSecretText(secretChatId: '1', text: '我的消息');
      final sent = server.ciphertexts.single;
      final myMsgId = provider.messagesFor('1', 'secret').single.msgId;
      server.messages['1'] = [
        {
          'msgId': myMsgId,
          'fromUserId': 100,
          'seq': 1,
          'ciphertext': sent,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00',
        },
      ];
      // 发送方本端无已读上报（自己的消息），销毁仅靠 states 增量同步。
      final destroyAt = DateTime.now().toUtc().add(const Duration(milliseconds: 120));
      server.destroyedAt[myMsgId] = destroyAt;
      server.destroyDeadlines['1'] = destroyAt;

      await provider.pullSecretMessages('1', forceFull: true);
      expect(provider.messagesFor('1', 'secret'), hasLength(1));

      // 服务端销毁 → 轮询同步移除。
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await provider.pullSecretMessages('1');
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(provider.messagesFor('1', 'secret'), isEmpty,
          reason: '发送方通过服务端销毁状态同步自动移除，无需重新进入');

      // 再次拉取：游标已推进，不再重复处理（消息不复活）。
      await provider.pullSecretMessages('1');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(provider.messagesFor('1', 'secret'), isEmpty,
          reason: '销毁状态增量同步幂等，消息不得复活');
    });

    test('接收方解密展示后会话列表更新最近消息预览（快捷展示回归）', () async {
      server.setPeerPublicKey('1', peerPublicKeyB64);
      await provider.ensureSecretChatHandshake('1');
      // 用真实共享密钥加密一条「对方发来」的不同内容消息（接收方视角无本地乐观插入）。
      final cipher = await e2ee.encryptForChat(
        '1',
        jsonEncode({'t': 'text', 'c': '接收方预览内容'}),
      );
      expect(cipher, isNotNull);
      server.messages['1'] = [
        {
          'msgId': 'peer-msg-1',
          'fromUserId': 200,
          'seq': 7,
          'ciphertext': cipher!,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00',
        },
      ];

      await provider.pullSecretMessages('1', forceFull: true);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final secretConvs = provider.conversations
          .where((c) => c.chatType == 'secret' && c.id == '1')
          .toList();
      expect(secretConvs, isNotEmpty,
          reason: '接收方解密展示后应存在私密会话条目');
      expect(secretConvs.single.lastMessage, contains('接收方预览内容'),
          reason: '会话列表应快捷展示最近一条私密消息');
    });

    test('服务端主动推 WS 销毁事件：在线端立即移除本地消息（无需等轮询）', () async {
      server.setPeerPublicKey('1', peerPublicKeyB64);
      await provider.ensureSecretChatHandshake('1');
      await provider.sendSecretText(secretChatId: '1', text: '对方消息');
      final sent = server.ciphertexts.single;
      const peerMsgId = 'peer-msg-1';
      server.messages['1'] = [
        {
          'msgId': peerMsgId,
          'fromUserId': 200,
          'seq': 7,
          'ciphertext': sent,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00',
        },
      ];
      await provider.pullSecretMessages('1', forceFull: true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        provider.messagesFor('1', 'secret').any((m) => m.msgId == peerMsgId),
        isTrue,
      );

      // 服务端销毁后主动推送 WS 事件（模拟 im-access-ws 推送的 payload）。
      provider.onSecretMessagesDestroyed({
        'secretChatId': '1',
        'msgIds': [peerMsgId],
        'destroyedAt': '2026-08-19T00:00:30Z',
      });

      expect(
        provider.messagesFor('1', 'secret').any((m) => m.msgId == peerMsgId),
        isFalse,
        reason: '在线端收到服务端主动销毁事件应立即移除本地消息',
      );
    });

    test('服务端推送撤回事件（reason=recalled）：本地渲染撤回墓碑而非删除', () async {
      server.setPeerPublicKey('1', peerPublicKeyB64);
      await provider.ensureSecretChatHandshake('1');
      await provider.sendSecretText(secretChatId: '1', text: '对方消息');
      final sent = server.ciphertexts.single;
      const peerMsgId = 'peer-msg-2';
      server.messages['1'] = [
        {
          'msgId': peerMsgId,
          'fromUserId': 200,
          'seq': 8,
          'ciphertext': sent,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00',
        },
      ];
      await provider.pullSecretMessages('1', forceFull: true);
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        provider.messagesFor('1', 'secret').any((m) => m.msgId == peerMsgId),
        isTrue,
      );

      // 服务端撤回后推送 reason=recalled 的销毁事件：应保留消息但置为撤回墓碑。
      provider.onSecretMessagesDestroyed({
        'secretChatId': '1',
        'msgIds': [peerMsgId],
        'destroyedAt': '2026-08-19T00:00:30Z',
        'reason': 'recalled',
      });

      final tombstone = provider
          .messagesFor('1', 'secret')
          .where((m) => m.msgId == peerMsgId)
          .toList();
      expect(tombstone, hasLength(1),
          reason: '撤回应保留消息并渲染墓碑，而非删除');
      expect(tombstone.single.msgType, 'recall');
      expect(tombstone.single.status, 'recalled');
    });
  });
}

/// 模拟服务端：握手公钥 + 密文存储 + 已读上报/销毁状态记录，真实完成 E2EE 加密闭环。
class _SecretWireServer {
  final Map<String, String> peerPublicKeys = {};
  final Map<String, String> myPublicKeys = {};
  final Map<String, List<Map<String, dynamic>>> messages = {};
  final Map<String, int> readAfterSeq = {};
  final Map<String, DateTime> destroyDeadlines = {};
  final Map<String, DateTime> destroyedAt = {};
  final List<String> ciphertexts = [];

  void setPeerPublicKey(String chatId, String peerPublicKey) {
    peerPublicKeys[chatId] = peerPublicKey;
  }

  InterceptorsWrapper get interceptor => InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.path;
          dynamic respond() {
            final body = Map<String, dynamic>.from(options.data as Map? ?? {});
            if (path.endsWith('/device-keys')) {
              return {'ok': true};
            }
            if (path.endsWith('/handshake')) {
              final chatId = _chatIdFromPath(path);
              myPublicKeys[chatId] = body['publicKey'] as String;
              final my = myPublicKeys[chatId];
              final peer = peerPublicKeys[chatId];
              return {
                'id': int.tryParse(chatId) ?? 0,
                'userA': 100,
                'userB': 200,
                'userAPublicKey': peer,
                'userBPublicKey': my,
                'handshakeState': (peer != null && my != null) ? 'ready' : 'pending',
                'safeCode': '',
                'destroyPolicy': 'off',
              };
            }
            if (path.contains('/secret-messages/') &&
                path.endsWith('/read') &&
                options.method.toUpperCase() == 'POST') {
              final chatId = _chatIdFromPath(path);
              final afterSeq = (body['afterSeq'] as num?)?.toInt() ?? 0;
              readAfterSeq[chatId] = afterSeq;
              return {
                'secretChatId': chatId,
                'counted': 1,
                'destroyAt': (destroyDeadlines[chatId] ??
                        DateTime.now().toUtc().add(const Duration(seconds: 30)))
                    .toIso8601String(),
              };
            }
            if (path.contains('/secret-messages/') &&
                path.endsWith('/status') &&
                options.method.toUpperCase() == 'GET') {
              final chatId = _chatIdFromPath(path);
              return {
                'secretChatId': chatId,
                'earliestDestroyAt':
                    destroyDeadlines[chatId]?.toIso8601String(),
              };
            }
            if (path.contains('/secret-messages/') &&
                path.endsWith('/states') &&
                options.method.toUpperCase() == 'GET') {
              final chatId = _chatIdFromPath(path);
              final afterRaw = options.queryParameters['afterDestroyAt']?.toString();
              final after = afterRaw == null || afterRaw.isEmpty
                  ? null
                  : DateTime.tryParse(afterRaw);
              final destroyed = <Map<String, dynamic>>[];
              for (final entry in destroyedAt.entries) {
                if (after != null && !entry.value.isAfter(after)) continue;
                destroyed.add({
                  'msgId': entry.key,
                  'destroyAt': entry.value.toIso8601String(),
                });
              }
              destroyed.sort((a, b) =>
                  (a['destroyAt'] as String).compareTo(b['destroyAt'] as String));
              return {'secretChatId': chatId, 'destroyed': destroyed};
            }
            if (path.endsWith('/secret-messages') &&
                options.method.toUpperCase() == 'POST') {
              ciphertexts.add(body['ciphertext'] as String);
              return {
                'msgId': body['msgId'],
                'seq': ciphertexts.length,
                'ciphertext': body['ciphertext'],
              };
            }
            if (path.contains('/secret-messages') &&
                options.method.toUpperCase() == 'GET') {
              final chatId = options.queryParameters['secretChatId']?.toString();
              return messages[chatId] ?? const [];
            }
            if (path.endsWith('/mine') && path.contains('secret-chats')) {
              return <Object>[];
            }
            return const {};
          }

          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: respond(),
            ),
          );
        },
      );

  String _chatIdFromPath(String path) {
    final parts = path.split('/');
    return parts.length >= 4 ? parts[parts.length - 2] : '0';
  }

  /// 用服务端持有的「对方公钥」+ 本端「我的私钥」？——服务端不做加密。
  /// 这里仅占位：真实加密由客户端完成，测试中用客户端密钥。
  Future<String> encryptForPeer(String chatId, String plaintext) async {
    // 通过真实 ImApi 客户端加密不可行（无私钥）；改为返回占位并在测试中
    // 用同一 E2eeManager 解密。由于密文需真实可解，这里直接用客户端流程：
    // 测试里由 ChatProvider.pullSecretMessages 前的 sendSecretText 生成密文。
    return plaintext;
  }
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository(this._imApi);

  final ImApi _imApi;

  @override
  Future<SecretChatInfo> secretChatInfo(String id) =>
      _imApi.secretChatInfo(id);

  @override
  Future<SecretChatInfo> submitSecretChatHandshake({
    required String id,
    required String publicKey,
  }) =>
      _imApi.submitSecretChatHandshake(id: id, publicKey: publicKey);

  @override
  Future<Map<String, dynamic>> postSecretMessage({
    required int secretChatId,
    required String msgId,
    required String ciphertext,
    List<String>? mediaObjectIds,
  }) =>
      _imApi.postSecretMessage(
        secretChatId: secretChatId,
        msgId: msgId,
        ciphertext: ciphertext,
        mediaObjectIds: mediaObjectIds,
      );

  @override
  Future<List<Map<String, dynamic>>> listSecretMessages({
    required int secretChatId,
    int afterSeq = 0,
    int limit = 50,
  }) =>
      _imApi.listSecretMessages(
        secretChatId: secretChatId,
        afterSeq: afterSeq,
        limit: limit,
      );

  @override
  Future<Map<String, dynamic>> markSecretMessagesRead({
    required int secretChatId,
    required int afterSeq,
  }) =>
      _imApi.markSecretMessagesRead(
        secretChatId: secretChatId,
        afterSeq: afterSeq,
      );

  @override
  Future<Map<String, dynamic>> secretChatDestroyStatus(int secretChatId) =>
      _imApi.secretChatDestroyStatus(secretChatId);

  @override
  Future<List<Map<String, dynamic>>> secretChatDestroyStates(
    int secretChatId, {
    String? afterDestroyAt,
    int limit = 100,
  }) =>
      _imApi.secretChatDestroyStates(
        secretChatId,
        afterDestroyAt: afterDestroyAt,
        limit: limit,
      );

  @override
  Future<void> recallSecretMessage({
    required int secretChatId,
    required String msgId,
  }) =>
      _imApi.recallSecretMessage(secretChatId: secretChatId, msgId: msgId);

  @override
  Future<void> deleteSecretMessage({
    required int secretChatId,
    required String msgId,
  }) =>
      _imApi.deleteSecretMessage(secretChatId: secretChatId, msgId: msgId);

  @override
  Future<SecretChatInfo> createSecretChat({
    required int peerUserId,
    String? publicKey,
  }) async =>
      SecretChatInfo(id: '9', peerUserId: peerUserId);

  @override
  Future<List<SecretChatInfo>> mySecretChats() async => const [];

  @override
  Future<SecretChatInfo> destroySecretChatPolicy({
    required String id,
    required String policy,
  }) async =>
      SecretChatInfo(id: id, destroyPolicy: policy);

  @override
  Future<void> deleteSecretChat(String id) async {}

  @override
  Future<Map<String, dynamic>> registerDeviceKey({
    required String deviceId,
    required String publicKey,
  }) async =>
      {'deviceId': deviceId};

  @override
  Future<List<Map<String, dynamic>>> myDeviceKeys() async => const [];

  @override
  Future<List<dynamic>> messageHistory({
    required String peerId,
    required String chatType,
    String? beforeMsgId,
    String? afterMsgId,
    int pageSize = 30,
  }) async =>
      const [];

  @override
  Future<List<dynamic>> messageHistoryCentered({
    required String peerId,
    required String chatType,
    required String centerMsgId,
    int beforeCount = 30,
    int afterCount = 30,
  }) async =>
      const [];

  @override
  Future<void> markRead(List<String> msgIds) async {}

  @override
  Future<MessageSyncPage> syncMessages({
    required int afterSyncSeq,
    int limit = 200,
  }) async =>
      MessageSyncPage(
        items: const [],
        nextSyncSeq: afterSyncSeq,
        hasMore: false,
      );

  @override
  Future<List<dynamic>> searchChatMessages({
    String? peerId,
    String? chatType,
    required String keyword,
    String msgType = 'text',
    int page = 1,
    int pageSize = 30,
    String? beforeMsgId,
  }) async =>
      const [];

  @override
  Future<void> deleteMessageForEveryone(String msgId) async {}

  @override
  Future<int> deleteMessagesForMe(List<String> msgIds) async => msgIds.length;

  @override
  Future<void> recallMessage(String msgId) async {}

  @override
  Future<Map<String, dynamic>> editMessage({
    required String msgId,
    required String newContent,
  }) async =>
      {};

  @override
  Future<int> unreadCount() async => 0;

  @override
  Future<List<({String conversationId, int count})>> unreadByConversation() async =>
      const [];

  @override
  Future<Map<String, dynamic>> clearPrivateChat(String peerId) async => {};

  @override
  Future<Map<String, dynamic>> clearGroupChat(String groupId) async => {};

  @override
  Future<ChannelInfo> createChannel({
    required String name,
    String? description,
  }) async =>
      ChannelInfo(id: '1', name: name);

  @override
  Future<List<ChannelInfo>> myChannels() async => const [];

  @override
  Future<ChannelInfo> channelInfo(String id) async =>
      ChannelInfo(id: id, name: '频道');

  @override
  Future<ChannelInfo> subscribeChannel(String id) async =>
      ChannelInfo(id: id, name: '频道');

  @override
  Future<void> unsubscribeChannel(String id) async {}

  @override
  Future<ChannelInfo> updateChannel(
    String id, {
    String? name,
    String? announcement,
  }) async =>
      ChannelInfo(id: id, name: name ?? '频道', description: announcement ?? '');

  @override
  Future<void> deleteChannel(String id) async {}

  @override
  Future<List<ChannelInfo>> searchChannels(String keyword, {int limit = 20}) async =>
      const [];

  @override
  Future<ChannelInfo> channelByCode(String code) async =>
      ChannelInfo(id: '1', name: '频道', code: code);

  @override
  Future<SecretGroupChatInfo> createSecretGroupChat({
    required List<int> memberUserIds,
  }) async =>
      const SecretGroupChatInfo(id: '1');

  @override
  Future<List<SecretGroupChatInfo>> mySecretGroupChats() async => const [];

  @override
  Future<SecretGroupChatInfo> secretGroupChatInfo(String id) async =>
      SecretGroupChatInfo(id: id);

  @override
  Future<SecretGroupChatInfo> addSecretGroupMember({
    required String id,
    required int userId,
  }) async =>
      SecretGroupChatInfo(id: id);

  @override
  Future<SecretGroupChatInfo> submitSecretGroupHandshake({
    required String id,
    required String publicKey,
  }) async =>
      SecretGroupChatInfo(id: id);

  @override
  Future<SecretGroupChatInfo> setSecretGroupDestroyPolicy({
    required String id,
    required String policy,
  }) async =>
      SecretGroupChatInfo(id: id, destroyPolicy: policy);

  @override
  Future<void> leaveSecretGroupChat(String id) async {}

  @override
  Future<void> deleteSecretGroupChat(String id) async {}

  @override
  Future<Map<String, dynamic>> postSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
    required List<Map<String, dynamic>> recipients,
    List<String>? mediaObjectIds,
    List<dynamic>? atUsers,
  }) async =>
      {'msgId': msgId};

  @override
  Future<void> muteConversation(String conversationId, bool muted) async {}

  @override
  Future<List<String>> mutedConversations() async => const [];

  @override
  Future<List<Map<String, dynamic>>> listSecretGroupMessages({
    required int secretGroupId,
    int afterSeq = 0,
    int limit = 50,
  }) async =>
      const [];

  @override
  Future<Map<String, dynamic>> editSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
    required List<Map<String, dynamic>> recipients,
  }) async =>
      {'msgId': msgId};

  @override
  Future<SecretGroupChatInfo> generateSecretGroupInvite(String id) async =>
      SecretGroupChatInfo(id: id);

  @override
  Future<SecretGroupChatInfo> joinSecretGroupByInvite(String token) async =>
      const SecretGroupChatInfo(id: '9');

  @override
  Future<void> recallSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
  }) async {}

  @override
  Future<void> deleteSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
  }) async {}

  @override
  Future<List<Map<String, dynamic>>> resolveSecretGroupMessageMediaUrls({
    required int secretGroupId,
    required String msgId,
    required List<String> objectIds,
  }) async =>
      const [];

  @override
  Future<Map<String, dynamic>> markSecretGroupRead({
    required int secretGroupId,
    required int afterSeq,
  }) async =>
      {'counted': 0};

  @override
  Future<List<Map<String, dynamic>>> listSecretGroupDestroyedStates(
    int secretGroupId, {
    String? afterDestroyAt,
    int limit = 100,
  }) async =>
      const [];

  @override
  Future<SecretGroupChatInfo> setSecretGroupAnonymous({
    required String id,
    required bool enabled,
  }) async =>
      SecretGroupChatInfo(id: id);

  @override
  Future<SecretGroupChatInfo> pinSecretGroupMessage({
    required String id,
    required String msgId,
  }) async =>
      SecretGroupChatInfo(id: id);

  @override
  Future<SecretGroupChatInfo> unpinSecretGroupMessage(String id) async =>
      SecretGroupChatInfo(id: id);

  @override
  Future<SecretGroupChatInfo> setSecretGroupOwnerOnlyPost({
    required String id,
    required bool enabled,
  }) async =>
      SecretGroupChatInfo(id: id);

  @override
  Future<SecretGroupChatInfo> setSecretGroupName({
    required String id,
    required String name,
  }) async =>
      SecretGroupChatInfo(id: id, name: name);

  @override
  Future<SecretGroupChatInfo> setSecretGroupAnnouncement({
    required String id,
    required String announcement,
  }) async =>
      SecretGroupChatInfo(id: id, announcement: announcement);

  @override
  Future<SecretGroupChatInfo> removeSecretGroupMember({
    required String id,
    required int userId,
  }) async =>
      SecretGroupChatInfo(id: id);

  @override
  Future<List<Map<String, dynamic>>> resolveSecretMessageMediaUrls({
    required int secretChatId,
    required String msgId,
    required List<String> objectIds,
  }) async =>
      const [];
}

class _FakeFriendRepository implements FriendRepository {
  @override
  Future<List<FriendRequestItem>> loadPendingRequests() async => const [];

  @override
  Future<void> handleRequest(int requestId, String action) async {}

  @override
  Future<List<FriendItem>> loadFriends() async => const [];

  @override
  Future<void> blockFriend(int friendId) async {}

  @override
  Future<ImUser> loadUserProfile(int userId) => throw UnimplementedError();

  @override
  Future<void> removeFriend(int friendId) async {}

  @override
  Future<List<dynamic>> searchUser(String keyword) async => const [];

  @override
  Future<void> sendRequest(int userId, String message,
      {String? source, int? groupId}) async {}

  @override
  Future<void> updateFriendRemark(int friendId, String remark) async {}

  @override
  Future<void> unblockFriend(int friendId) async {}

  @override
  Future<List<FriendItem>> loadBlockedList() async => const [];

  @override
  Future<List<String>> loadFriendGroups() async => const [];

  @override
  Future<void> setFriendGroup(int friendId, String groupName) async {}
}

class _FakeGroupRepository implements GroupRepository {
  @override
  Future<List<GroupItem>> loadGroups() async => const [];

  @override
  Future<GroupItem> createGroup({
    required String name,
    required List<int> memberIds,
  }) =>
      throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> loadGroupInfo(int groupId) async => {};

  @override
  Future<List<GroupMember>> loadMembers(int groupId) async => const [];

  @override
  Future<void> addMembers(int groupId, List<int> userIds) async {}

  @override
  Future<void> removeMember(int groupId, int userId) async {}

  @override
  Future<void> leaveGroup(int groupId) async {}

  @override
  Future<void> updateGroup(int groupId, Map<String, dynamic> data) async {}

  @override
  Future<void> dissolveGroup(int groupId) async {}

  @override
  Future<void> updateMyNickname(int groupId, String nickname) async {}

  @override
  Future<void> muteMember(int groupId, int userId, int? durationMinutes) async {}

  @override
  Future<void> setRole(int groupId, int userId, String role) async {}
}

/// 通用最小 Socket 替身：用 noSuchMethod 动态满足接口，避免手写全部成员。
class _FakeSocket implements GvSocketClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
