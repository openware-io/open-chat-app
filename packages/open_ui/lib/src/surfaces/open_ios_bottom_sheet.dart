import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens/open_tokens.dart';

/// Shows a modal bottom sheet with iOS-like surface, dim layer, and drag handle.
Future<T?> showGvIosModalBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  bool useSurfaceShell = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (context) {
      final child = builder(context);
      if (!useSurfaceShell) return child;
      return GvIosBottomSheetSurface(
        showDragHandle: showDragHandle,
        child: child,
      );
    },
  );
}

class GvIosBottomSheetSurface extends StatelessWidget {
  const GvIosBottomSheetSurface({
    super.key,
    required this.child,
    this.showDragHandle = true,
  });

  final Widget child;
  final bool showDragHandle;

  static BorderRadius get topBorderRadius =>
      const BorderRadius.vertical(top: Radius.circular(GvRadii.cardLg));

  @override
  Widget build(BuildContext context) {
    final background = CupertinoColors.systemBackground.resolveFrom(context);
    final handle = CupertinoColors.tertiaryLabel.resolveFrom(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: topBorderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.42 : 0.14),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        // 背景由内层 Material 绘制（而不是外层 DecoratedBox），使 ListTile/InkWell
        // 能找到最近的 Material 祖先绘制背景与墨迹，避免框架
        // “ListTile background color or ink splashes may be invisible”断言。
        child: Material(
          color: background,
          borderRadius: topBorderRadius,
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      decoration: BoxDecoration(
                        color: handle.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
