import 'package:flutter_test/flutter_test.dart';

import 'package:gv_chat_app/models/secret_group_chat_models.dart';

/// 私密群聊模型 fromJson 容错测试：字段名、long→String、null 容错。
void main() {
  group('SecretGroupChatInfo.fromJson', () {
    test('camelCase 字段 + long id 转 String + members 解析', () {
      final info = SecretGroupChatInfo.fromJson({
        'id': 1001,
        'ownerUserId': 7,
        'status': 'active',
        'safeCode': 'AB CD EF 01',
        'destroyPolicy': '1h',
        'members': [
          {'userId': 7, 'devicePublicKey': 'PUB7', 'joinedAt': '2026-08-19T00:00:00'},
          {'userId': 8, 'devicePublicKey': null, 'joinedAt': null},
        ],
        'createdBy': 7,
        'createdAt': '2026-08-19T00:00:00',
        'updatedBy': 7,
        'updatedAt': '2026-08-19T00:00:00',
      });

      expect(info.id, '1001');
      expect(info.ownerUserId, 7);
      expect(info.status, 'active');
      expect(info.safeCode, 'AB CD EF 01');
      expect(info.destroyPolicy, '1h');
      expect(info.members, hasLength(2));
      expect(info.members[0].userId, 7);
      expect(info.members[0].devicePublicKey, 'PUB7');
      expect(info.members[0].joinedAt, isNotNull);
      expect(info.members[1].devicePublicKey, isNull);
      expect(info.members[1].joinedAt, isNull);
      expect(info.createdAt, isNotNull);
    });

    test('id 为字符串 + members 缺失 → 空列表 + safeCode null 容错为空串', () {
      final info = SecretGroupChatInfo.fromJson({
        'id': '42',
        'safeCode': null,
        'destroyPolicy': 'off',
      });

      expect(info.id, '42');
      expect(info.ownerUserId, isNull);
      expect(info.safeCode, '');
      expect(info.destroyPolicy, 'off');
      expect(info.members, isEmpty);
    });

    test('destroyPolicy 兼容下划线变体归一化', () {
      final info = SecretGroupChatInfo.fromJson({
        'id': 3,
        'destroyPolicy': '30_SECONDS',
      });
      expect(info.destroyPolicy, '30s');
    });
  });
}
