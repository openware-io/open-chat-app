/// Matches H5 `formatTime` in `utils/helpers.js`
String formatTime(DateTime d) {
  // 消息时间戳统一为 UTC 存储；展示前转本地时区（服务端无时区时间串按 UTC 解析）。
  final local = d.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  const oneDay = Duration(milliseconds: 86400000);

  if (diff.inMilliseconds < 60000) return '刚刚';
  if (diff.inMilliseconds < 3600000) return '${diff.inMinutes}分钟前';

  final isToday =
      local.year == now.year && local.month == now.month && local.day == now.day;
  final yesterday = now.subtract(oneDay);
  final isYesterday = local.year == yesterday.year &&
      local.month == yesterday.month &&
      local.day == yesterday.day;

  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final time = '$hh:$mm';

  if (isToday) return time;
  if (isYesterday) return '昨天 $time';
  if (diff < const Duration(days: 7)) {
    const days = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final idx = local.weekday % 7;
    return '${days[idx]} $time';
  }

  final M = local.month;
  final D = local.day;
  if (local.year == now.year) return '$M月$D日';
  return '${local.year}/$M/$D';
}

/// Matches H5 `formatChatTime`
String formatChatTime(DateTime d) {
  // 消息时间戳统一为 UTC 存储；展示前转本地时区（修复「下午15:38 显示为昨天23:38」）。
  final local = d.toLocal();
  final now = DateTime.now();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');

  if (local.year == now.year && local.month == now.month && local.day == now.day) {
    return '$hh:$mm';
  }

  final yesterday = now.subtract(const Duration(days: 1));
  if (local.year == yesterday.year &&
      local.month == yesterday.month &&
      local.day == yesterday.day) {
    return '昨天 $hh:$mm';
  }

  return '${local.month}月${local.day}日 $hh:$mm';
}

String getAvatarText(String? name) {
  if (name == null || name.isEmpty) return '?';
  final it = name.runes.iterator;
  if (!it.moveNext()) return '?';
  return String.fromCharCode(it.current).toUpperCase();
}
