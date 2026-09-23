import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/currency.dart';
import 'package:open_chat_app/models/ktv_models.dart';
import 'package:open_chat_app/providers/currency_provider.dart';
import 'package:open_chat_app/providers/pending_approval_provider.dart';
import 'package:open_chat_app/repositories/business/ktv_api_client.dart';
import 'package:open_chat_app/screens/business/ktv_timing_screen.dart';
import 'package:provider/provider.dart';

/// 「确认/拒绝之后，订单数据必须重拉」的守卫（A380 收银端）。
///
/// 背景（Web 后台同形状的线上问题）：确认/拒绝改的不只是待确认清单，更是订单本身的
/// 金额与明细。只刷新清单的话，看板房态卡片 / 收银应收 / 结台账单会停在旧值——
/// 「抽屉已确认、卡片还是确认前的钱」，与账单/其它端对不上。
///
/// 覆盖两部分：
/// 1. 行为：计时加项页真的在信号到来后重拉本单订单（金额卡片换成服务端新值）；
/// 2. 源码守卫：四个订单页都接上了信号，且金额只用服务端可直接展示总额，
///    不在总额上叠加包厢费估算（Web 后台就是这么双计包厢费的）。
void main() {
  tearDown(Currency.resetCurrentCode);

  String read(String path) {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: '缺少文件：$path');
    return file.readAsStringSync();
  }

  group('行为：信号 -> 本页重拉自己的订单数据', () {
    testWidgets('计时加项页监听信号后重拉本单订单，金额卡片换成服务端新值',
        (tester) async {
      final captured = <RequestOptions>[];
      // 第一次读订单返回 6150（旧值），重拉后返回 10150（服务端已经算进包厢费）。
      final client = _client(
        captured: captured,
        orderTotals: <String>['6150', '10150'],
      );
      final pending = PendingApprovalController(_FakePendingApi());
      addTearDown(() {
        pending.stop();
        pending.dispose();
      });

      await tester.pumpWidget(_timingHarness(client: client, pending: pending));
      await tester.pumpAndSettle();

      expect(_orderCalls(captured), 1);
      expect(find.text('¥61.50'), findsOneWidget, reason: '首屏显示服务端当时的总额');

      // 一条客户自助加项被确认（本机或另一台设备）：控制器抬「订单数据已被改动」版本号。
      final result = await pending.confirm('ord_002', 'itm_1');
      expect(result, PendingApprovalAction.success);
      expect(pending.orderDataRevision, 1);

      // 去抖窗口（合并「本单全部确认」连抬多次）后重拉。
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(_orderCalls(captured), 2, reason: '订单数据变了就必须重拉，不能停在旧值');
      expect(find.text('¥101.50'), findsOneWidget,
          reason: '金额卡片必须换成服务端最新总额');
      expect(find.text('¥61.50'), findsNothing);
    });

    testWidgets('只读刷新（没有改动）不触发重拉：不做订单详情的轮询', (tester) async {
      final captured = <RequestOptions>[];
      final client = _client(captured: captured, orderTotals: <String>['6150']);
      final pending = PendingApprovalController(_FakePendingApi());
      addTearDown(() {
        pending.stop();
        pending.dispose();
      });

      await tester.pumpWidget(_timingHarness(client: client, pending: pending));
      await tester.pumpAndSettle();
      expect(_orderCalls(captured), 1);

      await pending.refresh(silent: true);
      await pending.refresh(silent: true);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(_orderCalls(captured), 1, reason: '拉快照不是改数据，不得把重拉当成轮询');
    });
  });

  group('源码守卫：信号产生侧', () {
    test('控制器暴露版本号，且只在成功/409 时 +1（失败与只读刷新不 +1）', () {
      final source = read('lib/providers/pending_approval_provider.dart');

      expect(source.contains('orderDataRevision'), isTrue);
      expect(source.contains('orderDataChanged'), isTrue);
      expect(
        RegExp(r'_orderDataRevision\.value \+= 1').allMatches(source).length,
        2,
        reason: '只允许两处抬版本号：操作成功 + 409（已被别人处理）；'
            '失败与只读 refresh 都不得抬，否则各页会白重拉或把轮询变成重拉风暴',
      );

      final refreshBody = source.substring(
        source.indexOf('Future<void> refresh('),
        source.indexOf('Future<PendingApprovalAction> confirm('),
      );
      expect(refreshBody.contains('_orderDataRevision'), isFalse,
          reason: '只读拉取（含 15s 轮询）不是改动，不得抬版本号');
      final actBody =
          source.substring(source.indexOf('Future<PendingApprovalAction> _act('));
      final failureBranch = actBody.substring(
        actBody.indexOf('_error = KtvApiClient.describeError(e);'),
      );
      expect(failureBranch.contains('_orderDataRevision.value += 1'), isFalse,
          reason: '失败分支不得抬版本号：服务端没变，各页不该白重拉');
    });

    test('生命周期与轮询一致：stop 归零、reset 归零', () {
      final source = read('lib/providers/pending_approval_provider.dart');
      final stopBody = source.substring(
        source.indexOf('void stop()'),
        source.indexOf('void setForeground('),
      );
      expect(stopBody.contains('_orderDataRevision.value = 0'), isTrue,
          reason: '离开工作台（引用计数归零）时信号随轮询一起归零');
      final resetBody = source.substring(
        source.indexOf('void reset()'),
        source.indexOf('void clearNotice()'),
      );
      expect(resetBody.contains('stop()'), isTrue,
          reason: 'reset 走 stop 归零，退出登录不留上一位收银员的改动版本');
    });
  });

  group('源码守卫：四个订单页都监听信号并重拉本页既有数据', () {
    test('看板 / 收银 / 计时 / 结台都 bind，且重拉走本页既有加载方法', () {
      final expected = <String, List<String>>{
        'lib/screens/business/ktv_dashboard_screen.dart': ['_load(silent: true)'],
        'lib/screens/business/ktv_cashier_screen.dart': [
          '_loadList(silent: true)',
          '_loadDetail(orderId, silent: true)',
        ],
        'lib/screens/business/ktv_timing_screen.dart': ['_load(silent: true)'],
        'lib/screens/business/ktv_settle_screen.dart': ['_load(silent: true)'],
      };
      for (final entry in expected.entries) {
        final source = read(entry.key);
        expect(source.contains('bindOrderDataRevision()'), isTrue,
            reason: '${entry.key} 没监听「订单数据已被改动」信号');
        expect(source.contains('unbindOrderDataRevision()'), isTrue,
            reason: '${entry.key} 没在 dispose 解绑（会留下定时器/回调）');
        expect(source.contains('void reloadOrderData()'), isTrue,
            reason: '${entry.key} 没实现重拉');
        for (final call in entry.value) {
          expect(source.contains(call), isTrue,
              reason: '${entry.key} 的重拉没有走本页既有加载方法：$call');
        }
      }
    });

    test('重拉是「消费全局信号」，不是各页自己轮询订单详情', () {
      for (final path in const [
        'lib/screens/business/ktv_dashboard_screen.dart',
        'lib/screens/business/ktv_cashier_screen.dart',
        'lib/screens/business/ktv_settle_screen.dart',
      ]) {
        final source = read(path);
        expect(source.contains('Timer.periodic'), isFalse,
            reason: '$path 不得为了刷新订单自己起轮询（数据源仍是各页既有接口）');
      }
    });

    test('集中处理页不另起数据路径：它的清单本来就由控制器刷新', () {
      final source =
          read('lib/screens/business/ktv_pending_approval_screen.dart');
      expect(source.contains('controller.refresh()'), isTrue);
      expect(source.contains('OrderDataRevisionReload'), isFalse,
          reason: '处理页展示的就是控制器快照，再挂一次重拉等于重复请求');
    });
  });

  group('源码守卫：金额只用服务端可直接展示总额，绝不叠加包厢费估算', () {
    test('订单卡片展示 liveTotalAmount，不再展示落库 totalAmount', () {
      final timing = read('lib/screens/business/ktv_timing_screen.dart');
      expect(timing.contains('order.liveTotalAmount.formatted'), isTrue);
      expect(timing.contains('order.totalAmount'), isFalse,
          reason: '计时页订单卡片必须用服务端实时总额');

      final cashier = read('lib/screens/business/ktv_cashier_screen.dart');
      // 收银列表卡片上的 bill 实际是 KtvOrder：必须用服务端实时总额。
      final listBody = cashier.substring(
        cashier.indexOf('Widget _buildList('),
        cashier.indexOf('Widget _buildDetail('),
      );
      expect(listBody.contains('liveTotalAmount.formatted'), isTrue,
          reason: '收银列表的订单卡片必须用服务端实时总额');
      expect(listBody.contains('totalAmount.formatted'), isFalse,
          reason: '收银列表不得再展示落库总额（结台前的实时包厢费会漏算）');
    });

    test('任何业务屏都不得把包厢费（或估算）加到总额上', () {
      final violations = <String>[];
      // 「总额 + 包厢费/估算」的几种写法：Web 后台就是这么双计包厢费的
      // （账单 6150 / 卡片 10150）。注释里说明这条规矩是允许的，故跳过注释行。
      final patterns = <RegExp>[
        RegExp(r'(totalAmount|liveTotalAmount)[^;]*\+'),
        RegExp(r'\+\s*[A-Za-z_.()\[\]]*roomFee'),
        RegExp(r'roomFee[^;]*\+\s*[A-Za-z_]'),
        RegExp(r'估算|预估'),
      ];
      for (final file in Directory('lib/screens/business')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          for (final pattern in patterns) {
            if (pattern.hasMatch(line)) {
              violations.add('${file.path}:${i + 1}: ${line.trim()}');
            }
          }
        }
      }
      expect(violations, isEmpty,
          reason: '业务屏在总额上叠加包厢费/估算（会像 Web 后台一样双计包厢费）：\n'
              '${violations.join('\n')}');
    });

    test('模型兼容两种键名并回退 totalAmount', () {
      final model = read('lib/models/ktv_models.dart');
      expect(model.contains("json['liveTotalAmount']"), isTrue);
      expect(model.contains("json['live_total_amount']"), isTrue);
      expect(model.contains('liveTotalAmount = liveTotalAmount ?? totalAmount'),
          isTrue, reason: '直接构造（dev mock）时也要有可展示总额');
    });
  });
}

int _orderCalls(List<RequestOptions> captured) =>
    captured.where((r) => r.path == '/business/orders/ord_002').length;

Widget _timingHarness({
  required KtvApiClient client,
  required PendingApprovalController pending,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        Provider<KtvApiClient>.value(value: client),
        ChangeNotifierProvider<CurrencyController>.value(
          value: CurrencyController(initialCode: 'CNY'),
        ),
        ChangeNotifierProvider<PendingApprovalController>.value(value: pending),
      ],
      child: const KtvTimingScreen(
        args: KtvSessionArgs(orderId: 'ord_002', sessionId: 'ses_002'),
      ),
    ),
  );
}

/// 待确认控制器的假客户端：确认成功 + 空快照（本用例只关心信号）。
class _FakePendingApi extends KtvApiClient {
  @override
  Future<KtvPendingApprovalView> getPendingApproval() async =>
      KtvPendingApprovalView.empty;

  @override
  Future<void> confirmPendingItem(String orderId, String itemId) async {}
}

/// 订单接口按调用次序返回不同的 liveTotalAmount，用来证明金额卡片真的换了值。
KtvApiClient _client({
  required List<RequestOptions> captured,
  required List<String> orderTotals,
}) {
  var orderCalls = 0;
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.httpClientAdapter = _FakeAdapter((options) {
    captured.add(options);
    Object? body;
    if (options.path == '/business/orders/ord_002') {
      final index = orderCalls < orderTotals.length
          ? orderCalls
          : orderTotals.length - 1;
      orderCalls += 1;
      body = <String, dynamic>{
        'id': 'ord_002',
        'orderNo': 'KT20260817-0001',
        'status': 'SERVING',
        'roomName': 'A02',
        'sessionId': 'ses_002',
        'sessionStatus': 'OPEN',
        'totalAmount': '6150',
        'liveTotalAmount': orderTotals[index],
        'paidAmount': '0',
        'currency': 'CNY',
      };
    } else if (options.path == '/business/catalog/items') {
      body = <dynamic>[];
    } else {
      body = <String, dynamic>{};
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  });
  return KtvApiClient(dio: dio);
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._respond);

  final ResponseBody Function(RequestOptions options) _respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      _respond(options);

  @override
  void close({bool force = false}) {}
}
