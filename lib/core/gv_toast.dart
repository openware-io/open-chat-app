import 'dart:async';

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'gv_root_navigator.dart';

/// 轻提示（Toast），替代 [SnackBar]，水平居中、位于屏幕上半部附近。
abstract final class GvToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    dismiss();

    OverlayState? overlay;
    BuildContext? layoutCtx;

    void takeOverlayFromNav(NavigatorState? nav) {
      if (nav == null || !nav.mounted) return;
      final o = nav.overlay;
      if (o != null && o.mounted) {
        overlay = o;
        layoutCtx = nav.context;
      }
    }

    if (context.mounted) {
      overlay = Overlay.maybeOf(context, rootOverlay: true);
      if (overlay != null) layoutCtx = context;
    }
    if (overlay == null) {
      takeOverlayFromNav(gvRootNavigatorKey.currentState);
    }
    if (overlay == null) {
      takeOverlayFromNav(Navigator.maybeOf(context, rootNavigator: true));
    }
    if (overlay == null && context.mounted) {
      overlay = Overlay.maybeOf(context);
      if (overlay != null) layoutCtx = context;
    }
    if (overlay == null || layoutCtx == null || !layoutCtx!.mounted) {
      debugPrint('GvToast: no overlay for message: $message');
      return;
    }

    final oState = overlay!;
    final lc = layoutCtx!;
    final padding = MediaQuery.paddingOf(lc);
    final h = MediaQuery.sizeOf(lc).height;
    // 状态栏下方约 1/4 屏高处，落在上半区且不贴顶
    final top = padding.top + h * 0.22;

    _entry = OverlayEntry(
      builder: (ctx) {
        return Positioned(
          left: 24,
          right: 24,
          top: top,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xE61E1E1E),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: GvShadows.card,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    oState.insert(_entry!);
    _timer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}
