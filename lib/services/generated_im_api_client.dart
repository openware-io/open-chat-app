import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'generated_im_api_client.g.dart';

/// Retrofit 生成的远端 API 客户端。
///
/// 先迁移纯 JSON、无文件流、无特殊进度回调的接口；上传/下载和复杂聊天分页暂时保留在 [ImApi] 手写层。
@RestApi()
abstract class GeneratedImApiClient {
  factory GeneratedImApiClient(Dio dio, {String? baseUrl}) =
      _GeneratedImApiClient;

  @POST('/auth/register')
  Future<dynamic> register(@Body() Map<String, dynamic> body);

  @POST('/auth/login')
  Future<dynamic> login(@Body() Map<String, dynamic> body);

  @POST('/auth/ws-ticket')
  Future<dynamic> createWsTicket();

  @POST('/auth/password/forgot')
  Future<dynamic> forgotPassword(@Body() Map<String, dynamic> body);

  @POST('/auth/password/reset')
  Future<dynamic> resetPassword(@Body() Map<String, dynamic> body);

  @GET('/users/me')
  Future<dynamic> getMe();

  @PUT('/users/me')
  Future<dynamic> updateMe(@Body() Map<String, dynamic> body);

  @GET('/users/me/notification-settings')
  Future<dynamic> getNotificationSettings();

  @PUT('/users/me/notification-settings')
  Future<dynamic> updateNotificationSettings(@Body() Map<String, dynamic> body);

  @GET('/users/me/privacy-settings')
  Future<dynamic> getPrivacySettings();

  @PUT('/users/me/privacy-settings')
  Future<dynamic> updatePrivacySettings(@Body() Map<String, dynamic> body);

  @GET('/users/me/self-destruct')
  Future<dynamic> getSelfDestructPolicy();

  @PUT('/users/me/self-destruct')
  Future<dynamic> updateSelfDestructPolicy(@Body() Map<String, dynamic> body);

  @PUT('/users/me/password')
  Future<void> changePassword(@Body() Map<String, dynamic> body);

  @DELETE('/users/me')
  Future<void> deleteAccount(@Body() Map<String, dynamic> body);

  @GET('/users/{id}')
  Future<dynamic> getUser(@Path('id') int id);

  @GET('/users/search')
  Future<dynamic> searchUsers(@Query('keyword') String keyword);

  @GET('/friends')
  Future<dynamic> friendsList();

  @GET('/friends/requests/pending')
  Future<dynamic> pendingRequests();

  @POST('/friends/request')
  Future<void> sendFriendRequest(@Body() Map<String, dynamic> body);

  @PUT('/friends/request/{id}')
  Future<void> handleFriendRequest(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/friends/{friendId}')
  Future<void> removeFriend(@Path('friendId') int friendId);

  @PUT('/friends/{friendId}')
  Future<void> updateFriend(
    @Path('friendId') int friendId,
    @Body() Map<String, dynamic> data,
  );

  @POST('/friends/{friendId}/block')
  Future<void> blockFriend(@Path('friendId') int friendId);

  @POST('/friends/{friendId}/unblock')
  Future<void> unblockFriend(@Path('friendId') int friendId);

  @GET('/friends/groups')
  Future<dynamic> friendGroups();

  @GET('/friends/blocked')
  Future<dynamic> blockedFriends();

  @PUT('/conversations/{conversationId}/mute')
  Future<dynamic> muteConversation(
    @Path('conversationId') String conversationId,
    @Body() Map<String, dynamic> body,
  );

  @GET('/conversations/muted')
  Future<dynamic> mutedConversations();

  @POST('/favorites')
  Future<dynamic> addFavorite(@Body() Map<String, dynamic> body);

  @DELETE('/favorites/{msgId}')
  Future<void> removeFavorite(@Path('msgId') String msgId);

  @GET('/favorites')
  Future<dynamic> listFavorites({
    @Query('page') required int page,
    @Query('pageSize') required int pageSize,
  });

  /// 批量收藏：同一会话的多条消息一次提交，服务端按 msgId 幂等去重。
  @POST('/favorites/batch')
  Future<dynamic> addFavoritesBatch(@Body() Map<String, dynamic> body);

  /// 查询收藏对应原消息是否仍可访问（收藏按 msgId 唯一，故用 msgId 定位）。
  @GET('/favorites/{msgId}/source')
  Future<dynamic> favoriteSource(@Path('msgId') String msgId);

  @POST('/groups')
  Future<dynamic> createGroup(@Body() Map<String, dynamic> body);

  @GET('/groups/mine')
  Future<dynamic> myGroups();

  @GET('/groups/{id}')
  Future<dynamic> groupInfo(@Path('id') int id);

  @GET('/groups/{id}/members')
  Future<dynamic> groupMembers(@Path('id') int id);

  @PUT('/groups/{id}')
  Future<void> updateGroup(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/groups/{id}/members')
  Future<void> addGroupMembers(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/groups/{id}/members/{userId}')
  Future<void> removeGroupMember(
    @Path('id') int id,
    @Path('userId') int userId,
  );

  @POST('/groups/{id}/mute')
  Future<dynamic> muteGroupMember(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/groups/{id}/role')
  Future<dynamic> setGroupMemberRole(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @PUT('/groups/{id}/members/me/nickname')
  Future<dynamic> updateMyGroupNickname(
    @Path('id') int id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/groups/{id}/leave')
  Future<void> leaveGroup(@Path('id') int id);

  @DELETE('/groups/{id}')
  Future<void> dissolveGroup(@Path('id') int id);

  @GET('/messages/history')
  Future<dynamic> messageHistory({
    @Query('peerId') required String peerId,
    @Query('chatType') required String chatType,
    @Query('beforeMsgId') String? beforeMsgId,
    @Query('afterMsgId') String? afterMsgId,
    @Query('date') String? date,
    @Query('pageSize') required int pageSize,
  });

  @GET('/messages/history/dates')
  Future<dynamic> messageHistoryDates({
    @Query('peerId') required String peerId,
    @Query('chatType') required String chatType,
  });

  @GET('/messages/history')
  Future<dynamic> messageHistoryCentered({
    @Query('peerId') required String peerId,
    @Query('chatType') required String chatType,
    @Query('centerMsgId') required String centerMsgId,
    @Query('beforeCount') required int beforeCount,
    @Query('afterCount') required int afterCount,
  });

  @GET('/messages/sync')
  Future<dynamic> syncMessages({
    @Query('afterSyncSeq') required int afterSyncSeq,
    @Query('limit') required int limit,
  });

  @GET('/messages/search')
  Future<dynamic> searchChatMessages({
    @Query('peerId') String? peerId,
    @Query('chatType') String? chatType,
    @Query('keyword') required String keyword,
    @Query('msgType') required String msgType,
    @Query('page') required int page,
    @Query('pageSize') required int pageSize,
    @Query('beforeMsgId') String? beforeMsgId,
  });

  @POST('/messages/read')
  Future<void> markRead(@Body() Map<String, dynamic> body);

  @POST('/messages/recall')
  Future<dynamic> recallMessage(@Body() Map<String, dynamic> body);

  @POST('/messages/delete-for-everyone')
  Future<void> deleteMessageForEveryone(@Body() Map<String, dynamic> body);

  @POST('/messages/clear-private')
  Future<dynamic> clearPrivateChat(@Body() Map<String, dynamic> body);

  @POST('/messages/clear-group')
  Future<dynamic> clearGroupChat(@Body() Map<String, dynamic> body);

  // ─── Channels (频道：单向广播) ───

  @POST('/channels')
  Future<dynamic> createChannel(@Body() Map<String, dynamic> body);

  @GET('/channels/mine')
  Future<dynamic> myChannels();

  @GET('/channels/{id}')
  Future<dynamic> channelInfo(@Path('id') String id);

  @POST('/channels/{id}/subscribe')
  Future<dynamic> subscribeChannel(@Path('id') String id);

  @DELETE('/channels/{id}/subscribe')
  Future<dynamic> unsubscribeChannel(@Path('id') String id);

  @PUT('/channels/{id}')
  Future<dynamic> updateChannel(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/channels/{id}')
  Future<dynamic> deleteChannel(@Path('id') String id);

  @GET('/channels/search')
  Future<dynamic> searchChannels({
    @Query('keyword') String? keyword,
    @Query('limit') int? limit,
  });

  @GET('/channels/by-code/{code}')
  Future<dynamic> channelByCode(@Path('code') String code);

  // ─── Secret Chats (私密聊天：E2EE 形态) ───

  @POST('/secret-chats')
  Future<dynamic> createSecretChat(@Body() Map<String, dynamic> body);

  @GET('/secret-chats/mine')
  Future<dynamic> mySecretChats();

  @GET('/secret-chats/{id}')
  Future<dynamic> secretChatInfo(@Path('id') String id);

  @POST('/secret-chats/{id}/handshake')
  Future<dynamic> submitSecretChatHandshake(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/secret-chats/{id}/destroy-policy')
  Future<dynamic> destroySecretChatPolicy(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/secret-chats/{id}')
  Future<dynamic> deleteSecretChat(@Path('id') String id);

  // ─── Secret Group Chats (私密群聊：逐成员 E2EE) ───

  @POST('/secret-group-chats')
  Future<dynamic> createSecretGroupChat(@Body() Map<String, dynamic> body);

  @GET('/secret-group-chats/mine')
  Future<dynamic> mySecretGroupChats();

  @GET('/secret-group-chats/{id}')
  Future<dynamic> secretGroupChatInfo(@Path('id') String id);

  @POST('/secret-group-chats/{id}/members')
  Future<dynamic> addSecretGroupMember(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/secret-group-chats/{id}/handshake')
  Future<dynamic> submitSecretGroupHandshake(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/secret-group-chats/{id}/destroy-policy')
  Future<dynamic> setSecretGroupDestroyPolicy(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/secret-group-chats/{id}/anonymous')
  Future<dynamic> setSecretGroupAnonymous(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/secret-group-chats/{id}/pin')
  Future<dynamic> pinSecretGroupMessage(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/secret-group-chats/{id}/unpin')
  Future<dynamic> unpinSecretGroupMessage(@Path('id') String id);

  @POST('/secret-group-chats/{id}/invite')
  Future<dynamic> generateSecretGroupInvite(@Path('id') String id);

  @POST('/secret-group-chats/{id}/owner-only-post')
  Future<dynamic> setSecretGroupOwnerOnlyPost(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/secret-group-chats/join')
  Future<dynamic> joinSecretGroupByInvite(@Body() Map<String, dynamic> body);

  @POST('/secret-group-chats/{id}/name')
  Future<dynamic> setSecretGroupName(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/secret-group-chats/{id}/announcement')
  Future<dynamic> setSecretGroupAnnouncement(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/secret-group-chats/{id}/members/{userId}')
  Future<dynamic> removeSecretGroupMember(
    @Path('id') String id,
    @Path('userId') int userId,
  );

  @POST('/secret-group-chats/{id}/leave')
  Future<dynamic> leaveSecretGroupChat(@Path('id') String id);

  @DELETE('/secret-group-chats/{id}')
  Future<dynamic> deleteSecretGroupChat(@Path('id') String id);

  // ─── Secret Group Messages (逐成员密文存储) ───

  @POST('/secret-group-messages')
  Future<dynamic> postSecretGroupMessage(@Body() Map<String, dynamic> body);

  @POST('/secret-group-messages/edit')
  Future<dynamic> editSecretGroupMessage(@Body() Map<String, dynamic> body);

  @GET('/secret-group-messages')
  Future<dynamic> listSecretGroupMessages({
    @Query('secretGroupId') required int secretGroupId,
    @Query('afterSeq') int? afterSeq,
    @Query('limit') int? limit,
  });

  @POST('/secret-group-messages/read')
  Future<dynamic> markSecretGroupRead(@Body() Map<String, dynamic> body);

  @GET('/secret-group-messages/destroyed-states')
  Future<dynamic> listSecretGroupDestroyedStates({
    @Query('secretGroupId') required int secretGroupId,
    @Query('afterDestroyAt') String? afterDestroyAt,
    @Query('limit') int? limit,
  });

  @POST('/secret-group-messages/recall/{msgId}')
  Future<dynamic> recallSecretGroupMessage(
    @Path('msgId') String msgId, {
    @Query('secretGroupId') required int secretGroupId,
  });

  @DELETE('/secret-group-messages/{msgId}')
  Future<dynamic> deleteSecretGroupMessageForEveryone(
    @Path('msgId') String msgId, {
    @Query('secretGroupId') required int secretGroupId,
  });

  // ─── Device Keys (E2EE 设备身份) ───

  @POST('/device-keys')
  Future<dynamic> registerDeviceKey(@Body() Map<String, dynamic> body);

  @GET('/device-keys/me')
  Future<dynamic> myDeviceKeys();

  // ─── Secret Messages (E2EE 密文存储) ───

  @POST('/secret-messages')
  Future<dynamic> postSecretMessage(@Body() Map<String, dynamic> body);

  @GET('/secret-messages')
  Future<dynamic> listSecretMessages({
    @Query('secretChatId') required int secretChatId,
    @Query('afterSeq') int? afterSeq,
    @Query('limit') int? limit,
  });

  /// 接收方已读上报：对 seq<=afterSeq 且由对方发送、尚未计时的密文开始销毁倒计时。
  @POST('/secret-messages/{secretChatId}/read')
  Future<dynamic> markSecretMessagesRead(
    @Path('secretChatId') int secretChatId,
    @Body() Map<String, dynamic> body,
  );

  /// 会话销毁状态：返回 active 密文中最早的销毁时刻（无计时为 null）。
  @GET('/secret-messages/{secretChatId}/status')
  Future<dynamic> secretChatDestroyStatus(
      @Path('secretChatId') int secretChatId);

  /// 销毁状态增量同步（服务端权威）：返回销毁时刻晚于 afterDestroyAt 的 destroyed 密文标识。
  @GET('/secret-messages/{secretChatId}/states')
  Future<dynamic> secretChatDestroyStates(
    @Path('secretChatId') int secretChatId, {
    @Query('afterDestroyAt') String? afterDestroyAt,
    @Query('limit') int? limit,
  });

  /// 撤回（仅发送方，窗口内）：服务端协调对端渲染撤回墓碑。
  @POST('/secret-messages/{secretChatId}/recall/{msgId}')
  Future<dynamic> recallSecretMessage(
    @Path('secretChatId') int secretChatId,
    @Path('msgId') String msgId,
  );

  /// 删除（任意参与方）：服务端协调对端移除本地消息。
  @DELETE('/secret-messages/{secretChatId}/{msgId}')
  Future<dynamic> deleteSecretMessage(
    @Path('secretChatId') int secretChatId,
    @Path('msgId') String msgId,
  );

  @GET('/rtc/ice-servers')
  Future<dynamic> rtcIceConfig();

  @GET('/user-stickers')
  Future<dynamic> getUserStickers();

  @POST('/user-stickers')
  Future<dynamic> addUserSticker(@Body() Map<String, dynamic> body);

  @DELETE('/user-stickers/{id}')
  Future<void> removeUserSticker(@Path('id') int id);

  @POST('/reports')
  Future<dynamic> submitReport(@Body() Map<String, dynamic> body);

  @POST('/device-tokens')
  Future<dynamic> registerDeviceToken(@Body() Map<String, dynamic> body);

  @DELETE('/device-tokens')
  Future<void> removeDeviceToken(@Body() Map<String, dynamic> body);

  @GET('/config/client')
  Future<dynamic> getClientConfig();

  @GET('/miniapp/services')
  Future<dynamic> listMiniProgramServicesForClient({
    @Query('keyword') String? keyword,
  });

  @GET('/points/balance')
  Future<dynamic> getMyPointsBalance();

  @GET('/points/ledger')
  Future<dynamic> getMyPointsLedger({
    @Query('page') required int page,
    @Query('pageSize') required int pageSize,
    @Query('entryType') String? entryType,
    @Query('businessType') int? businessType,
  });

  @GET('/coins/info')
  Future<dynamic> getCoinInfo();

  @GET('/coins/balance')
  Future<dynamic> getMyCoinBalance();

  @GET('/coins/ledger')
  Future<dynamic> getMyCoinLedger({
    @Query('page') required int page,
    @Query('pageSize') required int pageSize,
    @Query('entryType') String? entryType,
  });

  @GET('/reservations/service-types')
  Future<dynamic> getReservationServiceTypes();

  @GET('/reservations/stores')
  Future<dynamic> getReservationStores({
    @Query('serviceTypeId') required int serviceTypeId,
  });

  @GET('/reservations/config')
  Future<dynamic> getReservationConfig();

  @POST('/reservations')
  Future<dynamic> createReservation(@Body() Map<String, dynamic> body);

  @GET('/reservations/me')
  Future<dynamic> getMyReservations({
    @Query('page') required int page,
    @Query('pageSize') required int pageSize,
    @Query('status') int? status,
    @Query('serviceTypeId') int? serviceTypeId,
  });

  @GET('/reservations/me/{orderNo}')
  Future<dynamic> getMyReservationDetail(
    @Path('orderNo') String orderNo,
  );

  @POST('/client/release-check')
  Future<dynamic> checkClientRelease(@Body() Map<String, dynamic> body);
}
