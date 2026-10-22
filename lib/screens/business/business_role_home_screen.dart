import 'package:flutter/material.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../widgets/open_nav_bar.dart';

/// 移动端角色工作台原型：与 Web 端使用同一套“角色 → 工作区 → 任务”语义。
///
/// 数据为本地 mock；正式接入后由登录角色和 BFF 返回任务列表。
class BusinessRoleHomeScreen extends StatefulWidget {
  const BusinessRoleHomeScreen({super.key});

  @override
  State<BusinessRoleHomeScreen> createState() => _BusinessRoleHomeScreenState();
}

class _BusinessRoleHomeScreenState extends State<BusinessRoleHomeScreen> {
  String _role = 'manager';

  static const _roles = <({String key, String label, String hint})>[
    (key: 'manager', label: '店长', hint: '经营与异常'),
    (key: 'frontdesk', label: '前台', hint: '入住与退房'),
    (key: 'cashier', label: '收银', hint: '收款与结账'),
  ];

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
          Text('OpenChat 生活服务 / 西湖店', style: GvTypography.title(primary)),
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
    switch (role) {
      case 'frontdesk':
        return const [
          _Task('待入住', '王先生 · 1208', '12:30', '高', Icons.login),
          _Task('待退房', '周女士 · 0806', '13:00', '高', Icons.logout),
          _Task('待收款', '李女士 · 1506', '14:20', '中', Icons.payments_outlined),
        ];
      case 'cashier':
        return const [
          _Task('待结账', 'A05 · 包厢', '¥428', '高', Icons.receipt_long),
          _Task('待退款', '订单 H20261022', '¥120', '中', Icons.undo),
          _Task('交班盘点', '早班 · 小票', '15:30', '中', Icons.point_of_sale),
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
      'cashier' => const [('待结账', '4'), ('待退款', '2'), ('当班营收', '¥18.6k')],
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
