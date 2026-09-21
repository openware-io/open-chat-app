import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/currency.dart';
import '../core/local_storage.dart';

/// 全局租户币种状态（规范 §3.4：全局 store 持有 `currencyCode`，缺省 USD）。
///
/// - 唯一来源：服务端（业务响应 `currencyCode` / `X-Currency` 响应头 / 上下文接口）。
/// - 变更后 `notifyListeners`，业务屏通过 `context.watch<CurrencyController>()` 统一跟随；
///   金额格式化本身走 [formatMoney]，同样读取这里写入的全局当前币种。
/// - 禁止各业务屏自行写死币种。
class CurrencyController extends ChangeNotifier {
  CurrencyController({LocalStorage? storage, String? initialCode})
      : _storage = storage {
    Currency.setCurrentCode(initialCode ?? Currency.fallbackCode);
    _code = Currency.currentCode;
  }

  final LocalStorage? _storage;
  late String _code;

  /// 当前租户币种码（`CNY` / `USD`）。
  String get code => _code;

  /// 展示符号（`¥` / `$`）。
  String get symbol => Currency.symbolOf(_code);

  /// 展示名称（`人民币` / `美元`）。
  String get label => Currency.labelOf(_code);

  /// 小数位数（CNY/USD 均为 2）。
  int get decimals => Currency.decimalsOf(_code);

  bool get isCny => _code == Currency.cny;

  bool get isUsd => _code == Currency.usd;

  /// 启动时从本地缓存恢复（无缓存保持默认 USD）。
  void hydrate() {
    _apply(_storage?.currencyCode, persist: false);
  }

  /// 应用服务端下发的币种（空值/未知值由 [Currency.setCurrentCode] 兜底为 USD）。
  void apply(String? currencyCode) => _apply(currencyCode, persist: true);

  void _apply(String? currencyCode, {required bool persist}) {
    final before = _code;
    Currency.setCurrentCode(currencyCode);
    _code = Currency.currentCode;
    if (persist) {
      // 本地缓存只用于下次启动的兜底展示；写失败不影响内存态。
      unawaited(_storage?.setCurrencyCode(_code));
    }
    if (_code != before) notifyListeners();
  }
}
