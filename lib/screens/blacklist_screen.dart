import 'package:flutter/material.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/friend_models.dart';
import '../providers/friend_provider.dart';
import '../widgets/gv_avatar.dart';
import '../widgets/gv_dialog_actions.dart';
import '../widgets/gv_nav_bar.dart';

/// 黑名单列表：展示被拉黑用户，点按/长按可「移出黑名单」。
class BlacklistScreen extends StatefulWidget {
  const BlacklistScreen({super.key});

  @override
  State<BlacklistScreen> createState() => _BlacklistScreenState();
}

class _BlacklistScreenState extends State<BlacklistScreen> {
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      await context.read<FriendProvider>().loadBlockedList();
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _confirmUnblock(BuildContext context, FriendItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          title: Text(loc.contactUnblockTitle),
          content: Text(loc.contactUnblockConfirmBody),
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
    if (ok == true && context.mounted) {
      await context.read<FriendProvider>().unblockFriend(item.friendId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = context.watch<FriendProvider>();

    final Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error) {
      body = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.blacklistLoadFailed,
              style: GvTypography.caption(
                AppColors.textSecondary.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _load,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    } else if (f.blockedFriends.isEmpty) {
      body = Center(
        child: Text(
          l10n.blacklistEmpty,
          style: GvTypography.caption(
            AppColors.textSecondary.resolveFrom(context),
          ),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: f.blockedFriends.length,
        itemBuilder: (_, i) {
          final item = f.blockedFriends[i];
          return _BlockedTile(
            friend: item,
            onUnblock: () => _confirmUnblock(context, item),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.blacklistTitle, showBack: true),
      body: body,
    );
  }
}

class _BlockedTile extends StatelessWidget {
  const _BlockedTile({required this.friend, required this.onUnblock});

  final FriendItem friend;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GvCardShell(
      borderRadius: BorderRadius.circular(GvRadii.card),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: ListTile(
          leading: GvAvatar(
            name: friend.displayName,
            uid: friend.friendId,
            src: friend.friendUser?.avatar,
            size: 44,
          ),
          title: Text(
            friend.displayName,
            style: GvTypography.navTitle(
              AppColors.textPrimary.resolveFrom(context),
            ),
          ),
          trailing: TextButton(
            onPressed: onUnblock,
            child: Text(l10n.contactUnblockAction),
          ),
          onTap: onUnblock,
          onLongPress: onUnblock,
        ),
      ),
    );
  }
}
