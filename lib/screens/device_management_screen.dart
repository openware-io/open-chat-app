import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_toast.dart';
import '../models/device_session.dart';
import '../services/api_client.dart';
import '../services/im_api.dart';
import '../widgets/open_nav_bar.dart';

/// 登录设备管理：展示多端登录会话（登录方式 / 登录 IP / 设备 / 最后活跃时间），
/// 支持主设备踢出副设备、副设备主动退出（参考百度网盘登录账号管理）。
class DeviceManagementScreen extends StatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  State<DeviceManagementScreen> createState() => _DeviceManagementScreenState();
}

class _DeviceManagementScreenState extends State<DeviceManagementScreen> {
  List<DeviceSession>? _devices;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await context.read<ImApi>().listDevices();
      if (!mounted) return;
      setState(() {
        _devices = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      GvToast.show(context, AppLocalizations.of(context)!.gvFaDeviceLoadFailed);
    }
  }

  String _methodLabel(AppLocalizations l10n, String? method) {
    switch (method) {
      case 'qr_code':
        return l10n.gvFaLoginMethodQrCode;
      case 'sso':
        return l10n.gvFaLoginMethodSso;
      case 'verification_code':
        return l10n.gvFaLoginMethodVerificationCode;
      default:
        return l10n.gvFaLoginMethodPassword;
    }
  }

  String _statusLabel(AppLocalizations l10n, String? status) {
    switch (status) {
      case 'kicked':
        return l10n.gvFaDeviceStatusKicked;
      case 'logout':
        return l10n.gvFaDeviceStatusLogout;
      default:
        return l10n.gvFaDeviceStatusActive;
    }
  }

  Future<void> _kick(DeviceSession d) async {
    final l10n = AppLocalizations.of(context)!;
    final api = context.read<ImApi>();
    final client = context.read<ApiClient>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l10n.gvFaDeviceKickConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l10n.commonConfirm)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.kickDevice(d.deviceId);
      await _load();
    } catch (e) {
      if (mounted) {
        GvToast.show(context, client.extractErrorMessage(e));
      }
    }
  }

  Future<void> _logout(DeviceSession d) async {
    final l10n = AppLocalizations.of(context)!;
    final api = context.read<ImApi>();
    final client = context.read<ApiClient>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text(l10n.gvFaDeviceLogoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text(l10n.commonCancel)),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(l10n.commonConfirm)),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.logoutDevice(d.deviceId);
      await _load();
    } catch (e) {
      if (mounted) {
        GvToast.show(context, client.extractErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.gvFaDeviceManagementTitle, showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_devices == null || _devices!.isEmpty)
              ? Center(child: Text(l10n.gvFaDeviceEmpty))
              : ListView.separated(
                  padding: const EdgeInsets.all(GvSpacing.page),
                  itemCount: _devices!.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: GvSpacing.sm),
                  itemBuilder: (_, i) => _tile(context, _devices![i], l10n),
                ),
    );
  }

  Widget _tile(BuildContext context, DeviceSession d, AppLocalizations l10n) {
    final name = d.deviceName?.isNotEmpty == true
        ? d.deviceName!
        : (d.deviceType?.isNotEmpty == true ? d.deviceType! : d.deviceId);
    final time = d.lastActiveAt?.toLocal();
    final timeText = time == null
        ? ''
        : time.year.toString() +
            '-' +
            time.month.toString().padLeft(2, '0') +
            '-' +
            time.day.toString().padLeft(2, '0') +
            ' ' +
            time.hour.toString().padLeft(2, '0') +
            ':' +
            time.minute.toString().padLeft(2, '0');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text(_statusLabel(l10n, d.status),
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            Text(l10n.gvFaDeviceLoginMethod(_methodLabel(l10n, d.loginMethod))),
            if ((d.loginIp ?? '').isNotEmpty)
              Text(l10n.gvFaDeviceLoginIp(d.loginIp!)),
            if (timeText.isNotEmpty)
              Text(l10n.gvFaDeviceLastActive(timeText)),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                    onPressed: () => _logout(d),
                    child: Text(l10n.gvFaDeviceLogout)),
                const SizedBox(width: 8),
                TextButton(
                    onPressed: () => _kick(d),
                    child: Text(l10n.gvFaDeviceKick)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
