import 'package:flutter/material.dart';

import '../tokens/open_tokens.dart';

/// Generic tappable row used by settings, profile, contacts, and similar lists.
///
/// The app layer provides colors, text styles, labels, and business callbacks;
/// this widget only owns spacing, row layout, and interactive states.
class GvActionRow extends StatelessWidget {
  const GvActionRow({
    super.key,
    required this.title,
    required this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    this.leading,
    this.trailing,
    this.onTap,
    this.borderRadius,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: GvSpacing.page,
      vertical: GvSpacing.page + GvSpacing.xs,
    ),
    this.leadingGap = GvSpacing.sm,
    this.titleSubtitleGap = 4,
    this.titleMaxLines = 1,
    this.subtitleMaxLines = 1,
  });

  final String title;
  final TextStyle titleStyle;
  final String? subtitle;
  final TextStyle? subtitleStyle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final EdgeInsetsGeometry padding;
  final double leadingGap;
  final double titleSubtitleGap;
  final int titleMaxLines;
  final int subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: leadingGap),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: titleMaxLines,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  SizedBox(height: titleSubtitleGap),
                  Text(
                    subtitle!,
                    maxLines: subtitleMaxLines,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      hoverColor: hoverColor,
      highlightColor: highlightColor ?? hoverColor,
      splashColor: splashColor,
      child: content,
    );
  }
}

/// Title/value variant for profile and settings detail rows.
class GvValueActionRow extends StatelessWidget {
  const GvValueActionRow({
    super.key,
    required this.title,
    required this.titleStyle,
    required this.value,
    required this.valueStyle,
    this.onTap,
    this.trailing,
    this.borderRadius,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: GvSpacing.page,
      vertical: GvSpacing.page,
    ),
    this.titleFlex = 2,
    this.valueFlex = 3,
    this.valueMaxLines = 1,
  });

  final String title;
  final TextStyle titleStyle;
  final String value;
  final TextStyle valueStyle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final BorderRadius? borderRadius;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final EdgeInsetsGeometry padding;
  final int titleFlex;
  final int valueFlex;
  final int valueMaxLines;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            flex: titleFlex,
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ),
          Expanded(
            flex: valueFlex,
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: valueMaxLines,
              overflow: TextOverflow.ellipsis,
              style: valueStyle,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing!,
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius,
      hoverColor: hoverColor,
      highlightColor: highlightColor ?? hoverColor,
      splashColor: splashColor,
      child: content,
    );
  }
}
