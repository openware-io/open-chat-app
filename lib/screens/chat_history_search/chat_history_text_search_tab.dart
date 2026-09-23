import 'dart:async';

import 'package:flutter/material.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_ui/open_ui.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/open_toast.dart';
import '../../core/media_url.dart';
import '../../models/chat_message.dart';
import 'chat_history_search_helpers.dart';

typedef ChatHistorySearchMessages = Future<List<dynamic>> Function({
  String? peerId,
  String? chatType,
  required String keyword,
  String msgType,
  int page,
  int pageSize,
  String? beforeMsgId,
});

/// 聊天记录页「文本」Tab：关键词提交后走服务端检索，列表新在上、触底分页。
class ChatHistoryTextSearchTab extends StatefulWidget {
  const ChatHistoryTextSearchTab({
    super.key,
    required this.queryController,
    required this.peerId,
    required this.chatType,
    required this.localCaptionMessages,
    required this.searchMessages,
    required this.senderLabel,
    required this.displayBody,
    required this.onOpenMessage,
  });

  final TextEditingController queryController;
  final String peerId;
  final String chatType;
  final List<ChatMessage> localCaptionMessages;
  final ChatHistorySearchMessages searchMessages;
  final String Function(ChatMessage m) senderLabel;
  final String Function(String raw) displayBody;

  /// 点击检索结果，带上完整 [ChatMessage] 进聊天室锚定。
  final void Function(ChatMessage message) onOpenMessage;

  @override
  State<ChatHistoryTextSearchTab> createState() =>
      _ChatHistoryTextSearchTabState();
}

class _ChatHistoryTextSearchTabState extends State<ChatHistoryTextSearchTab> {
  static const int _pageSize = 30;

  List<ChatMessage> _remoteHits = [];
  bool _remoteLoading = false;
  bool _remotePaging = false;
  bool _remoteNoMore = false;

  /// 最近一次点击「搜索」提交的关键词；分页与列表展示均以此为准。
  String _activeSearchKeyword = '';
  int _searchSeq = 0;

  Future<({List<dynamic> raw, bool failed})> _searchMessageType({
    required String keyword,
    required String msgType,
    String? beforeMsgId,
  }) async {
    try {
      final raw = await widget.searchMessages(
        peerId: widget.peerId,
        chatType: widget.chatType,
        keyword: keyword,
        msgType: msgType,
        beforeMsgId: beforeMsgId,
        pageSize: _pageSize,
      );
      return (raw: raw, failed: false);
    } catch (_) {
      return (raw: const <dynamic>[], failed: true);
    }
  }

  List<ChatMessage> _mergeLocalCaptionHits(
    List<ChatMessage> remote,
    String keyword,
  ) {
    final normalizedKeyword = keyword.trim().toLowerCase();
    final byId = <String, ChatMessage>{for (final m in remote) m.msgId: m};
    for (final m in widget.localCaptionMessages) {
      final caption = parseImageForChat('', m.content).caption.toLowerCase();
      if (caption.contains(normalizedKeyword)) byId[m.msgId] = m;
    }
    return byId.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  void didUpdateWidget(covariant ChatHistoryTextSearchTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.peerId != widget.peerId ||
        oldWidget.chatType != widget.chatType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _remoteHits = [];
          _remoteLoading = false;
          _remotePaging = false;
          _remoteNoMore = false;
          _activeSearchKeyword = '';
          _searchSeq++;
        });
      });
    }
  }

  /// 输入清空时重置远端结果状态，避免展示过期关键词的数据。
  void _onSearchFieldChanged(String _) {
    if (widget.queryController.text.trim().isEmpty) {
      setState(() {
        _activeSearchKeyword = '';
        _remoteHits = [];
        _remoteLoading = false;
        _remotePaging = false;
        _remoteNoMore = false;
        _searchSeq++;
      });
    }
  }

  /// 提交检索：空关键词则清空；否则递增序列号并拉第一页。
  void _submitSearch() {
    FocusScope.of(context).unfocus();
    final q = widget.queryController.text.trim();
    if (q.isEmpty) {
      setState(() {
        _activeSearchKeyword = '';
        _remoteHits = [];
        _remoteLoading = false;
        _remotePaging = false;
        _remoteNoMore = false;
        _searchSeq++;
      });
      return;
    }
    final seq = ++_searchSeq;
    unawaited(_fetchRemoteFirstPage(q, seq));
  }

  /// 请求第一页检索结果；[seq] 与 [_searchSeq] 不一致时丢弃响应（防竞态）。
  Future<void> _fetchRemoteFirstPage(String keyword, int seq) async {
    setState(() {
      _remoteLoading = true;
      _remoteHits = [];
      _remoteNoMore = false;
      _activeSearchKeyword = keyword;
    });
    try {
      final results = await Future.wait([
        _searchMessageType(keyword: keyword, msgType: 'text'),
        _searchMessageType(keyword: keyword, msgType: 'image'),
      ]);
      if (results.every((result) => result.failed)) {
        throw StateError('Search requests failed');
      }
      if (!mounted || seq != _searchSeq) return;
      final parsed = _mergeLocalCaptionHits(
        parseRemoteChatSearchHits(
          [...results[0].raw, ...results[1].raw],
          keyword: keyword,
        ),
        keyword,
      );
      setState(() {
        _remoteHits = parsed;
        _remoteLoading = false;
        _remoteNoMore =
            results.every((result) => result.raw.length < _pageSize);
      });
    } catch (_) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _remoteLoading = false;
        _remoteHits = [];
      });
      GvToast.show(context, AppLocalizations.of(context)!.toastSearchFailed);
    }
  }

  /// 以当前列表最旧一条的 [msgId] 为游标请求更早一页。
  Future<void> _loadMoreRemote() async {
    final kw = _activeSearchKeyword;
    if (kw.isEmpty ||
        _remoteNoMore ||
        _remotePaging ||
        _remoteLoading ||
        _remoteHits.isEmpty) {
      return;
    }
    setState(() => _remotePaging = true);
    try {
      final oldest = _remoteHits.last.msgId;
      final results = await Future.wait([
        _searchMessageType(
          keyword: kw,
          msgType: 'text',
          beforeMsgId: oldest,
        ),
        _searchMessageType(
          keyword: kw,
          msgType: 'image',
          beforeMsgId: oldest,
        ),
      ]);
      if (results.every((result) => result.failed)) {
        throw StateError('Search requests failed');
      }
      if (!mounted || kw != _activeSearchKeyword) return;
      final more = parseRemoteChatSearchHits(
        [...results[0].raw, ...results[1].raw],
        keyword: kw,
      );
      setState(() {
        final seen = _remoteHits.map((m) => m.msgId).toSet();
        for (final m in more) {
          if (!seen.contains(m.msgId)) {
            _remoteHits.add(m);
            seen.add(m.msgId);
          }
        }
        _remoteHits.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        _remotePaging = false;
        if (results.every((result) => result.raw.length < _pageSize)) {
          _remoteNoMore = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _remotePaging = false);
      GvToast.show(context, AppLocalizations.of(context)!.toastLoadMoreFailed);
    }
  }

  /// 列表接近底部时触发 [_loadMoreRemote]。
  void _onScroll(ScrollMetrics m) {
    if (!m.hasViewportDimension || m.axis != Axis.vertical) return;
    if (m.maxScrollExtent <= 0 || m.pixels < m.maxScrollExtent - 240) return;
    if (_activeSearchKeyword.isEmpty) return;
    unawaited(_loadMoreRemote());
  }

  /// 检索列表底部：分页 loading 或「已全部显示」提示。
  Widget _remoteFooter(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final primary = AppColors.primary.resolveFrom(context);
    if (_remotePaging) {
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
    if (_remoteNoMore && _remoteHits.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Center(
          child: Text(
            l10n.chatHistorySearchAllResultsShown,
            style: GvTypography.caption(secondary),
          ),
        ),
      );
    }
    return const SizedBox(height: 12);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hint = AppColors.textHint.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final primary = AppColors.primary.resolveFrom(context);
    final dividerColor = Theme.of(context).dividerColor;
    final hasCommittedSearch = _activeSearchKeyword.isNotEmpty;
    final messages = hasCommittedSearch ? _remoteHits : const <ChatMessage>[];

    final Widget listBody;
    if (!hasCommittedSearch) {
      listBody = const Center(child: SizedBox.shrink());
    } else if (_remoteLoading && _remoteHits.isEmpty) {
      listBody = Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary.resolveFrom(context),
          ),
        ),
      );
    } else if (messages.isEmpty) {
      listBody = GvEmptyState(
        text: l10n.chatHistorySearchNoMatches,
        textStyle: GvTypography.caption(secondary),
      );
    } else {
      listBody = ListView.builder(
        padding: const EdgeInsets.only(bottom: GvSpacing.page),
        itemCount: messages.length + 1,
        itemBuilder: (context, i) {
          if (i == messages.length) {
            return _remoteFooter(context);
          }
          final m = messages[i];
          final body = m.msgType == 'image'
              ? parseImageForChat('', m.content).caption
              : widget.displayBody(m.content);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  indent: GvSpacing.page,
                  endIndent: GvSpacing.page,
                  color: dividerColor,
                ),
              GvSearchResultRow(
                primaryText: widget.senderLabel(m),
                primaryStyle: GvTypography.caption(secondary),
                trailingText: formatChatTime(m.timestamp),
                trailingStyle: GvTypography.caption(secondary),
                bodyText: body,
                bodyStyle: GvTypography.body(
                  AppColors.textPrimary.resolveFrom(context),
                ),
                onTap: () => widget.onOpenMessage(m),
              ),
            ],
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GvSpacing.page,
            GvSpacing.sm,
            GvSpacing.page,
            4,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GvRadii.input),
            child: Material(
              color: AppColors.bgWhite.resolveFrom(context),
              child: TextField(
                controller: widget.queryController,
                onChanged: _onSearchFieldChanged,
                onSubmitted: (_) => _submitSearch(),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.chatHistorySearchFieldHint,
                  hintStyle: GvTypography.body(hint),
                  suffixIcon: IconButton(
                    tooltip: l10n.commonSearch,
                    onPressed: _remoteLoading ? null : _submitSearch,
                    icon: Icon(
                      LucideIcons.search,
                      size: 22,
                      color: _remoteLoading ? hint : primary,
                    ),
                  ),
                  filled: true,
                  fillColor: AppColors.bgWhite.resolveFrom(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GvRadii.input),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GvRadii.input),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(GvRadii.input),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: GvSpacing.sm,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                style: GvTypography.body(
                  AppColors.textPrimary.resolveFrom(context),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GvSpacing.page,
            0,
            GvSpacing.page,
            GvSpacing.sm,
          ),
          child: Text(
            l10n.chatHistorySearchScopeNote,
            style: GvTypography.caption(secondary),
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification n) {
              if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
                _onScroll(n.metrics);
              }
              return false;
            },
            child: listBody,
          ),
        ),
      ],
    );
  }
}
