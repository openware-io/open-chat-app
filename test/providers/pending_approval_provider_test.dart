import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/api_failure.dart';
import 'package:open_chat_app/models/ktv_models.dart';
import 'package:open_chat_app/providers/pending_approval_provider.dart';
import 'package:open_chat_app/repositories/business/ktv_api_client.dart';

/// 可编程的假客户端：只覆盖待确认加项相关的三个方法，其余走父类（测试里不会被调用）。
class _FakeKtvApi extends KtvApiClient {
  KtvPendingApprovalView next = KtvPendingApprovalView.empty;
  Object? viewError;
  Object? writeError;
  int viewCalls = 0;
  final List<String> confirmed = <String>[];
  final List<String> rejected = <String>[];

  @override
  Future<KtvPendingApprovalView> getPendingApproval() async {
    viewCalls += 1;
    final error = viewError;
    if (error != null) throw error;
    return next;
  }

  @override
  Future<void> confirmPendingItem(String orderId, String itemId) async {
    final error = writeError;
    if (error != null) throw error;
    confirmed.add(orderId + '/' + itemId);
  }

  @override
  Future<void> rejectPendingItem(String orderId, String itemId) async {
    final error = writeError;
    if (error != null) throw error;
    rejected.add(orderId + '/' + itemId);
  }
}

KtvPendingApprovalView viewWith(
  List<Map<String, dynamic>> orders, {
  required int revision,
  int? pendingCount,
  String currencyCode = 'CNY',
  bool mixedCurrency = false,
}) {
  final items = orders
      .expand((order) => (order['items'] as List).cast<Map<String, dynamic>>())
      .toList();
  return KtvPendingApprovalView.fromJson(<String, dynamic>{
    'pendingCount': pendingCount ?? items.length,
    'pendingAmount':
        items.fold<int>(0, (sum, item) => sum + (item['amount'] as int)),
    'currencyCode': currencyCode,
    'mixedCurrency': mixedCurrency,
    'revision': revision,
    'orders': orders,
  });
}

Map<String, dynamic> order(int id, List<Map<String, dynamic>> items) =>
    <String, dynamic>{
      'orderId': id,
      'orderNo': 'O' + id.toString(),
      'roomName': '小包 S0' + id.toString(),
      'sessionStatus': 'OPEN',
      'pendingCount': items.length,
      'pendingAmount':
          items.fold<int>(0, (sum, i) => sum + (i['amount'] as int)),
      'items': items,
    };

Map<String, dynamic> item(int id, String name, int amount) => <String, dynamic>{
      'id': id,
      'name': name,
      'quantity': 1.0,
      'unitPrice': amount,
      'amount': amount,
      'currencyCode': 'CNY',
    };

void main() {
  late _FakeKtvApi api;
  late PendingApprovalController controller;

  setUp(() {
    api = _FakeKtvApi();
    controller = PendingApprovalController(api);
  });

  tearDown(() {
    controller.reset();
    controller.dispose();
  });

  test('refresh 拉取聚合视图并通知', () async {
    api.next = viewWith([
      order(69, [item(74, '可乐', 200), item(75, '可乐', 200)]),
    ], revision: 75);
    var notified = 0;
    controller.addListener(() => notified += 1);

    await controller.refresh();

    expect(controller.pendingCount, 2);
    expect(controller.hasPending, isTrue);
    expect(controller.countOfOrder('69'), 2);
    expect(controller.loading, isFalse);
    expect(controller.error, isNull);
    expect(notified, greaterThan(0));
    expect(api.viewCalls, 1);
  });

  test('revision 与条数都没变时不重复通知（防角标闪烁）', () async {
    api.next = viewWith([
      order(69, [item(74, '可乐', 200)])
    ], revision: 74);
    await controller.refresh();
    var notified = 0;
    controller.addListener(() => notified += 1);

    await controller.refresh(silent: true);
    await controller.refresh(silent: true);

    expect(notified, 0, reason: '同一快照不应触发重渲染');
    expect(api.viewCalls, 3);
  });

  test('快照变化时通知（新明细进来）', () async {
    api.next = viewWith([
      order(69, [item(74, '可乐', 200)])
    ], revision: 74);
    await controller.refresh();
    var notified = 0;
    controller.addListener(() => notified += 1);

    api.next = viewWith([
      order(69, [item(74, '可乐', 200), item(75, '啤酒', 1500)]),
    ], revision: 75);
    await controller.refresh(silent: true);

    expect(controller.pendingCount, 2);
    expect(notified, greaterThan(0));
  });

  test('拉取失败只记错误、不编造待确认数据', () async {
    api.viewError = const ApiFailure(message: 'boom', statusCode: 500);
    await controller.refresh();

    expect(controller.pendingCount, 0);
    expect(controller.error, isNotNull);
    expect(controller.hasPending, isFalse);
  });

  test('确认成功：乐观移除该条并立即收敛角标', () async {
    api.next = viewWith([
      order(69, [item(74, '可乐', 200), item(75, '啤酒', 1500)]),
    ], revision: 75);
    await controller.refresh();

    final result = await controller.confirm('69', '74');

    expect(result, PendingApprovalAction.success);
    expect(api.confirmed, ['69/74']);
    expect(controller.pendingCount, 1);
    expect(controller.countOfOrder('69'), 1);
  });

  test('并发输家（409）不当作失败：提示已被处理并按服务端刷新', () async {
    api.next = viewWith([
      order(69, [item(74, '可乐', 200)])
    ], revision: 74);
    await controller.refresh();
    api.writeError =
        const ApiFailure(message: '该加项已被处理，请刷新后查看', statusCode: 409);
    // 服务端此时已经没有这条（别人先确认了）。
    api.next = viewWith(const [], revision: 74, pendingCount: 0);

    final result = await controller.confirm('69', '74');

    expect(result, PendingApprovalAction.alreadyHandled);
    expect(controller.error, isNull, reason: '409 是并发收敛，不是故障');
    expect(controller.notice, isNotNull);
    await pumpEventQueue();
    expect(controller.pendingCount, 0, reason: '以服务端快照为准');
  });

  test('拒绝成功与确认同口径', () async {
    api.next = viewWith([
      order(66, [item(62, '啤酒', 1500)])
    ], revision: 62);
    await controller.refresh();

    final result = await controller.reject('66', '62');

    expect(result, PendingApprovalAction.success);
    expect(api.rejected, ['66/62']);
    expect(controller.pendingCount, 0);
  });

  test('其它错误如实暴露，供界面提示', () async {
    api.next = viewWith([
      order(69, [item(74, '可乐', 200)])
    ], revision: 74);
    await controller.refresh();
    api.writeError = const ApiFailure(message: '无权限', statusCode: 403);

    final result = await controller.confirm('69', '74');

    expect(result, PendingApprovalAction.failed);
    expect(controller.error, isNotNull);
    expect(controller.pendingCount, 1, reason: '失败不得乐观移除');
  });

  test('本单全部确认：串行提交并返回真正生效条数', () async {
    api.next = viewWith([
      order(69, [item(74, '可乐', 200), item(75, '啤酒', 1500)]),
    ], revision: 75);
    await controller.refresh();
    api.next = viewWith(const [], revision: 75, pendingCount: 0);

    final done = await controller.confirmOrder('69');

    expect(done, 2);
    expect(api.confirmed, ['69/74', '69/75']);
  });

  test('start/stop 是引用计数：多页共用一次轮询，全部释放才停', () async {
    api.next = viewWith([
      order(69, [item(74, '可乐', 200)])
    ], revision: 74);

    controller.start();
    expect(controller.isPolling, isTrue);
    controller.start();
    controller.stop();
    expect(controller.isPolling, isTrue, reason: '收银页 dispose 不能把看板刚启动的轮询一并关掉');
    controller.stop();
    expect(controller.isPolling, isFalse);
    await pumpEventQueue();
  });

  group('「订单数据已被改动」信号（orderDataRevision）', () {
    // 背景（Web 后台同形状的线上问题）：确认/拒绝改的不只是待确认清单，更是订单本身的
    // 金额与明细。若只刷新清单，看板房态卡片/收银应收/结台账单会停在旧值，
    // 于是「抽屉已确认、卡片还是确认前的钱」，与账单/其它端对不上。
    // 这里钉住信号的**产生条件**：只有服务端状态真的变了才 +1。

    test('确认成功：+1 且通知监听者', () async {
      api.next = viewWith([
        order(69, [item(74, '可乐', 200)])
      ], revision: 74);
      await controller.refresh();
      expect(controller.orderDataRevision, 0, reason: '只读拉快照不是改动');

      var notified = 0;
      controller.orderDataChanged.addListener(() => notified += 1);

      final result = await controller.confirm('69', '74');

      expect(result, PendingApprovalAction.success);
      expect(controller.orderDataRevision, 1);
      expect(notified, 1, reason: '订单页靠这个通知重拉自己的数据');
    });

    test('拒绝成功同样 +1（拒绝会回滚库存与金额）', () async {
      api.next = viewWith([
        order(66, [item(62, '啤酒', 1500)])
      ], revision: 62);
      await controller.refresh();

      final result = await controller.reject('66', '62');

      expect(result, PendingApprovalAction.success);
      expect(controller.orderDataRevision, 1);
    });

    test('409（已被别人处理）也 +1：服务端已变，本地订单快照必然过期', () async {
      api.next = viewWith([
        order(69, [item(74, '可乐', 200)])
      ], revision: 74);
      await controller.refresh();
      api.writeError =
          const ApiFailure(message: '该加项已被处理，请刷新后查看', statusCode: 409);

      final result = await controller.confirm('69', '74');

      expect(result, PendingApprovalAction.alreadyHandled);
      expect(controller.orderDataRevision, 1,
          reason: '并发输家同样要重拉：别人改了单，本页旧金额不能再摆着');
    });

    test('其它失败不 +1：服务端没变，不该让各页白跑一次接口', () async {
      api.next = viewWith([
        order(69, [item(74, '可乐', 200)])
      ], revision: 74);
      await controller.refresh();
      api.writeError = const ApiFailure(message: '无权限', statusCode: 403);

      final result = await controller.confirm('69', '74');

      expect(result, PendingApprovalAction.failed);
      expect(controller.orderDataRevision, 0);
    });

    test('只读刷新与轮询不 +1（否则每 15s 会把全工作台重拉一遍）', () async {
      api.next = viewWith([
        order(69, [item(74, '可乐', 200)])
      ], revision: 74);

      controller.start();
      await pumpEventQueue();
      await controller.refresh(silent: true);
      controller.setForeground(false);
      controller.setForeground(true);
      await pumpEventQueue();

      expect(controller.orderDataRevision, 0);
    });

    test('本单全部确认：按真正生效的条数累计', () async {
      api.next = viewWith([
        order(69, [item(74, '可乐', 200), item(75, '啤酒', 1500)]),
      ], revision: 75);
      await controller.refresh();
      api.next = viewWith(const [], revision: 75, pendingCount: 0);

      final done = await controller.confirmOrder('69');

      expect(done, 2);
      expect(controller.orderDataRevision, 2, reason: '两条明细各自改了一次服务端状态');
    });

    test('本单没有待确认项时不 +1（什么都没改）', () async {
      api.next = KtvPendingApprovalView.empty;
      await controller.refresh();

      final done = await controller.confirmOrder('69');

      expect(done, 0);
      expect(controller.orderDataRevision, 0);
    });

    test('生命周期归零：仍有页面持有时不动，全部释放/重置才归零', () async {
      api.next = viewWith([
        order(69, [item(74, '可乐', 200)])
      ], revision: 74);
      controller.start();
      await pumpEventQueue();
      await controller.confirm('69', '74');
      expect(controller.orderDataRevision, 1);

      controller.start();
      controller.stop();
      expect(controller.orderDataRevision, 1,
          reason: '切页瞬间（仍有页面持有）不能归零，否则栈上页面会与信号错位');
      controller.stop();
      expect(controller.orderDataRevision, 0, reason: '离开工作台后信号随轮询一起归零');

      controller.start();
      await pumpEventQueue();
      await controller.confirm('69', '74');
      expect(controller.orderDataRevision, 1);
      controller.reset();
      expect(controller.orderDataRevision, 0, reason: '退出登录不留上一位收银员的改动版本');
    });
  });

  test('回到前台立即补拉一次，后台不轮询', () async {
    api.next = viewWith([
      order(69, [item(74, '可乐', 200)])
    ], revision: 74);
    controller.start();
    await pumpEventQueue();
    final afterStart = api.viewCalls;

    controller.setForeground(false);
    await pumpEventQueue();
    expect(api.viewCalls, afterStart, reason: '后台不主动拉取');

    controller.setForeground(true);
    await pumpEventQueue();
    expect(api.viewCalls, greaterThan(afterStart), reason: '回前台立即补拉');
  });

  test('reset 清空角标与轮询（换收银员不留上一位的数字）', () async {
    api.next = viewWith([
      order(69, [item(74, '可乐', 200)])
    ], revision: 74);
    controller.start();
    await pumpEventQueue();
    expect(controller.pendingCount, 1);

    controller.reset();

    expect(controller.pendingCount, 0);
    expect(controller.isPolling, isFalse);
    expect(controller.notice, isNull);
  });
}
