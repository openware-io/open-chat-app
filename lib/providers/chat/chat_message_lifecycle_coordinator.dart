import '../../models/chat_message.dart';
import '../../models/conversation.dart';
import '../../core/conversation_preview.dart';

/// 聊天消息生命周期协调器。
///
/// 负责已读/撤回/删除/清空/本机隐藏等“消息已经存在之后”的状态变更。
/// ChatProvider 仍持有状态，本类只集中这些强相关流程，避免 Provider 继续膨胀。
class ChatMessageLifecycleCoordinator {
  ChatMessageLifecycleCoordinator({
    required Map<String, List<ChatMessage>> messageMap,
    required Map<String, ChatMessage> pendingAcks,
    required int? Function() myId,
    required List<Conversation> Function() conversations,
    required Map<String, List<dynamic>> Function() hiddenMessagesByChat,
    required void Function(Map<String, List<dynamic>>) setHiddenMessagesByChat,
    required String Function(String chatType, String peerId) chatKey,
    required bool Function(String sessionKey, ChatMessage message)
        isMessageLocallyCleared,
    required void Function() persistConversations,
    required void Function() persistHidden,
    required void Function(ChatMessage message) persistMessageUpdate,
    required void Function(String msgId) deletePersistedMessage,
    required void Function(String peerId, String chatType)
        clearPersistedSession,
    required void Function() notifyChanged,
  })  : _messageMap = messageMap,
        _pendingAcks = pendingAcks,
        _myId = myId,
        _conversations = conversations,
        _hiddenMessagesByChat = hiddenMessagesByChat,
        _setHiddenMessagesByChat = setHiddenMessagesByChat,
        _chatKey = chatKey,
        _isMessageLocallyCleared = isMessageLocallyCleared,
        _persistConversations = persistConversations,
        _persistHidden = persistHidden,
        _persistMessageUpdate = persistMessageUpdate,
        _deletePersistedMessage = deletePersistedMessage,
        _clearPersistedSession = clearPersistedSession,
        _notifyChanged = notifyChanged;

  final Map<String, List<ChatMessage>> _messageMap;
  final Map<String, ChatMessage> _pendingAcks;
  final int? Function() _myId;
  final List<Conversation> Function() _conversations;
  final Map<String, List<dynamic>> Function() _hiddenMessagesByChat;
  final void Function(Map<String, List<dynamic>>) _setHiddenMessagesByChat;
  final String Function(String chatType, String peerId) _chatKey;
  final bool Function(String sessionKey, ChatMessage message)
      _isMessageLocallyCleared;
  final void Function() _persistConversations;
  final void Function() _persistHidden;
  final void Function(ChatMessage message) _persistMessageUpdate;
  final void Function(String msgId) _deletePersistedMessage;
  final void Function(String peerId, String chatType) _clearPersistedSession;
  final void Function() _notifyChanged;

  void onReadNotify(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final id = map['msgId']?.toString();
    if (id == null) return;
    for (final list in _messageMap.values) {
      for (var i = 0; i < list.length; i++) {
        final message = list[i];
        if (message.msgId == id) {
          final updated = message.copyWith(status: 'read');
          list[i] = updated;
          _persistMessageUpdate(updated);
        }
      }
    }
    _notifyChanged();
  }

  void onRecallNotify(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final id = map['msgId']?.toString();
    if (id == null) return;
    markMessageRecalled(id, content: '消息已撤回');
  }

  void markMessageRecalled(String msgId, {required String content}) {
    final affectedSessionKeys = <String>{};
    for (final entry in _messageMap.entries) {
      final list = entry.value;
      for (var i = 0; i < list.length; i++) {
        final message = list[i];
        if (message.msgId == msgId) {
          // 保留原始消息类型，供「撤回一条消息/一张图片/一个视频」等类型化提示。
          final originalType = message.msgType;
          final updated = message.copyWith(
            status: 'recalled',
            msgType: 'recall',
            content: originalType,
          );
          list[i] = updated;
          _persistMessageUpdate(updated);
          affectedSessionKeys.add(entry.key);
        }
      }
    }
    for (final sessionKey in affectedSessionKeys) {
      refreshConversationLastFromSession(
        sessionKey,
        includeRecalled: true,
      );
    }
    if (affectedSessionKeys.isNotEmpty) _persistConversations();
    _notifyChanged();
  }

  void onMessageDeletedNotify(dynamic data) {
    if (data is! Map) return;
    final raw = Map<dynamic, dynamic>.from(data);
    final id = (raw['msgId'] ?? raw['msg_id'])?.toString().trim();
    if (id == null || id.isEmpty) return;
    applyMessageDeleted(id);
  }

  /// 服务端已删除该条消息：从本地列表、pending ack 与本机隐藏记录中移除。
  void applyMessageDeleted(String msgId) {
    String? affectedKey;
    for (final entry in _messageMap.entries) {
      final list = entry.value;
      final index = list.indexWhere((m) => m.msgId == msgId);
      if (index >= 0) {
        list.removeAt(index);
        affectedKey = entry.key;
        break;
      }
    }
    _pendingAcks.removeWhere((_, m) => m.msgId == msgId);
    _deletePersistedMessage(msgId);
    _removeMsgIdFromAllHidden(msgId);
    if (affectedKey != null) {
      refreshConversationLastFromSession(affectedKey);
    }
    _persistConversations();
    _notifyChanged();
  }

  bool isMessageHidden(String peerId, String chatType, String msgId) {
    final key = _chatKey(chatType, peerId);
    final list = _hiddenMessagesByChat()[key];
    return list != null && list.map((e) => e.toString()).contains(msgId);
  }

  /// 会话内可见消息（不含撤回、不含本机隐藏），顺序与时间轴一致。
  List<ChatMessage> visibleMessagesFor(String peerId, String chatType) {
    final key = _chatKey(chatType, peerId);
    final list = _messageMap[key] ?? [];
    return [
      for (final m in list)
        if (!m.isRecalled &&
            !isMessageHidden(peerId, chatType, m.msgId) &&
            !_isMessageLocallyCleared(key, m))
          m,
    ];
  }

  void hideMessageForMe(String peerId, String chatType, String msgId) {
    final key = _chatKey(chatType, peerId);
    final current = List<dynamic>.from(_hiddenMessagesByChat()[key] ?? []);
    if (current.contains(msgId)) return;
    current.add(msgId);
    _setHiddenMessagesByChat({..._hiddenMessagesByChat(), key: current});
    refreshConversationLastFromSession(key);
    _persistConversations();
    _persistHidden();
    _notifyChanged();
  }

  void refreshConversationLastFromSession(
    String sessionKey, {
    bool includeRecalled = false,
  }) {
    final colon = sessionKey.indexOf(':');
    if (colon <= 0 || colon >= sessionKey.length - 1) return;
    final chatType = sessionKey.substring(0, colon);
    final peerId = sessionKey.substring(colon + 1);
    final messages = _messageMap[sessionKey] ?? [];
    ChatMessage? lastVisible;
    for (var i = messages.length - 1; i >= 0; i--) {
      final m = messages[i];
      if ((includeRecalled || !m.isRecalled) &&
          !isMessageHidden(peerId, chatType, m.msgId) &&
          !_isMessageLocallyCleared(sessionKey, m)) {
        lastVisible = m;
        break;
      }
    }
    final conversations = _conversations();
    for (var i = 0; i < conversations.length; i++) {
      final conversation = conversations[i];
      if (conversation.id == peerId && conversation.chatType == chatType) {
        if (lastVisible == null) {
          conversations[i] = conversation.copyWith(
            lastMessage: '',
            lastTime: DateTime.fromMillisecondsSinceEpoch(0),
          );
        } else {
          conversations[i] = conversation.copyWith(
            lastMessage: conversationPreviewForMessage(
              lastVisible,
              viewerId: _myId(),
            ),
            lastTime: lastVisible.timestamp,
          );
        }
        break;
      }
    }
  }

  void applyPrivateChatCleared(String peerId) {
    final key = _chatKey('private', peerId);
    _messageMap[key] = [];
    _removeHiddenForKey(key);
    _pendingAcks.removeWhere(
      (_, m) => m.chatType == 'private' && m.toId == peerId,
    );
    _clearPersistedSession(peerId, 'private');
    final conversations = _conversations();
    for (var i = 0; i < conversations.length; i++) {
      final conversation = conversations[i];
      if (conversation.id == peerId && conversation.chatType == 'private') {
        conversations[i] = conversation.copyWith(
          lastMessage: '',
          unread: 0,
          lastTime: DateTime.fromMillisecondsSinceEpoch(0),
        );
        break;
      }
    }
    _persistConversations();
    _notifyChanged();
  }

  void onClearPrivateChatNotify(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    if (map['chatType']?.toString() != 'private') return;
    final peer = map['peerId']?.toString();
    if (peer == null || peer.isEmpty) return;
    applyPrivateChatCleared(peer);
  }

  void applyGroupChatCleared(String groupId) {
    final key = _chatKey('group', groupId);
    _messageMap[key] = [];
    _removeHiddenForKey(key);
    _pendingAcks.removeWhere(
      (_, m) => m.chatType == 'group' && m.toId == groupId,
    );
    _clearPersistedSession(groupId, 'group');
    final conversations = _conversations();
    for (var i = 0; i < conversations.length; i++) {
      final conversation = conversations[i];
      if (conversation.id == groupId && conversation.chatType == 'group') {
        conversations[i] = conversation.copyWith(
          lastMessage: '',
          unread: 0,
          lastTime: DateTime.fromMillisecondsSinceEpoch(0),
        );
        break;
      }
    }
    _persistConversations();
    _notifyChanged();
  }

  void onClearGroupChatNotify(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    if (map['chatType']?.toString() != 'group') return;
    final groupId = map['groupId']?.toString();
    if (groupId == null || groupId.isEmpty) return;
    applyGroupChatCleared(groupId);
  }

  void _removeMsgIdFromAllHidden(String msgId) {
    var changed = false;
    final next = Map<String, List<dynamic>>.from(_hiddenMessagesByChat());
    for (final key in next.keys.toList()) {
      final current = List<dynamic>.from(next[key] ?? []);
      if (current.remove(msgId)) {
        next[key] = current;
        changed = true;
      }
    }
    if (changed) {
      _setHiddenMessagesByChat(next);
      _persistHidden();
    }
  }

  void _removeHiddenForKey(String key) {
    if (!_hiddenMessagesByChat().containsKey(key)) return;
    final next = Map<String, List<dynamic>>.from(_hiddenMessagesByChat());
    next.remove(key);
    _setHiddenMessagesByChat(next);
    _persistHidden();
  }
}
