import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/currency.dart';

/// 规范 16 §9：储值币（代币）与积分是**数量**口径，与币种完全解耦。
///
/// 覆盖：代币个数 -> 最小货币单位的折算（缺省 ratio 100；ratio 50/3 等非缺省值
/// 与 `round(个数 ÷ ratio × 100)` 逐项一致）、反向降级换算、数量输入解析、
/// 以及数量展示绝不出现货币符号/币种码/小数。
void main() {
  /// 数量口径的输出**绝不**允许出现货币痕迹。
  final currencyTrace = RegExp(r'[¥￥$€]|CNY|USD|RMB|元');

  group('tokensToMinor：代币个数 -> 最小货币单位', () {
    test('ratio 100（缺省）：1000 个 -> 1000 分', () {
      expect(tokensToMinor(1000, 100), 1000);
      expect(tokensToMinor(1000), 1000, reason: '比例缺省按 100');
      expect(tokensToMinor(1, 100), 1);
      expect(tokensToMinor(0, 100), 0);
      expect(tokensToMinor(32400, 100), 32400);
    });

    test('ratio 50：1000 个 -> 2000 分、1 个 -> 2 分', () {
      expect(tokensToMinor(1000, 50), 2000);
      expect(tokensToMinor(1, 50), 2);
      expect(tokensToMinor(3, 50), 6);
      expect(tokensToMinor(25, 50), 50);
      expect(tokensToMinor(0, 50), 0);
    });

    test('与 round(个数 ÷ ratio × 100) 逐项一致（HALF_UP）', () {
      for (final ratio in const [1, 3, 7, 50, 100, 200, 999]) {
        for (final count in const [
          0,
          1,
          2,
          3,
          7,
          99,
          100,
          101,
          1000,
          12345,
          999999,
        ]) {
          final expected = (count / ratio * 100).round();
          expect(
            tokensToMinor(count, ratio),
            expected,
            reason: '$count 个 / ratio $ratio',
          );
        }
      }
    });

    test('比例缺失/非法一律按 100 降级，不抛错', () {
      expect(normalizeWalletRatio(null), 100);
      expect(normalizeWalletRatio(''), 100);
      expect(normalizeWalletRatio('abc'), 100);
      expect(normalizeWalletRatio(0), 100);
      expect(normalizeWalletRatio(-5), 100);
      expect(normalizeWalletRatio(' 200 '), 200);
      expect(normalizeWalletRatio(50), 50);
      expect(tokensToMinor(1000, null), 1000);
      expect(tokensToMinor(1000, 0), 1000);
      expect(tokensToMinor(1000, -5), 1000);
    });

    test('POINT 300 个 -> 300 分：1:1，不乘任何比例（ratio 50/3 都不变）', () {
      expect(pointsToMinor(300), 300);
      expect(pointsToMinor(0), 0);
      expect(pointsToMinor(12345), 12345);
      for (final ratio in const [50, 3]) {
        // 比例归一化本身有效，但积分换算不经过它。
        expect(normalizeWalletRatio(ratio), ratio);
        expect(pointsToMinor(300), 300, reason: 'ratio $ratio 不改变积分个数');
        expect(pointsToMinor(300), isNot(tokensToMinor(300, ratio)));
      }
    });
  });

  group('tokenCountFromMinor：余额 -> 数量（服务端未给 tokenAmount 时的降级）', () {
    test('round(余额 ÷ 100 × ratio) 与服务端口径一致', () {
      expect(tokenCountFromMinor(100000, 100), 100000);
      expect(tokenCountFromMinor(100, 100), 100);
      expect(tokenCountFromMinor(50, 200), 100);
      expect(tokenCountFromMinor(0, 100), 0);
      expect(tokenCountFromMinor(100000), 100000, reason: '比例缺省 100');
    });

    test('整除场景与 tokensToMinor 互逆', () {
      for (final ratio in const [50, 100, 200]) {
        for (final count in const [0, 1, 10, 1000, 12345]) {
          if ((count * 100) % ratio != 0) continue;
          expect(
            tokenCountFromMinor(tokensToMinor(count, ratio), ratio),
            count,
            reason: '$count 个 / ratio $ratio',
          );
        }
      }
    });
  });

  group('parseTokenCountInput：整数个数输入', () {
    test('只接受非负整数，容忍千分位与空白', () {
      expect(parseTokenCountInput('1000'), 1000);
      expect(parseTokenCountInput(' 1,000 '), 1000);
      expect(parseTokenCountInput('1 000'), 1000);
      expect(parseTokenCountInput('12,345,678'), 12345678);
      expect(parseTokenCountInput('0'), 0);
    });

    test('空/小数/负号/非法字符 -> null（按未填写处理，不抛错）', () {
      expect(parseTokenCountInput(''), isNull);
      expect(parseTokenCountInput('   '), isNull);
      expect(parseTokenCountInput('1.5'), isNull);
      expect(parseTokenCountInput('.5'), isNull);
      expect(parseTokenCountInput('-1'), isNull);
      expect(parseTokenCountInput('abc'), isNull);
      expect(parseTokenCountInput('1,0.5'), isNull);
    });
  });

  group('formatTokens / formatPoints：只出数量，绝不出货币与单位', () {
    test('formatTokens：只出数量（千分位），不拼品牌名', () {
      expect(formatTokens(1000), '1,000');
      expect(formatTokens(888000), '888,000');
      expect(formatTokens(0), '0');
      expect(formatTokens('1000'), '1,000');
      expect(formatTokens(777), '777');
    });

    test('formatPoints：只出数量（千分位），不拼「积分」', () {
      expect(formatPoints(300), '300');
      expect(formatPoints(3000), '3,000');
      expect(formatPoints(0), '0');
      expect(formatPoints('12345'), '12,345');
    });

    test('品牌名只做标签兜底（不再出现在值里）', () {
      expect(defaultTokenBrandName, 'A380币');
      expect(tokenBrandOrDefault(null), 'A380币');
      expect(tokenBrandOrDefault(' 皇冠币 '), '皇冠币');
      // 值是纯数字：品牌名 / 「积分」/「个」都不参与拼接
      for (final text in <String>[formatTokens(1000), formatPoints(300)]) {
        expect(text.contains(defaultTokenBrandName), isFalse, reason: text);
        expect(text.contains('积分'), isFalse, reason: text);
        expect(text.contains('个'), isFalse, reason: text);
      }
    });

    test('输出绝不匹配货币痕迹，也不含小数与任何单位', () {
      final samples = <String>[
        formatTokens(1000),
        formatTokens(888000),
        formatTokens(0),
        formatPoints(300),
        formatPoints(1234567),
        formatTokenCount(1000),
      ];
      for (final text in samples) {
        expect(currencyTrace.hasMatch(text), isFalse, reason: text);
        expect(text.contains('.'), isFalse, reason: text);
        expect(RegExp(r'[A-Za-z\u4e00-\u9fa5]').hasMatch(text), isFalse, reason: text);
      }
    });

    test('数量无效 -> 占位符', () {
      expect(formatTokenCount(null), tokenCountPlaceholder);
      expect(formatTokens(null), tokenCountPlaceholder);
      expect(formatTokens('abc'), tokenCountPlaceholder);
      expect(formatTokens(''), tokenCountPlaceholder);
      expect(formatPoints(null), tokenCountPlaceholder);
      expect(formatPoints('1.5'), tokenCountPlaceholder);
      expect(formatTokens(null), '—');
      expect(formatPoints('abc'), '—');
    });
  });
}
