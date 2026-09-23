import 'package:flutter/material.dart';

import '../tokens/open_tokens.dart';

/// Reusable search field chrome without app localization or color dependencies.
class GvSearchBarBase extends StatelessWidget {
  const GvSearchBarBase({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.fillColor,
    this.barBackgroundColor,
    this.textStyle,
    this.hintStyle,
    this.prefixIcon,
    this.padding = const EdgeInsets.fromLTRB(
      GvSpacing.page,
      GvSpacing.searchBarOuterV,
      GvSpacing.page,
      GvSpacing.searchBarOuterV,
    ),
    this.fieldVerticalPadding = 10,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final Color? fillColor;
  final Color? barBackgroundColor;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final Widget? prefixIcon;
  final EdgeInsets padding;
  final double fieldVerticalPadding;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      onChanged: onChanged,
      style: textStyle,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle,
        filled: true,
        fillColor: fillColor,
        contentPadding: EdgeInsets.symmetric(
          horizontal: GvSpacing.page,
          vertical: fieldVerticalPadding,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(GvRadii.input),
          borderSide: BorderSide.none,
        ),
        prefixIcon: prefixIcon,
      ),
    );
    final padded = Padding(padding: padding, child: field);
    if (barBackgroundColor == null) return padded;
    return ColoredBox(
      color: barBackgroundColor!,
      child: SizedBox(width: double.infinity, child: padded),
    );
  }
}
