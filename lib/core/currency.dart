import 'package:flutter/foundation.dart' show debugPrint;

// ─────────────────────────────────────────────────────────────────────────────
// 币种约定（租户级单一来源）：唯一注册表 + 唯一金额格式化入口。
//
// 依据 `16_CURRENCY_CONVENTIONS.md`：
// - 支持 CNY（¥）/ USD（$），**默认 USD**；切币种不做汇率换算，金额数字不变。
// - 符号与小数位**集中在此一处**，业务代码不得再写 `¥`/`元`/`CNY`/`RMB` 字面量。
// - DB/接口金额一律是「最小货币单位整数」（CNY 分 / USD cent），
//   客户端只做「最小单位 <-> 展示字符串」的换算，不做任何金额运算。
// - 展示格式统一为「符号紧跟数字、无空格」：`¥100.00` / `$100.00`（规范 §4）。
//
// 本文件是 App 侧唯一的换算/格式化实现；`lib/models/ktv_models.dart` 的
// `KtvMoney` 与各业务屏都委托到这里，不再各写一套。
// ─────────────────────────────────────────────────────────────────────────────

/// 币种注册表与全局当前租户币种。
///
/// 任何符号/小数位/名称映射都必须走这里，禁止在业务代码里另建映射表。
class Currency {
  Currency._();

  /// 缺省币种（租户未配置/接口未返回时）。
  static const String fallbackCode = 'USD';

  /// 租户级可选币种（规范 §1：当前只有这两个）。
  static const String cny = 'CNY';
  static const String usd = 'USD';

  /// 币种 -> 展示符号（仅用于展示，不参与任何计算）。
  static const Map<String, String> symbols = {
    'CNY': '¥',
    'JPY': '¥',
    'KRW': '₩',
    'USD': '\u0024',
    'EUR': '€',
    'HKD': 'HK\u0024',
  };

  /// 币种 -> 小数位数（最小单位换算到主单位的 10 的幂）。
  static const Map<String, int> decimals = {
    'JPY': 0,
    'KRW': 0,
  };

  /// 币种 -> 展示名称（界面不得再裸露 `CNY`/`USD` 裸码）。
  static const Map<String, String> labels = {
    'CNY': '人民币',
    'USD': '美元',
    'JPY': '日元',
    'KRW': '韩元',
    'EUR': '欧元',
    'HKD': '港币',
  };

  /// 支持的后端币种码（规范 §1）；未知值一律回退 [fallbackCode]。
  static const List<String> supportedCodes = [cny, usd];

  static String _currentCode = fallbackCode;

  /// 当前租户币种（全局可读，缺省 USD）。
  static String get currentCode => _currentCode;

  /// 归一化币种码：去空白 + 大写。
  static String normalize(String? raw) => (raw ?? '').trim().toUpperCase();

  /// 是否是可格式化的已知币种（含未来新增币种字典项）。
  static bool isKnown(String? raw) {
    final code = normalize(raw);
    return code.isNotEmpty && symbols.containsKey(code);
  }

  /// 是否为租户级可选币种。
  static bool isSupported(String? raw) => supportedCodes.contains(normalize(raw));

  /// 币种小数位，未知/空值按 2 位（最小单位口径）。
  static int decimalsOf(String? raw) => decimals[normalize(raw)] ?? 2;

  /// 币种展示符号，未知/空值回退当前租户币种。
  static String symbolOf(String? raw) => symbols[_resolve(raw)]!;

  /// 币种展示名称，未知/空值回退当前租户币种（界面不得展示裸 ASCII 码）。
  static String labelOf(String? raw) => labels[_resolve(raw)]!;

  /// 设置全局当前租户币种。
  ///
  /// - 空值：回退 [fallbackCode]（默认 USD），属预期行为，不打日志。
  /// - 非空但未知：回退 [fallbackCode] 并记 debug 日志（不静默）。
  static void setCurrentCode(String? raw) {
    final code = normalize(raw);
    if (code.isEmpty) {
      _currentCode = fallbackCode;
      return;
    }
    if (!isKnown(code)) {
      debugPrint(
        '[Currency] 未知币种 "$code"，回退 $fallbackCode',
      );
      _currentCode = fallbackCode;
      return;
    }
    _currentCode = code;
  }

  /// 重置为缺省币种（登出/测试用）。
  static void resetCurrentCode() => _currentCode = fallbackCode;

  static String _resolve(String? raw) {
    final code = normalize(raw);
    return isKnown(code) ? code : _currentCode;
  }
}

/// 解析「记录自带币种」：空值回退当前租户币种；未知值回退当前租户币种并记日志。
///
/// 规范 §3.6：记录自身带 `currencyCode` 的以记录为准；缺失才用上下文币种。
String resolveCurrencyCode(String? currencyCode, {String source = ''}) {
  final raw = Currency.normalize(currencyCode);
  if (raw.isEmpty) return Currency.currentCode;
  if (!Currency.isKnown(raw)) {
    debugPrint(
      '[Currency] 未知币种 "$raw"'
      '${source.isEmpty ? '' : '（$source）'}，回退当前币种 ${Currency.currentCode}',
    );
    return Currency.currentCode;
  }
  return raw;
}

/// **唯一**金额格式化入口：最小货币单位 -> 「符号紧跟数字、无空格」。
///
/// 例：`formatMoney(10000, 'CNY')` -> `¥100.00`；`formatMoney(10000, 'USD')` -> `$100.00`。
/// 未知/缺省币种回退当前租户币种并记 debug 日志；0/负数/大额千分位均正确处理。
/// 仅做展示换算，不做任何金额运算。
String formatMoney(int minorUnits, [String? currencyCode]) {
  final code = resolveCurrencyCode(currencyCode, source: 'formatMoney');
  final decimals = Currency.decimalsOf(code);
  final symbol = Currency.symbolOf(code);
  final sign = minorUnits < 0 ? '-' : '';
  final abs = minorUnits.abs();

  if (decimals <= 0) return '$sign$symbol${_withThousandsSeparator(abs)}';

  final factor = _pow10(decimals);
  final major = abs ~/ factor;
  final frac = (abs % factor).toString().padLeft(decimals, '0');
  return '$sign$symbol${_withThousandsSeparator(major)}.$frac';
}

/// 无符号主单位金额文本（输入框回填用），如 `32400` + CNY -> `324.00`。
/// 与 [formatMoney] 共用同一份小数位表，因此不会出现「写死 2 位」的分叉。
String formatAmountPlain(int minorUnits, [String? currencyCode]) {
  final code = resolveCurrencyCode(currencyCode, source: 'formatAmountPlain');
  final decimals = Currency.decimalsOf(code);
  final sign = minorUnits < 0 ? '-' : '';
  final abs = minorUnits.abs();

  if (decimals <= 0) return '$sign$abs';

  final factor = _pow10(decimals);
  final major = abs ~/ factor;
  final frac = (abs % factor).toString().padLeft(decimals, '0');
  return '$sign$major.$frac';
}

/// 主单位输入文本 -> 最小货币单位整数（与 [formatAmountPlain] 互逆）。
///
/// 小数位**跟随币种**（规范 §4：禁止视图里散落 `÷100`/`×100`）。
/// 空输入返回 0；非法字符按缺失处理，不抛异常。
int parseMoneyInput(String text, [String? currencyCode]) {
  final code = resolveCurrencyCode(currencyCode, source: 'parseMoneyInput');
  final decimals = Currency.decimalsOf(code);

  var t = text.trim().replaceAll(',', '').replaceAll('，', '');
  if (t.isEmpty) return 0;
  var negative = false;
  if (t.startsWith('-')) {
    negative = true;
    t = t.substring(1);
  } else if (t.startsWith('+')) {
    t = t.substring(1);
  }
  if (t.isEmpty) return 0;

  final parts = t.split('.');
  final major = int.tryParse(parts[0].trim()) ?? 0;
  if (decimals <= 0) return negative ? -major : major;

  var minor = 0;
  if (parts.length > 1 && parts[1].isNotEmpty) {
    final digits = parts[1].replaceAll(RegExp('[^0-9]'), '');
    if (digits.isNotEmpty) {
      minor = int.tryParse(
            digits.padRight(decimals, '0').substring(0, decimals),
          ) ??
          0;
    }
  }
  final value = major * _pow10(decimals) + minor;
  return negative ? -value : value;
}

// ─────────────────────────────────────────────────────────────────────────────
// 储值币（代币）与积分：**数量**口径，与币种完全解耦（规范 16 §9）。
//
// 储值币与积分都**不是货币**（组合支付里的储值币 / 营销币）：
// - 界面只显示/输入**个数**，绝不出现货币符号（¥ ￥ $ €）、币种码（CNY/USD/RMB）
//   或主单位名（元），也不带小数位；只有现金与价格带币种。
// - 换算（冻结口径）：`wallet_ratio`（缺省 100）= 1 个主单位（1 元 / 1 美元，
//   随租户币种）= ratio 个代币，即 `代币个数 = 金额主单位 × ratio`；
//   反向 `最小货币单位 = round(个数 ÷ ratio × 100)`（HALF_UP，与服务端一致）。
// - 积分是**个数**，1:1，不乘任何比例。
// - 收款接口的 wire 契约不变：`payments[].amount` 仍是最小货币单位整数，
//   各腿**折算后**的金额合计必须等于应收。
//
// 这里是 App 侧唯一的数量换算/格式化入口；业务代码不得再自建第二套。
// ─────────────────────────────────────────────────────────────────────────────

/// 储值币品牌名缺失时的**唯一**回退（租户未配置 `wallet_brand_name`）。
const String defaultTokenBrandName = 'A380币';

/// 租户未配置 `wallet_ratio` 时的缺省比例：1 个主单位 = 100 个代币。
/// 取不到/非法一律按此值处理，**不抛错**。
const int defaultWalletRatio = 100;

/// 积分的展示单位（积分是个数，1:1，不参与任何比例换算）。
const String pointUnitName = '积分';

/// 数量无效（空 / 非数字）时的占位符。
const String tokenCountPlaceholder = '—';

/// 归一化租户储值比例：缺失 / 非数字 / ≤ 0 一律回退 [defaultWalletRatio]（不抛错）。
int normalizeWalletRatio(Object? raw) {
  final value = raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}'.trim());
  if (value == null || value <= 0) return defaultWalletRatio;
  return value;
}

/// 品牌名归一化：空白 / 缺失回退 [defaultTokenBrandName]（页面不得自带兜底）。
String tokenBrandOrDefault(String? raw) {
  final name = (raw ?? '').trim();
  return name.isEmpty ? defaultTokenBrandName : name;
}

/// 代币数量 -> 最小货币单位（wire 契约仍是分/cent 整数）：`round(个数 ÷ ratio × 100)`。
///
/// 例：ratio 100 时 1000 个 -> 1000；ratio 50 时 1000 个 -> 2000、1 个 -> 2。
int tokensToMinor(int count, [int? ratio]) =>
    _roundDivide(count * 100, normalizeWalletRatio(ratio));

/// 最小货币单位 -> 代币数量（服务端未下发 `tokenAmount` 时的降级换算）：
/// `round(主单位 × ratio)`，即余额 ÷ 100 × ratio。
int tokenCountFromMinor(int minorUnits, [int? ratio]) =>
    _roundDivide(minorUnits * normalizeWalletRatio(ratio), 100);

/// 积分个数 -> 最小货币单位金额（wire 仍是整数）：积分是 1:1 的**个数**，
/// 不乘任何比例（`wallet_ratio` 只作用于储值币）。
int pointsToMinor(int count) => count;

/// 数量输入解析：只接受**非负整数**，容忍千分位逗号与空白。
///
/// 空输入 / 含小数 / 含负号 / 含其它字符一律返回 null（按「未填写」处理，不抛错）。
int? parseTokenCountInput(String text) {
  final t = text
      .trim()
      .replaceAll(',', '')
      .replaceAll('，', '')
      .replaceAll(RegExp(r'\s'), '');
  if (t.isEmpty) return null;
  if (!RegExp(r'^[0-9]+$').hasMatch(t)) return null;
  return int.tryParse(t);
}

/// 纯数量文本：千分位、**无货币符号、无币种码、无小数**；无效值返回 [tokenCountPlaceholder]。
String formatTokenCount(Object? count) {
  if (count == null) return tokenCountPlaceholder;
  final text = count.toString().trim().replaceAll(',', '');
  final value = count is num ? count.round() : int.tryParse(text);
  if (value == null) return tokenCountPlaceholder;
  final sign = value < 0 ? '-' : '';
  return '$sign${_withThousandsSeparator(value.abs())}';
}

/// **储值币唯一展示入口**：只出数量，如 `1,000`。
///
/// 储值币与积分都是**数量**，值里不拼任何单位：既不出现货币符号 / 币种码 / 小数，
/// 也不拼品牌名或「积分」——名字由支付方式、列头、卡片标题与字段标签承担。
String formatTokens(Object? count) => formatTokenCount(count);

/// **积分唯一展示入口**：只出数量，如 `300`（积分是 1:1 的个数，不乘任何比例）。
String formatPoints(Object? count) => formatTokenCount(count);

/// HALF_UP 整数除法（与 `(a / b).round()` 同值，且不用浮点）。
int _roundDivide(int numerator, int denominator) {
  if (denominator <= 0) return 0;
  final negative = numerator < 0;
  final abs = numerator.abs();
  final quotient = (abs * 2 + denominator) ~/ (2 * denominator);
  return negative ? -quotient : quotient;
}

int _pow10(int n) {
  var result = 1;
  for (var i = 0; i < n; i++) {
    result *= 10;
  }
  return result;
}

String _withThousandsSeparator(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    buffer.write(digits[i]);
    if (remaining > 1 && remaining % 3 == 1) buffer.write(',');
  }
  return buffer.toString();
}
