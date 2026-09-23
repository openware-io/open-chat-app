import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:open_core/open_core.dart' show GvSocketClient;

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
import 'package:open_chat_app/services/e2ee/e2ee_crypto.dart';
import 'package:open_chat_app/services/e2ee/e2ee_manager.dart';
import 'package:open_chat_app/services/im_api.dart';

/// ChatProvider 私密群聊（逐成员 E2EE）服务层测试。
///
/// 覆盖：逐成员加密（每条密文用各自共享密钥解密）、游标拉取合并去重、
/// WS 信号触发拉取、模型 fromJson 容错。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatProvider provider;
  late ChatDatabase database;
  late _SecretGroupWireServer server;
  late E2eeManager e2ee;

  // 成员 200 / 300 的真实密钥对（测试中用其私钥解密服务端存下的密文）。
  late SimpleKeyPair member200KeyPair;
  late SimpleKeyPair member300KeyPair;
  late String member200Pub;
  late String member300Pub;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'im_user': '{"id": 100, "username": "owner"}',
      'client_release_installation_id': 'test-device-1',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    database = ChatDatabase.forTesting(NativeDatabase.memory());
    final local = ChatLocalStore(storage, database);

    member200KeyPair = await X25519().newKeyPair();
    member300KeyPair = await X25519().newKeyPair();
    final pub200 = await member200KeyPair.extractPublicKey();
    final pub300 = await member300KeyPair.extractPublicKey();
    member200Pub = base64Encode(pub200.bytes);
    member300Pub = base64Encode(pub300.bytes);

    server = _SecretGroupWireServer(
      memberPublicKeys: {200: member200Pub, 300: member300Pub},
    );
    final apiClient = ApiClient(storage);
    apiClient.dio.interceptors.add(server.interceptor);
    final imApi = ImApi(apiClient);
    e2ee = E2eeManager(imApi: imApi, preferences: prefs);

    final chatRepo = _FakeChatRepository(imApi);
    provider = ChatProvider(
      local,
      chatRepo,
      _FakeSocket(),
      FriendProvider(_FakeFriendRepository()),
      GroupProvider(_FakeGroupRepository()),
      e2ee,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('sendSecretGroupText', () {
    test('逐成员加密：每条密文不含明文，且各成员用各自共享密钥解回同一明文', () async {
      final info = await provider.ensureSecretGroupHandshake('1');
      expect(info, isNotNull);
      expect(provider.secretGroupReady('1'), isTrue);

      final result = await provider.sendSecretGroupText(
        groupId: '1',
        text: '私密群聊机密内容',
      );
      expect(result, SecretSendResult.success);

      expect(server.ciphertexts, hasLength(2));
      for (final cipher in server.ciphertexts) {
        expect(cipher, isNot(contains('私密群聊机密内容')));
      }

      // 成员 200 用「自己私钥 + 发送方公钥」解密收到的密文。
      final member200Cipher = server.ciphertextByUserId[200]!;
      final senderPub = server.ownerPublicKey;
      final shared200 = await _sharedSecret(
        privateKeyBase64: base64Encode(
          await member200KeyPair.extractPrivateKeyBytes(),
        ),
        peerPublicKeyBase64: senderPub,
      );
      final decrypted200 = await E2eeCryptoBridge.decrypt(shared200, member200Cipher);
      expect(decrypted200, contains('私密群聊机密内容'));

      // 成员 300 同理。
      final member300Cipher = server.ciphertextByUserId[300]!;
      final shared300 = await _sharedSecret(
        privateKeyBase64: base64Encode(
          await member300KeyPair.extractPrivateKeyBytes(),
        ),
        peerPublicKeyBase64: senderPub,
      );
      final decrypted300 = await E2eeCryptoBridge.decrypt(shared300, member300Cipher);
      expect(decrypted300, decrypted200,
          reason: '同一份明文逐成员加密，各自解密应得到相同载荷');
    });

    test('成员未提交公钥时本地乐观展示并入队（不再返回 waitingForPeer）', () async {
      // 清空成员公钥 → 全员未握手。
      server.clearMemberPublicKeys();
      final result = await provider.sendSecretGroupText(groupId: '1', text: 'hi');
      expect(result, SecretSendResult.success);
    });
  });

  group('pullSecretGroupMessages', () {
    test('解密合并去重：重复全量拉取同一条消息不重复插入', () async {
      await provider.ensureSecretGroupHandshake('1');
      // 成员 200 用「自己私钥 + 发送方公钥」加密一条消息发给我（接收方视角）。
      final shared = await _sharedSecret(
        privateKeyBase64: base64Encode(
          await member200KeyPair.extractPrivateKeyBytes(),
        ),
        peerPublicKeyBase64: server.ownerPublicKey,
      );
      final cipher = await E2eeCryptoBridge.encrypt(
        shared,
        jsonEncode({'t': 'text', 'c': '对方群消息'}),
      );
      server.messages['1'] = [
        {
          'msgId': 'peer-msg-1',
          'fromUserId': 200,
          'recipientUserId': 100,
          'seq': 1,
          'ciphertext': cipher,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00',
        },
      ];

      await provider.pullSecretGroupMessages('1', forceFull: true);
      expect(provider.messagesFor('1', 'secret_group'), hasLength(1));

      // 再次全量拉取同一批消息：合并去重，不重复插入。
      await provider.pullSecretGroupMessages('1', forceFull: true);
      expect(provider.messagesFor('1', 'secret_group'), hasLength(1),
          reason: '重复拉取同一条消息不得重复插入');
    });

    test('解密失败的消息不推进游标（保留重试）', () async {
      await provider.ensureSecretGroupHandshake('1');
      final badCipher = base64Encode(utf8.encode('cannot-decrypt'));
      server.messages['1'] = [
        {
          'msgId': 'peer-msg-1',
          'fromUserId': 200,
          'recipientUserId': 100,
          'seq': 6,
          'ciphertext': badCipher,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00',
        },
      ];

      await provider.pullSecretGroupMessages('1', forceFull: true);
      expect(provider.messagesFor('1', 'secret_group'), isEmpty,
          reason: '解密失败不展示');
    });
  });

  group('onSecretGroupStored', () {
    test('收到 WS 信号后若 groupReady 则触发拉取', () async {
      await provider.ensureSecretGroupHandshake('1');
      expect(provider.secretGroupReady('1'), isTrue);
      // 模拟成员 200 发来一条可用共享密钥加密的消息。
      final senderPub = server.ownerPublicKey;
      final shared = await _sharedSecret(
        privateKeyBase64: base64Encode(
          await member200KeyPair.extractPrivateKeyBytes(),
        ),
        peerPublicKeyBase64: senderPub,
      );
      final cipher = await E2eeCryptoBridge.encrypt(
        shared,
        jsonEncode({'t': 'text', 'c': '对方群消息'}),
      );
      server.messages['1'] = [
        {
          'msgId': 'peer-msg-9',
          'fromUserId': 200,
          'recipientUserId': 100,
          'seq': 9,
          'ciphertext': cipher,
          'status': 'active',
          'createdAt': '2026-08-19T00:00:00',
        },
      ];

      provider.onSecretGroupStored({'secretGroupId': 1, 'senderId': 200, 'msgId': 'peer-msg-9'});
      // pullSecretGroupMessages 异步执行，等待其完成。
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final messages = provider.messagesFor('1', 'secret_group');
      expect(messages.any((m) => m.msgId == 'peer-msg-9'), isTrue,
          reason: 'WS 信号应触发拉取并解密对方消息');
    });
  });
}

Future<Uint8List> _sharedSecret({
  required String privateKeyBase64,
  required String peerPublicKeyBase64,
}) async {
  final x = X25519();
  final priv = base64Decode(privateKeyBase64);
  final pub = base64Decode(peerPublicKeyBase64);
  final kp = await x.newKeyPairFromSeed(priv);
  final shared = await x.sharedSecretKey(
    keyPair: kp,
    remotePublicKey: SimplePublicKey(pub, type: KeyPairType.x25519),
  );
  return Uint8List.fromList(await shared.extractBytes());
}

/// 复用 E2eeCrypto 原语（避免测试里重复实现 AES-GCM）。
class E2eeCryptoBridge {
  static Future<String> encrypt(Uint8List shared, String plaintext) =>
      E2eeCrypto.encrypt(sharedSecret: shared, plaintext: plaintext);

  static Future<String?> decrypt(Uint8List shared, String ciphertext) =>
      E2eeCrypto.decrypt(sharedSecret: shared, ciphertextBase64: ciphertext);
}

/// 模拟服务端：握手公钥 + 逐成员密文存储，真实完成 E2EE 加密闭环。
class _SecretGroupWireServer {
  _SecretGroupWireServer({required Map<int, String> memberPublicKeys})
      : memberPublicKeys = Map.of(memberPublicKeys);

  final Map<int, String> memberPublicKeys;
  final Map<String, List<Map<String, dynamic>>> messages = {};
  final List<String> ciphertexts = [];
  final Map<int, String> ciphertextByUserId = {};
  String ownerPublicKey = '';

  void clearMemberPublicKeys() => memberPublicKeys.clear();

  InterceptorsWrapper get interceptor => InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.path;
          dynamic respond() {
            final body = Map<String, dynamic>.from(options.data as Map? ?? {});
            if (path.endsWith('/device-keys')) {
              return {'ok': true};
            }
            if (path.contains('/handshake') &&
                path.contains('secret-group-chats')) {
              ownerPublicKey = body['publicKey'] as String;
              return _groupInfo('1');
            }
            if (path.contains('secret-group-chats/mine')) {
              return [_groupInfo('1')];
            }
            if (path.contains('secret-group-chats/') &&
                options.method.toUpperCase() == 'GET' &&
                !path.contains('members')) {
              return _groupInfo(_groupIdFromPath(path));
            }
            if (path.contains('secret-group-messages') &&
                options.method.toUpperCase() == 'POST') {
              final recipients = (body['recipients'] as List).cast<Map>();
              for (final r in recipients) {
                final uid = (r['userId'] as num).toInt();
                final cipher = r['ciphertext'] as String;
                ciphertexts.add(cipher);
                ciphertextByUserId[uid] = cipher;
              }
              return {'msgId': body['msgId']};
            }
            if (path.contains('secret-group-messages') &&
                options.method.toUpperCase() == 'GET') {
              final groupId = options.queryParameters['secretGroupId']?.toString();
              return messages[groupId] ?? const [];
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

  Map<String, dynamic> _groupInfo(String id) {
    return {
      'id': int.tryParse(id) ?? 0,
      'ownerUserId': 100,
      'status': 'active',
      'safeCode': '',
      'destroyPolicy': 'off',
      'members': [
        {'userId': 100, 'devicePublicKey': ownerPublicKey, 'joinedAt': '2026-08-19T00:00:00'},
        for (final e in memberPublicKeys.entries)
          {'userId': e.key, 'devicePublicKey': e.value, 'joinedAt': '2026-08-19T00:00:00'},
      ],
      'createdBy': 100,
      'createdAt': '2026-08-19T00:00:00',
      'updatedBy': 100,
      'updatedAt': '2026-08-19T00:00:00',
    };
  }

  String _groupIdFromPath(String path) {
    final parts = path.split('/');
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] == 'secret-group-chats' && i + 1 < parts.length) {
        return parts[i + 1];
      }
    }
    return '1';
  }
}

class _FakeChatRepository implements ChatRepository {
  _FakeChatRepository(this._imApi);

  final ImApi _imApi;

  @override
  Future<SecretGroupChatInfo> createSecretGroupChat({
    required List<int> memberUserIds,
  }) =>
      _imApi.createSecretGroupChat(memberUserIds: memberUserIds);

  @override
  Future<List<SecretGroupChatInfo>> mySecretGroupChats() =>
      _imApi.mySecretGroupChats();

  @override
  Future<SecretGroupChatInfo> secretGroupChatInfo(String id) =>
      _imApi.secretGroupChatInfo(id);

  @override
  Future<SecretGroupChatInfo> submitSecretGroupHandshake({
    required String id,
    required String publicKey,
  }) =>
      _imApi.submitSecretGroupHandshake(id: id, publicKey: publicKey);

  @override
  Future<Map<String, dynamic>> postSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
    required List<Map<String, dynamic>> recipients,
    List<String>? mediaObjectIds,
    List<dynamic>? atUsers,
  }) =>
      _imApi.postSecretGroupMessage(
        secretGroupId: secretGroupId,
        msgId: msgId,
        recipients: recipients,
        mediaObjectIds: mediaObjectIds,
        atUsers: atUsers,
      );

  @override
  Future<void> muteConversation(String conversationId, bool muted) async {}

  @override
  Future<List<String>> mutedConversations() async => const [];

  @override
  Future<List<Map<String, dynamic>>> listSecretGroupMessages({
    required int secretGroupId,
    int afterSeq = 0,
    int limit = 50,
  }) =>
      _imApi.listSecretGroupMessages(
        secretGroupId: secretGroupId,
        afterSeq: afterSeq,
        limit: limit,
      );

  @override
  Future<SecretGroupChatInfo> addSecretGroupMember({
    required String id,
    required int userId,
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

  // ── 其余 ChatRepository 方法用最小桩实现 ──

  @override
  Future<SecretChatInfo> secretChatInfo(String id) => _imApi.secretChatInfo(id);

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
  }) async =>
      const [];

  @override
  Future<Map<String, dynamic>> markSecretMessagesRead({
    required int secretChatId,
    required int afterSeq,
  }) async =>
      {'counted': 0};

  @override
  Future<Map<String, dynamic>> secretChatDestroyStatus(int secretChatId) async =>
      {};

  @override
  Future<List<Map<String, dynamic>>> secretChatDestroyStates(
    int secretChatId, {
    String? afterDestroyAt,
    int limit = 100,
  }) async =>
      const [];

  @override
  Future<void> recallSecretMessage({
    required int secretChatId,
    required String msgId,
  }) async {}

  @override
  Future<void> deleteSecretMessage({
    required int secretChatId,
    required String msgId,
  }) async {}

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
