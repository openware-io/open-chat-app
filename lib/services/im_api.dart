import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/config.dart';

import 'package:gv_core/gv_core.dart';

import '../core/chat_type_wire.dart';
import '../core/upload_mime.dart';
import '../models/channel_models.dart';
import '../models/device_session.dart';
import '../models/favorite_models.dart';
import '../models/self_destruct_policy.dart';
import '../models/media_upload_result.dart';
import '../models/message_sync.dart';
import '../models/secret_chat_models.dart';
import '../models/secret_group_chat_models.dart';
import '../models/client_release_models.dart';
import 'api_client.dart';
import 'generated_im_api_client.dart';

class ImApi {
  ImApi(this._c) : _generated = GeneratedImApiClient(_c.dio);

  final ApiClient _c;
  final GeneratedImApiClient _generated;
  final Dio _mediaDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
    ),
  );

  /// 扫码登录：手机端确认桌面端登录会话。
  Future<bool> confirmQrLogin(String qrToken) async {
    final response = await _c.dio.post<dynamic>(
      '/auth/qr-login/confirm',
      data: {'qrToken': qrToken},
    );
    final raw = response.data;
    final body =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final nested = body['data'];
    final payload = nested is Map ? Map<String, dynamic>.from(nested) : body;
    return payload['ok'] == true;
  }

  DioMediaType _multipartBytesContentType(
    List<int> bytes,
    String filename,
    String? explicit,
  ) {
    if (explicit != null && explicit.trim().isNotEmpty) {
      return DioMediaType.parse(explicit);
    }
    return DioMediaType.parse(uploadMimeTypeForBytes(bytes, filename));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return map;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List) return List<dynamic>.from(data);
    if (data is Map) {
      final items = data['items'];
      if (items is List) return List<dynamic>.from(items);
      final nested = data['data'];
      if (nested is List) return List<dynamic>.from(nested);
      if (nested is Map && nested['items'] is List) {
        return List<dynamic>.from(nested['items'] as List);
      }
    }
    return const <dynamic>[];
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String password,
    required String email,
    String? nickname,
  }) async {
    final data = await _generated.register({
      'username': username,
      'password': password,
      'email': email,
      if (nickname != null) 'nickname': nickname,
    });
    return _asMap(data);
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final data = await _generated.login({
      'username': username,
      'password': password,
    });
    return _asMap(data);
  }

  Future<String> createWsTicket() async {
    final data = _asMap(await _generated.createWsTicket());
    final ticket = data['ticket']?.toString().trim() ?? '';
    if (ticket.isEmpty) {
      throw StateError('WebSocket ticket is missing');
    }
    return ticket;
  }

  Future<ImUser> getMe() async {
    final data = await _generated.getMe();
    return ImUser.fromJson(_asMap(data));
  }

  Future<ImUser> updateMe(Map<String, dynamic> body) async {
    final data = await _generated.updateMe(body);
    return ImUser.fromJson(_asMap(data));
  }

  /// 读取离线推送通知设置（私聊/群聊/频道）。
  Future<({bool notifyPrivate, bool notifyGroup, bool notifyChannel})>
      getNotificationSettings() async {
    final data = _asMap(await _generated.getNotificationSettings());
    return _notificationSettingsFrom(data);
  }

  /// 更新离线推送通知设置。
  Future<({bool notifyPrivate, bool notifyGroup, bool notifyChannel})>
      updateNotificationSettings({
    required bool notifyPrivate,
    required bool notifyGroup,
    required bool notifyChannel,
  }) async {
    final data = _asMap(
      await _generated.updateNotificationSettings({
        'notifyPrivate': notifyPrivate,
        'notifyGroup': notifyGroup,
        'notifyChannel': notifyChannel,
      }),
    );
    return _notificationSettingsFrom(data);
  }

  ({bool notifyPrivate, bool notifyGroup, bool notifyChannel})
      _notificationSettingsFrom(Map<String, dynamic> data) {
    return (
      notifyPrivate: data['notifyPrivate'] == true,
      notifyGroup: data['notifyGroup'] == true,
      notifyChannel: data['notifyChannel'] == true,
    );
  }

  /// 读取账号自毁策略。
  Future<SelfDestructPolicy> getSelfDestructPolicy() async {
    final data = _asMap(await _generated.getSelfDestructPolicy());
    return SelfDestructPolicy.fromJson(data);
  }

  /// 更新账号自毁策略（policy：off / 1mo / 3mo / 6mo / 1yr）。
  Future<SelfDestructPolicy> updateSelfDestructPolicy({
    required String policy,
  }) async {
    final data = _asMap(
      await _generated.updateSelfDestructPolicy({'policy': policy}),
    );
    return SelfDestructPolicy.fromJson(data);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _generated.changePassword({
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  /// 忘记密码：向邮箱发送重置邮件（无论邮箱是否存在都返回成功）。
  Future<void> forgotPassword({required String email}) async {
    await _generated.forgotPassword({'email': email});
  }

  /// 使用邮件中的短时令牌重置密码；令牌无效/过期会返回 401。
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _generated.resetPassword({
      'token': token,
      'newPassword': newPassword,
    });
  }

  /// 手机短信找回密码：下发短信验证码（无论手机号是否注册都返回成功）。
  Future<void> forgotPasswordBySms({required String phone}) async {
    await _c.dio.post<dynamic>(
      '/auth/password/forgot-sms',
      data: {'phone': phone},
    );
  }

  /// 凭手机短信验证码设置新密码。
  Future<void> resetPasswordBySms({
    required String phone,
    required String code,
    required String newPassword,
  }) async {
    await _c.dio.post<dynamic>(
      '/auth/password/reset-by-sms',
      data: {'phone': phone, 'code': code, 'newPassword': newPassword},
    );
  }

  /// 密保问题找回密码（需同时提供用户名、密保问题与答案）。
  Future<void> resetPasswordBySecurityQuestion({
    required String username,
    required String question,
    required String answer,
    required String newPassword,
  }) async {
    await _c.dio.post<dynamic>(
      '/auth/password/reset-by-security-question',
      data: {
        'username': username,
        'question': question,
        'answer': answer,
        'newPassword': newPassword,
      },
    );
  }

  /// 查询当前账号登录设备会话列表（登录 IP/方式/设备/最后活跃时间）。
  Future<List<DeviceSession>> listDevices() async {
    final data = _asList(await _c.dio.get<dynamic>('/devices'));
    return data
        .whereType<Map>()
        .map((e) => DeviceSession.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  /// 主设备踢出指定设备（按 deviceId）。
  Future<void> kickDevice(String deviceId) async {
    await _c.dio.post<dynamic>(
      '/devices/${Uri.encodeComponent(deviceId)}/kick',
    );
  }

  /// 副设备主动退出登录（按 deviceId）。
  Future<void> logoutDevice(String deviceId) async {
    await _c.dio.post<dynamic>(
      '/devices/${Uri.encodeComponent(deviceId)}/logout',
    );
  }

  /// 注销当前账号（需提供登录密码）；成功后客户端应清除会话。
  Future<void> deleteAccount({required String password}) async {
    await _generated.deleteAccount({'password': password});
  }

  Future<ImUser> getUser(int id) async {
    final data = await _generated.getUser(id);
    return ImUser.fromJson(_asMap(data));
  }

  Future<List<dynamic>> searchUsers(String keyword) async {
    return _asList(await _generated.searchUsers(keyword));
  }

  Future<List<FriendItem>> friendsList() async {
    final data = _asList(await _generated.friendsList());
    return data
        .map((e) => FriendItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<FriendRequestItem>> pendingRequests() async {
    final data = _asList(await _generated.pendingRequests());
    return data
        .map(
          (e) =>
              FriendRequestItem.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  Future<void> sendFriendRequest(
    int toUserId,
    String? message, {
    String? source,
    int? groupId,
  }) async {
    await _generated.sendFriendRequest({
      'toUserId': toUserId,
      'message': message ?? '',
      if (source != null && source.isNotEmpty) 'source': source,
      if (groupId != null) 'groupId': groupId,
    });
  }

  Future<void> handleFriendRequest(int id, String action) async {
    await _generated.handleFriendRequest(id, {'action': action});
  }

  Future<void> removeFriend(int friendId) async {
    await _generated.removeFriend(friendId);
  }

  Future<void> updateFriend(int friendId, Map<String, dynamic> data) async {
    await _generated.updateFriend(friendId, data);
  }

  Future<void> blockFriend(int friendId) async {
    await _generated.blockFriend(friendId);
  }

  Future<void> unblockFriend(int friendId) async {
    await _generated.unblockFriend(friendId);
  }

  Future<List<String>> friendGroups() async {
    final data = _asList(await _generated.friendGroups());
    return data.map((e) => e.toString()).toList();
  }

  Future<List<FriendItem>> blockedFriends() async {
    final data = _asList(await _generated.blockedFriends());
    return data
        .map((e) => FriendItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> muteConversation(String conversationId, bool muted) async {
    await _generated.muteConversation(conversationId, {'muted': muted});
  }

  Future<List<String>> mutedConversations() async {
    final data = _asList(await _generated.mutedConversations());
    return data
        .map(
          (e) =>
              (Map<String, dynamic>.from(
                e as Map,
              ))['conversationId']
                  ?.toString() ??
              '',
        )
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> addFavorite({
    required String msgId,
    required String peerId,
    required String chatType,
  }) async {
    await _generated.addFavorite({
      'msgId': msgId,
      'peerId': peerId,
      'chatType': chatType,
    });
  }

  Future<void> removeFavorite(String msgId) async {
    await _generated.removeFavorite(msgId);
  }

  Future<Map<String, dynamic>> listFavorites({
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await _generated.listFavorites(page: page, pageSize: pageSize);
    return _asMap(data);
  }

  /// 批量收藏：同一会话的多条消息一次提交（服务端按 msgId 幂等去重）。
  Future<FavoriteBatchResult> addFavoritesBatch({
    required String peerId,
    required String chatType,
    required List<String> messageIds,
  }) async {
    final data = await _generated.addFavoritesBatch({
      'peerId': peerId,
      'chatType': chatType,
      'messageIds': messageIds,
    });
    return FavoriteBatchResult.fromJson(_asMap(data));
  }

  /// 查询收藏对应的原消息是否仍可访问（收藏按 msgId 唯一，故按 msgId 定位）。
  Future<FavoriteSource> favoriteSource(String msgId) async {
    final data = await _generated.favoriteSource(msgId);
    return FavoriteSource.fromJson(_asMap(data));
  }

  Future<GroupItem> createGroup({
    required String name,
    required List<int> memberIds,
  }) async {
    final data = await _generated.createGroup({
      'name': name,
      'memberIds': memberIds,
    });
    return GroupItem.fromJson(_asMap(data));
  }

  Future<List<GroupItem>> myGroups() async {
    final data = _asList(await _generated.myGroups());
    return data
        .map((e) => GroupItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> groupInfo(int id) async {
    return _asMap(await _generated.groupInfo(id));
  }

  Future<List<GroupMember>> groupMembers(int id) async {
    final data = _asList(await _generated.groupMembers(id));
    return data
        .map((e) => GroupMember.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> updateGroup(int id, Map<String, dynamic> body) async {
    await _generated.updateGroup(id, body);
  }

  Future<void> addGroupMembers(int id, List<int> userIds) async {
    await _generated.addGroupMembers(id, {'userIds': userIds});
  }

  Future<void> removeGroupMember(int id, int userId) async {
    await _generated.removeGroupMember(id, userId);
  }

  Future<void> updateMyGroupNickname(int id, String nickname) async {
    await _generated.updateMyGroupNickname(id, {'nickname': nickname});
  }

  Future<void> leaveGroup(int id) async {
    await _generated.leaveGroup(id);
  }

  Future<void> dissolveGroup(int id) async {
    await _generated.dissolveGroup(id);
  }

  /// 对群成员禁言/取消禁言；[durationMinutes] 为 null 或 0 表示取消禁言。
  Future<void> muteGroupMember(int id, int userId, int? durationMinutes) async {
    await _generated.muteGroupMember(id, {
      'userId': userId,
      'duration': durationMinutes ?? 0,
    });
  }

  /// 更新群成员角色（`admin` / `member`）。
  Future<void> setGroupMemberRole(int id, int userId, String role) async {
    await _generated.setGroupMemberRole(id, {'userId': userId, 'role': role});
  }

  /// 拉取会话历史。
  ///
  /// - [beforeMsgId]：早于该消息的若干条（通常旧→新）。
  /// - [afterMsgId]：晚于该消息的若干条（锚点向较新一侧分页；需服务端支持）。
  Future<List<dynamic>> messageHistory({
    required String peerId,
    required String chatType,
    String? beforeMsgId,
    String? afterMsgId,
    String? date,
    int pageSize = 30,
  }) async {
    return _asList(
      await _generated.messageHistory(
        peerId: peerId,
        chatType: chatTypeToHttpQuery(chatType),
        pageSize: pageSize,
        beforeMsgId: beforeMsgId,
        afterMsgId: afterMsgId,
        date: date,
      ),
    );
  }

  /// 会话内「有消息」的日期列表（yyyy-MM-dd，UTC 倒序），用于聊天记录日历标记。
  Future<List<String>> messageHistoryDates({
    required String peerId,
    required String chatType,
  }) async {
    final data = await _generated.messageHistoryDates(
      peerId: peerId,
      chatType: chatTypeToHttpQuery(chatType),
    );
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return const <String>[];
  }

  /// 以 [centerMsgId] 为中心一次拉取前后若干条（旧→新）。
  ///
  /// 服务端可在同一 `GET /messages/history` 上识别 `centerMsgId` + `beforeCount` + `afterCount`；
  /// 未实现时返回空列表，客户端将退回「before + after 两次分页」。
  Future<List<dynamic>> messageHistoryCentered({
    required String peerId,
    required String chatType,
    required String centerMsgId,
    int beforeCount = 30,
    int afterCount = 30,
  }) async {
    try {
      final data = await _generated.messageHistoryCentered(
        peerId: peerId,
        chatType: chatTypeToHttpQuery(chatType),
        centerMsgId: centerMsgId,
        beforeCount: beforeCount,
        afterCount: afterCount,
      );
      if (data is List) return data;
      if (data is Map) {
        final items = data['items'];
        if (items is List) return List<dynamic>.from(items);
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  Future<MessageSyncPage> syncMessages({
    required int afterSyncSeq,
    int limit = 200,
  }) async {
    final data = await _generated.syncMessages(
      afterSyncSeq: afterSyncSeq,
      limit: limit,
    );
    return MessageSyncPage.fromJson(_asMap(data));
  }

  /// 服务端返回 `{ items, total, page, pageSize }`，此处只取出 `items` 列表。
  Future<List<dynamic>> searchChatMessages({
    String? peerId,
    String? chatType,
    required String keyword,
    String msgType = 'text',
    int page = 1,
    int pageSize = 30,
    String? beforeMsgId,
  }) async {
    final data = await _generated.searchChatMessages(
      keyword: keyword,
      page: page,
      pageSize: pageSize,
      msgType: messageTypeToHttpQuery(msgType),
      peerId: peerId,
      chatType: chatType == null ? null : chatTypeToHttpQuery(chatType),
      beforeMsgId: beforeMsgId,
    );
    if (data is Map) {
      final items = data['items'];
      if (items is List) return List<dynamic>.from(items);
    }
    if (data is List) return data;
    return [];
  }

  Future<void> markRead(List<String> msgIds) async {
    if (msgIds.isEmpty) return;
    await _generated.markRead({'msgIds': msgIds});
  }

  Future<void> recallMessage(String msgId) async {
    await _generated.recallMessage({'msgId': msgId});
  }

  /// 发送者删除该条消息（服务端删库；私聊双方/群全员同步移除）。
  Future<void> deleteMessageForEveryone(String msgId) async {
    await _generated.deleteMessageForEveryone({'msgId': msgId});
  }

  /// 「删除仅我」：POST /messages/delete-for-me。
  ///
  /// 服务端为这些消息写入 per-user 墓碑（只对该用户隐藏，不影响对方），
  /// 因此卸载重装后重新同步也不会把消息“复活”。
  /// 未走 generated 客户端是因为该端点较新，避免此处依赖生成代码的重新生成。
  Future<int> deleteMessagesForMe(List<String> msgIds) async {
    if (msgIds.isEmpty) return 0;
    final response = await _c.dio.post<dynamic>('/messages/delete-for-me',
        data: {'msgIds': msgIds});
    final data = _asMap(response.data);
    final deleted = data['deleted'];
    return deleted is int ? deleted : int.tryParse('$deleted') ?? 0;
  }

  /// 编辑消息正文：POST /messages/edit（发送后 2 分钟内仅发送者本人）。
  /// 响应为 `{ msgId, edited, editedAt }`，新正文由调用方本地回写。
  Future<Map<String, dynamic>> editMessage({
    required String msgId,
    required String newContent,
  }) async {
    final response = await _c.dio.post<dynamic>(
      '/messages/edit',
      data: {'msgId': msgId, 'newContent': newContent},
    );
    return _asMap(response.data);
  }

  /// 未读消息总数：GET /messages/unread-count（响应 `{ count }`）。
  Future<int> unreadCount() async {
    final response = await _c.dio.get<dynamic>('/messages/unread-count');
    final data = _asMap(response.data);
    final raw = data['count'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  /// 按会话未读数：GET /messages/unread-by-conversation。
  Future<List<({String conversationId, int count})>> unreadByConversation() async {
    final raw = await _c.dio.get<dynamic>('/messages/unread-by-conversation');
    return _asList(raw.data)
        .whereType<Map>()
        .map((e) {
          final map = Map<String, dynamic>.from(e);
          final count = map['count'];
          return (
            conversationId: map['conversationId']?.toString() ?? '',
            count: count is int
                ? count
                : (count is num ? count.toInt() : (int.tryParse(count?.toString() ?? '') ?? 0)),
          );
        })
        .where((e) => e.conversationId.isNotEmpty)
        .toList(growable: false);
  }

  /// 纯 TURN ICE（iceTransportPolicy=relay），与信令 rtcIceConfig 同源。
  Future<Map<String, dynamic>> rtcIceConfig() async {
    final raw = await _generated.rtcIceConfig();

    // 当前服务端直接返回 RTCIceServer 数组：
    // [{ urls: [...], username: '...', credential: '...' }]
    // CallProvider 需要标准 RTCConfiguration 外层结构。
    if (raw is List) {
      return <String, dynamic>{
        'iceServers': List<dynamic>.from(raw),
        'iceTransportPolicy': 'relay',
      };
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final nested = map['data'];
      if (nested is List) {
        return <String, dynamic>{
          'iceServers': List<dynamic>.from(nested),
          'iceTransportPolicy': map['iceTransportPolicy'] ?? 'relay',
        };
      }
      if (map['iceServers'] is List) {
        map['iceServers'] = List<dynamic>.from(map['iceServers'] as List);
        map['iceTransportPolicy'] ??= 'relay';
        return map;
      }
    }

    return <String, dynamic>{};
  }

  Future<MediaUploadResult> uploadFile(
    String filePath,
    String filename, {
    String scope = 'chat',
    String? mediaKind,
    int? durationMs,
    String? contentType,
    ProgressCallback? onSendProgress,
  }) async {
    final file = File(filePath);
    final size = await file.length();
    final digest = await sha256.bind(file.openRead()).first;
    // Prefer the real file signature over the caller-provided filename. Image
    // preprocessing can change PNG/WebP bytes into JPEG while retaining the
    // source name; declaring the stale MIME makes server-side validation reject
    // the upload after it has already completed.
    final header = size == 0
        ? const <int>[]
        : await file
            .openRead(0, min(size, 12))
            .expand((chunk) => chunk)
            .toList();
    final resolvedType = _multipartBytesContentType(
      header,
      filename,
      contentType,
    ).toString();
    return _uploadManagedMedia(
      scope: _mediaScope(scope),
      mediaKind: mediaKind ?? _mediaKindForContentType(resolvedType),
      filename: filename,
      contentType: resolvedType,
      size: size,
      checksum: digest.toString(),
      durationMs: durationMs,
      openRead: (start, end) => file.openRead(start, end),
      onSendProgress: onSendProgress,
    );
  }

  Future<MediaUploadResult> uploadBytes(
    List<int> bytes,
    String filename, {
    String scope = 'chat',
    String? mediaKind,
    int? durationMs,
    String? contentType,
  }) async {
    // 尽量使用 Uint8List 视图（不复制），避免 Web 大文件分片时整块拷贝驻留内存。
    final Uint8List buffer =
        bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    final resolvedType = _multipartBytesContentType(
      bytes,
      filename,
      contentType,
    ).toString();
    return _uploadManagedMedia(
      scope: _mediaScope(scope),
      mediaKind: mediaKind ?? _mediaKindForContentType(resolvedType),
      filename: filename,
      contentType: resolvedType,
      size: bytes.length,
      checksum: sha256.convert(bytes).toString(),
      durationMs: durationMs,
      openRead: (start, end) =>
          Stream<List<int>>.value(Uint8List.sublistView(buffer, start, end)),
    );
  }

  Future<MediaUploadResult> _uploadManagedMedia({
    required String scope,
    required String mediaKind,
    required String filename,
    required String contentType,
    required int size,
    required String checksum,
    required Stream<List<int>> Function(int start, int end) openRead,
    int? durationMs,
    ProgressCallback? onSendProgress,
  }) async {
    const multipartThreshold = 20 * 1024 * 1024;
    if (size > multipartThreshold) {
      return _uploadManagedMediaMultipart(
        scope: scope,
        mediaKind: mediaKind,
        filename: filename,
        contentType: contentType,
        size: size,
        checksum: checksum,
        durationMs: durationMs,
        openRead: openRead,
        onSendProgress: onSendProgress,
      );
    }
    final session = _asMap(
      (await _c.dio.post<dynamic>(
        '/media/upload-sessions',
        data: {
          'scope': scope,
          'mediaKind': mediaKind,
          'fileName': filename,
          'contentType': contentType,
          'size': size,
          'sha256': checksum,
          if (durationMs != null) 'durationMs': durationMs,
        },
      ))
          .data,
    );
    final sessionId = _requiredString(session, 'uploadSessionId');
    final objectId = _requiredString(session, 'objectId');
    final uploadUrl = _requiredString(session, 'uploadUrl');
    _requireManagedMediaUrl(uploadUrl);
    // 后端可在上传会话响应中下发 requiredHeaders（如 Content-Disposition），
    // 客户端原样透传到直传 PUT；缺省为空 Map 时行为不变（Content-Type 仍由
    // Options.contentType 设置）。
    final rawHeaders = session['requiredHeaders'];
    final requiredHeaders = rawHeaders is Map
        ? rawHeaders.map((key, value) => MapEntry('$key', '$value'))
        : <String, String>{};

    if (kDebugMode) {
      debugPrint('[MEDIA DEBUG] PUT ${_safeOrigin(Uri.tryParse(uploadUrl))}');
    }
    await Dio().put<void>(
      uploadUrl,
      data: openRead(0, size),
      options: Options(
        headers: {...requiredHeaders, HttpHeaders.contentLengthHeader: size},
        contentType: contentType,
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 3),
      ),
      onSendProgress: onSendProgress,
    );

    await _c.dio.post<dynamic>(
      '/media/upload-sessions/$sessionId/complete',
      data: {'size': size, 'sha256': checksum},
    );
    await _waitForMediaActive(objectId);
    return _mediaUploadResult(
      objectId: objectId,
      fallbackContentType: contentType,
      fallbackSize: size,
    );
  }

  Future<MediaUploadResult> _uploadManagedMediaMultipart({
    required String scope,
    required String mediaKind,
    required String filename,
    required String contentType,
    required int size,
    required String checksum,
    required Stream<List<int>> Function(int start, int end) openRead,
    int? durationMs,
    ProgressCallback? onSendProgress,
  }) async {
    final session = _asMap(
      (await _c.dio.post<dynamic>(
        '/media/multipart-upload-sessions',
        data: {
          'scope': scope,
          'mediaKind': mediaKind,
          'fileName': filename,
          'contentType': contentType,
          'size': size,
          'sha256': checksum,
          if (durationMs != null) 'durationMs': durationMs,
        },
      ))
          .data,
    );
    final sessionId = _requiredString(session, 'uploadSessionId');
    final objectId = _requiredString(session, 'objectId');
    final partSize = int.tryParse('${session['partSize']}') ?? 0;
    final partCount = int.tryParse('${session['partCount']}') ?? 0;
    if (partSize <= 0 || partCount <= 0) {
      throw StateError('Multipart upload response is incomplete');
    }

    final signatures = _asMap(
      (await _c.dio.post<dynamic>(
        '/media/multipart-upload-sessions/$sessionId/parts/signatures',
        data: {
          'partNumbers': [for (var i = 1; i <= partCount; i++) i],
        },
      ))
          .data,
    );
    final rawPartUrls = signatures['partUrls'];
    if (rawPartUrls is! List || rawPartUrls.length != partCount) {
      throw StateError('Multipart upload signatures are incomplete');
    }
    final urlByPart = <int, String>{};
    for (final raw in rawPartUrls.whereType<Map>()) {
      final part = int.tryParse('${raw['partNumber']}');
      final url = raw['uploadUrl']?.toString() ?? '';
      if (part != null && url.isNotEmpty) urlByPart[part] = url;
    }

    final completed = <Map<String, dynamic>>[];
    var completedBytes = 0;
    for (var partNumber = 1; partNumber <= partCount; partNumber++) {
      final uploadUrl = urlByPart[partNumber];
      if (uploadUrl == null) {
        throw StateError(
          'Multipart upload URL is missing for part $partNumber',
        );
      }
      _requireManagedMediaUrl(uploadUrl);
      final start = (partNumber - 1) * partSize;
      final end = min(start + partSize, size);
      final length = end - start;
      final response = await Dio().put<void>(
        uploadUrl,
        data: openRead(start, end),
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: contentType,
            HttpHeaders.contentLengthHeader: length,
          },
          contentType: contentType,
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 3),
        ),
        onSendProgress: onSendProgress == null
            ? null
            : (sent, _) => onSendProgress(completedBytes + sent, size),
      );
      final etag = response.headers.value('etag')?.trim() ?? '';
      if (etag.isEmpty) {
        throw StateError('Multipart upload response is missing ETag');
      }
      await _c.dio.post<dynamic>(
        '/media/multipart-upload-sessions/$sessionId/parts/'
        '$partNumber/complete',
        data: {'etag': etag},
      );
      completed.add({'partNumber': partNumber, 'etag': etag});
      completedBytes += length;
      onSendProgress?.call(completedBytes, size);
    }

    await _c.dio.post<dynamic>(
      '/media/multipart-upload-sessions/$sessionId/complete',
      data: {'parts': completed, 'size': size, 'sha256': checksum},
    );
    await _waitForMediaActive(objectId);
    return _mediaUploadResult(
      objectId: objectId,
      fallbackContentType: contentType,
      fallbackSize: size,
    );
  }

  Future<MediaUploadResult> _mediaUploadResult({
    required String objectId,
    required String fallbackContentType,
    required int fallbackSize,
  }) async {
    final access = _asMap(
      (await _c.dio.get<dynamic>('/media/$objectId/access')).data,
    );
    final url = _requiredString(access, 'url');
    _requireManagedMediaUrl(url);
    return MediaUploadResult(
      objectId: objectId,
      url: url,
      contentType: access['contentType']?.toString() ?? fallbackContentType,
      size: int.tryParse('${access['size']}') ?? fallbackSize,
    );
  }

  Future<void> _waitForMediaActive(String objectId) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      final status = _asMap(
        (await _c.dio.get<dynamic>('/media/$objectId')).data,
      )['status']
          ?.toString()
          .toLowerCase();
      if (status == 'active') return;
      if (status == 'rejected' || status == 'deleted') {
        throw StateError('Media processing failed with status: $status');
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    throw TimeoutException('Media processing timed out');
  }

  String _mediaScope(String value) => switch (value) {
        'profile' => 'avatar',
        'emoji' => 'chat',
        _ => value,
      };

  String _mediaKindForContentType(String contentType) {
    if (contentType.startsWith('image/')) return 'image';
    if (contentType.startsWith('audio/')) return 'audio';
    if (contentType.startsWith('video/')) return 'video';
    return 'attachment';
  }

  String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key]?.toString().trim() ?? '';
    if (value.isEmpty) throw StateError('Media response is missing $key');
    return value;
  }

  void _requireManagedMediaUrl(String value) {
    final actual = Uri.tryParse(value);
    final expected = Uri.tryParse(AppConfig.mediaBase);
    final actualPort =
        actual?.hasPort == true ? actual!.port : _defaultPort(actual);
    final expectedPort =
        expected?.hasPort == true ? expected!.port : _defaultPort(expected);
    if (actual == null ||
        expected == null ||
        !actual.isAbsolute ||
        (actual.scheme != 'http' && actual.scheme != 'https') ||
        actual.scheme != expected.scheme ||
        actual.host != expected.host ||
        actualPort != expectedPort) {
      throw StateError(
        'Media URL origin is not managed: actual=${_safeOrigin(actual)}, '
        'expected=${_safeOrigin(expected)}',
      );
    }
  }

  int? _defaultPort(Uri? uri) => switch (uri?.scheme) {
        'http' => 80,
        'https' => 443,
        _ => null,
      };

  /// 下载服务端返回的受管绝对媒体 URL。
  Future<void> downloadFileToPath(String fileUrl, String savePath) async {
    final uri = resolveMediaUrl(AppConfig.mediaBase, fileUrl);
    if (uri.isEmpty) throw const FormatException('Invalid managed media URL');
    _requireManagedMediaUrl(uri);
    if (kDebugMode) {
      debugPrint('[MEDIA DEBUG] GET ${Uri.parse(uri).replace(query: '')}');
    }
    await _mediaDio.download(
      uri,
      savePath,
      options: Options(receiveTimeout: const Duration(minutes: 10)),
    );
  }

  /// Web 等无法落盘场景：仅使用对象存储签名 URL 拉取文件字节。
  Future<Uint8List> downloadFileBytes(String fileUrl) async {
    final uri = resolveMediaUrl(AppConfig.mediaBase, fileUrl);
    if (uri.isEmpty) throw const FormatException('Invalid managed media URL');
    _requireManagedMediaUrl(uri);
    if (kDebugMode) {
      debugPrint('[MEDIA DEBUG] GET ${Uri.parse(uri).replace(query: '')}');
    }
    final r = await _mediaDio.get<List<int>>(
      uri,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 10),
      ),
    );
    final data = r.data;
    if (data == null) {
      throw StateError('downloadFileBytes: empty body');
    }
    return data is Uint8List ? data : Uint8List.fromList(data);
  }

  String _safeOrigin(Uri? uri) {
    if (uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return '<invalid>';
    }
    return uri.hasPort
        ? '${uri.scheme}://${uri.host}:${uri.port}'
        : '${uri.scheme}://${uri.host}';
  }

  // ─── Client Config ───

  Future<Map<String, dynamic>> getClientConfig() async {
    return _asMap(await _generated.getClientConfig());
  }

  // ─── Clear Chat ───

  Future<Map<String, dynamic>> clearPrivateChat(String peerId) async {
    return _asMap(await _generated.clearPrivateChat({'peerId': peerId}));
  }

  Future<Map<String, dynamic>> clearGroupChat(String groupId) async {
    return _asMap(await _generated.clearGroupChat({'groupId': groupId}));
  }

  // ─── Channels (频道：单向广播) ───

  /// 创建频道（仅管理员语义由服务端 owner 校验）。返回频道详情。
  Future<ChannelInfo> createChannel({
    required String name,
    String? description,
  }) async {
    final data = await _generated.createChannel({
      'name': name,
      if (description != null && description.trim().isNotEmpty)
        'announcement': description.trim(),
    });
    return ChannelInfo.fromJson(_asMap(data));
  }

  /// 我的频道（创建的 + 已订阅的）。
  Future<List<ChannelInfo>> myChannels() async {
    final list = _asList(await _generated.myChannels());
    return list
        .whereType<Map>()
        .map((e) => ChannelInfo.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  /// 频道详情：含 [ChannelInfo.ownerId]，用于订阅者/管理员判定。
  Future<ChannelInfo> channelInfo(String id) async {
    final data = await _generated.channelInfo(id);
    return ChannelInfo.fromJson(_asMap(data));
  }

  /// 订阅频道（订阅者可读历史；重复订阅由服务端幂等处理）。
  Future<ChannelInfo> subscribeChannel(String id) async {
    final data = await _generated.subscribeChannel(id);
    return ChannelInfo.fromJson(_asMap(data));
  }

  /// 取消订阅频道（幂等）。
  Future<void> unsubscribeChannel(String id) async {
    await _generated.unsubscribeChannel(id);
  }

  /// 更新频道信息（名称/公告），仅 owner。
  Future<ChannelInfo> updateChannel(
    String id, {
    String? name,
    String? announcement,
  }) async {
    final data = await _generated.updateChannel(id, {
      if (name != null) 'name': name,
      if (announcement != null) 'announcement': announcement,
    });
    return ChannelInfo.fromJson(_asMap(data));
  }

  /// 删除频道（硬删除），仅 owner。
  Future<void> deleteChannel(String id) async {
    await _generated.deleteChannel(id);
  }

  /// 按名称搜索公开频道（返回含订阅状态的结果）。
  Future<List<ChannelInfo>> searchChannels(
    String keyword, {
    int limit = 20,
  }) async {
    final list = _asList(
      await _generated.searchChannels(keyword: keyword, limit: limit),
    );
    return list
        .whereType<Map>()
        .map((e) => ChannelInfo.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  /// 通过频道号（分享码）查频道。
  Future<ChannelInfo> channelByCode(String code) async {
    final data = await _generated.channelByCode(code);
    return ChannelInfo.fromJson(_asMap(data));
  }

  // ─── Secret Chats (私密聊天：E2EE 形态) ───

  /// 发起私密聊天；返回会话实体（含安全码 [SecretChatInfo.safeCode]）。
  /// [publicKey] 为本端设备公钥：创建时后端预填双方公钥，双方齐备即 ready，
  /// 发起方无需等对方接受/在线即可加密发送。
  Future<SecretChatInfo> createSecretChat({
    required int peerUserId,
    String? publicKey,
  }) async {
    final data = await _generated.createSecretChat({
      'userB': peerUserId,
      if (publicKey != null && publicKey.isNotEmpty) 'publicKey': publicKey,
    });
    return SecretChatInfo.fromJson(_asMap(data));
  }

  /// 我的私密会话列表。
  Future<List<SecretChatInfo>> mySecretChats() async {
    final list = _asList(await _generated.mySecretChats());
    return list
        .whereType<Map>()
        .map((e) => SecretChatInfo.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  /// 设置私密会话定时销毁策略（off / 30s / 5m / 1h / 1d）。
  Future<SecretChatInfo> destroySecretChatPolicy({
    required String id,
    required String policy,
  }) async {
    final data = await _generated.destroySecretChatPolicy(id, {
      'policy': policy,
    });
    return SecretChatInfo.fromJson(_asMap(data));
  }

  /// 删除私密会话（任意一方删除即终止，双方列表都不再返回）。
  Future<void> deleteSecretChat(String id) async {
    await _generated.deleteSecretChat(id);
  }

  /// 私密会话详情（含双方公钥与握手状态，供 E2EE 握手使用）。
  Future<SecretChatInfo> secretChatInfo(String id) async {
    final data = await _generated.secretChatInfo(id);
    return SecretChatInfo.fromJson(_asMap(data));
  }

  /// 提交本端公钥参与 E2EE 握手；双方齐备后会话进入 ready 并返回安全码。
  Future<SecretChatInfo> submitSecretChatHandshake({
    required String id,
    required String publicKey,
  }) async {
    final data = await _generated.submitSecretChatHandshake(id, {
      'publicKey': publicKey,
    });
    return SecretChatInfo.fromJson(_asMap(data));
  }

  // ─── Secret Group Chats (私密群聊：逐成员 E2EE) ───

  /// 发起私密群聊；body `memberUserIds`（不含群主，群主=当前用户）。
  Future<SecretGroupChatInfo> createSecretGroupChat({
    required List<int> memberUserIds,
  }) async {
    final data = await _generated.createSecretGroupChat({
      'memberUserIds': memberUserIds,
    });
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 我的私密群聊列表。
  Future<List<SecretGroupChatInfo>> mySecretGroupChats() async {
    final list = _asList(await _generated.mySecretGroupChats());
    return list
        .whereType<Map>()
        .map((e) => SecretGroupChatInfo.fromJson(_asMap(e)))
        .toList(growable: false);
  }

  /// 私密群聊详情（含成员公钥/安全码/销毁策略）。
  Future<SecretGroupChatInfo> secretGroupChatInfo(String id) async {
    final data = await _generated.secretGroupChatInfo(id);
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 拉入新成员；body `{"userId":10}`。
  Future<SecretGroupChatInfo> addSecretGroupMember({
    required String id,
    required int userId,
  }) async {
    final data = await _generated.addSecretGroupMember(id, {'userId': userId});
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 提交本设备公钥参与群握手；全员齐备后 `safeCode` 由服务端生成。
  Future<SecretGroupChatInfo> submitSecretGroupHandshake({
    required String id,
    required String publicKey,
  }) async {
    final data = await _generated.submitSecretGroupHandshake(id, {
      'publicKey': publicKey,
    });
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 设置私密群聊定时销毁策略。
  Future<SecretGroupChatInfo> setSecretGroupDestroyPolicy({
    required String id,
    required String policy,
  }) async {
    final data = await _generated.setSecretGroupDestroyPolicy(id, {
      'policy': policy,
    });
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 设置私密群聊匿名发言开关（仅群主）。
  Future<SecretGroupChatInfo> setSecretGroupAnonymous({
    required String id,
    required bool enabled,
  }) async {
    final data = await _generated.setSecretGroupAnonymous(id, {
      'enabled': enabled,
    });
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 置顶私密群聊消息（仅群主）。
  Future<SecretGroupChatInfo> pinSecretGroupMessage({
    required String id,
    required String msgId,
  }) async {
    final data = await _generated.pinSecretGroupMessage(id, {'msgId': msgId});
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 取消置顶（仅群主）。
  Future<SecretGroupChatInfo> unpinSecretGroupMessage(String id) async {
    final data = await _generated.unpinSecretGroupMessage(id);
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 生成私密群聊邀请令牌（仅群主）。
  Future<SecretGroupChatInfo> generateSecretGroupInvite(String id) async {
    final data = await _generated.generateSecretGroupInvite(id);
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 凭邀请令牌加入私密群聊。
  Future<SecretGroupChatInfo> joinSecretGroupByInvite(String token) async {
    final data = await _generated.joinSecretGroupByInvite({'token': token});
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 设置私密群聊「仅群主可发言」（仅群主）。
  Future<SecretGroupChatInfo> setSecretGroupOwnerOnlyPost({
    required String id,
    required bool enabled,
  }) async {
    final data = await _generated.setSecretGroupOwnerOnlyPost(id, {
      'enabled': enabled,
    });
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 设置私密群聊名称（仅群主）。
  Future<SecretGroupChatInfo> setSecretGroupName({
    required String id,
    required String name,
  }) async {
    final data = await _generated.setSecretGroupName(id, {'name': name});
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 设置私密群聊公告（仅群主）。
  Future<SecretGroupChatInfo> setSecretGroupAnnouncement({
    required String id,
    required String announcement,
  }) async {
    final data = await _generated.setSecretGroupAnnouncement(id, {
      'announcement': announcement,
    });
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 移除私密群聊成员（仅群主，不可移除自己）。
  Future<SecretGroupChatInfo> removeSecretGroupMember({
    required String id,
    required int userId,
  }) async {
    final data = await _generated.removeSecretGroupMember(id, userId);
    return SecretGroupChatInfo.fromJson(_asMap(data));
  }

  /// 退出私密群聊。
  Future<void> leaveSecretGroupChat(String id) async {
    await _generated.leaveSecretGroupChat(id);
  }

  /// 删除（解散）私密群聊，仅群主。
  Future<void> deleteSecretGroupChat(String id) async {
    await _generated.deleteSecretGroupChat(id);
  }

  /// 逐成员密文上报：`recipients` 为 `{userId, ciphertext}` 列表（不含发送方）。
  Future<Map<String, dynamic>> postSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
    required List<Map<String, dynamic>> recipients,
    List<String>? mediaObjectIds,
    List<dynamic>? atUsers,
  }) async {
    return _asMap(
      await _generated.postSecretGroupMessage({
        'secretGroupId': secretGroupId,
        'msgId': msgId,
        'recipients': recipients,
        if (mediaObjectIds != null && mediaObjectIds.isNotEmpty)
          'mediaObjectIds': mediaObjectIds,
        if (atUsers != null && atUsers.isNotEmpty) 'atUserIds': atUsers,
      }),
    );
  }

  /// 编辑私密群聊消息（仅发送方）：保留 msgId，逐成员替换密文。
  Future<Map<String, dynamic>> editSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
    required List<Map<String, dynamic>> recipients,
  }) async {
    return _asMap(
      await _generated.editSecretGroupMessage({
        'secretGroupId': secretGroupId,
        'msgId': msgId,
        'recipients': recipients,
      }),
    );
  }

  /// 游标拉取本端可读的密文（只返回接收方=当前用户的消息）。
  Future<List<Map<String, dynamic>>> listSecretGroupMessages({
    required int secretGroupId,
    int afterSeq = 0,
    int limit = 50,
  }) async {
    return _asList(
      await _generated.listSecretGroupMessages(
        secretGroupId: secretGroupId,
        afterSeq: afterSeq,
        limit: limit,
      ),
    ).whereType<Map>().map(_asMap).toList(growable: false);
  }

  /// 重新换取私密群聊消息媒体访问 URL（参与方授权）。
  Future<List<Map<String, dynamic>>> resolveSecretGroupMessageMediaUrls({
    required int secretGroupId,
    required String msgId,
    required List<String> objectIds,
  }) async {
    final response = await _c.dio.post<dynamic>(
      '/secret-group-messages/media/access-urls',
      data: {
        'secretGroupId': secretGroupId,
        'msgId': msgId,
        'objectIds': objectIds,
      },
    );
    return _asList(response.data)
        .whereType<Map>()
        .map(_asMap)
        .toList(growable: false);
  }

  /// 接收方已读上报：对 seq<=afterSeq 且由对方发送、尚未计时的密文开始销毁倒计时。
  Future<Map<String, dynamic>> markSecretGroupRead({
    required int secretGroupId,
    required int afterSeq,
  }) async {
    return _asMap(
      await _generated.markSecretGroupRead({
        'secretGroupId': secretGroupId,
        'afterSeq': afterSeq,
      }),
    );
  }

  /// 销毁状态增量同步（服务端权威）：返回撤回/删除痕迹（msgId + destroyAt + reason）。
  Future<List<Map<String, dynamic>>> listSecretGroupDestroyedStates(
    int secretGroupId, {
    String? afterDestroyAt,
    int limit = 100,
  }) async {
    final data = _asMap(
      await _generated.listSecretGroupDestroyedStates(
        secretGroupId: secretGroupId,
        afterDestroyAt: afterDestroyAt,
        limit: limit,
      ),
    );
    final destroyed = data['destroyed'];
    if (destroyed is! List) return const [];
    return destroyed.whereType<Map>().map(_asMap).toList(growable: false);
  }

  /// 撤回私密群聊消息（仅发送方，不限时）：服务端协调全员移除。
  Future<void> recallSecretGroupMessage({
    required int secretGroupId,
    required String msgId,
  }) async {
    await _generated.recallSecretGroupMessage(
      msgId,
      secretGroupId: secretGroupId,
    );
  }

  /// 删除私密群聊消息所有人（仅发送方，不限时）：服务端协调全员移除。
  Future<void> deleteSecretGroupMessageForEveryone({
    required int secretGroupId,
    required String msgId,
  }) async {
    await _generated.deleteSecretGroupMessageForEveryone(
      msgId,
      secretGroupId: secretGroupId,
    );
  }

  /// 注册本设备 E2EE 公钥（设备身份）。
  Future<Map<String, dynamic>> registerDeviceKey({
    required String deviceId,
    required String publicKey,
  }) async {
    return _asMap(
      await _generated.registerDeviceKey({
        'deviceId': deviceId,
        'publicKey': publicKey,
      }),
    );
  }

  /// 我的设备密钥列表。
  Future<List<Map<String, dynamic>>> myDeviceKeys() async {
    return _asList(await _generated.myDeviceKeys())
        .whereType<Map>()
        .map(_asMap)
        .toList(growable: false);
  }

  /// 上报私密消息密文（服务端不解密，仅存储与游标同步）。
  Future<Map<String, dynamic>> postSecretMessage({
    required int secretChatId,
    required String msgId,
    required String ciphertext,
    List<String>? mediaObjectIds,
  }) async {
    return _asMap(
      await _generated.postSecretMessage({
        'secretChatId': secretChatId,
        'msgId': msgId,
        'ciphertext': ciphertext,
        if (mediaObjectIds != null && mediaObjectIds.isNotEmpty)
          'mediaObjectIds': mediaObjectIds,
      }),
    );
  }

  /// 游标拉取私密消息密文（纯拉取，不触发销毁计时；计时由已读上报触发）。
  Future<List<Map<String, dynamic>>> listSecretMessages({
    required int secretChatId,
    int afterSeq = 0,
    int limit = 50,
  }) async {
    return _asList(
      await _generated.listSecretMessages(
        secretChatId: secretChatId,
        afterSeq: afterSeq,
        limit: limit,
      ),
    ).whereType<Map>().map(_asMap).toList(growable: false);
  }

  /// 重新换取私密消息媒体访问 URL（参与方授权）：媒体签名 URL 过期后按消息引用换新鲜 URL。
  Future<List<Map<String, dynamic>>> resolveSecretMessageMediaUrls({
    required int secretChatId,
    required String msgId,
    required List<String> objectIds,
  }) async {
    final response = await _c.dio.post<dynamic>(
      '/secret-messages/media/access-urls',
      data: {
        'secretChatId': secretChatId,
        'msgId': msgId,
        'objectIds': objectIds,
      },
    );
    return _asList(response.data)
        .whereType<Map>()
        .map(_asMap)
        .toList(growable: false);
  }

  /// 接收方已读上报：对 seq<=afterSeq 且由对方发送、尚未计时的密文开始销毁倒计时。
  /// 仅当本端真正解密展示到消息后才应调用——未查阅/未解密成功的消息不进入计时。
  /// 响应携带本次计时截止 destroyAt（UTC），供客户端设置本地销毁定时器。
  Future<Map<String, dynamic>> markSecretMessagesRead({
    required int secretChatId,
    required int afterSeq,
  }) async {
    return _asMap(
      await _generated.markSecretMessagesRead(secretChatId, {
        'afterSeq': afterSeq,
      }),
    );
  }

  /// 会话销毁状态：返回 active 密文中最早的销毁时刻（无计时为 null，UTC）。
  Future<Map<String, dynamic>> secretChatDestroyStatus(int secretChatId) async {
    return _asMap(await _generated.secretChatDestroyStatus(secretChatId));
  }

  /// 销毁状态增量同步（服务端权威）：返回销毁时刻晚于 [afterDestroyAt] 的
  /// destroyed 密文标识（msgId + destroyAt，UTC）。端侧按此移除本地消息。
  Future<List<Map<String, dynamic>>> secretChatDestroyStates(
    int secretChatId, {
    String? afterDestroyAt,
    int limit = 100,
  }) async {
    final data = _asMap(
      await _generated.secretChatDestroyStates(
        secretChatId,
        afterDestroyAt: afterDestroyAt,
        limit: limit,
      ),
    );
    final destroyed = data['destroyed'];
    if (destroyed is! List) return const [];
    return destroyed.whereType<Map>().map(_asMap).toList(growable: false);
  }

  /// 撤回私密消息（仅发送方，窗口内）：服务端协调对端渲染撤回墓碑。
  Future<void> recallSecretMessage({
    required int secretChatId,
    required String msgId,
  }) async {
    await _generated.recallSecretMessage(secretChatId, msgId);
  }

  /// 删除私密消息（任意参与方）：服务端协调对端移除本地消息。
  Future<void> deleteSecretMessage({
    required int secretChatId,
    required String msgId,
  }) async {
    await _generated.deleteSecretMessage(secretChatId, msgId);
  }

  // ─── User Stickers (我的表情) ───

  Future<List<dynamic>> getUserStickers() async {
    return _asList(await _generated.getUserStickers());
  }

  Future<Map<String, dynamic>> addUserSticker(
    String url, {
    String? thumbnail,
  }) async {
    return _asMap(
      await _generated.addUserSticker({
        'url': url,
        if (thumbnail != null) 'thumbnail': thumbnail,
      }),
    );
  }

  Future<void> removeUserSticker(int id) async {
    await _generated.removeUserSticker(id);
  }

  // ─── Report (举报) ───

  Future<Map<String, dynamic>> submitReport({
    required int targetId,
    required String reason,
    String? description,
    String? evidence,
  }) async {
    return _asMap(
      await _generated.submitReport({
        'targetId': targetId,
        'reason': reason,
        if (description != null) 'description': description,
        if (evidence != null) 'evidence': evidence,
      }),
    );
  }

  // ─── Device Push Token ───

  /// [pushProvider]：本 App 移动端统一使用 `jpush`；`apns`/`fcm` 仅服务端保留以兼容旧客户端。
  Future<Map<String, dynamic>> registerDeviceToken({
    required String token,
    required String platform,
    required String pushProvider,
    String? deviceId,
  }) async {
    return _asMap(
      await _generated.registerDeviceToken({
        'token': token,
        'platform': platform,
        'pushProvider': pushProvider,
        if (deviceId != null) 'deviceId': deviceId,
      }),
    );
  }

  Future<void> removeDeviceToken(String token, {String? pushProvider}) async {
    await _generated.removeDeviceToken({
      'token': token,
      if (pushProvider != null) 'pushProvider': pushProvider,
    });
  }

  /// 服务 Tab：`GET /miniapp/services`（分组列表）
  Future<List<MiniAppServiceCategory>>
      listMiniProgramServicesForClient() async {
    final data = await _generated.listMiniProgramServicesForClient();
    return MiniAppServiceCategory.parseResponse(data);
  }

  /// 服务 Tab 搜索：`GET /miniapp/services?keyword=...`（平铺服务项列表）
  Future<List<MiniAppServiceItem>> searchMiniProgramServices(
    String keyword,
  ) async {
    final data = await _generated.listMiniProgramServicesForClient(
      keyword: keyword,
    );
    return MiniAppServiceCategory.parseResponse(data)
        .expand((c) => c.items)
        .toList(growable: false);
  }

  /// 无需登录；版本治理使用明确决策，Web 与 HarmonyOS 不会调用此边界。
  Future<ClientReleaseCheckResult> checkClientRelease({
    required String platform,
    required String channel,
    required String version,
    required int buildNumber,
    required String architecture,
    required String protocolVersion,
    required String installationId,
  }) async {
    // _asMap 已经把响应里的 data 解包；这里直接解析，不能再套一层 _asMap(envelope['data'])。
    final envelope = _asMap(
      await _generated.checkClientRelease({
        'platform': platform,
        'channel': channel,
        'version': version,
        'buildNumber': buildNumber,
        'architecture': architecture,
        'protocolVersion': protocolVersion,
        'installationId': installationId,
      }),
    );
    return ClientReleaseCheckResult.fromJson(envelope);
  }
}
