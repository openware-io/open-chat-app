import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/models/favorite_models.dart';

/// 收藏相关模型的解析契约：原消息可用性状态必须严格按服务端字面量解析，
/// 未知/缺失一律落到 LOOKUP_UNAVAILABLE，保证客户端「绝不盲跳」。
void main() {
  group('FavoriteSourceState', () {
    test('解析服务端 state 字面量', () {
      expect(
        FavoriteSourceState.fromWire('AVAILABLE'),
        FavoriteSourceState.available,
      );
      expect(
        FavoriteSourceState.fromWire('MESSAGE_DELETED'),
        FavoriteSourceState.messageDeleted,
      );
      expect(
        FavoriteSourceState.fromWire('CONVERSATION_UNAVAILABLE'),
        FavoriteSourceState.conversationUnavailable,
      );
      expect(
        FavoriteSourceState.fromWire('NO_PERMISSION'),
        FavoriteSourceState.noPermission,
      );
      expect(
        FavoriteSourceState.fromWire('LOOKUP_UNAVAILABLE'),
        FavoriteSourceState.lookupUnavailable,
      );
    });

    test('大小写与空白容错', () {
      expect(
        FavoriteSourceState.fromWire(' available '),
        FavoriteSourceState.available,
      );
    });

    test('未知或缺失 state 一律按 LOOKUP_UNAVAILABLE 处理（fail closed）', () {
      expect(
        FavoriteSourceState.fromWire(null),
        FavoriteSourceState.lookupUnavailable,
      );
      expect(
        FavoriteSourceState.fromWire(''),
        FavoriteSourceState.lookupUnavailable,
      );
      expect(
        FavoriteSourceState.fromWire('SOMETHING_NEW'),
        FavoriteSourceState.lookupUnavailable,
      );
    });
  });

  group('FavoriteSource', () {
    test('只有 AVAILABLE 允许跳转原消息', () {
      const available = FavoriteSource(
        state: FavoriteSourceState.available,
        conversationId: 'conv:group:g1',
        messageId: 'm1',
      );
      expect(available.canOpenOriginal, isTrue);

      for (final state in const [
        FavoriteSourceState.messageDeleted,
        FavoriteSourceState.conversationUnavailable,
        FavoriteSourceState.noPermission,
        FavoriteSourceState.lookupUnavailable,
      ]) {
        expect(
          FavoriteSource(state: state, messageId: 'm1').canOpenOriginal,
          isFalse,
          reason: '$state 不允许跳转',
        );
      }
    });

    test('查询失败时的保守结果不带任何可跳转信息', () {
      expect(
        FavoriteSource.unavailable.state,
        FavoriteSourceState.lookupUnavailable,
      );
      expect(FavoriteSource.unavailable.canOpenOriginal, isFalse);
    });

    test('fromJson 兼容 camelCase / snake_case 并去除空串', () {
      final source = FavoriteSource.fromJson(const {
        'state': 'AVAILABLE',
        'conversation_id': 'conv:private:1:2',
        'message_id': ' m9 ',
      });
      expect(source.state, FavoriteSourceState.available);
      expect(source.conversationId, 'conv:private:1:2');
      expect(source.messageId, 'm9');

      final empty = FavoriteSource.fromJson(const {
        'state': 'NO_PERMISSION',
        'conversationId': '',
        'messageId': null,
      });
      expect(empty.conversationId, isNull);
      expect(empty.messageId, isNull);
    });
  });

  group('FavoriteBatchResult', () {
    test('解析 created / skipped / items', () {
      final result = FavoriteBatchResult.fromJson(const {
        'created': 2,
        'skipped': 1,
        'items': [
          {'messageId': 'm1', 'created': true},
          {'messageId': 'm2', 'created': true},
          {'messageId': 'm3', 'created': false},
        ],
      });
      expect(result.created, 2);
      expect(result.skipped, 1);
      expect(result.total, 3);
      expect(result.items, hasLength(3));
      expect(result.items.first.messageId, 'm1');
      expect(result.items.last.created, isFalse);
    });

    test('服务端未下发汇总时按 items 退化统计', () {
      final result = FavoriteBatchResult.fromJson(const {
        'items': [
          {'messageId': 'm1', 'created': true},
          {'messageId': 'm2', 'created': false},
        ],
      });
      expect(result.created, 1);
      expect(result.skipped, 1);
    });

    test('空响应退化为 0/0，不抛异常', () {
      final result = FavoriteBatchResult.fromJson(const {});
      expect(result.created, 0);
      expect(result.skipped, 0);
      expect(result.total, 0);
      expect(result.items, isEmpty);
    });
  });
}
