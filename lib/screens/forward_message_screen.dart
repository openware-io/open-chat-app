import 'package:flutter/material.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_toast.dart';
import '../core/message_preview.dart';
import '../models/chat_message.dart';
import '../models/secret_chat_models.dart';
import '../models/secret_group_chat_models.dart';
import '../providers/chat_provider.dart';
import '../providers/client_remote_config_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../widgets/gv_avatar.dart';
import '../widgets/gv_nav_bar.dart';
import '../widgets/gv_search_bar.dart';

/// 转发消息：可选好友（单聊）、群聊、私密聊天、私密群聊。
///
/// 私密聊天 / 私密群聊作为**来源**时不可转发（入口已按 [gvChatMessageCanForward] 拦截），
/// 但作为**目标**时允许接收转发（单聊/群聊内容可以转入密聊/密群）。
class ForwardMessageScreen extends StatefulWidget {
  const ForwardMessageScreen({super.key, required this.message});

  final ChatMessage message;

  @override
  State<ForwardMessageScreen> createState() => _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends State<ForwardMessageScreen> {
  final _search = TextEditingController();
  String _selectedChatType = '';
  String _selectedTargetId = '';
  List<SecretChatInfo> _secretChats = const [];
  List<SecretGroupChatInfo> _secretGroups = const [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = context.read<ChatProvider>();
      context.read<FriendProvider>().loadFriends();
      context.read<GroupProvider>().loadGroups();
      chat.mySecretChats().then((list) {
        if (mounted) setState(() => _secretChats = list);
      }).catchError((_) {});
      chat.mySecretGroupChats().then((list) {
        if (mounted) setState(() => _secretGroups = list);
      }).catchError((_) {});
    });
  }

  String _secretChatName(
    SecretChatInfo info,
    FriendProvider friend,
    AppLocalizations l10n,
  ) {
    final pid = info.peerUserId;
    if (pid != null) {
      final fd = friend.getFriendDisplay(pid);
      final n = fd?.name.trim();
      if (n != null && n.isNotEmpty) return n;
    }
    return l10n.convTypeSecret;
  }

  String _secretGroupName(SecretGroupChatInfo info, AppLocalizations l10n) {
    final n = info.name?.trim() ?? '';
    return n.isNotEmpty ? n : l10n.secretGroupChatDefaultTitle;
  }

  Future<void> _onForward() async {
    if (_selectedTargetId.isEmpty) return;
    final cfg = context.read<ClientRemoteConfigProvider>();
    final l10n = AppLocalizations.of(context)!;
    final disabled = switch (_selectedChatType) {
      'private' => !cfg.privateChatEnabled ? l10n.featurePrivateChatDisabled : null,
      'secret' => !cfg.secretChatEnabled ? l10n.featureSecretChatDisabled : null,
      'secret_group' =>
        !cfg.secretGroupChatEnabled ? l10n.featureSecretGroupChatDisabled : null,
      _ => null,
    };
    if (disabled != null) {
      GvToast.show(context, disabled);
      return;
    }

    final chat = context.read<ChatProvider>();
    final m = widget.message;
    final preview = previewTextFromContent(m.msgType, m.content);
    chat.sendMessage(
      _selectedTargetId,
      _selectedChatType,
      m.msgType,
      m.content,
      convPreview: preview.isEmpty ? null : preview,
    );
    if (!mounted) return;
    GvToast.show(context, l10n.toastForwarded);
    context.pop();
  }

  void _select(String chatType, String targetId) {
    setState(() {
      if (_selectedChatType == chatType && _selectedTargetId == targetId) {
        _selectedChatType = '';
        _selectedTargetId = '';
      } else {
        _selectedChatType = chatType;
        _selectedTargetId = targetId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friends = context.watch<FriendProvider>().friends;
    final groups = context.watch<GroupProvider>().groups;
    final myId = context.watch<ChatProvider>().myId;

    final kw = _search.text.toLowerCase().trim();
    final friendPool = myId == null
        ? friends
        : friends.where((f) => f.friendId != myId).toList();
    final filteredFriends = kw.isEmpty
        ? friendPool
        : friendPool
            .where((f) => f.displayName.toLowerCase().contains(kw))
            .toList();
    final filteredGroups = kw.isEmpty
        ? groups
        : groups.where((g) => g.name.toLowerCase().contains(kw)).toList();
    final filteredSecretChats = kw.isEmpty
        ? _secretChats
        : _secretChats
            .where((s) => _secretChatName(
                  s,
                  context.read<FriendProvider>(),
                  l10n,
                ).toLowerCase().contains(kw))
            .toList();
    final filteredSecretGroups = kw.isEmpty
        ? _secretGroups
        : _secretGroups
            .where((s) =>
                _secretGroupName(s, l10n).toLowerCase().contains(kw))
            .toList();

    final hasAny = filteredFriends.isNotEmpty ||
        filteredGroups.isNotEmpty ||
        filteredSecretChats.isNotEmpty ||
        filteredSecretGroups.isNotEmpty;

    Widget row({
      required Key? key,
      required String avatarName,
      required int uid,
      required String? avatarSrc,
      required String title,
      required String chatType,
      required String targetId,
    }) {
      final selected =
          _selectedChatType == chatType && _selectedTargetId == targetId;
      final primary = AppColors.primary.resolveFrom(context);
      return InkWell(
        key: key,
        onTap: () => _select(chatType, targetId),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? primary : const Color(0xFFDDDDDD),
                    width: 2,
                  ),
                  color: selected ? primary : null,
                ),
                child: selected
                    ? const Icon(LucideIcons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              GvAvatar(name: avatarName, uid: uid, src: avatarSrc, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget sectionHeader(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary.resolveFrom(context),
            ),
          ),
        );

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(
        title: l10n.forwardMessageTitle,
        showBack: true,
        right: TextButton(
          onPressed: _selectedTargetId.isEmpty ? null : _onForward,
          child: Text(
            l10n.forwardMessageAction,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: _selectedTargetId.isEmpty
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
              child: !hasAny
                  ? Center(
                      child: Text(
                        l10n.friendsNoMatches,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary.resolveFrom(context),
                        ),
                      ),
                    )
                  : ListView(
                      children: [
                        if (filteredFriends.isNotEmpty) ...[
                          sectionHeader(l10n.channelShareSectionFriends),
                          GvCardShell(
                            borderRadius: BorderRadius.circular(GvRadii.input),
                            child: Material(
                              color: AppColors.bgWhite.resolveFrom(context),
                              child: Column(
                                children: [
                                  for (final f in filteredFriends)
                                    row(
                                      key: null,
                                      avatarName: f.displayName,
                                      uid: f.friendId,
                                      avatarSrc: f.friendUser?.avatar,
                                      title: f.displayName,
                                      chatType: 'private',
                                      targetId: '${f.friendId}',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (filteredGroups.isNotEmpty) ...[
                          sectionHeader(l10n.channelShareSectionGroups),
                          GvCardShell(
                            borderRadius: BorderRadius.circular(GvRadii.input),
                            child: Material(
                              color: AppColors.bgWhite.resolveFrom(context),
                              child: Column(
                                children: [
                                  for (final g in filteredGroups)
                                    row(
                                      key: null,
                                      avatarName: g.name,
                                      uid: g.id,
                                      avatarSrc: g.avatar,
                                      title: g.name,
                                      chatType: 'group',
                                      targetId: '${g.id}',
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (filteredSecretChats.isNotEmpty) ...[
                          sectionHeader(l10n.convTypeSecret),
                          GvCardShell(
                            borderRadius: BorderRadius.circular(GvRadii.input),
                            child: Material(
                              color: AppColors.bgWhite.resolveFrom(context),
                              child: Column(
                                children: [
                                  for (final s in filteredSecretChats)
                                    row(
                                      key: null,
                                      avatarName: _secretChatName(
                                        s,
                                        context.read<FriendProvider>(),
                                        l10n,
                                      ),
                                      uid: s.peerUserId ?? 0,
                                      avatarSrc: null,
                                      title: _secretChatName(
                                        s,
                                        context.read<FriendProvider>(),
                                        l10n,
                                      ),
                                      chatType: 'secret',
                                      targetId: s.id,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (filteredSecretGroups.isNotEmpty) ...[
                          sectionHeader(l10n.convTypeSecretGroup),
                          GvCardShell(
                            borderRadius: BorderRadius.circular(GvRadii.input),
                            child: Material(
                              color: AppColors.bgWhite.resolveFrom(context),
                              child: Column(
                                children: [
                                  for (final s in filteredSecretGroups)
                                    row(
                                      key: null,
                                      avatarName: _secretGroupName(s, l10n),
                                      uid: int.tryParse(s.id) ?? 0,
                                      avatarSrc: null,
                                      title: _secretGroupName(s, l10n),
                                      chatType: 'secret_group',
                                      targetId: s.id,
                                    ),
                                ],
                              ),
                            ),
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
