import 'package:flutter_test/flutter_test.dart';

import 'package:gv_chat_app/models/channel_models.dart';
import 'package:gv_chat_app/models/secret_chat_models.dart';

void main() {
  group('ChannelInfo.fromJson', () {
    test('parses camelCase channel payload', () {
      final info = ChannelInfo.fromJson(const {
        'id': 42,
        'name': '产品公告',
        'description': '发布订阅',
        'ownerId': 1,
        'memberCount': 128,
        'role': 'owner',
        'subscribed': true,
      });

      expect(info.id, '42');
      expect(info.name, '产品公告');
      expect(info.description, '发布订阅');
      expect(info.ownerId, 1);
      expect(info.memberCount, 128);
      expect(info.isOwner, isTrue);
      expect(info.subscribed, isTrue);
    });

    test('parses snake_case payload and defaults role to subscriber', () {
      final info = ChannelInfo.fromJson(const {
        'id': 7,
        'title': 'Announcements',
        'owner_id': 3,
        'member_count': 5,
      });

      expect(info.id, '7');
      expect(info.name, 'Announcements');
      expect(info.ownerId, 3);
      expect(info.memberCount, 5);
      expect(info.role, 'subscriber');
      expect(info.isOwner, isFalse);
      expect(info.subscribed, isFalse);
    });

    test('admin role counts as owner', () {
      final info = ChannelInfo.fromJson(const {'id': 1, 'role': 'admin'});
      expect(info.isOwner, isTrue);
    });
  });

  group('SecretChatDestroyPolicy.normalize', () {
    test('normalizes backend variants to the wire contract', () {
      expect(SecretChatDestroyPolicy.normalize(null), 'off');
      expect(SecretChatDestroyPolicy.normalize('off'), 'off');
      expect(SecretChatDestroyPolicy.normalize('OFF'), 'off');
      expect(SecretChatDestroyPolicy.normalize('30_SECONDS'), '30s');
      expect(SecretChatDestroyPolicy.normalize('5_minutes'), '5m');
      expect(SecretChatDestroyPolicy.normalize('1hour'), '1h');
      expect(SecretChatDestroyPolicy.normalize('1_day'), '1d');
      expect(SecretChatDestroyPolicy.normalize('bogus'), 'off');
    });
  });

  group('SecretChatInfo.fromJson', () {
    test('parses safe code and destroy policy', () {
      final info = SecretChatInfo.fromJson(const {
        'id': 99,
        'peerUserId': 7,
        'safeCode': 'ABCD-EFGH',
        'destroyPolicy': '5m',
        'createdAt': '2026-08-18T10:00:00Z',
      });

      expect(info.id, '99');
      expect(info.peerUserId, 7);
      expect(info.safeCode, 'ABCD-EFGH');
      expect(info.destroyPolicy, '5m');
      expect(info.createdAt, isNotNull);
    });

    test('falls back to off when destroy policy is absent', () {
      final info = SecretChatInfo.fromJson(const {'id': 1});
      expect(info.destroyPolicy, 'off');
      expect(info.safeCode, '');
    });
  });
}
