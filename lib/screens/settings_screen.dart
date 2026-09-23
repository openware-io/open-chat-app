import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../app/app_routes.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/legal_urls.dart';
import '../core/gv_app_update_platform.dart';
import '../core/gv_root_navigator.dart';
import '../core/gv_secondary_navigation.dart';
import '../core/gv_toast.dart';
import '../core/gv_automation_keys.dart';
import '../models/client_release_models.dart';
import '../providers/app_locale_provider.dart';
import '../providers/app_theme_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/client_release_coordinator.dart';
import '../repositories/client_release_repository.dart';
import '../core/local_storage.dart';
import '../services/api_client.dart';
import '../services/push_notification_service.dart';
import '../widgets/gv_dialog_actions.dart';
import '../widgets/gv_nav_bar.dart';
import 'protocol_webview_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const bool _showUpdateCheck = true;

  /// 设置页卡片相对屏幕的左右边距（与全局 [GvSpacing.page] 独立）。
  static const double _cardMarginH = 12;

  String _versionLabel = '';
  bool _updatingNotifications = false;

  /// 是否有新版本可用。进入设置页时**主动静默检测**，有新版就在「检查更新」行显示小红点，
  /// 无需用户手动点一次才知道（此前只有点击才查，导致发布新版本没有任何提示）。
  bool _updateAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadVersionLabel();
    unawaited(_probeClientRelease());
  }

  /// 静默检测新版本：不弹任何对话框，只更新小红点状态；失败静默忽略。
  ///
  /// 复用全局 [ClientReleaseCoordinator]（启动时已 `checkOnLaunch`），
  /// 避免设置页与「我」tab 各自发一次请求、结果显示不一致。
  Future<void> _probeClientRelease() async {
    if (!_showUpdateCheck) return;
    try {
      final coordinator = context.read<ClientReleaseCoordinator>();
      if (!coordinator.checked) {
        await coordinator.checkOnLaunch();
      }
      if (!mounted) return;
      setState(() {
        _updateAvailable = coordinator.updateAvailable;
      });
    } catch (_) {
      // 静默检测失败不影响设置页使用（例如离线）；用户仍可手动「检查更新」。
    }
  }

  Future<void> _loadVersionLabel() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionLabel = '${info.version} (${info.buildNumber})';
      });
    } catch (_) {
      /* 忽略 */
    }
  }

  Color _rowHover(BuildContext context) =>
      AppColors.textPrimary.resolveFrom(context).withValues(alpha: 0.06);

  String _appearanceSubtitle(
    AppLocalizations l10n,
    AppThemeModeController c,
  ) {
    switch (c.selectedCode) {
      case AppThemeModeController.followSystem:
        return l10n.langFollowSystem;
      case 'light':
        return l10n.appAppearanceLight;
      case 'dark':
        return l10n.appAppearanceDark;
      default:
        return l10n.langFollowSystem;
    }
  }

  String _languageSubtitle(AppLocalizations l10n, AppLocaleController c) {
    switch (c.selectedCode) {
      case AppLocaleController.followSystem:
        return l10n.langFollowSystem;
      case 'zh':
        return l10n.langChinese;
      case 'en':
        return l10n.langEnglish;
      default:
        return l10n.langFollowSystem;
    }
  }

  Future<void> _pickAppearance(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = context.read<AppThemeModeController>();
    final current = ctrl.selectedCode;
    final choice = await showGvIosModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final primary = AppColors.primary.resolveFrom(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.langFollowSystem),
                trailing: current == AppThemeModeController.followSystem
                    ? Icon(Icons.check, color: primary)
                    : null,
                onTap: () =>
                    Navigator.pop(ctx, AppThemeModeController.followSystem),
              ),
              ListTile(
                title: Text(l10n.appAppearanceLight),
                trailing: current == 'light'
                    ? Icon(Icons.check, color: primary)
                    : null,
                onTap: () => Navigator.pop(ctx, 'light'),
              ),
              ListTile(
                title: Text(l10n.appAppearanceDark),
                trailing: current == 'dark'
                    ? Icon(Icons.check, color: primary)
                    : null,
                onTap: () => Navigator.pop(ctx, 'dark'),
              ),
            ],
          ),
        );
      },
    );
    if (choice != null && context.mounted) {
      await context.read<AppThemeModeController>().setThemeModeCode(choice);
    }
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final appLocale = context.read<AppLocaleController>();
    final current = appLocale.selectedCode;
    final choice = await showGvIosModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final primary = AppColors.primary.resolveFrom(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.langFollowSystem),
                trailing: current == AppLocaleController.followSystem
                    ? Icon(Icons.check, color: primary)
                    : null,
                onTap: () =>
                    Navigator.pop(ctx, AppLocaleController.followSystem),
              ),
              ListTile(
                title: Text(l10n.langChinese),
                trailing:
                    current == 'zh' ? Icon(Icons.check, color: primary) : null,
                onTap: () => Navigator.pop(ctx, 'zh'),
              ),
              ListTile(
                title: Text(l10n.langEnglish),
                trailing:
                    current == 'en' ? Icon(Icons.check, color: primary) : null,
                onTap: () => Navigator.pop(ctx, 'en'),
              ),
            ],
          ),
        );
      },
    );
    if (choice != null && context.mounted) {
      await context.read<AppLocaleController>().setLocaleCode(choice);
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();

    final noticeOk = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          title: Text(dl.settingsDeleteAccountNoticeTitle),
          content: SingleChildScrollView(
            child: Text(dl.settingsDeleteAccountNoticeBody),
          ),
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: dl.commonCancel,
              primaryText: dl.settingsDeleteAccountNoticeConfirm,
              onSecondary: () => Navigator.pop(ctx, false),
              onPrimary: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (noticeOk != true || !context.mounted) return;

    final password = await _showDeleteAccountPasswordDialog(context);
    if (password == null || password.isEmpty || !context.mounted) return;

    try {
      await auth.deleteAccount(password: password);
      if (!context.mounted) return;
      GvToast.show(context, l10n.toastDeleteAccountSuccess);
      context.go('/login');
    } catch (e) {
      if (context.mounted) {
        GvToast.show(context, auth.apiError(e));
      }
    }
  }

  Future<String?> _showDeleteAccountPasswordDialog(BuildContext context) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final dl = AppLocalizations.of(ctx)!;
          return AlertDialog(
            actionsPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.start,
            buttonPadding: EdgeInsets.zero,
            title: Text(dl.settingsDeleteAccountPasswordTitle),
            content: TextField(
              controller: controller,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: dl.settingsDeleteAccountPasswordHint,
              ),
              onSubmitted: (_) => _popDeletePasswordIfValid(ctx, controller),
            ),
            actions: [
              GvDialogActions.weChatFooter(
                ctx,
                primaryText: dl.settingsDeleteAccountSubmit,
                onSecondary: () => Navigator.pop(ctx),
                onPrimary: () => _popDeletePasswordIfValid(ctx, controller),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  void _popDeletePasswordIfValid(
    BuildContext ctx,
    TextEditingController controller,
  ) {
    final dl = AppLocalizations.of(ctx)!;
    if (controller.text.isEmpty) {
      GvToast.show(ctx, dl.toastEnterCurrentPassword);
      return;
    }
    Navigator.pop(ctx, controller.text);
  }

  Widget _menuRow({
    Key? key,
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    required BorderRadius inkBorderRadius,
    Color? titleColor,
    Widget? badge,
  }) {
    final hint = AppColors.textHint.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final hover = _rowHover(context);
    final titleFg = titleColor ?? AppColors.textPrimary.resolveFrom(context);
    return GvActionRow(
      key: key,
      title: title,
      titleStyle: GvTypography.navTitle(titleFg),
      subtitle: subtitle,
      subtitleStyle: GvTypography.caption(secondary),
      onTap: onTap,
      borderRadius: inkBorderRadius,
      hoverColor: hover,
      highlightColor: hover,
      splashColor:
          AppColors.textPrimary.resolveFrom(context).withValues(alpha: 0.10),
      leading: Icon(icon, size: 22, color: secondary),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge != null) ...[
            badge,
            const SizedBox(width: 6),
          ],
          Icon(
            LucideIcons.chevron_right,
            size: 20,
            color: hint,
          ),
        ],
      ),
    );
  }

  Widget _notificationSwitchRow({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
    IconData icon = LucideIcons.bell,
    String? subtitle,
    BorderRadius? borderRadius = const BorderRadius.vertical(
      bottom: Radius.circular(GvRadii.card),
    ),
  }) {
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final hint = AppColors.textHint.resolveFrom(context);
    final hover = _rowHover(context);
    return GvActionRow(
      title: title,
      titleStyle: GvTypography.navTitle(
        AppColors.textPrimary.resolveFrom(context),
      ),
      subtitle: subtitle,
      subtitleStyle: GvTypography.small(hint),
      leading: Icon(icon, size: 22, color: secondary),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      onTap: onChanged == null ? null : () => onChanged(!value),
      borderRadius: borderRadius,
      hoverColor: hover,
      highlightColor: hover,
      splashColor:
          AppColors.textPrimary.resolveFrom(context).withValues(alpha: 0.10),
    );
  }

  Future<void> _setNotificationsEnabled(
    PushNotificationService pushService,
    bool enabled,
  ) async {
    if (_updatingNotifications) return;
    setState(() => _updatingNotifications = true);
    try {
      await pushService.setNotificationsEnabled(enabled);
    } finally {
      if (mounted) setState(() => _updatingNotifications = false);
    }
  }

  void _toastForUpdate(BuildContext context, String message) {
    final rootCtx = gvRootNavigatorKey.currentContext;
    if (rootCtx != null && rootCtx.mounted) {
      GvToast.show(rootCtx, message);
    } else if (context.mounted) {
      GvToast.show(context, message);
    }
  }

  Future<void> _checkClientRelease(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CupertinoActivityIndicator(radius: 14),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.updateChecking,
                  style: GvTypography.body(
                    AppColors.textPrimary.resolveFrom(ctx),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    ClientReleaseCheckResult? result;
    try {
      final releaseRepository = context.read<ClientReleaseRepository>();
      final storage = context.read<LocalStorage>();
      final info = await PackageInfo.fromPlatform();
      final code = int.tryParse(info.buildNumber.trim()) ?? 0;
      final platform = gvClientReleasePlatformKey();
      if (platform == null) return;
      var installationId = storage.clientReleaseInstallationId;
      installationId ??= const Uuid().v4();
      await storage.setClientReleaseInstallationId(installationId);
      result = await releaseRepository.checkRelease(
          platform: platform,
          channel: gvClientReleaseChannelKey(),
          version: info.version,
          buildNumber: code,
          architecture: 'universal',
          protocolVersion: 'v1',
          installationId: installationId);
    } catch (e) {
      if (context.mounted) {
        final msg = context.read<ApiClient>().extractErrorMessage(e);
        _toastForUpdate(context, msg);
      }
    } finally {
      // 用根 Navigator 关闭「检查中」弹层，避免沿用旧的 rootNav 引用导致 pop 失败（安卓上像「没反应」）。
      final nav = gvRootNavigatorKey.currentState;
      if (nav != null && nav.canPop()) nav.pop();
    }

    if (!context.mounted || result == null) return;

    final latest = result.target;
    if (!result.requiresUpdate) {
      _toastForUpdate(context, l10n.updateUpToDate);
      return;
    }

    if (latest == null) {
      _toastForUpdate(context, l10n.updateNoReleaseInfo);
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: !result.mandatory,
      useRootNavigator: true,
      builder: (ctx) {
        final dlgL10n = AppLocalizations.of(ctx)!;
        final primary = AppColors.textPrimary.resolveFrom(ctx);
        final secondary = AppColors.textSecondary.resolveFrom(ctx);
        final title = result!.mandatory
            ? dlgL10n.updateMandatoryTitle
            : dlgL10n.updateNewVersionTitle;
        final notes = latest.releaseNotes.trim().isEmpty
            ? dlgL10n.updateNoNotes
            : latest.releaseNotes.trim();

        Future<void> openUrl() async {
          final urlStr = latest.launchUrl;
          if (urlStr == null) {
            GvToast.show(ctx, dlgL10n.updateNoDownloadUrl);
            return;
          }
          final uri = Uri.tryParse(urlStr);
          if (uri == null || !uri.hasScheme) {
            GvToast.show(ctx, dlgL10n.updateInvalidUrl);
            return;
          }
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok && ctx.mounted) {
            GvToast.show(ctx, dlgL10n.updateCannotOpenLink);
          }
        }

        return PopScope(
          canPop: !result.mandatory,
          child: AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dlgL10n.updateLatestVersionLine(
                      latest.version,
                      latest.buildNumber,
                    ),
                    style: GvTypography.body(primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    notes,
                    style: GvTypography.body(secondary),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(
              GvSpacing.page,
              8,
              GvSpacing.page,
              GvSpacing.lg,
            ),
            actionsAlignment: MainAxisAlignment.end,
            actionsOverflowAlignment: OverflowBarAlignment.end,
            buttonPadding: EdgeInsets.zero,
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!result.mandatory) ...[
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(dlgL10n.updateLater),
                    ),
                    const SizedBox(width: GvSpacing.sm),
                  ],
                  FilledButton(
                    onPressed: () async {
                      await openUrl();
                      if (result!.mandatory) return;
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(dlgL10n.updateNow),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appLocale = context.watch<AppLocaleController>();
    final appThemeMode = context.watch<AppThemeModeController>();
    final pushService = context.watch<PushNotificationService>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      key: GvAutomationKeys.settingsScreen,
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.settingsTitle, showBack: true),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                _cardMarginH,
                GvSpacing.sm,
                _cardMarginH,
                0,
              ),
              children: [
                GvCardShell(
                  borderRadius: BorderRadius.circular(GvRadii.card),
                  child: Material(
                    color: AppColors.bgWhite.resolveFrom(context),
                    child: Column(
                      children: [
                        _menuRow(
                          key: GvAutomationKeys.settingsProfile,
                          context: context,
                          icon: LucideIcons.user,
                          title: l10n.settingsProfile,
                          onTap: () => gvOpenProfileEdit(context),
                          inkBorderRadius: const BorderRadius.vertical(
                            top: Radius.circular(GvRadii.card),
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.textHint
                              .resolveFrom(context)
                              .withValues(alpha: 0.22),
                        ),
                        _menuRow(
                          key: GvAutomationKeys.settingsPassword,
                          context: context,
                          icon: LucideIcons.lock,
                          title: l10n.settingsChangePassword,
                          onTap: () => gvOpenChangePassword(context),
                          inkBorderRadius: BorderRadius.zero,
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.textHint
                              .resolveFrom(context)
                              .withValues(alpha: 0.22),
                        ),
                        _menuRow(
                          context: context,
                          icon: LucideIcons.smartphone,
                          title: l10n.gvFaDeviceManagementEntry,
                          onTap: () => context.push(AppRoutes.settingsDevices),
                          inkBorderRadius: BorderRadius.zero,
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.textHint
                              .resolveFrom(context)
                              .withValues(alpha: 0.22),
                        ),
                        _menuRow(
                          context: context,
                          icon: LucideIcons.timer,
                          title: l10n.selfDestructTitle,
                          onTap: () => context.push(AppRoutes.selfDestruct),
                          inkBorderRadius: BorderRadius.zero,
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.textHint
                              .resolveFrom(context)
                              .withValues(alpha: 0.22),
                        ),
                        _menuRow(
                          context: context,
                          icon: LucideIcons.ban,
                          title: l10n.settingsBlacklist,
                          onTap: () => gvOpenBlacklist(context),
                          inkBorderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(GvRadii.card),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: GvSpacing.sm),
                GvCardShell(
                  borderRadius: BorderRadius.circular(GvRadii.card),
                  child: Material(
                    color: AppColors.bgWhite.resolveFrom(context),
                    child: Column(
                      children: [
                        _menuRow(
                          context: context,
                          icon: LucideIcons.hard_drive,
                          title: l10n.settingsChatStorage,
                          onTap: () => context.push(AppRoutes.chatStorage),
                          inkBorderRadius: const BorderRadius.vertical(
                            top: Radius.circular(GvRadii.card),
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.textHint
                              .resolveFrom(context)
                              .withValues(alpha: 0.22),
                        ),
                        _menuRow(
                          context: context,
                          icon: LucideIcons.archive_restore,
                          title: l10n.settingsChatBackup,
                          onTap: () => context.push(AppRoutes.chatBackup),
                          inkBorderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(GvRadii.card),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: GvSpacing.sm),
                GvCardShell(
                  borderRadius: BorderRadius.circular(GvRadii.card),
                  child: Material(
                    color: AppColors.bgWhite.resolveFrom(context),
                    child: Column(
                      children: [
                        _menuRow(
                          key: GvAutomationKeys.settingsAppearance,
                          context: context,
                          icon: LucideIcons.palette,
                          title: l10n.settingsAppearance,
                          subtitle: _appearanceSubtitle(l10n, appThemeMode),
                          onTap: () => _pickAppearance(context),
                          inkBorderRadius: const BorderRadius.vertical(
                            top: Radius.circular(GvRadii.card),
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.textHint
                              .resolveFrom(context)
                              .withValues(alpha: 0.22),
                        ),
                        _menuRow(
                          key: GvAutomationKeys.settingsLanguage,
                          context: context,
                          icon: LucideIcons.languages,
                          title: l10n.settingsLanguage,
                          subtitle: _languageSubtitle(l10n, appLocale),
                          onTap: () => _pickLanguage(context),
                          inkBorderRadius: pushService.notificationsSupported
                              ? BorderRadius.zero
                              : const BorderRadius.vertical(
                                  bottom: Radius.circular(GvRadii.card),
                                ),
                        ),
                        if (pushService.notificationsSupported) ...[
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.textHint
                                .resolveFrom(context)
                                .withValues(alpha: 0.22),
                          ),
                          _notificationSwitchRow(
                            context: context,
                            title: l10n.settingsNotifications,
                            value: pushService.notificationsEnabled,
                            onChanged: _updatingNotifications
                                ? null
                                : (enabled) => unawaited(
                                      _setNotificationsEnabled(
                                        pushService,
                                        enabled,
                                      ),
                                    ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.textHint
                                .resolveFrom(context)
                                .withValues(alpha: 0.22),
                          ),
                          _menuRow(
                            key: GvAutomationKeys.settingsNotifications,
                            context: context,
                            icon: LucideIcons.bell,
                            title: l10n.settingsNotifyDetail,
                            onTap: () =>
                                context.push(AppRoutes.notificationSettings),
                            inkBorderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(GvRadii.card),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: GvSpacing.sm),
                GvCardShell(
                  borderRadius: BorderRadius.circular(GvRadii.card),
                  child: Material(
                    color: AppColors.bgWhite.resolveFrom(context),
                    child: Column(
                      children: [
                        if (_showUpdateCheck) ...[
                          _menuRow(
                            context: context,
                            icon: LucideIcons.download,
                            title: l10n.settingsCheckUpdate,
                            subtitle: _updateAvailable
                                ? l10n.updateNewVersionTitle
                                : (_versionLabel.isEmpty
                                    ? l10n.settingsVersionCurrent
                                    : '${l10n.settingsVersionCurrent} $_versionLabel'),
                            badge: _updateAvailable ? const _NewVersionDot() : null,
                            onTap: () => _checkClientRelease(context),
                            inkBorderRadius: const BorderRadius.vertical(
                              top: Radius.circular(GvRadii.card),
                            ),
                          ),
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.textHint
                                .resolveFrom(context)
                                .withValues(alpha: 0.22),
                          ),
                        ],
                        _menuRow(
                          context: context,
                          icon: LucideIcons.file_text,
                          title: l10n.authAgreementUserTerms,
                          onTap: () => ProtocolWebViewScreen.open(
                            context,
                            title: l10n.authAgreementUserTerms,
                            url: LegalUrls.userAgreement,
                          ),
                          inkBorderRadius: _showUpdateCheck
                              ? BorderRadius.zero
                              : const BorderRadius.vertical(
                                  top: Radius.circular(GvRadii.card),
                                ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.textHint
                              .resolveFrom(context)
                              .withValues(alpha: 0.22),
                        ),
                        _menuRow(
                          context: context,
                          icon: LucideIcons.shield,
                          title: l10n.authAgreementPrivacy,
                          onTap: () => ProtocolWebViewScreen.open(
                            context,
                            title: l10n.authAgreementPrivacy,
                            url: LegalUrls.privacyPolicy,
                          ),
                          inkBorderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(GvRadii.card),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                _cardMarginH,
                8,
                _cardMarginH,
                16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 注销账号：比退出登录更危险，视觉弱化（小号红色文字），保留双确认（提示 + 密码）。
                  TextButton(
                    onPressed: () =>
                        unawaited(_confirmDeleteAccount(context)),
                    child: Text(
                      l10n.settingsDeleteAccount,
                      style: GvTypography.caption(
                        AppColors.danger.resolveFrom(context),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: GvAutomationKeys.settingsLogout,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppColors.danger.resolveFrom(context),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) {
                            final dl = AppLocalizations.of(ctx)!;
                            return AlertDialog(
                              actionsPadding: EdgeInsets.zero,
                              actionsAlignment: MainAxisAlignment.start,
                              buttonPadding: EdgeInsets.zero,
                              title: Text(dl.settingsLogoutConfirmTitle),
                              content: Text(dl.settingsLogoutConfirmBody),
                              actions: [
                                GvDialogActions.weChatFooter(
                                  ctx,
                                  onSecondary: () =>
                                      Navigator.pop(ctx, false),
                                  onPrimary: () => Navigator.pop(ctx, true),
                                ),
                              ],
                            );
                          },
                        );
                        if (ok == true && context.mounted) {
                          await context
                              .read<PushNotificationService>()
                              .unregisterToken();
                          await auth.logout();
                          if (context.mounted) context.go('/login');
                        }
                      },
                      child: Text(l10n.settingsLogout),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 「检查更新」行的小红点：有新版本可用时显示，
/// 让用户在发布新版后无需先手动点一次「检查更新」才知道。
class _NewVersionDot extends StatelessWidget {
  const _NewVersionDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFFF3B30),
        shape: BoxShape.circle,
      ),
    );
  }
}
