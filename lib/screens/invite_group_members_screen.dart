import 'package:flutter/material.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_toast.dart';
import '../models/friend_models.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../services/api_client.dart';
import '../widgets/gv_avatar.dart';
import '../widgets/gv_nav_bar.dart';
import '../widgets/gv_search_bar.dart';

/// 向已有群聊添加好友（非「添加好友」扫码/账号页）。
class InviteGroupMembersScreen extends StatefulWidget {
  const InviteGroupMembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  State<InviteGroupMembersScreen> createState() =>
      _InviteGroupMembersScreenState();
}

class _InviteGroupMembersScreenState extends State<InviteGroupMembersScreen> {
  /// 与 [CreateGroupScreen] 好友行布局一致：分割线从名称左缘起。
  static const double _rowDividerIndent = 12 + 22 + 10 + 40 + 10;

  final _search = TextEditingController();
  final _selected = <int>{};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final f = context.read<FriendProvider>();
      final g = context.read<GroupProvider>();
      f.loadFriends();
      final gid = int.tryParse(widget.groupId);
      if (gid != null) await g.loadMembers(gid);
    });
  }

  List<FriendItem> _filtered(List<FriendItem> all) {
    final kw = _search.text.toLowerCase();
    if (kw.isEmpty) return all;
    return all.where((x) => x.displayName.toLowerCase().contains(kw)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friends = context.watch<FriendProvider>().friends;
    final memberIds = context
        .watch<GroupProvider>()
        .currentGroupMembers
        .map((m) => m.userId)
        .toSet();
    final pool =
        friends.where((fr) => !memberIds.contains(fr.friendId)).toList();
    final list = _filtered(pool);

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: l10n.inviteGroupMembersTitle,
        showBack: true,
        right: TextButton(
          onPressed: _selected.isEmpty
              ? null
              : () async {
                  final gid = int.tryParse(widget.groupId);
                  if (gid == null) return;
                  try {
                    await context
                        .read<GroupProvider>()
                        .addMembers(gid, _selected.toList());
                    if (context.mounted) {
                      GvToast.show(
                        context,
                        AppLocalizations.of(context)!.toastMembersAdded,
                      );
                      context.pop();
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    final msg =
                        context.read<ApiClient>().extractErrorMessage(e);
                    GvToast.show(context, msg);
                  }
                },
          child: Text(
            l10n.createGroupDoneWithCount(_selected.length),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: _selected.isEmpty ? AppColors.textHint : AppColors.primary,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GvSearchBar(
            controller: _search,
            hint: l10n.createGroupSearchFriendsHint,
            onChanged: (_) => setState(() {}),
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GvSpacing.page,
                vertical: GvSpacing.sm,
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _selected.map((uid) {
                  var label = '$uid';
                  for (final x in friends) {
                    if (x.friendId == uid) {
                      label = x.displayName;
                      break;
                    }
                  }
                  return InputChip(
                    label: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    onDeleted: () => setState(() => _selected.remove(uid)),
                    deleteIconColor: Colors.white,
                    backgroundColor: AppColors.primary,
                  );
                }).toList(),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment.topCenter,
                    child: GvCardShell(
                      borderRadius: BorderRadius.circular(GvRadii.input),
                      child: Material(
                        color: AppColors.bgWhite.resolveFrom(context),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight,
                            minWidth: constraints.maxWidth,
                            maxWidth: constraints.maxWidth,
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            physics: const ClampingScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (ctx, __) => Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: _rowDividerIndent,
                              endIndent: 0,
                              color: AppColors.textHint
                                  .resolveFrom(ctx)
                                  .withValues(alpha: 0.22),
                            ),
                            itemBuilder: (_, i) {
                              final fr = list[i];
                              final sel = _selected.contains(fr.friendId);
                              return InkWell(
                                onTap: () => setState(() {
                                  if (sel) {
                                    _selected.remove(fr.friendId);
                                  } else {
                                    _selected.add(fr.friendId);
                                  }
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: sel
                                                ? AppColors.primary
                                                : const Color(0xFFDDDDDD),
                                            width: 2,
                                          ),
                                          color: sel ? AppColors.primary : null,
                                        ),
                                        child: sel
                                            ? const Icon(
                                                LucideIcons.check,
                                                size: 14,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 10),
                                      GvAvatar(
                                        name: fr.displayName,
                                        uid: fr.friendId,
                                        src: fr.friendUser?.avatar,
                                        size: 40,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          fr.displayName,
                                          style: const TextStyle(fontSize: 17),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
