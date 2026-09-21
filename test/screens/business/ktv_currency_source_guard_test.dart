import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 规范 16 §7：**硬编码符号源码守卫**。
///
/// `lib/screens/business/**` 是现金流界面（收银/结台/班次），币种符号、币种码、
/// 「元」都必须走 `lib/core/currency.dart` 的唯一入口（`formatMoney` /
/// `Currency.labelOf`），不得再出现硬编码。
///
/// 若确实需要保留 dev-only mock/占位数据，必须集中到明确的 dev-only 文件，
/// 并在下面的 [knownDebt] 中按「文件 -> 允许的匹配」登记并写清理由；
/// 该白名单**只允许缩小，不允许新增**。
void main() {
  const businessDir = 'lib/screens/business';

  /// 审计基线：当前 `lib/screens/business/**` 硬编码为 **0**。
  /// 键为相对 `lib/screens/business` 的路径。
  const knownDebt = <String, List<String>>{};

  test('lib/screens/business 不得硬编码 ¥ / ￥ / CNY / RMB / USD', () {
    final dir = Directory(businessDir);
    expect(dir.existsSync(), isTrue,
        reason: '未找到 $businessDir（测试需在包根目录运行）');

    final pattern = RegExp(r'¥|￥|CNY|RMB|USD');
    final violations = <String>[];

    for (final file in dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))) {
      final relative = file.path.replaceAll('\\', '/');
      final allowed = knownDebt[relative] ?? const <String>[];
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final hit = pattern.firstMatch(lines[i]);
        if (hit == null) continue;
        final token = hit.group(0)!;
        if (allowed.contains(token)) continue;
        violations.add('$relative:${i + 1}: $token  ->  ${lines[i].trim()}');
      }
    }

    expect(
      violations,
      isEmpty,
      reason: '业务屏出现硬编码币种符号/币种码，请改走 lib/core/currency.dart：\n'
          '${violations.join('\n')}',
    );
  });

  test('班次页不得再写死 ×100 / ÷100（金额换算跟随币种小数位）', () {
    final source = File('$businessDir/ktv_shift_screen.dart').readAsStringSync();
    for (final banned in const [
      '~/ 100',
      '* 100',
      '× 100',
      'padLeft(2',
      'substring(0, 2)',
    ]) {
      expect(source.contains(banned), isFalse,
          reason: 'ktv_shift_screen.dart 仍包含写死两位小数的实现："$banned"');
    }
  });

  test('收银页不得再自建小数位/幂运算平行实现', () {
    final source =
        File('$businessDir/ktv_cashier_screen.dart').readAsStringSync();
    for (final banned in const [
      '_decimalsOf',
      '_pow10',
      '_plainAmount',
      '_toMinor',
    ]) {
      expect(source.contains(banned), isFalse,
          reason: 'ktv_cashier_screen.dart 仍有平行实现："$banned"');
    }
  });

  test('业务屏金额输入换算只经由 core/currency.dart', () {
    final dir = Directory(businessDir);
    final files = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    final converters = <String>[];
    for (final file in files) {
      final source = file.readAsStringSync();
      if (!source.contains('parseMoneyInput') &&
          !source.contains('amountPlain')) {
        continue;
      }
      converters.add(file.path.replaceAll('\\', '/'));
      expect(source.contains('core/currency.dart'), isTrue,
          reason: '${file.path} 做金额输入换算但未引入统一币种入口');
    }
    // 班次页 + 收银页都必须走统一入口（不再是本地 ×100 实现）。
    expect(converters, hasLength(2));
  });
}
