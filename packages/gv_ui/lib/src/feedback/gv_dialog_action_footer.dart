import 'package:flutter/material.dart';

/// Shared dialog action styles and footer layout.
abstract final class GvDialogActionFooter {
  static double actionsTargetWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    const inset = 40.0;
    return (w - inset * 2).clamp(280.0, 560.0);
  }

  static ButtonStyle cancelStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final fg = Theme.of(context).colorScheme.onSurface;
    return TextButton.styleFrom(
      foregroundColor: fg,
      backgroundColor: bg,
      disabledForegroundColor: fg.withValues(alpha: 0.38),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      minimumSize: const Size(64, 48),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static ButtonStyle confirmStyle(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return TextButton.styleFrom(
      foregroundColor: Colors.white,
      backgroundColor: primary,
      disabledForegroundColor: Colors.white.withValues(alpha: 0.38),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      minimumSize: const Size(64, 48),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  static Widget doubleAction(
    BuildContext context, {
    required VoidCallback onSecondary,
    required VoidCallback onPrimary,
    required String secondaryText,
    required String primaryText,
    Key? secondaryKey,
    Key? primaryKey,
  }) {
    final divider = Theme.of(context).dividerColor;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    final secondaryStyle =
        (labelStyle ?? const TextStyle(fontSize: 16)).copyWith(
      color: onSurface,
      fontWeight: FontWeight.w400,
    );
    final primaryStyle = (labelStyle ?? const TextStyle(fontSize: 16)).copyWith(
      color: primaryColor,
      fontWeight: FontWeight.w400,
    );

    Widget textBtn({
      Key? key,
      required String text,
      required TextStyle style,
      required VoidCallback onPressed,
    }) {
      return TextButton(
        key: key,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: style.color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          minimumSize: const Size(0, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: const RoundedRectangleBorder(),
        ),
        child: Text(text, style: style),
      );
    }

    return SizedBox(
      width: actionsTargetWidth(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, thickness: 0.5, color: divider),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: textBtn(
                    key: secondaryKey,
                    text: secondaryText,
                    style: secondaryStyle,
                    onPressed: onSecondary,
                  ),
                ),
                Container(width: 0.5, color: divider),
                Expanded(
                  child: textBtn(
                    key: primaryKey,
                    text: primaryText,
                    style: primaryStyle,
                    onPressed: onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget singleAction(
    BuildContext context, {
    required VoidCallback onPressed,
    required String text,
  }) {
    final divider = Theme.of(context).dividerColor;
    final primary = Theme.of(context).colorScheme.primary;
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    final style = (labelStyle ?? const TextStyle(fontSize: 16)).copyWith(
      color: primary,
      fontWeight: FontWeight.w400,
    );

    return SizedBox(
      width: actionsTargetWidth(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, thickness: 0.5, color: divider),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const RoundedRectangleBorder(),
            ),
            child: Text(text, style: style),
          ),
        ],
      ),
    );
  }
}
