import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/conversation_preview.dart';
import '../core/formatters.dart';
import '../core/open_channel_code.dart';
import '../core/open_chat_navigation.dart';
import '../core/open_automation_keys.dart';
import '../core/open_toast.dart';
import '../l10n/app_localizations.dart';
import '../core/open_secondary_navigation.dart';
import '../models/channel_models.dart';
import '../models/conversation.dart';
import '../providers/chat_provider.dart';
import '../providers/client_remote_config_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../services/api_client.dart';
import '../widgets/open_avatar.dart';
import '../widgets/open_dialog_actions.dart';
import '../widgets/open_nav_bar.dart';
import '../widgets/open_search_bar.dart';

/// 与列表项内 [GvAvatar.size] 一致；用于计算分割线左内边距（从名称列左缘开始对齐）。
const double _kChatListAvatarSize = 50;

/// 列表单元格与分割线之间的垂直留白（单侧）；上下各用一半，使线落在相邻两项之间的视觉中部。
const double _kChatListDividerGapHalf = GvSpacing.cellV;

/// 会话列表页（「消息」）：搜索、排序会话、侧滑置顶/删除、加号菜单进添加好友/建群/扫一扫。
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  /// 搜索框文本；[GvSearchBar] 绑定，变更时 [setState] 过滤 [ChatProvider.sortedConversations]。
  final _search = TextEditingController();

  final ScrollController _listScrollController = ScrollController();

  static const ScrollPhysics _listPhysics = AlwaysScrollableScrollPhysics(
    parent: ClampingScrollPhysics(),
  );

  /// 释放搜索框控制器。
  @override
  void dispose() {
    _search.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  /// 首帧后拉会话/好友/群、刷新展示名，并在有需要时弹出公告对话框。
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      final f = context.read<FriendProvider>();
      final g = context.read<GroupProvider>();
      await chat.synchronizeMessages();
      await Future.wait([
        f.loadFriends(),
        f.loadPendingRequests(),
        g.loadGroups(),
        // 同步私密会话（对方创建的私密聊天也出现在本端会话列表，可进入握手）。
        chat.syncSecretChatsIntoConversations(),
        // 同步私密群聊（成员创建的私密群聊也出现在本端会话列表，可进入握手）。
        chat.syncSecretGroupChatsIntoConversations(),
      ]);
      if (mounted) {
        if (chat.applyDisplayNamesFromContactProviders()) {
          chat.saveConversations();
        }
      }
      if (!mounted) return;
      final remote = context.read<ClientRemoteConfigProvider>();
      // 远程配置里待展示的一条公告正文；为 null 则不弹窗。
      final ann = remote.peekAnnouncementForDialog();
      if (ann != null && mounted) {
        final l10n = AppLocalizations.of(context)!;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l10n.chatAnnouncementTitle),
            content: SingleChildScrollView(child: Text(ann)),
            actions: [
              TextButton(
                onPressed: () {
                  remote.markAnnouncementConsumed();
                  Navigator.pop(ctx);
                },
                child: Text(l10n.commonOk),
              ),
            ],
          ),
        );
      }
    });
  }

  /// 会话类型对应的远程能力开关是否开启。
  bool _isChatTypeEnabled(String chatType) {
    final remote = context.read<ClientRemoteConfigProvider>();
    return switch (chatType) {
      'private' => remote.privateChatEnabled,
      'group' => remote.groupChatEnabled,
      'channel' => remote.channelEnabled,
      'secret' => remote.secretChatEnabled,
      'secret_group' => remote.secretGroupChatEnabled,
      _ => true,
    };
  }

  /// 会话类型被禁用时展示的提示文案；未禁用返回 null。
  String? _chatDisabledMessage(String chatType, AppLocalizations l10n) {
    return switch (chatType) {
      'private' => l10n.featurePrivateChatDisabled,
      'group' => l10n.featureGroupChatDisabled,
      'channel' => l10n.featureChannelDisabled,
      'secret' => l10n.featureSecretChatDisabled,
      'secret_group' => l10n.featureSecretGroupChatDisabled,
      _ => null,
    };
  }

  /// 构建导航栏、搜索栏与会话列表（或空状态）。
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 全局聊天状态；watch 以便会话列表与未读等变更时重建。
    final chat = context.watch<ChatProvider>();
    // 删除类操作（删除聊天等）总开关。
    final deleteOn =
        context.read<ClientRemoteConfigProvider>().chatDeleteEnabled;
    // 按置顶与时间排序后的会话，再按 _search 关键字（不区分大小写）过滤得到的展示列表。
    final list = chat.sortedConversations.where((c) {
      final q = _search.text.toLowerCase();
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final mq = MediaQuery.of(context);
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;
        final size = Size(
          w,
          h.isFinite ? h : mq.size.height,
        );
        return MediaQuery(
          data: mq.copyWith(size: size),
          child: SizedBox.expand(
            key: GvAutomationKeys.chatListScreen,
            child: ColoredBox(
              color: gvPageScaffoldBackground(context),
              child: ScrollConfiguration(
                behavior: const NoStretchScrollBehavior(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GvNavBar(
                      title: l10n.tabMessages,
                      showBottomShadow: false,
                      right: Builder(
                        builder: (anchorCtx) => IconButton(
                          key: GvAutomationKeys.chatListAdd,
                          style: IconButton.styleFrom(
                            foregroundColor:
                                CupertinoColors.label.resolveFrom(anchorCtx),
                          ),
                          padding: EdgeInsets.zero,
                          icon: const Icon(LucideIcons.plus),
                          onPressed: () => _showPlusMenu(anchorCtx),
                        ),
                      ),
                    ),
                    GvSearchBar(
                      key: GvAutomationKeys.chatListSearch,
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      barBackgroundColor:
                          AppColors.bgWhite.resolveFrom(context),
                      fillColor: AppColors.bgSearchField.resolveFrom(context),
                      padding: const EdgeInsets.fromLTRB(
                        GvSpacing.page,
                        GvSpacing.searchBarOuterV,
                        GvSpacing.page,
                        GvSpacing.searchBarOuterV,
                      ),
                      fieldVerticalPadding: 8,
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? LayoutBuilder(
                              builder: (context, constraints) {
                                return ListView(
                                  controller: _listScrollController,
                                  physics: _listPhysics,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              LucideIcons.message_square,
                                              size: 56,
                                              color: AppColors.textHint
                                                  .resolveFrom(context)
                                                  .withValues(alpha: 0.5),
                                            ),
                                            const SizedBox(
                                                height: GvSpacing.sm),
                                            Text(
                                              l10n.chatListEmpty,
                                              style: GvTypography.caption(
                                                AppColors.textSecondary
                                                    .resolveFrom(context)
                                                    .withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : ListView.builder(
                              controller: _listScrollController,
                              physics: _listPhysics,
                              padding:
                                  const EdgeInsets.only(bottom: GvSpacing.sm),
                              itemCount: list.length,
                              itemBuilder: (_, i) {
                                final c = list[i];
                                final displayConversation =
                                    _isChatTypeEnabled(c.chatType)
                                        ? c
                                        : c.copyWith(unread: 0);
                                return _ChatCell(
                                  conv: displayConversation,
                                  isFirst: i == 0,
                                  isLast: i == list.length - 1,
                                  pinLabel: c.pinned
                                      ? l10n.chatUnpinConversation
                                      : l10n.chatPinConversation,
                                  muteLabel: c.muted
                                      ? l10n.chatUnmuteConversation
                                      : l10n.chatMuteConversation,
                                  deleteLabel: l10n.commonDelete,
                                  deleteEnabled: deleteOn,
                                  onOpen: () {
                                    if (!_isChatTypeEnabled(c.chatType)) {
                                      final msg = _chatDisabledMessage(
                                          c.chatType, l10n);
                                      if (msg != null) {
                                        GvToast.show(context, msg);
                                      }
                                      return;
                                    }
                                    gvOpenChat(
                                      context,
                                      chatType: c.chatType,
                                      peerId: c.id,
                                    );
                                  },
                                  onPin: () => chat.togglePin(c.id, c.chatType),
                                  onMute: () =>
                                      chat.toggleMute(c.id, c.chatType),
                                  onDelete: () async {
                                    if (!deleteOn) return;
                                    if (c.chatType == 'secret' ||
                                        c.chatType == 'secret_group') {
                                      // 私密聊天/私密群聊删除 = 终止（Telegram 语义），不可恢复，先二次确认。
                                      final isGroup =
                                          c.chatType == 'secret_group';
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (dialogCtx) => AlertDialog(
                                          title: Text(isGroup
                                              ? l10n.secretGroupChatDeleteTitle
                                              : l10n.secretChatDeleteTitle),
                                          content: Text(isGroup
                                              ? l10n.secretGroupChatDeleteBody
                                              : l10n.secretChatDeleteBody),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(dialogCtx)
                                                      .pop(false),
                                              child: Text(l10n.commonCancel),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(dialogCtx)
                                                      .pop(true),
                                              child: Text(l10n.commonDelete),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        if (isGroup) {
                                          await chat
                                              .deleteSecretGroupChat(c.id);
                                        } else {
                                          await chat.deleteSecretChat(c.id);
                                        }
                                      }
                                    } else {
                                      chat.removeConversation(c.id, c.chatType);
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 在导航栏加号下方弹出菜单：添加好友、发起群聊（受远程开关）、扫一扫。
  ///
  /// [anchorContext] 为加号按钮所在 [BuildContext]，用于 [showMenu] 定位。
  Future<void> _showPlusMenu(BuildContext anchorContext) async {
    final l10n = AppLocalizations.of(context)!;
    // 弹出菜单背景色（随深浅色解析）。
    final bg = CupertinoColors.systemBackground.resolveFrom(context);
    // 菜单项主文案颜色。
    final label = AppColors.textPrimary.resolveFrom(context);
    // 菜单项图标颜色，与 anchorContext 主题一致。
    final iconColor = CupertinoColors.label.resolveFrom(anchorContext);
    // 是否展示「发起群聊」入口。
    final groupOn = context.read<ClientRemoteConfigProvider>().groupChatEnabled;
    // 是否展示「创建频道」入口。
    final channelOn = context.read<ClientRemoteConfigProvider>().channelEnabled;
    // 是否展示「发起私密群聊」入口。
    final secretGroupOn =
        context.read<ClientRemoteConfigProvider>().secretGroupChatEnabled;
    final items = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        key: GvAutomationKeys.chatListAddFriend,
        value: 'add_friend',
        child: Row(
          children: [
            Icon(LucideIcons.user_plus, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Text(l10n.addFriendTitle, style: GvTypography.body(label)),
          ],
        ),
      ),
      if (groupOn)
        PopupMenuItem<String>(
          key: GvAutomationKeys.chatListCreateGroup,
          value: 'group',
          child: Row(
            children: [
              Icon(LucideIcons.users, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(l10n.startGroupChatTitle, style: GvTypography.body(label)),
            ],
          ),
        ),
      if (channelOn)
        PopupMenuItem<String>(
          key: GvAutomationKeys.chatListCreateChannel,
          value: 'channel',
          child: Row(
            children: [
              Icon(LucideIcons.megaphone, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(l10n.channelCreateTitle, style: GvTypography.body(label)),
            ],
          ),
        ),
      if (secretGroupOn)
        PopupMenuItem<String>(
          value: 'secret_group',
          child: Row(
            children: [
              Icon(LucideIcons.lock, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(l10n.secretGroupChatStartTitle,
                  style: GvTypography.body(label)),
            ],
          ),
        ),
      if (channelOn)
        PopupMenuItem<String>(
          key: GvAutomationKeys.chatListSearchChannel,
          value: 'channel_search',
          child: Row(
            children: [
              Icon(LucideIcons.search, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(l10n.channelSearchTitle, style: GvTypography.body(label)),
            ],
          ),
        ),
      if (channelOn)
        PopupMenuItem<String>(
          key: GvAutomationKeys.chatListJoinChannel,
          value: 'channel_join',
          child: Row(
            children: [
              Icon(LucideIcons.hash, color: iconColor, size: 22),
              const SizedBox(width: 12),
              Text(l10n.channelJoinByCodeTitle,
                  style: GvTypography.body(label)),
            ],
          ),
        ),
      PopupMenuItem<String>(
        key: GvAutomationKeys.chatListScan,
        value: 'scan',
        child: Row(
          children: [
            Icon(LucideIcons.scan_qr_code, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Text(l10n.scanQrTitle,
                style: TextStyle(color: label, fontSize: 16)),
          ],
        ),
      ),
    ];
    // 用户选中的菜单 value；点为外部关闭则为 null。
    final choice = await showMenu<String>(
      context: anchorContext,
      position: gvMenuPositionBelowWidget(anchorContext, gapBelow: 10),
      color: bg,
      surfaceTintColor: Colors.transparent,
      elevation: kGvPopoverMenuElevation,
      shadowColor: gvPopoverMenuShadowColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GvRadii.button),
      ),
      items: items,
    );
    if (choice == null || !mounted) return;
    switch (choice) {
      case 'add_friend':
        gvOpenAddFriend(context);
        break;
      case 'group':
        gvOpenCreateGroup(context);
        break;
      case 'secret_group':
        gvOpenCreateSecretGroup(context);
        break;
      case 'channel':
        await _showCreateChannelDialog(context);
        break;
      case 'channel_search':
        await _showChannelSearchDialog(context);
        break;
      case 'channel_join':
        await _showChannelJoinByCodeDialog(context);
        break;
      case 'scan':
        gvOpenScan(context);
        break;
    }
  }

  /// 创建频道：输入名称 → [ChatProvider.createChannel] → 进频道聊天室。
  ///
  /// 输入值只由弹窗内的 [TextField]（[onChanged]）维护到本方法的局部变量，
  /// 不再把外部 [TextEditingController] 的生命周期绑到会被提前 dispose 的宿主上
  /// （弹窗 route 被 pop 后退场过渡仍在 build 子节点，外部 controller 若此时被
  /// dispose 会触发 "A TextEditingController was used after being disposed"）。
  Future<void> _showCreateChannelDialog(BuildContext dialogContext) async {
    var input = '';
    final name = await showDialog<String>(
      context: dialogContext,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(loc.channelCreateTitle),
          content: TextField(
            key: GvAutomationKeys.channelNameField,
            autofocus: true,
            maxLength: 64,
            textInputAction: TextInputAction.done,
            onChanged: (value) => input = value,
            onSubmitted: (v) => Navigator.pop(ctx, v),
            decoration: InputDecoration(
              hintText: loc.channelNameHint,
              filled: true,
              fillColor: AppColors.bgSearchField.resolveFrom(ctx),
              counterText: '',
              isDense: true,
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
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: loc.commonCancel,
              primaryText: loc.channelCreateConfirm,
              onSecondary: () => Navigator.pop(ctx),
              onPrimary: () => Navigator.pop(ctx, input),
            ),
          ],
        );
      },
    );
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;
    final chat = context.read<ChatProvider>();
    try {
      final info = await chat.createChannel(name: trimmed);
      if (!mounted) return;
      GvToast.show(
        context,
        AppLocalizations.of(context)!.toastChannelCreated,
        duration: const Duration(seconds: 1),
      );
      gvOpenChat(context, chatType: 'channel', peerId: info.id);
    } catch (e) {
      if (mounted) {
        GvToast.show(
          context,
          context.read<ApiClient>().extractErrorMessage(e),
        );
      }
    }
  }

  /// 搜索频道：输入关键字 → 展示匹配的公开频道 → 点击订阅并进房。
  ///
  /// 与 [_showCreateChannelDialog] 相同：不持有外部 controller，输入值由弹窗内
  /// [TextField] 的 [onChanged] 维护，避免退场过渡期间访问已 dispose 的 controller。
  Future<void> _showChannelSearchDialog(BuildContext dialogContext) async {
    final chat = context.read<ChatProvider>();
    List<ChannelInfo> results = const [];
    var searched = false;
    var input = '';

    final selected = await showDialog<ChannelInfo>(
      context: dialogContext,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> submit(String raw) async {
              final text = raw.trim();
              if (text.isEmpty) return;
              // 粘贴频道号 / OPEN_CHANNEL 分享信息时直接解析并订阅，无需先按名称搜索。
              final code = extractChannelCode(text);
              if (code != null) {
                try {
                  final info = await chat.channelByCode(code);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx, info);
                  return;
                } catch (_) {
                  // 不是有效频道号：回落到按名称搜索。
                }
              }
              final list = await chat.searchChannels(text);
              if (!ctx.mounted) return;
              setDialogState(() {
                results = list;
                searched = true;
              });
            }

            return AlertDialog(
              title: Text(loc.channelSearchTitle),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: GvAutomationKeys.channelSearchField,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: (value) => input = value,
                      onSubmitted: (v) => submit(v),
                      decoration: InputDecoration(
                        hintText: loc.channelSearchHint,
                        prefixIcon: const Icon(LucideIcons.search, size: 20),
                        filled: true,
                        fillColor: AppColors.bgSearchField.resolveFrom(ctx),
                        isDense: true,
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
                    const SizedBox(height: 12),
                    if (results.isEmpty && !searched)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          loc.channelSearchEmptyHint,
                          style: GvTypography.caption(
                            AppColors.textSecondary.resolveFrom(ctx),
                          ),
                        ),
                      )
                    else if (results.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          loc.channelSearchNoResult,
                          style: GvTypography.caption(
                            AppColors.textSecondary.resolveFrom(ctx),
                          ),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (ctx, index) {
                            final item = results[index];
                            return ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              tileColor:
                                  AppColors.bgSearchField.resolveFrom(ctx),
                              title: Text(item.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                '${loc.channelInfoHintShort} · ${item.memberCount}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GvTypography.caption(
                                  AppColors.textSecondary.resolveFrom(ctx),
                                ),
                              ),
                              trailing: item.subscribed
                                  ? Text(
                                      loc.channelJoined,
                                      style: GvTypography.caption(
                                        AppColors.textSecondary
                                            .resolveFrom(ctx),
                                      ),
                                    )
                                  : Icon(LucideIcons.circle_plus,
                                      size: 20,
                                      color:
                                          AppColors.primary.resolveFrom(ctx)),
                              onTap: () => Navigator.pop(ctx, item),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                GvDialogActions.weChatFooter(
                  ctx,
                  secondaryText: loc.commonCancel,
                  primaryText: loc.commonSearch,
                  onSecondary: () => Navigator.pop(ctx),
                  onPrimary: () => submit(input),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected == null || !mounted) return;
    await _joinChannelAndOpen(chat, selected);
  }

  /// 输入频道号订阅：输入分享码 → 查频道 → 订阅并进房。
  ///
  /// 与 [_showCreateChannelDialog] 相同：不持有外部 controller，输入值由弹窗内
  /// [TextField] 的 [onChanged] 维护，避免退场过渡期间访问已 dispose 的 controller。
  Future<void> _showChannelJoinByCodeDialog(BuildContext dialogContext) async {
    final chat = context.read<ChatProvider>();
    var input = '';
    final code = await showDialog<String>(
      context: dialogContext,
      builder: (ctx) {
        final loc = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(loc.channelJoinByCodeTitle),
          content: TextField(
            key: GvAutomationKeys.channelJoinCodeField,
            autofocus: true,
            maxLength: 16,
            textInputAction: TextInputAction.done,
            onChanged: (value) => input = value,
            onSubmitted: (v) => Navigator.pop(ctx, v),
            decoration: InputDecoration(
              hintText: loc.channelJoinByCodeHint,
              prefixIcon: const Icon(LucideIcons.hash, size: 20),
              filled: true,
              fillColor: AppColors.bgSearchField.resolveFrom(ctx),
              counterText: '',
              isDense: true,
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
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: loc.commonCancel,
              primaryText: loc.channelJoinConfirm,
              onSecondary: () => Navigator.pop(ctx),
              onPrimary: () => Navigator.pop(ctx, input),
            ),
          ],
        );
      },
    );
    final trimmed = code?.trim() ?? '';
    if (trimmed.isEmpty || !mounted) return;
    try {
      final info = await chat.channelByCode(trimmed);
      if (!mounted) return;
      await _joinChannelAndOpen(chat, info);
    } catch (e) {
      if (mounted) {
        GvToast.show(
          context,
          context.read<ApiClient>().extractErrorMessage(e),
        );
      }
    }
  }

  /// 订阅频道（幂等）并进入聊天室。
  Future<void> _joinChannelAndOpen(ChatProvider chat, ChannelInfo info) async {
    try {
      if (!info.subscribed && !info.isOwner) {
        await chat.subscribeChannel(info.id);
      }
    } catch (_) {
      // 订阅失败不阻塞进房（服务端进房阅读路径也会兜底订阅）。
    }
    if (!mounted) return;
    gvOpenChat(context, chatType: 'channel', peerId: info.id);
  }
}

/// 单条会话行：头像、名称、最后一条预览、时间、未读角标；左滑露出置顶与删除。
class _ChatCell extends StatelessWidget {
  const _ChatCell({
    required this.conv,
    required this.isFirst,
    required this.isLast,
    required this.pinLabel,
    required this.muteLabel,
    required this.deleteLabel,
    this.deleteEnabled = true,
    required this.onOpen,
    required this.onPin,
    required this.onMute,
    required this.onDelete,
  });

  /// 本会话行对应的数据模型。
  final Conversation conv;

  /// 是否为当前 [ListView] 中第一项（影响上内边距）。
  final bool isFirst;

  /// 是否为当前 [ListView] 中最后一项（影响下内边距与是否画底部分割线）。
  final bool isLast;

  /// Localized slide action label for pin/unpin.
  final String pinLabel;

  /// Localized slide action label for mute/unmute.
  final String muteLabel;

  /// Localized slide action label for deletion.
  final String deleteLabel;

  /// 是否展示「删除」侧滑动作（受 chatDeleteEnabled 控制）。
  final bool deleteEnabled;

  /// 点击行主体进入聊天页。
  final VoidCallback onOpen;

  /// 侧滑「置顶 / 取消置顶」。
  final VoidCallback onPin;

  /// 侧滑「免打扰 / 取消免打扰」。
  final VoidCallback onMute;

  /// 侧滑「删除」会话（仅从列表移除，具体语义见 [ChatProvider.removeConversation]）。
  final VoidCallback onDelete;

  /// 绘制可滑动单元格：主行 + 可选底部分割线。
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasAtMention =
        context.read<ChatProvider>().hasUnreadAtMention(conv.id, conv.chatType);
    final visibleUnread =
        context.read<ChatProvider>().unreadForConversation(conv);
    // 物理像素对齐的 1px 分割线高度。
    final dividerH = 1.0 / MediaQuery.devicePixelRatioOf(context);
    // 分割线颜色（浅灰半透明）。
    final dividerColor =
        AppColors.textHint.resolveFrom(context).withValues(alpha: 0.22);

    // 侧滑按钮文案，随 Conversation.pinned 切换。
    // 屏幕宽度，用于估算侧滑动作面板宽度比例。
    final sw = MediaQuery.sizeOf(context).width;
    // 按「置顶/取消置顶」「免打扰/取消免打扰」等文案估算动作区像素宽度，再换算为 ActionPane.extentRatio。
    final estW = pinLabel.length * 16.0 +
        muteLabel.length * 16.0 +
        56 +
        3 * 15 +
        24; // 删除 + 间距
    // 侧滑展开宽度占屏宽比例，夹在 0.42～0.72 之间以免过窄裁字或过宽占满屏。
    final extentRatio = (estW / sw).clamp(0.42, 0.72);

    final baseBg = conv.pinned
        ? AppColors.bgPage.resolveFrom(context)
        : AppColors.bgWhite.resolveFrom(context);
    final rowMaterialColor = baseBg;

    return Slidable(
      key: GvAutomationKeys.conversation(conv.chatType, conv.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: extentRatio,
        children: [
          CustomSlidableAction(
            onPressed: (_) => onPin(),
            backgroundColor: AppColors.primary.resolveFrom(context),
            foregroundColor: CupertinoColors.white,
            flex: pinLabel.length >= 4 ? 5 : 4,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text(
                pinLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.15,
                ),
              ),
            ),
          ),
          CustomSlidableAction(
            onPressed: (_) => onMute(),
            backgroundColor: AppColors.textSecondary.resolveFrom(context),
            foregroundColor: CupertinoColors.white,
            flex: 4,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Center(
              child: Text(
                muteLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.15,
                ),
              ),
            ),
          ),
          if (deleteEnabled)
            CustomSlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppColors.danger.resolveFrom(context),
              foregroundColor: CupertinoColors.white,
              flex: 3,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Center(
                child: Text(
                  deleteLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.15,
                  ),
                ),
              ),
            ),
        ],
      ),
      child: Material(
        color: rowMaterialColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onOpen,
              splashFactory: InkRipple.splashFactory,
              splashColor: AppColors.textPrimary
                  .resolveFrom(context)
                  .withValues(alpha: 0.10),
              highlightColor: AppColors.textPrimary
                  .resolveFrom(context)
                  .withValues(alpha: 0.06),
              hoverColor: AppColors.textPrimary
                  .resolveFrom(context)
                  .withValues(alpha: 0.05),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  GvSpacing.page,
                  isFirst ? GvSpacing.cellV : _kChatListDividerGapHalf,
                  GvSpacing.page,
                  isLast ? GvSpacing.cellV : _kChatListDividerGapHalf,
                ),
                child: Row(
                  children: [
                    GvAvatar(
                        name: conv.name,
                        uid: conv.id,
                        src: conv.avatar.isEmpty ? null : conv.avatar,
                        size: _kChatListAvatarSize),
                    const SizedBox(width: GvSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (conv.pinned) ...[
                                Icon(LucideIcons.pin,
                                    size: 13,
                                    color: AppColors.textHint
                                        .resolveFrom(context)
                                        .withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                              ],
                              if (conv.muted) ...[
                                Icon(LucideIcons.bell_off,
                                    size: 13,
                                    color: AppColors.textHint
                                        .resolveFrom(context)
                                        .withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                              ],
                              if (hasAtMention) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.danger.resolveFrom(context),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    '@',
                                    style: GvTypography.tabLabel(
                                            CupertinoColors.white)
                                        .copyWith(fontSize: 10),
                                  ),
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  conv.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GvTypography.navTitle(AppColors
                                      .textPrimary
                                      .resolveFrom(context)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            (conv.draftText != null &&
                                    conv.draftText!.isNotEmpty)
                                ? '${l10n.chatDraftPrefix} ${conv.draftText!}'
                                : localizedConversationPreview(
                                    l10n,
                                    conv.lastMessage,
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GvTypography.caption(
                              (conv.draftText != null &&
                                      conv.draftText!.isNotEmpty)
                                  ? AppColors.danger.resolveFrom(context)
                                  : AppColors.textSecondary.resolveFrom(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formatTime(conv.lastTime),
                            style: GvTypography.caption(
                                    AppColors.textHint.resolveFrom(context))
                                .copyWith(fontSize: 11)),
                        if (visibleUnread > 0) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.danger.resolveFrom(context),
                                borderRadius:
                                    BorderRadius.circular(GvRadii.input)),
                            child: Text(
                              visibleUnread > 99 ? '99+' : '$visibleUnread',
                              style:
                                  GvTypography.tabLabel(CupertinoColors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(
                  left: GvSpacing.page + _kChatListAvatarSize + GvSpacing.sm,
                  right: GvSpacing.page,
                ),
                child: SizedBox(
                  height: dividerH,
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: dividerColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
