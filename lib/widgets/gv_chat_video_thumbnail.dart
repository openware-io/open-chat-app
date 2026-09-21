import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// 聊天中的视频预览：优先用 [posterUrl] 网络封面（懒加载）；否则从视频拉首帧。
class GvChatVideoThumbnail extends StatefulWidget {
  const GvChatVideoThumbnail({
    super.key,
    required this.videoUrl,
    this.posterUrl,
    this.httpHeaders,
    this.width = 200,
    this.height = 120,
    this.playIconSize = 48,
  });

  final String videoUrl;

  /// 已解析的绝对 URL；若提供则不再从视频解码缩略图。
  final String? posterUrl;

  final Map<String, String>? httpHeaders;
  final double width;
  final double height;
  final double playIconSize;

  @override
  State<GvChatVideoThumbnail> createState() => _GvChatVideoThumbnailState();
}

class _GvChatVideoThumbnailState extends State<GvChatVideoThumbnail> {
  Uint8List? _bytes;
  bool _failed = false;

  bool get _usePoster =>
      widget.posterUrl != null && widget.posterUrl!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_usePoster) {
      _failed = false;
    } else if (kIsWeb || widget.videoUrl.isEmpty) {
      _failed = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  @override
  void didUpdateWidget(covariant GvChatVideoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl ||
        oldWidget.httpHeaders != widget.httpHeaders ||
        oldWidget.posterUrl != widget.posterUrl) {
      if (_usePoster) {
        setState(() {
          _bytes = null;
          _failed = false;
        });
      } else {
        setState(() {
          _bytes = null;
          _failed = kIsWeb || widget.videoUrl.isEmpty;
        });
        if (!kIsWeb && widget.videoUrl.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _load();
          });
        }
      }
    }
  }

  Future<void> _load() async {
    if (!mounted || widget.videoUrl.isEmpty || _usePoster) return;
    final pr = MediaQuery.devicePixelRatioOf(context);
    final maxW = (widget.width * pr).round().clamp(120, 720);
    try {
      final b = await VideoThumbnail.thumbnailData(
        video: widget.videoUrl,
        headers: widget.httpHeaders,
        imageFormat: ImageFormat.JPEG,
        maxWidth: maxW,
        quality: 55,
      );
      if (!mounted) return;
      if (b != null && b.isNotEmpty) {
        setState(() => _bytes = b);
      } else {
        setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Widget _playOverlay() {
    return Center(
      child: Icon(
        LucideIcons.circle_play,
        size: widget.playIconSize,
        color: Colors.white.withValues(alpha: 0.95),
        shadows: const [
          Shadow(
            offset: Offset(0, 1),
            blurRadius: 4,
            color: Color(0x80000000),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_usePoster) {
      final pr = MediaQuery.devicePixelRatioOf(context);
      final memW = (widget.width * pr).round().clamp(80, 1600);
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: widget.posterUrl!.trim(),
              httpHeaders: widget.httpHeaders,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.cover,
              memCacheWidth: memW,
              placeholder: (_, __) => const ColoredBox(
                color: Color(0xFF2C2C2E),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => const ColoredBox(
                color: Color(0xFF2C2C2E),
                child: Center(
                  child: Icon(
                    LucideIcons.video,
                    size: 40,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),
            _playOverlay(),
          ],
        ),
      );
    }

    final placeholder = ColoredBox(
      color: const Color(0xFF2C2C2E),
      child: _failed
          ? const Center(
              child: Icon(
                LucideIcons.video,
                size: 40,
                color: Colors.white38,
              ),
            )
          : const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ),
    );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_bytes != null)
            Image.memory(
              _bytes!,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            )
          else
            placeholder,
          _playOverlay(),
        ],
      ),
    );
  }
}
