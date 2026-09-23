import 'package:flutter/material.dart';

import '../tokens/open_tokens.dart';

/// Centered empty-state text used by lightweight list tabs.
class GvEmptyState extends StatelessWidget {
  const GvEmptyState({
    super.key,
    required this.text,
    required this.textStyle,
  });

  final String text;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: textStyle),
    );
  }
}

/// Section header for grouped lists.
class GvSectionHeader extends StatelessWidget {
  const GvSectionHeader({
    super.key,
    required this.label,
    required this.textStyle,
    this.padding = const EdgeInsets.fromLTRB(
      GvSpacing.page,
      12,
      GvSpacing.page,
      8,
    ),
  });

  final String label;
  final TextStyle textStyle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(label, style: textStyle),
    );
  }
}

/// Generic text search result row.
class GvSearchResultRow extends StatelessWidget {
  const GvSearchResultRow({
    super.key,
    required this.primaryText,
    required this.primaryStyle,
    required this.bodyText,
    required this.bodyStyle,
    this.trailingText,
    this.trailingStyle,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(
      horizontal: GvSpacing.page,
      vertical: 12,
    ),
    this.bodyMaxLines = 4,
  });

  final String primaryText;
  final TextStyle primaryStyle;
  final String bodyText;
  final TextStyle bodyStyle;
  final String? trailingText;
  final TextStyle? trailingStyle;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final int bodyMaxLines;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(primaryText, style: primaryStyle),
              ),
              if (trailingText != null)
                Text(trailingText!, style: trailingStyle ?? primaryStyle),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            bodyText,
            maxLines: bodyMaxLines,
            overflow: TextOverflow.ellipsis,
            style: bodyStyle,
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}
