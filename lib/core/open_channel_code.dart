const gvChannelCodePrefix = 'OPEN_CHANNEL:';

/// 频道二维码/分享 payload：`OPEN_CHANNEL:{code}`。
/// 与加好友码（OPEN_UID:）同风格，扫码时先按用户码、再按频道码依次解析。
/// 保留频道号原样（服务端按大小写无关匹配），避免把 `c` 前缀误转大写。
String buildGvChannelCodePayload(String code) {
  final c = code.trim();
  return '$gvChannelCodePrefix$c';
}

String? parseGvChannelCodePayload(String text) {
  final t = text.trim();
  if (!t.startsWith(gvChannelCodePrefix)) return null;
  final c = t.substring(gvChannelCodePrefix.length).trim();
  return c.isEmpty ? null : c;
}

/// 从任意粘贴文本中提取频道号，用于「粘贴到搜索框即可订阅」：
/// 1. 整串以 `OPEN_CHANNEL:` 开头（扫码/分享 payload）；
/// 2. 文本中任意位置出现 `OPEN_CHANNEL:{code}`（多行分享文本）；
/// 3. 「频道号/Channel code/code」标签后跟的 8 位频道号；
/// 4. 整串就是一个 8 位频道号（`c` 前缀 + 7 位大写字母数字）。
///
/// 返回 null 表示未识别出频道号（按频道名称搜索）。
String? extractChannelCode(String text) {
  final direct = parseGvChannelCodePayload(text);
  if (direct != null) return direct;

  final payloadMatch = RegExp(
    r'OPEN_CHANNEL:\s*([A-Za-z0-9]+)',
    caseSensitive: false,
  ).firstMatch(text);
  if (payloadMatch != null) {
    final c = payloadMatch.group(1)!.trim();
    if (c.isNotEmpty) return c;
  }

  final labeledMatch = RegExp(
    r'(?:频道号|channel\s*code|code)\s*[:：]?\s*([cC][A-Z0-9]{7})',
    caseSensitive: false,
  ).firstMatch(text);
  if (labeledMatch != null) return labeledMatch.group(1)!;

  final bare = text.trim();
  if (RegExp(r'^[cC][A-Z0-9]{7}$').hasMatch(bare)) return bare;
  return null;
}
