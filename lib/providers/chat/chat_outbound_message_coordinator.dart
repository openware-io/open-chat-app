import 'dart:convert';

import 'package:gv_core/gv_core.dart';

import '../../core/message_preview.dart';

typedef ChatConversationUpsert = void Function(
  String peerId,
  String chatType,
  String lastMsg, {
  bool incrementUnread,
  String? name,
  DateTime? lastTime,
});

/// 聊天发送侧协调器。
///
/// 负责本地乐观消息、媒体上传占位、Socket 发出和 ack 合并；ChatProvider 只
/// 保留状态入口和通知 UI，避免发送细节继续堆在 Provider 里。
class ChatOutboundMessageCoordinator {
  ChatOutboundMessageCoordinator({
    required GvSocketClient socket,
    required int? Function() myId,
    required String? Function() selfDisplayName,
    required String Function(String chatType, String peerId) chatKey,
    required Map<String, List<ChatMessage>> messageMap,
    required Map<String, ChatMessage> pendingAcks,
    required ChatConversationUpsert upsertConversation,
    required void Function(String chatKey) refreshConversationLastFromSession,
    required void Function(String peerId, ChatMessage message)
        persistPendingMessage,
    required void Function(
      String peerId,
      String clientMsgId,
      ChatMessage confirmed,
    ) confirmPendingMessage,
    required void Function(String clientMsgId) removePendingMessage,
    required void Function(String message) enqueueWsError,
    required void Function() notifyChanged,
  })  : _socket = socket,
        _myId = myId,
        _selfDisplayName = selfDisplayName,
        _chatKey = chatKey,
        _messageMap = messageMap,
        _pendingAcks = pendingAcks,
        _upsertConversation = upsertConversation,
        _refreshConversationLastFromSession =
            refreshConversationLastFromSession,
        _persistPendingMessage = persistPendingMessage,
        _confirmPendingMessage = confirmPendingMessage,
        _removePendingMessage = removePendingMessage,
        _enqueueWsError = enqueueWsError,
        _notifyChanged = notifyChanged;

  final GvSocketClient _socket;
  final int? Function() _myId;
  final String? Function() _selfDisplayName;
  final String Function(String chatType, String peerId) _chatKey;
  final Map<String, List<ChatMessage>> _messageMap;
  final Map<String, ChatMessage> _pendingAcks;
  final ChatConversationUpsert _upsertConversation;
  final void Function(String chatKey) _refreshConversationLastFromSession;
  final void Function(String peerId, ChatMessage message)
      _persistPendingMessage;
  final void Function(
    String peerId,
    String clientMsgId,
    ChatMessage confirmed,
  ) _confirmPendingMessage;
  final void Function(String clientMsgId) _removePendingMessage;
  final void Function(String message) _enqueueWsError;
  final void Function() _notifyChanged;

  String _convPreview(String msgType, String content, {String? convPreview}) {
    if (convPreview != null) return convPreview;
    return previewTextFromContent(msgType, content);
  }

  ChatMessage? _newPendingMessage({
    required String toId,
    required String chatType,
    required String msgType,
    required String content,
    String? replyMsgId,
    List<dynamic>? atUsers,
    List<dynamic>? mediaObjectIds,
  }) {
    final uid = _myId();
    if (uid == null) return null;
    final clientMsgId = genClientMsgId();
    return ChatMessage(
      msgId: clientMsgId,
      from: uid,
      fromUsername: _selfDisplayName() ?? '',
      toId: toId,
      chatType: chatType,
      msgType: msgType,
      content: content,
      timestamp: DateTime.now().toUtc(),
      clientMsgId: clientMsgId,
      status: 'sending',
      replyMsgId: replyMsgId,
      atUsers: atUsers,
      mediaObjectIds: mediaObjectIds,
    );
  }

  void sendMessage(
    String toId,
    String chatType,
    String msgType,
    String content, {
    String? replyMsgId,
    List<dynamic>? atUsers,
    String? convPreview,
    List<String>? mediaObjectIds,
    String? wireContent,
  }) {
    final msg = _newPendingMessage(
      toId: toId,
      chatType: chatType,
      msgType: msgType,
      content: content,
      replyMsgId: replyMsgId,
      atUsers: atUsers,
      mediaObjectIds: mediaObjectIds,
    );
    if (msg == null) return;

    final clientMsgId = msg.clientMsgId!;
    final key = _chatKey(chatType, toId);
    _messageMap.putIfAbsent(key, () => []);
    _messageMap[key]!.add(msg);
    _pendingAcks[clientMsgId] = msg;
    _persistPendingMessage(toId, msg);

    _upsertConversation(
      toId,
      chatType,
      _convPreview(msgType, content, convPreview: convPreview),
      incrementUnread: false,
    );

    if (!_emitChatSendOrRollback(
      key: key,
      toId: toId,
      chatType: chatType,
      msgType: msgType,
      content: wireContent ?? content,
      clientMsgId: clientMsgId,
      replyMsgId: replyMsgId,
      atUsers: atUsers,
      mediaObjectIds: mediaObjectIds,
    )) {
      return;
    }
    _notifyChanged();
  }

  /// 仅写入本地列表的「发送中」媒体占位，不记入 [_pendingAcks]、不发出 `chat:send`。
  String? appendSendingMediaDraft(
    String toId,
    String chatType,
    String msgType,
    String provisionalContent, {
    String? replyMsgId,
    List<dynamic>? atUsers,
    String? convPreview,
  }) {
    final msg = _newPendingMessage(
      toId: toId,
      chatType: chatType,
      msgType: msgType,
      content: provisionalContent,
      replyMsgId: replyMsgId,
      atUsers: atUsers,
    );
    if (msg == null) return null;

    final key = _chatKey(chatType, toId);
    _messageMap.putIfAbsent(key, () => []);
    _messageMap[key]!.add(msg);

    _upsertConversation(
      toId,
      chatType,
      _convPreview(msgType, provisionalContent, convPreview: convPreview),
      incrementUnread: false,
    );

    _notifyChanged();
    return msg.clientMsgId;
  }

  ChatMessage? _replaceMessageByClientMsgId(
    String clientMsgId,
    ChatMessage Function(ChatMessage current) update,
  ) {
    for (final entry in _messageMap.entries) {
      final list = entry.value;
      final index = list.indexWhere((m) => m.clientMsgId == clientMsgId);
      if (index < 0) continue;
      final next = update(list[index]);
      list[index] = next;
      return next;
    }
    return null;
  }

  void finalizeSendingMediaDraft({
    required String clientMsgId,
    required String toId,
    required String chatType,
    required String finalContent,
    required List<String> mediaObjectIds,
    String? wireContent,
    String? convPreview,
  }) {
    final uid = _myId();
    if (uid == null) return;
    final key = _chatKey(chatType, toId);
    final list = _messageMap[key];
    if (list == null) return;

    var pendingIndex = -1;
    for (var i = 0; i < list.length; i++) {
      final message = list[i];
      if (message.clientMsgId == clientMsgId && message.from == uid) {
        pendingIndex = i;
        break;
      }
    }
    if (pendingIndex < 0) return;

    final pending = list[pendingIndex].copyWith(
      content: finalContent,
      mediaObjectIds: mediaObjectIds,
    );
    list[pendingIndex] = pending;
    _upsertConversation(
      toId,
      chatType,
      _convPreview(pending.msgType, finalContent, convPreview: convPreview),
      incrementUnread: false,
    );

    _pendingAcks[clientMsgId] = pending;
    _persistPendingMessage(toId, pending);

    if (!_emitChatSendOrRollback(
      key: key,
      toId: toId,
      chatType: chatType,
      msgType: pending.msgType,
      content: wireContent ?? finalContent,
      clientMsgId: clientMsgId,
      replyMsgId: pending.replyMsgId,
      atUsers: pending.atUsers,
      mediaObjectIds: mediaObjectIds,
    )) {
      return;
    }
    _notifyChanged();
  }

  void discardSendingMediaDraft({
    required String clientMsgId,
    required String toId,
    required String chatType,
  }) {
    final key = _chatKey(chatType, toId);
    _messageMap[key]?.removeWhere((m) => m.clientMsgId == clientMsgId);
    _pendingAcks.remove(clientMsgId);
    _removePendingMessage(clientMsgId);
    _refreshConversationLastFromSession(key);
    _notifyChanged();
  }

  void onMessageAck(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final cid =
        map['clientMsgId']?.toString() ?? map['client_msg_id']?.toString();
    if (cid == null || cid.isEmpty) return;
    final pending = _pendingAcks.remove(cid);
    if (pending != null) {
      final mid = map['msgId'] ?? map['msg_id'];
      final ts = map['timestamp'];
      var timestamp = pending.timestamp;
      if (ts is String) {
        timestamp = parseUtcDateTime(ts) ?? timestamp;
      } else if (ts != null) {
        timestamp = parseUtcDateTime(ts) ?? timestamp;
      }
      final ackContent = map['content'];
      final ackSeq = int.tryParse(map['seq']?.toString() ?? '');
      final confirmed = _replaceMessageByClientMsgId(
        cid,
        (current) => current.copyWith(
          msgId: mid?.toString() ?? current.msgId,
          timestamp: timestamp,
          content: current.mediaObjectIds?.isNotEmpty != true &&
                  ackContent is String &&
                  ackContent.isNotEmpty
              ? ackContent
              : current.content,
          seq: ackSeq ?? current.seq,
          status: 'sent',
        ),
      );
      if (confirmed != null) {
        _confirmPendingMessage(pending.toId, cid, confirmed);
      }
    }
    _notifyChanged();
  }

  void retryPendingMessages() {
    if (!_socket.connected) return;
    for (final pending in List<ChatMessage>.from(_pendingAcks.values)) {
      final clientMsgId = pending.clientMsgId?.trim();
      if (clientMsgId == null || clientMsgId.isEmpty) continue;
      // 私密聊天消息走 HTTP /secret-messages（E2EE 密文链路），绝不通过 WS chat:send 重发：
      // 服务端 ChatType 校验会拒绝该事件，历史版本遗留的 secret pending 必须跳过并清理。
      if (pending.chatType == 'secret') {
        _pendingAcks.remove(clientMsgId);
        _removePendingMessage(clientMsgId);
        continue;
      }
      _socket.emitChat('chat:send', {
        'toId': pending.toId,
        'chatType': pending.chatType,
        'msgType': pending.msgType,
        'content': _wireContentForPending(pending),
        'clientMsgId': clientMsgId,
        if (pending.replyMsgId != null) 'replyMsgId': pending.replyMsgId,
        if (pending.atUsers != null) 'atUsers': pending.atUsers,
        if (pending.mediaObjectIds?.isNotEmpty == true)
          'mediaObjectIds': pending.mediaObjectIds,
      });
    }
  }

  bool _emitChatSendOrRollback({
    required String key,
    required String toId,
    required String chatType,
    required String msgType,
    required String content,
    required String clientMsgId,
    String? replyMsgId,
    List<dynamic>? atUsers,
    List<dynamic>? mediaObjectIds,
  }) {
    if (!_socket.hasClient) {
      _pendingAcks.remove(clientMsgId);
      _messageMap[key]?.removeWhere((m) => m.clientMsgId == clientMsgId);
      _removePendingMessage(clientMsgId);
      _refreshConversationLastFromSession(key);
      _enqueueWsError('网络未连接，消息未发送');
      _notifyChanged();
      return false;
    }

    _socket.emitChat('chat:send', {
      'toId': toId,
      'chatType': chatType,
      'msgType': msgType,
      'content': content,
      'clientMsgId': clientMsgId,
      if (replyMsgId != null) 'replyMsgId': replyMsgId,
      if (atUsers != null) 'atUsers': atUsers,
      if (mediaObjectIds?.isNotEmpty == true) 'mediaObjectIds': mediaObjectIds,
    });
    // 短时断开时保留 optimistic UI，原生 WebSocket 恢复后由待发送队列重试。
    return true;
  }

  String _wireContentForPending(ChatMessage message) {
    if (message.mediaObjectIds?.isNotEmpty != true) return message.content;
    if (message.msgType == 'image') {
      return _jsonField(message.content, 'caption');
    }
    if (message.msgType == 'file') {
      return _jsonField(message.content, 'name');
    }
    return '';
  }

  String _jsonField(String value, String key) {
    try {
      final decoded = jsonDecode(value);
      return decoded is Map ? decoded[key]?.toString() ?? '' : '';
    } catch (_) {
      return '';
    }
  }
}
