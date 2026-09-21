import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/formatters.dart';
import '../core/gv_toast.dart';
import '../core/message_preview.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_message.dart';
import '../repositories/favorite_repository.dart';
import '../widgets/gv_nav_bar.dart';
import 'favorite_detail_screen.dart';

/// 「收藏」列表页：分页加载收藏消息、按类型筛选，点击进入收藏详情页。
///
/// 列表项展示的是**收藏自身保存的内容**（原消息删除后仍可读）；
/// 进入详情页后再由「查看原消息」按需向服务端确认原消息可用性。
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const int _pageSize = 20;

  /// 单次拉取最多补拉的页数：筛选稀有类型时不至于长时间空转。
  static const int _maxFillPages = 5;

  /// 当前类型筛选：`all` 或具体 msgType 分组。
  String _filter = 'all';

  /// 服务端返回的原始收藏记录（类型筛选在本地完成，现有列表接口不带类型参数）。
  final List<ChatMessage> _raw = <ChatMessage>[];

  /// 多选模式与已选消息 id（进入多选后点击条目切换选中）。
  bool _multiSelect = false;
  final Set<String> _selectedMsgIds = <String>{};

  final ScrollController _scrollController = ScrollController();

  bool _loading = false;
  bool _hasMore = true;
  bool _initialLoaded = false;
  bool _loadFailed = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadMore());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 当前筛选下的可见收藏。
  List<ChatMessage> get _visibleItems => _raw
      .where((m) => _filter == 'all' || _filterGroupOf(m.msgType) == _filter)
      .toList(growable: false);

  /// 把消息类型归入筛选项：文本 / 图片 / 视频 / 语音 / 文件 / 其他。
  static String _filterGroupOf(String msgType) {
    return switch (msgType) {
      'text' => 'text',
      'image' => 'image',
      'video' => 'video',
      'voice' => 'voice',
      'file' => 'file',
      _ => 'other',
    };
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final repo = context.read<FavoriteRepository>();
      // 类型筛选在本地完成：筛选项下内容不足一页时继续补拉，保证列表能填满可视区域。
      var fetched = 0;
      while (_hasMore && fetched < _maxFillPages) {
        final page = await repo.listFavorites(page: _page, pageSize: _pageSize);
        if (!mounted) return;
        _raw.addAll(page);
        _page++;
        _hasMore = page.length >= _pageSize;
        fetched++;
        if (_filter == 'all' || _visibleItems.length >= _pageSize) break;
      }
      if (!mounted) return;
      setState(() => _initialLoaded = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialLoaded = true;
        if (_raw.isEmpty) _loadFailed = true;
      });
      // 仅翻页失败（列表已有内容）时用 toast 提示；首屏失败走错误态 + 重试。
      if (_raw.isNotEmpty) {
        GvToast.show(
            context, AppLocalizations.of(context)!.favoritesLoadFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {
      _raw.clear();
      _page = 1;
      _hasMore = true;
      _initialLoaded = false;
      _loadFailed = false;
      _selectedMsgIds.clear();
    });
    await _loadMore();
  }

  /// 切换类型筛选；筛选项下内容不足一页时继续补拉。
  void _onFilterChanged(String value) {
    if (_filter == value) return;
    setState(() => _filter = value);
    if (_visibleItems.length < _pageSize && _hasMore) {
      unawaited(_loadMore());
    }
  }

  /// 点击收藏：多选模式下切换选中，否则进入收藏详情页。
  Future<void> _onTapItem(ChatMessage m) async {
    if (_multiSelect) {
      _toggleSelect(m.msgId);
      return;
    }
    final result = await context.push<FavoriteDetailResult>(
      AppRoutes.favoriteDetail,
      extra: m,
    );
    if (!mounted) return;
    if (result == FavoriteDetailResult.removed) {
      setState(() => _raw.removeWhere((x) => x.msgId == m.msgId));
    } else if (result == FavoriteDetailResult.enterMultiSelect) {
      // 详情页的「多选」：回到列表并选中当前条目，便于批量转发/删除。
      setState(() {
        _multiSelect = true;
        _selectedMsgIds
          ..clear()
          ..add(m.msgId);
      });
    }
  }

  void _enterMultiSelect(ChatMessage m) {
    setState(() {
      _multiSelect = true;
      _selectedMsgIds
        ..clear()
        ..add(m.msgId);
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _multiSelect = false;
      _selectedMsgIds.clear();
    });
  }

  void _toggleSelect(String msgId) {
    setState(() {
      if (!_selectedMsgIds.add(msgId)) {
        _selectedMsgIds.remove(msgId);
      }
    });
  }

  List<ChatMessage> get _selectedItems =>
      _raw.where((m) => _selectedMsgIds.contains(m.msgId)).toList();

  /// 多选「转发」：仅单选时可用（转发页一次只转发一条）。
  void _forwardSelected() {
    final selected = _selectedItems;
    if (selected.length != 1) return;
    context.push(AppRoutes.forwardMessage, extra: selected.first);
  }

  /// 多选「删除」：现有取消收藏接口按单条 msgId 删除，这里逐条调用（幂等）。
  Future<void> _deleteSelected() async {
    final selected = _selectedItems;
    if (selected.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Text(l10n.favoritesDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, true),
            child: Text(
              l10n.commonDelete,
              style: TextStyle(color: AppColors.danger.resolveFrom(context)),
            ),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;

    final repo = context.read<FavoriteRepository>();
    final removed = <String>[];
    var failed = 0;
    for (final m in selected) {
      try {
        await repo.removeFavorite(m.msgId);
        removed.add(m.msgId);
      } catch (_) {
        failed++;
      }
    }
    if (!mounted) return;
    setState(() {
      _raw.removeWhere((x) => removed.contains(x.msgId));
      _selectedMsgIds.removeAll(removed);
      if (_selectedMsgIds.isEmpty) _multiSelect = false;
    });
    GvToast.show(
      context,
      failed == 0 ? l10n.favoriteRemoved : l10n.favoriteRemovedFailed,
      duration: const Duration(seconds: 1),
    );
  }

  String _titleFor(ChatMessage m, AppLocalizations l10n) {
    final name = m.fromUsername?.trim();
    if (name != null && name.isNotEmpty) return name;
    return l10n.chatUserDefaultTitle('${m.from}');
  }

  (IconData, Color) _glyphFor(String chatType, Color hint, Color primary) {
    return switch (chatType) {
      'group' => (LucideIcons.users, hint),
      'channel' => (LucideIcons.megaphone, primary),
      'secret' => (LucideIcons.lock, primary),
      'secret_group' => (LucideIcons.lock, primary),
      _ => (LucideIcons.user, hint),
    };
  }

  /// 类型筛选条：全部 / 文本 / 图片 / 视频 / 语音 / 文件 / 其他。
  Widget _buildFilterBar(AppLocalizations l10n, Color hint) {
    final options = <(String, String)>[
      ('all', l10n.favoritesFilterAll),
      ('text', l10n.favoritesFilterText),
      ('image', l10n.favoritesFilterImage),
      ('video', l10n.favoritesFilterVideo),
      ('voice', l10n.favoritesFilterVoice),
      ('file', l10n.favoritesFilterFile),
      ('other', l10n.favoritesFilterOther),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: GvSpacing.page,
          vertical: GvSpacing.xs,
        ),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: GvSpacing.sm),
        itemBuilder: (context, index) {
          final (value, label) = options[index];
          return ChoiceChip(
            label: Text(label),
            selected: _filter == value,
            onSelected: (_) => _onFilterChanged(value),
          );
        },
      ),
    );
  }

  /// 多选底部操作栏：转发（单选）/ 删除。
  Widget _buildMultiSelectActionBar(AppLocalizations l10n) {
    final danger = AppColors.danger.resolveFrom(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GvSpacing.page,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: gvPageScaffoldBackground(context),
          border: Border(
            top: BorderSide(
              color:
                  AppColors.textHint.resolveFrom(context).withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _selectedMsgIds.length == 1 ? _forwardSelected : null,
                child: Text(l10n.chatActionForward),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _selectedMsgIds.isEmpty
                    ? null
                    : () => unawaited(_deleteSelected()),
                style: FilledButton.styleFrom(backgroundColor: danger),
                child: Text(l10n.commonDelete),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    AppLocalizations l10n,
    Color hint, {
    required IconData icon,
    required String text,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: hint.withValues(alpha: 0.5)),
          const SizedBox(height: GvSpacing.sm),
          Text(
            text,
            style: GvTypography.caption(
              AppColors.textSecondary.resolveFrom(context).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, Color hint, Color primary) {
    if (_loading && _raw.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_loadFailed && _raw.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.cloud_off,
                size: 56, color: hint.withValues(alpha: 0.5)),
            const SizedBox(height: GvSpacing.sm),
            Text(
              l10n.favoritesLoadFailed,
              style: GvTypography.caption(
                AppColors.textSecondary
                    .resolveFrom(context)
                    .withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: GvSpacing.sm),
            FilledButton(
              onPressed: _refresh,
              child: Text(l10n.commonRetry),
            ),
          ],
        ),
      );
    }
    final items = _visibleItems;
    if (items.isEmpty) {
      return _buildEmptyState(
        l10n,
        hint,
        icon: _raw.isEmpty ? LucideIcons.star : LucideIcons.list_filter,
        text: _raw.isEmpty ? l10n.favoritesEmpty : l10n.favoritesFilterEmpty,
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: GvSpacing.sm),
        itemCount: items.length + (_hasMore || !_initialLoaded ? 1 : 0),
        separatorBuilder: (_, __) => Divider(
          height: 1,
          thickness: 0.5,
          indent: 72,
          color: hint.withValues(alpha: 0.22),
        ),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CupertinoActivityIndicator()),
            );
          }
          final m = items[index];
          final (icon, iconColor) = _glyphFor(m.chatType, hint, primary);
          final selected = _selectedMsgIds.contains(m.msgId);
          return ListTile(
            leading: _multiSelect
                ? Checkbox(
                    value: selected,
                    onChanged: (_) => _toggleSelect(m.msgId),
                  )
                : CircleAvatar(
                    radius: 20,
                    backgroundColor: iconColor.withValues(alpha: 0.12),
                    child: Icon(icon, size: 20, color: iconColor),
                  ),
            title: Text(
              _titleFor(m, l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GvTypography.navTitle(
                AppColors.textPrimary.resolveFrom(context),
              ),
            ),
            subtitle: Text(
              getMessagePreview(msgType: m.msgType, content: m.content),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GvTypography.caption(
                AppColors.textSecondary.resolveFrom(context),
              ),
            ),
            trailing: Text(
              formatTime(m.timestamp),
              style: GvTypography.caption(hint).copyWith(fontSize: 11),
            ),
            onTap: () => unawaited(_onTapItem(m)),
            onLongPress: _multiSelect ? null : () => _enterMultiSelect(m),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hint = AppColors.textHint.resolveFrom(context);
    final primary = AppColors.primary.resolveFrom(context);
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: _multiSelect
          ? GvNavBar(
              title: l10n.chatMultiSelectCount(_selectedMsgIds.length),
              showBack: false,
              right: TextButton(
                onPressed: _exitMultiSelect,
                child: Text(l10n.commonCancel),
              ),
            )
          : GvNavBar(title: l10n.favoritesTitle, showBack: true),
      body: Column(
        children: [
          if (_raw.isNotEmpty && !_multiSelect) _buildFilterBar(l10n, hint),
          Expanded(child: _buildBody(l10n, hint, primary)),
          if (_multiSelect) _buildMultiSelectActionBar(l10n),
        ],
      ),
    );
  }
}
