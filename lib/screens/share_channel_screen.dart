import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_channel_code.dart';
import '../core/gv_toast.dart';
import '../l10n/app_localizations.dart';
import '../models/channel_models.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/gv_avatar.dart';
import '../widgets/gv_nav_bar.dart';
import '../widgets/gv_search_bar.dart';

/// 把频道分享信息（名称 + 频道号 + `GV_CHANNEL` 码）作为一条文本消息转发到所选会话。
///
/// 会话范围：好友（私聊）、群聊、以及当前用户拥有的频道（仅管理员可发布）。
class ShareChannelScreen extends StatefulWidget {
  const ShareChannelScreen({super.key, required this.channel});

  final ChannelInfo channel;

  @override
  State<ShareChannelScreen> createState() => _ShareChannelScreenState();
}

class _ShareChannelScreenState extends State<ShareChannelScreen> {
  final _search = TextEditingController();
  List<ChannelInfo> _channels = const [];

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
      context.read<GroupProvider>().loadGroups();
      context.read<ChatProvider>().myChannels().then((list) {
        if (mounted) setState(() => _channels = list);
      }).catchError((_) {});
    });
  }

  String _shareText(AppLocalizations l10n) {
    final c = widget.channel;
    return [
      '${l10n.channelShareTitle}: ${c.name}',
      if (c.code.isNotEmpty) '${l10n.channelShareCodeLabel}: ${c.code}',
      if (c.code.isNotEmpty) buildGvChannelCodePayload(c.code),
    ].join('\n');
  }

  Future<void> _sendTo(String toId, String chatType) async {
    final l10n = AppLocalizations.of(context)!;
    final chat = context.read<ChatProvider>();
    chat.sendMessage(
      toId,
      chatType,
      'text',
      _shareText(l10n),
      convPreview: '${l10n.channelShareTitle}: ${widget.channel.name}',
    );
    if (!mounted) return;
    GvToast.show(context, l10n.toastForwarded);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friends = context.watch<FriendProvider>().friends;
    final groups = context.watch<GroupProvider>().groups;
    final myId = context.watch<ChatProvider>().myId;

    final friendPool = myId == null
        ? friends
        : friends.where((f) => f.friendId != myId).toList();
    final ownedChannels =
        _channels.where((c) => c.isOwner && c.id != widget.channel.id).toList();

    final kw = _search.text.toLowerCase().trim();
    final filteredFriends = kw.isEmpty
        ? friendPool
        : friendPool
            .where((f) => f.displayName.toLowerCase().contains(kw))
            .toList();
    final filteredGroups = kw.isEmpty
        ? groups
        : groups.where((g) => g.name.toLowerCase().contains(kw)).toList();
    final filteredChannels = kw.isEmpty
        ? ownedChannels
        : ownedChannels
            .where((c) =>
                c.name.toLowerCase().contains(kw) ||
                c.code.toLowerCase().contains(kw))
            .toList();

    final hasAny =
        friendPool.isNotEmpty || groups.isNotEmpty || ownedChannels.isNotEmpty;
    final nothingMatched = filteredFriends.isEmpty &&
        filteredGroups.isEmpty &&
        filteredChannels.isEmpty;

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: l10n.channelShareToChat,
        showBack: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GvSearchBar(
            controller: _search,
            hint: l10n.channelShareSearchHint,
            onChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
              child: !hasAny
                  ? Center(
                      child: Text(
                        l10n.channelShareEmpty,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary.resolveFrom(context),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(top: GvSpacing.sm),
                      children: [
                        if (filteredFriends.isNotEmpty) ...[
                          _sectionHeader(l10n.channelShareSectionFriends),
                          _card(
                            filteredFriends.map((f) {
                              return _row(
                                icon: GvAvatar(
                                  name: f.displayName,
                                  uid: f.friendId,
                                  src: f.friendUser?.avatar,
                                  size: 40,
                                ),
                                title: f.displayName,
                                onTap: () =>
                                    _sendTo('${f.friendId}', 'private'),
                              );
                            }).toList(),
                          ),
                        ],
                        if (filteredGroups.isNotEmpty) ...[
                          _sectionHeader(l10n.channelShareSectionGroups),
                          _card(
                            filteredGroups.map((g) {
                              return _row(
                                icon: GvAvatar(
                                  name: g.name,
                                  uid: g.id,
                                  src: g.avatar,
                                  size: 40,
                                ),
                                title: g.name,
                                onTap: () => _sendTo('${g.id}', 'group'),
                              );
                            }).toList(),
                          ),
                        ],
                        if (filteredChannels.isNotEmpty) ...[
                          _sectionHeader(l10n.channelShareSectionChannels),
                          _card(
                            filteredChannels.map((c) {
                              return _row(
                                icon: const Icon(
                                  LucideIcons.hash,
                                  size: 22,
                                ),
                                title: c.name,
                                onTap: () => _sendTo(c.id, 'channel'),
                              );
                            }).toList(),
                          ),
                        ],
                        if (nothingMatched)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                l10n.channelShareNoMatch,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textSecondary
                                      .resolveFrom(context),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: GvTypography.caption(
          AppColors.textSecondary.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _card(List<Widget> rows) {
    return GvCardShell(
      borderRadius: BorderRadius.circular(GvRadii.input),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 12,
                  endIndent: 0,
                  color: AppColors.textHint
                      .resolveFrom(context)
                      .withValues(alpha: 0.22),
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _row({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 40, height: 40, child: Center(child: icon)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17),
              ),
            ),
            Icon(
              LucideIcons.send,
              size: 16,
              color: AppColors.textHint.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}
