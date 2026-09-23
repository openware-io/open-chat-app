import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/api_failure.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_chat_navigation.dart';
import '../core/gv_toast.dart';
import '../models/friend_models.dart';
import '../providers/chat_provider.dart';
import '../providers/client_remote_config_provider.dart';
import '../providers/friend_provider.dart';
import '../widgets/gv_avatar.dart';
import '../widgets/gv_nav_bar.dart';
import '../widgets/gv_search_bar.dart';

/// 发起私密群聊：从好友里多选成员（不含自己），创建后进入私密群聊聊天页。
class CreateSecretGroupScreen extends StatefulWidget {
  const CreateSecretGroupScreen({super.key});

  @override
  State<CreateSecretGroupScreen> createState() =>
      _CreateSecretGroupScreenState();
}

class _CreateSecretGroupScreenState extends State<CreateSecretGroupScreen> {
  /// 行内 padding 12 + 勾选 22 + 间距 10 + 头像 40 + 间距 10 → 名称左缘。
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!context.read<ClientRemoteConfigProvider>().secretGroupChatEnabled) {
        GvToast.show(context,
            AppLocalizations.of(context)!.featureSecretGroupChatDisabled);
        context.pop();
        return;
      }
      context.read<FriendProvider>().loadFriends();
    });
  }

  List<FriendItem> _filtered(List<FriendItem> all) {
    final kw = _search.text.toLowerCase();
    if (kw.isEmpty) return all;
    return all.where((f) => f.displayName.toLowerCase().contains(kw)).toList();
  }

  Future<void> _create(ChatProvider chat) async {
    if (_selected.isEmpty) return;
    if (!context.read<ClientRemoteConfigProvider>().secretGroupChatEnabled) {
      GvToast.show(
          context, AppLocalizations.of(context)!.featureSecretGroupChatDisabled);
      return;
    }
    try {
      final info = await chat.createSecretGroupChat(memberUserIds: _selected.toList());
      if (!mounted) return;
      GvToast.show(
        context,
        AppLocalizations.of(context)!.toastSecretGroupChatCreated,
        duration: const Duration(seconds: 1),
      );
      gvOpenChat(context, chatType: 'secret_group', peerId: info.id);
    } catch (e) {
      if (mounted) {
        GvToast.show(
          context,
          AppLocalizations.of(context)!.toastOperationFailed(ApiFailure.messageOf(e)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friends = context.watch<FriendProvider>().friends;
    final list = _filtered(friends);

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: l10n.secretGroupChatStartTitle,
        showBack: true,
        right: TextButton(
          onPressed: _selected.isEmpty
              ? null
              : () => _create(context.read<ChatProvider>()),
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
            barBackgroundColor: AppColors.bgWhite.resolveFrom(context),
            fillColor: AppColors.bgSearchField.resolveFrom(context),
            padding: const EdgeInsets.fromLTRB(
              GvSpacing.page,
              GvSpacing.searchBarOuterV,
              GvSpacing.page,
              GvSpacing.searchBarOuterV,
            ),
            fieldVerticalPadding: 8,
          ),
          if (_selected.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: GvSpacing.page, vertical: GvSpacing.sm),
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
                    label: Text(label,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12)),
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
