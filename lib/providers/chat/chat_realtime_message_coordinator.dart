import '../../models/chat_message.dart';
import '../../core/conversation_preview.dart';
import 'chat_message_merge.dart';
import 'chat_provider_types.dart';

typedef ChatRealtimeConversationUpsert = void Function(
  String peerId,
  String chatType,
  String lastMsg, {
  bool incrementUnread,
  String? name,
  DateTime? lastTime,
});

/// 聊天实时接收侧协调器。
///
/// 负责 WebSocket 推送入库、与本地乐观发送合并、当前会话延迟测高插入、
/// 未读判定和自动已读上报。ChatProvider 继续持有状态，本类只编排接收流程。
class ChatRealtimeMessageCoordinator {
  ChatRealtimeMessageCoordinator({
    required int? Function() myId,
    required String? Function() currentChatId,
    required String Function() currentChatType,
    required bool Function() isForeground,
    required bool Function() allowRealtimeMergeIntoCurrentChatList,
    required Map<String, List<ChatMessage>> messageMap,
    required Map<String, ChatMessage> pendingAcks,
    required String Function(String chatType, String peerId) chatKey,
    required DeferredRealtimeSessionInsert? Function()
        deferredRealtimeSessionInsert,
    required void Function(DeferredRealtimeSessionInsert?)
        setDeferredRealtimeSessionInsert,
    required void Function(String sessionKey) bumpRealtimeIngestEpoch,
    required bool Function(String sessionKey, ChatMessage msg)
        isMessageMutedByReadWatermark,
    required bool Function(String sessionKey, ChatMessage msg)
        isMessageLocallyCleared,
    required ChatRealtimeConversationUpsert upsertConversation,
    required void Function(String peerId, ChatMessage message) persistMessage,
    required void Function(
      String peerId,
      String clientMsgId,
      ChatMessage confirmed,
    ) confirmPendingMessage,
    required void Function(String peerId, String chatType)
        maybeScheduleAddressBookSyncForIncoming,
    required void Function(List<String> msgIds) markRead,
    required void Function() maybeTriggerInAppNewMessageBanner,
    required void Function() notifyChanged,
  })  : _myId = myId,
        _currentChatId = currentChatId,
        _currentChatType = currentChatType,
        _isForeground = isForeground,
        _allowRealtimeMergeIntoCurrentChatList =
            allowRealtimeMergeIntoCurrentChatList,
        _messageMap = messageMap,
        _pendingAcks = pendingAcks,
        _chatKey = chatKey,
        _deferredRealtimeSessionInsert = deferredRealtimeSessionInsert,
        _setDeferredRealtimeSessionInsert = setDeferredRealtimeSessionInsert,
        _bumpRealtimeIngestEpoch = bumpRealtimeIngestEpoch,
        _isMessageMutedByReadWatermark = isMessageMutedByReadWatermark,
        _isMessageLocallyCleared = isMessageLocallyCleared,
        _upsertConversation = upsertConversation,
        _persistMessage = persistMessage,
        _confirmPendingMessage = confirmPendingMessage,
        _maybeScheduleAddressBookSyncForIncoming =
            maybeScheduleAddressBookSyncForIncoming,
        _markRead = markRead,
        _maybeTriggerInAppNewMessageBanner = maybeTriggerInAppNewMessageBanner,
        _notifyChanged = notifyChanged;

  final int? Function() _myId;
  final String? Function() _currentChatId;
  final String Function() _currentChatType;
  final bool Function() _isForeground;
  final bool Function() _allowRealtimeMergeIntoCurrentChatList;
  final Map<String, List<ChatMessage>> _messageMap;
  final Map<String, ChatMessage> _pendingAcks;
  final String Function(String chatType, String peerId) _chatKey;
  final DeferredRealtimeSessionInsert? Function()
      _deferredRealtimeSessionInsert;
  final void Function(DeferredRealtimeSessionInsert?)
      _setDeferredRealtimeSessionInsert;
  final void Function(String sessionKey) _bumpRealtimeIngestEpoch;
  final bool Function(String sessionKey, ChatMessage msg)
      _isMessageMutedByReadWatermark;
  final bool Function(String sessionKey, ChatMessage msg)
      _isMessageLocallyCleared;
  final ChatRealtimeConversationUpsert _upsertConversation;
  final void Function(String peerId, ChatMessage message) _persistMessage;
  final void Function(
    String peerId,
    String clientMsgId,
    ChatMessage confirmed,
  ) _confirmPendingMessage;
  final void Function(String peerId, String chatType)
      _maybeScheduleAddressBookSyncForIncoming;
  final void Function(List<String> msgIds) _markRead;
  final void Function() _maybeTriggerInAppNewMessageBanner;
  final void Function() _notifyChanged;

  bool onMessageReceived(dynamic raw) {
    if (raw is! Map) return false;
    final map = Map<String, dynamic>.from(raw);
    if (map['type'] == 'batch' && map['messages'] is List) {
      final readIds = <String>{};
      var receivedIncoming = false;
      for (final item in map['messages'] as List) {
        if (item is! Map) continue;
        final result = _ingestSingleMessage(Map<String, dynamic>.from(item));
        final id = result.markReadMsgId;
        if (id != null) readIds.add(id);
        receivedIncoming = receivedIncoming || result.receivedIncoming;
      }
      if (readIds.isNotEmpty) _markRead(readIds.toList());
      return receivedIncoming;
    }
    final result = _ingestSingleMessage(map);
    final id = result.markReadMsgId;
    if (id != null) _markRead([id]);
    return result.receivedIncoming;
  }

  /// 写入一条推送消息。若与本地乐观发送的 `clientMsgId` 对应则合并，
  /// 避免 receive 早于 ack 时出现双条。
  ///
  /// 返回是否实际接收了他人的新消息，以及当前会话内需要上报已读的 [msgId]。
  ({String? markReadMsgId, bool receivedIncoming}) _ingestSingleMessage(
    Map<String, dynamic> map,
  ) {
    final msg = ChatMessage.fromJson(map);
    final my = _myId();
    if (my == null) {
      return (markReadMsgId: null, receivedIncoming: false);
    }

    final peerId = _peerIdForPrivateOrGroup(
      msg,
      my,
      '${map['conversationId'] ?? map['conversation_id'] ?? ''}',
    );
    final key = _chatKey(msg.chatType, peerId);
    if (_isMessageLocallyCleared(key, msg)) {
      return (markReadMsgId: null, receivedIncoming: false);
    }
    _messageMap.putIfAbsent(key, () => []);
    final list = _messageMap[key]!;
    final isCurrent = _isForeground() &&
        _currentChatId() == peerId &&
        _currentChatType() == msg.chatType;

    if (list.any((m) => m.msgId == msg.msgId)) {
      return (markReadMsgId: null, receivedIncoming: false);
    }

    final optimisticMerge = _applyOptimisticSendMergeIfNeeded(
      msg: msg,
      list: list,
      peerId: peerId,
      myId: my,
      isCurrent: isCurrent,
    );
    if (optimisticMerge.done) {
      return (
        markReadMsgId: optimisticMerge.markReadMsgId,
        receivedIncoming: false,
      );
    }

    final suppressListInsert =
        isCurrent && !_allowRealtimeMergeIntoCurrentChatList();
    final deferForViewportMeasure =
        isCurrent && _allowRealtimeMergeIntoCurrentChatList() && msg.from != my;

    if (deferForViewportMeasure) {
      _deferIncomingMessageForMeasuredInsert(
        peerId: peerId,
        key: key,
        msg: msg,
        listSnapshot: list,
      );
      return (markReadMsgId: null, receivedIncoming: true);
    }

    if (!suppressListInsert) {
      insertChatMessageChronologically(list, msg);
      _bumpRealtimeIngestEpoch(key);
    }
    _persistMessage(peerId, msg);

    _upsertConversation(
      peerId,
      msg.chatType,
      conversationPreviewForMessage(msg, viewerId: my),
      incrementUnread: ((!isCurrent || suppressListInsert) && msg.from != my) &&
          !_isSystemMessage(msg) &&
          !_isMessageMutedByReadWatermark(key, msg),
      name: msg.fromUsername,
      lastTime: msg.timestamp,
    );
    _maybeScheduleAddressBookSyncForIncoming(peerId, msg.chatType);
    _notifyChanged();
    if (!isCurrent && msg.from != my) {
      _maybeTriggerInAppNewMessageBanner();
    }
    if (isCurrent && msg.from != my && !suppressListInsert) {
      return (markReadMsgId: msg.msgId, receivedIncoming: true);
    }
    return (
      markReadMsgId: null,
      receivedIncoming: msg.from != my,
    );
  }

  String _peerIdForPrivateOrGroup(ChatMessage msg, int my, String rawConversationId) {
    if (msg.chatType == 'private') {
      if (msg.from == my) return msg.toId;
      // 系统消息（from == 0）不能用发送方当对端：那会凭空多出一个「用户 0」会话并带未读角标
      // （真机实测：同意好友后列表多出「用户 0」，角标与服务端未读口径对不上）。
      // 与同步链路保持一致，从推送报文的 conversationId（conv:private:A:B）解析「不是我」的一方。
      if (msg.from == 0) {
        return _peerFromPrivateConversationId(rawConversationId, my) ?? msg.toId;
      }
      return '${msg.from}';
    }
    return msg.toId;
  }

  /// 从私聊会话 id 解析出对端：兼容 `conv:private:<a>:<b>` 与 `private:<a>:<b>` 两种写法。
  ///
  /// 取末尾两段并要求其一必须是「我」，否则返回 null —— 宁可回退到既有逻辑，
  /// 也不能解析出一个不属于本会话的对端。
  String? _peerFromPrivateConversationId(String conversationId, int my) {
    final parts = conversationId.split(':');
    if (parts.length < 2) return null;
    final a = parts[parts.length - 2];
    final b = parts[parts.length - 1];
    final aId = int.tryParse(a);
    final bId = int.tryParse(b);
    if (aId == null || bId == null || aId == bId) return null;
    if (aId != my && bId != my) return null;
    return aId == my ? b : a;
  }

  /// 系统消息不计入未读角标，与服务端未读口径一致（服务端过滤 `msg_type <> 'SYSTEM'`）。
  bool _isSystemMessage(ChatMessage msg) => msg.msgType.toLowerCase() == 'system';

  ({bool done, String? markReadMsgId}) _applyOptimisticSendMergeIfNeeded({
    required ChatMessage msg,
    required List<ChatMessage> list,
    required String peerId,
    required int myId,
    required bool isCurrent,
  }) {
    final cid = msg.clientMsgId?.trim();
    if (cid == null || cid.isEmpty) {
      return (done: false, markReadMsgId: null);
    }
    final mergeIdx = list.indexWhere(
      (m) =>
          m.from == msg.from &&
          (m.msgId == cid || (m.clientMsgId != null && m.clientMsgId == cid)),
    );
    if (mergeIdx < 0) {
      return (done: false, markReadMsgId: null);
    }

    final local = list[mergeIdx];
    final confirmed = local.copyWith(
      msgId: msg.msgId,
      timestamp: msg.timestamp,
      status: 'sent',
      content: msg.content,
      msgType: msg.msgType,
      fromUsername:
          msg.fromUsername != null && msg.fromUsername!.trim().isNotEmpty
              ? msg.fromUsername
              : local.fromUsername,
      fromAvatar: msg.fromAvatar ?? local.fromAvatar,
      replyMsgId: msg.replyMsgId ?? local.replyMsgId,
      atUsers: msg.atUsers ?? local.atUsers,
      mediaObjectIds: msg.mediaObjectIds ?? local.mediaObjectIds,
      seq: msg.seq ?? local.seq,
      clientMsgId: msg.clientMsgId ?? local.clientMsgId,
    );
    list[mergeIdx] = confirmed;
    _pendingAcks.remove(cid);
    _confirmPendingMessage(peerId, cid, confirmed);

    _upsertConversation(
      peerId,
      msg.chatType,
      conversationPreviewForMessage(msg, viewerId: myId),
      incrementUnread: !isCurrent,
      name: msg.fromUsername,
      lastTime: msg.timestamp,
    );
    _maybeScheduleAddressBookSyncForIncoming(peerId, msg.chatType);
    _notifyChanged();

    if (isCurrent && msg.from != myId) {
      return (done: true, markReadMsgId: msg.msgId);
    }
    return (done: true, markReadMsgId: null);
  }

  void _deferIncomingMessageForMeasuredInsert({
    required String peerId,
    required String key,
    required ChatMessage msg,
    required List<ChatMessage> listSnapshot,
  }) {
    final existing = _deferredRealtimeSessionInsert();
    final List<ChatMessage> merged;
    final List<String> readIds;
    final int version;
    if (existing != null &&
        existing.peerId == peerId &&
        existing.chatType == msg.chatType) {
      merged = List<ChatMessage>.from(existing.mergedSession);
      insertChatMessageChronologically(merged, msg);
      readIds = [...existing.readMsgIds, msg.msgId];
      version = existing.version + 1;
    } else {
      merged = List<ChatMessage>.from(listSnapshot);
      insertChatMessageChronologically(merged, msg);
      readIds = [msg.msgId];
      version = 1;
    }
    _setDeferredRealtimeSessionInsert(
      DeferredRealtimeSessionInsert(
        peerId: peerId,
        chatType: msg.chatType,
        mergedSession: merged,
        version: version,
        readMsgIds: readIds,
      ),
    );
    _persistMessage(peerId, msg);
    _bumpRealtimeIngestEpoch(key);
    _notifyChanged();
  }
}
