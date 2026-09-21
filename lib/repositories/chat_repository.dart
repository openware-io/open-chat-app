import '../models/channel_models.dart';
import '../models/message_sync.dart';
import '../models/secret_chat_models.dart';
import '../models/secret_group_chat_models.dart';

/// 聊天历史和已读上报边界。
///
/// 当前 ChatProvider 仍负责复杂的消息合并、分页窗口和本地状态；
/// Repository 只先隔离远端接口调用，后续再逐步拆分算法服务。
///
/// 频道 / 私密聊天（形态先行）的会话域接口也先收敛在本仓库，
/// 由 [ChatProvider] 暴露给 UI，避免 screen 直接触达网络层。
abstract interface class ChatRepository {
  Future<List<dynamic>> messageHistory({
    required String peerId,
    required String chatType,
    String? beforeMsgId,
    String? afterMsgId,
    int pageSize = 30,
  });

  Future<List<dynamic>> messageHistoryCentered({
    required String peerId,
    required String chatType,
    required String centerMsgId,
    int beforeCount = 30,
    int afterCount = 30,
  });

  Future<void> markRead(List<String> msgIds);

  Future<MessageSyncPage> syncMessages({
    required int afterSyncSeq,
    int limit = 200,
  });

  Future<List<dynamic>> searchChatMessages({
    String? peerId,
    String? chatType,
    required String keyword,
    String msgType = 'text',
    int page = 1,
    int pageSize = 30,
    String? beforeMsgId,
  });

  Future<void> deleteMessageForEveryone(String msgId);

  /// 「删除仅我」：服务端写入 per-user 墓碑，卸载重装后不会复活（不影响对方）。
  Future<int> deleteMessagesForMe(List<String> msgIds);

  Future<void> recallMessage(String msgId);

  /// 编辑消息正文（发送后 2 分钟内仅发送者本人）：POST /messages/edit。
  Future<Map<String, dynamic>> editMessage({
    required String msgId,
    required String newContent,
  });

  /// 未读消息总数：GET /messages/unread-count。
  Future<int> unreadCount();

  /// 按会话未读数：GET /messages/unread-by-conversation。
  Future<List<({String conversationId, int count})>> unreadByConversation();

  Future<Map<String, dynamic>> clearPrivateChat(String peerId);

  Future<Map<String, dynamic>> clearGroupChat(String groupId);

  // ─── Channels ───

  Future<ChannelInfo> createChannel({
    required String name,
    String? description,
  });

  Future<List<ChannelInfo>> myChannels();

  Future<ChannelInfo> channelInfo(String id);

  Future<ChannelInfo> subscribeChannel(String id);

  Future<void> unsubscribeChannel(String id);

  Future<ChannelInfo> updateChannel(String id, {String? name, String? announcement});

  Future<void> deleteChannel(String id);

  Future<List<ChannelInfo>> searchChannels(String keyword, {int limit = 20});

  Future<ChannelInfo> channelByCode(String code);

  // ─── Secret Chats ───

  Future<SecretChatInfo> createSecretChat({
    required int peerUserId,
    String? publicKey,
  });

  Future<List<SecretChatInfo>> mySecretChats();

  Future<SecretChatInfo> secretChatInfo(String id);

  Future<SecretChatInfo> submitSecretChatHandshake({
    required String id,
    required String publicKey,
  });

  Future<SecretChatInfo> destroySecretChatPolicy({
    required String id,
    required String policy,
  });

  /// 删除私密会话（任意一方删除即终止，双方列表都不再返回）。
  Future<void> deleteSecretChat(String id);

  // ─── Secret Group Chats (私密群聊：逐成员 E2EE) ───

  Future<SecretGroupChatInfo> createSecretGroupChat({
    required List<int> memberUserIds,
  });

  Future<List<SecretGroupChatInfo>> mySecretGroupChats();

  Future<SecretGroupChatInfo> secretGroupChatInfo(String id);

  Future<SecretGroupChatInfo> addSecretGroupMember({
    required String id,
    required int userId,
  });

  Future<SecretGroupChatInfo> submitSecretGroupHandshake({
    required String id,
    required String publicKey,
  });

  Future<SecretGroupChatInfo> setSecretGroupDestroyPolicy({
    required String id,
    required String policy,
  });

  Future<SecretGroupChatInfo> setSecretGroupAnonymous({
    required String id,
    required bool enabled,
  });

  Future<SecretGroupChatInfo> pinSecretGroupMessage({
    required String id,
    required String msgId,
  });

  Future<SecretGroupChatInfo> unpinSecretGroupMessage(String id);

  Future<SecretGroupChatInfo> generateSecretGroupInvite(String id);

  Future<SecretGroupChatInfo> joinSecretGroupByInvite(String token);

  Future<SecretGroupChatInfo> setSecretGroupOwnerOnlyPost({
    required String id,
    required bool enabled,
  });

  Future<SecretGroupChatInfo> setSecretGroupName({
    required String id,
    required String name,
  });

  Future<SecretGroupChatInfo> setSecretGroupAnnouncement({
    required String id,
    required String announcement,
  });

  Future<SecretGroupChatInfo> removeSecretGroupMember({
    required String id,
    required int userId,
  });

  Future<void> leaveSecretGroupChat(String id);

  /// 删除（解散）私密群聊，仅群主。
  Future<void> deleteSecretGroupChat(String id);

  // ─── Secret Group Messages (逐成员密文存储) ───

  Future<Map<String, dynamic>> postSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
    required List<Map<String, dynamic>> recipients,
    List<String>? mediaObjectIds,
    List<dynamic>? atUsers,
  });

  Future<Map<String, dynamic>> editSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
    required List<Map<String, dynamic>> recipients,
  });

  Future<List<Map<String, dynamic>>> listSecretGroupMessages({
    required int secretGroupId,
    int afterSeq = 0,
    int limit = 50,
  });

  /// 重新换取私密群聊消息媒体访问 URL（参与方授权）。
  Future<List<Map<String, dynamic>>> resolveSecretGroupMessageMediaUrls({
    required int secretGroupId,
    required String msgId,
    required List<String> objectIds,
  });

  /// 接收方已读上报：对 seq<=afterSeq 且由对方发送、尚未计时的群密文开始销毁倒计时。
  Future<Map<String, dynamic>> markSecretGroupRead({
    required int secretGroupId,
    required int afterSeq,
  });

  /// 群消息销毁状态增量同步（服务端权威）：返回撤回/删除痕迹（msgId + destroyAt + reason）。
  Future<List<Map<String, dynamic>>> listSecretGroupDestroyedStates(
    int secretGroupId, {
    String? afterDestroyAt,
    int limit = 100,
  });

  // ─── Device Keys (E2EE 设备身份) ───

  Future<Map<String, dynamic>> registerDeviceKey({
    required String deviceId,
    required String publicKey,
  });

  Future<List<Map<String, dynamic>>> myDeviceKeys();

  // ─── Secret Messages (E2EE 密文) ───

  Future<Map<String, dynamic>> postSecretMessage({
    required int secretChatId,
    required String msgId,
    required String ciphertext,
    List<String>? mediaObjectIds,
  });

  Future<List<Map<String, dynamic>>> listSecretMessages({
    required int secretChatId,
    int afterSeq = 0,
    int limit = 50,
  });

  /// 重新换取私密消息媒体访问 URL（参与方授权）。
  Future<List<Map<String, dynamic>>> resolveSecretMessageMediaUrls({
    required int secretChatId,
    required String msgId,
    required List<String> objectIds,
  });

  /// 接收方已读上报：对 seq<=afterSeq 且由对方发送、尚未计时的密文开始销毁倒计时。
  Future<Map<String, dynamic>> markSecretMessagesRead({
    required int secretChatId,
    required int afterSeq,
  });

  /// 会话销毁状态：返回 active 密文中最早的销毁时刻（无计时为 null）。
  Future<Map<String, dynamic>> secretChatDestroyStatus(int secretChatId);

  /// 销毁状态增量同步（服务端权威）：返回销毁时刻晚于 afterDestroyAt 的 destroyed 密文标识。
  Future<List<Map<String, dynamic>>> secretChatDestroyStates(
    int secretChatId, {
    String? afterDestroyAt,
    int limit = 100,
  });

  /// 撤回私密消息（仅发送方，窗口内）：服务端协调对端渲染撤回墓碑。
  Future<void> recallSecretMessage({
    required int secretChatId,
    required String msgId,
  });

  /// 删除私密消息（任意参与方）：服务端协调对端移除本地消息。
  Future<void> deleteSecretMessage({
    required int secretChatId,
    required String msgId,
  });

  /// 撤回私密群聊消息（仅发送方，不限时）：服务端协调全员移除。
  Future<void> recallSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
  });

  /// 删除私密群聊消息所有人（仅发送方，不限时）：服务端协调全员移除。
  Future<void> deleteSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
  });

  // ─── Conversation Mute (免打扰跨端同步) ───

  /// 设置服务端持久化的会话级免打扰状态（跨端同步 + 离线推送过滤）。
  Future<void> muteConversation(String conversationId, bool muted);

  /// 拉取当前用户已免打扰的会话标识列表（服务端权威）。
  Future<List<String>> mutedConversations();
}
