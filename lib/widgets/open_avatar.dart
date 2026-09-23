import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:open_ui/open_ui.dart';

import '../core/config.dart';
import '../core/formatters.dart';
import '../core/media_url.dart';

class GvAvatar extends StatelessWidget {
  const GvAvatar({
    super.key,
    required this.name,
    required this.uid,
    this.src,
    this.size = 50,
    this.square = false,
  });

  final String name;
  final dynamic uid;
  final String? src;
  final double size;

  /// true 时为圆角方形（与圆形同一套渐变/字/网络图逻辑）。
  final bool square;

  @override
  Widget build(BuildContext context) {
    final url = (src != null && src!.isNotEmpty)
        ? resolveMediaUrl(AppConfig.mediaBase, src)
        : null;
    final letter = getAvatarText(name);
    final colors = avatarGradientColorsForId(uid);
    return GvInitialsAvatar(
      initials: letter,
      gradientColors: colors,
      size: size,
      square: square,
      semanticLabel: '$name的头像',
      image: url != null
          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
          : null,
    );
  }
}
