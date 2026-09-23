import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/api_failure.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_toast.dart';
import '../providers/chat_provider.dart';
import '../services/chat_backup_file_io.dart';
import '../widgets/gv_dialog_actions.dart';
import '../widgets/gv_nav_bar.dart';

/// 聊天记录备份与迁移：纯客户端、本地文件级。
///
/// - 备份：把当前账号全部本地会话与消息导出为 JSON 文件（媒体只存 URL / objectId）。
/// - 恢复：解析 JSON，「覆盖合并」写入本地（按 msgId 去重）并刷新会话列表。
class ChatBackupScreen extends StatefulWidget {
  const ChatBackupScreen({super.key});

  @override
  State<ChatBackupScreen> createState() => _ChatBackupScreenState();
}

class _ChatBackupScreenState extends State<ChatBackupScreen> {
  bool _busy = false;

  String _formatTimestamp(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}${two(local.month)}${two(local.day)}'
        '${two(local.hour)}${two(local.minute)}${two(local.second)}';
  }

  int _countMessages(Object? sessions) {
    if (sessions is! List) return 0;
    var count = 0;
    for (final session in sessions) {
      if (session is Map) {
        final messages = session['messages'];
        if (messages is List) count += messages.length;
      }
    }
    return count;
  }

  Future<void> _exportBackup() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final chat = context.read<ChatProvider>();
    setState(() => _busy = true);

    String? errorMessage;
    String? savedPath;
    int conversationCount = 0;
    int messageCount = 0;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogCtx) {
        Future(() async {
          try {
            final data = await chat.buildChatBackup();
            final uid = (chat.myId ?? 0).toString();
            final stamp = _formatTimestamp(DateTime.now());
            final fileName = 'wv-chat-backup-$uid-$stamp.json';
            conversationCount = (data['conversations'] as List?)?.length ?? 0;
            messageCount = _countMessages(data['sessions']);
            if (conversationCount == 0 && messageCount == 0) {
              errorMessage = l10n.chatBackupExportEmpty;
            } else {
              final jsonStr =
                  const JsonEncoder.withIndent('  ').convert(data);
              final bytes = Uint8List.fromList(utf8.encode(jsonStr));
              savedPath = await saveChatBackupFile(
                fileName,
                bytes,
                dialogTitle: l10n.chatBackupExportAction,
              );
            }
          } catch (e) {
            errorMessage = ApiFailure.messageOf(e);
          } finally {
            if (dialogCtx.mounted) {
              Navigator.of(dialogCtx, rootNavigator: true).pop();
            }
          }
        });
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CupertinoActivityIndicator(radius: 14),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.chatBackupExporting,
                    style: GvTypography.body(
                      AppColors.textPrimary.resolveFrom(dialogCtx),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() => _busy = false);

    if (errorMessage != null) {
      GvToast.show(context, errorMessage!);
      return;
    }
    if (savedPath == null) return; // 用户取消保存。

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(dl.chatBackupExportSuccessTitle),
          content: SingleChildScrollView(
            child: Text(
              dl.chatBackupExportSuccessBody(
                conversationCount,
                messageCount,
                savedPath!,
              ),
            ),
          ),
          actions: [
            GvDialogActions.weChatSingle(
              ctx,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importBackup() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    final chat = context.read<ChatProvider>();
    setState(() => _busy = true);

    PickedBackupFile? picked;
    try {
      picked = await pickChatBackupFile();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        GvToast.show(context, '$l10n.chatBackupRestoreFailed: ${ApiFailure.messageOf(e)}');
      }
      return;
    }
    if (!mounted) return;
    if (picked == null) {
      setState(() => _busy = false);
      return; // 用户取消选择。
    }

    Map<String, dynamic>? parsed;
    try {
      final decoded = jsonDecode(utf8.decode(picked.bytes));
      if (decoded is Map) parsed = Map<String, dynamic>.from(decoded);
    } catch (_) {
      parsed = null;
    }
    if (parsed == null) {
      setState(() => _busy = false);
      GvToast.show(context, l10n.chatBackupRestoreInvalid);
      return;
    }

    final confirmed = await _confirmRestore();
    if (!mounted) return;
    if (confirmed != true) {
      setState(() => _busy = false);
      return;
    }

    try {
      final result = await chat.restoreChatBackup(parsed);
      if (!mounted) return;
      GvToast.show(
        context,
        l10n.chatBackupRestoreSuccess(
          result.conversationCount,
          result.messageCount,
        ),
      );
    } catch (_) {
      if (mounted) GvToast.show(context, l10n.chatBackupRestoreInvalid);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmRestore() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          title: Text(dl.chatBackupRestoreConfirmTitle),
          content: SingleChildScrollView(
            child: Text(dl.chatBackupRestoreConfirmBody),
          ),
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              onSecondary: () => Navigator.pop(ctx, false),
              onPrimary: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.textPrimary.resolveFrom(context);
    final hint = AppColors.textHint.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final hover = AppColors.textPrimary
        .resolveFrom(context)
        .withValues(alpha: 0.06);

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.settingsChatBackup, showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          _sectionCard(
            title: l10n.chatBackupExportSectionTitle,
            description: l10n.chatBackupExportDesc,
            actionText: l10n.chatBackupExportAction,
            icon: LucideIcons.download,
            onTap: _busy ? null : _exportBackup,
            primary: primary,
            hint: hint,
            secondary: secondary,
            hover: hover,
          ),
          const SizedBox(height: GvSpacing.sm),
          _sectionCard(
            title: l10n.chatBackupRestoreSectionTitle,
            description: l10n.chatBackupRestoreDesc,
            actionText: l10n.chatBackupRestoreAction,
            icon: LucideIcons.upload,
            onTap: _busy ? null : _importBackup,
            primary: primary,
            hint: hint,
            secondary: secondary,
            hover: hover,
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required String description,
    required String actionText,
    required IconData icon,
    required VoidCallback? onTap,
    required Color primary,
    required Color hint,
    required Color secondary,
    required Color hover,
  }) {
    return GvCardShell(
      borderRadius: BorderRadius.circular(GvRadii.card),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(
                title,
                style: GvTypography.navTitle(primary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                description,
                style: GvTypography.caption(hint),
              ),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              color: AppColors.textHint
                  .resolveFrom(context)
                  .withValues(alpha: 0.22),
            ),
            GvActionRow(
              title: actionText,
              titleStyle: GvTypography.navTitle(primary),
              leading: Icon(icon, size: 22, color: secondary),
              trailing: Icon(LucideIcons.chevron_right, size: 20, color: hint),
              onTap: onTap,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(GvRadii.card),
              ),
              hoverColor: hover,
              highlightColor: hover,
              splashColor: AppColors.textPrimary
                  .resolveFrom(context)
                  .withValues(alpha: 0.10),
            ),
          ],
        ),
      ),
    );
  }
}
