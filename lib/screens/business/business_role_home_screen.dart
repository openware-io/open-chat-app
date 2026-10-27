import 'package:flutter/material.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../core/currency.dart' show formatMoney;
import '../../repositories/business/admin_api_client.dart';
import '../../widgets/open_nav_bar.dart';

/// 移动端角色工作台：登录角色决定初始工作台，酒店任务优先读取 BFF，失败回退 mock。
class BusinessRoleHomeScreen extends StatefulWidget {
  const BusinessRoleHomeScreen({super.key});

  @override
  State<BusinessRoleHomeScreen> createState() => _BusinessRoleHomeScreenState();
}

class _BusinessRoleHomeScreenState extends State<BusinessRoleHomeScreen> {
  late String _role;
  List<_Task>? _remoteTasks;

  static const _roles = <({String key, String label, String hint})>[
    (key: 'manager', label: '店长', hint: '经营与异常'),
    (key: 'frontdesk', label: '前台', hint: '入住与退房'),
    (key: 'cashier', label: '收银', hint: '收款与结账'),
  ];

  @override
  void initState() {
    super.initState();
    _role = AdminApiClient.instance.role ?? 'manager';
    _loadRemoteTasks();
  }

  Future<void> _loadRemoteTasks() async {
    try {
      final rows = await AdminApiClient.instance.hotelTasks();
      if (!mounted || rows.isEmpty) return;
      setState(() {
        _remoteTasks = rows.map((row) {
          final status = row['status'] as String? ?? '';
          final label = switch (status) {
            'ARRIVAL' => '待入住',
            'DUE_OUT' => '待退房',
            'IN_HOUSE' => '在住',
            _ => status,
          };
          return _Task(
            label,
            '${row['guestName'] ?? ''} · ${row['roomNo'] ?? ''}',
            row['checkInDate'] as String? ?? '',
            status == 'DUE_OUT' ? '高' : '中',
            status == 'ARRIVAL' ? Icons.login : Icons.meeting_room_outlined,
          );
        }).toList();
      });
    } catch (_) {
      // 原型回退：未登录/网络不可用时保留本地任务。
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageBg = gvPageScaffoldBackground(context);
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: GvNavBar(title: '角色工作台', backgroundColor: pageBg),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          GvSpacing.page,
          GvSpacing.sm,
          GvSpacing.page,
          GvSpacing.lg,
        ),
        children: [
          Text('当前工作区', style: GvTypography.caption(secondary)),
          const SizedBox(height: 4),
          Text(
            AdminApiClient.instance.storeName == null
                ? '本地原型门店'
                : 'SaaS 生活服务 / ${AdminApiClient.instance.storeName}',
            style: GvTypography.title(primary),
          ),
          const SizedBox(height: GvSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in _roles)
                ChoiceChip(
                  label: Text('${role.label} · ${role.hint}'),
                  selected: _role == role.key,
                  onSelected: (_) => setState(() => _role = role.key),
                ),
            ],
          ),
          const SizedBox(height: GvSpacing.lg),
          _RoleMetricGrid(role: _role),
          const SizedBox(height: GvSpacing.lg),
          Text(
            _role == 'manager'
                ? '今日经营'
                : _role == 'frontdesk'
                    ? '前台任务'
                    : '收银任务',
            style: GvTypography.title(primary)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: GvSpacing.sm),
          for (final task in _tasksFor(_role))
            Padding(
              padding: const EdgeInsets.only(bottom: GvSpacing.sm),
              child: _TaskCard(task: task),
            ),
          const SizedBox(height: GvSpacing.lg),
          Text(
            '角色由登录账号决定；这里仅用于验证移动端任务首页。无权限模块不会出现在工作台。',
            style: GvTypography.small(secondary),
          ),
        ],
      ),
    );
  }

  List<_Task> _tasksFor(String role) {
    if (_remoteTasks != null && role != 'cashier') return _remoteTasks!;
    switch (role) {
      case 'frontdesk':
        return const [
          _Task('待入住', '王先生 · 1208', '12:30', '高', Icons.login),
          _Task('待退房', '周女士 · 0806', '13:00', '高', Icons.logout),
          _Task('待收款', '李女士 · 1506', '14:20', '中', Icons.payments_outlined),
        ];
      case 'cashier':
        // 金额只走 lib/core/currency.dart 的唯一格式化入口（最小单位 + 租户币种），
        // 这里不得硬编码币种符号：currency_source_guard_test 会拦。
        return [
          _Task('待结账', 'A05 · 包厢', formatMoney(42800), '高',
              Icons.receipt_long),
          _Task('待退款', '订单 H20261022', formatMoney(12000), '中', Icons.undo),
          const _Task('交班盘点', '早班 · 小票', '15:30', '中',
              Icons.point_of_sale),
        ];
      default:
        return const [
          _Task('今日到店', '18 位客人', '10:00', '中', Icons.event_available),
          _Task('待退房', '12 间客房', '12:00', '高', Icons.meeting_room_outlined),
          _Task('房态异常', '1205 维修', '持续', '中', Icons.build_outlined),
        ];
    }
  }
}

class _RoleMetricGrid extends StatelessWidget {
  const _RoleMetricGrid({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final metrics = switch (role) {
      'frontdesk' => const [('待入住', '8'), ('待退房', '5'), ('待收款', '3')],
      'cashier' => [
          ('待结账', '4'),
          ('待退款', '2'),
          ('当班营收', formatMoney(1860000)),
        ],
      _ => const [('今日到店', '18'), ('在住', '76'), ('出租率', '82%')],
    };
    return Row(
      children: [
        for (final metric in metrics)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgWhite.resolveFrom(context),
                borderRadius: BorderRadius.circular(GvRadii.card),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.$1,
                      style: GvTypography.caption(
                          AppColors.textSecondary.resolveFrom(context))),
                  const SizedBox(height: 4),
                  Text(metric.$2,
                      style: GvTypography.title(
                          AppColors.textPrimary.resolveFrom(context))),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final _Task task;

  @override
  Widget build(BuildContext context) {
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgWhite.resolveFrom(context),
        borderRadius: BorderRadius.circular(GvRadii.card),
      ),
      child: Row(
        children: [
          Icon(task.icon, color: AppColors.primary.resolveFrom(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: GvTypography.body(primary)
                        .copyWith(fontWeight: FontWeight.w700)),
                Text(task.detail, style: GvTypography.small(secondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(task.time, style: GvTypography.small(secondary)),
              Text(task.priority,
                  style: GvTypography.small(
                      AppColors.danger.resolveFrom(context))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Task {
  const _Task(this.title, this.detail, this.time, this.priority, this.icon);

  final String title;
  final String detail;
  final String time;
  final String priority;
  final IconData icon;
}
