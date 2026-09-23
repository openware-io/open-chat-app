import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/models/ktv_models.dart';

/// 状态文案与术语口径（收银端 / 看板 / C 端 l10n）。
///
/// 背景 1：收银列表拉的是**全部订单**（`KtvApiClient.listOrders`），原先页面里只有 4 个状态的局部
/// switch、其余 `default: return status`，于是 DRAFT / WAITING_PAYMENT / PARTIAL_REFUNDED / REFUNDED
/// 会**把英文枚举直接显示给收银员**。现在收敛到模型层唯一入口，本用例守住「后端每个状态都有中文」。
///
/// 背景 2：术语一致性排查把三端叫法统一为——订单 `WAITING_SETTLEMENT`=「待结算」、
/// 会话 `RESERVED`=「待开台」、包厢被预订（资源态）=「已预订」、C 端场所预约用「预约」/包厢用「包厢」
/// （机票/酒店出行流程的「预订人」保留）。
void main() {
  test('后端全部订单状态都有中文，不透英文枚举', () {
    const statuses = [
      'DRAFT',
      'SERVING',
      'WAITING_SETTLEMENT',
      'WAITING_PAYMENT',
      'WAITING_ARRIVAL',
      'COMPLETED',
      'PARTIAL_REFUNDED',
      'REFUNDED',
      'VOIDED',
      'CANCELLED',
    ];
    for (final status in statuses) {
      final label = orderStatusLabel(status);
      expect(label, isNot(status), reason: '$status 未映射中文（会透英文枚举）');
      expect(RegExp(r'^[A-Z_]+$').hasMatch(label), isFalse,
          reason: '$status 的中文里混进了英文枚举形态：$label');
      expect(label, isNotEmpty);
    }
  });

  test('大小写不敏感；未知状态回退原码（可见、可排查，不猜中文）', () {
    expect(orderStatusLabel('serving'), '服务中');
    expect(orderStatusLabel('Waiting_Settlement'), '待结算');
    expect(orderStatusLabel('SOME_NEW_STATUS'), 'SOME_NEW_STATUS');
  });

  test('与 Web 后台词表完全对齐（含 WAITING_SETTLEMENT = 待结算）', () {
    // 与 gv_saas_admin/src/constants/terms.js#ORDER_STATUS_TEXT 相同的状态集合
    expect(ktvOrderStatusText.keys.toSet(), {
      'DRAFT', 'SERVING', 'WAITING_SETTLEMENT', 'WAITING_PAYMENT', 'WAITING_ARRIVAL',
      'COMPLETED', 'PARTIAL_REFUNDED', 'REFUNDED', 'VOIDED', 'CANCELLED',
    });
    // 三端同词：后台/H5/App 都是「待结算」（曾出现收银端「待收款」）
    expect(orderStatusLabel('WAITING_SETTLEMENT'), '待结算');
    expect(orderStatusLabel('WAITING_PAYMENT'), '待支付');
    expect(orderStatusLabel('COMPLETED'), '已完成');
    expect(orderStatusLabel('VOIDED'), '已作废');
  });

  test('会话态 RESERVED = 待开台；包厢被预订（资源态）才是「已预订」', () {
    const session = KtvSession(
      id: '1', orderId: '1', status: 'RESERVED', billingStartAt: null,
      pausedSeconds: 0, openedAt: null, closedAt: null, expectedVersion: 0,
    );
    expect(session.statusText, '待开台');
    expect(KtvSession(
      id: '1', orderId: '1', status: 'OPEN', billingStartAt: null,
      pausedSeconds: 0, openedAt: null, closedAt: null, expectedVersion: 0,
    ).statusText, '计时中');
  });

  test('收银页/看板不再出现过时叫法（待收款 / 已预留）', () {
    for (final path in const [
      'lib/screens/business/ktv_cashier_screen.dart',
      'lib/screens/business/ktv_dashboard_screen.dart',
      'lib/models/ktv_models.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source.contains('待收款'), isFalse, reason: '$path 仍有「待收款」（统一为「待结算」）');
      expect(source.contains('已预留'), isFalse, reason: '$path 仍有「已预留」（会话用「待开台」、包厢预订用「已预订」）');
    }
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

  test('收银页不再自带局部状态 switch（统一走 orderStatusLabel）', () {
    final source = File('lib/screens/business/ktv_cashier_screen.dart').readAsStringSync();
    expect(source.contains('orderStatusLabel('), isTrue,
        reason: '收银页必须复用模型层唯一入口');
    expect(source.contains("case 'WAITING_SETTLEMENT':"), isFalse,
        reason: '不得再写局部 switch：漏一个状态就会把英文枚举显示给收银员');
  });
}
