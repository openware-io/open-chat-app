import '../services/im_api.dart';
import '../models/channel_models.dart';
import '../models/message_sync.dart';
import '../models/secret_chat_models.dart';
import '../models/secret_group_chat_models.dart';
import 'chat_repository.dart';

/// ImApi 版本的聊天仓库，先把远端依赖从 ChatProvider 中隔离出来。
class ImChatRepository implements ChatRepository {
  ImChatRepository(this._api);

  final ImApi _api;

  @override
  Future<List<dynamic>> messageHistory({
    required String peerId,
    required String chatType,
    String? beforeMsgId,
    String? afterMsgId,
    int pageSize = 30,
  }) {
    return _api.messageHistory(
      peerId: peerId,
      chatType: chatType,
      beforeMsgId: beforeMsgId,
      afterMsgId: afterMsgId,
      pageSize: pageSize,
    );
  }

  @override
  Future<List<dynamic>> messageHistoryCentered({
    required String peerId,
    required String chatType,
    required String centerMsgId,
    int beforeCount = 30,
    int afterCount = 30,
  }) {
    return _api.messageHistoryCentered(
      peerId: peerId,
      chatType: chatType,
      centerMsgId: centerMsgId,
      beforeCount: beforeCount,
      afterCount: afterCount,
    );
  }

  @override
  Future<void> markRead(List<String> msgIds) => _api.markRead(msgIds);

  @override
  Future<MessageSyncPage> syncMessages({
    required int afterSyncSeq,
    int limit = 200,
  }) {
    return _api.syncMessages(afterSyncSeq: afterSyncSeq, limit: limit);
  }

  @override
  Future<List<dynamic>> searchChatMessages({
    String? peerId,
    String? chatType,
    required String keyword,
    String msgType = 'text',
    int page = 1,
    int pageSize = 30,
    String? beforeMsgId,
  }) {
    return _api.searchChatMessages(
      peerId: peerId,
      chatType: chatType,
      keyword: keyword,
      msgType: msgType,
      page: page,
      pageSize: pageSize,
      beforeMsgId: beforeMsgId,
    );
  }

  @override
  Future<void> deleteMessageForEveryone(String msgId) {
    return _api.deleteMessageForEveryone(msgId);
  }

  @override
  Future<int> deleteMessagesForMe(List<String> msgIds) {
    return _api.deleteMessagesForMe(msgIds);
  }

  @override
  Future<void> recallMessage(String msgId) {
    return _api.recallMessage(msgId);
  }

  @override
  Future<Map<String, dynamic>> editMessage({
    required String msgId,
    required String newContent,
  }) {
    return _api.editMessage(msgId: msgId, newContent: newContent);
  }

  @override
  Future<int> unreadCount() => _api.unreadCount();

  @override
  Future<List<({String conversationId, int count})>> unreadByConversation() {
    return _api.unreadByConversation();
  }

  @override
  Future<Map<String, dynamic>> clearPrivateChat(String peerId) {
    return _api.clearPrivateChat(peerId);
  }

  @override
  Future<Map<String, dynamic>> clearGroupChat(String groupId) {
    return _api.clearGroupChat(groupId);
  }

  @override
  Future<ChannelInfo> createChannel({
    required String name,
    String? description,
  }) {
    return _api.createChannel(name: name, description: description);
  }

  @override
  Future<List<ChannelInfo>> myChannels() => _api.myChannels();

  @override
  Future<ChannelInfo> channelInfo(String id) => _api.channelInfo(id);

  @override
  Future<ChannelInfo> subscribeChannel(String id) =>
      _api.subscribeChannel(id);

  @override
  Future<void> unsubscribeChannel(String id) => _api.unsubscribeChannel(id);

  @override
  Future<ChannelInfo> updateChannel(String id, {String? name, String? announcement}) =>
      _api.updateChannel(id, name: name, announcement: announcement);

  @override
  Future<void> deleteChannel(String id) => _api.deleteChannel(id);

  @override
  Future<List<ChannelInfo>> searchChannels(String keyword, {int limit = 20}) =>
      _api.searchChannels(keyword, limit: limit);

  @override
  Future<ChannelInfo> channelByCode(String code) => _api.channelByCode(code);

  @override
  Future<SecretChatInfo> createSecretChat({
    required int peerUserId,
    String? publicKey,
  }) {
    return _api.createSecretChat(peerUserId: peerUserId, publicKey: publicKey);
  }

  @override
  Future<List<SecretChatInfo>> mySecretChats() => _api.mySecretChats();

  @override
  Future<SecretChatInfo> secretChatInfo(String id) => _api.secretChatInfo(id);

  @override
  Future<SecretChatInfo> submitSecretChatHandshake({
    required String id,
    required String publicKey,
  }) {
    return _api.submitSecretChatHandshake(id: id, publicKey: publicKey);
  }

  @override
  Future<SecretChatInfo> destroySecretChatPolicy({
    required String id,
    required String policy,
  }) {
    return _api.destroySecretChatPolicy(id: id, policy: policy);
  }

  @override
  Future<void> deleteSecretChat(String id) {
    return _api.deleteSecretChat(id);
  }

  @override
  Future<SecretGroupChatInfo> createSecretGroupChat({
    required List<int> memberUserIds,
  }) {
    return _api.createSecretGroupChat(memberUserIds: memberUserIds);
  }

  @override
  Future<List<SecretGroupChatInfo>> mySecretGroupChats() =>
      _api.mySecretGroupChats();

  @override
  Future<SecretGroupChatInfo> secretGroupChatInfo(String id) =>
      _api.secretGroupChatInfo(id);

  @override
  Future<SecretGroupChatInfo> addSecretGroupMember({
    required String id,
    required int userId,
  }) {
    return _api.addSecretGroupMember(id: id, userId: userId);
  }

  @override
  Future<SecretGroupChatInfo> submitSecretGroupHandshake({
    required String id,
    required String publicKey,
  }) {
    return _api.submitSecretGroupHandshake(id: id, publicKey: publicKey);
  }

  @override
  Future<SecretGroupChatInfo> setSecretGroupDestroyPolicy({
    required String id,
    required String policy,
  }) {
    return _api.setSecretGroupDestroyPolicy(id: id, policy: policy);
  }

  @override
  Future<SecretGroupChatInfo> setSecretGroupAnonymous({
    required String id,
    required bool enabled,
  }) {
    return _api.setSecretGroupAnonymous(id: id, enabled: enabled);
  }

  @override
  Future<SecretGroupChatInfo> pinSecretGroupMessage({
    required String id,
    required String msgId,
  }) {
    return _api.pinSecretGroupMessage(id: id, msgId: msgId);
  }

  @override
  Future<SecretGroupChatInfo> unpinSecretGroupMessage(String id) {
    return _api.unpinSecretGroupMessage(id);
  }

  @override
  Future<SecretGroupChatInfo> generateSecretGroupInvite(String id) {
    return _api.generateSecretGroupInvite(id);
  }

  @override
  Future<SecretGroupChatInfo> joinSecretGroupByInvite(String token) {
    return _api.joinSecretGroupByInvite(token);
  }

  @override
  Future<SecretGroupChatInfo> setSecretGroupOwnerOnlyPost({
    required String id,
    required bool enabled,
  }) {
    return _api.setSecretGroupOwnerOnlyPost(id: id, enabled: enabled);
  }

  @override
  Future<SecretGroupChatInfo> setSecretGroupName({
    required String id,
    required String name,
  }) {
    return _api.setSecretGroupName(id: id, name: name);
  }

  @override
  Future<SecretGroupChatInfo> setSecretGroupAnnouncement({
    required String id,
    required String announcement,
  }) {
    return _api.setSecretGroupAnnouncement(id: id, announcement: announcement);
  }

  @override
  Future<SecretGroupChatInfo> removeSecretGroupMember({
    required String id,
    required int userId,
  }) {
    return _api.removeSecretGroupMember(id: id, userId: userId);
  }

  @override
  Future<void> leaveSecretGroupChat(String id) {
    return _api.leaveSecretGroupChat(id);
  }

  @override
  Future<void> deleteSecretGroupChat(String id) {
    return _api.deleteSecretGroupChat(id);
  }

  @override
  Future<Map<String, dynamic>> postSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
    required List<Map<String, dynamic>> recipients,
    List<String>? mediaObjectIds,
    List<dynamic>? atUsers,
  }) {
    return _api.postSecretGroupMessage(
      secretGroupId: secretGroupId,
      msgId: msgId,
      recipients: recipients,
      mediaObjectIds: mediaObjectIds,
      atUsers: atUsers,
    );
  }

  @override
  Future<Map<String, dynamic>> editSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
    required List<Map<String, dynamic>> recipients,
  }) {
    return _api.editSecretGroupMessage(
      secretGroupId: secretGroupId,
      msgId: msgId,
      recipients: recipients,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listSecretGroupMessages({
    required int secretGroupId,
    int afterSeq = 0,
    int limit = 50,
  }) {
    return _api.listSecretGroupMessages(
      secretGroupId: secretGroupId,
      afterSeq: afterSeq,
      limit: limit,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> resolveSecretGroupMessageMediaUrls({
    required int secretGroupId,
    required String msgId,
    required List<String> objectIds,
  }) {
    return _api.resolveSecretGroupMessageMediaUrls(
      secretGroupId: secretGroupId,
      msgId: msgId,
      objectIds: objectIds,
    );
  }

  @override
  Future<Map<String, dynamic>> markSecretGroupRead({
    required int secretGroupId,
    required int afterSeq,
  }) {
    return _api.markSecretGroupRead(
      secretGroupId: secretGroupId,
      afterSeq: afterSeq,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listSecretGroupDestroyedStates(
    int secretGroupId, {
    String? afterDestroyAt,
    int limit = 100,
  }) {
    return _api.listSecretGroupDestroyedStates(
      secretGroupId,
      afterDestroyAt: afterDestroyAt,
      limit: limit,
    );
  }

  @override
  Future<Map<String, dynamic>> registerDeviceKey({
    required String deviceId,
    required String publicKey,
  }) {
    return _api.registerDeviceKey(deviceId: deviceId, publicKey: publicKey);
  }

  @override
  Future<List<Map<String, dynamic>>> myDeviceKeys() => _api.myDeviceKeys();

  @override
  Future<Map<String, dynamic>> postSecretMessage({
    required int secretChatId,
    required String msgId,
    required String ciphertext,
    List<String>? mediaObjectIds,
  }) {
    return _api.postSecretMessage(
      secretChatId: secretChatId,
      msgId: msgId,
      ciphertext: ciphertext,
      mediaObjectIds: mediaObjectIds,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> listSecretMessages({
    required int secretChatId,
    int afterSeq = 0,
    int limit = 50,
  }) {
    return _api.listSecretMessages(
      secretChatId: secretChatId,
      afterSeq: afterSeq,
      limit: limit,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> resolveSecretMessageMediaUrls({
    required int secretChatId,
    required String msgId,
    required List<String> objectIds,
  }) {
    return _api.resolveSecretMessageMediaUrls(
      secretChatId: secretChatId,
      msgId: msgId,
      objectIds: objectIds,
    );
  }

  @override
  Future<Map<String, dynamic>> markSecretMessagesRead({
    required int secretChatId,
    required int afterSeq,
  }) {
    return _api.markSecretMessagesRead(
      secretChatId: secretChatId,
      afterSeq: afterSeq,
    );
  }

  @override
  Future<Map<String, dynamic>> secretChatDestroyStatus(int secretChatId) {
    return _api.secretChatDestroyStatus(secretChatId);
  }

  @override
  Future<List<Map<String, dynamic>>> secretChatDestroyStates(
    int secretChatId, {
    String? afterDestroyAt,
    int limit = 100,
  }) {
    return _api.secretChatDestroyStates(
      secretChatId,
      afterDestroyAt: afterDestroyAt,
      limit: limit,
    );
  }

  @override
  Future<void> recallSecretMessage({
    required int secretChatId,
    required String msgId,
  }) {
    return _api.recallSecretMessage(secretChatId: secretChatId, msgId: msgId);
  }

  @override
  Future<void> deleteSecretMessage({
    required int secretChatId,
    required String msgId,
  }) {
    return _api.deleteSecretMessage(secretChatId: secretChatId, msgId: msgId);
  }

  @override
  Future<void> recallSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
  }) {
    return _api.recallSecretGroupMessage(secretGroupId: secretGroupId, msgId: msgId);
  }

  @override
  Future<void> deleteSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
  }) {
    return _api.deleteSecretGroupMessageForEveryone(secretGroupId: secretGroupId, msgId: msgId);
  }

  @override
  Future<void> muteConversation(String conversationId, bool muted) {
    return _api.muteConversation(conversationId, muted);
  }

  @override
  Future<List<String>> mutedConversations() => _api.mutedConversations();
}
