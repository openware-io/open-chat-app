import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/conversation_preview.dart';
import 'package:gv_chat_app/l10n/app_localizations_zh.dart';
import 'package:gv_chat_app/models/chat_message.dart';
import 'package:gv_chat_app/models/conversation.dart';
import 'package:gv_chat_app/providers/chat/chat_message_lifecycle_coordinator.dart';

void main() {
  test('localizes the peer recall marker for the conversation list', () {
    expect(
      localizedConversationPreview(
        AppLocalizationsZh(),
        gvConversationRecallPeerPreview,
      ),
      '对方撤回了一条消息',
    );
  });

  group('message recall conversation preview', () {
    test('updates and persists the latest peer recall preview', () {
      final timestamp = DateTime(2026, 8, 18, 10);
      final messages = <String, List<ChatMessage>>{
        'private:2': [
          _message(
            msgId: 'latest',
            from: 2,
            timestamp: timestamp,
            content: '撤回前的内容',
          ),
        ],
      };
      final conversations = <Conversation>[
        _conversation(lastMessage: '撤回前的内容', lastTime: timestamp),
      ];
      var conversationPersistCount = 0;
      ChatMessage? persistedMessage;

      final coordinator = _coordinator(
        messages: messages,
        conversations: conversations,
        onPersistConversations: () => conversationPersistCount++,
        onPersistMessage: (message) => persistedMessage = message,
      );

      coordinator.onRecallNotify({'msgId': 'latest'});

      expect(messages['private:2']!.single.isRecalled, isTrue);
      expect(persistedMessage?.isRecalled, isTrue);
      expect(
        conversations.single.lastMessage,
        gvConversationRecallPeerPreview,
      );
      expect(conversations.single.lastTime, timestamp);
      expect(conversationPersistCount, 1);
    });

    test('keeps a newer conversation preview when an older message is recalled',
        () {
      final older = DateTime(2026, 8, 18, 10);
      final newer = older.add(const Duration(minutes: 1));
      final messages = <String, List<ChatMessage>>{
        'private:2': [
          _message(
            msgId: 'older',
            from: 2,
            timestamp: older,
            content: '旧消息',
          ),
          _message(
            msgId: 'newer',
            from: 2,
            timestamp: newer,
            content: '新消息',
          ),
        ],
      };
      final conversations = <Conversation>[
        _conversation(lastMessage: '新消息', lastTime: newer),
      ];

      final coordinator = _coordinator(
        messages: messages,
        conversations: conversations,
      );

      coordinator.onRecallNotify({'msgId': 'older'});

      expect(conversations.single.lastMessage, '新消息');
      expect(conversations.single.lastTime, newer);
    });

    test('distinguishes a recall sent by the current user', () {
      final timestamp = DateTime(2026, 8, 18, 10);
      final messages = <String, List<ChatMessage>>{
        'private:2': [
          _message(
            msgId: 'self',
            from: 1,
            timestamp: timestamp,
            content: '我发出的消息',
          ),
        ],
      };
      final conversations = <Conversation>[
        _conversation(lastMessage: '我发出的消息', lastTime: timestamp),
      ];

      final coordinator = _coordinator(
        messages: messages,
        conversations: conversations,
      );

      coordinator.onRecallNotify({'msgId': 'self'});

      expect(
        conversations.single.lastMessage,
        gvConversationRecallSelfPreview,
      );
    });
  });
}

ChatMessageLifecycleCoordinator _coordinator({
  required Map<String, List<ChatMessage>> messages,
  required List<Conversation> conversations,
  void Function()? onPersistConversations,
  void Function(ChatMessage)? onPersistMessage,
}) {
  var hidden = <String, List<dynamic>>{};
  return ChatMessageLifecycleCoordinator(
    messageMap: messages,
    pendingAcks: {},
    myId: () => 1,
    conversations: () => conversations,
    hiddenMessagesByChat: () => hidden,
    setHiddenMessagesByChat: (next) => hidden = next,
    chatKey: (chatType, peerId) => '$chatType:$peerId',
    isMessageLocallyCleared: (_, __) => false,
    persistConversations: onPersistConversations ?? () {},
    persistHidden: () {},
    persistMessageUpdate: onPersistMessage ?? (_) {},
    deletePersistedMessage: (_) {},
    clearPersistedSession: (_, __) {},
    notifyChanged: () {},
  );
}

ChatMessage _message({
  required String msgId,
  required int from,
  required DateTime timestamp,
  required String content,
}) {
  return ChatMessage(
    msgId: msgId,
    from: from,
    toId: '2',
    chatType: 'private',
    content: content,
    timestamp: timestamp,
  );
}

Conversation _conversation({
  required String lastMessage,
  required DateTime lastTime,
}) {
  return Conversation(
    id: '2',
    name: '对方',
    lastMessage: lastMessage,
    lastTime: lastTime,
  );
}
