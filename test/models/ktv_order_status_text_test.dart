import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/models/ktv_models.dart';

/// 状态文案与术语口径（收银端 / 看板 / C 端 l10n）。
///
/// 背景（领域重构 ORDER_ROOM_INVENTORY_TARGET §2/§4）：
/// - 订单主表只表达**交易状态** `tradeStatus`（DRAFT/PENDING_PAYMENT/PAID/COMPLETED/CANCELLED/VOIDED）；
/// - KTV 业务状态在**会话状态** `sessionStatus`（RESERVED/OPEN/PAUSED/CLOSED/CANCELLED）；
/// - 结算进度由服务端派生 `settlementStatus`；
/// - `ord_order.status` 是收口前兼容列，客户端只在旧后端缺字段时兜底推导，不再直接渲染。
///
/// 本用例守住「后端每个状态都有中文、不把英文枚举透给收银员」，以及三端术语一致。
void main() {
  test('后端全部交易状态都有中文，不透英文枚举', () {
    const statuses = [
      'DRAFT',
      'PENDING_PAYMENT',
      'PAID',
      'COMPLETED',
      'CANCELLED',
      'VOIDED',
    ];
    for (final status in statuses) {
      final label = tradeStatusLabel(status);
      expect(label, isNot(status), reason: '$status 未映射中文（会透英文枚举）');
      expect(RegExp(r'^[A-Z_]+$').hasMatch(label), isFalse,
          reason: '$status 的中文里混进了英文枚举形态：$label');
      expect(label, isNotEmpty);
    }
  });

  test('会话/结算/退款状态同样有中文映射', () {
    for (final status in const ['RESERVED', 'OPEN', 'PAUSED', 'CLOSED', 'CANCELLED']) {
      expect(sessionStatusLabel(status), isNot(status));
    }
    for (final status in const [
      'UNSETTLED',
      'PENDING_PAYMENT',
      'PAID',
      'COMPLETED',
      'CANCELLED',
      'REFUNDED',
      'PARTIALLY_REFUNDED',
    ]) {
      expect(settlementStatusLabel(status), isNot(status));
    }
    expect(orderRefundStatusLabel('NONE'), '未退款');
    expect(orderRefundStatusLabel('FULL'), '已全额退款');
  });

  test('大小写不敏感；未知状态回退原码（可见、可排查，不猜中文）', () {
    expect(tradeStatusLabel('pending_payment'), '待收款');
    expect(sessionStatusLabel('open'), '计时中');
    expect(tradeStatusLabel('SOME_NEW_STATUS'), 'SOME_NEW_STATUS');
  });

  test('与 Web 后台/契约词表对齐', () {
    expect(ktvTradeStatusText.keys.toSet(), {
      'DRAFT',
      'PENDING_PAYMENT',
      'PAID',
      'COMPLETED',
      'CANCELLED',
      'VOIDED',
    });
    // KTV 开台中仍是交易 DRAFT（订单未进入结算），开台中是会话状态
    expect(tradeStatusLabel('DRAFT'), '开台中');
    expect(tradeStatusLabel('PENDING_PAYMENT'), '待收款');
    expect(tradeStatusLabel('PAID'), '已收款');
    expect(tradeStatusLabel('COMPLETED'), '已完成');
    expect(tradeStatusLabel('CANCELLED'), '已取消');
    // 审批作废/冲正独立于用户取消（报表分开统计）
    expect(tradeStatusLabel('VOIDED'), '已作废');
  });

  test('旧 ord_order.status 只在新字段缺失时兜底推导交易状态', () {
    expect(tradeStatusFromLegacy('SERVING'), 'DRAFT');
    expect(tradeStatusFromLegacy('WAITING_SETTLEMENT'), 'PENDING_PAYMENT');
    expect(tradeStatusFromLegacy('WAITING_PAYMENT'), 'PENDING_PAYMENT');
    expect(tradeStatusFromLegacy('VOIDED'), 'VOIDED');
    expect(tradeStatusFromLegacy('CANCELLED'), 'CANCELLED');
    expect(tradeStatusFromLegacy('COMPLETED'), 'COMPLETED');

    final order = KtvOrder.fromJson(<String, dynamic>{
      'id': 'ord_1',
      'orderNo': 'KT1',
      'status': 'WAITING_SETTLEMENT',
      'totalAmount': '100',
      'paidAmount': '0',
      'currency': 'CNY',
    });
    expect(order.effectiveTradeStatus, 'PENDING_PAYMENT');
    expect(order.displayStatusText, '待收款');
  });

  test('列表展示状态：优先会话业务状态，结台/无会话回落交易状态', () {
    Map<String, dynamic> json(String trade, String? session) => {
          'id': 'ord_1',
          'orderNo': 'KT1',
          'status': 'SERVING',
          'tradeStatus': trade,
          if (session != null) 'sessionStatus': session,
          'totalAmount': '100',
          'paidAmount': '0',
          'currency': 'CNY',
        };
    expect(KtvOrder.fromJson(json('DRAFT', 'OPEN')).displayStatusText, '计时中');
    expect(KtvOrder.fromJson(json('DRAFT', 'PAUSED')).displayStatusText, '已暂停');
    expect(KtvOrder.fromJson(json('DRAFT', 'RESERVED')).displayStatusText, '待开台');
    expect(KtvOrder.fromJson(json('PENDING_PAYMENT', 'CLOSED')).displayStatusText, '待收款');
    expect(KtvOrder.fromJson(json('COMPLETED', null)).displayStatusText, '已完成');
    expect(KtvOrder.fromJson(json('VOIDED', 'CANCELLED')).displayStatusText, '已取消');
  });

  test('会话态 RESERVED = 待开台；包厢被预订（资源态）才是「已预订」', () {
    const session = KtvSession(
      id: '1',
      orderId: '1',
      status: 'RESERVED',
      billingStartAt: null,
      pausedSeconds: 0,
      openedAt: null,
      closedAt: null,
      expectedVersion: 0,
    );
    expect(session.statusText, '待开台');
    expect(
        const KtvSession(
          id: '1',
          orderId: '1',
          status: 'OPEN',
          billingStartAt: null,
          pausedSeconds: 0,
          openedAt: null,
          closedAt: null,
          expectedVersion: 0,
        ).statusText,
        '计时中');
  });

  test('账单同时带交易/会话/结算状态，展示口径与订单一致', () {
    final bill = KtvBill.fromJson(<String, dynamic>{
      'orderId': '1',
      'orderNo': 'KT1',
      'currency': 'CNY',
      'status': 'WAITING_PAYMENT',
      'tradeStatus': 'PENDING_PAYMENT',
      'sessionStatus': 'CLOSED',
      'settlementStatus': 'PENDING_PAYMENT',
      'refundStatus': 'NONE',
      'roomFee': <String, dynamic>{},
      'items': <dynamic>[],
      'serverFee': <String, dynamic>{},
      'promotions': <dynamic>[],
      'subtotalAmount': '100',
      'discountAmount': '0',
      'taxAmount': '0',
      'totalAmount': '100',
      'paidAmount': '0',
      'paidByMethod': <String, dynamic>{},
      'changeAmount': '0',
    });
    expect(bill.tradeLabel, '待收款');
    expect(bill.displayStatusText, '待收款');
    expect(bill.settlementLabel, '待收款');
  });

  test('收银页/看板不再出现过时叫法（已预留），也不再渲染旧订单状态', () {
    for (final path in const [
      'lib/screens/business/ktv_cashier_screen.dart',
      'lib/screens/business/ktv_dashboard_screen.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source.contains('已预留'), isFalse,
          reason: '$path 仍有「已预留」（会话用「待开台」、包厢预订用「已预订」）');
      expect(source.contains('WAITING_SETTLEMENT'), isFalse,
          reason: '$path 仍把已废弃的订单状态当业务判据');
      expect(source.contains('SERVING'), isFalse,
          reason: '$path 仍把 SERVING 当订单状态（开台中是会话状态）');
    }
    // 模型层保留旧状态映射是**兼容**：只在旧后端缺 tradeStatus/sessionStatus 时兜底，页面不得直接用。
    final models = File('lib/models/ktv_models.dart').readAsStringSync();
    expect(models.contains('已预留'), isFalse);
  });

  test('收银页不再自带局部状态 switch（统一走模型层 displayStatusText）', () {
    final source =
        File('lib/screens/business/ktv_cashier_screen.dart').readAsStringSync();
    expect(source.contains('displayStatusText'), isTrue,
        reason: '收银页必须复用模型层唯一入口');
    expect(source.contains("case 'WAITING_SETTLEMENT':"), isFalse,
        reason: '不得再写局部 switch：漏一个状态就会把英文枚举显示给收银员');
  });

  test('C 端场所预约/包厢文案已统一（包间→包厢、场所预订→预约；机票酒店「预订人」保留）', () {
    final arb = File('lib/l10n/app_zh.arb').readAsStringSync();
    expect(arb.contains('包间'), isFalse, reason: 'C 端仍出现「包间」');
    expect(arb.contains('立即预约'), isTrue);
    expect(arb.contains('预约方式'), isTrue);
    expect(arb.contains('包厢套餐'), isTrue);
    // 机票/酒店出行流程的「预订人」是正确的业务叫法，刻意保留
    expect(arb.contains('预订人姓名'), isTrue);
  });
}
