import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 横向三圆点动画，用于历史分页「向新」一端加载中的轻量指示。
class ChatRoomPagingDotsRow extends StatefulWidget {
  /// [color]：圆点基准色，透明度由正弦动画调制。
  const ChatRoomPagingDotsRow({super.key, required this.color});

  /// 加载指示点的主题色（通常取次级文字色）。
  final Color color;

  @override
  State<ChatRoomPagingDotsRow> createState() => _ChatRoomPagingDotsRowState();
}

class _ChatRoomPagingDotsRowState extends State<ChatRoomPagingDotsRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  /// 启动循环动画控制器。
  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  /// 释放动画资源。
  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  /// 三个圆点按相位差做呼吸式闪烁。
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final t = _pulse.value * 2 * math.pi;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final opacity = 0.38 + 0.62 * (0.5 + 0.5 * math.sin(t + i * 0.9));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
