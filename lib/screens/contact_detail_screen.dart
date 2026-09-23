import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_chat_navigation.dart';
import '../core/open_secondary_navigation.dart';
import '../core/open_toast.dart';
import '../core/namecard_message.dart';
import '../models/friend_models.dart';
import '../models/im_user.dart';
import '../providers/auth_provider.dart';
import '../providers/call_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/client_remote_config_provider.dart';
import '../providers/friend_provider.dart';
import '../services/api_client.dart';
import '../services/im_api.dart';
import '../widgets/open_avatar.dart';
import '../widgets/open_dialog_actions.dart';
import '../widgets/open_nav_bar.dart';
import '../widgets/open_report_dialog.dart';

class ContactDetailScreen extends StatefulWidget {
  const ContactDetailScreen(
      {super.key,
      required this.id,
      this.fromGroup = false,
      this.sourceGroupId,
      this.hideAccountDetails = false,
      this.hideFriendRequest = false});

  final String id;
  final bool fromGroup;
  final int? sourceGroupId;
  final bool hideAccountDetails;
  final bool hideFriendRequest;

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  static const bool _showCallActions = true;

  /// 黑名单功能暂不开放；保留底层实现，后续恢复时只需开启此开关。
  static const bool _blacklistFeatureEnabled = false;

  /// 资料页各独立卡片（头像区 / 备注 / 通话 / 主按钮 / 危险操作）之间的垂直间距。
  static const double _cardGap = GvSpacing.page;

  ImUser? _fetchedUser;
  bool _profileLoading = false;

  /// 本页已成功发出好友申请（展示「已发送」）。
  bool _friendRequestSentThisSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<FriendProvider>();
      await provider.loadFriends();
      await provider.loadBlockedList();
      if (!mounted) return;
      await _ensureProfileLoaded();
      if (!mounted) return;
      _syncConversationDisplayFromCurrentProfile();
    });
  }

  void _syncConversationDisplayFromCurrentProfile() {
    final uid = int.tryParse(widget.id);
    if (uid == null) return;
    final display = context.read<FriendProvider>().getFriendDisplay(uid);
    final profile = _fetchedUser;
    final name = display?.name.trim() ?? profile?.displayName.trim() ?? '';
    if (name.isEmpty) return;
    context.read<ChatProvider>().updateConversationDisplay(
          widget.id,
          'private',
          name: name,
          avatar: display?.avatar ?? profile?.avatar ?? '',
        );
  }

  /// 非好友关系时（例如从群成员点进）拉取用户资料；本人用 [AuthProvider]，不请求接口。
  Future<void> _ensureProfileLoaded() async {
    final uid = int.tryParse(widget.id);
    if (uid == null) return;
    final me = context.read<AuthProvider>().user?.id;
    if (me == uid) return;
    if (_friend(context.read<FriendProvider>().friends) != null) return;

    setState(() => _profileLoading = true);
    try {
      final u = await context.read<FriendProvider>().loadUserProfile(uid);
      if (mounted) {
        setState(() {
          _fetchedUser = u;
          _profileLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _profileLoading = false);
    }
  }

  /// 与弹窗「取消」一致的灰底，文字仍为危险色。
  ButtonStyle _grayDangerActionStyle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    return TextButton.styleFrom(
      foregroundColor: AppColors.danger.resolveFrom(context),
      backgroundColor: bg,
      padding: const EdgeInsets.symmetric(vertical: 14),
      minimumSize: const Size(double.infinity, 48),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GvRadii.input),
      ),
    );
  }

  FriendItem? _friend(List<FriendItem> friends) {
    final fid = int.tryParse(widget.id);
    if (fid == null) return null;
    for (final f in friends) {
      if (f.friendId == fid) return f;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = context.watch<FriendProvider>();
    final auth = context.watch<AuthProvider>();
    final remote = context.watch<ClientRemoteConfigProvider>();
    final friend = _friend(f.friends);
    final uid = int.tryParse(widget.id);
    final myId = auth.user?.id;
    final isSelf = myId != null && uid != null && myId == uid;
    final isFriend = friend != null;
    final isBlocked = uid != null && f.isBlocked(uid);
    final showRestrictedGroupProfile = widget.hideAccountDetails && !isSelf;

    late final String name;
    late final String accountLine;
    final String? avatarSrc;
    final String? signature;

    if (isSelf && auth.user != null) {
      final u = auth.user!;
      name = u.displayName.isNotEmpty
          ? u.displayName
          : l10n.displayUserIdLabel('${u.id}');
      accountLine = u.username.isNotEmpty ? u.username : u.id.toString();
      avatarSrc = u.avatar;
      signature = u.signature;
    } else if (friend != null) {
      final fu = friend.friendUser;
      name = friend.displayName;
      accountLine = (fu != null && fu.username.isNotEmpty)
          ? fu.username
          : (uid != null ? uid.toString() : widget.id);
      avatarSrc = fu?.avatar;
      signature = fu?.signature;
    } else if (_fetchedUser != null) {
      final u = _fetchedUser!;
      name = u.displayName.isNotEmpty
          ? u.displayName
          : l10n.displayUserIdLabel('${u.id}');
      accountLine = u.username.isNotEmpty ? u.username : u.id.toString();
      avatarSrc = u.avatar;
      signature = u.signature;
    } else {
      name = uid != null
          ? l10n.displayUserIdLabel('$uid')
          : l10n.displayUserIdLabel(widget.id);
      accountLine = widget.id;
      avatarSrc = null;
      signature = null;
    }

    final children = <Widget>[
      GvCardShell(
        borderRadius: BorderRadius.circular(GvRadii.card),
        child: Material(
          color: AppColors.bgWhite.resolveFrom(context),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_profileLoading &&
                    !isSelf &&
                    friend == null &&
                    _fetchedUser == null)
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary.resolveFrom(context),
                        ),
                      ),
                    ),
                  )
                else
                  GvAvatar(
                    name: name,
                    uid: widget.id,
                    src: avatarSrc,
                    size: 60,
                  ),
                const SizedBox(width: GvSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GvTypography.title(
                          AppColors.textPrimary.resolveFrom(context),
                        ),
                      ),
                      if (!showRestrictedGroupProfile) ...[
                        Text(
                          l10n.contactAccountLine(accountLine),
                          style: GvTypography.caption(
                            AppColors.textSecondary.resolveFrom(context),
                          ),
                        ),
                        if ((signature ?? '').isNotEmpty)
                          Text(
                            signature!,
                            style: GvTypography.caption(
                              AppColors.textSecondary.resolveFrom(context),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];

    if (!isSelf && isFriend) {
      children.add(const SizedBox(height: _cardGap));
      children.add(_remarkAndChatHistoryCard(context, friend, l10n));
      children.add(const SizedBox(height: _cardGap));
      if (_showCallActions &&
          (remote.voiceCallEnabled || remote.videoCallEnabled)) {
        children.add(_callOptionsCard(context, name, remote, l10n));
      }
      // 私密聊天（E2EE 形态）入口：从好友详情页新建独立私密会话。
      if (remote.secretChatEnabled) {
        children.add(const SizedBox(height: _cardGap));
        children.add(_secretChatEntryCard(context, name, l10n));
      }
    }

    if (!isSelf &&
        !(isFriend && !remote.privateChatEnabled) &&
        !(widget.hideFriendRequest && !isFriend)) {
      children.add(const SizedBox(height: _cardGap));
      children.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: uid == null ||
                    (!isFriend && _friendRequestSentThisSession)
                ? null
                : () async {
                    if (isFriend) {
                      if (!context
                          .read<ClientRemoteConfigProvider>()
                          .privateChatEnabled) {
                        GvToast.show(
                          context,
                          AppLocalizations.of(context)!
                              .featurePrivateChatDisabled,
                        );
                        return;
                      }
                      final chat = context.read<ChatProvider>();
                      chat.upsertConversation(widget.id, 'private', '',
                          incrementUnread: false, name: name);
                      gvOpenChat(context,
                          chatType: 'private', peerId: widget.id);
                      return;
                    }
                    try {
                      await context.read<FriendProvider>().sendRequest(
                            uid,
                            '',
                            source: widget.fromGroup ? 'group' : null,
                            groupId: widget.sourceGroupId,
                          );
                      if (context.mounted) {
                        setState(() => _friendRequestSentThisSession = true);
                        GvToast.show(
                          context,
                          AppLocalizations.of(context)!
                              .toastFriendRequestSentDetail,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        final api = context.read<ApiClient>();
                        final raw = api.extractErrorMessage(e);
                        final msg = raw.toLowerCase();
                        final alreadyFriend =
                            msg.contains('already') && msg.contains('friend');
                        final groupForbid = raw.contains('已禁用添加群成员');
                        GvToast.show(
                          context,
                          alreadyFriend
                              ? AppLocalizations.of(context)!
                                  .addFriendAlreadyFriends
                              : groupForbid
                                  ? AppLocalizations.of(context)!
                                      .groupMemberFriendRequestDisabled
                                  : AppLocalizations.of(context)!
                                      .toastOperationFailed(raw),
                        );
                      }
                    }
                  },
            child: Text(
              isFriend
                  ? l10n.contactSendMessage
                  : (_friendRequestSentThisSession
                      ? l10n.addFriendRequestSent
                      : l10n.addFriendTitle),
            ),
          ),
        ),
      );
    }

    if (!isSelf && (isFriend || isBlocked) && _blacklistFeatureEnabled) {
      children.add(const SizedBox(height: _cardGap));
      children.add(
        TextButton(
          style: _grayDangerActionStyle(context),
          onPressed: () async {
            final fid = int.tryParse(widget.id);
            if (fid == null) return;
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final loc = AppLocalizations.of(ctx)!;
                return AlertDialog(
                  actionsPadding: EdgeInsets.zero,
                  actionsAlignment: MainAxisAlignment.start,
                  buttonPadding: EdgeInsets.zero,
                  title: Text(
                    isBlocked ? loc.contactUnblockTitle : loc.contactBlockTitle,
                  ),
                  content: Text(
                    isBlocked
                        ? loc.contactUnblockConfirmBody
                        : loc.contactBlockConfirmBody,
                  ),
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
              if (isBlocked) {
                await f.unblockFriend(fid);
              } else {
                await f.blockFriend(fid);
                if (context.mounted) context.pop();
              }
            }
          },
          child: Text(
            isBlocked ? l10n.contactUnblockAction : l10n.contactBlockAction,
          ),
        ),
      );
    }
    if (!isSelf && isFriend) {
      children.add(const SizedBox(height: _cardGap));
      children.add(
        TextButton(
          style: _grayDangerActionStyle(context),
          onPressed: () async {
            final fid = int.tryParse(widget.id);
            if (fid == null) return;
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) {
                final loc = AppLocalizations.of(ctx)!;
                return AlertDialog(
                  actionsPadding: EdgeInsets.zero,
                  actionsAlignment: MainAxisAlignment.start,
                  buttonPadding: EdgeInsets.zero,
                  title: Text(loc.contactDeleteFriendTitle),
                  content: Text(loc.contactDeleteFriendConfirmBody),
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
              await f.removeFriend(fid);
              if (!context.mounted) return;
              context
                  .read<ChatProvider>()
                  .removeConversation(widget.id, 'private');
              if (context.mounted) {
                gvNavigateContactsAfterRemoveOnDesktop(context);
              }
            }
          },
          child: Text(l10n.contactDeleteFriendAction),
        ),
      );
    }

    if (!isSelf) {
      children.add(const SizedBox(height: _cardGap));
      children.add(
        TextButton(
          style: _grayDangerActionStyle(context),
          onPressed: uid == null
              ? null
              : () => showReportDialog(
                    context,
                    api: context.read<ImApi>(),
                    targetUserId: uid,
                    targetName: name,
                  ),
          child: Text(l10n.contactReport),
        ),
      );
    }

    Widget body = ListView(
      padding: const EdgeInsets.all(GvSpacing.page),
      children: children,
    );
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.contactDetailTitle, showBack: true),
      body: body,
    );
  }

  /// 备注与聊天记录同卡，中间分割线与 [_callOptionsCard] 一致。
  Widget _detailActionRow(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
    Widget? leading,
    Widget? trailing,
  }) {
    return GvActionRow(
      title: title,
      titleStyle: GvTypography.navTitle(
        AppColors.textPrimary.resolveFrom(context),
      ),
      onTap: onTap,
      leading: leading,
      trailing: trailing,
      padding: const EdgeInsets.symmetric(
        horizontal: GvSpacing.page,
        vertical: GvSpacing.page,
      ),
    );
  }

  Widget _detailValueRow(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return GvValueActionRow(
      title: title,
      titleStyle: GvTypography.navTitle(
        AppColors.textPrimary.resolveFrom(context),
      ),
      value: value,
      valueStyle: GvTypography.caption(
        AppColors.textSecondary.resolveFrom(context),
      ),
      onTap: onTap,
      trailing: Icon(
        LucideIcons.chevron_right,
        color: AppColors.textHint.resolveFrom(context),
      ),
    );
  }

  String _friendGroupLabel(FriendItem friend, AppLocalizations l10n) {
    final group = friend.groupName?.trim() ?? '';
    return group.isEmpty ? l10n.friendGroupNoGroup : group;
  }

  /// 弹出分组选择（含「无分组」与「新建分组」），选择后通过 [FriendProvider.setFriendGroup] 落库。
  Future<void> _setFriendGroup(BuildContext context, FriendItem friend) async {
    final provider = context.read<FriendProvider>();
    await provider.loadFriendGroups();
    if (!context.mounted) return;

    final current = friend.groupName?.trim() ?? '';
    const createAction = '__create_group__';
    final selected = await showGvIosModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        final primary = AppColors.primary.resolveFrom(ctx);
        final options = <String>[
          '',
          ...provider.friendGroups.where((g) => g.trim().isNotEmpty),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final group in options)
                ListTile(
                  title: Text(
                    group.isEmpty ? loc.friendGroupNoGroup : group,
                  ),
                  trailing: current == group
                      ? Icon(Icons.check, color: primary)
                      : null,
                  onTap: () => Navigator.pop(ctx, group),
                ),
              ListTile(
                leading: Icon(Icons.add, color: primary),
                title: Text(
                  loc.friendGroupCreate,
                  style: TextStyle(color: primary),
                ),
                onTap: () => Navigator.pop(ctx, createAction),
              ),
            ],
          ),
        );
      },
    );
    if (!context.mounted) return;
    if (selected == createAction) {
      await _createGroupAndAssign(context, friend);
    } else if (selected != null) {
      await provider.setFriendGroup(friend.friendId, selected);
    }
  }

  /// 「新建分组」后直接把当前好友移入该分组。
  Future<void> _createGroupAndAssign(
    BuildContext context,
    FriendItem friend,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final dl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          title: Text(dl.friendGroupCreate),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(hintText: dl.friendGroupNameHint),
            onSubmitted: (_) => Navigator.pop(ctx, controller.text),
          ),
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: dl.commonCancel,
              primaryText: dl.commonConfirm,
              onSecondary: () => Navigator.pop(ctx),
              onPrimary: () => Navigator.pop(ctx, controller.text),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    final provider = context.read<FriendProvider>();
    await provider.setFriendGroup(friend.friendId, name.trim());
    await provider.loadFriendGroups();
    if (context.mounted) {
      GvToast.show(context, loc.friendGroupCreateSuccess);
    }
  }

  Widget _remarkAndChatHistoryCard(
    BuildContext context,
    FriendItem friend,
    AppLocalizations l10n,
  ) {
    final dividerColor = Theme.of(context).dividerColor;
    final hint = AppColors.textHint.resolveFrom(context);
    return GvCardShell(
      borderRadius: BorderRadius.circular(GvRadii.card),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _detailValueRow(
              context,
              title: l10n.contactRemarkLabel,
              value: friend.remark ?? l10n.contactRemarkNotSet,
              onTap: () async {
                final ok = await showDialog<String>(
                  context: context,
                  builder: (ctx) => _ContactRemarkEditDialog(
                    initialText: friend.remark ?? '',
                  ),
                );
                if (ok != null && context.mounted) {
                  await context
                      .read<FriendProvider>()
                      .updateFriendRemark(friend.friendId, ok);
                  if (context.mounted) {
                    _syncConversationDisplayFromCurrentProfile();
                  }
                }
              },
            ),
            SizedBox(
              height: 0.5,
              child: ColoredBox(color: dividerColor),
            ),
            _detailValueRow(
              context,
              title: l10n.setFriendGroupTitle,
              value: _friendGroupLabel(friend, l10n),
              onTap: () => _setFriendGroup(context, friend),
            ),
            SizedBox(
              height: 0.5,
              child: ColoredBox(color: dividerColor),
            ),
            _detailActionRow(
              context,
              title: l10n.contactRecommendToFriends,
              trailing: Icon(LucideIcons.chevron_right, color: hint),
              onTap: () {
                if (!context
                    .read<ClientRemoteConfigProvider>()
                    .privateChatEnabled) {
                  GvToast.show(
                    context,
                    AppLocalizations.of(context)!.featurePrivateChatDisabled,
                  );
                  return;
                }
                final uid = friend.friendId;
                final fu = friend.friendUser;
                final un = (fu?.username ?? '').trim().isNotEmpty
                    ? fu!.username.trim()
                    : '$uid';
                context.push(
                  '/recommend-contact',
                  extra: NamecardPayload(
                    userId: uid,
                    displayName: friend.displayName,
                    username: un,
                    avatar: fu?.avatar,
                  ),
                );
              },
            ),
            SizedBox(
              height: 0.5,
              child: ColoredBox(color: dividerColor),
            ),
            _detailActionRow(
              context,
              title: l10n.chatHistoryTitle,
              trailing: Icon(LucideIcons.chevron_right, color: hint),
              onTap: () => gvPushChatHistoryContact(context, widget.id),
            ),
            if (context
                .read<ClientRemoteConfigProvider>()
                .chatDeleteEnabled) ...[
              SizedBox(
                height: 0.5,
                child: ColoredBox(color: dividerColor),
              ),
              _detailActionRow(
                context,
                title: l10n.contactClearChatRow,
                onTap: () async {
                  var alsoDeleteServer = false;
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) {
                      final loc = AppLocalizations.of(ctx)!;
                      return StatefulBuilder(
                        builder: (ctx, setDialogState) => AlertDialog(
                          actionsPadding: EdgeInsets.zero,
                          actionsAlignment: MainAxisAlignment.start,
                          buttonPadding: EdgeInsets.zero,
                          title: Text(loc.contactClearChatTitle),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(loc.contactClearChatConfirmBody),
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: alsoDeleteServer,
                                title: Text(loc.chatClearAlsoDeleteServer),
                                onChanged: (v) => setDialogState(
                                    () => alsoDeleteServer = v ?? false),
                              ),
                            ],
                          ),
                          actions: [
                            GvDialogActions.weChatFooter(
                              ctx,
                              secondaryText: loc.commonCancel,
                              primaryText: loc.commonConfirm,
                              onSecondary: () => Navigator.pop(ctx, false),
                              onPrimary: () => Navigator.pop(ctx, true),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  if (ok != true || !context.mounted) return;
                  final chat = context.read<ChatProvider>();
                  if (alsoDeleteServer) {
                    await chat.clearPrivateChatOnServer(widget.id);
                  } else {
                    chat.clearChatLocally(widget.id, 'private');
                  }
                  if (!context.mounted) return;
                  GvToast.show(
                    context,
                    AppLocalizations.of(context)!.toastPrivateChatCleared,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 「发起私密聊天」入口卡：新建独立私密会话（E2EE 形态），成功后进私密聊天室。
  Widget _secretChatEntryCard(
    BuildContext context,
    String name,
    AppLocalizations l10n,
  ) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      onPressed: () => _startSecretChat(context, name),
      child: Text(l10n.secretChatStartTitle),
    );
  }

  Future<void> _startSecretChat(
      BuildContext context, String displayName) async {
    final uid = int.tryParse(widget.id);
    if (uid == null) return;
    final chat = context.read<ChatProvider>();
    try {
      final info = await chat.createSecretChat(
        peerUserId: uid,
        name: displayName,
      );
      if (!context.mounted) return;
      GvToast.show(
        context,
        AppLocalizations.of(context)!.toastSecretChatCreated,
        duration: const Duration(seconds: 1),
      );
      gvOpenChat(context, chatType: 'secret', peerId: info.id);
    } catch (e) {
      if (context.mounted) {
        GvToast.show(
          context,
          context.read<ApiClient>().extractErrorMessage(e),
        );
      }
    }
  }

  Widget _callOptionsCard(
    BuildContext context,
    String name,
    ClientRemoteConfigProvider remote,
    AppLocalizations l10n,
  ) {
    final dividerColor = Theme.of(context).dividerColor;
    final rows = <Widget>[];
    if (remote.voiceCallEnabled) {
      rows.add(
        _detailActionRow(
          context,
          title: l10n.contactVoiceCall,
          onTap: () => _startCall(context, name, 'audio'),
          leading: Icon(
            LucideIcons.phone,
            color: AppColors.primary.resolveFrom(context),
            size: 22,
          ),
        ),
      );
    }
    if (remote.voiceCallEnabled && remote.videoCallEnabled) {
      rows.add(
        SizedBox(
          height: 0.5,
          child: ColoredBox(color: dividerColor),
        ),
      );
    }
    if (remote.videoCallEnabled) {
      rows.add(
        _detailActionRow(
          context,
          title: l10n.contactVideoCall,
          onTap: () => _startCall(context, name, 'video'),
          leading: Icon(
            LucideIcons.video,
            color: AppColors.primary.resolveFrom(context),
            size: 22,
          ),
        ),
      );
    }

    return GvCardShell(
      borderRadius: BorderRadius.circular(GvRadii.card),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }

  void _startCall(BuildContext context, String displayName, String type) {
    unawaited(_startCallAsync(context, displayName, type));
  }

  Future<void> _startCallAsync(
      BuildContext context, String displayName, String type) async {
    final remote = context.read<ClientRemoteConfigProvider>();
    if (type == 'video' && !remote.videoCallEnabled) {
      GvToast.show(
          context, AppLocalizations.of(context)!.toastVideoCallDisabled);
      return;
    }
    if (type != 'video' && !remote.voiceCallEnabled) {
      GvToast.show(
          context, AppLocalizations.of(context)!.toastVoiceCallDisabled);
      return;
    }
    final fid = int.tryParse(widget.id);
    if (fid == null) return;
    final me = context.read<AuthProvider>().user?.id;
    if (me != null && me == fid) {
      GvToast.show(context, AppLocalizations.of(context)!.toastCannotCallSelf);
      return;
    }
    final call = context.read<CallProvider>();
    final loc = GoRouterState.of(context).matchedLocation;
    final ok = call.startCall(
      fid,
      displayName,
      type: type == 'video' ? 'video' : 'audio',
      returnLocation: loc,
      peerIdStr: widget.id,
    );
    if (!ok) {
      GvToast.show(context, AppLocalizations.of(context)!.toastAlreadyInCall);
      return;
    }
    if (kIsWeb) {
      final prep = await call.prepareWebLocalMediaInUserGesture();
      if (!context.mounted) return;
      if (prep != CallInitMediaOutcome.success) {
        await call.reset();
        if (!context.mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final u = Uri.base;
        final secure = u.isScheme('https') ||
            u.host == 'localhost' ||
            u.host == '127.0.0.1';
        GvToast.show(
          context,
          secure
              ? l10n.callErrorMediaPermission
              : l10n.callErrorMediaNeedsHttps,
        );
        return;
      }
    }
    if (!context.mounted) return;
    context.push('/call');
  }
}

/// 设置备注弹窗：首帧 [FocusNode.requestFocus]，避免仅依赖 [TextField.autofocus] 在底部通栏 [AlertDialog] 下不生效。
class _ContactRemarkEditDialog extends StatefulWidget {
  const _ContactRemarkEditDialog({required this.initialText});

  final String initialText;

  @override
  State<_ContactRemarkEditDialog> createState() =>
      _ContactRemarkEditDialogState();
}

class _ContactRemarkEditDialogState extends State<_ContactRemarkEditDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return AlertDialog(
      actionsPadding: EdgeInsets.zero,
      actionsAlignment: MainAxisAlignment.start,
      buttonPadding: EdgeInsets.zero,
      title: Text(loc.contactRemarkEditTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.pop(context, _controller.text),
          decoration: InputDecoration(
            hintText: loc.contactRemarkHint,
            filled: true,
            fillColor: AppColors.bgSearchField.resolveFrom(context),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: GvSpacing.fieldH,
              vertical: GvSpacing.fieldV,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(GvRadii.input),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      actions: [
        GvDialogActions.weChatFooter(
          context,
          secondaryText: loc.commonCancel,
          primaryText: loc.commonConfirm,
          onSecondary: () => Navigator.pop(context),
          onPrimary: () => Navigator.pop(context, _controller.text),
        ),
      ],
    );
  }
}
