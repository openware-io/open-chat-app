import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api_failure.dart';
import '../models/ktv_models.dart';
import '../repositories/business/ktv_api_client.dart';

/// 一次确认/拒绝操作的结果，供界面决定提示文案。
enum PendingApprovalAction {
  /// 本次操作生效。
  success,

  /// 409：同一条明细已被其他人（另一台设备/另一个收银员）处理，已收敛为服务端最新快照。
  alreadyHandled,

  /// 其它失败（网络/权限/服务端错误），已把文案放到 [PendingApprovalController.error]。
  failed,
}

/// 客户自助加项「待确认」的全局提醒状态（B 端 / A380 收银端）。
///
/// 与后台端（gv_saas_admin）同一口径、同一数据源：`GET /business/orders/pending-approval`。
///
/// 实时性与一致性：
/// - **轮询 15s**（[pollInterval]），页面在后台（[setForeground] = false）时暂停，回到前台立即补拉；
/// - 服务端返回 `revision`（本门店命中行最大明细 id）：未变化视为同一快照，不重渲染（防角标闪烁）；
/// - 确认/拒绝成功后**乐观移除**，随后静默拉一次服务端快照 —— 本地计数永远不是权威；
/// - 并发输的一方（409）不当作失败：提示「已被处理」并按服务端刷新；
/// - 缓存/轮询只影响角标数字，**永不参与业务判定**（金额仍由服务端算、状态仍由服务端裁决）；
/// - 确认/拒绝还会改**订单本身**的数据（应收/明细/房态卡片），所以本控制器额外对外发出
///   一个「订单数据已被改动」信号 [orderDataRevision]：各订单页面监听它重拉**自己**的数据。
class PendingApprovalController extends ChangeNotifier {
  PendingApprovalController(
    this._api, {
    this.pollInterval = const Duration(milliseconds: pollIntervalMs),
  });

  /// 与服务端读缓存 TTL（默认 3s）和后台端保持一致的轮询间隔。
  static const int pollIntervalMs = 15000;

  final KtvApiClient _api;
  final Duration pollInterval;

  KtvPendingApprovalView _view = KtvPendingApprovalView.empty;
  bool _loading = false;
  bool _refreshing = false;
  bool _started = false;
  int _holders = 0;
  bool _inForeground = true;
  String? _error;
  String? _notice;
  Timer? _timer;

  /// 「订单数据已被改动」信号：一次确认/拒绝/本单全部确认**真的改了服务端状态**后 +1。
  ///
  /// **为什么要有它**：确认/拒绝改的不只是「待确认清单」，更是**订单本身**——
  /// 确认后才计费（应收变大、明细多一行）、拒绝则回滚库存。Web 后台已经踩过这个坑：
  /// 抽屉（待确认列表）自己刷新了，看板/账单页各自持有的订单快照却还是旧金额，
  /// 于是「抽屉里已确认，房态卡片仍是确认前的钱」，与账单/其它端对不上。
  /// A380 收银端同一形状：看板房态卡片、收银列表/组合收款、计时加项页、结台账单
  /// 都各持一份订单快照，光刷新清单并不会让它们变。
  ///
  /// 所以这里暴露一个**单调递增的版本号**，由各订单页面监听后重拉自己的数据
  /// （见 `lib/core/order_data_revision_reload.dart`）。
  ///
  /// 只在服务端状态真的变了时才前进：
  /// - 操作成功 → 前进；
  /// - 409（同一条已被别人处理）→ **也前进**：服务端已变、本地快照必然过期，必须重拉；
  /// - 其它失败（网络/权限/服务端错误）→ **不前进**：服务端没变，不该让各页白跑一次接口；
  /// - 只读的 [refresh]（含 15s 轮询）→ 不前进：拉快照不是改数据，否则轮询会每 15s
  ///   把全工作台的重拉都触发一遍。
  ///
  /// 生命周期与轮询一致：离开工作台（[stop] 的引用计数归零）或 [reset]（退出登录）归零，
  /// 下次进入重新计数；仍有页面持有时不归零——那只是切页瞬间的释放。
  final ValueNotifier<int> _orderDataRevision = ValueNotifier<int>(0);

  /// 「订单数据已被改动」的版本号（只读；监听请在 [orderDataChanged] 上注册）。
  int get orderDataRevision => _orderDataRevision.value;

  /// [orderDataRevision] 的可监听形态：各订单页面 `addListener` 后重拉自己的
  /// 订单/账单/房态（**不新开数据路径、不轮询订单详情**）。
  ValueListenable<int> get orderDataChanged => _orderDataRevision;

  KtvPendingApprovalView get view => _view;
  int get pendingCount => _view.pendingCount;
  bool get hasPending => _view.hasPending;
  bool get loading => _loading;
  String? get error => _error;
  String? get notice => _notice;

  /// 是否正在轮询（引用计数归零后为 false）。仅用于测试与调试断言。
  @visibleForTesting
  bool get isPolling => _started;

  /// 某订单的待确认条数（0 表示该单没有待确认加项）。
  int countOfOrder(String orderId) => _view.pendingCountOf(orderId);

  KtvPendingOrder? orderOf(String orderId) => _view.orderOf(orderId);

  /// 开始轮询并立即拉一次。
  ///
  /// 采用**引用计数**：工作台三个一级页（看板/收银/交班）都会 `start()`，
  /// 页面切换时旧页 `dispose` 会 `stop()`——若只按布尔量管理，切页瞬间就会把
  /// 新页刚启动的轮询一起关掉。计数归零才真正停止。
  void start() {
    _holders += 1;
    if (_started) return;
    _started = true;
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) {
      if (_inForeground) unawaited(refresh(silent: true));
    });
    unawaited(refresh());
  }

  /// 释放一个持有者；仍有其它页面持有时不停（见 [start]）。
  void stop() {
    if (_holders > 0) _holders -= 1;
    if (_holders > 0) return;
    _started = false;
    _timer?.cancel();
    _timer = null;
    // 引用计数归零 = 离开工作台：信号随轮询一起归零（下次进入重新计数）。
    // 仍有页面持有时**不**归零：那只是切页瞬间的释放，归零会让仍在栈上的页面
    // 把「旧快照」当成「发生过改动」，白重拉一次。
    _orderDataRevision.value = 0;
  }

  /// 前后台切换：后台暂停轮询，回前台立即补拉一次（回到柜台第一眼就是最新数字）。
  void setForeground(bool foreground) {
    if (_inForeground == foreground) return;
    _inForeground = foreground;
    if (foreground && _started) unawaited(refresh(silent: true));
  }

  /// 退出登录时清空（不留上一位收银员的角标；订单改动信号也随 [stop] 归零）。
  void reset() {
    _holders = 0;
    stop();
    _view = KtvPendingApprovalView.empty;
    _error = null;
    _notice = null;
    _loading = false;
    notifyListeners();
  }

  void clearNotice() {
    if (_notice == null) return;
    _notice = null;
    notifyListeners();
  }

  /// 拉取聚合视图。[silent] 为 true 时不切换整页 loading（轮询用）。
  Future<void> refresh({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    var changed = false;
    if (!silent && !_loading) {
      _loading = true;
      changed = true;
    }
    if (changed) notifyListeners();
    try {
      final next = await _api.getPendingApproval();
      // revision + 条数都不变 = 同一快照：更新本地对象但仍不触发重渲染。
      final sameSnapshot = next.revision == _view.revision &&
          next.pendingCount == _view.pendingCount &&
          next.orders.length == _view.orders.length;
      _view = next;
      if (!sameSnapshot) changed = true;
      if (_error != null) {
        _error = null;
        changed = true;
      }
    } catch (e) {
      final message = KtvApiClient.describeError(e);
      if (_error != message) {
        _error = message;
        changed = true;
      }
    } finally {
      _refreshing = false;
      if (_loading) {
        _loading = false;
        changed = true;
      }
      if (changed) notifyListeners();
    }
  }

  /// 确认一条客户自助加项。
  Future<PendingApprovalAction> confirm(String orderId, String itemId) =>
      _act(() => _api.confirmPendingItem(orderId, itemId), itemId);

  /// 拒绝一条客户自助加项。
  Future<PendingApprovalAction> reject(String orderId, String itemId) =>
      _act(() => _api.rejectPendingItem(orderId, itemId), itemId);

  /// 「本单全部确认」：逐条串行提交（并发提交同一条会在服务端互相打架），
  /// 已失效的条目按 409 收敛，返回真正生效的条数。
  Future<int> confirmOrder(String orderId) async {
    final target = _view.orderOf(orderId);
    if (target == null || target.items.isEmpty) return 0;
    var done = 0;
    for (final item in target.items) {
      final result = await confirm(orderId, item.id);
      if (result == PendingApprovalAction.success) done += 1;
    }
    await refresh(silent: true);
    return done;
  }

  Future<PendingApprovalAction> _act(
    Future<void> Function() submit,
    String itemId,
  ) async {
    try {
      await submit();
      // 服务端状态真的变了：抬版本号，让看板/收银/计时/结台账各页重拉自己的订单数据。
      _orderDataRevision.value += 1;
      // 乐观移除：角标立刻收敛；随后仍以服务端快照为准（本地计数不是权威）。
      final next = _view.withoutItem(itemId);
      if (!identical(next, _view)) {
        _view = next;
      }
      _error = null;
      notifyListeners();
      unawaited(refresh(silent: true));
      return PendingApprovalAction.success;
    } catch (e) {
      if (_statusCodeOf(e) == 409) {
        // 并发输家：明细已被别人处理，不报错，按服务端刷新即可。
        // 这也是「服务端已改动」：本地各页的订单快照必然过期，同样要抬版本号重拉，
        // 否则收银员会对着别人处理前的旧金额收款。
        _orderDataRevision.value += 1;
        _notice = '该加项已被处理，已刷新为最新状态';
        _error = null;
        notifyListeners();
        unawaited(refresh(silent: true));
        return PendingApprovalAction.alreadyHandled;
      }
      _error = KtvApiClient.describeError(e);
      notifyListeners();
      return PendingApprovalAction.failed;
    }
  }

  int? _statusCodeOf(Object error) {
    if (error is ApiFailure) return error.statusCode;
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiFailure) return inner.statusCode;
      return error.response?.statusCode;
    }
    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _orderDataRevision.dispose();
    super.dispose();
  }
}
