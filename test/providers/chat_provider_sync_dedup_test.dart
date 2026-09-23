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
import 'package:open_chat_app/services/e2ee/e2ee_manager.dart';
import 'package:open_chat_app/services/im_api.dart';

/// 同步拉取去重回归测试：本地媒体占位（msgId=clientMsgId）与服务端确认消息
/// （msgId=雪花 id、clientMsgId 相同）必须按 clientMsgId 视为同一条，
/// 否则上传视频等耗时长消息会重复显示（占位 + sent 两条）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatProvider provider;
  late ChatDatabase database;
  late _SyncFakeChatRepository chatRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'im_user': '{"id": 100, "username": "sender"}',
    });
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    database = ChatDatabase.forTesting(NativeDatabase.memory());
    final local = ChatLocalStore(storage, database);
    final apiClient = ApiClient(storage);
    final imApi = ImApi(apiClient);
    final e2ee = E2eeManager(imApi: imApi, preferences: prefs);
    chatRepo = _SyncFakeChatRepository(imApi);
    provider = ChatProvider(
      local,
      chatRepo,
      _OnlineSocket(),
      FriendProvider(_EmptyFriendRepository()),
      GroupProvider(_EmptyGroupRepository()),
      e2ee,
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('好友重新建立后会幂等恢复已删除的私聊会话', () {
    provider.upsertConversation('2', 'private', '旧消息');
    provider.removeConversation('2', 'private');
    expect(provider.conversations, isEmpty);

    provider.restoreFriendConversation(2);
    provider.restoreFriendConversation(2);

    expect(provider.conversations, hasLength(1));
    expect(provider.conversations.single.id, '2');
    expect(provider.conversations.single.chatType, 'private');
    expect(provider.conversations.single.unread, 0);
  });

  test('同步拉取与服务端同 clientMsgId 的消息不重复，且用服务端数据替换占位', () async {
    // 1) 本地乐观/媒体占位：msgId = clientMsgId，status=sending。
    provider.sendMessage(
      '2',
      'private',
      'video',
      '{"url":"http://img/v.mp4","duration":5000}',
      mediaObjectIds: ['obj-1'],
    );
    final before = provider.messagesFor('2', 'private');
    expect(before, hasLength(1));
    final placeholder = before.single;
    expect(placeholder.status, 'sending');
    final cid = placeholder.clientMsgId;
    expect(cid, isNotNull);

    // 2) 服务端已存储该消息（msgId=雪花 id，clientMsgId 相同），同步拉取返回。
    chatRepo.syncPage = MessageSyncPage(
      items: [
        MessageSyncItem(
          syncSeq: 1,
          message: {
            'msgId': 'srv-365418376367325184',
            'from': 100,
            'fromUsername': 'sender',
            'toId': '2',
            'chatType': 'private',
            'msgType': 'video',
            'content': '{"url":"http://img/v.mp4","duration":5000}',
            'clientMsgId': cid,
            'timestamp': '2026-08-19T08:00:00Z',
            'status': 'sent',
            'mediaObjectIds': ['obj-1'],
          },
          readAt: null,
        ),
      ],
      nextSyncSeq: 1,
      hasMore: false,
    );

    await provider.synchronizeMessages();

    // 3) 不得出现重复（占位 + sent 两条）；占位被服务端权威数据替换。
    final after = provider.messagesFor('2', 'private');
    expect(after, hasLength(1),
        reason: '同 clientMsgId 的占位与服务端消息必须视为同一条（上传视频重复回归）');
    expect(after.single.msgId, 'srv-365418376367325184',
        reason: '占位应被服务端消息替换（msgId 更新为服务端 id）');
    expect(after.single.status, isNot('sending'),
        reason: '替换后不应再是发送中');
  });

  test('服务端消息 msgId 与本地相同（已 ack 确认）时同步不重复、不替换', () async {
    provider.sendMessage(
      '2',
      'private',
      'text',
      'hello',
    );
    final placeholder = provider.messagesFor('2', 'private').single;
    final cid = placeholder.clientMsgId;
    // 模拟 ack 已确认：占位 msgId 已更新为服务端 id。
    final confirmed = placeholder.copyWith(
      msgId: 'srv-99',
      status: 'sent',
    );
    // 直接用确认后的消息替换本地占位（等价于 ack 路径）。
    // 通过再次同步：服务端返回同 msgId 消息，应被去重跳过。
    chatRepo.syncPage = MessageSyncPage(
      items: [
        MessageSyncItem(
          syncSeq: 1,
          message: {
            'msgId': 'srv-99',
            'from': 100,
            'fromUsername': 'sender',
            'toId': '2',
            'chatType': 'private',
            'msgType': 'text',
            'content': 'hello',
            'clientMsgId': cid,
            'timestamp': '2026-08-19T08:00:00Z',
            'status': 'sent',
          },
          readAt: null,
        ),
      ],
      nextSyncSeq: 1,
      hasMore: false,
    );
    // 先把占位确认（模拟 ack），再同步。
    final list = provider.messagesFor('2', 'private');
    list[0] = confirmed;

    await provider.synchronizeMessages();

    final after = provider.messagesFor('2', 'private');
    expect(after, hasLength(1));
    expect(after.single.msgId, 'srv-99');
  });

  test('推送锚点请求全部失败时保留当前聊天记录，不会变成空白', () async {
    provider.sendMessage('2', 'private', 'text', 'cached message');
    final before = List.of(provider.messagesFor('2', 'private'));
    expect(before, isNotEmpty);

    chatRepo.centeredHistoryError = StateError('center unavailable');
    chatRepo.historyError = StateError('history unavailable');

    await provider.replaceSessionWithAnchorWindow(
      '2',
      'private',
      'missing-anchor',
    );

    final after = provider.messagesFor('2', 'private');
    expect(after.map((m) => m.msgId), before.map((m) => m.msgId),
        reason: '远端锚点历史失败时不得清空已显示的缓存消息');
  });

  test('居中接口返回目标消息时才用锚点窗口替换当前记录', () async {
    provider.sendMessage('2', 'private', 'text', 'cached message');
    chatRepo.centeredHistory = [
      {
        'msgId': 'anchor-1',
        'from': 2,
        'fromUsername': 'peer',
        'toId': '100',
        'chatType': 'private',
        'msgType': 'text',
        'content': 'notification target',
        'timestamp': '2026-08-19T08:00:00Z',
        'status': 'sent',
      },
    ];

    await provider.replaceSessionWithAnchorWindow(
      '2',
      'private',
      'anchor-1',
    );

    expect(
        provider.messagesFor('2', 'private').map((m) => m.msgId), ['anchor-1']);
  });

  test('旧服务端忽略 centerMsgId 返回其他消息时不覆盖当前记录', () async {
    provider.sendMessage('2', 'private', 'text', 'cached message');
    final before = List.of(provider.messagesFor('2', 'private'));
    chatRepo.centeredHistory = [
      {
        'msgId': 'latest-but-not-anchor',
        'from': 2,
        'fromUsername': 'peer',
        'toId': '100',
        'chatType': 'private',
        'msgType': 'text',
        'content': 'latest',
        'timestamp': '2026-08-19T09:00:00Z',
        'status': 'sent',
      },
    ];

    await provider.replaceSessionWithAnchorWindow(
      '2',
      'private',
      'missing-anchor',
    );

    expect(provider.messagesFor('2', 'private').map((m) => m.msgId),
        before.map((m) => m.msgId));
  });
}

class _SyncFakeChatRepository implements ChatRepository {
  _SyncFakeChatRepository(this._imApi);

  final ImApi _imApi;
  MessageSyncPage syncPage = const MessageSyncPage(
    items: [],
    nextSyncSeq: 0,
    hasMore: false,
  );
  List<dynamic> history = const [];
  List<dynamic> centeredHistory = const [];
  Object? historyError;
  Object? centeredHistoryError;

  @override
  Future<MessageSyncPage> syncMessages({
    required int afterSyncSeq,
    int limit = 200,
  }) async =>
      syncPage;

  @override
  Future<List<dynamic>> messageHistory({
    required String peerId,
    required String chatType,
    String? beforeMsgId,
    String? afterMsgId,
    int pageSize = 30,
  }) async {
    if (historyError case final error?) throw error;
    return history;
  }

  @override
  Future<List<dynamic>> messageHistoryCentered({
    required String peerId,
    required String chatType,
    required String centerMsgId,
    int beforeCount = 30,
    int afterCount = 30,
  }) async {
    if (centeredHistoryError case final error?) throw error;
    return centeredHistory;
  }

  @override
  Future<void> markRead(List<String> msgIds) async {}

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
      SecretChatInfo(id: '1', peerUserId: peerUserId);

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

class _OnlineSocket implements GvSocketClient {
  @override
  bool get connected => true;

  @override
  bool get hasClient => true;

  @override
  void emitChat(String event, dynamic data) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _EmptyFriendRepository implements FriendRepository {
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

class _EmptyGroupRepository implements GroupRepository {
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
