import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_secondary_navigation.dart';
import '../core/open_toast.dart';
import '../l10n/app_localizations.dart';
import '../models/friend_models.dart';
import '../providers/friend_provider.dart';
import '../widgets/open_avatar.dart';
import '../widgets/open_dialog_actions.dart';
import '../widgets/open_nav_bar.dart';

/// 好友分组管理：列出分组、新建分组，点击分组查看组内好友。
class FriendGroupsScreen extends StatefulWidget {
  const FriendGroupsScreen({super.key});

  @override
  State<FriendGroupsScreen> createState() => _FriendGroupsScreenState();
}

class _FriendGroupsScreenState extends State<FriendGroupsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<FriendProvider>();
      await provider.loadFriends();
      if (mounted) await provider.loadFriendGroups();
    });
  }

  List<String> _groupNames(FriendProvider f) =>
      f.friendGroups.where((g) => g.trim().isNotEmpty).toList();

  List<FriendItem> _friendsInGroup(FriendProvider f, String group) => f.friends
      .where((fr) => (fr.groupName?.trim() ?? '') == group)
      .toList();

  Future<void> _createGroup(BuildContext context) async {
    final name = await _promptGroupName(context);
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    final groupName = name.trim();
    final provider = context.read<FriendProvider>();
    final selected = await _pickGroupMembers(context, provider);
    if (selected == null || selected.isEmpty || !context.mounted) return;
    var failed = false;
    for (final friend in selected) {
      try {
        await provider.setFriendGroup(friend.friendId, groupName);
      } catch (_) {
        failed = true;
      }
    }
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context)!;
    if (failed) {
      GvToast.show(context, l10n.friendGroupCreateFailed);
      return;
    }
    await provider.loadFriendGroups();
    if (!context.mounted) return;
    GvToast.show(context, l10n.friendGroupCreateSuccess);
  }

  Future<String?> _promptGroupName(
    BuildContext context, {
    String initial = '',
    String? title,
  }) async {
    final controller = TextEditingController(text: initial);
    try {
      return await showDialog<String>(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
            actionsPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.start,
            buttonPadding: EdgeInsets.zero,
            title: Text(title ?? loc.friendGroupCreate),
            content: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(hintText: loc.friendGroupNameHint),
              onSubmitted: (_) => Navigator.pop(ctx, controller.text),
            ),
            actions: [
              GvDialogActions.weChatFooter(
                ctx,
                secondaryText: loc.commonCancel,
                primaryText: loc.commonConfirm,
                onSecondary: () => Navigator.pop(ctx),
                onPrimary: () => Navigator.pop(ctx, controller.text),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  /// 新建分组时选择要移入该分组的好友；取消返回 null。
  Future<List<FriendItem>?> _pickGroupMembers(
    BuildContext context,
    FriendProvider provider,
  ) async {
    final selected = <FriendItem>[];
    final friends = List<FriendItem>.from(provider.friends);
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.7,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              loc.friendGroupCreate,
                              style: GvTypography.navTitle(
                                AppColors.textPrimary.resolveFrom(ctx),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: selected.isEmpty
                                ? null
                                : () => Navigator.pop(ctx, true),
                            child: Text(loc.commonConfirm),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: friends.isEmpty
                          ? Center(child: Text(loc.friendGroupEmpty))
                          : ListView.builder(
                              itemCount: friends.length,
                              itemBuilder: (_, i) {
                                final fr = friends[i];
                                final isSelected = selected
                                    .any((s) => s.friendId == fr.friendId);
                                return CheckboxListTile(
                                  value: isSelected,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  onChanged: (v) => setSheetState(() {
                                    if (v == true) {
                                      selected.add(fr);
                                    } else {
                                      selected.removeWhere(
                                        (s) => s.friendId == fr.friendId,
                                      );
                                    }
                                  }),
                                  secondary: GvAvatar(
                                    name: fr.displayName,
                                    uid: fr.friendId,
                                    src: fr.friendUser?.avatar,
                                    size: 36,
                                  ),
                                  title: Text(fr.displayName),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return confirmed == true ? selected : null;
  }

  void _showGroupMembers(BuildContext context, String group) {
    final f = context.read<FriendProvider>();
    final members = _friendsInGroup(f, group);
    showGvIosModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  group,
                  style: GvTypography.navTitle(
                    AppColors.textPrimary.resolveFrom(ctx),
                  ),
                ),
              ),
              if (members.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(loc.friendGroupEmpty),
                )
              else
                for (final member in members)
                  ListTile(
                    leading: GvAvatar(
                      name: member.displayName,
                      uid: member.friendId,
                      src: member.friendUser?.avatar,
                      size: 40,
                    ),
                    title: Text(member.displayName),
                    onTap: () {
                      Navigator.pop(ctx);
                      gvOpenContactFromContactsList(
                        context,
                        '${member.friendId}',
                      );
                    },
                  ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _renameGroup(BuildContext context, String groupName) async {
    final loc = AppLocalizations.of(context)!;
    final name = await _promptGroupName(
      context,
      initial: groupName,
      title: loc.friendGroupRename,
    );
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    final newName = name.trim();
    if (newName == groupName) return;
    final provider = context.read<FriendProvider>();
    try {
      await provider.renameFriendGroup(groupName, newName);
    } catch (_) {
      if (context.mounted) {
        GvToast.show(context, loc.friendGroupCreateFailed);
      }
      return;
    }
    if (context.mounted) {
      GvToast.show(context, loc.friendGroupRenameSuccess);
    }
  }

  Future<void> _deleteGroup(BuildContext context, String groupName) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.friendGroupDelete),
        content: Text(loc.friendGroupDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final provider = context.read<FriendProvider>();
    try {
      await provider.deleteFriendGroup(groupName);
    } catch (_) {
      if (context.mounted) {
        GvToast.show(context, loc.friendGroupCreateFailed);
      }
      return;
    }
    if (context.mounted) {
      GvToast.show(context, loc.friendGroupDeleteSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = context.watch<FriendProvider>();
    final names = _groupNames(f);

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.friendGroupsTitle, showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          GvCardShell(
            borderRadius: BorderRadius.circular(GvRadii.card),
            child: Material(
              color: AppColors.bgWhite.resolveFrom(context),
              child: ListTile(
                leading: Icon(
                  LucideIcons.folder_plus,
                  color: AppColors.primary.resolveFrom(context),
                ),
                title: Text(l10n.friendGroupCreate),
                onTap: () => _createGroup(context),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (names.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                child: Text(
                  l10n.friendGroupEmpty,
                  style: GvTypography.caption(
                    AppColors.textSecondary.resolveFrom(context),
                  ),
                ),
              ),
            )
          else
            GvCardShell(
              borderRadius: BorderRadius.circular(GvRadii.card),
              child: Material(
                color: AppColors.bgWhite.resolveFrom(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < names.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          thickness: 0.5,
                          color: AppColors.textHint
                              .resolveFrom(context)
                              .withValues(alpha: 0.22),
                        ),
                      ListTile(
                        leading: Icon(
                          LucideIcons.folder,
                          color: AppColors.textSecondary.resolveFrom(context),
                        ),
                        title: Text(names[i]),
                        subtitle: Text(
                          l10n.friendGroupMemberCount(
                            _friendsInGroup(f, names[i]).length,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: Icon(
                            LucideIcons.ellipsis_vertical,
                            color: AppColors.textHint.resolveFrom(context),
                          ),
                          onSelected: (action) {
                            if (action == 'rename') {
                              _renameGroup(context, names[i]);
                            } else if (action == 'delete') {
                              _deleteGroup(context, names[i]);
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'rename',
                              child: Text(l10n.friendGroupRename),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.friendGroupDelete),
                            ),
                          ],
                        ),
                        onTap: () => _showGroupMembers(context, names[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
