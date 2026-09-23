import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../app/app_routes.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_secondary_navigation.dart';
import '../core/open_automation_keys.dart';
import '../core/open_toast.dart';
import '../core/open_uid.dart';
import '../models/im_user.dart';
import '../providers/auth_provider.dart';
import '../widgets/open_avatar.dart';
import '../l10n/app_localizations.dart';
import '../widgets/open_dialog_actions.dart';
import '../widgets/open_nav_bar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.user;
    final name = u?.displayName ?? '';
    final l10n = AppLocalizations.of(context)!;
    final label = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);

    return SizedBox.expand(
      key: GvAutomationKeys.profileScreen,
      child: ColoredBox(
        color: gvPageScaffoldBackground(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GvNavBar(
              title: l10n.tabMe,
              showBottomShadow: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  top: GvSpacing.xs,
                  bottom: GvSpacing.page,
                ),
                children: [
                  Material(
                    color: AppColors.bgWhite.resolveFrom(context),
                    child: Padding(
                      padding: const EdgeInsets.all(GvSpacing.page),
                      child: Row(
                        children: [
                          GvAvatar(
                              name: name,
                              uid: u?.id ?? 0,
                              src: u?.avatar,
                              size: 60),
                          const SizedBox(width: GvSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: GvTypography.title(label)),
                                const SizedBox(height: 4),
                                Text(l10n.contactAccountLine(u?.username ?? ''),
                                    style: GvTypography.caption(secondary)),
                                if ((u?.phone ?? '').isNotEmpty)
                                  Text('手机：${u!.phone}',
                                      style: GvTypography.caption(secondary)),
                                if ((u?.email ?? '').isNotEmpty)
                                  Text('邮箱：${u!.email}',
                                      style: GvTypography.caption(secondary)),
                                if ((u?.signature ?? '').isNotEmpty)
                                  Text(u!.signature!,
                                      style: GvTypography.caption(secondary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: GvSpacing.sm),
                  Material(
                    color: AppColors.bgWhite.resolveFrom(context),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _profileMenuRow(
                          key: GvAutomationKeys.profileQrCode,
                          context: context,
                          icon: LucideIcons.qr_code,
                          title: l10n.profileMyQrCode,
                          onTap: () => _showQr(context, u),
                          inkBorderRadius: BorderRadius.zero,
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.textHint
                              .resolveFrom(context)
                              .withValues(alpha: 0.22),
                        ),
                        _profileMenuRow(
                          key: GvAutomationKeys.profileFavorites,
                          context: context,
                          icon: LucideIcons.star,
                          title: l10n.favoritesTitle,
                          onTap: () => context.push(AppRoutes.favorites),
                          inkBorderRadius: BorderRadius.zero,
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.textHint
                              .resolveFrom(context)
                              .withValues(alpha: 0.22),
                        ),
                        _profileMenuRow(
                          key: GvAutomationKeys.profileSettings,
                          context: context,
                          icon: LucideIcons.settings,
                          title: l10n.settingsTitle,
                          onTap: () => gvOpenSettings(context),
                          inkBorderRadius: BorderRadius.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _profileRowHover(BuildContext context) =>
      AppColors.textPrimary.resolveFrom(context).withValues(alpha: 0.06);

  Widget _profileMenuRow({
    Key? key,
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required BorderRadius inkBorderRadius,
  }) {
    final hint = AppColors.textHint.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final hover = _profileRowHover(context);
    return GvActionRow(
      key: key,
      title: title,
      titleStyle: GvTypography.navTitle(
        AppColors.textPrimary.resolveFrom(context),
      ),
      onTap: onTap,
      borderRadius: inkBorderRadius,
      hoverColor: hover,
      highlightColor: hover,
      splashColor:
          AppColors.textPrimary.resolveFrom(context).withValues(alpha: 0.10),
      leading: Icon(icon, size: 22, color: secondary),
      trailing: Icon(
        LucideIcons.chevron_right,
        size: 20,
        color: hint,
      ),
    );
  }

  void _showQr(BuildContext context, ImUser? u) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ProfileQrDialog(user: u),
    );
  }
}

class _ProfileQrDialog extends StatefulWidget {
  const _ProfileQrDialog({required this.user});

  final ImUser? user;

  @override
  State<_ProfileQrDialog> createState() => _ProfileQrDialogState();
}

class _ProfileQrDialogState extends State<_ProfileQrDialog> {
  final GlobalKey _qrBoundaryKey = GlobalKey();
  bool _saving = false;

  bool get _saveSupported {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.windows =>
        true,
      _ => false,
    };
  }

  Future<void> _saveQrCode() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context)!;
    if (!_saveSupported) {
      GvToast.show(context, l10n.toastQrSaveNotSupported);
      return;
    }

    setState(() => _saving = true);
    try {
      var hasAccess = await Gal.hasAccess();
      if (!hasAccess) hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        if (mounted) GvToast.show(context, l10n.galErrorAccessDenied);
        return;
      }

      await WidgetsBinding.instance.endOfFrame;
      final boundary = _qrBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('QR image is not ready');

      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('Could not encode QR image');

      final username = widget.user?.username.trim() ?? '';
      final safeUsername = username.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await Gal.putImageBytes(
        data.buffer.asUint8List(),
        name:
            'wv_chat_qr_${safeUsername.isEmpty ? 'user' : safeUsername}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (mounted) GvToast.show(context, l10n.toastSavedToGallery);
    } on GalException catch (e) {
      if (!mounted) return;
      final message = switch (e.type) {
        GalExceptionType.accessDenied => l10n.galErrorAccessDenied,
        GalExceptionType.notEnoughSpace => l10n.galErrorNotEnoughSpace,
        GalExceptionType.notSupportedFormat => l10n.galErrorUnsupportedFormat,
        GalExceptionType.unexpected => l10n.galErrorUnexpected,
      };
      GvToast.show(context, message);
    } catch (_) {
      if (mounted) GvToast.show(context, l10n.galErrorUnexpected);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final u = widget.user;
    final username = u?.username ?? '';
    final payload = buildGvUidPayload(username);
    final name = u?.displayName ?? '';
    final label = CupertinoColors.label.resolveFrom(context);
    final dialogRadius = BorderRadius.circular(GvRadii.dialogLarge);
    final dialogBg = CupertinoColors.systemBackground.resolveFrom(context);
    final ctx = context;

    return Dialog(
      key: GvAutomationKeys.profileQrDialog,
      shadowColor: GvShadows.card.first.color,
      shape: RoundedRectangleBorder(borderRadius: dialogRadius),
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              children: [
                Text(
                  l10n.profileMyQrCode,
                  textAlign: TextAlign.center,
                  style: GvTypography.navTitle(
                    AppColors.textPrimary.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: _qrBoundaryKey,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: payload,
                            size: 220,
                            padding: EdgeInsets.zero,
                            backgroundColor: CupertinoColors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: dialogBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: GvAvatar(
                              square: true,
                              name: name,
                              uid: u?.id ?? 0,
                              src: u?.avatar,
                              size: 56,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  username,
                  textAlign: TextAlign.center,
                  style: GvTypography.caption(label),
                ),
              ],
            ),
          ),
          GvDialogActions.weChatFooter(
            ctx,
            secondaryKey: GvAutomationKeys.profileQrClose,
            secondaryText: l10n.commonClose,
            primaryText:
                _saving ? '${l10n.commonSave}…' : l10n.profileSaveQrCode,
            onSecondary: () => Navigator.pop(ctx),
            onPrimary: _saveQrCode,
          ),
        ],
      ),
    );
  }
}
