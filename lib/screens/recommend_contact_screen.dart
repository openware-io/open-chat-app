import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_toast.dart';
import '../core/message_preview.dart';
import '../core/namecard_message.dart';
import '../models/friend_models.dart';
import '../providers/chat_provider.dart';
import '../providers/client_remote_config_provider.dart';
import '../providers/friend_provider.dart';
import '../widgets/gv_avatar.dart';
import '../widgets/gv_nav_bar.dart';
import '../widgets/gv_search_bar.dart';

/// 将 [card] 以 `namecard` 消息发给所选好友（[GoRouter] `extra` 为 [NamecardPayload]）。
class RecommendContactScreen extends StatefulWidget {
  const RecommendContactScreen({super.key, required this.card});

  final NamecardPayload card;

  @override
  State<RecommendContactScreen> createState() => _RecommendContactScreenState();
}

class _RecommendContactScreenState extends State<RecommendContactScreen> {
  static const double _rowDividerIndent = 12 + 22 + 10 + 40 + 10;

  final _search = TextEditingController();
  int? _selectedFriendId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().loadFriends();
    });
  }

  List<FriendItem> _filtered(List<FriendItem> all) {
    final kw = _search.text.toLowerCase().trim();
    if (kw.isEmpty) return all;
    return all.where((x) => x.displayName.toLowerCase().contains(kw)).toList();
  }

  Future<void> _onSend() async {
    final fid = _selectedFriendId;
    if (fid == null) return;
    if (!context.read<ClientRemoteConfigProvider>().privateChatEnabled) {
      GvToast.show(
          context, AppLocalizations.of(context)!.featurePrivateChatDisabled);
      return;
    }
    final body = widget.card.encode();
    final chat = context.read<ChatProvider>();
    chat.sendMessage(
      '$fid',
      'private',
      'namecard',
      body,
      convPreview: previewTextFromContent('namecard', body),
    );
    if (!mounted) return;
    GvToast.show(context, AppLocalizations.of(context)!.toastSent);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friends = context.watch<FriendProvider>().friends;
    final myId = context.watch<ChatProvider>().myId;
    final targetId = widget.card.userId;
    final pool = friends.where((f) {
      if (myId != null && f.friendId == myId) return false;
      if (f.friendId == targetId) return false;
      return true;
    }).toList();
    final list = _filtered(pool);

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: l10n.recommendContactTitle,
        showBack: true,
        right: TextButton(
          onPressed: _selectedFriendId == null ? null : _onSend,
          child: Text(
            l10n.recommendContactAction,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: _selectedFriendId == null
                  ? AppColors.textHint.resolveFrom(context)
                  : AppColors.primary.resolveFrom(context),
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        friends.isEmpty
                            ? l10n.friendsEmpty
                            : l10n.friendsNoMatches,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary.resolveFrom(context),
                        ),
                      ),
                    )
                  : Align(
                      alignment: Alignment.topCenter,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GvCardShell(
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
                                    final sel =
                                        _selectedFriendId == fr.friendId;
                                    final primary =
                                        AppColors.primary.resolveFrom(context);
                                    return InkWell(
                                      onTap: () => setState(() {
                                        _selectedFriendId =
                                            sel ? null : fr.friendId;
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
                                                      ? primary
                                                      : const Color(
                                                          0xFFDDDDDD,
                                                        ),
                                                  width: 2,
                                                ),
                                                color: sel ? primary : null,
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
                                                style: const TextStyle(
                                                  fontSize: 17,
                                                ),
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
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
