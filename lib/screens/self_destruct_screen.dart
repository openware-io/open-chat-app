import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_toast.dart';
import '../services/api_client.dart';
import '../services/im_api.dart';
import '../widgets/gv_nav_bar.dart';

/// 聊天记录自动清理策略子页：off / 1mo / 3mo / 6mo / 1yr 五选一。
/// 注意：该策略只清除聊天记录，不会注销账号（账号仍可正常登录）。
///
/// 进入时 `GET /users/me/self-destruct` 拉取当前值，选择后
/// `PUT /users/me/self-destruct` 保存并 toast。
class SelfDestructScreen extends StatefulWidget {
  const SelfDestructScreen({super.key});

  @override
  State<SelfDestructScreen> createState() => _SelfDestructScreenState();
}

class _SelfDestructScreenState extends State<SelfDestructScreen> {
  static const List<String> _policies = [
    'off',
    '1mo',
    '3mo',
    '6mo',
    '1yr',
  ];

  String _policy = 'off';
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ImApi>();
      final s = await api.getSelfDestructPolicy();
      if (!mounted) return;
      setState(() => _policy = s.policy);
    } catch (_) {
      // 读取失败保持默认（off）。
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _select(String policy) async {
    if (_updating || policy == _policy) return;
    setState(() => _updating = true);
    try {
      final api = context.read<ImApi>();
      final s = await api.updateSelfDestructPolicy(policy: policy);
      if (!mounted) return;
      setState(() => _policy = s.policy);
      GvToast.show(
        context,
        AppLocalizations.of(context)!.selfDestructUpdated,
      );
    } catch (e) {
      if (mounted) {
        GvToast.show(
          context,
          context.read<ApiClient>().extractErrorMessage(e),
        );
        await _load();
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  String _labelFor(AppLocalizations l10n, String policy) {
    switch (policy) {
      case 'off':
        return l10n.selfDestructOff;
      case '1mo':
        return l10n.selfDestruct1mo;
      case '3mo':
        return l10n.selfDestruct3mo;
      case '6mo':
        return l10n.selfDestruct6mo;
      case '1yr':
        return l10n.selfDestruct1yr;
      default:
        return l10n.selfDestructOff;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.primary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final hint = AppColors.textHint.resolveFrom(context);
    final hover = AppColors.textPrimary
        .resolveFrom(context)
        .withValues(alpha: 0.06);
    final divider = Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.textHint
          .resolveFrom(context)
          .withValues(alpha: 0.22),
    );

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.selfDestructTitle, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                l10n.selfDestructHint,
                style: GvTypography.caption(hint),
              ),
            ),
            GvCardShell(
              borderRadius: BorderRadius.circular(GvRadii.card),
              child: Material(
                color: AppColors.bgWhite.resolveFrom(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < _policies.length; i++) ...[
                      if (i > 0) divider,
                      _row(
                        policy: _policies[i],
                        label: _labelFor(l10n, _policies[i]),
                        selected: _policy == _policies[i],
                        enabled: !_loading && !_updating,
                        primary: primary,
                        secondary: secondary,
                        hover: hover,
                        borderRadius: BorderRadius.vertical(
                          top: i == 0
                              ? const Radius.circular(GvRadii.card)
                              : Radius.zero,
                          bottom: i == _policies.length - 1
                              ? const Radius.circular(GvRadii.card)
                              : Radius.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row({
    required String policy,
    required String label,
    required bool selected,
    required bool enabled,
    required Color primary,
    required Color secondary,
    required Color hover,
    required BorderRadius borderRadius,
  }) {
    return GvActionRow(
      title: label,
      titleStyle: GvTypography.navTitle(
        AppColors.textPrimary.resolveFrom(context),
      ),
      leading: Icon(
        policy == 'off' ? LucideIcons.timer_off : LucideIcons.timer,
        size: 22,
        color: secondary,
      ),
      trailing: selected
          ? Icon(LucideIcons.check, size: 20, color: primary)
          : null,
      onTap: enabled && !selected ? () => unawaited(_select(policy)) : null,
      borderRadius: borderRadius,
      hoverColor: hover,
      highlightColor: hover,
      splashColor: AppColors.textPrimary
          .resolveFrom(context)
          .withValues(alpha: 0.10),
    );
  }
}
