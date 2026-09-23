import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/order_data_revision_reload.dart';
import '../../models/ktv_models.dart';
import '../../providers/currency_provider.dart';
import '../../providers/pending_approval_provider.dart';
import '../../repositories/business/ktv_api_client.dart';
import '../../widgets/open_nav_bar.dart';

/// KTV 结台页：展示服务端账单快照（GET /orders/{id}/bill），
/// 确认后执行结台（POST /ktv/sessions/{id}/close）并跳转组合收款。
class KtvSettleScreen extends StatefulWidget {
  const KtvSettleScreen({super.key, this.args});

  final KtvSessionArgs? args;

  @override
  State<KtvSettleScreen> createState() => _KtvSettleScreenState();
}

class _KtvSettleScreenState extends State<KtvSettleScreen>
    with OrderDataRevisionReload<KtvSettleScreen> {
  KtvBill? _bill;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  /// initState 里取一次（只监听，不启动轮询：轮询由工作台一级页持引用）。
  PendingApprovalController? _pendingApproval;

  @override
  PendingApprovalController? get pendingApprovalController => _pendingApproval;

  /// 确认/拒绝会改本单应收：静默重拉账单快照（结台前收银员看到的就是这个数）。
  @override
  void reloadOrderData() {
    if (widget.args?.orderId == null) return;
    _load(silent: true);
  }

  @override
  void initState() {
    super.initState();
    _pendingApproval = context.read<PendingApprovalController?>();
    // 账单快照会因确认/拒绝而过期（确认才计费）：监听信号重拉，避免停在与账单页不一致的旧值。
    bindOrderDataRevision();
    _load();
  }

  @override
  void dispose() {
    unbindOrderDataRevision();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    final orderId = widget.args?.orderId;
    if (orderId == null || orderId.isEmpty) {
      setState(() {
        _loading = false;
        _error = '缺少订单上下文';
      });
      return;
    }
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final bill = await context.read<KtvApiClient>().getBill(orderId);
      if (!mounted) return;
      setState(() {
        _bill = bill;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // 静默重拉失败时保留屏幕上已有的账单，只有确实没数据才把整页打成错误态。
        if (!silent || _bill == null) _error = KtvApiClient.describeError(e);
      });
    }
  }

  Future<void> _confirm() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final client = context.read<KtvApiClient>();
      final sid = widget.args?.sessionId;
      if (sid != null && sid.isNotEmpty) {
        await client.closeSession(sid);
      }
      if (!mounted) return;
      context.push(
        AppRoutes.ktvCashier,
        extra: KtvSessionArgs(
          orderId: widget.args?.orderId,
          sessionId: sid,
          roomId: widget.args?.roomId,
          roomName: widget.args?.roomName,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(KtvApiClient.describeError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 全局币种变更后，无单据快照的金额（回退当前租户币种）同步刷新。
    context.watch<CurrencyController>();
    final pageBg = gvPageScaffoldBackground(context);
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final bgCard = AppColors.bgWhite.resolveFrom(context);
    final border = AppColors.border.resolveFrom(context);
    final accent = AppColors.primary.resolveFrom(context);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(title: '结台', showBack: true, backgroundColor: pageBg),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _bill == null
              ? _buildError(secondary)
              : ListView(
                  padding: const EdgeInsets.all(GvSpacing.page),
                  children: [
                    _billCard(_bill!, bgCard, border, primary, secondary),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _busy ? null : _confirm,
                        style: FilledButton.styleFrom(backgroundColor: accent),
                        child: Text(_busy ? '结台中…' : '确认结台'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '结台由服务端结算并释放包厢，金额以服务端账单为准。',
                      textAlign: TextAlign.center,
                      style: GvTypography.caption(secondary),
                    ),
                  ],
                ),
    );
  }

  Widget _billCard(KtvBill bill, Color bgCard, Color border, Color primary,
      Color secondary) {
    final lines = <Widget>[];

    if (bill.roomFee.name.isNotEmpty) {
      lines.add(_row(bill.roomFee.name, bill.roomFee.amount.formatted, primary));
    }
    for (final item in bill.items) {
      final label = item.name + (item.quantity > 1 ? ' ×' + item.quantity.toString() : '');
      lines.add(_row(label, item.amount.formatted, primary));
    }
    if (bill.serverFee.name.isNotEmpty && !bill.serverFee.amount.isZero) {
      lines.add(_row(bill.serverFee.name, bill.serverFee.amount.formatted, primary));
    }
    for (final p in bill.promotions) {
      lines.add(_row(p.name, p.amount.formatted, secondary));
    }
    lines.add(Divider(color: border.withValues(alpha: 0.4)));
    lines.add(_row('应收合计', bill.totalAmount.formatted, primary, bold: true));
    if (!bill.paidAmount.isZero) {
      lines.add(_row('已收', bill.paidAmount.formatted, secondary));
    }
    if (!bill.changeAmount.isZero) {
      lines.add(_row('找零', bill.changeAmount.formatted, secondary));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(GvRadii.card),
        border: Border.all(color: border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('包厢 ' + (widget.args?.roomName ?? '-'),
              style: GvTypography.title(primary)),
          const SizedBox(height: 4),
          Text('账单快照（' + bill.currencyLabel + '）',
              style: GvTypography.caption(secondary)),
          const SizedBox(height: 12),
          ...lines,
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color color, {bool bold = false}) {
    final style = bold ? GvTypography.title(color) : GvTypography.body(color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _buildError(Color secondary) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Center(
          child: Column(
            children: [
              Text(_error ?? '', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: const Text('重试')),
            ],
          ),
        ),
      ],
    );
  }
}

