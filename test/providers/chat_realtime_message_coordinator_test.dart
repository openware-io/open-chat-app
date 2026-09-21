import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/models/chat_message.dart';
import 'package:gv_chat_app/providers/chat/chat_provider_types.dart';
import 'package:gv_chat_app/providers/chat/chat_realtime_message_coordinator.dart';

void main() {
  late Map<String, List<ChatMessage>> messageMap;
  late ChatRealtimeMessageCoordinator coordinator;

  Map<String, dynamic> message({
    required String msgId,
    required int from,
  }) =>
      <String, dynamic>{
        'msgId': msgId,
        'from': from,
        'toId': '100',
        'chatType': 'private',
        'msgType': 'text',
        'content': 'hello',
        'timestamp': '2026-08-24T01:00:00Z',
        'status': 'sent',
      };

  setUp(() {
    messageMap = <String, List<ChatMessage>>{};
    DeferredRealtimeSessionInsert? deferredInsert;
    coordinator = ChatRealtimeMessageCoordinator(
      myId: () => 100,
      currentChatId: () => null,
      currentChatType: () => 'private',
      isForeground: () => true,
      allowRealtimeMergeIntoCurrentChatList: () => true,
      messageMap: messageMap,
      pendingAcks: <String, ChatMessage>{},
      chatKey: (chatType, peerId) => '$chatType:$peerId',
      deferredRealtimeSessionInsert: () => deferredInsert,
      setDeferredRealtimeSessionInsert: (next) => deferredInsert = next,
      bumpRealtimeIngestEpoch: (_) {},
      isMessageMutedByReadWatermark: (_, __) => false,
      isMessageLocallyCleared: (_, __) => false,
      upsertConversation: (
        _,
        __,
        ___, {
        incrementUnread = false,
        name,
        lastTime,
      }) {},
      persistMessage: (_, __) {},
      confirmPendingMessage: (_, __, ___) {},
      maybeScheduleAddressBookSyncForIncoming: (_, __) {},
      markRead: (_) {},
      maybeTriggerInAppNewMessageBanner: () {},
      notifyChanged: () {},
    );
  });

  test('new incoming message requests a foreground notification sound', () {
    expect(
        coordinator.onMessageReceived(message(msgId: 'm1', from: 2)), isTrue);
  });

  test('own-device message does not request a notification sound', () {
    expect(
      coordinator.onMessageReceived(message(msgId: 'm1', from: 100)),
      isFalse,
    );
  });

  test('duplicate incoming message requests a sound only once', () {
    final raw = message(msgId: 'm1', from: 2);

    expect(coordinator.onMessageReceived(raw), isTrue);
    expect(coordinator.onMessageReceived(raw), isFalse);
  });

  test('incoming batch requests one sound while ignoring own messages', () {
    expect(
      coordinator.onMessageReceived(<String, dynamic>{
        'type': 'batch',
        'messages': <Map<String, dynamic>>[
          message(msgId: 'own', from: 100),
          message(msgId: 'incoming-1', from: 2),
          message(msgId: 'incoming-2', from: 3),
        ],
      }),
      isTrue,
    );
  });
}
