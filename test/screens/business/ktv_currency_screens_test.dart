import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/currency.dart';
import 'package:open_chat_app/models/ktv_models.dart';
import 'package:open_chat_app/providers/currency_provider.dart';
import 'package:open_chat_app/repositories/business/ktv_api_client.dart';
import 'package:open_chat_app/screens/business/ktv_cashier_screen.dart';
import 'package:open_chat_app/screens/business/ktv_shift_screen.dart';
import 'package:provider/provider.dart';

/// 业务屏金额换算/展示必须跟随币种（规范 §3.4/§4/§7）。
///
/// 覆盖：班次页不再写死 ×100/÷100；收银页收款上行带币种；
/// 展示用服务端币种符号与名称。
void main() {
  tearDown(Currency.resetCurrentCode);

  testWidgets('开班 openingCash 跟随币种小数位：0 位小数币种不再 ×100',
      (tester) async {
    // JPY 在币种小数位表里是 0 位；旧实现写死 ×100 会得到 50000。
    final captured = <RequestOptions>[];
    final client = _client(
      captured: captured,
      route: (path) => switch (path) {
        '/business/shifts/open' => {
            'id': 'shift_001',
            'status': 'OPEN',
            'currency': 'JPY',
            'openingCash': '500',
            'expectedCash': '5000',
            'actualCash': '0',
            'differenceAmount': '0',
          },
        _ => <String, dynamic>{},
      },
    );

    await tester.pumpWidget(
      _harness(
        client: client,
        currency: CurrencyController(initialCode: 'JPY'),
        child: const KtvShiftScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '开班'));
    await tester.pumpAndSettle();

    expect(captured, hasLength(1));
    expect(captured.single.path, '/business/shifts/open');
    final data = _requestJson(captured.single);
    expect(data['openingCash'], '500');

    // 0 位小数币种展示不带小数（¥1,000 而非 ¥1,000.00）。
    expect(find.text('¥500'), findsOneWidget);
    expect(find.text('¥5,000'), findsOneWidget);
  });

  testWidgets('班次金额按服务端币种渲染：USD 显示 \$ 且带币种名称', (tester) async {
    final client = _client(
      captured: <RequestOptions>[],
      route: (path) => {
        'id': 'shift_001',
        'status': 'OPEN',
        'currency': 'USD',
        'openingCash': '50000',
        'expectedCash': '82400',
        'actualCash': '0',
        'differenceAmount': '0',
      },
    );

    await tester.pumpWidget(
      _harness(
        client: client,
        currency: CurrencyController(initialCode: 'USD'),
        child: const KtvShiftScreen(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, '开班'));
    await tester.pumpAndSettle();

    expect(find.text(r'$500.00'), findsOneWidget);
    expect(find.text(r'$824.00'), findsOneWidget);
    expect(find.text('当前班次 · 美元'), findsOneWidget);
    expect(find.textContaining('¥'), findsNothing);
  });

  testWidgets('币种状态变更后业务屏跟随（无需重建页面）', (tester) async {
    final currency = CurrencyController(initialCode: 'USD');
    final client = _client(
      captured: <RequestOptions>[],
      route: (path) => <String, dynamic>{},
    );

    await tester.pumpWidget(
      _harness(
        client: client,
        currency: currency,
        child: const KtvShiftScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('备用金（openingCash）· 美元'), findsOneWidget);

    currency.apply('CNY');
    await tester.pumpAndSettle();

    expect(currency.code, 'CNY');
    expect(find.text('备用金（openingCash）· 人民币'), findsOneWidget);
  });

  testWidgets('收银页：可用支付方式与收款上行都带本单币种', (tester) async {
    final captured = <RequestOptions>[];
    final client = _client(
      captured: captured,
      route: (path) => switch (path) {
        '/business/orders/ord_002' => {
            'id': 'ord_002',
            'orderNo': 'KT20260817-0001',
            'status': 'WAITING_SETTLEMENT',
            'roomName': 'A02',
            'totalAmount': '32400',
            'paidAmount': '0',
            'currency': 'USD',
          },
        '/business/orders/ord_002/bill' => {
            'orderId': 'ord_002',
            'orderNo': 'KT20260817-0001',
            'currency': 'USD',
            'subtotalAmount': '32400',
            'discountAmount': '0',
            'taxAmount': '0',
            'totalAmount': '32400',
            'paidAmount': '0',
            'changeAmount': '0',
          },
        '/business/payments/available-methods' => [
            {
              'method': 'CASH',
              'enabled': true,
              'displayName': '现金',
              'balance': '0',
              'currency': 'USD',
            },
          ],
        '/business/orders/ord_002/collect' => {
            'remainingAmount': '0',
            'currency': 'USD',
            'collectedByMethod': <dynamic>[],
            'changeAmount': '0',
          },
        _ => <String, dynamic>{},
      },
    );

    await tester.pumpWidget(
      _harness(
        client: client,
        currency: CurrencyController(initialCode: 'USD'),
        child: const KtvCashierScreen(
          args: KtvSessionArgs(orderId: 'ord_002'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 展示服务端币种符号与名称，而不是裸 ASCII 码。
    expect(find.textContaining(r'$324.00'), findsWidgets);
    expect(find.textContaining('· 美元'), findsOneWidget);

    final methodsCall = captured
        .firstWhere((r) => r.path == '/business/payments/available-methods');
    expect(methodsCall.queryParameters['currency'], 'USD');

    // 收款输入框按币种小数位预填（32400 -> 324.00），提交时换算回最小单位。
    expect(find.widgetWithText(TextField, '324.00'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '确认收款'));
    await tester.pumpAndSettle();

    final collect =
        captured.firstWhere((r) => r.path == '/business/orders/ord_002/collect');
    final body = _requestJson(collect);
    final payments = (body['payments'] as List).cast<Map<String, dynamic>>();
    expect(payments, isNotEmpty);
    expect(payments.first['currency'], 'USD');
    expect(payments.first['amount'], 32400);
  });

  test('收款拆分入参必须带币种（不再只发 amount）', () {
    Currency.setCurrentCode('CNY');
    expect(
      ktvPaymentEntry(method: 'CASH', amount: 100),
      {'method': 'CASH', 'amount': 100, 'currency': 'CNY'},
    );
    expect(
      ktvPaymentEntry(method: 'WALLET', amount: 100, currency: 'USD'),
      {'method': 'WALLET', 'amount': 100, 'currency': 'USD'},
    );
    expect(
      ktvPaymentEntry(method: 'POINT', amount: 1, currency: 'usd'),
      {'method': 'POINT', 'amount': 1, 'currency': 'USD'},
    );
  });

  test('KtvMoney.amountPlain 跟随币种小数位', () {
    expect(const KtvMoney(minorUnits: 32400, currency: 'CNY').amountPlain,
        '324.00');
    expect(const KtvMoney(minorUnits: 32400, currency: 'USD').amountPlain,
        '324.00');
    expect(const KtvMoney(minorUnits: 500, currency: 'JPY').amountPlain, '500');
  });

  test('KtvMoney 缺省币种回退当前租户币种', () {
    Currency.setCurrentCode('USD');
    expect(const KtvMoney(minorUnits: 10000).formatted, r'$100.00');
    expect(KtvMoney.parse('10000', null).formatted, r'$100.00');
    Currency.setCurrentCode('CNY');
    expect(KtvMoney.parse('10000', null).formatted, '¥100.00');
  });
}

Widget _harness({
  required KtvApiClient client,
  required CurrencyController currency,
  required Widget child,
}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        Provider<KtvApiClient>.value(value: client),
        ChangeNotifierProvider<CurrencyController>.value(value: currency),
      ],
      child: child,
    ),
  );
}

/// dio 可能在到达 adapter 前把请求体序列化成 JSON 字符串，两种形态都兼容。
Map<String, dynamic> _requestJson(RequestOptions options) {
  final data = options.data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) {
    return Map<String, dynamic>.from(jsonDecode(data) as Map);
  }
  throw StateError('unexpected request body type: ${data.runtimeType}');
}

KtvApiClient _client({
  required List<RequestOptions> captured,
  required Object? Function(String path) route,
}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.httpClientAdapter = _FakeAdapter((options) {
    captured.add(options);
    return ResponseBody.fromString(
      jsonEncode(route(options.path)),
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
