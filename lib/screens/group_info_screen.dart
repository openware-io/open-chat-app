import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/gv_secondary_navigation.dart';
import '../core/gv_toast.dart';
import 'package:gv_core/gv_core.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/client_remote_config_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../services/api_client.dart';
import '../widgets/gv_avatar.dart';
import '../widgets/gv_dialog_actions.dart';
import '../widgets/gv_nav_bar.dart';

class GroupInfoScreen extends StatefulWidget {
  const GroupInfoScreen({super.key, required this.id});

  final String id;

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  Map<String, dynamic>? _info;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final gid = int.tryParse(widget.id);
    if (gid == null) return;
    final g = context.read<GroupProvider>();
    final f = context.read<FriendProvider>();
    final info = await g.loadGroupInfo(gid);
    await Future.wait([
      g.loadMembers(gid),
      // 刷新好友缓存：好友列表可能过期，否则好友成员会被误判为非好友而显示「用户{id}」隐私模式。
      f.loadFriends().catchError((_, __) {}),
    ]);
    if (mounted) setState(() => _info = info);
  }

  /// 下拉刷新兜底：重拉群信息、成员与好友列表。
  Future<void> _refresh() async {
    try {
      await Future.wait<void>([
        _load(),
        context.read<FriendProvider>().loadFriends(),
      ]);
    } catch (_) {
      // 拉取失败保持现有数据。
    }
  }

  Widget _thinRowDivider(BuildContext context) {
    return SizedBox(
      height: 0.5,
      child: ColoredBox(color: Theme.of(context).dividerColor),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final g = context.watch<GroupProvider>();
    final auth = context.watch<AuthProvider>();
    // 订阅好友列表：成为好友/删除好友后，群成员名称与头像主动更新。
    context.watch<FriendProvider>();
    final myId = auth.user?.id ?? 0;
    final name = _info?['name'] as String? ?? l10n.groupChatDefaultName;
    final announcement = _info?['announcement'] as String?;
    final ownerId =
        jsonInt(_info?['owner_id']) ?? jsonInt(_info?['ownerId']) ?? 0;
    final isOwner = ownerId == myId;
    final rawAllowMemberInvite =
        _info?['allowMemberInvite'] ?? _info?['allow_member_invite'];
    final allowMemberInvite = rawAllowMemberInvite is bool
        ? rawAllowMemberInvite
        : rawAllowMemberInvite?.toString().toLowerCase() != 'false';
    final rawAllowMemberFriendRequest = _info?['allowMemberFriendRequest'] ??
        _info?['allow_member_friend_request'];
    final allowMemberFriendRequest = rawAllowMemberFriendRequest is bool
        ? rawAllowMemberFriendRequest
        : rawAllowMemberFriendRequest?.toString().toLowerCase() != 'false';
    final rawAllowMemberViewAccount =
        _info?['allowMemberViewAccount'] ?? _info?['allow_member_view_account'];
    final allowMemberViewAccount = rawAllowMemberViewAccount is bool
        ? rawAllowMemberViewAccount
        : rawAllowMemberViewAccount?.toString().toLowerCase() != 'false';

    final members = g.currentGroupMembers;
    final display = _showAll ? members : members.take(12).toList();
    GroupMember? myMembership;
    for (final x in members) {
      if (x.userId == myId) {
        myMembership = x;
        break;
      }
    }
    final myRoleEffective =
        isOwner ? 'owner' : (myMembership?.role ?? 'member');
    final canEditGroupInfo = _canEditGroupInfo(myRoleEffective);

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: name, showBack: true),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(GvSpacing.page),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _membersCard(
              context,
              display,
              members.length,
              l10n: l10n,
              myId: myId,
              myRole: myRoleEffective,
              memberFriendRequestAllowed: allowMemberFriendRequest,
              allowMemberViewAccount: allowMemberViewAccount,
            ),
            const SizedBox(height: GvSpacing.page),
            _groupNameAnnouncementCard(
              context,
              l10n: l10n,
              name: name,
              announcement: announcement,
              canEdit: canEditGroupInfo,
              isOwner: isOwner,
              allowMemberInvite: allowMemberInvite,
              allowMemberFriendRequest: allowMemberFriendRequest,
              allowMemberViewAccount: allowMemberViewAccount,
            ),
            const SizedBox(height: GvSpacing.page),
            GvCardShell(
              borderRadius: BorderRadius.circular(GvRadii.input),
              child: Material(
                color: AppColors.bgWhite.resolveFrom(context),
                child: _groupValueRow(
                  context,
                  title: '我在本群的昵称',
                  value: myMembership?.nickname?.trim().isNotEmpty == true
                      ? myMembership!.nickname!.trim()
                      : l10n.groupAnnouncementRowPlaceholder,
                  valueMaxLines: 1,
                  onTap: () =>
                      _showEditMyNicknameDialog(myMembership?.nickname ?? ''),
                  trailing: Icon(
                    LucideIcons.chevron_right,
                    size: 16,
                    color: AppColors.textHint.resolveFrom(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: GvSpacing.page),
            GvCardShell(
              borderRadius: BorderRadius.circular(GvRadii.input),
              child: Material(
                color: AppColors.bgWhite.resolveFrom(context),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _groupActionRow(
                      context,
                      title: l10n.chatHistoryTitle,
                      trailing: Icon(
                        LucideIcons.chevron_right,
                        color: AppColors.textHint.resolveFrom(context),
                      ),
                      onTap: () => gvPushChatHistoryGroup(context, widget.id),
                    ),
                    if (context
                        .read<ClientRemoteConfigProvider>()
                        .chatDeleteEnabled) ...[
                      _thinRowDivider(context),
                      _groupActionRow(
                        context,
                        title: l10n.groupClearHistoryRow,
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
                                  title: Text(loc.groupClearHistoryTitle),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(loc.groupClearHistoryConfirmBody),
                                      CheckboxListTile(
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity:
                                            ListTileControlAffinity.leading,
                                        value: alsoDeleteServer,
                                        title:
                                            Text(loc.chatClearAlsoDeleteServer),
                                        onChanged: (v) => setDialogState(() =>
                                            alsoDeleteServer = v ?? false),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    GvDialogActions.weChatFooter(
                                      ctx,
                                      secondaryText: loc.commonCancel,
                                      primaryText: loc.commonConfirm,
                                      onSecondary: () =>
                                          Navigator.pop(ctx, false),
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
                            await chat.clearGroupChatOnServer(widget.id);
                          } else {
                            chat.clearChatLocally(widget.id, 'group');
                          }
                          if (!context.mounted) return;
                          GvToast.show(
                            context,
                            AppLocalizations.of(context)!.toastGroupChatCleared,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: GvSpacing.page),
            if (isOwner) ...[
              TextButton(
                style: _grayDangerActionStyle(context),
                onPressed: () => _confirmDissolveGroup(context),
                child: Text(l10n.groupDissolveAction),
              ),
              const SizedBox(height: GvSpacing.page),
            ],
            TextButton(
              style: _grayDangerActionStyle(context),
              onPressed: () async {
                final gid = int.tryParse(widget.id);
                if (gid == null) return;
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) {
                    final loc = AppLocalizations.of(ctx)!;
                    return AlertDialog(
                      actionsPadding: EdgeInsets.zero,
                      actionsAlignment: MainAxisAlignment.start,
                      buttonPadding: EdgeInsets.zero,
                      content: Text(loc.groupLeaveConfirmBody),
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
                if (ok != true || !context.mounted) return;
                final gp = context.read<GroupProvider>();
                final chat = context.read<ChatProvider>();
                final api = context.read<ApiClient>();
                try {
                  await gp.leaveGroup(gid);
                } catch (e) {
                  if (context.mounted) {
                    GvToast.show(context, api.extractErrorMessage(e));
                  }
                  return;
                }
                if (!context.mounted) return;
                chat.removeConversation(widget.id, 'group');
                if (context.mounted) {
                  gvNavigateContactsAfterRemoveOnDesktop(context);
                }
              },
              child: Text(l10n.groupLeaveAction),
            ),
          ],
        ),
      ),
    );
  }

  /// 与后端 [roleWeight] 一致：仅当操作者角色权重高于被操作者时可移除。
  static int _roleWeight(String? r) {
    switch ((r ?? 'member').toLowerCase()) {
      case 'owner':
        return 3;
      case 'admin':
        return 2;
      default:
        return 1;
    }
  }

  static bool _canRemoveMember(int myId, String myRole, GroupMember target) {
    if (target.userId == myId) return false;
    return _roleWeight(myRole) > _roleWeight(target.role);
  }

  /// 与后端 [updateGroup] 一致：群主或管理员可改群名称、公告。
  static bool _canEditGroupInfo(String myRole) {
    final r = myRole.toLowerCase();
    return r == 'owner' || r == 'admin';
  }

  Widget _groupActionRow(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GvActionRow(
      title: title,
      titleStyle: GvTypography.navTitle(
        AppColors.textPrimary.resolveFrom(context),
      ),
      onTap: onTap,
      trailing: trailing,
      padding: const EdgeInsets.symmetric(
        horizontal: GvSpacing.page,
        vertical: GvSpacing.page,
      ),
    );
  }

  Widget _groupValueRow(
    BuildContext context, {
    required String title,
    required String value,
    required int valueMaxLines,
    VoidCallback? onTap,
    Widget? trailing,
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
      valueMaxLines: valueMaxLines,
      onTap: onTap,
      trailing: trailing,
    );
  }

  Widget _membersCard(
    BuildContext context,
    List<GroupMember> display,
    int totalCount, {
    required AppLocalizations l10n,
    required int myId,
    required String myRole,
    required bool memberFriendRequestAllowed,
    required bool allowMemberViewAccount,
  }) {
    return GvCardShell(
      borderRadius: BorderRadius.circular(GvRadii.input),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: Padding(
          padding: const EdgeInsets.all(GvSpacing.page),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: GvSpacing.page,
                runSpacing: GvSpacing.page,
                children: [
                  ...display.map(
                    (m) => _memberCell(
                      context,
                      m,
                      l10n: l10n,
                      myId: myId,
                      myRole: myRole,
                      memberFriendRequestAllowed: memberFriendRequestAllowed,
                      allowMemberViewAccount: allowMemberViewAccount,
                    ),
                  ),
                  _inviteCell(context, l10n),
                ],
              ),
              if (totalCount > 12)
                TextButton(
                  onPressed: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll
                        ? l10n.groupCollapseMembers
                        : l10n.groupShowAllMembers(totalCount),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshGroupInfoOnly() async {
    final gid = int.tryParse(widget.id);
    if (gid == null) return;
    final info = await context.read<GroupProvider>().loadGroupInfo(gid);
    if (mounted) setState(() => _info = info);
  }

  Future<void> _showEditGroupNameDialog(String currentName) async {
    final gid = int.tryParse(widget.id);
    if (gid == null) return;
    final ctrl = TextEditingController(text: currentName);
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
            actionsPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.start,
            buttonPadding: EdgeInsets.zero,
            title: Text(loc.groupEditNameTitle),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 128,
              decoration: InputDecoration(
                hintText: loc.groupNameFieldHint,
                counterText: '',
              ),
            ),
            actions: [
              GvDialogActions.weChatFooter(
                ctx,
                secondaryText: loc.commonCancel,
                primaryText: loc.commonSave,
                onSecondary: () => Navigator.pop(ctx),
                onPrimary: () => Navigator.pop(ctx, ctrl.text.trim()),
              ),
            ],
          );
        },
      );
      if (result == null || !mounted) return;
      if (result.isEmpty) {
        GvToast.show(
          context,
          AppLocalizations.of(context)!.toastEnterGroupName,
        );
        return;
      }
      if (result == currentName) return;
      try {
        final group = context.read<GroupProvider>();
        final chat = context.read<ChatProvider>();
        await group.updateGroup(gid, {'name': result});
        chat.updateConversationDisplay('$gid', 'group', name: result);
        await _refreshGroupInfoOnly();
      } catch (e) {
        if (mounted) {
          GvToast.show(
            context,
            context.read<ApiClient>().extractErrorMessage(e),
          );
        }
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _showEditMyNicknameDialog(String current) async {
    final gid = int.tryParse(widget.id);
    if (gid == null) return;
    final ctrl = TextEditingController(text: current);
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
            actionsPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.start,
            buttonPadding: EdgeInsets.zero,
            title: const Text('我在本群的昵称'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 64,
              decoration: const InputDecoration(
                hintText: '留空则使用全局昵称',
                counterText: '',
              ),
            ),
            actions: [
              GvDialogActions.weChatFooter(
                ctx,
                secondaryText: loc.commonCancel,
                primaryText: loc.commonSave,
                onSecondary: () => Navigator.pop(ctx),
                onPrimary: () => Navigator.pop(ctx, ctrl.text.trim()),
              ),
            ],
          );
        },
      );
      if (result == null || !mounted) return;
      if (result == current.trim()) return;
      try {
        await context.read<GroupProvider>().updateMyNickname(gid, result);
        await _load();
      } catch (e) {
        if (mounted) {
          GvToast.show(
            context,
            context.read<ApiClient>().extractErrorMessage(e),
          );
        }
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _showAnnouncementViewDialog(String body) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Text(
              body.isEmpty ? loc.groupAnnouncementViewEmpty : body,
            ),
          ),
          actions: [
            GvDialogActions.weChatSingle(
              ctx,
              text: loc.commonOk,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditAnnouncementDialog(String? current) async {
    final gid = int.tryParse(widget.id);
    if (gid == null) return;
    final ctrl = TextEditingController(text: current ?? '');
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
            actionsPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.start,
            buttonPadding: EdgeInsets.zero,
            title: Text(loc.groupEditAnnouncementTitle),
            content: SizedBox(
              width: double.maxFinite,
              child: TextField(
                controller: ctrl,
                autofocus: true,
                maxLength: 2000,
                maxLines: 8,
                minLines: 4,
                decoration: InputDecoration(
                  hintText: loc.groupAnnouncementFieldHint,
                  alignLabelWithHint: true,
                ),
              ),
            ),
            actions: [
              GvDialogActions.weChatFooter(
                ctx,
                secondaryText: loc.commonCancel,
                primaryText: loc.commonSave,
                onSecondary: () => Navigator.pop(ctx),
                onPrimary: () => Navigator.pop(ctx, ctrl.text),
              ),
            ],
          );
        },
      );
      if (result == null || !mounted) return;
      final next = result.trim();
      final prev = (current ?? '').trim();
      if (next == prev) return;
      try {
        await context
            .read<GroupProvider>()
            .updateGroup(gid, {'announcement': next});
        await _refreshGroupInfoOnly();
      } catch (e) {
        if (mounted) {
          GvToast.show(
            context,
            context.read<ApiClient>().extractErrorMessage(e),
          );
        }
      }
    } finally {
      ctrl.dispose();
    }
  }

  Widget _groupNameAnnouncementCard(
    BuildContext context, {
    required AppLocalizations l10n,
    required String name,
    required String? announcement,
    required bool canEdit,
    required bool isOwner,
    required bool allowMemberInvite,
    required bool allowMemberFriendRequest,
    required bool allowMemberViewAccount,
  }) {
    final value = (announcement == null || announcement.isEmpty)
        ? l10n.groupAnnouncementRowPlaceholder
        : announcement;
    final dialogText = announcement?.isNotEmpty == true
        ? announcement!
        : l10n.groupAnnouncementViewEmpty;

    Widget nameRow() {
      return _groupValueRow(
        context,
        title: l10n.groupNameLabel,
        value: name,
        valueMaxLines: 4,
        onTap: canEdit ? () => _showEditGroupNameDialog(name) : null,
        trailing: canEdit
            ? Icon(
                LucideIcons.chevron_right,
                size: 16,
                color: AppColors.textHint.resolveFrom(context),
              )
            : null,
      );
    }

    Widget announcementRow() {
      return _groupValueRow(
        context,
        title: l10n.groupAnnouncementLabel,
        value: value,
        valueMaxLines: 1,
        onTap: () {
          if (canEdit) {
            _showEditAnnouncementDialog(announcement);
          } else {
            _showAnnouncementViewDialog(dialogText);
          }
        },
        trailing: canEdit
            ? Icon(
                LucideIcons.chevron_right,
                size: 16,
                color: AppColors.textHint.resolveFrom(context),
              )
            : null,
      );
    }

    return GvCardShell(
      borderRadius: BorderRadius.circular(GvRadii.input),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            nameRow(),
            _thinRowDivider(context),
            announcementRow(),
            _thinRowDivider(context),
            SwitchListTile.adaptive(
              title: Text(
                l10n.groupAllowMemberInvite,
                style: GvTypography.navTitle(
                  AppColors.textPrimary.resolveFrom(context),
                ),
              ),
              value: allowMemberInvite,
              onChanged: canEdit
                  ? (value) async {
                      final gid = int.tryParse(widget.id);
                      if (gid == null) return;
                      try {
                        await context.read<GroupProvider>().updateGroup(
                          gid,
                          {'allowMemberInvite': value},
                        );
                        await _refreshGroupInfoOnly();
                      } catch (error) {
                        if (context.mounted) {
                          GvToast.show(
                            context,
                            context
                                .read<ApiClient>()
                                .extractErrorMessage(error),
                          );
                        }
                      }
                    }
                  : null,
            ),
            _thinRowDivider(context),
            SwitchListTile.adaptive(
              title: Text(
                l10n.groupAllowMemberFriendRequest,
                style: GvTypography.navTitle(
                  AppColors.textPrimary.resolveFrom(context),
                ),
              ),
              value: allowMemberFriendRequest,
              onChanged: isOwner
                  ? (value) async {
                      final gid = int.tryParse(widget.id);
                      if (gid == null) return;
                      try {
                        await context.read<GroupProvider>().updateGroup(
                          gid,
                          {'allowMemberFriendRequest': value},
                        );
                        await _refreshGroupInfoOnly();
                      } catch (error) {
                        if (context.mounted) {
                          GvToast.show(
                            context,
                            context
                                .read<ApiClient>()
                                .extractErrorMessage(error),
                          );
                        }
                      }
                    }
                  : null,
            ),
            _thinRowDivider(context),
            SwitchListTile.adaptive(
              title: Text(
                l10n.gvFaGroupAllowMemberViewAccount,
                style: GvTypography.navTitle(
                  AppColors.textPrimary.resolveFrom(context),
                ),
              ),
              value: allowMemberViewAccount,
              onChanged: isOwner
                  ? (value) async {
                      final gid = int.tryParse(widget.id);
                      if (gid == null) return;
                      try {
                        await context.read<GroupProvider>().updateGroup(
                          gid,
                          {'allowMemberViewAccount': value},
                        );
                        await _refreshGroupInfoOnly();
                      } catch (error) {
                        if (context.mounted) {
                          GvToast.show(
                            context,
                            context
                                .read<ApiClient>()
                                .extractErrorMessage(error),
                          );
                        }
                      }
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemoveMember(
    BuildContext context,
    GroupMember m,
  ) async {
    final gid = int.tryParse(widget.id);
    if (gid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          content: Text(loc.groupRemoveMemberConfirm(m.displayName)),
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: loc.commonCancel,
              primaryText: loc.groupRemoveMemberAction,
              onSecondary: () => Navigator.pop(ctx, false),
              onPrimary: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<GroupProvider>().removeMember(gid, m.userId);
    } catch (e) {
      if (context.mounted) {
        final msg = context.read<ApiClient>().extractErrorMessage(e);
        GvToast.show(context, msg);
      }
    }
  }

  static bool _canMuteMember(int myId, String myRole, GroupMember target) {
    if (target.userId == myId) return false;
    // 与移除成员/后端 rank 校验一致：仅能禁言角色权重低于自己的成员（admin 不可禁言 owner/admin）。
    return _roleWeight(myRole) > _roleWeight(target.role);
  }

  static bool _canSetRole(int myId, String myRole, GroupMember target) {
    if (myRole.toLowerCase() != 'owner') return false;
    if (target.userId == myId) return false;
    return (target.role?.toLowerCase() ?? 'member') != 'owner';
  }

  Widget _memberCell(
    BuildContext context,
    GroupMember m, {
    required AppLocalizations l10n,
    required int myId,
    required String myRole,
    required bool memberFriendRequestAllowed,
    required bool allowMemberViewAccount,
  }) {
    // 群内展示优先群昵称，其次好友备注/账号名；是否可见非好友账号由平台隐私与
    // 群主的「允许群成员查看他人账号」共同决定，群主本人不受群级开关限制。
    final friend = context.read<FriendProvider>().getFriendDisplay(m.userId);
    final privacy =
        context.read<ClientRemoteConfigProvider>().hideGroupMemberInfo;
    final isSelf = m.userId == myId;
    final canViewAccount = myRole.toLowerCase() == 'owner' ||
        allowMemberViewAccount;
    final showIdentity = isSelf || friend != null ||
        (!privacy && canViewAccount);

    var display = m.nickname?.trim();
    if (display == null || display.isEmpty) {
      display = friend?.name.trim();
    }
    if (display == null || display.isEmpty) {
      display = showIdentity ? m.username?.trim() : '用户${m.userId}';
    }
    if (display == null || display.isEmpty) {
      display = '用户${m.userId}';
    }
    final avatarSrc = showIdentity ? m.avatar : null;
    final canRemove = _canRemoveMember(myId, myRole, m);
    final canMute = _canMuteMember(myId, myRole, m);
    final canSetRole = _canSetRole(myId, myRole, m);
    final canManage = canRemove || canMute || canSetRole;
    final isGroupOwner = m.role?.toLowerCase() == 'owner';
    return Semantics(
      label:
          '$display${isGroupOwner ? ' ${l10n.groupOwnerBadge}' : ''}${canManage ? l10n.groupMemberLongPressRemoveHint : ''}',
      child: InkWell(
        onTap: () async {
          await gvPushContactDetail(context, '${m.userId}',
              fromGroup: true,
              sourceGroupId: int.tryParse(widget.id),
              hideAccountDetails: !isSelf &&
                  myRole.toLowerCase() != 'owner' &&
                  !allowMemberViewAccount,
              hideFriendRequest: !isSelf &&
                  myRole.toLowerCase() != 'owner' &&
                  !memberFriendRequestAllowed);
          if (!context.mounted) return;
          // 从好友资料返回后刷新好友列表，群成员名称/头像主动更新。
          try {
            await context.read<FriendProvider>().loadFriends();
          } catch (_) {
            // 忽略：下拉刷新可兜底。
          }
        },
        onLongPress: canManage
            ? () =>
                _showMemberActionSheet(context, m, myId: myId, myRole: myRole)
            : null,
        child: SizedBox(
          width: 56,
          child: Column(
            children: [
              GvAvatar(
                name: display,
                uid: m.userId,
                src: avatarSrc,
                size: 44,
              ),
              const SizedBox(height: 4),
              Text(
                display,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GvTypography.small(
                  AppColors.textPrimary.resolveFrom(context),
                ),
              ),
              if (isGroupOwner) ...[
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .resolveFrom(context)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(GvRadii.input),
                  ),
                  child: Text(
                    l10n.groupOwnerBadge,
                    style: GvTypography.tabLabel(
                      AppColors.primary.resolveFrom(context),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMemberActionSheet(
    BuildContext context,
    GroupMember m, {
    required int myId,
    required String myRole,
  }) async {
    final canRemove = _canRemoveMember(myId, myRole, m);
    final canMute = _canMuteMember(myId, myRole, m);
    final canSetRole = _canSetRole(myId, myRole, m);
    final isAdmin = (m.role?.toLowerCase() ?? 'member') == 'admin';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetCtx) {
        final loc = AppLocalizations.of(sheetCtx)!;
        final tiles = <Widget>[
          if (canMute) ...[
            ListTile(
              title: Text(loc.groupMute10Minutes),
              onTap: () {
                Navigator.pop(sheetCtx);
                _muteMember(context, m, 10);
              },
            ),
            ListTile(
              title: Text(loc.groupMute1Hour),
              onTap: () {
                Navigator.pop(sheetCtx);
                _muteMember(context, m, 60);
              },
            ),
            ListTile(
              title: Text(loc.groupMute1Day),
              onTap: () {
                Navigator.pop(sheetCtx);
                _muteMember(context, m, 1440);
              },
            ),
            ListTile(
              title: Text(loc.groupUnmuteAction),
              onTap: () {
                Navigator.pop(sheetCtx);
                _muteMember(context, m, null);
              },
            ),
          ],
          if (canSetRole)
            ListTile(
              title: Text(isAdmin
                  ? loc.groupUnsetAdminAction
                  : loc.groupSetAdminAction),
              onTap: () {
                Navigator.pop(sheetCtx);
                _setMemberRole(context, m, isAdmin ? 'member' : 'admin');
              },
            ),
          if (canRemove)
            ListTile(
              title: Text(loc.groupRemoveMemberAction),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmRemoveMember(context, m);
              },
            ),
        ];
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: tiles,
          ),
        );
      },
    );
  }

  Future<void> _muteMember(
      BuildContext context, GroupMember m, int? minutes) async {
    final gid = int.tryParse(widget.id);
    if (gid == null) return;
    try {
      await context.read<GroupProvider>().muteMember(gid, m.userId, minutes);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        GvToast.show(
          context,
          minutes == null ? l10n.groupUnmuteSuccess : l10n.groupMuteSuccess,
        );
      }
    } catch (e) {
      if (context.mounted) {
        GvToast.show(context, context.read<ApiClient>().extractErrorMessage(e));
      }
    }
  }

  Future<void> _setMemberRole(
      BuildContext context, GroupMember m, String role) async {
    final gid = int.tryParse(widget.id);
    if (gid == null) return;
    try {
      await context.read<GroupProvider>().setRole(gid, m.userId, role);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        GvToast.show(
          context,
          role == 'admin'
              ? l10n.groupSetAdminSuccess
              : l10n.groupUnsetAdminSuccess,
        );
      }
    } catch (e) {
      if (context.mounted) {
        GvToast.show(context, context.read<ApiClient>().extractErrorMessage(e));
      }
    }
  }

  Future<void> _confirmDissolveGroup(BuildContext context) async {
    final gid = int.tryParse(widget.id);
    if (gid == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          title: Text(l.groupDissolveAction),
          content: Text(l.groupDissolveConfirmBody),
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: l.commonCancel,
              primaryText: l.groupDissolveAction,
              onSecondary: () => Navigator.pop(ctx, false),
              onPrimary: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) return;
    final gp = context.read<GroupProvider>();
    final chat = context.read<ChatProvider>();
    final api = context.read<ApiClient>();
    try {
      await gp.dissolveGroup(gid);
    } catch (e) {
      if (context.mounted) {
        GvToast.show(context, api.extractErrorMessage(e));
      }
      return;
    }
    if (!context.mounted) return;
    chat.removeConversation(widget.id, 'group');
    if (context.mounted) {
      gvNavigateContactsAfterRemoveOnDesktop(context);
    }
  }

  Widget _inviteCell(BuildContext context, AppLocalizations l10n) {
    return InkWell(
      onTap: () => gvPushInviteMembers(context, widget.id),
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.bgInput.resolveFrom(context),
                borderRadius: BorderRadius.circular(GvRadii.card + 8),
              ),
              child: Icon(
                LucideIcons.plus,
                color: AppColors.primary.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(l10n.groupInvite,
                style: GvTypography.small(
                  AppColors.textPrimary.resolveFrom(context),
                )),
          ],
        ),
      ),
    );
  }
}
