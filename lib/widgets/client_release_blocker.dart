import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography;

import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/client_release_coordinator.dart';

class ClientReleaseBlocker extends StatelessWidget {
  const ClientReleaseBlocker({super.key, required this.coordinator});
  final ClientReleaseCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    if (coordinator.blocksUsage) return _buildMandatoryBlocker(context);
    // 可选更新：启动后弹一次可关闭的更新提示（不阻断使用）。
    if (coordinator.shouldPromptOptional) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        coordinator.markOptionalPrompted();
        _showOptionalUpdateDialog(context);
      });
    }
    return const SizedBox.shrink();
  }

  Widget _buildMandatoryBlocker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final target = coordinator.result?.target;
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final typography = Theme.of(context).textTheme;
    return ColoredBox(
      color: AppColors.bgPage.resolveFrom(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.updateMandatoryTitle,
                        style: typography.titleLarge?.copyWith(color: primary)),
                    const SizedBox(height: 16),
                    Text(
                        target == null
                            ? l10n.updateNoReleaseInfo
                            : l10n.updateLatestVersionLine(
                                target.version, target.buildNumber),
                        style:
                            typography.bodyMedium?.copyWith(color: secondary)),
                    if (target?.releaseNotes.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Text(target!.releaseNotes,
                          style: typography.bodyMedium
                              ?.copyWith(color: secondary)),
                    ],
                    const SizedBox(height: 24),
                    Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                            onPressed: target?.launchUrl == null
                                ? null
                                : () => _open(context, target!.launchUrl!),
                            child: Text(l10n.updateNow))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showOptionalUpdateDialog(BuildContext context) async {
    final target = coordinator.result?.target;
    if (target == null || target.launchUrl == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (ctx) {
        final dlgL10n = AppLocalizations.of(ctx)!;
        final primary = AppColors.textPrimary.resolveFrom(ctx);
        final secondary = AppColors.textSecondary.resolveFrom(ctx);
        final notes = target.releaseNotes.trim().isEmpty
            ? dlgL10n.updateNoNotes
            : target.releaseNotes.trim();
        return AlertDialog(
          title: Text(dlgL10n.updateSuggestTitle),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dlgL10n.updateLatestVersionLine(
                    target.version,
                    target.buildNumber,
                  ),
                  style: GvTypography.body(primary),
                ),
                const SizedBox(height: 12),
                Text(notes, style: GvTypography.body(secondary)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(dlgL10n.updateLater),
            ),
            FilledButton(
              onPressed: () async {
                await _open(ctx, target.launchUrl!);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(dlgL10n.updateNow),
            ),
          ],
        );
      },
    );
  }

  Future<void> _open(BuildContext context, String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) return;
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.updateCannotOpenLink),
        ),
      );
    }
  }
}
