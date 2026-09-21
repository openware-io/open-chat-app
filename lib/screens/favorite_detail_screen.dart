import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:gv_ui/gv_ui.dart';
import 'package:provider/provider.dart';

import '../app/app_routes.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/call_trace_display.dart';
import '../core/config.dart';
import '../core/formatters.dart';
import '../core/gv_chat_navigation.dart';
import '../core/gv_http_headers.dart';
import '../core/gv_message_forward.dart';
import '../core/gv_toast.dart';
import '../core/local_storage.dart';
import '../core/media_url.dart';
import '../core/namecard_message.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_message.dart';
import '../models/favorite_models.dart';
import '../providers/chat_provider.dart';
import '../repositories/favorite_repository.dart';
import '../services/im_api.dart';
import '../widgets/gv_avatar.dart';
import '../widgets/gv_chat_video_thumbnail.dart';
import '../widgets/gv_image_viewer.dart';
import '../widgets/gv_nav_bar.dart';
import '../widgets/gv_video_viewer.dart';
import '../widgets/gv_voice_message_player.dart';
import 'chat_room/chat_room_media_helpers.dart';

/// 收藏详情页的返回结果：列表页据此刷新或进入多选。
enum FavoriteDetailResult {
  /// 已在详情页删除该收藏，列表需要移除。
  removed,

  /// 在详情页点了「多选」，列表页应进入多选模式并选中当前条目。
  enterMultiSelect,
}

/// 收藏详情页：只渲染**收藏自身保存的内容快照**，与「原消息是否还在」完全解耦。
///
/// 「查看原消息」是次级入口：先向服务端确认原消息是否仍可访问，
/// 只有 AVAILABLE 才允许跳转；其余状态（含查询失败）一律留在本页并给出中文说明。
class FavoriteDetailScreen extends StatefulWidget {
  const FavoriteDetailScreen({super.key, required this.message});

  /// 收藏记录（列表响应里已带回收藏时保存的 msgType/content）。
  final ChatMessage message;

  @override
  State<FavoriteDetailScreen> createState() => _FavoriteDetailScreenState();
}

class _FavoriteDetailScreenState extends State<FavoriteDetailScreen> {
  /// 是否正在向服务端确认原消息可用性。
  bool _checkingSource = false;

  /// 上一次确认结果不可跳转时的中文说明（常驻展示，不依赖 toast 消失）。
  String? _sourceNote;

  /// 转发能力与聊天室长按菜单一致（撤回墓碑/系统/通话，以及私密会话不可转发）。
  bool get _canForward => gvChatMessageCanForward(
        widget.message,
        chatType: widget.message.chatType,
      );

  /// 跳转原会话所需的 peerId：私聊取对方 userId，群/频道取 toId（收藏记录里存的是会话 peerId）。
  String _peerIdForOriginal() {
    final m = widget.message;
    if (m.chatType != 'private') return m.toId;
    final myId = context.read<ChatProvider>().myId;
    return m.from == myId ? m.toId : '${m.from}';
  }

  /// 「查看原消息」：先查可用性，再按状态决定跳转或说明（fail closed）。
  Future<void> _viewOriginal() async {
    if (_checkingSource) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _checkingSource = true;
      _sourceNote = null;
    });
    // 查询失败时仓库返回 LOOKUP_UNAVAILABLE，绝不跳转。
    final source = await context
        .read<FavoriteRepository>()
        .lookupSource(widget.message.msgId);
    if (!mounted) return;

    if (source.state == FavoriteSourceState.available) {
      final peerId = _peerIdForOriginal();
      setState(() => _checkingSource = false);
      if (peerId.isEmpty) {
        // 状态可用但收藏记录里没有可定位的会话：同样不跳转。
        GvToast.show(context, l10n.favoritesSourceConversationMissing);
        return;
      }
      gvOpenChat(
        context,
        chatType: widget.message.chatType,
        peerId: peerId,
        anchorMsgId: source.messageId,
      );
      return;
    }

    // 其余状态：留在本页，给出明确中文说明，收藏内容继续可读。
    final note = switch (source.state) {
      FavoriteSourceState.messageDeleted => l10n.favoritesSourceMessageDeleted,
      FavoriteSourceState.conversationUnavailable =>
        l10n.favoritesSourceConversationUnavailable,
      FavoriteSourceState.noPermission => l10n.favoritesSourceNoPermission,
      _ => l10n.favoritesSourceLookupUnavailable,
    };
    setState(() {
      _checkingSource = false;
      _sourceNote = note;
    });
    GvToast.show(context, note);
  }

  /// 转发：走既有转发页，转发的是收藏保存下来的内容。
  void _forward() {
    context.push(AppRoutes.forwardMessage, extra: widget.message);
  }

  /// 删除该收藏：二次确认后调服务端，并把结果回传给列表页。
  Future<void> _delete() async {
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
    try {
      await context
          .read<FavoriteRepository>()
          .removeFavorite(widget.message.msgId);
      if (!mounted) return;
      GvToast.show(
        context,
        l10n.favoriteRemoved,
        duration: const Duration(seconds: 1),
      );
      context.pop(FavoriteDetailResult.removed);
    } catch (_) {
      if (!mounted) return;
      GvToast.show(
        context,
        l10n.favoriteRemovedFailed,
        duration: const Duration(seconds: 1),
      );
    }
  }

  /// 「多选」：回到列表页并进入多选模式（当前条目默认选中），便于批量转发/删除。
  void _enterMultiSelect() {
    context.pop(FavoriteDetailResult.enterMultiSelect);
  }

  String _title(AppLocalizations l10n) {
    final name = widget.message.fromUsername?.trim();
    if (name != null && name.isNotEmpty) return name;
    return l10n.chatUserDefaultTitle('${widget.message.from}');
  }

  /// 收藏内容的类型标签（图片 / 视频 / 语音 …）。
  String _typeLabel(AppLocalizations l10n, String msgType) {
    return switch (msgType) {
      'text' => l10n.favoritesFilterText,
      'image' => l10n.favoritesFilterImage,
      'video' => l10n.favoritesFilterVideo,
      'voice' => l10n.favoritesFilterVoice,
      'file' => l10n.favoritesFilterFile,
      _ => l10n.favoritesFilterOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.favoritesDetailTitle, showBack: true),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(GvSpacing.page),
              children: [
                _buildHeader(context, l10n),
                const SizedBox(height: GvSpacing.page),
                _buildContentCard(context, l10n),
                const SizedBox(height: GvSpacing.page),
                _buildSourceEntry(context, l10n),
              ],
            ),
          ),
          _buildActionBar(context, l10n),
        ],
      ),
    );
  }

  /// 头部：发送者 + 会话类型 + 收藏内容类型 + 时间。
  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    final m = widget.message;
    final hint = AppColors.textHint.resolveFrom(context);
    final secondary = AppColors.textSecondary.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(GvSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.bgWhite.resolveFrom(context),
        borderRadius: BorderRadius.circular(GvRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GvAvatar(
                name: _title(l10n),
                uid: m.from,
                src: m.fromAvatar,
                size: 36,
              ),
              const SizedBox(width: GvSpacing.sm),
              Expanded(
                child: Text(
                  _title(l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GvTypography.navTitle(
                    AppColors.textPrimary.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GvSpacing.sm),
          Row(
            children: [
              _buildTag(context, _typeLabel(l10n, m.msgType)),
              const SizedBox(width: GvSpacing.sm),
              Expanded(
                child: Text(
                  '${l10n.favoritesDetailTime} ${formatTime(m.timestamp)}',
                  style: GvTypography.caption(hint),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            m.chatType == 'private'
                ? l10n.convTypePrivate
                : (m.chatType == 'group' ? l10n.convTypeGroup : m.chatType),
            style: GvTypography.caption(secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text) {
    final primary = AppColors.primary.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(GvRadii.compact),
      ),
      child: Text(text, style: GvTypography.caption(primary)),
    );
  }

  /// 收藏内容卡片：只依赖收藏自身保存的 msgType/content 渲染。
  Widget _buildContentCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GvSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.bgWhite.resolveFrom(context),
        borderRadius: BorderRadius.circular(GvRadii.card),
      ),
      child: _buildContent(context, l10n),
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    final m = widget.message;
    const baseUrl = AppConfig.mediaBase;
    final authHdrs = gvBearerHeaders(context.read<LocalStorage>()) ??
        const <String, String>{};
    switch (m.msgType) {
      case 'image':
        final image = parseImageForChat(baseUrl, m.content);
        final url = image.imageUrl;
        if (url.isEmpty) return _buildEmpty(context, l10n);
        final sz = gvChatBubbleMediaDisplaySize(
          context,
          MediaQuery.sizeOf(context).width - GvSpacing.page * 4,
          image.w,
          image.h,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => showGvImageViewer(
                context,
                imageUrl: url,
                api: context.read<ImApi>(),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(GvRadii.input),
                child: CachedNetworkImage(
                  imageUrl: url,
                  httpHeaders: gvMediaRequestHeaders(url, authHdrs),
                  width: sz.dw,
                  height: sz.dh,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            if (image.caption.isNotEmpty) ...[
              const SizedBox(height: GvSpacing.sm),
              Text(
                image.caption,
                style: GvTypography.body(
                  AppColors.textPrimary.resolveFrom(context),
                ),
              ),
            ],
          ],
        );
      case 'video':
        final video = parseVideoForChat(baseUrl, m.content);
        final url = video.playUrl;
        if (url.isEmpty) return _buildEmpty(context, l10n);
        final headers = gvMediaRequestHeaders(url, authHdrs);
        return GestureDetector(
          onTap: () => showGvVideoViewer(
            context,
            videoUrl: url,
            api: context.read<ImApi>(),
            httpHeaders: headers,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(GvRadii.input),
            child: GvChatVideoThumbnail(
              videoUrl: url,
              posterUrl: video.posterResolved,
              httpHeaders: headers,
              width: 220,
              height: 150,
            ),
          ),
        );
      case 'voice':
        final url = resolveMediaUrl(baseUrl, m.content);
        if (url.isEmpty) return _buildEmpty(context, l10n);
        return GvVoiceMessagePlayer(
          url: url,
          fromSelf: false,
          color: AppColors.textPrimary.resolveFrom(context),
          imApi: context.read<ImApi>(),
        );
      case 'emoji':
        final url = resolveMediaUrl(baseUrl, m.content);
        if (url.isEmpty) return _buildEmpty(context, l10n);
        return CachedNetworkImage(
          imageUrl: url,
          httpHeaders: gvMediaRequestHeaders(url, authHdrs),
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        );
      case 'file':
        return _buildFile(context, l10n, baseUrl);
      case 'namecard':
        final card = NamecardPayload.tryParse(m.content);
        if (card == null) return _buildEmpty(context, l10n);
        return Row(
          children: [
            const Icon(LucideIcons.user_round, size: 20),
            const SizedBox(width: GvSpacing.sm),
            Expanded(
              child: Text(
                '${card.displayName}（${card.username}）',
                style: GvTypography.body(
                  AppColors.textPrimary.resolveFrom(context),
                ),
              ),
            ),
          ],
        );
      case 'call':
        return Text(
          parseCallTraceDisplay(l10n, m.content).line,
          style: GvTypography.body(AppColors.textPrimary.resolveFrom(context)),
        );
      case 'recall':
      case 'system':
        return _buildEmpty(context, l10n);
      default:
        final text = m.content.replaceAllMapped(
          RegExp(r'\[emoji\](\d+)\[/emoji\]'),
          (_) => l10n.chatHistoryEmojiPlaceholder,
        );
        if (text.trim().isEmpty) return _buildEmpty(context, l10n);
        return Text(
          text,
          style: GvTypography.body(AppColors.textPrimary.resolveFrom(context)),
        );
    }
  }

  Widget _buildFile(BuildContext context, AppLocalizations l10n, String baseUrl) {
    var name = l10n.favoritesFilterFile;
    var url = '';
    try {
      final decoded = jsonDecode(widget.message.content);
      if (decoded is Map) {
        name = decoded['name']?.toString() ?? name;
        url = resolveMediaUrl(baseUrl, decoded['url']?.toString() ?? '');
      }
    } catch (_) {
      // 内容非 JSON：只按文件占位展示。
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.file_text, size: 22),
            const SizedBox(width: GvSpacing.sm),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GvTypography.body(
                  AppColors.textPrimary.resolveFrom(context),
                ),
              ),
            ),
          ],
        ),
        if (url.isNotEmpty) ...[
          const SizedBox(height: GvSpacing.sm),
          OutlinedButton(
            onPressed: () => gvShowChatFileDownloadSheet(
              context,
              api: context.read<ImApi>(),
              fileName: name,
              fileUrl: url,
            ),
            child: Text(l10n.commonDownload),
          ),
        ],
      ],
    );
  }

  Widget _buildEmpty(BuildContext context, AppLocalizations l10n) {
    return Text(
      l10n.favoritesContentEmpty,
      style: GvTypography.body(AppColors.textHint.resolveFrom(context)),
    );
  }

  /// 次级入口「查看原消息」：样式弱化，命中失败时在下方常驻中文说明。
  Widget _buildSourceEntry(BuildContext context, AppLocalizations l10n) {
    final secondary = AppColors.textSecondary.resolveFrom(context);
    final hint = AppColors.textHint.resolveFrom(context);
    return Material(
      color: AppColors.bgWhite.resolveFrom(context),
      borderRadius: BorderRadius.circular(GvRadii.card),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(LucideIcons.link_2, size: 18, color: hint),
            title: Text(
              l10n.favoritesViewOriginal,
              style: GvTypography.body(secondary),
            ),
            trailing: _checkingSource
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CupertinoActivityIndicator(radius: 8),
                  )
                : Icon(LucideIcons.chevron_right, size: 18, color: hint),
            onTap: _checkingSource ? null : () => unawaited(_viewOriginal()),
          ),
          if (_sourceNote != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GvSpacing.page,
                0,
                GvSpacing.page,
                GvSpacing.page,
              ),
              child: Text(
                _sourceNote!,
                style: GvTypography.caption(secondary),
              ),
            ),
        ],
      ),
    );
  }

  /// 底部操作：转发 / 多选 / 删除。
  Widget _buildActionBar(BuildContext context, AppLocalizations l10n) {
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
                onPressed: _canForward ? _forward : null,
                child: Text(l10n.chatActionForward),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _enterMultiSelect,
                child: Text(l10n.chatMultiSelect),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => unawaited(_delete()),
                style: FilledButton.styleFrom(backgroundColor: danger),
                child: Text(l10n.commonDelete),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
