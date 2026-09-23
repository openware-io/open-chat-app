import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:open_core/open_core.dart';
import 'package:open_ui/open_ui.dart';
import 'package:provider/provider.dart';

import '../core/api_failure.dart';
import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_toast.dart';
import '../l10n/app_localizations.dart';
import '../models/shared_media_item.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../services/im_api.dart';
import '../widgets/open_avatar.dart';
import '../widgets/open_nav_bar.dart';
import '../widgets/open_search_bar.dart';
import 'chat_room/chat_room_media_helpers.dart';

/// 系统「分享」进 App 后，微信式「选择发送给朋友」：把分享的图片/视频/文件/文本转发到所选会话。
class ShareMediaScreen extends StatefulWidget {
  const ShareMediaScreen({super.key, required this.items});

  final List<SharedMediaItem> items;

  @override
  State<ShareMediaScreen> createState() => _ShareMediaScreenState();
}

class _ShareMediaScreenState extends State<ShareMediaScreen> {
  final _search = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().loadFriends();
      context.read<GroupProvider>().loadGroups();
    });
  }

  Future<void> _sendTo(String toId, String chatType) async {
    if (_sending) return;
    setState(() => _sending = true);
    final l10n = AppLocalizations.of(context)!;
    final api = context.read<ImApi>();
    final chat = context.read<ChatProvider>();
    try {
      for (final item in widget.items) {
        await _sendItem(item, api, chat, toId, chatType);
      }
      if (!mounted) return;
      GvToast.show(context, l10n.toastForwarded);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      GvToast.show(context, ApiFailure.messageOf(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendItem(
    SharedMediaItem item,
    ImApi api,
    ChatProvider chat,
    String toId,
    String chatType,
  ) async {
    final msgType = item.msgType;
    if (msgType == 'text') {
      final text = item.text ?? '';
      if (text.trim().isNotEmpty) {
        chat.sendMessage(toId, chatType, 'text', text, convPreview: text);
      }
      return;
    }

    final path = item.path;
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (!await file.exists()) return;

    var name = (item.displayName ?? '').trim();
    if (name.isEmpty) name = file.path.split(Platform.pathSeparator).last;
    if (name.isEmpty) name = 'shared';

    var uploadFile = file;
    int? videoDurationMs;
    if (msgType == 'video') {
      videoDurationMs = await gvReadVideoDurationMs(file);
      uploadFile = await gvPrepareChatVideoForUpload(file);
    }

    File imageBody = file;
    if (msgType == 'image') {
      imageBody = await gvPrepareChatImageForUpload(file);
    }

    (int, int)? imageDim;
    if (msgType == 'image') {
      imageDim = await gvDecodeImageSize(imageBody);
    }

    final uploaded = await api.uploadFile(
      msgType == 'video' ? uploadFile.path : imageBody.path,
      name,
      mediaKind: msgType == 'image'
          ? 'image'
          : msgType == 'video'
              ? 'video'
              : 'attachment',
      durationMs: msgType == 'video' ? videoDurationMs : null,
    );

    var content = uploaded.url;
    if (msgType == 'image') {
      content = encodeImageForChat(
        storedUrl: uploaded.url,
        caption: '',
        w: imageDim?.$1,
        h: imageDim?.$2,
      );
    } else if (msgType == 'file') {
      content = jsonEncode({'name': name, 'url': uploaded.url});
    }

    chat.sendMessage(
      toId,
      chatType,
      msgType,
      content,
      mediaObjectIds: [uploaded.objectId],
      wireContent: msgType == 'image' ? '' : name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friends = context.watch<FriendProvider>().friends;
    final groups = context.watch<GroupProvider>().groups;
    final myId = context.watch<ChatProvider>().myId;

    final friendPool =
        myId == null ? friends : friends.where((f) => f.friendId != myId).toList();
    final kw = _search.text.toLowerCase().trim();
    final filteredFriends = kw.isEmpty
        ? friendPool
        : friendPool.where((f) => f.displayName.toLowerCase().contains(kw)).toList();
    final filteredGroups = kw.isEmpty
        ? groups
        : groups.where((g) => g.name.toLowerCase().contains(kw)).toList();

    return Scaffold(
      backgroundColor: gvPageScaffoldBackground(context),
      appBar: GvNavBar(title: l10n.shareMediaTitle, showBack: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPreview(context),
          GvSearchBar(
            controller: _search,
            hint: l10n.channelShareSearchHint,
            onChanged: (_) => setState(() {}),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GvSpacing.page),
              child: ListView(
                padding: const EdgeInsets.only(top: GvSpacing.sm),
                children: [
                  if (filteredFriends.isNotEmpty) ...[
                    _sectionHeader(l10n.channelShareSectionFriends),
                    _card(filteredFriends.map((f) => _row(
                          icon: GvAvatar(
                            name: f.displayName,
                            uid: f.friendId,
                            src: f.friendUser?.avatar,
                            size: 40,
                          ),
                          title: f.displayName,
                          onTap: () => _sendTo('${f.friendId}', 'private'),
                        )).toList()),
                  ],
                  if (filteredGroups.isNotEmpty) ...[
                    _sectionHeader(l10n.channelShareSectionGroups),
                    _card(filteredGroups.map((g) => _row(
                          icon: GvAvatar(
                            name: g.name,
                            uid: g.id,
                            src: g.avatar,
                            size: 40,
                          ),
                          title: g.name,
                          onTap: () => _sendTo('${g.id}', 'group'),
                        )).toList()),
                  ],
                  if (filteredFriends.isEmpty && filteredGroups.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          l10n.channelShareEmpty,
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary.resolveFrom(context),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 96,
      margin: const EdgeInsets.fromLTRB(GvSpacing.page, 12, GvSpacing.page, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in items) ...[
              _previewTile(context, item),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewTile(BuildContext context, SharedMediaItem item) {
    final isImage = item.type == 'image' && item.path != null;
    return Container(
      width: 72,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.bgWhite.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: isImage
                  ? Image.file(File(item.path!), fit: BoxFit.cover)
                  : Icon(
                      switch (item.type) {
                        'video' => LucideIcons.video,
                        'text' => LucideIcons.type,
                        _ => LucideIcons.file,
                      },
                      size: 30,
                      color: AppColors.textSecondary.resolveFrom(context),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Text(
              item.type == 'text'
                  ? (item.text ?? '')
                  : (item.displayName ?? item.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title,
        style: GvTypography.caption(
          AppColors.textSecondary.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _card(List<Widget> rows) {
    return GvCardShell(
      borderRadius: BorderRadius.circular(GvRadii.input),
      child: Material(
        color: AppColors.bgWhite.resolveFrom(context),
        child: Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 0.5,
                  indent: 12,
                  color: AppColors.textHint
                      .resolveFrom(context)
                      .withValues(alpha: 0.22),
                ),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _row({
    required Widget icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _sending ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 40, height: 40, child: Center(child: icon)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17),
              ),
            ),
            Icon(
              LucideIcons.send,
              size: 16,
              color: AppColors.textHint.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }
}
