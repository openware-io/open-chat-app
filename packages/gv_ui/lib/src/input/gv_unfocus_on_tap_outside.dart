import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Unfocuses the active input when the user taps outside its editable region.
///
/// This keeps keyboard dismissal consistent across plain text fields and
/// toolbars that join [EditableText] through [TextFieldTapRegion].
class GvUnfocusOnTapOutside extends StatelessWidget {
  const GvUnfocusOnTapOutside({super.key, required this.child});

  final Widget child;

  static bool _pointerHitsEditableTapRegionGroup(
    PointerDownEvent event,
    BuildContext context,
  ) {
    final view = View.maybeOf(context);
    if (view == null) return false;
    final result = HitTestResult();
    RendererBinding.instance.hitTestInView(result, event.position, view.viewId);
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderTapRegion &&
          target.enabled &&
          target.groupId == EditableText) {
        return true;
      }
    }
    return false;
  }

  static RenderEditable? _renderEditableInSubtree(Element root) {
    RenderEditable? found;
    void walk(Element element) {
      if (found != null) return;
      final renderObject = element.findRenderObject();
      if (renderObject is RenderEditable &&
          renderObject.attached &&
          renderObject.hasSize) {
        found = renderObject;
        return;
      }
      element.visitChildren(walk);
    }

    walk(root);
    return found;
  }

  static Rect? _globalRectForFocus(FocusNode focus) {
    final focusContext = focus.context;
    if (focusContext is! Element || !focusContext.mounted) return null;

    final editable = _renderEditableInSubtree(focusContext);
    final renderObject = focusContext.findRenderObject();
    final box = editable ??
        (renderObject is RenderBox && renderObject.attached
            ? renderObject
            : null);
    if (box == null || !box.attached || !box.hasSize) return null;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (rect.isEmpty) return null;
    return rect;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        final focus = FocusManager.instance.primaryFocus;
        if (focus == null || !focus.hasFocus) return;

        final rect = _globalRectForFocus(focus);
        if (rect == null) return;

        if (!rect.contains(event.position)) {
          if (_pointerHitsEditableTapRegionGroup(event, context)) return;
          focus.unfocus();
        }
      },
      child: child,
    );
  }
}
