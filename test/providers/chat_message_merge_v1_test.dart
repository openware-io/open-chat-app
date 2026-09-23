import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/models/chat_message.dart';
import 'package:open_chat_app/providers/chat/chat_message_merge.dart';

void main() {
  test('parses frozen v1 message field names', () {
    final message = ChatMessage.fromJson({
      'msgId': 'm1',
      'fromUserId': 8,
      'senderUsername': 'alice',
      'toId': '1',
      'chatType': 'PRIVATE',
      'msgType': 'text',
      'content': 'hello',
      'createdAt': '2026-07-31T08:00:00Z',
      'seq': 12,
      'status': 'sent',
    });

    expect(message.from, 8);
    expect(message.fromUsername, 'alice');
    expect(message.timestamp, DateTime.utc(2026, 7, 31, 8));
    expect(message.seq, 12);
  });

  test('orders v1 messages by server sequence before device timestamp', () {
    final laterDeviceTime = ChatMessage(
      msgId: 'm1',
      from: 1,
      toId: '8',
      chatType: 'private',
      timestamp: DateTime.utc(2026, 7, 31, 12),
      seq: 1,
    );
    final earlierDeviceTime = ChatMessage(
      msgId: 'm2',
      from: 8,
      toId: '1',
      chatType: 'private',
      timestamp: DateTime.utc(2026, 7, 31, 11),
      seq: 2,
    );
    final messages = [earlierDeviceTime, laterDeviceTime];

    sortChatMessagesChronological(messages);

    expect(messages.map((message) => message.msgId), ['m1', 'm2']);
  });

  test('parses managed voice media from server response', () {
    final message = ChatMessage.fromJson({
      'msgId': 'voice-1',
      'fromUserId': 8,
      'toId': '1',
      'chatType': 'private',
      'msgType': 'voice',
      'content': '',
      'createdAt': '2026-08-04T08:00:00Z',
      'media': [
        {
          'objectId': 'media-voice-1',
          'url': 'http://192.168.1.3:9000/private/voice.m4a?signature=1',
        },
      ],
    });

    expect(message.mediaObjectIds, ['media-voice-1']);
    expect(
      message.content,
      'http://192.168.1.3:9000/private/voice.m4a?signature=1',
    );
  });

  test('keeps image caption while injecting managed display URL', () {
    final message = ChatMessage.fromJson({
      'msgId': 'image-1',
      'fromUserId': 8,
      'toId': '1',
      'chatType': 'private',
      'msgType': 'image',
      'content': 'summer',
      'createdAt': '2026-08-04T08:00:00Z',
      'media': [
        {
          'objectId': 'media-image-1',
          'url': 'http://192.168.1.3:9000/private/image.jpg?signature=1',
        },
      ],
    });

    expect(message.mediaObjectIds, ['media-image-1']);
    expect(message.content, contains('"caption":"summer"'));
    expect(message.content, contains('"url":"http://192.168.1.3:9000/'));
  });
}
