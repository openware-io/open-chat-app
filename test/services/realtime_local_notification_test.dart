import 'package:flutter_test/flutter_test.dart';

import 'package:gv_chat_app/services/push_notification_service.dart';

void main() {
  group('realtimeChatNotificationsFrom', () {
    test('私聊实时消息生成与极光一致的聊天导航载荷', () {
      final notifications = realtimeChatNotificationsFrom(
        <String, dynamic>{
          'msgId': 'msg-1',
          'fromUserId': 17,
          'fromUsername': 'Alice',
          'toId': '32',
          'chatType': 'private',
          'msgType': 'text',
          'content': '你好',
          'timestamp': '2026-08-24T00:00:00Z',
        },
        currentUserId: 32,
        fallbackTitle: '新消息',
        fallbackBody: '收到新消息',
      );

      expect(notifications, hasLength(1));
      expect(notifications.single.title, 'Alice');
      expect(notifications.single.body, '你好');
      expect(notifications.single.payload, containsPair('chatType', 'private'));
      expect(notifications.single.payload, containsPair('peerId', '17'));
      expect(notifications.single.payload, containsPair('msgId', 'msg-1'));
    });

    test('batch 跳过自己其它设备同步回来的消息并保留群聊目标', () {
      final notifications = realtimeChatNotificationsFrom(
        <String, dynamic>{
          'type': 'batch',
          'messages': <Map<String, dynamic>>[
            <String, dynamic>{
              'msgId': 'own-message',
              'fromUserId': 32,
              'toId': '17',
              'chatType': 'private',
              'msgType': 'text',
              'content': '自己发送',
              'timestamp': '2026-08-24T00:00:00Z',
            },
            <String, dynamic>{
              'msgId': 'group-message',
              'fromUserId': 17,
              'toId': '88',
              'chatType': 'group',
              'msgType': 'image',
              'content': '{"url":"/image.jpg"}',
              'timestamp': '2026-08-24T00:00:01Z',
            },
          ],
        },
        currentUserId: 32,
        fallbackTitle: '新消息',
        fallbackBody: '收到新消息',
      );

      expect(notifications, hasLength(1));
      expect(notifications.single.msgId, 'group-message');
      expect(notifications.single.body, '收到新消息');
      expect(notifications.single.payload, containsPair('chatType', 'group'));
      expect(notifications.single.payload, containsPair('peerId', '88'));
    });

    test('无效实时载荷不会阻断或产生通知', () {
      expect(
        realtimeChatNotificationsFrom(
          <String, dynamic>{'msgId': 'missing-fields'},
          currentUserId: 32,
          fallbackTitle: '新消息',
          fallbackBody: '收到新消息',
        ),
        isEmpty,
      );
    });
  });
}
