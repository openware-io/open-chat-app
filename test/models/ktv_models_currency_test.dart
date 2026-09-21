import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/currency.dart';
import 'package:gv_chat_app/models/ktv_models.dart';

/// 记录级币种解析：既有 `currency` 与规范 16 §2 的 `currencyCode` 都要支持，
/// 都缺失时回退当前租户币种（缺省 USD）。
void main() {
  tearDown(Currency.resetCurrentCode);

  test('KtvMoney.parse 支持 currency / currencyCode / 缺失回退', () {
    expect(KtvMoney.parse('10000', 'CNY').formatted, '¥100.00');
    Currency.setCurrentCode('CNY');
    // 记录缺币种 -> 用当前租户币种（规范 §3.6）
    expect(KtvMoney.parse('10000', null).formatted, '¥100.00');
    expect(KtvMoney.parse('10000', '').formatted, '¥100.00');
    expect(Currency.currentCode, 'CNY');
  });

  test('KtvBill.fromJson 接受 currencyCode 字段名', () {
    final bill = KtvBill.fromJson(<String, dynamic>{
      'orderId': 'ord_1',
      'orderNo': 'KT1',
      'currencyCode': 'USD',
      'totalAmount': '32400',
      'paidAmount': '0',
      'changeAmount': '0',
      'subtotalAmount': '32400',
      'discountAmount': '0',
      'taxAmount': '0',
      'roomFee': {
        'name': '包厢计时费',
        'unitPrice': '12800',
        'quantity': 2,
        'amount': '25600',
      },
      'items': [
        {'name': '果盘', 'unitPrice': '8800', 'quantity': 1, 'amount': '8800'},
      ],
      'promotions': [
        {'type': 'DISCOUNT', 'name': '满减', 'amount': '-2000'},
      ],
    });

    expect(bill.currency, 'USD');
    expect(bill.currencyLabel, '美元');
    expect(bill.totalAmount.formatted, r'$324.00');
    expect(bill.roomFee.amount.formatted, r'$256.00');
    expect(bill.items.single.amount.formatted, r'$88.00');
    expect(bill.promotions.single.amount.formatted, r'-$20.00');
    expect(bill.totalAmount.amountPlain, '324.00');
  });

  test('KtvBill.fromJson 缺币种时回退当前租户币种', () {
    Currency.setCurrentCode('USD');
    final bill = KtvBill.fromJson(<String, dynamic>{
      'orderId': 'ord_1',
      'totalAmount': '10000',
      'changeAmount': '0',
    });
    expect(bill.currency, '');
    expect(bill.totalAmount.formatted, r'$100.00');
    expect(bill.currencyLabel, '美元');
  });

  test('KtvOrder / KtvShift / KtvCollectResult 均支持 currencyCode', () {
    final order = KtvOrder.fromJson(<String, dynamic>{
      'id': 'ord_1',
      'orderNo': 'KT1',
      'status': 'WAITING_SETTLEMENT',
      'currencyCode': 'USD',
      'totalAmount': '51200',
      'paidAmount': '0',
      'allowedActions': <String>[],
    });
    expect(order.currency, 'USD');
    expect(order.currencyLabel, '美元');
    expect(order.totalAmount.formatted, r'$512.00');

    final shift = KtvShift.fromJson(<String, dynamic>{
      'id': 'shift_1',
      'status': 'OPEN',
      'currencyCode': 'CNY',
      'openingCash': '50000',
      'expectedCash': '82400',
      'actualCash': '0',
      'differenceAmount': '0',
    });
    expect(shift.currency, 'CNY');
    expect(shift.currencyLabel, '人民币');
    expect(shift.expectedCash.amountPlain, '824.00');

    final result = KtvCollectResult.fromJson(<String, dynamic>{
      'currencyCode': 'USD',
      'remainingAmount': '0',
      'changeAmount': '2500',
      'collectedByMethod': [
        {'method': 'CASH', 'amount': '32400'},
      ],
    });
    expect(result.currency, 'USD');
    expect(result.changeAmount.formatted, r'$25.00');
    expect(result.collectedByMethod.single.amount.formatted, r'$324.00');
  });
}
