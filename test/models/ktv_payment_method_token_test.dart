import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/currency.dart';
import 'package:gv_chat_app/models/ktv_models.dart';

/// 规范 16 §9：可用支付方式里数量腿（WALLET / POINT）的**数量**口径。
///
/// 覆盖：服务端 `tokenAmount` / `tokenBrandName` / `walletRatio` 优先，
/// 字段缺失时按缺省品牌名 `A380币` + 缺省比例 `100` 降级且**不抛错**；
/// 金额字段（`balance`）仍是货币语义，只有展示层才转成数量。
void main() {
  tearDown(Currency.resetCurrentCode);

  group('WALLET（储值币/代币）数量口径', () {
    test('服务端 tokenAmount / tokenBrandName 优先', () {
      final method = KtvPaymentMethod.fromJson(const {
        'method': 'WALLET',
        'enabled': true,
        'displayName': '欢乐币',
        'balance': '100000',
        'currency': 'USD',
        'tokenAmount': '777',
        'tokenBrandName': '欢乐币',
        'walletRatio': 50,
      });

      expect(method.isWallet, isTrue);
      expect(method.enabled, isTrue);
      expect(method.tokenBrand, '欢乐币');
      expect(method.availableTokenCount, 777);
      expect(method.canCheckAvailableBalance, isTrue);
      expect(formatTokens(method.availableTokenCount), '777');
      // 金额字段仍是货币语义（wire 契约不变），只是不再用于展示数量。
      expect(method.balance.formatted, r'$1,000.00');
    });

    test('tokenAmount 缺失 -> 按 walletRatio 从余额降级换算', () {
      final method = KtvPaymentMethod.fromJson(const {
        'method': 'WALLET',
        'enabled': true,
        'displayName': 'A380币',
        'balance': '100000',
        'currency': 'USD',
        'walletRatio': 50,
      });

      expect(method.tokenAmount, isNull);
      expect(method.walletRatio, 50);
      // 100000 最小单位 = 1000 个主单位 × 50 = 50,000 个代币
      expect(method.availableTokenCount, 50000);
      expect(tokensToMinor(method.availableTokenCount, method.walletRatio),
          100000);
    });

    test('比例缺失/非法/非正一律按 100 降级，不抛错', () {
      for (final raw in const <Object?>[null, '', 'abc', 0, -3, '0']) {
        final method = KtvPaymentMethod.fromJson(<String, dynamic>{
          'method': 'WALLET',
          'enabled': true,
          'displayName': 'A380币',
          'balance': '100000',
          if (raw != null) 'walletRatio': raw,
        });
        expect(method.walletRatio, isNull, reason: 'raw=$raw');
        expect(method.availableTokenCount, 100000, reason: 'raw=$raw');
      }
    });

    test('品牌名：tokenBrandName > displayName > 缺省 A380币', () {
      expect(
        KtvPaymentMethod.fromJson(const {
          'method': 'WALLET',
          'enabled': true,
          'displayName': 'A380币',
          'tokenBrandName': '皇冠币',
        }).tokenBrand,
        '皇冠币',
      );
      expect(
        KtvPaymentMethod.fromJson(const {
          'method': 'WALLET',
          'enabled': true,
          'displayName': '欢乐币',
        }).tokenBrand,
        '欢乐币',
      );
      expect(
        KtvPaymentMethod.fromJson(const {'method': 'WALLET', 'enabled': true})
            .tokenBrand,
        defaultTokenBrandName,
      );
      expect(defaultTokenBrandName, 'A380币');
    });
  });

  group('POINT（积分）数量口径：1:1，不乘任何比例', () {
    test('积分个数即可用数量，服务端比例不参与换算', () {
      final method = KtvPaymentMethod.fromJson(const {
        'method': 'POINT',
        'enabled': true,
        'displayName': '积分',
        'balance': '5000',
        'walletRatio': 50,
      });

      expect(method.isPoint, isTrue);
      expect(method.availableTokenCount, 5000);
      expect(method.canCheckAvailableBalance, isTrue);
      // 数量口径只出数字：不拼「积分」等单位（单位由界面标签/列头承担）。
      expect(formatPoints(method.availableTokenCount), '5,000');
      // 积分腿金额 = 个数（1:1），与比例无关。
      expect(pointsToMinor(300), 300);
      expect(pointsToMinor(300), isNot(tokensToMinor(300, 50)));
      expect(pointsToMinor(300), isNot(tokensToMinor(300, 3)));
    });

    test('服务端给了数量就用数量，否则退回余额数值本身', () {
      final withToken = KtvPaymentMethod.fromJson(const {
        'method': 'POINT',
        'enabled': true,
        'displayName': '积分',
        'balance': '5000',
        'tokenAmount': '300',
      });
      expect(withToken.availableTokenCount, 300);

      final withoutBalance = KtvPaymentMethod.fromJson(const {
        'method': 'POINT',
        'enabled': true,
        'displayName': '积分',
      });
      expect(withoutBalance.hasBalance, isFalse);
      expect(withoutBalance.availableTokenCount, 0);
      // 能力数据缺失 -> 前端不做超用拦截，交给服务端判定。
      expect(withoutBalance.canCheckAvailableBalance, isFalse);
    });
  });

  group('数量展示绝不出现货币痕迹', () {
    final currencyTrace = RegExp(r'[¥￥$€]|CNY|USD|RMB|元');

    test('WALLET / POINT 的展示文本不含符号、币种码与小数', () {
      final wallet = KtvPaymentMethod.fromJson(const {
        'method': 'WALLET',
        'enabled': true,
        'displayName': 'A380币',
        'balance': '100000',
        'currency': 'USD',
      });
      final point = KtvPaymentMethod.fromJson(const {
        'method': 'POINT',
        'enabled': true,
        'displayName': '积分',
        'balance': '5000',
        'currency': 'USD',
      });

      final texts = <String>[
        formatTokens(wallet.availableTokenCount),
        formatPoints(point.availableTokenCount),
      ];
      // 只出数量：不带货币符号、品牌名与「积分」单位
      expect(texts, <String>['100,000', '5,000']);
      for (final text in texts) {
        expect(currencyTrace.hasMatch(text), isFalse, reason: text);
        expect(text.contains('.'), isFalse, reason: text);
        expect(RegExp(r'[A-Za-z\u4e00-\u9fa5]').hasMatch(text), isFalse,
            reason: text);
      }
    });
  });
}
