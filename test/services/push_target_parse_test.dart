import 'package:flutter_test/flutter_test.dart';

import 'package:open_chat_app/services/push_notification_service.dart';

/// 推送点击导航 peerId 解析回归测试。
///
/// 背景：推送 extras 的 conversationId 是归一化会话标识（conv:private:17:32），
/// 旧实现把它直接当 peerId，进房校验 int.tryParse 失败 → 误报「不是好友或
/// 此群已解散」并退出聊天室（聊天记录其实完好）。
void main() {
  group('normalizeCallInvitePayload', () {
    test('call classification wins over a private conversation target', () {
      final result = normalizeCallInvitePayload({
        'chatType': 'call',
        'peerId': '17',
        'conversationId': 'conv:private:17:32',
        'callId': 'invite-1',
        'fromUserId': '17',
        'mediaType': 'video',
      });
      expect(result!['chatType'], 'call');
      expect(result['callId'], 'invite-1');
      expect(result['mediaType'], 'video');
    });

    test('notification type identifies call and normalizes alternate keys', () {
      final result = normalizeCallInvitePayload({
        'notification_type': 'CALL',
        'chat_type': 'private',
        'call_id': ' invite-2 ',
        'from_user_id': '17',
        'media_type': 'audio',
        'from_username': 'Peer',
        'from_avatar': 'avatar.png',
      });
      expect(result!['chatType'], 'call');
      expect(result['callId'], 'invite-2');
      expect(result['fromUserId'], '17');
      expect(result['mediaType'], 'audio');
      expect(result['fromUsername'], 'Peer');
      expect(result['fromAvatar'], 'avatar.png');
    });

    test('ordinary messages and call-history messages are not invites', () {
      expect(
          normalizeCallInvitePayload({
            'chatType': 'private',
            'type': 'call',
            'peerId': '17',
          }),
          isNull);
      expect(
          normalizeCallInvitePayload({'chatType': 'friend_request'}), isNull);
    });
  });

  group('resolveChatTargetPeerId', () {
    test('私聊推送（extras 含 conversationId + fromUserId）取 fromUserId 为 peerId', () {
      final payload = <String, String>{
        'conversationId': 'conv:private:17:32',
        'fromUserId': '17',
        'chatType': 'private',
      };
      expect(resolveChatTargetPeerId(payload, 'private'), '17',
          reason: '不得把归一化 conversationId 当 peerId，私聊应取发送方 id');
    });

    test('私聊推送无 fromUserId 时从 conversationId 兜底提取末尾数字 id', () {
      final payload = <String, String>{
        'conversationId': 'conv:private:17:32',
        'chatType': 'private',
      };
      final peerId = resolveChatTargetPeerId(payload, 'private');
      expect(peerId, isNotNull);
      expect(int.tryParse(peerId!), isNotNull,
          reason: 'peerId 必须是可解析的数字 id（否则进房好友校验误拦）');
    });

    test('显式 peerId 优先于 conversationId', () {
      final payload = <String, String>{
        'peerId': '17',
        'conversationId': 'conv:private:17:32',
        'chatType': 'private',
      };
      expect(resolveChatTargetPeerId(payload, 'private'), '17');
    });

    test('群聊推送取 groupId', () {
      final payload = <String, String>{
        'groupId': '88',
        'conversationId': 'conv:group:88',
        'chatType': 'group',
      };
      expect(resolveChatTargetPeerId(payload, 'group'), '88');
    });
  });
}
