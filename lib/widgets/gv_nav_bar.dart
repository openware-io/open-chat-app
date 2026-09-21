import 'package:flutter/cupertino.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';

import '../core/app_colors.dart';

/// 返回逻辑：优先 [GoRouter.pop]，否则 [Navigator.maybePop]。
void _gvNavBarDefaultPop(BuildContext context) {
  final go = GoRouter.maybeOf(context);
  if (go != null && go.canPop()) {
    go.pop();
    return;
  }
  Navigator.maybePop(context);
}

class GvNavBar extends StatelessWidget implements PreferredSizeWidget {
  const GvNavBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.onBack,
    this.right,
    this.backgroundColor,
    this.showBottomShadow = true,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? right;

  /// 为 null 时用 [CupertinoColors.systemBackground]（子页顶栏默认）。
  final Color? backgroundColor;

  /// 主 Tab 等页面可设为 false，去掉顶栏底部分割感阴影。
  final bool showBottomShadow;

  @override
  Size get preferredSize => const GvNavBarChrome(
        title: '',
        titleStyle: TextStyle(),
      ).preferredSize;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ??
        CupertinoColors.systemBackground.resolveFrom(context);

    /// 与 [CupertinoTheme.applyThemeToAll] 解耦，避免返回键被染成 primary 蓝。
    final navIconColor = CupertinoColors.label.resolveFrom(context);

    return GvNavBarChrome(
      title: title,
      titleStyle:
          GvTypography.navTitle(AppColors.textPrimary.resolveFrom(context)),
      showBack: showBack,
      onBack: onBack ?? () => _gvNavBarDefaultPop(context),
      right: right,
      backgroundColor: bg,
      iconColor: navIconColor,
      backTooltip: '返回',
      backIcon: LucideIcons.chevron_left,
      showBottomShadow: showBottomShadow,
    );
  }
}
