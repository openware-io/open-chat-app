import 'package:flutter/material.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/currency.dart';
import '../../models/ktv_models.dart';
import '../../providers/currency_provider.dart';
import '../../providers/pending_approval_provider.dart';
import '../../repositories/business/ktv_api_client.dart';
import '../../widgets/open_nav_bar.dart';
import 'ktv_bottom_nav.dart';

/// KTV 开班/交班页：
/// - 开班 POST /api/v1/business/shifts/open（{terminalId, openingCash}）
/// - 交班 POST /api/v1/business/shifts/{id}/close（{actualCash, remark}）
/// 差额≠0 需填写原因；金额（opening/expected/actual/difference）以服务端返回为准。
///
/// 金额输入/展示统一走 lib/core/currency.dart（`parseMoneyInput` /
/// `formatAmountPlain`），小数位跟随币种，不再写死 ×100/÷100。
class KtvShiftScreen extends StatefulWidget {
  const KtvShiftScreen({super.key});

  @override
  State<KtvShiftScreen> createState() => _KtvShiftScreenState();
}

class _KtvShiftScreenState extends State<KtvShiftScreen> {
  KtvShift? _shift;
  bool _busy = false;

  final _openingCash = TextEditingController(text: '500.00');
  final _actualCash = TextEditingController();
  final _remark = TextEditingController();
  final _terminalId = TextEditingController();

  /// initState 里取一次：dispose 阶段再用 `context.read` 有被卸载后取不到的风险。
  PendingApprovalController? _pendingApproval;

  @override
  void initState() {
    super.initState();
    // 交班页同样保留待确认加项角标（引用计数，与看板/收银页共用一次轮询）。
    // 可缺省：提醒态装配缺失不应让交班流程崩掉。
    _pendingApproval = context.read<PendingApprovalController?>()?..start();
  }

  @override
  void dispose() {
    _pendingApproval?.stop();
    _openingCash.dispose();
    _actualCash.dispose();
    _remark.dispose();
    _terminalId.dispose();
    super.dispose();
  }

  /// 当前租户币种（开班时本单尚无快照，用全局当前币种）。
  String get _currentCurrency => Currency.currentCode;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final shift = await context.read<KtvApiClient>().openShift(
            terminalId: _terminalId.text.trim().isEmpty
                ? null
                : _terminalId.text.trim(),
            openingCash:
                parseMoneyInput(_openingCash.text, _currentCurrency).toString(),
          );
      if (!mounted) return;
      setState(() {
        _shift = shift;
        _actualCash.text = shift.expectedCash.amountPlain;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(KtvApiClient.describeError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    final shift = _shift;
    if (shift == null || _busy) return;
    final actual = parseMoneyInput(_actualCash.text, shift.currency);
    final remark = _remark.text.trim();
    if (actual <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入实收现金')));
      return;
    }
    setState(() => _busy = true);
    try {
      final closed = await context.read<KtvApiClient>().closeShift(
            shift.id,
            actualCash: actual.toString(),
            remark: remark.isEmpty ? null : remark,
          );
      if (!mounted) return;
      setState(() => _shift = closed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(KtvApiClient.describeError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    setState(() {
      _shift = null;
      _actualCash.clear();
      _remark.clear();
    });
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.bgWhite.resolveFrom(context),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GvRadii.input),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GvSpacing.fieldH,
        vertical: GvSpacing.fieldV,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = gvPageScaffoldBackground(context);
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final bgCard = AppColors.bgWhite.resolveFrom(context);
    final border = AppColors.border.resolveFrom(context);
    final accent = AppColors.primary.resolveFrom(context);

    // 全局币种变更（服务端下发）后，本页的备用金输入与差额展示同步刷新。
    final currencyLabel = context.watch<CurrencyController>().label;

    final shift = _shift;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(title: '交班', backgroundColor: pageBg),
      body: ListView(
        padding: const EdgeInsets.all(GvSpacing.page),
        children: shift == null
            ? _buildOpen(primary, secondary, accent, currencyLabel)
            : shift.isOpen
                ? _buildClosing(
                    shift, primary, secondary, bgCard, border, accent)
                : _buildClosed(
                    shift, primary, secondary, bgCard, border, accent),
      ),
      bottomNavigationBar: const KtvBottomNav(currentIndex: 2),
    );
  }

  List<Widget> _buildOpen(
      Color primary, Color secondary, Color accent, String currencyLabel) {
    return [
      const SizedBox(height: 8),
      Text('开班', style: GvTypography.title(primary)),
      const SizedBox(height: 12),
      TextField(
        controller: _terminalId,
        decoration: _decoration('终端号（可选）'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _openingCash,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _decoration('备用金（openingCash）· $currencyLabel'),
      ),
      const SizedBox(height: 24),
      SizedBox(
        height: 50,
        child: FilledButton(
          onPressed: _busy ? null : _open,
          style: FilledButton.styleFrom(backgroundColor: accent),
          child: Text(_busy ? '开班中…' : '开班'),
        ),
      ),
    ];
  }

  List<Widget> _buildClosing(KtvShift shift, Color primary, Color secondary,
      Color bgCard, Color border, Color accent) {
    return [
      _summaryCard(shift, primary, secondary, bgCard, border),
      const SizedBox(height: 16),
      Text('交班', style: GvTypography.title(primary)),
      const SizedBox(height: 12),
      TextField(
        controller: _actualCash,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _decoration('实收现金（actualCash）'),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _remark,
        decoration: _decoration('备注（差额≠0 时必填）'),
      ),
      const SizedBox(height: 24),
      SizedBox(
        height: 50,
        child: FilledButton(
          onPressed: _busy ? null : _close,
          style: FilledButton.styleFrom(backgroundColor: accent),
          child: Text(_busy ? '交班中…' : '交班'),
        ),
      ),
    ];
  }

  List<Widget> _buildClosed(KtvShift shift, Color primary, Color secondary,
      Color bgCard, Color border, Color accent) {
    return [
      _summaryCard(shift, primary, secondary, bgCard, border),
      const SizedBox(height: 8),
      if (!shift.differenceAmount.isZero)
        Text(
          '差额 ' + shift.differenceAmount.formatted + '，需复核',
          style: GvTypography.caption(secondary),
        ),
      const SizedBox(height: 24),
      SizedBox(
        height: 50,
        child: FilledButton(
          onPressed: _reset,
          style: FilledButton.styleFrom(backgroundColor: accent),
          child: const Text('再开班'),
        ),
      ),
    ];
  }

  Widget _summaryCard(KtvShift shift, Color primary, Color secondary,
      Color bgCard, Color border) {
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
          Text(
            '${shift.isOpen ? '当前班次' : '已交班'} · ${shift.currencyLabel}',
            style: GvTypography.caption(secondary),
          ),
          const SizedBox(height: 8),
          _metricRow('备用金', shift.openingCash.formatted, primary),
          _metricRow('应缴现金', shift.expectedCash.formatted, primary),
          if (!shift.isOpen) ...[
            _metricRow('实收现金', shift.actualCash.formatted, primary),
            _metricRow('差额', shift.differenceAmount.formatted, primary),
          ],
        ],
      ),
    );
  }

  Widget _metricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GvTypography.body(color))),
          Text(value, style: GvTypography.body(color)),
        ],
      ),
    );
  }
}
