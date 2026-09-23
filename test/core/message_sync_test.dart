import 'package:flutter_test/flutter_test.dart';
import 'package:gv_core/gv_core.dart';
import 'package:open_chat_app/models/message_sync.dart';

void main() {
  test('parses a message synchronization page', () {
    final page = MessageSyncPage.fromJson({
      'items': [
        {
          'syncSeq': 11,
          'readAt': '2026-08-17T09:01:00Z',
          'message': {
            'msgId': 'message-11',
            'fromUserId': 8,
            'toId': '1',
            'chatType': 'private',
            'content': 'hello',
            'createdAt': '2026-08-17T09:00:00Z',
          },
        },
      ],
      'nextSyncSeq': 11,
      'hasMore': false,
    });

    expect(page.nextSyncSeq, 11);
    expect(page.hasMore, isFalse);
    expect(page.items.single.syncSeq, 11);
    expect(page.items.single.message['msgId'], 'message-11');
    expect(page.items.single.message['status'], 'read');
    expect(page.items.single.readAt, DateTime.utc(2026, 8, 17, 9, 1));
  });

  test('interprets legacy bare message times as UTC', () {
    final page = MessageSyncPage.fromJson({
      'items': [
        {
          'syncSeq': 1,
          'readAt': null,
          'message': {
            'msgId': 'message-1',
            'fromUserId': 8,
            'toId': '1',
            'chatType': 'private',
            'content': 'hello',
            'createdAt': '2026-08-17T09:00:00',
          },
        },
      ],
      'nextSyncSeq': 1,
      'hasMore': false,
    });

    expect(page.items.single.readAt, isNull);
    expect(page.items.single.message['createdAt'], '2026-08-17T09:00:00');
    final message = ChatMessage.fromJson(page.items.single.message);
    expect(message.timestamp, DateTime.utc(2026, 8, 17, 9));
  });

  test('rejects a synchronization page without a valid watermark', () {
    expect(
      () => MessageSyncPage.fromJson({
        'items': const [],
        'nextSyncSeq': -1,
        'hasMore': false,
      }),
      throwsFormatException,
    );
  });
}
