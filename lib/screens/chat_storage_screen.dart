import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_toast.dart';
import '../models/chat_session_storage_stat.dart';
import '../providers/chat_provider.dart';
import '../widgets/gv_avatar.dart';
import '../widgets/gv_dialog_actions.dart';
import '../widgets/gv_nav_bar.dart';

/// 「聊天记录存储空间」管理页（纯客户端）。
///
/// 顶部展示本机聊天记录总占用；按 (chatType, peerId) 分组展示各会话
/// 本地消息库占用，按大小降序。每个会话可「清空全部记录」或「仅清理媒体缓存」，
/// 底部「全部清理」带二次确认。所有清理仅作用于本机记录，不影响云端。
class ChatStorageScreen extends StatefulWidget {
  const ChatStorageScreen({super.key});

  @override
  State<ChatStorageScreen> createState() => _ChatStorageScreenState();
}

class _ChatStorageScreenState extends State<ChatStorageScreen> {
  static const String _clearAll = 'all';
  static const String _clearMedia = 'media';

  bool _loading = true;
  bool _busy = false;
  List<ChatSessionStorageStat> _stats = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final chat = context.read<ChatProvider>();
    setState(() => _loading = true);
    try {
      final stats = await chat.loadSessionStorageStats();
      if (!mounted) return;
      final list = List<ChatSessionStorageStat>.from(stats);
      list.sort((a, b) => b.messageBytes.compareTo(a.messageBytes));
      setState(() {
        _stats = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _stats = const [];
          _loading = false;
        });
      }
    }
  }

  int get _totalBytes =>
      _stats.fold<int>(0, (sum, s) => sum + s.messageBytes);

  ({String name, String? avatar}) _sessionDisplay(
    ChatSessionStorageStat stat,
  ) {
    for (final c in context.read<ChatProvider>().conversations) {
      if (c.id == stat.peerId && c.chatType == stat.chatType) {
        final name = c.name.trim();
        return (name: name.isNotEmpty ? name : _fallbackName(stat), avatar: c.avatar);
      }
    }
    return (name: _fallbackName(stat), avatar: null);
  }

  String _fallbackName(ChatSessionStorageStat stat) {
    final l10n = AppLocalizations.of(context)!;
    switch (stat.chatType) {
      case 'group':
        return l10n.chatGroupDefaultTitle(stat.peerId);
      case 'channel':
        return l10n.chatChannelDefaultTitle(stat.peerId);
      case 'secret':
        return l10n.chatSecretDefaultTitle(stat.peerId);
      case 'secret_group':
        return l10n.secretGroupChatDefaultTitle;
      default:
        return l10n.chatUserDefaultTitle(stat.peerId);
    }
  }

  Future<void> _onClearSession(ChatSessionStorageStat stat) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showGvIosModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        final secondary = AppColors.textSecondary.resolveFrom(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  _sessionDisplay(stat).name,
                  style: GvTypography.navTitle(
                    AppColors.textPrimary.resolveFrom(ctx),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(LucideIcons.trash, color: secondary),
                title: Text(loc.chatStorageClearAllRecords),
                trailing: Icon(LucideIcons.chevron_right, color: secondary),
                onTap: () => Navigator.pop(ctx, _clearAll),
              ),
              ListTile(
                leading: Icon(LucideIcons.images, color: secondary),
                title: Text(loc.chatStorageClearMediaOnly),
                trailing: Icon(LucideIcons.chevron_right, color: secondary),
                onTap: () => Navigator.pop(ctx, _clearMedia),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || choice == null) return;

    final chat = context.read<ChatProvider>();
    if (choice == _clearAll) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
            actionsPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.start,
            buttonPadding: EdgeInsets.zero,
            title: Text(loc.chatStorageClearRecordsConfirmTitle),
            content: Text(loc.chatStorageClearRecordsConfirmBody),
            actions: [
              GvDialogActions.weChatFooter(
                ctx,
                secondaryText: loc.commonCancel,
                primaryText: loc.commonConfirm,
                onSecondary: () => Navigator.pop(ctx, false),
                onPrimary: () => Navigator.pop(ctx, true),
              ),
            ],
          );
        },
      );
      if (ok != true || !mounted) return;
      await chat.clearSessionStorage(stat.peerId, stat.chatType);
    } else {
      await chat.clearSessionMediaStorage(stat.peerId, stat.chatType);
    }

    if (!mounted) return;
    GvToast.show(context, l10n.chatStorageCleared);
    await _load();
  }

  Future<void> _onClearAll() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          title: Text(loc.chatStorageClearAllConfirmTitle),
          content: Text(loc.chatStorageClearAllConfirmBody),
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: loc.commonCancel,
              primaryText: loc.commonConfirm,
              onSecondary: () => Navigator.pop(ctx, false),
              onPrimary: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await context.read<ChatProvider>().clearAllStorage();
      if (!mounted) return;
      GvToast.show(context, l10n.chatStorageCleared);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    final text = value >= 100 || unit == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
    return '$text ${units[unit]}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primary = AppColors.textPrimary.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final hint = AppColors.textHint.resolveFrom(context);

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.settingsChatStorage, showBack: true),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _buildBody(l10n, primary, secondary, hint),
          ),
          SafeArea(
            top: false,
            left: false,
            right: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.danger.resolveFrom(context),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: (_busy || _loading || _stats.isEmpty)
                      ? null
                      : () => unawaited(_onClearAll()),
                  child: Text(l10n.chatStorageClearAll),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l10n,
    Color primary,
    Color secondary,
    Color hint,
  ) {
    if (_stats.isEmpty) {
      return Center(
        child: Text(
          l10n.chatStorageEmpty,
          style: GvTypography.caption(secondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      children: [
        GvCardShell(
          borderRadius: BorderRadius.circular(GvRadii.card),
          child: Material(
            color: AppColors.bgWhite.resolveFrom(context),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.chatStorageTotalUsed,
                    style: GvTypography.caption(hint),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatBytes(_totalBytes),
                    style: GvTypography.title(primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.chatStorageLocalOnlyNote,
                    style: GvTypography.caption(hint),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: GvSpacing.sm),
        for (var i = 0; i < _stats.length; i++) ...[
          if (i > 0) const SizedBox(height: GvSpacing.sm),
          _buildSessionTile(l10n, _stats[i], secondary),
        ],
      ],
    );
  }

  Widget _buildSessionTile(
    AppLocalizations l10n,
    ChatSessionStorageStat stat,
    Color secondary,
  ) {
    final display = _sessionDisplay(stat);
    return GvCardShell(
      borderRadius: BorderRadius.circular(GvRadii.card),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: GvAvatar(
            name: display.name,
            uid: stat.peerId,
            src: display.avatar,
            size: 44,
          ),
          title: Text(
            display.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GvTypography.navTitle(
              AppColors.textPrimary.resolveFrom(context),
            ),
          ),
          subtitle: Text(
            _formatBytes(stat.messageBytes),
            style: GvTypography.caption(secondary),
          ),
          trailing: TextButton(
            onPressed: () => unawaited(_onClearSession(stat)),
            child: Text(l10n.chatStorageClear),
          ),
        ),
      ),
    );
  }
}
