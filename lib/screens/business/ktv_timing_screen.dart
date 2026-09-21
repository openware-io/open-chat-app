import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/order_data_revision_reload.dart';
import '../../models/ktv_models.dart';
import '../../providers/currency_provider.dart';
import '../../providers/pending_approval_provider.dart';
import '../../repositories/business/ktv_api_client.dart';
import '../../widgets/gv_pending_approval_banner.dart';
import '../../widgets/gv_nav_bar.dart';

/// KTV 会话页（计时/加项/暂停/恢复/结台）。
///
/// 对应接口：
/// - 开台 POST /api/v1/business/ktv/sessions/{id}/open
/// - 暂停 POST /api/v1/business/ktv/sessions/{id}/pause
/// - 恢复 POST /api/v1/business/ktv/sessions/{id}/resume
/// - 点单目录 GET /api/v1/business/catalog/items（带可用库存）
/// - 加项 POST /api/v1/business/orders/{id}/items（**只在点「确认加项」时提交一次**）
/// - 结台 POST /api/v1/business/ktv/sessions/{id}/close（跳转结算页执行）
///
/// 加项口径：加减号只改本地购物车，**不调接口**（每点一次就提交会立刻锁库存，减号无法退回）；
/// 加号上限取服务端 `availableQuantity`（查库存防超卖），真正扣减由服务端原子扣减兜底。
/// 金额与状态均以服务端返回为准；本页计时器仅作展示，不参与任何计费。
class KtvTimingScreen extends StatefulWidget {
  const KtvTimingScreen({super.key, this.args});

  final KtvSessionArgs? args;

  @override
  State<KtvTimingScreen> createState() => _KtvTimingScreenState();
}

class _KtvTimingScreenState extends State<KtvTimingScreen>
    with OrderDataRevisionReload<KtvTimingScreen> {
  KtvOrder? _order;
  KtvSession? _session;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  /// 点单目录（来自服务端；无后端时走客户端兜底 mock）。
  List<KtvCatalogItem> _catalog = const [];
  bool _catalogLoading = false;
  String? _catalogError;

  /// 本地购物车：catalogItemId → 数量。**只有点「确认加项」才提交**，加减号不碰接口。
  final Map<String, int> _cart = <String, int>{};

  Timer? _timer;
  DateTime? _startAt;
  DateTime _now = DateTime.now();

  /// initState 里取一次（可缺省，不启动轮询：轮询由工作台一级页持引用）。
  PendingApprovalController? _pendingApproval;

  @override
  PendingApprovalController? get pendingApprovalController => _pendingApproval;

  /// 确认/拒绝会改本单金额与明细：静默重拉本单订单投影（不加项、不碰购物车）。
  @override
  void reloadOrderData() {
    if (widget.args?.orderId == null) return;
    _load(silent: true);
  }

  @override
  void initState() {
    super.initState();
    _pendingApproval = context.read<PendingApprovalController?>();
    // 客户待确认加项被确认/拒绝后，本页订单卡片上的金额立刻过期：监听信号重拉。
    bindOrderDataRevision();
    if (widget.args?.orderId == null) {
      _loading = false;
      _error = '缺少订单上下文，请从看板进入';
    } else {
      _load();
      _loadCatalog();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    unbindOrderDataRevision();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final order =
          await context.read<KtvApiClient>().getOrder(widget.args!.orderId!);
      if (!mounted) return;
      setState(() {
        _order = order;
        final sid = order.sessionId ?? widget.args?.sessionId;
        _session = sid == null
            ? null
            : KtvSession(
                id: sid,
                orderId: order.id,
                status: order.sessionStatus ?? 'RESERVED',
              );
        _startAt = _startTimeFor(order);
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // 静默重拉失败时保留屏幕上已有金额，只有确实没数据才把整页打成错误态。
        if (!silent || _order == null) _error = KtvApiClient.describeError(e);
      });
    }
  }

  DateTime _startTimeFor(KtvOrder order) {
    // 计时起点优先取会话 billingStartAt（服务端权威），否则退回订单创建时间做展示。
    final created = order.createdAt ?? DateTime.now();
    return _session?.billingStartAt ?? _session?.openedAt ?? created;
  }

  Future<void> _run(Future<void> Function(KtvApiClient c) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action(context.read<KtvApiClient>());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(KtvApiClient.describeError(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() {
    final sid = _session?.id;
    return _run((c) async {
      final s = await c.openSession(
        sid!,
        expectedVersion: _session?.expectedVersion,
      );
      if (mounted) {
        setState(() {
          _session = s;
          _startAt = s.billingStartAt ?? s.openedAt ?? _startAt;
        });
      }
    });
  }

  Future<void> _pause() {
    final sid = _session?.id;
    return _run((c) async {
      final s = await c.pauseSession(sid!,
          expectedVersion: _session?.expectedVersion);
      if (mounted) setState(() => _session = s);
    });
  }

  Future<void> _resume() {
    final sid = _session?.id;
    return _run((c) async {
      final s = await c.resumeSession(sid!,
          expectedVersion: _session?.expectedVersion);
      if (mounted) setState(() => _session = s);
    });
  }

  /// 拉取点单目录（含可用库存）。失败只提示，不阻塞计时/结台。
  Future<void> _loadCatalog() async {
    setState(() {
      _catalogLoading = true;
      _catalogError = null;
    });
    try {
      final items = await context.read<KtvApiClient>().listCatalog();
      if (!mounted) return;
      setState(() {
        _catalog = items;
        _catalogLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _catalogError = KtvApiClient.describeError(e);
        _catalogLoading = false;
      });
    }
  }

  int _cartQuantity(String catalogItemId) => _cart[catalogItemId] ?? 0;

  int get _cartTotalQuantity =>
      _cart.values.fold(0, (total, quantity) => total + quantity);

  /// 加号：只改本地购物车，**不提交**。上限取服务端可用库存（查库存防超卖）。
  void _increase(KtvCatalogItem item) {
    if (item.isSoldOut) {
      _snack('「' +
          item.name +
          '」' +
          (item.unavailableReason.isEmpty ? '当前不可点' : item.unavailableReason));
      return;
    }
    final current = _cartQuantity(item.id);
    if (!item.canIncrease(current)) {
      _snack('「' +
          item.name +
          '」可用库存仅 ' +
          item.stockText.replaceFirst('库存 ', '') +
          '，请先补货');
      return;
    }
    setState(() => _cart[item.id] = current + 1);
  }

  /// 减号：只改本地购物车（此前每点一次加号就已经把库存锁掉了，减号退不回来）。
  void _decrease(KtvCatalogItem item) {
    final current = _cartQuantity(item.id);
    if (current <= 0) return;
    setState(() {
      if (current == 1) {
        _cart.remove(item.id);
      } else {
        _cart[item.id] = current - 1;
      }
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// 确认加项：把购物车**一次**提交（服务端按目录项快照重算价格并原子扣库存），成功后清空购物车并刷新库存。
  Future<void> _submitCart() {
    final oid = _order?.id;
    final lines = _catalog
        .where((item) => _cartQuantity(item.id) > 0)
        .map((item) => <String, dynamic>{
              'catalogItemId': int.tryParse(item.id) ?? item.id,
              'quantity': _cartQuantity(item.id),
              'source': 'MERCHANT',
            })
        .toList(growable: false);
    if (oid == null || lines.isEmpty) return Future<void>.value();
    return _run((c) async {
      final o = await c.addItems(oid, lines,
          expectedVersion: _order?.expectedVersion);
      if (!mounted) return;
      setState(() {
        _order = o;
        _cart.clear();
      });
      _snack('已加 ' + lines.length.toString() + ' 项');
      await _loadCatalog();
    });
  }

  void _goSettle() {
    final order = _order;
    final session = _session;
    context.push(
      AppRoutes.ktvSettle,
      extra: KtvSessionArgs(
        orderId: order?.id ?? widget.args?.orderId,
        sessionId: session?.id ?? widget.args?.sessionId,
        roomId: order?.roomId ?? widget.args?.roomId,
        roomName: order?.roomName ?? widget.args?.roomName,
      ),
    );
  }

  String _clock() {
    final start = _startAt;
    if (start == null) return '--:--:--';
    final d = _now.difference(start);
    if (d.isNegative) return '00:00:00';
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h + ':' + m + ':' + s;
  }

  String get _statusText => _session?.statusText ?? '未知';

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

    final order = _order;
    final session = _session;
    final sessionStatus = (session?.status ?? '').toUpperCase();

    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(
        title: '计时加项',
        showBack: true,
        backgroundColor: pageBg,
        right: TextButton(
          onPressed: _busy ? null : _goSettle,
          child: const Text('结台'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && order == null
              ? _buildError(secondary)
              : ListView(
                  padding: const EdgeInsets.all(GvSpacing.page),
                  children: [
                    // 客户自助加项需要本单运营确认：在加项页最上方直接提醒。
                    GvPendingApprovalBanner(orderId: widget.args?.orderId),
                    if (order != null)
                      _orderCard(order, bgCard, border, primary, secondary),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: bgCard,
                        borderRadius: BorderRadius.circular(GvRadii.card),
                        border:
                            Border.all(color: border.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          Text('会话状态：' + _statusText,
                              style: GvTypography.caption(secondary)),
                          const SizedBox(height: 8),
                          Text(sessionStatus == 'OPEN' ? _clock() : '--:--:--',
                              style: GvTypography.headline(primary)),
                          const SizedBox(height: 4),
                          Text(
                            '包厢 ' +
                                (order?.roomName ??
                                    widget.args?.roomName ??
                                    '-') +
                                ' · 状态以服务端为准',
                            style: GvTypography.caption(secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _actionButtons(sessionStatus, accent),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('菜单（加减号只改数量，点「确认加项」才提交）',
                              style: GvTypography.title(primary)),
                        ),
                        TextButton(
                          onPressed: _catalogLoading ? null : _loadCatalog,
                          child: const Text('刷新'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_catalogLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_catalogError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('目录加载失败：' + _catalogError!,
                            style: GvTypography.caption(secondary)),
                      )
                    else if (_catalog.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('该门店暂无可点商品，请先在后台维护点单目录',
                            style: GvTypography.caption(secondary)),
                      )
                    else
                      ..._catalog.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: bgCard,
                              borderRadius: BorderRadius.circular(GvRadii.card),
                              border: Border.all(
                                  color: border.withValues(alpha: 0.4)),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(item.name,
                                              style:
                                                  GvTypography.body(primary)),
                                          if (item.isSoldOut) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                              item.unavailableReason.isEmpty
                                                  ? '不可点'
                                                  : item.unavailableReason,
                                              style: GvTypography.caption(
                                                  secondary),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.unitPrice.formatted +
                                            (item.unit.isEmpty
                                                ? ''
                                                : ' / ' + item.unit) +
                                            (item.stockText.isEmpty
                                                ? ''
                                                : ' · ' + item.stockText),
                                        style: GvTypography.caption(secondary),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: _busy || item.isSoldOut
                                      ? null
                                      : () => _decrease(item),
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 22),
                                  tooltip: '减少',
                                ),
                                SizedBox(
                                  width: 26,
                                  child: Text(
                                    _cartQuantity(item.id).toString(),
                                    textAlign: TextAlign.center,
                                    style: GvTypography.body(primary),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _busy || item.isSoldOut
                                      ? null
                                      : () => _increase(item),
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 22),
                                  tooltip: '增加',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 46,
                      child: FilledButton(
                        onPressed: _busy || _cartTotalQuantity == 0
                            ? null
                            : _submitCart,
                        style: FilledButton.styleFrom(backgroundColor: accent),
                        child: Text(_cartTotalQuantity == 0
                            ? '确认加项'
                            : '确认加项（' + _cartTotalQuantity.toString() + ' 件）'),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _orderCard(KtvOrder order, Color bgCard, Color border, Color primary,
      Color secondary) {
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
          Row(
            children: [
              Expanded(
                child: Text('订单 ' + order.orderNo,
                    style: GvTypography.title(primary)),
              ),
              // 金额只取服务端的「可直接展示总额」：liveTotalAmount 已含当前会话实时
              // 包厢费（结台后退回落库总额）。**绝不在总额上再加包厢费估算**——Web 后台
              // 曾这么加过，同一单账单 6150 / 卡片 10150，包厢费被算了两遍。
              Text(order.liveTotalAmount.formatted,
                  style: GvTypography.title(primary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '包厢 ' +
                (order.roomName ?? '-') +
                ' · 客户 ' +
                (order.customerMasked ?? '-'),
            style: GvTypography.caption(secondary),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(String sessionStatus, Color accent) {
    final buttons = <Widget>[];
    if (sessionStatus == 'RESERVED' || sessionStatus.isEmpty) {
      buttons.add(_actionButton('开台', accent, _busy ? null : _open));
    } else if (sessionStatus == 'OPEN') {
      buttons.add(_actionButton('暂停', accent, _busy ? null : _pause));
    } else if (sessionStatus == 'PAUSED') {
      buttons.add(_actionButton('恢复', accent, _busy ? null : _resume));
    }
    buttons.add(_actionButton('结台', accent, _busy ? null : _goSettle));
    return Row(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: buttons[i]),
        ],
      ],
    );
  }

  Widget _actionButton(String label, Color accent, VoidCallback? onTap) {
    return SizedBox(
      height: 46,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(backgroundColor: accent),
        child: Text(label),
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
