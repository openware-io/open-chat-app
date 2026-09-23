import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_ui/open_ui.dart' show GvTypographyScale;

import '../core/open_http_headers.dart';
import '../core/media_url.dart';
import '../core/message_preview.dart';
import '../core/unicode_emoji_palette.dart';
import '../models/chat_message.dart';
import 'open_chat_video_thumbnail.dart';

/// 引用/回复中的紧凑内容预览。
///
/// 图片与视频显示缩略图，其余消息继续使用轻量文本摘要。
class GvChatQuotedMessagePreview extends StatelessWidget {
  const GvChatQuotedMessagePreview({
    super.key,
    required this.message,
    required this.baseUrl,
    required this.color,
    this.appHttpHeaders,
    this.prefix = '',
    this.thumbnailSize = 42,
    this.maxLines = 1,
    this.onMediaTap,
  });

  final ChatMessage message;
  final String baseUrl;
  final Map<String, String>? appHttpHeaders;
  final String prefix;
  final Color color;
  final double thumbnailSize;
  final int maxLines;
  final VoidCallback? onMediaTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail = _buildThumbnail(context);
    if (thumbnail != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (prefix.isNotEmpty) ...[
            Flexible(child: _buildText(prefix)),
            const SizedBox(width: 6),
          ],
          thumbnail,
        ],
      );
    }

    return _buildText(
      '$prefix${getMessagePreview(msgType: message.msgType, content: message.content)}',
    );
  }

  Widget _buildText(String text) {
    return Text.rich(
      gvChatBubbleCaptionRich(text, color),
      strutStyle: gvChatBubbleStrutIosOnly(
        fontSize: GvTypographyScale.small,
        height: 1.2,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget? _buildThumbnail(BuildContext context) {
    switch (message.msgType) {
      case 'image':
        final image = parseImageForChat(baseUrl, message.content);
        final url = image.imageUrl;
        if (url.isEmpty) return null;
        final dpr = MediaQuery.devicePixelRatioOf(context);
        return _thumbnailSemantics(
          label: getMessagePreview(
            msgType: message.msgType,
            content: message.content,
          ),
          child: CachedNetworkImage(
            imageUrl: url,
            httpHeaders: gvMediaRequestHeaders(url, appHttpHeaders),
            width: thumbnailSize,
            height: thumbnailSize,
            fit: BoxFit.cover,
            memCacheWidth: (thumbnailSize * dpr).round().clamp(60, 512),
            placeholder: (_, __) => _loadingPlaceholder(),
            errorWidget: (_, __, ___) => _fallbackIcon(LucideIcons.image),
          ),
        );
      case 'video':
        final video = parseVideoForChat(baseUrl, message.content);
        if (video.playUrl.isEmpty) return null;
        final headerUrl = video.posterResolved ?? video.playUrl;
        return _thumbnailSemantics(
          label: getMessagePreview(
            msgType: message.msgType,
            content: message.content,
          ),
          child: GvChatVideoThumbnail(
            videoUrl: video.playUrl,
            posterUrl: video.posterResolved,
            httpHeaders: gvMediaRequestHeaders(headerUrl, appHttpHeaders),
            width: thumbnailSize,
            height: thumbnailSize,
            playIconSize: thumbnailSize * 0.46,
          ),
        );
      default:
        return null;
    }
  }

  Widget _thumbnailSemantics({
    required String label,
    required Widget child,
  }) {
    return Semantics(
      image: onMediaTap == null,
      button: onMediaTap != null,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onMediaTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox.square(dimension: thumbnailSize, child: child),
        ),
      ),
    );
  }

  Widget _loadingPlaceholder() {
    return const ColoredBox(
      color: Color(0xFFE5E5EA),
      child: Center(child: CupertinoActivityIndicator(radius: 7)),
    );
  }

  Widget _fallbackIcon(IconData icon) {
    return ColoredBox(
      color: const Color(0xFFE5E5EA),
      child: Center(child: Icon(icon, size: 18, color: color)),
    );
  }
}
