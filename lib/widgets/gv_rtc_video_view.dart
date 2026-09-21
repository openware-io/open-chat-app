import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// 通话全屏/小窗视频：不依赖插件自带 [RTCVideoView] 在「首帧尺寸未到」时的布局，
/// 避免 iOS 上 width/height 为 0 时 FittedBox 把 [Texture] 压成不可见（长期黑屏）。
class GvRtcVideoView extends StatelessWidget {
  const GvRtcVideoView({
    super.key,
    required this.renderer,
    this.objectFit = RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
    this.mirror = false,
    this.filterQuality = FilterQuality.medium,
  });

  final RTCVideoRenderer renderer;
  final RTCVideoViewObjectFit objectFit;
  final bool mirror;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<RTCVideoValue>(
          valueListenable: renderer,
          builder: (context, value, _) {
            final tid = renderer.textureId;
            final stream = renderer.srcObject;
            if (tid == null || stream == null) {
              return const ColoredBox(color: Colors.black);
            }
            // 必须与 flutter_webrtc 自带 RTCVideoView 一致：用 [RTCVideoValue.aspectRatio]，
            // 在 rotation 为 90°/270° 时交换有效宽高比。否则竖屏持机仍按 1280×720 横屏框去 FittedBox，
            // 会出现画面「横着」、四周留黑、整体显小等问题。
            final double ar;
            if (value.width > 1 && value.height > 1) {
              ar = value.aspectRatio;
            } else {
              // 首帧前尺寸未到：竖屏通话区常用纵向比例，避免先闪成横向大块
              ar = 9 / 16;
            }
            final fit =
                objectFit == RTCVideoViewObjectFit.RTCVideoViewObjectFitCover
                    ? BoxFit.cover
                    : BoxFit.contain;
            final h = constraints.maxHeight;
            return ColoredBox(
              color: Colors.black,
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: FittedBox(
                  fit: fit,
                  clipBehavior: Clip.hardEdge,
                  child: Center(
                    child: SizedBox(
                      width: h * ar,
                      height: h,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..rotateY(mirror ? -math.pi : 0.0),
                        child: Texture(
                          textureId: tid,
                          filterQuality: filterQuality,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
