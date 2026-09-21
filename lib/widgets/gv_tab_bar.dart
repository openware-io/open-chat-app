import 'package:flutter/cupertino.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gv_ui/gv_ui.dart';

import '../core/app_colors.dart';
import '../core/gv_automation_keys.dart';

/// iOS 风格底栏：扁平背景 + 顶部柔和阴影（无上边框）。
class GvTabBarShell extends StatelessWidget {
  const GvTabBarShell({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.totalUnread,
    required this.pendingCount,
    this.updateAvailable = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int totalUnread;
  final int pendingCount;

  /// 有新版本可用时，「我」tab 显示小红点（对齐微信：不点进去也能看到）。
  final bool updateAvailable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bg = CupertinoColors.systemBackground.resolveFrom(context);
    return GvBottomTabBar(
      currentIndex: currentIndex,
      onTap: onTap,
      activeColor: AppColors.primary.resolveFrom(context),
      idleColor: AppColors.textSecondary.resolveFrom(context),
      dangerColor: AppColors.danger.resolveFrom(context),
      backgroundColor: bg,
      labelStyleBuilder: GvTypography.tabLabel,
      items: [
        GvBottomTabBarItem(
          automationKey: GvAutomationKeys.tabMessages,
          label: l10n.tabMessages,
          icon: LucideIcons.messages_square,
          badge: totalUnread,
          semanticBadgeLabel:
              totalUnread > 0 ? l10n.tabBadgeUnread(totalUnread) : '',
        ),
        GvBottomTabBarItem(
          automationKey: GvAutomationKeys.tabContacts,
          label: l10n.tabContacts,
          icon: LucideIcons.users,
          badge: pendingCount,
          semanticBadgeLabel: pendingCount > 0 ? l10n.tabBadgeDot : '',
        ),
        GvBottomTabBarItem(
          automationKey: GvAutomationKeys.tabServices,
          label: l10n.tabServices,
          icon: LucideIcons.aperture,
        ),
        GvBottomTabBarItem(
          automationKey: GvAutomationKeys.tabProfile,
          label: l10n.tabMe,
          icon: LucideIcons.user,
          badge: updateAvailable ? 1 : 0,
          semanticBadgeLabel: updateAvailable ? l10n.tabBadgeDot : '',
        ),
      ],
    );
  }
}
