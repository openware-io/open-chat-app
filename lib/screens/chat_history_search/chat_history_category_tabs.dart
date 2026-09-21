import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:gv_ui/gv_ui.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../core/gv_http_headers.dart';
import '../../core/media_url.dart';
import '../../models/chat_message.dart';
import '../../widgets/gv_chat_video_thumbnail.dart';
import 'chat_history_flat_list.dart';
import 'chat_history_search_helpers.dart';

///「文件」分类：按月分组 + 列表行点击进会话。
class ChatHistoryFileCategoryTab extends StatelessWidget {
  const ChatHistoryFileCategoryTab({
    super.key,
    required this.messages,
    required this.groups,
    required this.senderLabel,
    required this.onOpenMessage,
    required this.listFooter,
  });

  final List<ChatMessage> messages;
  final Map<String, List<ChatMessage>> groups;
  final String Function(ChatMessage m) senderLabel;
  final void Function(ChatMessage m) onOpenMessage;
  final Widget listFooter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary.resolveFrom(context);
    if (messages.isEmpty) {
      return GvEmptyState(
        text: l10n.chatHistoryEmptyFiles,
        textStyle: GvTypography.caption(secondary),
      );
    }
    final flat = flattenHistoryGroupsForSearch(groups);
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: GvSpacing.page),
      itemCount: flat.length + 1,
      itemBuilder: (context, i) {
        if (i == flat.length) {
          return listFooter;
        }
        final row = flat[i];
        if (row is HistoryMonthHeader) {
          return GvSectionHeader(
            label: row.label,
            textStyle: GvTypography.caption(secondary),
          );
        }
        final m = (row as HistoryMessageRow).msg;
        final name = chatFileDisplayNameFromContent(
          m,
          unnamedLabel: l10n.chatHistoryFileUnnamed,
        );
        return GvActionRow(
          title: name,
          titleStyle: GvTypography.body(
            AppColors.textPrimary.resolveFrom(context),
          ),
          titleMaxLines: 2,
          subtitle: '${senderLabel(m)} · ${formatChatTime(m.timestamp)}',
          subtitleStyle: GvTypography.caption(secondary),
          leading: Icon(
            LucideIcons.file,
            size: 22,
            color: AppColors.primary.resolveFrom(context),
          ),
          onTap: () => onOpenMessage(m),
          padding: const EdgeInsets.symmetric(
            horizontal: GvSpacing.page,
            vertical: 12,
          ),
        );
      },
    );
  }
}

///「图片」分类：按月 + 四列网格，点击看图。
class ChatHistoryImageCategoryTab extends StatelessWidget {
  const ChatHistoryImageCategoryTab({
    super.key,
    required this.messages,
    required this.groups,
    required this.baseUrl,
    required this.authHdrs,
    required this.onTapImage,
    required this.listFooter,
  });

  final List<ChatMessage> messages;
  final Map<String, List<ChatMessage>> groups;
  final String baseUrl;
  final Map<String, String>? authHdrs;
  final void Function(String url) onTapImage;
  final Widget listFooter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary.resolveFrom(context);
    if (messages.isEmpty) {
      return GvEmptyState(
        text: l10n.chatHistoryEmptyImages,
        textStyle: GvTypography.caption(secondary),
      );
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(400),
      slivers: [
        for (final e in groups.entries)
          GvSliverMediaGridSection(
            header: e.key,
            headerStyle: GvTypography.caption(secondary),
            itemCount: e.value.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, i) {
              final m = e.value[i];
              final image = parseImageForChat(baseUrl, m.content);
              final u = image.imageUrl;
              return GvMediaGridTile(
                onTap: u.isEmpty ? null : () => onTapImage(u),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (u.isEmpty)
                      ColoredBox(
                        color: const Color(0xFFE8E8E8),
                        child: Icon(
                          LucideIcons.image_off,
                          color: secondary,
                          size: 24,
                        ),
                      )
                    else
                      CachedNetworkImage(
                        imageUrl: u,
                        httpHeaders: gvMediaRequestHeaders(u, authHdrs),
                        fit: BoxFit.cover,
                        memCacheWidth: (80 * dpr).round().clamp(80, 512),
                        placeholder: (_, __) => const ColoredBox(
                          color: Color(0xFFE8E8E8),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: const Color(0xFFE8E8E8),
                          child: Icon(
                            LucideIcons.image_off,
                            color: secondary,
                            size: 24,
                          ),
                        ),
                      ),
                    if (image.caption.isNotEmpty)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 3,
                          ),
                          color: Colors.black54,
                          child: Text(
                            image.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GvTypography.caption(Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        SliverToBoxAdapter(child: listFooter),
        const SliverToBoxAdapter(
          child: SizedBox(height: GvSpacing.page),
        ),
      ],
    );
  }
}

///「视频」分类：按月 + 两列缩略图网格。
class ChatHistoryVideoCategoryTab extends StatelessWidget {
  const ChatHistoryVideoCategoryTab({
    super.key,
    required this.messages,
    required this.groups,
    required this.baseUrl,
    required this.authHdrs,
    required this.onTapVideo,
    required this.listFooter,
  });

  final List<ChatMessage> messages;
  final Map<String, List<ChatMessage>> groups;
  final String baseUrl;
  final Map<String, String>? authHdrs;
  final void Function(String url, Map<String, String>? headers) onTapVideo;
  final Widget listFooter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final secondary = AppColors.textSecondary.resolveFrom(context);
    if (messages.isEmpty) {
      return GvEmptyState(
        text: l10n.chatHistoryEmptyVideos,
        textStyle: GvTypography.caption(secondary),
      );
    }
    return CustomScrollView(
      scrollCacheExtent: const ScrollCacheExtent.pixels(400),
      slivers: [
        for (final e in groups.entries)
          GvSliverMediaGridSection(
            header: e.key,
            headerStyle: GvTypography.caption(secondary),
            itemCount: e.value.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 16 / 10,
            ),
            itemBuilder: (context, i) {
              final m = e.value[i];
              final parsed = parseVideoForChat(baseUrl, m.content);
              final play = parsed.playUrl;
              final poster = parsed.posterResolved;
              final mediaHeaders = gvMediaRequestHeaders(play, authHdrs);
              return GvMediaGridTile(
                borderRadius: BorderRadius.circular(6),
                onTap: play.isEmpty
                    ? null
                    : () => onTapVideo(
                          stripChatMediaDisplayQueryParams(play),
                          mediaHeaders,
                        ),
                child: GvChatVideoThumbnail(
                  videoUrl: play,
                  posterUrl: poster,
                  httpHeaders: mediaHeaders,
                  width: 200,
                  height: 125,
                ),
              );
            },
          ),
        SliverToBoxAdapter(child: listFooter),
        const SliverToBoxAdapter(
          child: SizedBox(height: GvSpacing.page),
        ),
      ],
    );
  }
}
