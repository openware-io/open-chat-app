import 'package:flutter/material.dart';

/// Elevation shared by anchored popover menus built with [showMenu].
const double kGvPopoverMenuElevation = 4;

Color gvPopoverMenuShadowColor(BuildContext _) => const Color(0x1F000000);

/// Returns the overlay-relative rectangle occupied by [anchorContext].
RelativeRect gvMenuPositionForWidget(BuildContext anchorContext) {
  final button = anchorContext.findRenderObject() as RenderBox?;
  final overlay =
      Overlay.of(anchorContext).context.findRenderObject() as RenderBox;
  final size = overlay.size;
  final container = Offset.zero & size;
  if (button == null || !button.attached || !button.hasSize) {
    return RelativeRect.fromSize(Rect.zero, size);
  }
  final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
  final bottomRight = button.localToGlobal(
    Offset(button.size.width, button.size.height),
    ancestor: overlay,
  );
  return RelativeRect.fromRect(
    Rect.fromPoints(topLeft, bottomRight),
    container,
  );
}

/// Places a menu just below an anchor while keeping horizontal alignment.
RelativeRect gvMenuPositionBelowWidget(
  BuildContext anchorContext, {
  double gapBelow = 0,
}) {
  final button = anchorContext.findRenderObject() as RenderBox?;
  final overlay =
      Overlay.of(anchorContext).context.findRenderObject() as RenderBox;
  final size = overlay.size;
  final container = Offset.zero & size;
  if (button == null || !button.attached || !button.hasSize) {
    return RelativeRect.fromSize(Rect.zero, size);
  }
  final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
  final bottomRight = button.localToGlobal(
    Offset(button.size.width, button.size.height),
    ancestor: overlay,
  );
  final anchorTop = bottomRight.dy + gapBelow;
  final rect = Rect.fromLTRB(
    topLeft.dx,
    anchorTop,
    bottomRight.dx,
    anchorTop + 1,
  );
  return RelativeRect.fromRect(rect, container);
}

/// Uses a screen coordinate as a compact menu anchor.
RelativeRect gvMenuPositionForGlobalPoint(
  BuildContext context,
  Offset globalPosition,
) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final size = overlay.size;
  final container = Offset.zero & size;
  final local = overlay.globalToLocal(globalPosition);
  final rect = Rect.fromCircle(center: local, radius: 2);
  return RelativeRect.fromRect(rect, container);
}
