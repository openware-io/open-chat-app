import 'dart:async';

import 'package:flutter/widgets.dart';

import '../providers/pending_approval_provider.dart';

/// 「订单数据已被改动」信号（[PendingApprovalController.orderDataRevision]）的**消费侧**。
///
/// **为什么需要**：确认/拒绝一条待确认加项，改的不只是待确认清单，更是订单本身的
/// 金额与明细（确认后才计费、拒绝则回滚）。Web 后台踩过同一个坑：只有抽屉（清单）
/// 刷新了，看板/账单页各自持有的订单快照还是旧金额——「抽屉已确认、房态卡片仍是
/// 确认前的钱」，与账单/其它端对不上。A380 收银端同样是每页各持一份订单快照，
/// 所以每页都要在信号到来时**重拉自己**的数据。
///
/// 用法（[bindOrderDataRevision] / [unbindOrderDataRevision] 成对，放在
/// `initState` / `dispose` 里）：
/// - [pendingApprovalController]：本页读到的全局控制器；提醒态装配缺失时返回 null，
///   此时只是不监听，不影响收银主流程；
/// - [reloadOrderData]：调本页**既有的**加载方法（如 `_load()` / `_loadList()` /
///   `_loadDetail(id)`），不新开第二条数据路径，也**不轮询订单详情**。
///
/// 连点「本单全部确认」会连续抬多次版本号（逐条串行提交）：这里用 [_debounce]
/// 去抖合并成一次重拉，避免同一秒把详情/账单接口打上好几遍。
mixin OrderDataRevisionReload<T extends StatefulWidget> on State<T> {
  /// 合并连续信号的时间窗（远小于人眼可感知的等待，只用于合并同一次操作产生的多下）。
  static const Duration _debounce = Duration(milliseconds: 200);

  int _seenRevision = 0;
  Timer? _debounceTimer;

  /// 本页消费的待确认控制器（可缺省：装配缺失时不监听、不崩）。
  PendingApprovalController? get pendingApprovalController;

  /// 重拉本页自己的订单/账单/房态——必须是本页既有的加载方法。
  void reloadOrderData();

  /// 开始监听「订单数据已被改动」。
  void bindOrderDataRevision() {
    final controller = pendingApprovalController;
    _seenRevision = controller?.orderDataRevision ?? 0;
    controller?.orderDataChanged.addListener(_onOrderDataChanged);
  }

  /// 停止监听并取消待触发的重拉（页面 dispose 时必须调用，避免留下定时器）。
  void unbindOrderDataRevision() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _seenRevision = 0;
    pendingApprovalController?.orderDataChanged
        .removeListener(_onOrderDataChanged);
  }

  void _onOrderDataChanged() {
    final controller = pendingApprovalController;
    if (controller == null || !mounted) return;
    final revision = controller.orderDataRevision;
    // 轮询/角标变化不发这个信号；版本号没动就什么都不做（防无谓重拉）。
    if (revision == _seenRevision) return;
    _seenRevision = revision;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (!mounted) return;
      reloadOrderData();
    });
  }
}
