import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gv_ui/gv_ui.dart';

import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';

class GvSearchBar extends StatelessWidget {
  const GvSearchBar({
    super.key,
    required this.controller,
    this.hint,
    this.onChanged,
    this.fillColor = AppColors.bgSearchField,
    this.barBackgroundColor,
    this.padding = const EdgeInsets.fromLTRB(
      GvSpacing.page,
      GvSpacing.searchBarOuterV,
      GvSpacing.page,
      GvSpacing.searchBarOuterV,
    ),
    this.fieldVerticalPadding = 10,
  });

  final TextEditingController controller;

  /// 为 null 时使用 [AppLocalizations.commonSearch]（会话列表、通讯录等默认「搜索」）。
  final String? hint;
  final ValueChanged<String>? onChanged;
  final Color fillColor;
  final EdgeInsets padding;
  final double fieldVerticalPadding;

  /// 整条搜索区域（含外边距）背景；为 null 时不铺底，透出父级背景。
  final Color? barBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final hintC = AppColors.textHint.resolveFrom(context);
    final hintText = hint ?? AppLocalizations.of(context)!.commonSearch;
    return GvSearchBarBase(
      controller: controller,
      hintText: hintText,
      onChanged: onChanged,
      fillColor: fillColor,
      barBackgroundColor: barBackgroundColor,
      padding: padding,
      fieldVerticalPadding: fieldVerticalPadding,
      textStyle: GvTypography.body(AppColors.textPrimary.resolveFrom(context)),
      hintStyle: GvTypography.body(hintC),
      prefixIcon: Icon(
        LucideIcons.search,
        color: hintC,
        size: 22,
      ),
    );
  }
}
