import 'dart:convert';

import '../../core/media_url.dart';
import '../../models/chat_message.dart';

/// 按时间倒序（新在前）拷贝排序，不修改原列表。
List<ChatMessage> chatMessagesNewestFirst(List<ChatMessage> list) {
  return [...list]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
}

/// 按消息时间归并为「年+月」分组键，组内顺序由调用方已排好（通常为最新在前）。
Map<String, List<ChatMessage>> groupChatMessagesByYearMonth(
  List<ChatMessage> items,
  String Function(int year, int month) monthLabel,
) {
  final sorted = chatMessagesNewestFirst(items);
  final map = <String, List<ChatMessage>>{};
  for (final m in sorted) {
    final k = monthLabel(m.timestamp.year, m.timestamp.month);
    map.putIfAbsent(k, () => []).add(m);
  }
  return map;
}

/// 检索与气泡一致：把自定义表情占位替换为本地化占位便于纯文本预览。
String displayTextBodyStripEmojiTags(String raw, String emojiPlaceholder) {
  return raw.replaceAllMapped(
    RegExp(r'\[emoji\](\d+)\[/emoji\]'),
    (_) => emojiPlaceholder,
  );
}

/// 从 `file` 类型消息的 JSON [content] 中解析展示文件名。
String chatFileDisplayNameFromContent(
  ChatMessage m, {
  required String unnamedLabel,
}) {
  try {
    final map = jsonDecode(m.content);
    if (map is Map && map['name'] is String) {
      final n = (map['name'] as String).trim();
      if (n.isNotEmpty) return n;
    }
  } catch (_) {}
  return unnamedLabel;
}

/// 解析服务端文本检索接口返回的列表：只保留文本、去重、新在前。
List<ChatMessage> parseRemoteTextSearchHits(List<dynamic> raw) {
  final out = <ChatMessage>[];
  final seen = <String>{};
  for (final e in raw) {
    if (e is! Map) continue;
    final m = ChatMessage.fromJson(Map<String, dynamic>.from(e));
    if (m.msgType != 'text' || seen.contains(m.msgId)) continue;
    seen.add(m.msgId);
    out.add(m);
  }
  out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return out;
}

/// Parses text hits and image hits whose embedded caption matches [keyword].
List<ChatMessage> parseRemoteChatSearchHits(
  List<dynamic> raw, {
  required String keyword,
}) {
  final normalizedKeyword = keyword.trim().toLowerCase();
  final out = <ChatMessage>[];
  final seen = <String>{};
  for (final e in raw) {
    if (e is! Map) continue;
    final m = ChatMessage.fromJson(Map<String, dynamic>.from(e));
    var matches = m.msgType == 'text';
    if (m.msgType == 'image') {
      final caption = parseImageForChat('', m.content).caption.toLowerCase();
      matches =
          normalizedKeyword.isNotEmpty && caption.contains(normalizedKeyword);
    }
    if (!matches || seen.contains(m.msgId)) continue;
    seen.add(m.msgId);
    out.add(m);
  }
  out.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return out;
}
