import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../core/app_colors.dart';
import '../core/gv_mina.dart';
import '../core/gv_toast.dart';
import '../models/mini_program_route_args.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;
import 'gv_dialog_actions.dart';

/// 小程序码弹窗；二维码内容为 [buildGvMinaPayload]。
Future<void> showMiniProgramShareDialog(
  BuildContext context,
  MiniProgramRouteArgs args,
) async {
  if (args.miniProgramId.trim().isEmpty) {
    GvToast.show(
        context, AppLocalizations.of(context)!.toastMiniProgramNoShare);
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => _MiniProgramShareQrDialog(args: args),
  );
}

class _MiniProgramShareQrDialog extends StatelessWidget {
  const _MiniProgramShareQrDialog({required this.args});

  final MiniProgramRouteArgs args;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final payload = buildGvMinaPayload(args.miniProgramId);
    final dialogRadius = BorderRadius.circular(GvRadii.dialogLarge);
    final dialogBg = CupertinoColors.systemBackground.resolveFrom(context);
    final ctx = context;

    return Dialog(
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
                  l10n.miniProgramQrCodeTitle,
                  textAlign: TextAlign.center,
                  style: GvTypography.navTitle(
                    AppColors.textPrimary.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                        _MiniShareQrCenterIcon(args: args, dialogBg: dialogBg),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.border.resolveFrom(context),
          ),
          TextButton(
            style: GvDialogActions.cancelStyle(ctx).copyWith(
              minimumSize: WidgetStateProperty.all(
                const Size(double.infinity, 52),
              ),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: dialogRadius.bottomLeft,
                    bottomRight: dialogRadius.bottomRight,
                  ),
                ),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }
}

class _MiniShareQrCenterIcon extends StatelessWidget {
  const _MiniShareQrCenterIcon({
    required this.args,
    required this.dialogBg,
  });

  final MiniProgramRouteArgs args;
  final Color dialogBg;

  @override
  Widget build(BuildContext context) {
    final url = args.iconUrl.trim();
    final hint = AppColors.textHint.resolveFrom(context);
    final chatBg = AppColors.bgChat.resolveFrom(context);

    Widget child;
    if (url.isEmpty) {
      child = ColoredBox(
        color: chatBg,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(LucideIcons.app_window, size: 26, color: hint),
        ),
      );
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        httpHeaders: args.iconHttpHeaders,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        placeholder: (_, __) => ColoredBox(
          color: chatBg,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: hint.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => ColoredBox(
          color: chatBg,
          child: Icon(LucideIcons.app_window, size: 26, color: hint),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: dialogBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: child,
      ),
    );
  }
}
