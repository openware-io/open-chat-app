import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/app_colors.dart';
import '../../providers/pending_approval_provider.dart';

/// KTV 工作台三个一级页（看板 / 收银 / 交班）共用的底部导航。
///
/// 「收银」页签带客户待确认加项角标：客户自助加项后，收银员在任何一级页都能看到
/// 还有几条没确认（数字来自全局 [PendingApprovalController]，不在这里自己拉接口）。
class KtvBottomNav extends StatelessWidget {
  const KtvBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final pending =
        context.watch<PendingApprovalController?>()?.pendingCount ?? 0;
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(AppRoutes.ktvDashboard);
          case 1:
            context.go(AppRoutes.ktvCashier);
          case 2:
            context.go(AppRoutes.ktvShift);
        }
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: '看板'),
        BottomNavigationBarItem(
          icon: _badged(const Icon(Icons.receipt_long), pending),
          label: '收银',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.swap_horiz),
          label: '交班',
        ),
      ],
    );
  }

  /// 角标只显示数字（>99 显示 99+），为 0 时不显示任何角标。
  Widget _badged(Widget icon, int count) {
    if (count <= 0) return icon;
    return Badge(
      label: Text(count > 99 ? '99+' : count.toString()),
      backgroundColor: AppColors.danger,
      child: icon,
    );
  }
}
