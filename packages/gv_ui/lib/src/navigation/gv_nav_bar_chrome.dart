import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens/gv_tokens.dart';

double _gvTopInsetLogicalPx() {
  final views = PlatformDispatcher.instance.views;
  if (views.isEmpty) return 0;
  final view = views.first;
  return view.padding.top / view.devicePixelRatio;
}

const double _kNavBackMinTap = 48;
const double _kNavBackIcon = 22;
const double _kNavRightMinTap = 48;
const double _kNavRightIcon = 26;

double _gvNavBackLeadingPad() {
  const v = GvSpacing.page - (_kNavBackMinTap - _kNavBackIcon) / 2;
  return v > 0 ? v : 0;
}

double _gvNavBackSlotW() => _gvNavBackLeadingPad() + _kNavBackMinTap;

double _gvNavRightTrailingPad() {
  const v = GvSpacing.page - (_kNavRightMinTap - _kNavRightIcon) / 2;
  return v > 0 ? v : 0;
}

double _gvNavRightSlotW() => _gvNavRightTrailingPad() + _kNavRightMinTap;

/// Shared navigation bar shell.
///
/// This component owns only layout, tap target sizing, and visual chrome. Route
/// behavior and app-specific text styles stay in the app wrapper.
class GvNavBarChrome extends StatelessWidget implements PreferredSizeWidget {
  const GvNavBarChrome({
    super.key,
    required this.title,
    required this.titleStyle,
    this.showBack = false,
    this.onBack,
    this.right,
    this.backgroundColor,
    this.iconColor,
    this.backTooltip,
    this.backIcon,
    this.showBottomShadow = true,
  });

  final String title;
  final TextStyle titleStyle;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? right;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? backTooltip;
  final IconData? backIcon;
  final bool showBottomShadow;

  @override
  Size get preferredSize =>
      Size.fromHeight(_gvTopInsetLogicalPx() + GvLayout.navbarContent);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        CupertinoColors.systemBackground.resolveFrom(context);
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final shadowColor =
        isDark ? const Color(0x24FFFFFF) : const Color(0x0D000000);
    final navIconColor =
        iconColor ?? CupertinoColors.label.resolveFrom(context);
    final hasRight = right != null;
    final titlePadLeft = showBack
        ? _gvNavBackSlotW()
        : (hasRight ? _gvNavRightSlotW() : GvSpacing.page);
    final titlePadRight = hasRight
        ? _gvNavRightSlotW()
        : (showBack ? _gvNavBackSlotW() : GvSpacing.page);

    return Container(
      color: bg,
      width: double.infinity,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: GvLayout.navbarContent,
          decoration: BoxDecoration(
            color: bg,
            boxShadow: showBottomShadow
                ? [
                    BoxShadow(
                      color: shadowColor,
                      offset: const Offset(0, 2),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: titlePadLeft,
                    right: titlePadRight,
                  ),
                  child: Center(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: titleStyle,
                    ),
                  ),
                ),
              ),
              if (showBack)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: _gvNavBackLeadingPad()),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onBack ?? () => Navigator.maybePop(context),
                        style: ButtonStyle(
                          minimumSize: WidgetStateProperty.all(
                            const Size(_kNavBackMinTap, _kNavBackMinTap),
                          ),
                          maximumSize: WidgetStateProperty.all(
                            const Size(_kNavBackMinTap, _kNavBackMinTap),
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                          iconSize: const WidgetStatePropertyAll(_kNavBackIcon),
                          foregroundColor: WidgetStatePropertyAll(navIconColor),
                          overlayColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.pressed) ||
                                states.contains(WidgetState.hovered)) {
                              return isDark
                                  ? const Color(0xFF3A3A3C)
                                  : const Color(0xFFE5E5EA);
                            }
                            return Colors.transparent;
                          }),
                          splashFactory: NoSplash.splashFactory,
                          shape: WidgetStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(_kNavBackMinTap / 2),
                            ),
                          ),
                        ),
                        tooltip: backTooltip,
                        icon: Icon(
                          backIcon ?? Icons.chevron_left,
                          color: navIconColor,
                          size: _kNavBackIcon,
                        ),
                      ),
                    ),
                  ),
                ),
              if (hasRight)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: _gvNavRightTrailingPad()),
                      child: IconTheme(
                        data: IconThemeData(
                          color: navIconColor,
                          size: _kNavRightIcon,
                        ),
                        child: right!,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
