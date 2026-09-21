import 'dart:convert';

import 'media_url.dart';
import 'namecard_message.dart';

/// 占位：[ChatMessage.msgType] 为 image/video/voice 且已开始上传、`chat:send` 尚未发出的 [ChatMessage.content]。
const String gvChatPendingMediaUploadContent = '__gv_pending_media_upload__';

String previewTextFromContent(String msgType, String? content) {
  if (content == null) return '';
  final c = content;
  if (msgType == 'image' && c.trim().startsWith('{')) {
    final image = parseImageForChat('', c);
    if (image.caption.isNotEmpty) return '[图片] ${image.caption}';
  }
  if (msgType == 'text') {
    return c.replaceAllMapped(
      RegExp(r'\[emoji\](\d+)\[/emoji\]'),
      (_) => '[表情]',
    );
  }
  if (msgType == 'recall') return '[消息已撤回]';
  if (msgType == 'emoji') return '[表情包]';
  if (msgType == 'image') return '[图片]';
  if (msgType == 'video') return '[视频]';
  if (msgType == 'voice') return '[语音]';
  if (msgType == 'file') {
    try {
      final m = jsonDecode(c);
      if (m is Map && m['name'] is String) {
        return '[文件] ${m['name']}';
      }
    } catch (_) {}
    return '[文件]';
  }
  if (msgType == 'namecard') {
    try {
      final m = jsonDecode(c);
      if (m is Map) {
        final dn = (m['displayName'] ?? m['nickname'] ?? '').toString().trim();
        if (dn.isNotEmpty) return '[名片] $dn';
      }
    } catch (_) {}
    return '[名片]';
  }
  if (msgType == 'call') {
    try {
      final m = jsonDecode(c);
      if (m is Map) {
        final isVideo = m['media'] == 'video';
        return isVideo ? '[视频通话]' : '[语音通话]';
      }
    } catch (_) {}
    return '[通话]';
  }
  return c.length > 80 ? c.substring(0, 80) : c;
}

String getMessagePreview({required String msgType, required String? content}) {
  return previewTextFromContent(msgType, content);
}

String? getCopyTextForMessage({
  required String msgType,
  required String? content,
  required String baseUrl,
}) {
  if (msgType == 'recall' || msgType == 'system') return null;
  if (msgType == 'text') {
    return content?.replaceAllMapped(
      RegExp(r'\[emoji\](\d+)\[/emoji\]'),
      (_) => '[表情]',
    );
  }
  if (msgType == 'emoji') {
    return resolveMediaUrl(baseUrl, content);
  }
  if (msgType == 'image') {
    return parseImageForChat(baseUrl, content ?? '').imageUrl;
  }
  if (msgType == 'video') {
    return parseVideoForChat(baseUrl, content ?? '').playUrl;
  }
  if (msgType == 'file') {
    final raw = content ?? '';
    try {
      final m = jsonDecode(raw);
      if (m is Map) {
        final name = m['name']?.toString() ?? '文件';
        final url = m['url']?.toString();
        final resolved = url != null ? resolveMediaUrl(baseUrl, url) : '';
        return resolved.isNotEmpty ? '$name\n$resolved' : name;
      }
    } catch (_) {}
    return null;
  }
  if (msgType == 'voice') {
    final s = content ?? '';
    if (s.startsWith('data:') ||
        s.startsWith('http://') ||
        s.startsWith('https://') ||
        s.startsWith('/')) {
      return resolveMediaUrl(baseUrl, s);
    }
    return '[语音消息]';
  }
  if (msgType == 'namecard') {
    final p = NamecardPayload.tryParse(content);
    if (p == null) return null;
    final u = p.username.trim().isNotEmpty ? p.username : '${p.userId}';
    return '${p.displayName}（$u）';
  }
  return content;
}

bool canRecallMessage({
  required int myId,
  required int from,
  required String msgType,
  required String status,
  required DateTime? timestamp,
}) {
  if (from != myId) return false;
  if (status == 'recalled' || msgType == 'recall' || msgType == 'call') {
    return false;
  }
  if (status == 'sending') return false;
  // 撤回不限时：只要是自己发送、且非撤回/通话/发送中即可撤回。
  return true;
}
