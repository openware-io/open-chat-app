import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_automation_keys.dart';
import '../services/im_api.dart';
import '../widgets/open_nav_bar.dart';

/// 离线推送通知设置子页：私聊/群聊/频道三类分别开关。
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notifyPrivate = true;
  bool _notifyGroup = true;
  bool _notifyChannel = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ImApi>();
      final s = await api.getNotificationSettings();
      if (!mounted) return;
      setState(() {
        _notifyPrivate = s.notifyPrivate;
        _notifyGroup = s.notifyGroup;
        _notifyChannel = s.notifyChannel;
      });
    } catch (_) {}
  }

  Future<void> _update({
    bool? notifyPrivate,
    bool? notifyGroup,
    bool? notifyChannel,
  }) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      final api = context.read<ImApi>();
      final s = await api.updateNotificationSettings(
        notifyPrivate: notifyPrivate ?? _notifyPrivate,
        notifyGroup: notifyGroup ?? _notifyGroup,
        notifyChannel: notifyChannel ?? _notifyChannel,
      );
      if (!mounted) return;
      setState(() {
        _notifyPrivate = s.notifyPrivate;
        _notifyGroup = s.notifyGroup;
        _notifyChannel = s.notifyChannel;
      });
    } catch (_) {
      if (mounted) await _load();
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Widget _row(
    BuildContext context, {
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final hover =
        AppColors.textPrimary.resolveFrom(context).withValues(alpha: 0.06);
    return GvActionRow(
      title: title,
      titleStyle: GvTypography.navTitle(
        AppColors.textPrimary.resolveFrom(context),
      ),
      leading: Icon(
        LucideIcons.bell,
        size: 22,
        color: AppColors.textSecondary.resolveFrom(context),
      ),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      onTap: onChanged == null ? null : () => onChanged(!value),
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(GvRadii.card),
      ),
      hoverColor: hover,
      highlightColor: hover,
      splashColor:
          AppColors.textPrimary.resolveFrom(context).withValues(alpha: 0.10),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final divider = Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.textHint.resolveFrom(context).withValues(alpha: 0.22),
    );
    return Scaffold(
      key: GvAutomationKeys.notificationSettingsScreen,
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.settingsNotifyDetail, showBack: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: GvCardShell(
          borderRadius: BorderRadius.circular(GvRadii.card),
          child: Material(
            color: AppColors.bgWhite.resolveFrom(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _row(
                  context,
                  title: l10n.settingsNotifyPrivate,
                  value: _notifyPrivate,
                  onChanged: _updating
                      ? null
                      : (v) => unawaited(_update(notifyPrivate: v)),
                ),
                divider,
                _row(
                  context,
                  title: l10n.settingsNotifyGroup,
                  value: _notifyGroup,
                  onChanged: _updating
                      ? null
                      : (v) => unawaited(_update(notifyGroup: v)),
                ),
                divider,
                _row(
                  context,
                  title: l10n.settingsNotifyChannel,
                  value: _notifyChannel,
                  onChanged: _updating
                      ? null
                      : (v) => unawaited(_update(notifyChannel: v)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
