import 'package:flutter_test/flutter_test.dart';

import 'package:gv_chat_app/core/formatters.dart';

/// 消息时间时区回归测试。
///
/// 背景：消息时间戳统一为 UTC 存储，但旧实现直接格式化 UTC 字段（或裸
/// DateTime.tryParse 把无时区串当本地时间），导致「下午 15:38 显示成昨天
/// 23:38 / 今天 07:38」。修复要求：formatter 内部必须把输入当 UTC 转本地。
void main() {
  group('formatChatTime', () {
    test('内部转本地时区：UTC 输入与同刻本地输入输出等价', () {
      // 若内部没有 toLocal，UTC 输入会用 UTC 字段（如 7 点）而本地输入用
      // 本地字段（如 15 点），两者必不等——抓住「直接格式化 UTC 字段」的 bug。
      final utc = DateTime.utc(2026, 8, 19, 7, 38);
      final local = utc.toLocal();
      expect(formatChatTime(utc), formatChatTime(local));
    });

    test('「昨天」判定使用本地日期', () {
      // 本地昨天某时刻与其 UTC 表示：formatChatTime 必须都判为「昨天」。
      final now = DateTime.now().toLocal();
      final yesterdayLocal = DateTime(now.year, now.month, now.day - 1, 23, 30);
      final yesterdayUtc = yesterdayLocal.toUtc();
      expect(formatChatTime(yesterdayUtc), '昨天 23:30');
    });
  });

  group('formatTime', () {
    test('传入 UTC now 应显示「刚刚」而非 8 小时前', () {
      // 旧实现：now（本地）与 d（UTC）混用差 8 小时 → 误显示「8小时前」。
      expect(formatTime(DateTime.now().toUtc()), '刚刚');
    });

    test('几分钟前使用绝对间隔（UTC/本地混用不再干扰）', () {
      final utcNow = DateTime.now().toUtc();
      final fiveMinAgoUtc = utcNow.subtract(const Duration(minutes: 5));
      expect(formatTime(fiveMinAgoUtc), '5分钟前');
    });

    test('内部转本地时区：UTC 输入与同刻本地输入输出等价', () {
      final utc = DateTime.now().toUtc();
      expect(formatTime(utc), formatTime(utc.toLocal()));
    });
  });
}
