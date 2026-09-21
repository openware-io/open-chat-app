import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/currency.dart';
import 'package:gv_chat_app/models/ktv_models.dart';
import 'package:gv_chat_app/providers/currency_provider.dart';
import 'package:gv_chat_app/repositories/business/ktv_api_client.dart';
import 'package:gv_chat_app/screens/business/ktv_cashier_screen.dart';
import 'package:provider/provider.dart';

/// 规范 16 §9：KTV 组合收款页的储值币 / 积分是**数量腿**。
///
/// 覆盖：
/// - 输入的是整数个数；提交时报文里的 `amount` 是**折算后**的最小货币单位金额
///   （储值币 `tokensToMinor`，积分 1:1）；
/// - 数量超过可用（储值币比余额、积分比可用积分）时**拒绝提交**；
/// - 数量口径的输入/展示分支逐行不得出现货币符号、币种码与小数位（源码守卫）。
void main() {
  tearDown(Currency.resetCurrentCode);

  /// 数量口径的输出/文案**绝不**允许出现货币痕迹。
  final currencyTrace = RegExp(r'[¥￥$€]|CNY|USD|RMB|元');

  group('数量腿输入与折算提交', () {
    testWidgets('储值币 1000 个 -> 1000 分（缺省比例 100）；积分 300 个 -> 300 分（1:1）',
        (tester) async {
      final captured = <RequestOptions>[];
      final client = _client(captured: captured);

      await tester.pumpWidget(_harness(client: client));
      await tester.pumpAndSettle();

      // 输入框顺序：0 = 现金（金额）、1 = 储值币、2 = 积分。
      await tester.enterText(find.byType(TextField).at(1), '1000');
      await tester.enterText(find.byType(TextField).at(2), '300');
      await tester.tap(find.widgetWithText(FilledButton, '确认收款'));
      await tester.pumpAndSettle();

      final collect = captured.firstWhere((r) => r.path == _collectPath);
      final payments = (_requestJson(collect)['payments'] as List)
          .cast<Map<String, dynamic>>();
      expect(payments, hasLength(3));
      expect(
        payments[0],
        {'method': 'CASH', 'amount': 32400, 'currency': 'USD'},
      );
      // 1000 个 ÷ 100 × 100 = 1000 最小单位（wire 契约仍是最小货币单位整数）。
      expect(
        payments[1],
        {'method': 'WALLET', 'amount': 1000, 'currency': 'USD'},
      );
      // 积分是个数，1:1，不乘任何比例。
      expect(
        payments[2],
        {'method': 'POINT', 'amount': 300, 'currency': 'USD'},
      );
    });

    testWidgets('储值币数量超过可用余额时拒绝提交', (tester) async {
      final captured = <RequestOptions>[];
      final client = _client(captured: captured);

      await tester.pumpWidget(_harness(client: client));
      await tester.pumpAndSettle();

      // 可用 100,000 个（余额 100000 最小单位 × 缺省比例 100）。
      await tester.enterText(find.byType(TextField).at(1), '100001');
      await tester.tap(find.widgetWithText(FilledButton, '确认收款'));
      await tester.pumpAndSettle();

      expect(captured.where((r) => r.path == _collectPath), isEmpty);
      expect(find.textContaining('储值币数量超过可用'), findsOneWidget);
      expect(find.textContaining('100,000'), findsWidgets);
    });

    testWidgets('积分数量超过可用积分时拒绝提交', (tester) async {
      final captured = <RequestOptions>[];
      final client = _client(captured: captured);

      await tester.pumpWidget(_harness(client: client));
      await tester.pumpAndSettle();

      // 可用 5,000 积分。
      await tester.enterText(find.byType(TextField).at(2), '5001');
      await tester.tap(find.widgetWithText(FilledButton, '确认收款'));
      await tester.pumpAndSettle();

      expect(captured.where((r) => r.path == _collectPath), isEmpty);
      expect(find.textContaining('积分数量超过可用'), findsOneWidget);
    });

    testWidgets('数量腿输入框是整数键盘、带单位后缀，金额小数位只属于现金', (tester) async {
      final client = _client(captured: <RequestOptions>[]);

      await tester.pumpWidget(_harness(client: client));
      await tester.pumpAndSettle();

      final fields =
          tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields, hasLength(3));
      expect(
        fields[0].keyboardType,
        const TextInputType.numberWithOptions(decimal: true),
      );
      expect(fields[1].keyboardType, TextInputType.number);
      expect(fields[2].keyboardType, TextInputType.number);

      // 数量腿不挂任何单位后缀（既没有「个」，也没有品牌名 / 「积分」）
      expect(fields[1].decoration!.suffixText, isNull);
      expect(fields[2].decoration!.suffixText, isNull);
      expect(fields[1].decoration!.labelText, 'A380币（可用 100,000）');
      expect(fields[2].decoration!.labelText, '积分（可用 5,000）');

      for (final field in fields.sublist(1)) {
        final label = field.decoration!.labelText ?? '';
        final suffix = field.decoration!.suffixText ?? '';
        expect(currencyTrace.hasMatch(label), isFalse, reason: label);
        expect(currencyTrace.hasMatch(suffix), isFalse, reason: suffix);
        expect(RegExp(r'个').hasMatch(suffix), isFalse, reason: suffix);
      }

      // 旧实现把可用余额渲染成金额（$1,000.00 / $50.00）：数量口径下必须消失。
      expect(find.textContaining(r'$1,000.00'), findsNothing);
      expect(find.textContaining(r'$50.00'), findsNothing);
    });
  });

  group('源码守卫：数量腿分支不得出现货币符号/币种码', () {
    const path = 'lib/screens/business/ktv_cashier_screen.dart';

    /// 每个触及数量腿（储值币 / 积分 / 数量换算入口）的行。
    final tokenBranchLine = RegExp(r'WALLET|POINT|储值币|积分|[Tt]oken');

    /// 源码里的货币符号**字面量**：Dart 的 `$` 同时是字符串插值前缀
    /// （`$name` / `${expr}`），插值不是货币符号，守卫只剔除插值形态，
    /// 真正的 `$` 字面量（如 `'\$100'`）仍然会被命中。
    final moneyLiteral = RegExp(r'[¥￥€]|\$(?![A-Za-z_{])|CNY|USD|RMB|元');

    test('逐行断言：数量腿相关行不含货币符号、币种码与主单位名', () {
      final file = File(path);
      expect(file.existsSync(), isTrue,
          reason: '未找到 $path（测试需在包根目录运行）');

      final violations = <String>[];
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (!tokenBranchLine.hasMatch(line)) continue;
        final hit = moneyLiteral.firstMatch(line);
        if (hit != null) {
          violations.add('$path:${i + 1}: ${hit.group(0)} -> ${line.trim()}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason: '数量腿分支出现货币符号/币种码，请改走 lib/core/currency.dart 的数量口径：\n'
            '${violations.join('\n')}',
      );
    });

    test('现金仍走金额解析，数量腿不得复用金额解析/格式化', () {
      final source = File(path).readAsStringSync();

      final moneyParseLines = source
          .split('\n')
          .where((line) => line.contains('parseMoneyInput'))
          .where((line) => !line.trimLeft().startsWith('//'))
          .map((line) => line.trim())
          .toList();
      expect(moneyParseLines, hasLength(1));
      expect(moneyParseLines.single, contains('_cash'));

      // 小数位只允许出现在现金金额输入框。
      expect(RegExp('decimal: true').allMatches(source), hasLength(1));

      final tokenField = source.substring(
        source.indexOf('Widget _tokenCountField'),
        source.indexOf('Widget _buildError'),
      );
      expect(tokenField, contains('TextInputType.number'));
      expect(tokenField, isNot(contains('decimal: true')));
      expect(tokenField, isNot(contains('parseMoneyInput')));
      expect(tokenField, isNot(contains('formatMoney')));
      expect(tokenField, isNot(contains('.formatted')));

      // label/展示分支只出数量。
      final labelHelpers = source.substring(
        source.indexOf('String _walletFieldLabel'),
        source.indexOf('Widget _amountField'),
      );
      expect(labelHelpers, contains('formatTokenCount'));
      expect(labelHelpers, isNot(contains('formatMoney')));
      expect(labelHelpers, isNot(contains('.formatted')));
      expect(labelHelpers, isNot(contains('balance')));
    });
  });
}

const String _collectPath = '/business/orders/ord_002/collect';

Widget _harness({required KtvApiClient client}) {
  return MaterialApp(
    home: MultiProvider(
      providers: [
        Provider<KtvApiClient>.value(value: client),
        ChangeNotifierProvider<CurrencyController>.value(
          value: CurrencyController(initialCode: 'USD'),
        ),
      ],
      child: const KtvCashierScreen(args: KtvSessionArgs(orderId: 'ord_002')),
    ),
  );
}

/// 可用支付方式：现金 + 储值币（100,000 个）+ 积分（5,000 个）。
Object? _route(String path) => switch (path) {
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
          {
            'method': 'WALLET',
            'enabled': true,
            'displayName': 'A380币',
            'balance': '100000',
            'currency': 'USD',
          },
          {
            'method': 'POINT',
            'enabled': true,
            'displayName': '积分',
            'balance': '5000',
            'currency': 'USD',
          },
        ],
      _collectPath => {
          'remainingAmount': '0',
          'currency': 'USD',
          'collectedByMethod': <dynamic>[],
          'changeAmount': '0',
        },
      _ => <String, dynamic>{},
    };

/// dio 可能在到达 adapter 前把请求体序列化成 JSON 字符串，两种形态都兼容。
Map<String, dynamic> _requestJson(RequestOptions options) {
  final data = options.data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is String) {
    return Map<String, dynamic>.from(jsonDecode(data) as Map);
  }
  throw StateError('unexpected request body type: ${data.runtimeType}');
}

KtvApiClient _client({required List<RequestOptions> captured}) {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'));
  dio.httpClientAdapter = _FakeAdapter((options) {
    captured.add(options);
    return ResponseBody.fromString(
      jsonEncode(_route(options.path)),
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
