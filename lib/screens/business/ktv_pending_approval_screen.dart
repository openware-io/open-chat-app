import 'package:flutter/material.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../models/ktv_models.dart';
import '../../providers/pending_approval_provider.dart';
import '../../widgets/gv_nav_bar.dart';

/// 「客户待确认加项」集中处理页（B 端 / A380 收银端）。
///
/// 数据源唯一：`GET /business/orders/pending-approval`（见 [PendingApprovalController]）。
/// 处理动作走既有 `POST /business/orders/{orderId}/items/{itemId}/confirm|reject`：
/// 服务端原子条件更新，并发输的一方返回 409，本页把 409 当作「已被别人处理」收敛，
/// 不重复扣库存、不重复留痕、不把并发当故障。
class KtvPendingApprovalScreen extends StatefulWidget {
  const KtvPendingApprovalScreen({super.key, this.args});

  /// 可选：从某张订单的角标进入时只聚焦该单。
  final KtvPendingApprovalArgs? args;

  @override
  State<KtvPendingApprovalScreen> createState() =>
      _KtvPendingApprovalScreenState();
}

/// 处理页入参：聚焦某张订单（为空表示看全门店）。
class KtvPendingApprovalArgs {
  const KtvPendingApprovalArgs({this.orderId});

  final String? orderId;
}

class _KtvPendingApprovalScreenState extends State<KtvPendingApprovalScreen> {
  final Set<String> _busyItems = <String>{};
  bool _busyOrder = false;

  @override
  void initState() {
    super.initState();
    // 进入处理页立即补拉一次：可能已经有人确认过（本地快照不是权威）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PendingApprovalController>().refresh();
    });
  }

  Future<void> _confirm(KtvPendingOrder order, KtvPendingItem item) async {
    if (_busyItems.contains(item.id)) return;
    setState(() => _busyItems.add(item.id));
    final controller = context.read<PendingApprovalController>();
    final result = await controller.confirm(order.orderId, item.id);
    if (!mounted) return;
    setState(() => _busyItems.remove(item.id));
    switch (result) {
      case PendingApprovalAction.success:
        _toast('已确认「' + item.name + '」，应收已更新');
      case PendingApprovalAction.alreadyHandled:
        _toast('该加项已被处理，已刷新为最新状态');
      case PendingApprovalAction.failed:
        _toast('确认失败：' + (controller.error ?? '请稍后重试'));
    }
  }

  Future<void> _reject(KtvPendingOrder order, KtvPendingItem item) async {
    if (_busyItems.contains(item.id)) return;
    setState(() => _busyItems.add(item.id));
    final controller = context.read<PendingApprovalController>();
    final result = await controller.reject(order.orderId, item.id);
    if (!mounted) return;
    setState(() => _busyItems.remove(item.id));
    switch (result) {
      case PendingApprovalAction.success:
        _toast('已拒绝「' + item.name + '」');
      case PendingApprovalAction.alreadyHandled:
        _toast('该加项已被处理，已刷新为最新状态');
      case PendingApprovalAction.failed:
        _toast('拒绝失败：' + (controller.error ?? '请稍后重试'));
    }
  }

  Future<void> _confirmOrder(KtvPendingOrder order) async {
    if (_busyOrder) return;
    setState(() => _busyOrder = true);
    final controller = context.read<PendingApprovalController>();
    final done = await controller.confirmOrder(order.orderId);
    if (!mounted) return;
    setState(() => _busyOrder = false);
    _toast(done > 0 ? '本单已确认 ' + done.toString() + ' 项' : '本单待确认项已被处理');
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PendingApprovalController>();
    final pageBg = gvPageScaffoldBackground(context);
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final bgCard = AppColors.bgWhite.resolveFrom(context);
    final border = AppColors.border.resolveFrom(context);
    final accent = AppColors.primary.resolveFrom(context);
    final danger = AppColors.danger.resolveFrom(context);

    final focus = widget.args?.orderId;
    final orders = focus == null
        ? controller.view.orders
        : controller.view.orders
            .where((order) => order.orderId == focus)
            .toList(growable: false);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(
        title: '待确认加项',
        showBack: true,
        backgroundColor: pageBg,
        right: TextButton(
          onPressed: controller.loading ? null : () => controller.refresh(),
          child: const Text('刷新'),
        ),
      ),
      body: controller.loading && controller.pendingCount == 0
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? _empty(secondary, controller)
              : ListView(
                  padding: const EdgeInsets.all(GvSpacing.page),
                  children: [
                    _headline(
                        controller, primary, secondary, bgCard, border, danger),
                    const SizedBox(height: 12),
                    ...orders.map((order) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _orderCard(
                            order,
                            primary,
                            secondary,
                            bgCard,
                            border,
                            accent,
                            danger,
                          ),
                        )),
                    const SizedBox(height: 8),
                    Text(
                      '待确认加项不计入应收，确认后才计费；拒绝后库存回滚。',
                      style: GvTypography.caption(secondary),
                    ),
                  ],
                ),
    );
  }

  Widget _headline(
    PendingApprovalController controller,
    Color primary,
    Color secondary,
    Color bgCard,
    Color border,
    Color danger,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(GvRadii.card),
        border: Border.all(color: danger.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('共 ' + controller.pendingCount.toString() + ' 条客户加项待确认',
              style: GvTypography.title(primary)),
          const SizedBox(height: 4),
          Text(
            controller.view.amountText.isEmpty
                ? '客户自助提交，确认后才计入应收'
                : '合计 ' + controller.view.amountText + '（确认后计入应收）',
            style: GvTypography.caption(secondary),
          ),
          if (controller.notice != null) ...[
            const SizedBox(height: 6),
            Text(controller.notice!, style: GvTypography.caption(danger)),
          ],
        ],
      ),
    );
  }

  Widget _empty(Color secondary, PendingApprovalController controller) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('暂无待确认加项', style: GvTypography.title(secondary)),
          const SizedBox(height: 6),
          Text(
            controller.error == null ? '客户自助加项会实时出现在这里' : controller.error!,
            style: GvTypography.caption(secondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _orderCard(
    KtvPendingOrder order,
    Color primary,
    Color secondary,
    Color bgCard,
    Color border,
    Color accent,
    Color danger,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(GvRadii.card),
        border: Border.all(color: border.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('包厢 ' + order.roomLabel,
                        style: GvTypography.title(primary)),
                    const SizedBox(height: 2),
                    Text(
                      order.orderNo +
                          (order.sessionStatus.isEmpty
                              ? ''
                              : ' · 会话 ' + _sessionText(order.sessionStatus)),
                      style: GvTypography.caption(secondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: danger.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('待确认 ×' + order.pendingCount.toString(),
                    style: GvTypography.caption(danger)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...order.items.map((item) => _itemRow(
                order,
                item,
                primary,
                secondary,
                border,
                accent,
              )),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _busyOrder ? null : () => _confirmOrder(order),
                child: Text(_busyOrder ? '处理中…' : '本单全部确认'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemRow(
    KtvPendingOrder order,
    KtvPendingItem item,
    Color primary,
    Color secondary,
    Color border,
    Color accent,
  ) {
    final busy = _busyItems.contains(item.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: GvTypography.body(primary)),
                    const SizedBox(height: 2),
                    Text(
                      '× ' +
                          item.quantityText +
                          ' · ' +
                          item.unitPrice.formatted +
                          ' = ' +
                          item.amount.formatted,
                      style: GvTypography.caption(secondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: busy ? null : () => _confirm(order, item),
                child: const Text('确认'),
              ),
              TextButton(
                onPressed: busy ? null : () => _reject(order, item),
                style: TextButton.styleFrom(foregroundColor: accent),
                child: const Text('拒绝'),
              ),
            ],
          ),
          Divider(height: 1, color: border.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  /// 会话状态中文：与后台/收银台口径一致，未覆盖的状态原样展示（不猜）。
  String _sessionText(String status) {
    switch (status.toUpperCase()) {
      case 'RESERVED':
        return '已预约';
      case 'OPEN':
        return '计时中';
      case 'PAUSED':
        return '已暂停';
      case 'CLOSED':
        return '已结台';
      default:
        return status;
    }
  }
}
