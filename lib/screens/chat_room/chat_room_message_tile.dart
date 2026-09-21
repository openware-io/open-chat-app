import 'dart:convert';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/call_trace_display.dart';
import '../../core/gv_secondary_navigation.dart';
import '../../core/gv_http_headers.dart';
import '../../core/local_storage.dart';
import '../../core/media_url.dart';
import '../../core/message_preview.dart';
import '../../l10n/app_localizations.dart';
import '../../core/namecard_message.dart';
import '../../core/unicode_emoji_palette.dart';
import '../../models/chat_message.dart';
import '../../providers/chat_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/im_api.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypography, GvTypographyScale;
import '../../widgets/gv_avatar.dart';
import '../../widgets/gv_chat_quoted_message_preview.dart';
import '../../widgets/gv_chat_video_thumbnail.dart';
import '../../widgets/gv_image_viewer.dart';
import '../../widgets/gv_video_viewer.dart';
import '../../widgets/gv_voice_message_player.dart';
import 'chat_room_constants.dart';
import 'chat_room_media_helpers.dart';
import 'chat_room_sender_display.dart';

/// 单条聊天消息在列表中的完整一行（头像 + 气泡 + 发送中与引用副文案）。
class ChatRoomMessageTile extends StatelessWidget {
  /// 构建一条消息行；长按 / 桌面端右键通过 [onLongPressAt] 交给外层弹出菜单。
  const ChatRoomMessageTile({
    super.key,
    required this.msg,
    required this.myId,
    required this.chat,
    required this.sessionPeerId,
    required this.sessionChatType,
    required this.baseUrl,
    required this.onLongPressAt,
    this.onAvatarLongPressAt,
    this.anchorHighlight = false,
  });

  static const double _bubbleRadius = 9;
  static const double _imageClipRadius = 6;
  static const double _kRowAvatarSize = 36;
  static const double _kRowAvatarGap = 8;

  final ChatMessage msg;
  final int myId;
  final ChatProvider chat;
  final String sessionPeerId;
  final String sessionChatType;
  final String baseUrl;
  final void Function(Offset globalPosition) onLongPressAt;

  /// 长按**对方**头像：在输入框插入纯文本 `@展示名 `（见 [GvChatRoomBottomState.insertAtMention]）。
  final void Function(int userId, String displayLabel)? onAvatarLongPressAt;

  final bool anchorHighlight;

  /// 对方：左下角为「尖角」保持 [_bubbleRadius] 的一半；其余三角放大 1/3（×4/3）。
  /// 自己：右下角为尖角；其余三角放大 1/3。
  static BorderRadius _bubbleBorderRadius(bool self) {
    const r = _bubbleRadius;
    const tight = r * 0.5;
    const loose = r * (4.0 / 3.0);
    if (self) {
      return const BorderRadius.only(
        topLeft: Radius.circular(loose),
        topRight: Radius.circular(loose),
        bottomLeft: Radius.circular(loose),
        bottomRight: Radius.circular(tight),
      );
    }
    return const BorderRadius.only(
      topLeft: Radius.circular(loose),
      topRight: Radius.circular(loose),
      bottomLeft: Radius.circular(tight),
      bottomRight: Radius.circular(loose),
    );
  }

  /// 撤回提示：按原消息类型区分「撤回一条消息/一张图片/一个视频/一条语音/一个文件」。
  String _recallDisplayText(AppLocalizations l10n) {
    final self = msg.from == myId;
    return switch (msg.content) {
      'image' => self ? '你撤回了一张图片' : '对方撤回了一张图片',
      'video' => self ? '你撤回了一个视频' : '对方撤回了一个视频',
      'voice' => self ? '你撤回了一条语音' : '对方撤回了一条语音',
      'file' => self ? '你撤回了一个文件' : '对方撤回了一个文件',
      _ => self ? l10n.chatMessageRecalledSelf : l10n.chatMessageRecalledPeer,
    };
  }

  /// 系统/撤回：居中灰色小字；其余类型走气泡分支。
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (msg.msgType == 'system' || msg.msgType == 'recall') {
      final displayText =
          msg.msgType == 'recall' ? _recallDisplayText(l10n) : msg.content;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.5),
        child: Center(
            child: Text(displayText,
                style: const TextStyle(
                    fontSize: GvTypographyScale.small,
                    color: AppColors.textSecondary))),
      );
    }

    final friend = context.watch<FriendProvider>();
    final group = context.watch<GroupProvider>();
    final storage = context.read<LocalStorage>();
    final authHdrs = gvBearerHeaders(storage) ?? const <String, String>{};

    final self = msg.from == myId;
    // 是否被 @ 到「我」：仅他人消息且 atUsers 含当前 userId（字段可能为 int 或 string）。
    final atMe =
        !self && (msg.atUsers?.any((e) => e.toString() == '$myId') ?? false);
    // 匿名/群级隐私：私密群聊「匿名发言」开启，或普通群「禁止互加好友」开启时，
    // 他人消息发送者身份（名称/头像）对成员隐藏。
    final anonymous = (sessionChatType == 'secret_group' &&
            (chat.cachedSecretGroupChat(sessionPeerId)?.anonymousEnabled ??
                false)) ||
        (sessionChatType == 'group' &&
            !group
                .memberFriendRequestAllowed(int.tryParse(sessionPeerId) ?? 0));
    final sourceGroupId =
        sessionChatType == 'group' ? int.tryParse(sessionPeerId) : null;
    final hideAccountDetails = sourceGroupId != null &&
        !group.canViewOtherMemberAccounts(sourceGroupId, myId);
    final hideFriendRequest = sourceGroupId != null &&
        !group.canSendMemberFriendRequest(sourceGroupId, myId);
    // [CupertinoDynamicColor] 必须 [resolveFrom]，否则 [BoxDecoration] 用的是未解析色值，明暗色不生效。
    final bubbleColor = (self ? AppColors.bubbleSelf : AppColors.bubbleOther)
        .resolveFrom(context);

    final maxBubbleW = (MediaQuery.sizeOf(context).width -
            2 * GvSpacing.sm -
            2 * _kRowAvatarSize -
            2 * _kRowAvatarGap)
        .clamp(120.0, 1e6);

    final inner = _buildBubbleInner(context, self, maxBubbleW, authHdrs);

    final isEmoji = msg.msgType == 'emoji';
    final isImage = msg.msgType == 'image';
    final isVideo = msg.msgType == 'video';
    final isFile = msg.msgType == 'file';
    final isNamecard = msg.msgType == 'namecard';

    /// 图片/视频/表情包：无外层彩色气泡；文件/名片：无外层彩色气泡，内层白底卡片。
    final noBubbleBg = isEmoji || isImage || isVideo || isFile || isNamecard;

    final quoted = msg.replyMsgId != null
        ? chat.findMessageInSession(
            sessionPeerId, sessionChatType, msg.replyMsgId)
        : null;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            self ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!self) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => gvPushContactDetail(
                  context,
                  '${msg.from}',
                  fromGroup: sourceGroupId != null,
                  sourceGroupId: sourceGroupId,
                  hideAccountDetails: hideAccountDetails,
                  hideFriendRequest: hideFriendRequest,
                ),
                onLongPress: onAvatarLongPressAt == null
                    ? null
                    : () {
                        final name = messageTileSenderName(
                          msg,
                          myId,
                          chat,
                          friend,
                          group,
                          sessionChatType,
                          l10n,
                          anonymousEnabled: anonymous,
                        );
                        onAvatarLongPressAt!(msg.from, name);
                      },
                customBorder: const CircleBorder(),
                child: GvAvatar(
                  name: messageTileSenderName(
                    msg,
                    myId,
                    chat,
                    friend,
                    group,
                    sessionChatType,
                    l10n,
                    anonymousEnabled: anonymous,
                  ),
                  uid: msg.from,
                  src: messageTileSenderAvatar(
                      msg, myId, chat, friend, group, storage, sessionChatType,
                      anonymousEnabled: anonymous),
                  size: _kRowAvatarSize,
                ),
              ),
            ),
            const SizedBox(width: _kRowAvatarGap),
          ],
          Flexible(
            child: Align(
              alignment: self ? Alignment.centerRight : Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubbleW),
                child: Builder(
                  builder: (bubbleCtx) => Listener(
                    onPointerDown: (PointerDownEvent e) {
                      if (e.kind == PointerDeviceKind.mouse &&
                          e.buttons == kSecondaryMouseButton) {
                        final box = bubbleCtx.findRenderObject() as RenderBox?;
                        final pos = box?.localToGlobal(e.localPosition) ??
                            e.localPosition;
                        onLongPressAt(pos);
                      }
                    },
                    child: GestureDetector(
                      onLongPressStart: (d) => onLongPressAt(d.globalPosition),
                      child: Column(
                        crossAxisAlignment: self
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!self &&
                              (sessionChatType == 'group' ||
                                  sessionChatType == 'secret_group'))
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 3, left: 2),
                              child: Text(
                                messageTileSenderName(
                                  msg,
                                  myId,
                                  chat,
                                  friend,
                                  group,
                                  sessionChatType,
                                  l10n,
                                  anonymousEnabled: anonymous,
                                ),
                                style: GvTypography.small(
                                  AppColors.textSecondary,
                                ),
                              ),
                            ),
                          if (atMe)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 3, left: 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.resolveFrom(context),
                                  borderRadius:
                                      BorderRadius.circular(GvRadii.compact),
                                ),
                                child: Text(
                                  l10n.chatAtMentionYou,
                                  style:
                                      GvTypography.small(CupertinoColors.white),
                                ),
                              ),
                            ),
                          Container(
                            padding: (isImage || isVideo)
                                ? EdgeInsets.zero
                                : EdgeInsets.symmetric(
                                    horizontal: (isFile || isNamecard) ? 6 : 12,
                                    vertical: (isFile || isNamecard) ? 6 : 10,
                                  ),
                            decoration: noBubbleBg
                                ? null
                                : BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: _bubbleBorderRadius(self),
                                    border: atMe
                                        ? Border.all(
                                            color: AppColors.primary
                                                .resolveFrom(context),
                                            width: 1.4,
                                          )
                                        : null,
                                  ),
                            child: (isImage || isVideo)
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(_imageClipRadius),
                                    child: inner,
                                  )
                                : inner,
                          ),
                          if (msg.status == 'sending')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(l10n.chatSending,
                                  style: GvTypography.small(AppColors.textHint
                                      .withValues(alpha: 0.8))),
                            ),
                          if (msg.edited)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(l10n.gvMbEdited,
                                  style: GvTypography.small(AppColors.textHint
                                      .withValues(alpha: 0.8))),
                            ),
                          if (quoted != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: GvChatQuotedMessagePreview(
                                message: quoted,
                                baseUrl: baseUrl,
                                appHttpHeaders: authHdrs,
                                onMediaTap: () =>
                                    _openQuotedMedia(context, quoted, authHdrs),
                                prefix:
                                    '${messageTileSenderName(quoted, myId, chat, friend, group, sessionChatType, l10n, anonymousEnabled: anonymous)}：',
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (self) ...[
            const SizedBox(width: _kRowAvatarGap),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => gvPushContactDetail(
                  context,
                  '${msg.from}',
                  fromGroup: sourceGroupId != null,
                  sourceGroupId: sourceGroupId,
                  hideAccountDetails: hideAccountDetails,
                  hideFriendRequest: hideFriendRequest,
                ),
                customBorder: const CircleBorder(),
                child: GvAvatar(
                  name: l10n.chatReplySelfShort,
                  uid: myId,
                  src: messageTileSenderAvatar(
                      msg, myId, chat, friend, group, storage, sessionChatType,
                      anonymousEnabled: anonymous),
                  size: _kRowAvatarSize,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: anchorHighlight
            ? AppColors.primary.resolveFrom(context).withValues(alpha: 0.11)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: row,
    );
  }

  /// 与本类 [_buildBubbleInner] 对齐：占位内容见 [gvChatPendingMediaUploadContent]。
  bool _mediaSendingNeedsPlaceholder(ChatMessage msg) =>
      msg.status == 'sending' && msg.content == gvChatPendingMediaUploadContent;

  /// 按 [msg.msgType] 构建气泡内部主体（文本 / 媒体 / 文件卡片等）。
  Widget _buildBubbleInner(
    BuildContext context,
    bool self,
    double maxBubbleW,
    Map<String, String> authHdrs,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final fg = self
        ? AppColors.bubbleSelfText
        : AppColors.bubbleOtherText.resolveFrom(context);
    switch (msg.msgType) {
      case 'text':
        return Text.rich(
          gvChatBubbleBodyRich(
            msg.content.replaceAllMapped(
              RegExp(r'\[emoji\](\d+)\[/emoji\]'),
              (_) => l10n.chatHistoryEmojiPlaceholder,
            ),
            fg,
          ),
          strutStyle: gvChatBubbleStrutIosOnly(
            fontSize: GvTypographyScale.chatBody,
            height: 1.25,
          ),
        );
      case 'emoji':
        final stickerUrl = resolveMediaUrl(baseUrl, msg.content);
        return GestureDetector(
          onTap: stickerUrl.isEmpty
              ? null
              : () => showGvImageViewer(context,
                  imageUrl: stickerUrl, api: context.read<ImApi>()),
          behavior: HitTestBehavior.opaque,
          child: CachedNetworkImage(
            imageUrl: stickerUrl,
            httpHeaders: gvMediaRequestHeaders(stickerUrl, authHdrs),
            width: 120,
            height: 120,
            fit: BoxFit.contain,
            placeholder: (_, __) => const SizedBox(
              width: 120,
              height: 120,
              child: Center(child: CupertinoActivityIndicator()),
            ),
            errorWidget: (_, __, ___) => SizedBox(
              width: 120,
              height: 120,
              child:
                  Icon(Icons.broken_image, color: fg.withValues(alpha: 0.45)),
            ),
          ),
        );
      case 'image':
        if (_mediaSendingNeedsPlaceholder(msg)) {
          final sz = gvChatBubbleMediaDisplaySize(
            context,
            maxBubbleW,
            null,
            null,
            missingAspect: 0.75,
          );
          final dw = sz.dw;
          final dh = sz.dh;
          return SizedBox(
            width: dw,
            height: dh,
            child: ColoredBox(
              color: AppColors.bgChat.resolveFrom(context),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }
        final image = parseImageForChat(baseUrl, msg.content);
        final u = image.imageUrl;
        final iw0 = image.w;
        final ih0 = image.h;
        final sz = gvChatBubbleMediaDisplaySize(context, maxBubbleW, iw0, ih0);
        final dw = sz.dw;
        final dh = sz.dh;
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final imageView = GestureDetector(
          onTap: u.isEmpty
              ? null
              : () => showGvImageViewer(
                    context,
                    imageUrl: u,
                    api: context.read<ImApi>(),
                  ),
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_imageClipRadius),
            child: CachedNetworkImage(
              imageUrl: u,
              httpHeaders: gvMediaRequestHeaders(u, authHdrs),
              width: dw,
              height: dh,
              fit: BoxFit.cover,
              memCacheWidth: (dw * dpr).round().clamp(120, 2048),
              placeholder: (_, __) => SizedBox(
                width: dw,
                height: dh,
                child: ColoredBox(
                  color: AppColors.bgChat.resolveFrom(context),
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
              errorWidget: (_, __, ___) => SizedBox(
                width: dw,
                height: dh,
                child:
                    Icon(Icons.broken_image, color: fg.withValues(alpha: 0.45)),
              ),
            ),
          ),
        );
        if (image.caption.isEmpty) return imageView;
        final captionBg = (self ? AppColors.bubbleSelf : AppColors.bubbleOther)
            .resolveFrom(context);
        return Container(
          width: dw,
          color: captionBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              imageView,
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Text(
                  image.caption,
                  style: gvChatBubbleBodyTextStyle(
                    fg,
                    fontSize: GvTypographyScale.bodySmall,
                  ),
                ),
              ),
            ],
          ),
        );
      case 'video':
        if (_mediaSendingNeedsPlaceholder(msg)) {
          final sz = gvChatBubbleMediaDisplaySize(
            context,
            maxBubbleW,
            null,
            null,
            missingAspect: 9 / 16,
          );
          final dw = sz.dw;
          final dh = sz.dh;
          return SizedBox(
            width: dw,
            height: dh,
            child: ColoredBox(
              color: AppColors.bgChat.resolveFrom(context),
              child: const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }
        final v = parseVideoForChat(baseUrl, msg.content);
        final iw0 = v.w;
        final ih0 = v.h;
        final sz = gvChatBubbleMediaDisplaySize(
          context,
          maxBubbleW,
          iw0,
          ih0,
          missingAspect: 9 / 16,
        );
        final dw = sz.dw;
        final dh = sz.dh;
        final mediaHeaders = gvMediaRequestHeaders(v.playUrl, authHdrs);
        return GestureDetector(
          onTap: v.playUrl.isEmpty
              ? null
              : () => showGvVideoViewer(
                    context,
                    videoUrl: v.playUrl,
                    api: context.read<ImApi>(),
                    httpHeaders: mediaHeaders,
                  ),
          behavior: HitTestBehavior.opaque,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_imageClipRadius),
            child: GvChatVideoThumbnail(
              videoUrl: v.playUrl,
              posterUrl: v.posterResolved,
              httpHeaders: mediaHeaders,
              width: dw,
              height: dh,
            ),
          ),
        );
      case 'file':
        return _buildFileBubble(context, baseUrl);
      case 'voice':
        if (_mediaSendingNeedsPlaceholder(msg)) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fg,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.chatVoiceMessage,
                  style: TextStyle(color: fg.withValues(alpha: 0.92)),
                ),
              ),
            ],
          );
        }
        final voiceUrl = resolveMediaUrl(baseUrl, msg.content);
        return voiceUrl.isEmpty
            ? Text(l10n.chatVoiceMessage, style: TextStyle(color: fg))
            : GvVoiceMessagePlayer(
                url: voiceUrl,
                fromSelf: self,
                color: fg,
                imApi: context.read<ImApi>(),
              );
      case 'call':
        final display = parseCallTraceDisplay(l10n, msg.content);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              display.isVideo
                  ? Icons.videocam_outlined
                  : Icons.phone_in_talk_outlined,
              color: fg,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              display.line,
              style: gvChatBubbleBodyTextStyle(
                fg,
                fontSize: GvTypographyScale.chatBody,
              ),
            ),
          ],
        );
      case 'namecard':
        return _buildNamecardBubble(context, maxBubbleW);
      default:
        return Text.rich(
          gvChatBubbleBodyRich(msg.content, fg),
          strutStyle: gvChatBubbleStrutIosOnly(
            fontSize: GvTypographyScale.chatBody,
            height: 1.25,
          ),
        );
    }
  }

  void _openQuotedMedia(
    BuildContext context,
    ChatMessage quoted,
    Map<String, String> authHeaders,
  ) {
    if (quoted.msgType == 'image') {
      final image = parseImageForChat(baseUrl, quoted.content);
      if (image.imageUrl.isNotEmpty) {
        showGvImageViewer(
          context,
          imageUrl: image.imageUrl,
          api: context.read<ImApi>(),
        );
      }
      return;
    }
    if (quoted.msgType == 'video') {
      final video = parseVideoForChat(baseUrl, quoted.content);
      if (video.playUrl.isNotEmpty) {
        showGvVideoViewer(
          context,
          videoUrl: video.playUrl,
          api: context.read<ImApi>(),
          httpHeaders: gvMediaRequestHeaders(video.playUrl, authHeaders),
        );
      }
    }
  }

  /// 文件类型：白底卡片 + 下载入口。
  Widget _buildFileBubble(BuildContext context, String baseUrl) {
    final l10n = AppLocalizations.of(context)!;
    Map<String, dynamic>? p;
    try {
      p = jsonDecode(msg.content) as Map<String, dynamic>?;
    } catch (_) {}
    final name = p?['name'] as String? ?? l10n.chatHistoryFileUnnamed;
    final url =
        p?['url'] != null ? resolveMediaUrl(baseUrl, p!['url'] as String) : '';
    final chipFg = AppColors.textPrimary.resolveFrom(context);
    final chipSub = AppColors.textSecondary.resolveFrom(context);
    final fileCardBg = AppColors.bgWhite.resolveFrom(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(GvRadii.compact),
        onTap: url.isNotEmpty
            ? () => gvShowChatFileDownloadSheet(
                  context,
                  api: context.read<ImApi>(),
                  fileName: name,
                  fileUrl: url,
                )
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: fileCardBg,
            borderRadius: BorderRadius.circular(GvRadii.compact),
            boxShadow: GvShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(LucideIcons.file_text,
                  color: kChatFileIconOrange, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: chipFg,
                        fontSize: GvTypographyScale.bodySmall,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.chatTapToDownload,
                      style: TextStyle(
                        color: chipSub,
                        fontSize: GvTypographyScale.small,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 名片类型：头像 + 昵称 +「个人名片」说明。
  Widget _buildNamecardBubble(BuildContext context, double maxBubbleW) {
    final l10n = AppLocalizations.of(context)!;
    final p = NamecardPayload.tryParse(msg.content);
    final chipFg = AppColors.textPrimary.resolveFrom(context);
    final chipSub = AppColors.textSecondary.resolveFrom(context);
    final fileCardBg = AppColors.bgWhite.resolveFrom(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(GvRadii.compact),
        onTap: p != null ? () => context.push('/contacts/${p.userId}') : null,
        child: Container(
          width: math.min(maxBubbleW, 260),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: fileCardBg,
            borderRadius: BorderRadius.circular(GvRadii.compact),
            boxShadow: GvShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GvAvatar(
                name: p?.displayName ?? ' ',
                uid: p?.userId ?? 0,
                src: p?.avatar,
                size: 48,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p?.displayName ?? l10n.chatNameCard,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: chipFg,
                        fontSize: GvTypographyScale.body,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.chatPersonalNameCard,
                      style: TextStyle(
                        color: chipSub,
                        fontSize: GvTypographyScale.caption,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
