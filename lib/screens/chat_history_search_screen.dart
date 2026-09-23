import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_chat_navigation.dart';
import '../core/config.dart';
import '../core/open_http_headers.dart';
import '../core/open_toast.dart';
import '../core/local_storage.dart';
import '../models/chat_message.dart';
import '../models/friend_models.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../services/im_api.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;
import '../widgets/open_image_viewer.dart';
import '../widgets/open_nav_bar.dart';
import '../widgets/open_video_viewer.dart';
import 'chat_history_search/chat_history_category_tabs.dart';
import 'chat_history_search/chat_history_date_tab.dart';
import 'chat_history_search/chat_history_search_helpers.dart';
import 'chat_history_search/chat_history_text_search_tab.dart';

/// 私聊或群聊的本地/已同步聊天记录检索（按类型，参考微信「聊天记录」）。
class ChatHistorySearchScreen extends StatefulWidget {
  const ChatHistorySearchScreen({
    super.key,
    required this.peerId,
    this.chatType = 'private',
  });

  final String peerId;

  /// `private`（好友）或 `group`（群成员）。
  final String chatType;

  @override
  State<ChatHistorySearchScreen> createState() =>
      _ChatHistorySearchScreenState();
}

/// 路由页状态：Tab、权限门闸、本地历史分页与四类子 Tab 的数据切片。
class _ChatHistorySearchScreenState extends State<ChatHistorySearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _textQuery = TextEditingController();
  bool _loading = true;
  bool _allowed = false;
  bool _loadingMore = false;
  bool _noMoreOlder = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_onTabControllerTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  /// Tab 动画/索引变化时触发 rebuild，仅构建当前选中 Tab 以减负。
  void _onTabControllerTick() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabControllerTick);
    _tabController.dispose();
    _textQuery.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatHistorySearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.peerId != widget.peerId ||
        oldWidget.chatType != widget.chatType) {
      _noMoreOlder = false;
      _loadingMore = false;
    }
  }

  /// 列表新在上、旧在下；滑近底部加载更早一页（与 [ChatProvider.loadHistory] before 语义一致）。
  Future<void> _loadMoreOlder() async {
    if (_loadingMore || _noMoreOlder || _loading || !_allowed) return;
    final chat = context.read<ChatProvider>();
    final vis = chat.visibleMessagesFor(widget.peerId, widget.chatType);
    if (vis.isEmpty) {
      setState(() => _noMoreOlder = true);
      return;
    }
    setState(() => _loadingMore = true);
    final r = await chat.loadHistory(
      widget.peerId,
      widget.chatType,
      beforeMsgId: vis.first.msgId,
    );
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      const pageSize = 30;
      final atEnd = r.serverCount == 0 ||
          (r.serverCount < pageSize && r.added == r.serverCount);
      if (atEnd) _noMoreOlder = true;
    });
  }

  void _onScrollNearBottom(ScrollMetrics m) {
    if (_loading || !_allowed || _loadingMore || _noMoreOlder) return;
    if (!m.hasViewportDimension) return;
    if (m.axis != Axis.vertical) return;
    if (m.maxScrollExtent <= 0) return;
    if (m.pixels < m.maxScrollExtent - 240) return;
    _loadMoreOlder();
  }

  /// 包裹非文本 Tab 的 [ListView]/[CustomScrollView]，统一监听触底分页。
  Widget _wrapLoadMoreScroll(Widget child) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification n) {
        if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
          _onScrollNearBottom(n.metrics);
        }
        return false;
      },
      child: child,
    );
  }

  /// 本地历史列表底部：分页指示或「已全部加载」。
  Widget _historyListFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final primary = AppColors.primary.resolveFrom(context);
    if (_loadingMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: primary,
            ),
          ),
        ),
      );
    }
    if (_noMoreOlder) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Center(
          child: Text(
            l10n.chatHistoryAllLoaded,
            style: GvTypography.caption(secondary),
          ),
        ),
      );
    }
    return const SizedBox(height: 12);
  }

  /// 当前私聊对方在好友列表中的记录（用于展示名与权限）。
  FriendItem? _friendForPeer(List<FriendItem> friends) {
    final fid = int.tryParse(widget.peerId);
    if (fid == null) return null;
    for (final f in friends) {
      if (f.friendId == fid) return f;
    }
    return null;
  }

  /// 进页：校验好友或群成员，再拉首屏本地历史。
  Future<void> _bootstrap() async {
    final gateOk = widget.chatType == 'private'
        ? await _runPrivateFriendGate()
        : await _runGroupMemberGate();
    if (!gateOk || !mounted) return;

    setState(() => _allowed = true);
    await context
        .read<ChatProvider>()
        .loadHistory(widget.peerId, widget.chatType);
    if (mounted) setState(() => _loading = false);
  }

  /// 私聊：须为双向好友，否则提示并退出。
  Future<bool> _runPrivateFriendGate() async {
    await context.read<FriendProvider>().loadFriends();
    if (!mounted) return false;
    final fr = _friendForPeer(context.read<FriendProvider>().friends);
    if (fr == null) {
      GvToast.show(
        context,
        AppLocalizations.of(context)!.toastChatHistoryFriendsOnly,
      );
      context.pop();
      return false;
    }
    return true;
  }

  /// 群聊：须为群成员，否则提示并退出。
  Future<bool> _runGroupMemberGate() async {
    final gid = int.tryParse(widget.peerId);
    if (gid == null) {
      if (mounted) context.pop();
      return false;
    }
    final gp = context.read<GroupProvider>();
    await gp.loadMembers(gid);
    if (!mounted) return false;
    final myId = context.read<AuthProvider>().user?.id;
    final inGroup =
        myId != null && gp.currentGroupMembers.any((m) => m.userId == myId);
    if (!inGroup) {
      GvToast.show(
        context,
        AppLocalizations.of(context)!.toastChatHistoryGroupOnly,
      );
      context.pop();
      return false;
    }
    return true;
  }

  /// 消息列表行左侧发送者文案（我 / 好友名 / 群昵称）。
  String _senderLabel(
    AppLocalizations l10n,
    ChatMessage m,
    int? myId,
    FriendItem? fr,
    GroupProvider gp,
  ) {
    if (myId != null && m.from == myId) return l10n.chatHistorySenderMe;
    if (widget.chatType == 'private') {
      if (fr != null && m.from == fr.friendId) return fr.displayName;
      final u = m.fromUsername?.trim();
      if (u != null && u.isNotEmpty) return u;
      return l10n.chatHistorySenderPeer;
    }
    for (final mem in gp.currentGroupMembers) {
      if (mem.userId == m.from) return mem.displayName;
    }
    final u = m.fromUsername?.trim();
    if (u != null && u.isNotEmpty) return u;
    return l10n.displayUserIdLabel('${m.from}');
  }

  List<ChatMessage> _visible(ChatProvider chat) {
    return chat.visibleMessagesFor(widget.peerId, widget.chatType);
  }

  void _openAnchoredRoom(ChatMessage m) {
    gvOpenChat(
      context,
      chatType: widget.chatType,
      peerId: widget.peerId,
      anchorMsgId: m.msgId,
      anchorSeedMessage: m,
    );
  }

  /// 仅构建当前选中的 Tab；文件/图片/视频在选中后才挂载。
  Widget _buildCurrentTabContent(
    BuildContext context, {
    required AppLocalizations l10n,
    required int? myId,
    required FriendItem? fr,
    required GroupProvider gp,
    required String baseUrl,
    required Map<String, String>? authHdrs,
    required List<ChatMessage> fileList,
    required List<ChatMessage> imageList,
    required List<ChatMessage> videoList,
    required List<ChatMessage> allMessages,
  }) {
    String monthKey(int y, int m) => l10n.chatHistoryMonthLabel(y, m);

    switch (_tabController.index) {
      case 0:
        return ChatHistoryTextSearchTab(
          queryController: _textQuery,
          peerId: widget.peerId,
          chatType: widget.chatType,
          localCaptionMessages: imageList,
          searchMessages: context.read<ChatProvider>().searchChatMessages,
          senderLabel: (m) => _senderLabel(l10n, m, myId, fr, gp),
          displayBody: (s) => displayTextBodyStripEmojiTags(
            s,
            l10n.chatHistoryEmojiPlaceholder,
          ),
          onOpenMessage: _openAnchoredRoom,
        );
      case 1:
        return _wrapLoadMoreScroll(
          ChatHistoryFileCategoryTab(
            messages: chatMessagesNewestFirst(fileList),
            groups: groupChatMessagesByYearMonth(fileList, monthKey),
            senderLabel: (m) => _senderLabel(l10n, m, myId, fr, gp),
            onOpenMessage: _openAnchoredRoom,
            listFooter: _historyListFooter(context),
          ),
        );
      case 2:
        return _wrapLoadMoreScroll(
          ChatHistoryImageCategoryTab(
            messages: chatMessagesNewestFirst(imageList),
            groups: groupChatMessagesByYearMonth(imageList, monthKey),
            baseUrl: baseUrl,
            authHdrs: authHdrs,
            onTapImage: (url) => showGvImageViewer(
              context,
              imageUrl: url,
              api: context.read<ImApi>(),
            ),
            listFooter: _historyListFooter(context),
          ),
        );
      case 3:
        return _wrapLoadMoreScroll(
          ChatHistoryVideoCategoryTab(
            messages: chatMessagesNewestFirst(videoList),
            groups: groupChatMessagesByYearMonth(videoList, monthKey),
            baseUrl: baseUrl,
            authHdrs: authHdrs,
            onTapVideo: (url, headers) => showGvVideoViewer(
              context,
              videoUrl: url,
              api: context.read<ImApi>(),
              httpHeaders: headers,
            ),
            listFooter: _historyListFooter(context),
          ),
        );
      case 4:
        return ChatHistoryDateTab(
          peerId: widget.peerId,
          chatType: widget.chatType,
          senderLabel: (m) => _senderLabel(l10n, m, myId, fr, gp),
          onOpenMessage: _openAnchoredRoom,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!_allowed) {
      return Scaffold(
        backgroundColor: gvPageScaffoldBackground(context),
        appBar: GvNavBar(title: l10n.chatHistoryTitle, showBack: true),
        body: Center(
          child: Text(
            l10n.chatHistoryNoPermission,
            style: GvTypography.body(AppColors.textHint.resolveFrom(context)),
          ),
        ),
      );
    }

    final chat = context.watch<ChatProvider>();
    final auth = context.watch<AuthProvider>();
    final f = context.watch<FriendProvider>();
    final gp = context.watch<GroupProvider>();
    final fr = _friendForPeer(f.friends);
    final myId = auth.user?.id;
    const baseUrl = AppConfig.mediaBase;
    final storage = context.read<LocalStorage>();
    final authHdrs = gvBearerHeaders(storage);

    final all = _visible(chat);
    final fileList = all.where((m) => m.msgType == 'file').toList();
    final imageList = all.where((m) => m.msgType == 'image').toList();
    final videoList = all.where((m) => m.msgType == 'video').toList();

    Widget buildBody() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: TabBar(
                controller: _tabController,
                onTap: (index) {
                  if (_tabController.index != index) {
                    _tabController.index = index;
                  }
                },
                labelColor: AppColors.primary.resolveFrom(context),
                unselectedLabelColor:
                    AppColors.textSecondary.resolveFrom(context),
                indicatorColor: AppColors.primary.resolveFrom(context),
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GvTypography.bodySmall(
                  AppColors.textPrimary.resolveFrom(context),
                ),
                unselectedLabelStyle: GvTypography.bodySmall(
                  AppColors.textSecondary.resolveFrom(context),
                ),
                tabs: [
                  Tab(text: l10n.chatHistoryTabText),
                  Tab(text: l10n.chatHistoryTabFiles),
                  Tab(text: l10n.chatHistoryTabImages),
                  Tab(text: l10n.chatHistoryTabVideos),
                  Tab(text: l10n.chatHistoryTabDate),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary.resolveFrom(context),
                      ),
                    )
                  : _buildCurrentTabContent(
                      context,
                      l10n: l10n,
                      myId: myId,
                      fr: fr,
                      gp: gp,
                      baseUrl: baseUrl,
                      authHdrs: authHdrs,
                      fileList: fileList,
                      imageList: imageList,
                      videoList: videoList,
                      allMessages: all,
                    ),
            ),
          ],
        );

    Widget body = buildBody();
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.chatHistoryTitle, showBack: true),
      body: body,
    );
  }
}
