import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/currency.dart';

/// 规范 16 §4/§7：`formatMoney` 单测必须覆盖
/// CNY/USD、0、负数、大额千分位、未知币种回退。
void main() {
  setUp(() => Currency.resetCurrentCode());
  tearDown(() => Currency.resetCurrentCode());

  group('formatMoney 唯一格式化入口', () {
    test('CNY：符号紧跟数字、两位小数', () {
      expect(formatMoney(10000, 'CNY'), '¥100.00');
      expect(formatMoney(32400, 'CNY'), '¥324.00');
      expect(formatMoney(1, 'CNY'), '¥0.01');
    });

    test('USD：默认租户币种，符号为 \$', () {
      expect(formatMoney(10000, 'USD'), r'$100.00');
      expect(formatMoney(1, 'USD'), r'$0.01');
      expect(formatMoney(999, 'USD'), r'$9.99');
    });

    test('符号与数字之间没有空格', () {
      expect(formatMoney(10000, 'USD').contains(' '), isFalse);
      expect(formatMoney(10000, 'CNY').contains(' '), isFalse);
    });

    test('0 值', () {
      expect(formatMoney(0, 'CNY'), '¥0.00');
      expect(formatMoney(0, 'USD'), r'$0.00');
    });

    test('负数（-号在最前，符号仍在数字前）', () {
      expect(formatMoney(-2000, 'CNY'), '-¥20.00');
      expect(formatMoney(-1, 'USD'), r'-$0.01');
      expect(formatMoney(-100000, 'USD'), r'-$1,000.00');
    });

    test('大额千分位', () {
      expect(formatMoney(123456789, 'USD'), r'$1,234,567.89');
      expect(formatMoney(1000000, 'CNY'), '¥10,000.00');
      expect(formatMoney(100000, 'CNY'), '¥1,000.00');
      expect(formatMoney(10000, 'CNY'), '¥100.00');
      expect(formatMoney(-123456789, 'CNY'), '-¥1,234,567.89');
    });

    test('小数位跟随币种表（JPY 0 位，不输出小数）', () {
      expect(formatMoney(500, 'JPY'), '¥500');
      expect(formatMoney(1500, 'JPY'), '¥1,500');
      expect(formatMoney(-500, 'JPY'), '-¥500');
    });

    test('未知币种回退当前币种并记 debug 日志', () {
      final logs = <String>[];
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };
      addTearDown(() => debugPrint = original);

      Currency.setCurrentCode('CNY');
      expect(formatMoney(100, 'ZZZ'), '¥1.00');
      expect(logs.join('\n'), contains('ZZZ'));

      Currency.setCurrentCode('USD');
      expect(formatMoney(100, 'ZZZ'), r'$1.00');
    });

    test('缺省币种（空串/null）回退当前租户币种', () {
      Currency.setCurrentCode('CNY');
      expect(formatMoney(100), '¥1.00');
      expect(formatMoney(100, ''), '¥1.00');
      expect(formatMoney(100, '  '), '¥1.00');
    });

    test('默认当前币种为 USD', () {
      expect(Currency.currentCode, 'USD');
      expect(formatMoney(10000), r'$100.00');
    });
  });

  group('Currency 注册表', () {
    test('符号/小数位/名称集中一处', () {
      expect(Currency.symbolOf('CNY'), '¥');
      expect(Currency.symbolOf('USD'), r'$');
      expect(Currency.decimalsOf('CNY'), 2);
      expect(Currency.decimalsOf('USD'), 2);
      expect(Currency.decimalsOf('JPY'), 0);
      expect(Currency.labelOf('CNY'), '人民币');
      expect(Currency.labelOf('USD'), '美元');
    });

    test('归一化：小写/空白可用', () {
      expect(Currency.normalize(' usd '), 'USD');
      expect(formatMoney(100, 'usd'), r'$1.00');
    });

    test('未知/空当前币种回退 USD', () {
      Currency.setCurrentCode('XYZ');
      expect(Currency.currentCode, 'USD');
      Currency.setCurrentCode('');
      expect(Currency.currentCode, 'USD');
      Currency.setCurrentCode(null);
      expect(Currency.currentCode, 'USD');
      Currency.setCurrentCode('CNY');
      expect(Currency.currentCode, 'CNY');
    });

    test('租户级支持币种只有 CNY/USD', () {
      expect(Currency.supportedCodes, ['CNY', 'USD']);
      expect(Currency.isSupported('USD'), isTrue);
      expect(Currency.isSupported('cny'), isTrue);
      expect(Currency.isSupported('JPY'), isFalse);
    });

    test('resolveCurrencyCode：空值走当前币种，未知值记日志', () {
      Currency.setCurrentCode('USD');
      expect(resolveCurrencyCode(null), 'USD');
      expect(resolveCurrencyCode(''), 'USD');
      expect(resolveCurrencyCode('CNY'), 'CNY');
      final original = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {};
      addTearDown(() => debugPrint = original);
      expect(resolveCurrencyCode('QQQ'), 'USD');
    });
  });

  group('formatAmountPlain / parseMoneyInput（同一份小数位表）', () {
    test('formatAmountPlain 不带符号，小数位跟随币种', () {
      expect(formatAmountPlain(32400, 'CNY'), '324.00');
      expect(formatAmountPlain(32400, 'USD'), '324.00');
      expect(formatAmountPlain(500, 'JPY'), '500');
      expect(formatAmountPlain(-2000, 'CNY'), '-20.00');
      expect(formatAmountPlain(0, 'USD'), '0.00');
    });

    test('parseMoneyInput 不再写死 ×100（JPY 0 位直接取主单位）', () {
      expect(parseMoneyInput('500', 'JPY'), 500);
      expect(parseMoneyInput('500.00', 'JPY'), 500);
      expect(parseMoneyInput('500.00', 'CNY'), 50000);
      expect(parseMoneyInput('500.00', 'USD'), 50000);
      expect(parseMoneyInput('324.56', 'CNY'), 32456);
      expect(parseMoneyInput('1,234.56', 'USD'), 123456);
      expect(parseMoneyInput('.5', 'CNY'), 50);
      expect(parseMoneyInput('.5', 'JPY'), 0);
    });

    test('parseMoneyInput 边界：空串/非法字符/负数', () {
      expect(parseMoneyInput('', 'CNY'), 0);
      expect(parseMoneyInput('   ', 'CNY'), 0);
      expect(parseMoneyInput('-', 'CNY'), 0);
      expect(parseMoneyInput('abc', 'CNY'), 0);
      expect(parseMoneyInput('-20.00', 'CNY'), -2000);
      expect(parseMoneyInput('+20.00', 'USD'), 2000);
    });

    test('主单位往返一致', () {
      for (final code in const ['CNY', 'USD']) {
        for (final minor in const [0, 1, 50, 999, 10000, 32456, 123456789]) {
          expect(
            parseMoneyInput(formatAmountPlain(minor, code), code),
            minor,
            reason: '$code $minor',
          );
        }
      }
      expect(parseMoneyInput(formatAmountPlain(500, 'JPY'), 'JPY'), 500);
    });
  });
}
