import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:gv_ui/gv_ui.dart' show GvTypography;
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/currency.dart';
import '../../core/order_data_revision_reload.dart';
import '../../models/ktv_models.dart';
import '../../providers/currency_provider.dart';
import '../../providers/pending_approval_provider.dart';
import '../../repositories/business/ktv_api_client.dart';
import '../../widgets/gv_pending_approval_banner.dart';
import '../../widgets/gv_nav_bar.dart';
import 'ktv_bottom_nav.dart';

/// KTV 组合收款页：列出待结算订单，逐笔拆分现金/储值币/积分收款
/// （POST /orders/{id}/collect，common-payment）。
///
/// 金额口径（规范 §3.4/§4/§6/§9）：
/// - **现金**腿按金额输入（主单位），换算与展示走 `lib/core/currency.dart` 的
///   `parseMoneyInput` / `formatAmountPlain` / `formatMoney`，小数位跟随币种；
/// - **储值币 / 积分**是数量腿：界面只显示与输入**个数**，绝不出现货币符号、币种码
///   或小数位；提交时折算为最小货币单位金额（储值币 `tokensToMinor`，积分 1:1），
///   数量口径的解析/换算/展示同样只走 `lib/core/currency.dart`。
/// - 收款币种与各项金额以服务端返回的账单快照为准。
class KtvCashierScreen extends StatefulWidget {
  const KtvCashierScreen({super.key, this.args});

  final KtvSessionArgs? args;

  @override
  State<KtvCashierScreen> createState() => _KtvCashierScreenState();
}

class _KtvCashierScreenState extends State<KtvCashierScreen>
    with OrderDataRevisionReload<KtvCashierScreen> {
  List<KtvOrder> _orders = const [];
  KtvOrder? _selected;
  KtvBill? _bill;
  List<KtvPaymentMethod> _methods = const [];
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  final _cash = TextEditingController();
  final _wallet = TextEditingController();
  final _point = TextEditingController();

  /// 上一次**由本页预填**的现金金额：用户改过就不覆盖（见 [_loadDetail]）。
  String? _prefilledCash;

  /// initState 里取一次：dispose 阶段再用 `context.read` 有被卸载后取不到的风险。
  PendingApprovalController? _pendingApproval;

  @override
  PendingApprovalController? get pendingApprovalController => _pendingApproval;

  /// 确认/拒绝会改本单应收与明细：列表页重拉订单列表，详情页重拉本单订单+账单。
  @override
  void reloadOrderData() {
    final orderId = _selected?.id;
    if (orderId != null && orderId.isNotEmpty) {
      _loadDetail(orderId, silent: true);
    } else {
      _loadList(silent: true);
    }
  }

  @override
  void initState() {
    super.initState();
    // 收银台也要看客户待确认加项角标：进入本页开启（引用计数），离开释放。
    // 可缺省：提醒态装配缺失不应让收银主流程崩掉。
    _pendingApproval = context.read<PendingApprovalController?>()?..start();
    // 别人（或本页）确认/拒绝后，本页手里的订单/账单快照立刻过期：监听信号重拉。
    bindOrderDataRevision();
    if (widget.args?.orderId != null && widget.args!.orderId!.isNotEmpty) {
      _loadDetail(widget.args!.orderId!);
    } else {
      _loadList();
    }
  }

  @override
  void dispose() {
    unbindOrderDataRevision();
    _pendingApproval?.stop();
    _cash.dispose();
    _wallet.dispose();
    _point.dispose();
    super.dispose();
  }

  Future<void> _loadList({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final orders = await context.read<KtvApiClient>().listOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // 静默重拉失败时保留屏幕上已有的订单，只有确实没数据才把整页打成错误态。
        if (!silent || _orders.isEmpty) _error = KtvApiClient.describeError(e);
      });
    }
  }

  Future<void> _loadDetail(String orderId, {bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final client = context.read<KtvApiClient>();
      final order = await client.getOrder(orderId);
      final bill = await client.getBill(orderId);
      final methods = await client.availableMethods(
        orderId: orderId,
        currency: bill.currency,
      );
      if (!mounted) return;
      setState(() {
        _selected = order;
        _bill = bill;
        _methods = methods;
        // 应收由服务端账单快照决定（含包厢费），客户端绝不自己加包厢费估算。
        // 预填只在用户没动过这个输入框时跟随最新应收，避免「应收涨了、输入框还是旧数」。
        if (_cash.text.isEmpty || _cash.text == _prefilledCash) {
          _cash.text = bill.totalAmount.amountPlain;
          _prefilledCash = _cash.text;
        }
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // 静默重拉失败时保留屏幕上已有的账单，只有确实没数据才把整页打成错误态。
        if (!silent || _selected == null) {
          _error = KtvApiClient.describeError(e);
        }
      });
    }
  }

  void _backToList() {
    _cash.clear();
    _wallet.clear();
    _point.clear();
    _prefilledCash = null;
    setState(() {
      _selected = null;
      _bill = null;
      _methods = const [];
    });
    _loadList();
  }

  Future<void> _submitCollect() async {
    final bill = _bill;
    final order = _selected;
    if (bill == null || order == null) return;
    if (_submitting) return;

    final enabledMethods =
        _methods.where((m) => m.enabled).map((m) => m.method).toSet();
    final payments = <Map<String, dynamic>>[];

    // 收款币种以本单账单快照为准（规范 §3.6/§5），不写死。
    final currency = bill.currency;

    // 现金腿：按主单位金额输入，换算成最小货币单位（小数位跟随币种）。
    final cashAmount = parseMoneyInput(_cash.text, currency);
    if (cashAmount > 0) {
      payments.add(
        ktvPaymentEntry(method: 'CASH', amount: cashAmount, currency: currency),
      );
    }

    // 储值币腿：界面输入的是**代币个数**，提交前按租户比例折算成最小货币单位金额。
    if (enabledMethods.contains('WALLET')) {
      final count = parseTokenCountInput(_wallet.text);
      if (count != null && count > 0) {
        final method = _methodOf('WALLET');
        final available = method?.availableTokenCount ?? 0;
        if ((method?.canCheckAvailableBalance ?? false) && count > available) {
          _showSnack('储值币数量超过可用（可用 ${formatTokenCount(available)}），请调整数量');
          return;
        }
        final minor = tokensToMinor(count, method?.walletRatio);
        if (minor <= 0) {
          _showSnack('储值币数量过小：折算后的金额为 0，请增加数量或改用现金');
          return;
        }
        payments.add(
          ktvPaymentEntry(method: 'WALLET', amount: minor, currency: currency),
        );
      }
    }

    // 积分腿：积分是**个数**（1:1，不乘任何比例），个数即成功收款的最小单位金额。
    if (enabledMethods.contains('POINT')) {
      final count = parseTokenCountInput(_point.text);
      if (count != null && count > 0) {
        final method = _methodOf('POINT');
        final available = method?.availableTokenCount ?? 0;
        if ((method?.canCheckAvailableBalance ?? false) && count > available) {
          _showSnack('积分数量超过可用（可用 ${formatTokenCount(available)}），请调整数量');
          return;
        }
        payments.add(
          ktvPaymentEntry(
            method: 'POINT',
            amount: pointsToMinor(count),
            currency: currency,
          ),
        );
      }
    }

    if (payments.isEmpty) {
      _showSnack('请输入收款金额或数量');
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await context.read<KtvApiClient>().collect(
            order.id,
            payments,
            expectedVersion: order.expectedVersion,
          );
      if (!mounted) return;
      final change = result.changeAmount.isZero
          ? ''
          : '，找零 ' + result.changeAmount.formatted;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('收款成功，剩余应收 ' + result.remainingAmount.formatted + change),
        ),
      );
      await _loadDetail(order.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(KtvApiClient.describeError(e))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  KtvPaymentMethod? _methodOf(String method) {
    for (final m in _methods) {
      if (m.method == method) return m;
    }
    return null;
  }

  // ── 现金按金额（lib/core/currency.dart，小数位跟随币种）；
  //    储值币/积分按数量（个数），换算/展示同样只走 lib/core/currency.dart。 ──

  String _orderStatusText(String status) => orderStatusLabel(status);

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

    final detail = _selected != null;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(
        title: detail ? '组合收款' : '收银',
        backgroundColor: pageBg,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && (detail ? _bill == null : _orders.isEmpty)
              ? _buildError(secondary)
              : detail
                  ? _buildDetail(primary, secondary, bgCard, border, accent)
                  : _buildList(primary, secondary, bgCard, border, accent),
      bottomNavigationBar: const KtvBottomNav(currentIndex: 1),
    );
  }

  Widget _buildList(Color primary, Color secondary, Color bgCard, Color border,
      Color accent) {
    final pending = context.watch<PendingApprovalController?>();
    if (_orders.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(GvSpacing.page),
        children: [
          // 没有待结算订单也要能进处理页：客户加项与订单收款是两件事。
          const GvPendingApprovalBanner(),
          Text('暂无待结算订单', style: GvTypography.body(secondary)),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(GvSpacing.page),
      itemCount: _orders.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0)
          return const GvPendingApprovalBanner(margin: EdgeInsets.zero);
        final bill = _orders[index - 1];
        final pendingCount = pending?.countOfOrder(bill.id) ?? 0;
        return Material(
          color: bgCard,
          borderRadius: BorderRadius.circular(GvRadii.card),
          child: InkWell(
            onTap: () => _loadDetail(bill.id),
            borderRadius: BorderRadius.circular(GvRadii.card),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(GvRadii.card),
                border: Border.all(color: border.withValues(alpha: 0.4)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '包厢 ' + (bill.roomName ?? '-'),
                          style: GvTypography.title(primary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bill.orderNo + ' · ' + _orderStatusText(bill.status),
                          style: GvTypography.caption(secondary),
                        ),
                        if (pendingCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '待确认加项 ×' + pendingCount.toString(),
                            style: GvTypography.caption(
                                AppColors.danger.resolveFrom(context)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // 金额只取服务端的「可直接展示总额」：liveTotalAmount 已含当前会话
                  // 实时包厢费（结台后退回落库总额）。**绝不在总额上再加包厢费估算**——
                  // Web 后台曾这么加过，同一单账单 6150 / 卡片 10150，包厢费被算了两遍。
                  Text(bill.liveTotalAmount.formatted,
                      style: GvTypography.title(accent)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: secondary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetail(Color primary, Color secondary, Color bgCard,
      Color border, Color accent) {
    final bill = _bill!;
    return ListView(
      padding: const EdgeInsets.all(GvSpacing.page),
      children: [
        // 该单还有客户待确认加项时，收款前先让收银员看到（确认后才计入应收）。
        GvPendingApprovalBanner(orderId: _selected?.id),
        TextButton(
          onPressed: _backToList,
          child: Row(
            children: const [
              Icon(Icons.arrow_back, size: 16),
              SizedBox(width: 4),
              Text('返回列表'),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgCard,
            borderRadius: BorderRadius.circular(GvRadii.card),
            border: Border.all(color: border.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('应收 ' + bill.totalAmount.formatted,
                  style: GvTypography.title(accent)),
              const SizedBox(height: 4),
              Text(
                  '已收 ' +
                      bill.paidAmount.formatted +
                      ' · ' +
                      bill.currencyLabel,
                  style: GvTypography.caption(secondary)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '逐笔收款（各方式折算后的金额合计需等于应收金额）',
          style: GvTypography.title(primary),
        ),
        const SizedBox(height: 8),
        _amountField(_cash, '现金（始终可用）'),
        const SizedBox(height: 10),
        _tokenCountField(_wallet, _walletFieldLabel()),
        const SizedBox(height: 10),
        _tokenCountField(_point, _pointFieldLabel()),
        const SizedBox(height: 24),
        SizedBox(
          height: 50,
          child: FilledButton(
            onPressed: _submitting ? null : _submitCollect,
            style: FilledButton.styleFrom(backgroundColor: accent),
            child: Text(_submitting ? '收款中…' : '确认收款'),
          ),
        ),
      ],
    );
  }

  /// 储值币输入框 label：品牌名 + 可用**个数**（数量口径，绝不带货币符号/币种码）。
  String _walletFieldLabel() {
    final method = _methodOf('WALLET');
    if (method == null) return '储值币';
    if (!method.enabled) return '${method.tokenBrand}（未启用）';
    // 服务端没下发可用数量时不谎报 0，只显示品牌名。
    if (!method.canCheckAvailableBalance) return method.tokenBrand;
    return '${method.tokenBrand}（可用 ${formatTokenCount(method.availableTokenCount)}）';
  }

  /// 积分输入框 label：可用**积分个数**（积分是 1:1 的个数，不带货币符号/币种码）。
  String _pointFieldLabel() {
    final method = _methodOf('POINT');
    if (method == null) return pointUnitName;
    if (!method.enabled) return '$pointUnitName（未启用）';
    if (!method.canCheckAvailableBalance) return pointUnitName;
    return '$pointUnitName（可用 ${formatTokenCount(method.availableTokenCount)}）';
  }

  /// 现金/金额输入框：主单位金额，小数位跟随币种。
  Widget _amountField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
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
      ),
    );
  }

  /// 数量腿（储值币/积分）输入框：**整数个数**输入，无小数位，**不挂任何单位后缀**
  /// （储值币与积分只出数量，名字由 label 承担）。
  Widget _tokenCountField(
    TextEditingController controller,
    String label,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
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
              OutlinedButton(
                onPressed: () {
                  if (_selected != null) {
                    _loadDetail(_selected!.id);
                  } else {
                    _loadList();
                  }
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
