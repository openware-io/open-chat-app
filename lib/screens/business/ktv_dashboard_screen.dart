import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;
import 'package:provider/provider.dart';

import '../../app/app_routes.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/order_data_revision_reload.dart';
import '../../models/ktv_models.dart';
import '../../providers/pending_approval_provider.dart';
import '../../repositories/business/ktv_api_client.dart';
import '../../widgets/open_pending_approval_banner.dart';
import '../../widgets/open_nav_bar.dart';
import 'ktv_bottom_nav.dart';

/// KTV 包厢看板：数据来自 GET /api/v1/business/resources（KTV_ROOM）+ 会话状态投影。
/// 点击包厢：可用→快速开台；使用中→进入会话；已预订/不可用→提示。
class KtvDashboardScreen extends StatefulWidget {
  const KtvDashboardScreen({super.key});

  @override
  State<KtvDashboardScreen> createState() => _KtvDashboardScreenState();
}

class _KtvDashboardScreenState extends State<KtvDashboardScreen>
    with OrderDataRevisionReload<KtvDashboardScreen> {
  List<KtvRoom> _rooms = const [];
  bool _loading = true;
  String? _error;

  /// initState 里取一次：dispose 阶段再用 `context.read` 有被卸载后取不到的风险。
  PendingApprovalController? _pendingApproval;

  @override
  PendingApprovalController? get pendingApprovalController => _pendingApproval;

  @override
  void reloadOrderData() => _load(silent: true);

  @override
  void initState() {
    super.initState();
    // 看板是 KTV 工作台的入口：在这里开启客户待确认加项的轮询（引用计数）。
    // 可缺省：提醒态装配缺失不应让看板崩掉（生产装配见 app_dependencies.dart）。
    _pendingApproval = context.read<PendingApprovalController?>()?..start();
    // 确认/拒绝待确认加项会改订单（金额/明细），房态投影也随之变化：
    // 监听「订单数据已被改动」信号，静默重拉本页的包厢看板（看板数据不是清单）。
    bindOrderDataRevision();
    _load();
  }

  @override
  void dispose() {
    unbindOrderDataRevision();
    _pendingApproval?.stop();
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
      final rooms = await context.read<KtvApiClient>().getRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // 静默重拉失败时保留屏幕上已有的房态，只有确实没数据才把整页打成错误态。
        if (!silent || _rooms.isEmpty) _error = KtvApiClient.describeError(e);
      });
    }
  }

  void _onRoomTap(KtvRoom room) {
    final status = room.boardStatus.toUpperCase();
    if (status == 'RESERVED') {
      _toast(room.name + ' 已预订，请到预约流程处理');
      return;
    }
    if (room.isAvailable) {
      context.push(
        AppRoutes.ktvQuickOpen,
        extra: KtvSessionArgs(roomId: room.id, roomName: room.name),
      );
      return;
    }
    if (room.isBusy) {
      context.push(
        AppRoutes.ktvTiming,
        extra: KtvSessionArgs(
          orderId: room.orderId,
          sessionId: room.sessionId,
          roomId: room.id,
          roomName: room.name,
        ),
      );
      return;
    }
    _toast(room.name + ' 不可用');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg)));
  }

  (String, Color) _statusOf(KtvRoom room) {
    switch (room.boardStatus.toUpperCase()) {
      case 'IN_USE':
      case 'OPEN':
      case 'PAUSED':
        return ('使用中', AppColors.primary.resolveFrom(context));
      case 'RESERVED':
        return ('已预订', Colors.orange);
      case 'UNAVAILABLE':
      case 'DISABLED':
      case 'MAINTENANCE':
        return ('不可用', AppColors.textHint.resolveFrom(context));
      default:
        return ('可用', AppColors.success.resolveFrom(context));
    }
  }

  Widget _roomCard(KtvRoom room) {
    final bgCard = AppColors.bgWhite.resolveFrom(context);
    final primary = AppColors.textPrimary.resolveFrom(context);
    final border = AppColors.border.resolveFrom(context);
    final (label, color) = _statusOf(room);

    return Material(
      color: bgCard,
      borderRadius: BorderRadius.circular(GvRadii.card),
      child: InkWell(
        onTap: () => _onRoomTap(room),
        borderRadius: BorderRadius.circular(GvRadii.card),
        child: Container(
          decoration: BoxDecoration(
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
                    child: Text(room.name, style: GvTypography.title(primary)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(label, style: GvTypography.small(color)),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                room.isBusy
                    ? Icons.timer_outlined
                    : Icons.meeting_room_outlined,
                color: AppColors.textHint.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = gvPageScaffoldBackground(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(
        title: '包厢看板',
        backgroundColor: pageBg,
        right: TextButton(
          onPressed: () => context.push(AppRoutes.ktvQuickOpen),
          child: const Text('开台'),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary.resolveFrom(context),
        onRefresh: _load,
        child: Column(
          children: [
            if (context.watch<PendingApprovalController?>()?.hasPending ??
                false)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                    GvSpacing.page, GvSpacing.page, GvSpacing.page, 0),
                child: GvPendingApprovalBanner(margin: EdgeInsets.zero),
              ),
            Expanded(child: _buildBody(pageBg, secondary)),
          ],
        ),
      ),
      bottomNavigationBar: const KtvBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBody(Color pageBg, Color secondary) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(GvSpacing.page),
              child: Column(
                children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  OutlinedButton(onPressed: _load, child: const Text('重试')),
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (_rooms.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120),
          Center(
            child: Text('暂无包厢', style: GvTypography.body(secondary)),
          ),
        ],
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(GvSpacing.page),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: _rooms.length,
      itemBuilder: (context, index) => _roomCard(_rooms[index]),
    );
  }
}
