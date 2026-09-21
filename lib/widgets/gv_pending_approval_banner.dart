import 'package:flutter/material.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/app_colors.dart';
import '../providers/pending_approval_provider.dart';
import '../screens/business/ktv_pending_approval_screen.dart';

/// 客户「待确认加项」横幅（B 端 / A380 收银端）。
///
/// 数据来自全局 [PendingApprovalController]（唯一数据源 = 待确认加项聚合接口），
/// 本组件不自己发请求。没有待确认项时**不占位**（返回零尺寸），避免无谓的视觉噪音。
///
/// [orderId] 非空时会额外点出「本单 N 条」，点「处理」直接进处理页并聚焦该单。
///
/// 提醒组件按**可缺省**处理（`PendingApprovalController?`）：收银主流程不能因为
/// 提醒态的装配缺失而崩掉（例如被单独 pump 到没有该 Provider 的子树里）。
/// 生产装配见 `lib/app/app_dependencies.dart`，缺装配由接线守卫测试兜住。
class GvPendingApprovalBanner extends StatelessWidget {
  const GvPendingApprovalBanner({super.key, this.orderId, this.margin});

  final String? orderId;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PendingApprovalController?>();
    if (controller == null || !controller.hasPending) {
      return const SizedBox.shrink();
    }

    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final bgCard = AppColors.bgWhite.resolveFrom(context);
    final danger = AppColors.danger.resolveFrom(context);
    final orderCount = orderId == null ? 0 : controller.countOfOrder(orderId!);

    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(GvRadii.card),
        border: Border.all(color: danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active_outlined, size: 20, color: danger),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '客户加项待确认 ' + controller.pendingCount.toString() + ' 条',
                  style: GvTypography.body(primary),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(controller, orderCount),
                  style: GvTypography.caption(secondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(
              AppRoutes.ktvPendingApproval,
              extra: orderId == null
                  ? null
                  : KtvPendingApprovalArgs(orderId: orderId),
            ),
            child: const Text('去处理'),
          ),
        ],
      ),
    );
  }

  String _subtitle(PendingApprovalController controller, int orderCount) {
    if (orderCount > 0) {
      return '本单 ' + orderCount.toString() + ' 条 · 确认后才计入应收';
    }
    final amount = controller.view.amountText;
    if (amount.isEmpty) {
      return '客户自助提交 · 确认后才计入应收';
    }
    return '合计 ' + amount + ' · 确认后才计入应收';
  }
}
