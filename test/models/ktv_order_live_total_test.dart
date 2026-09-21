import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/models/ktv_models.dart';

/// 订单展示金额的唯一来源：服务端「可直接展示总额」`liveTotalAmount`。
///
/// 背景（Web 后台线上问题，同一形状）：房态卡片原先展示「落库总额 + 前端包厢费估算」，
/// 同一单账单 6150 / 卡片 10150，包厢费被算了两遍。服务端订单投影现在直接给
/// `liveTotalAmount`（已含当前会话实时包厢费，结台后退回落库总额），客户端只格式化。
///
/// 兼容口径：`liveTotalAmount` / `live_total_amount` 都认；缺失或为空（老后端）时
/// 回退 `totalAmount`，展示行为与改造前一致。
Map<String, dynamic> orderJson(Map<String, dynamic> extra) => <String, dynamic>{
      'id': 'ord_002',
      'orderNo': 'KT20260817-0001',
      'status': 'SERVING',
      'roomName': 'A02',
      'sessionId': 'ses_002',
      'sessionStatus': 'OPEN',
      'totalAmount': '6150',
      'paidAmount': '0',
      'currency': 'CNY',
      ...extra,
    };

void main() {
  test('优先取 liveTotalAmount：实时总额（已含包厢费）不是落库总额', () {
    final order = KtvOrder.fromJson(orderJson({'liveTotalAmount': '10150'}));

    expect(order.liveTotalAmount.minorUnits, 10150);
    expect(order.totalAmount.minorUnits, 6150, reason: '落库总额仍要保留（对账/排查）');
    expect(order.liveTotalAmount.formatted, '¥101.50');
    expect(order.liveTotalAmount.currency, 'CNY');
  });

  test('snake_case 契约 live_total_amount 同样认', () {
    final order = KtvOrder.fromJson(orderJson({'live_total_amount': '10150'}));

    expect(order.liveTotalAmount.minorUnits, 10150);
  });

  test('老后端没有 live 字段时回退 totalAmount（与改造前行为一致）', () {
    final order = KtvOrder.fromJson(orderJson(const {}));

    expect(order.liveTotalAmount.minorUnits, 6150);
    expect(order.liveTotalAmount.formatted, order.totalAmount.formatted);
  });

  test('字段给了空串（后端半成品）也回退 totalAmount，不显示 0', () {
    final order = KtvOrder.fromJson(orderJson({'liveTotalAmount': ''}));

    expect(order.liveTotalAmount.minorUnits, 6150);
    expect(order.liveTotalAmount.formatted, '¥61.50');
  });

  test('camelCase 优先于 snake_case（同一响应里两者都在时）', () {
    final order = KtvOrder.fromJson(orderJson({
      'liveTotalAmount': '10150',
      'live_total_amount': '99999',
    }));

    expect(order.liveTotalAmount.minorUnits, 10150);
  });

  test('直接构造（dev mock）不传 liveTotalAmount 时回退 totalAmount', () {
    const order = KtvOrder(
      id: 'ord_002',
      orderNo: 'KT1',
      status: 'SERVING',
      totalAmount: KtvMoney(minorUnits: 51200, currency: 'CNY'),
      paidAmount: KtvMoney(minorUnits: 0, currency: 'CNY'),
      currency: 'CNY',
      allowedActions: [],
    );

    expect(order.liveTotalAmount.minorUnits, 51200);
  });
}
