import 'dart:convert';

/// 占位：[ChatMessage.msgType] 为 image/video/voice 且已开始上传、`chat:send` 尚未发出的 content。
const String gvChatPendingMediaUploadContent = '__open_pending_media_upload__';

/// 会话列表和通知中使用的轻量预览文案。
String previewTextFromContent(String msgType, String? content) {
  if (content == null) return '';
  final value = content;
  if (msgType == 'image' && value.trim().startsWith('{')) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        final caption = decoded['caption']?.toString().trim() ?? '';
        if (caption.isNotEmpty) return '[图片] $caption';
      }
    } catch (_) {}
  }
  if (msgType == 'text') {
    return value.replaceAllMapped(
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
      final decoded = jsonDecode(value);
      if (decoded is Map && decoded['name'] is String) {
        return '[文件] ${decoded['name']}';
      }
    } catch (_) {}
    return '[文件]';
  }
  if (msgType == 'namecard') {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        final displayName =
            (decoded['displayName'] ?? decoded['nickname'] ?? '')
                .toString()
                .trim();
        if (displayName.isNotEmpty) return '[名片] $displayName';
      }
    } catch (_) {}
    return '[名片]';
  }
  if (msgType == 'call') {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) {
        final isVideo = decoded['media'] == 'video';
        return isVideo ? '[视频通话]' : '[语音通话]';
      }
    } catch (_) {}
    return '[通话]';
  }
  return value.length > 80 ? value.substring(0, 80) : value;
}
