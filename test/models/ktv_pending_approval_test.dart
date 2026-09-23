import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/models/ktv_models.dart';

/// 客户「待确认加项」聚合视图的解析与派生口径。
///
/// 契约（服务端 `GET /business/orders/pending-approval`）：一次返回本门店
/// 待确认条数/金额/按订单分组的明细；金额是最小单位整数；混币种时不给单一币种。
void main() {
  Map<String, dynamic> payload() => <String, dynamic>{
        'pendingCount': 5,
        'pendingAmount': 3900,
        'currencyCode': '',
        'mixedCurrency': true,
        'revision': 77,
        'serverTimeMillis': 1789823610400,
        'orders': [
          {
            'orderId': 69,
            'orderNo': 'O1789808533711',
            'storeId': 100,
            'roomName': '小包 S03',
            'roomCode': 'S03',
            'sessionStatus': 'OPEN',
            'orderElapsedSeconds': 1234,
            'pendingCount': 4,
            'pendingAmount': 2400,
            'items': [
              {
                'id': 74,
                'name': '可乐300',
                'quantity': 1.0,
                'unitPrice': 200,
                'amount': 200,
                'currencyCode': 'USD',
                'createdAt': '2026-09-19T12:37:23.665',
              },
              {
                'id': 77,
                'name': '服务员点歌',
                'quantity': 2.0,
                'unitPrice': 1000,
                'amount': 2000,
                'currencyCode': 'USD',
                'createdAt': '2026-09-19T12:37:30.636',
              },
            ],
          },
          {
            'orderId': 66,
            'orderNo': 'O1789800711625',
            'roomName': '小包 K02',
            'sessionStatus': 'CLOSED',
            'pendingCount': 1,
            'pendingAmount': 1500,
            'items': [
              {
                'id': 62,
                'name': '百威啤酒',
                'quantity': 1.0,
                'unitPrice': 1500,
                'amount': 1500,
                'currencyCode': 'CNY',
              },
            ],
          },
        ],
      };

  test('解析条数/金额/revision 与按订单分组', () {
    final view = KtvPendingApprovalView.fromJson(payload());
    expect(view.pendingCount, 5);
    expect(view.pendingAmount, 3900);
    expect(view.revision, 77);
    expect(view.orders, hasLength(2));
    expect(view.orders.first.orderId, '69');
    expect(view.orders.first.roomLabel, '小包 S03');
    expect(view.orders.first.sessionStatus, 'OPEN');
    expect(view.orders.first.orderElapsedSeconds, 1234);
    expect(view.orders.first.items, hasLength(2));
    expect(view.orders.first.items.first.name, '可乐300');
    expect(view.orders.first.items.first.quantityText, '1');
    expect(view.orders.last.items.first.quantityText, '1');
  });

  test('混币种不给单一币种金额文案（禁止跨币种相加）', () {
    final view = KtvPendingApprovalView.fromJson(payload());
    expect(view.mixedCurrency, isTrue);
    expect(view.amountText, isEmpty, reason: '混币种时展示单一金额会暗示跨币种合计');
  });

  test('包厢展示名逐级兜底，绝不留空（门店必须先看清是哪间包厢的需求）', () {
    KtvPendingOrder order(Map<String, dynamic> json) => KtvPendingOrder.fromJson(json);

    // 服务端 roomName 优先
    expect(order({'orderId': 1, 'roomName': '小包 S03', 'roomCode': 'S03'}).roomLabel, '小包 S03');
    // 名称快照为空 → 编码快照
    expect(order({'orderId': 1, 'roomName': '', 'roomCode': 'S03'}).roomLabel, 'S03');
    // 只有 roomCode 字段（服务端没给 roomName）
    expect(order({'orderId': 1, 'roomCode': 'K02'}).roomLabel, 'K02');
    // 都没有（订单没有包厢会话 / 资源服务不可达）→ 明确文案，不是空串
    expect(order({'orderId': 1}).roomLabel, '未关联包厢');
    expect(order({'orderId': 1, 'roomName': '', 'roomCode': ''}).roomLabel, '未关联包厢');
  });

  test('单一币种时金额走唯一格式化入口（最小单位 -> 展示）', () {
    final view = KtvPendingApprovalView.fromJson(<String, dynamic>{
      'pendingCount': 1,
      'pendingAmount': 1500,
      'currencyCode': 'CNY',
      'mixedCurrency': false,
      'revision': 62,
      'orders': const <dynamic>[],
    });
    expect(view.mixedCurrency, isFalse);
    expect(view.amountText, isNotEmpty);
    expect(view.amountText, contains('15'),
        reason: '1500 分 CNY 应展示为 15.00，而不是 1500');
  });

  test('pendingCountOf / orderOf 按订单取值，未知订单为 0/null', () {
    final view = KtvPendingApprovalView.fromJson(payload());
    expect(view.pendingCountOf('69'), 4);
    expect(view.pendingCountOf('66'), 1);
    expect(view.pendingCountOf('999'), 0);
    expect(view.orderOf('999'), isNull);
  });

  test('withoutItem 只做计数/金额同步减，不重算币种口径', () {
    final view = KtvPendingApprovalView.fromJson(payload());
    final next = view.withoutItem('74');
    expect(next.pendingCount, 4);
    expect(next.pendingAmount, 3700);
    expect(next.mixedCurrency, isTrue, reason: '剩余命中行币种组合未变');
    expect(next.orderOf('69')!.items.map((i) => i.id), ['77']);
    expect(next.revision, view.revision, reason: 'revision 是服务端快照，不本地重算');

    // 不存在的明细：原样返回（不产生幽灵变更）。
    expect(identical(view.withoutItem('404'), view), isTrue);
  });

  test('withoutItem 减到 0 时清空金额与币种', () {
    final view = KtvPendingApprovalView.fromJson(<String, dynamic>{
      'pendingCount': 1,
      'pendingAmount': 1500,
      'currencyCode': 'CNY',
      'revision': 62,
      'orders': [
        {
          'orderId': 66,
          'pendingCount': 1,
          'pendingAmount': 1500,
          'items': [
            {'id': 62, 'name': 'x', 'quantity': 1, 'amount': 1500},
          ],
        },
      ],
    });
    final next = view.withoutItem('62');
    expect(next.pendingCount, 0);
    expect(next.hasPending, isFalse);
    expect(next.pendingAmount, 0);
    expect(next.currencyCode, isEmpty);
    expect(next.amountText, isEmpty);
  });

  test('空响应不编造待确认数据', () {
    final view = KtvPendingApprovalView.fromJson(const <String, dynamic>{});
    expect(view.pendingCount, 0);
    expect(view.hasPending, isFalse);
    expect(view.orders, isEmpty);
    expect(KtvPendingApprovalView.empty.pendingCount, 0);
  });
}
