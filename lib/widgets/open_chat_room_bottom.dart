import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../core/config.dart';
import '../core/open_automation_keys.dart';
import '../core/open_http_headers.dart';
import '../core/media_url.dart';
import '../l10n/app_localizations.dart';
import '../core/unicode_emoji_palette.dart';
import '../core/web_clipboard_image_listener.dart';
import '../models/chat_message.dart';
import '../services/chat_media_clipboard_service.dart';
import '../services/im_api.dart';
import '../core/local_storage.dart';
import 'package:open_ui/open_ui.dart' show GvTypography;
import 'open_chat_bottom_composer.dart';
import 'open_chat_composer_editing_controller.dart';
import 'open_chat_quoted_message_preview.dart';
import 'open_image_viewer.dart';
import 'open_sticker_pack_panel.dart';
import 'open_video_viewer.dart';

const double _kComposerBarIconSize = 26;
const double _kComposerIconSlot = 30;

Widget _gvComposerTapIcon({
  required VoidCallback onTap,
  required Color color,
  required IconData icon,
  double size = _kComposerBarIconSize,
  EdgeInsetsGeometry padding =
      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  String? semanticsLabel,
}) {
  return Semantics(
    button: true,
    label: semanticsLabel,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: padding,
        child: SizedBox(
          width: _kComposerIconSlot,
          height: _kComposerIconSlot,
          child: Center(
            child: Icon(icon, size: size, color: color),
          ),
        ),
      ),
    ),
  );
}

/// 聊天室底部：输入栏 + 表情 / 「更多」面板（内部使用 [GvChatBottomComposer]）。
///
/// 通过 [GlobalKey<GvChatRoomBottomState>] 调用 [GvChatRoomBottomState.dismissPanelsAndKeyboard]、
/// [GvChatRoomBottomState.stickerPanelKey] 等，与消息列表点击收起键盘配合。
class GvChatRoomBottom extends StatefulWidget {
  const GvChatRoomBottom({
    super.key,
    required this.myId,
    required this.replyTo,
    required this.onDismissReply,
    required this.voiceMode,
    required this.recording,
    required this.onToggleVoiceMode,
    required this.voiceHoldAreaKey,
    required this.onVoicePointerDown,
    required this.onVoicePointerMove,
    required this.onVoicePointerUp,
    required this.onVoicePointerCancel,
    required this.onTyping,
    required this.ensureChatAllowed,
    required this.onSendText,
    this.attachmentBanner,
    this.attachmentFocusNode,
    this.onSendPendingAttachment,
    this.pendingAttachmentSending = false,
    required this.onComposerFocusGained,
    required this.onSendSticker,
    required this.onAddCustomSticker,
    required this.onPickImage,
    this.onTakePhoto,
    required this.onPickVideo,
    required this.onRecordVideo,
    required this.onPickFile,
    this.onPasteImage,
    this.onPasteVideo,
    required this.onStartPrivateCall,
    required this.isPrivateChat,
    required this.voiceCallEnabled,
    required this.videoCallEnabled,
    this.onAtMention,
    this.onBottomChromeExpanded,

    /// 进入会话时恢复的未发送草稿；为空则输入框为空。
    this.initialDraftText,

    /// 输入框文本变化时的草稿保存回调（已由本组件做 300ms 防抖）。
    this.onDraftChanged,

    /// 只读态（如频道订阅者）：由 [GvChatBottomComposer] 渲染提示条，不展示输入/发送。
    this.readOnly = false,
    this.readOnlyHint,

    /// 群聊成员候选（userId + 展示名），用于草稿恢复时从文本重建真@集合。
    this.atMentionCandidates = const [],
  });

  final int myId;
  final ChatMessage? replyTo;
  final VoidCallback onDismissReply;

  final bool voiceMode;
  final bool recording;
  final VoidCallback onToggleVoiceMode;

  final GlobalKey voiceHoldAreaKey;
  final void Function(PointerDownEvent event) onVoicePointerDown;
  final void Function(PointerMoveEvent event) onVoicePointerMove;
  final void Function(PointerEvent event) onVoicePointerUp;
  final void Function(PointerEvent event) onVoicePointerCancel;

  final VoidCallback onTyping;

  /// 发送前校验（如远程开关）；返回 false 则不发。
  final bool Function() ensureChatAllowed;

  /// 发送成功后本组件会清空输入框；无展开面板时会 [maintainComposerFocusAfterSend] 保持键盘。
  /// [atUsers] 为本次输入中通过 @ 选择器加入的 userId 集合（仅 group/secret_group 会非空）。
  final void Function(
    String trimmedText,
    String? replyMsgId,
    List<dynamic>? atUsers,
  ) onSendText;

  /// Inline pending-media editor displayed above the normal text composer.
  final Widget? attachmentBanner;

  /// Focus owned by the pending-media caption field, if one is visible.
  final FocusNode? attachmentFocusNode;

  /// Sends the pending media and its caption as one message.
  final Future<void> Function()? onSendPendingAttachment;

  final bool pendingAttachmentSending;

  /// 输入框获得焦点时（用于列表跟到底等）；由外层决定是否忽略「刚发送」等。
  final VoidCallback onComposerFocusGained;

  /// 本组件会先关面板再调用。
  final void Function(String stickerUrl) onSendSticker;

  final Future<void> Function() onAddCustomSticker;

  final Future<void> Function() onPickImage;
  final Future<void> Function()? onTakePhoto;
  final Future<void> Function() onPickVideo;
  final Future<void> Function() onRecordVideo;
  final Future<void> Function() onPickFile;

  /// 桌面端剪贴板图片已读取后的发送回调；为空时保留系统原生粘贴行为。
  final Future<void> Function(Uint8List imageBytes)? onPasteImage;

  /// 桌面端剪贴板视频文件已读取后的发送回调。
  final Future<void> Function(String videoPath)? onPasteVideo;

  /// [type] 为 `audio` 或 `video`；仅私聊且开关开启时由面板展示入口。
  final void Function(String type) onStartPrivateCall;

  final bool isPrivateChat;
  final bool voiceCallEnabled;
  final bool videoCallEnabled;

  /// 群聊「@」入口回调（打开成员选择器）；为空时不展示 @ 入口。
  final VoidCallback? onAtMention;

  final VoidCallback? onBottomChromeExpanded;

  /// 进入会话时恢复的未发送草稿；为空则输入框为空。
  final String? initialDraftText;

  /// 输入框文本变化时的草稿保存回调（已由本组件做 300ms 防抖）。
  final void Function(String text)? onDraftChanged;

  /// 只读态：隐藏输入/语音/表情/发送，仅展示提示条。
  final bool readOnly;

  /// 只读态提示文案（如「仅管理员可发布」）。
  final String? readOnlyHint;

  /// 群聊成员候选（userId + 展示名），用于草稿恢复时从文本重建真@集合。
  final List<({int userId, String label, String? avatar})> atMentionCandidates;

  @override
  State<GvChatRoomBottom> createState() => GvChatRoomBottomState();
}

class GvChatRoomBottomState extends State<GvChatRoomBottom> {
  static const bool _showCallActions = true;

  final GvChatMediaClipboardService _mediaClipboard =
      const GvChatMediaClipboardService();

  final TextEditingController _text = GvChatComposerEditingController();
  late final FocusNode _textFieldFocus;
  late final WebClipboardImageListenerDisposer
      _disposeWebClipboardImageListener;

  final GlobalKey<GvChatBottomComposerState> _composerKey =
      GlobalKey<GvChatBottomComposerState>();
  final GlobalKey<GvStickerPackPanelState> _stickerPanelKey =
      GlobalKey<GvStickerPackPanelState>();
  final GlobalKey _composerInputBarKey =
      GlobalKey(debugLabel: 'composer_input_bar');

  GlobalKey<GvStickerPackPanelState> get stickerPanelKey => _stickerPanelKey;

  /// 上一次输入框文本，用于检测「刚输入 @」触发成员选择器。
  String _lastComposerText = '';

  /// 本次输入中已通过 @ 选择器加入的 userId 集合（真@），发送时作为 [atUsers] 上报。
  final Set<int> _pendingAtUserIds = <int>{};

  /// 真@集合中 userId 对应的插入展示名（规整后），用于文本变化时对账、草稿恢复时重建。
  final Map<int, String> _pendingAtLabels = <int, String>{};

  /// 草稿保存防抖定时器（300ms）。
  Timer? _draftDebounce;

  /// 点击列表空白等：若面板开或键盘在，应消费并收起。
  bool get absorbBackgroundPointer {
    final c = _composerKey.currentState;
    return (c?.hasVisiblePanel ?? false) ||
        _textFieldFocus.hasFocus ||
        (widget.attachmentFocusNode?.hasFocus ?? false);
  }

  void dismissPanelsAndKeyboard() {
    final c = _composerKey.currentState;
    final panelOpen = c?.hasVisiblePanel ?? false;
    final attachmentHasFocus = widget.attachmentFocusNode?.hasFocus ?? false;
    if (!panelOpen && !_textFieldFocus.hasFocus && !attachmentHasFocus) return;
    _textFieldFocus.unfocus();
    widget.attachmentFocusNode?.unfocus();
    c?.closePanel();
  }

  void closeComposerPanel() => _composerKey.currentState?.closePanel();

  /// 把展示名规整为插入到输入框的提及文本，保证「插入」与「对账/重建」用同一口径。
  static String _sanitizeMentionLabel(String raw) =>
      raw.trim().replaceAll(RegExp(r'[\r\n]+'), ' ');

  /// 在光标处插入纯文本 `@展示名 `，并把 userId 记入本次输入的真@集合。
  void insertAtMention(int userId, String displayLabel) {
    if (!mounted) return;
    var label = _sanitizeMentionLabel(displayLabel);
    if (label.isEmpty) {
      if (userId <= 0) return;
      label = '用户$userId';
    }
    // userId == 0 表示「@所有人」（服务端 atUsers 使用 "0" 标记），同样记入真@集合。
    if (userId >= 0) {
      _pendingAtUserIds.add(userId);
      _pendingAtLabels[userId] = label;
    }
    final insert = '@$label ';
    final v = _text.value;
    final t = v.text;
    final s = v.selection;
    var start = s.isValid ? s.start.clamp(0, t.length) : t.length;
    final end = s.isValid ? s.end.clamp(0, t.length) : t.length;
    // 若光标前正是「输入 @ 触发选择器」留下的裸 @，则消费掉它，避免出现「@@名字」。
    if (start == end && start > 0 && t.codeUnitAt(start - 1) == 0x40) {
      start -= 1;
    }
    final newText = t.replaceRange(start, end, insert);
    final newOffset = (start + insert.length).clamp(0, newText.length);
    _text.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    setState(() {});
    widget.onTyping();
    _textFieldFocus.requestFocus();
    _composerKey.currentState?.closePanel();
  }

  /// 文本变化后对账真@集合：文本里已不含 `@展示名` 的 userId 从集合移除，避免虚假@通知。
  void _reconcilePendingAtUserIds(String text) {
    if (_pendingAtUserIds.isEmpty) return;
    final stale = <int>[];
    for (final userId in _pendingAtUserIds) {
      final label = _pendingAtLabels[userId];
      if (label == null || label.isEmpty || !text.contains('@$label')) {
        stale.add(userId);
      }
    }
    for (final userId in stale) {
      _pendingAtUserIds.remove(userId);
      _pendingAtLabels.remove(userId);
    }
  }

  /// 从恢复的草稿文本重建真@集合：文本中仍含 `@展示名` 的成员视为本次输入的真@。
  ///
  /// 边界：依赖 [GvChatRoomBottom.atMentionCandidates] 提供成员映射；若进入会话时
  /// 成员尚未加载完成（候选为空），则本批次无法重建，等待下一次插入 @ 时再补记。
  void _rebuildPendingAtUserIdsFromDraft(String draft) {
    _pendingAtUserIds.clear();
    _pendingAtLabels.clear();
    for (final c in widget.atMentionCandidates) {
      if (c.userId <= 0) continue;
      final label = _sanitizeMentionLabel(c.label);
      if (label.isEmpty) continue;
      if (draft.contains('@$label')) {
        _pendingAtUserIds.add(c.userId);
        _pendingAtLabels[c.userId] = label;
      }
    }
  }

  /// 检测用户在输入框新敲入 `@` 并触发成员选择器（参考微信：输入 @ 即弹出选人）。
  void _onComposerTextChanged() {
    final newText = _text.text;
    final prev = _lastComposerText;
    _lastComposerText = newText;
    _reconcilePendingAtUserIds(newText);
    _scheduleDraftSave();
    if (widget.onAtMention == null) return;
    // 仅在「恰好新增一个字符」时判定，避免删除/粘贴/插入 @名字 时误触发。
    if (newText.length != prev.length + 1) return;
    int i = 0;
    while (i < prev.length &&
        i < newText.length &&
        prev.codeUnitAt(i) == newText.codeUnitAt(i)) {
      i++;
    }
    if (i >= newText.length) return;
    if (newText.codeUnitAt(i) != 0x40) return; // '@'
    if (newText.substring(i + 1) != prev.substring(i)) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onAtMention!();
    });
  }

  /// 300ms 防抖后把当前输入框文本交给 [GvChatRoomBottom.onDraftChanged] 落库。
  void _scheduleDraftSave() {
    final handler = widget.onDraftChanged;
    if (handler == null) return;
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(milliseconds: 300), () {
      _draftDebounce = null;
      if (mounted) handler(_text.text);
    });
  }

  /// 立即落库当前草稿（离开会话时兜底，避免防抖未触发丢草稿）。
  void flushDraft() {
    _draftDebounce?.cancel();
    _draftDebounce = null;
    widget.onDraftChanged?.call(_text.text);
  }

  void maintainComposerFocusAfterSend() {
    // 仅在确已失焦时再要回焦点；避免与 [EditableText] / IME 同步抢焦点造成闪动。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_textFieldFocus.hasFocus || !_textFieldFocus.canRequestFocus) {
        return;
      }
      _textFieldFocus.requestFocus();
    });
  }

  @override
  void initState() {
    super.initState();
    _text.addListener(_onComposerTextChanged);
    final draft = widget.initialDraftText;
    if (draft != null && draft.isNotEmpty) {
      _text.text = draft;
      _lastComposerText = draft;
      _rebuildPendingAtUserIdsFromDraft(draft);
    }
    _textFieldFocus = FocusNode(onKeyEvent: _onTextFieldKeyEvent);
    _textFieldFocus.addListener(_onTextFieldFocusChange);
    _disposeWebClipboardImageListener = listenForWebClipboardImages(
      isEnabled: () => mounted && _textFieldFocus.hasFocus,
      onImage: (bytes) {
        final handler = widget.onPasteImage;
        if (handler != null) unawaited(handler(bytes));
      },
    );
  }

  KeyEventResult _onTextFieldKeyEvent(FocusNode node, KeyEvent event) {
    if (kIsWeb) return KeyEventResult.ignored;
    if (event is! KeyDownEvent ||
        (widget.onPasteImage == null && widget.onPasteVideo == null)) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final isPaste = event.logicalKey == LogicalKeyboardKey.keyV &&
        (keyboard.isControlPressed || keyboard.isMetaPressed);
    if (!isPaste) return KeyEventResult.ignored;
    unawaited(_pasteFromClipboard());
    return KeyEventResult.handled;
  }

  void _onTextFieldFocusChange() {
    if (_textFieldFocus.hasFocus) {
      widget.onComposerFocusGained();
    }
  }

  @override
  void dispose() {
    _disposeWebClipboardImageListener();
    _draftDebounce?.cancel();
    _draftDebounce = null;
    // 离开会话前把仍在防抖窗口内的草稿落库。
    widget.onDraftChanged?.call(_text.text);
    _textFieldFocus.removeListener(_onTextFieldFocusChange);
    _textFieldFocus.dispose();
    _text.removeListener(_onComposerTextChanged);
    _text.dispose();
    super.dispose();
  }

  void _onComposerTextFieldTapOutside(PointerDownEvent event) {
    final ctx = _composerInputBarKey.currentContext;
    if (ctx == null) {
      dismissPanelsAndKeyboard();
      return;
    }
    final ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize || !ro.attached) {
      dismissPanelsAndKeyboard();
      return;
    }
    final local = ro.globalToLocal(event.position);
    final hitRect = (Offset.zero & ro.size).inflate(2);
    if (hitRect.contains(local)) {
      return;
    }
    dismissPanelsAndKeyboard();
  }

  void _trySendComposedText() {
    final pendingSender = widget.onSendPendingAttachment;
    if (widget.attachmentBanner != null && pendingSender != null) {
      if (widget.pendingAttachmentSending) return;
      _composerKey.currentState?.closePanel();
      unawaited(pendingSender());
      return;
    }
    final t = _text.text.trim();
    if (t.isEmpty) return;
    if (!widget.ensureChatAllowed()) return;
    final hadPanel = _composerKey.currentState?.hasVisiblePanel ?? false;
    // 服务端 atUsers 为字符串列表：成员=用户 id 字符串，@all="0"。
    final atUsers = _pendingAtUserIds.isEmpty
        ? null
        : List<String>.from(_pendingAtUserIds.map((e) => '$e'));
    widget.onSendText(t, widget.replyTo?.msgId, atUsers);
    _pendingAtUserIds.clear();
    _pendingAtLabels.clear();
    _draftDebounce?.cancel();
    _draftDebounce = null;
    _text.clear();
    widget.onDraftChanged?.call('');
    setState(() {});
    if (!hadPanel) {
      maintainComposerFocusAfterSend();
    }
  }

  Future<void> _pasteFromClipboard() async {
    final imageHandler = widget.onPasteImage;
    if (imageHandler != null) {
      final image = await _mediaClipboard.readImageBytes();
      if (image != null && image.isNotEmpty) {
        await imageHandler(image);
        return;
      }
    }

    final videoHandler = widget.onPasteVideo;
    if (videoHandler != null) {
      final videoPath = await _mediaClipboard.readVideoFilePath();
      if (videoPath != null && videoPath.isNotEmpty) {
        await videoHandler(videoPath);
        return;
      }
    }

    // Ctrl/⌘+V 被本组件接管后，图片不存在时仍要保持普通文本粘贴。
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final pasted = data?.text;
    if (pasted == null || pasted.isEmpty) return;
    final value = _text.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    final start = selection.start.clamp(0, text.length);
    final end = selection.end.clamp(0, text.length);
    final next = text.replaceRange(start, end, pasted);
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + pasted.length),
    );
    widget.onTyping();
  }

  void _insertEmoji(String emoji) {
    final v = _text.value;
    final t = v.text;
    final s = v.selection;
    final start = s.isValid ? s.start.clamp(0, t.length) : t.length;
    final end = s.isValid ? s.end.clamp(0, t.length) : t.length;
    final newText = t.replaceRange(start, end, emoji);
    final newOffset = (start + emoji.length).clamp(0, newText.length);
    _text.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newOffset),
    );
    setState(() {});
  }

  void _clearComposerLastChar() {
    final v = _text.value;
    final t = v.text;
    if (t.isEmpty) return;
    final sel = v.selection;
    int cursor = sel.isValid ? sel.baseOffset.clamp(0, t.length) : t.length;
    if (cursor == 0) return;
    final prevCode = t.codeUnitAt(cursor - 1);
    int deleteFrom = cursor - 1;
    if (prevCode >= 0xDC00 && prevCode <= 0xDFFF && deleteFrom > 0) {
      deleteFrom -= 1;
    }
    final newText = t.substring(0, deleteFrom) + t.substring(cursor);
    _text.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: deleteFrom),
    );
    setState(() {});
  }

  void _handleSendSticker(String stickerUrl) {
    _composerKey.currentState?.closePanel();
    widget.onSendSticker(stickerUrl);
  }

  Widget _buildEmojiPanel() {
    return _GvEmojiAndStickerPanel(
      textController: _text,
      onInsertEmoji: _insertEmoji,
      onSendSticker: _handleSendSticker,
      onClearComposer: _clearComposerLastChar,
      onAddCustomSticker: () => unawaited(widget.onAddCustomSticker()),
      stickerPanelKey: _stickerPanelKey,
    );
  }

  Widget _moreActionTile({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    String? semanticsHint,
  }) {
    final fg = AppColors.textPrimary.resolveFrom(context);
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Semantics(
      key: key,
      button: true,
      label: label,
      hint: semanticsHint,
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(GvRadii.input),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 6,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final col = Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 28, color: iconColor),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GvTypography.small(fg).copyWith(height: 1.15),
                    ),
                  ],
                );
                return col;
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreActionsPanel() {
    final l10n = AppLocalizations.of(context)!;
    final tiles = <Widget>[
      _moreActionTile(
        icon: LucideIcons.image,
        label: l10n.chatMoreImage,
        onTap: () => unawaited(widget.onPickImage()),
      ),
      if (widget.onTakePhoto != null)
        _moreActionTile(
          key: GvAutomationKeys.chatMoreCamera,
          icon: LucideIcons.camera,
          label: l10n.chatMoreCamera,
          semanticsHint: l10n.chatMoreCameraHint,
          onTap: () => unawaited(widget.onTakePhoto!()),
        ),
      _moreActionTile(
        icon: LucideIcons.video,
        label: l10n.chatMoreVideo,
        onTap: () => unawaited(widget.onPickVideo()),
      ),
      if (widget.onTakePhoto == null)
        _moreActionTile(
          icon: LucideIcons.camera,
          label: l10n.chatMoreRecordVideo,
          onTap: () => unawaited(widget.onRecordVideo()),
        ),
      _moreActionTile(
        icon: LucideIcons.paperclip,
        label: l10n.chatMoreFile,
        onTap: () => unawaited(widget.onPickFile()),
      ),
      if (widget.onAtMention != null)
        _moreActionTile(
          icon: LucideIcons.at_sign,
          label: '@',
          onTap: () {
            closeComposerPanel();
            widget.onAtMention!();
          },
        ),
      if (_showCallActions && widget.isPrivateChat && widget.voiceCallEnabled)
        _moreActionTile(
          icon: LucideIcons.phone,
          label: l10n.chatMoreVoiceCall,
          onTap: () => widget.onStartPrivateCall('audio'),
        ),
      if (_showCallActions && widget.isPrivateChat && widget.videoCallEnabled)
        _moreActionTile(
          icon: LucideIcons.video,
          label: l10n.chatMoreVideoCall,
          onTap: () => widget.onStartPrivateCall('video'),
        ),
    ];
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: SingleChildScrollView(
          child: LayoutBuilder(
            builder: (context, c) {
              const count = 4;
              return GridView.count(
                crossAxisCount: count,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 4,
                childAspectRatio: 1.1,
                children: tiles,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reply = widget.replyTo;
    final l10n = AppLocalizations.of(context)!;
    return GvChatBottomComposer(
      key: _composerKey,
      toolbarKey: _composerInputBarKey,
      textController: _text,
      focusNode: _textFieldFocus,
      voiceMode: widget.voiceMode,
      recording: widget.recording,
      onToggleVoiceMode: widget.onToggleVoiceMode,
      voiceHoldAreaKey: widget.voiceHoldAreaKey,
      onVoicePointerDown: widget.onVoicePointerDown,
      onVoicePointerMove: widget.onVoicePointerMove,
      onVoicePointerUp: widget.onVoicePointerUp,
      onVoicePointerCancel: widget.onVoicePointerCancel,
      onTextChanged: (_) => widget.onTyping(),
      onSubmitted: (_) => _trySendComposedText(),
      onSend: _trySendComposedText,
      onTapOutside: _onComposerTextFieldTapOutside,
      attachmentBanner: widget.attachmentBanner,
      forceSendVisible: widget.attachmentBanner != null,
      sendEnabled: !widget.pendingAttachmentSending,
      replyBanner: reply == null
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.bgInput,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.chatReplyTo(reply.from == widget.myId
                              ? l10n.chatReplySelfShort
                              : (reply.fromUsername ??
                                  l10n.chatReplyPeerShort)),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.primary),
                        ),
                        GvChatQuotedMessagePreview(
                          message: reply,
                          baseUrl: AppConfig.mediaBase,
                          appHttpHeaders: gvBearerHeaders(
                            context.read<LocalStorage>(),
                          ),
                          color: AppColors.textSecondary,
                          thumbnailSize: 38,
                          onMediaTap: () => _openReplyMedia(reply),
                        ),
                      ],
                    ),
                  ),
                  _gvComposerTapIcon(
                    onTap: () {
                      closeComposerPanel();
                      widget.onDismissReply();
                    },
                    color: AppColors.textSecondary.resolveFrom(context),
                    icon: LucideIcons.x,
                    semanticsLabel: l10n.chatDismissReplySemantics,
                  ),
                ],
              ),
            ),
      emojiPanel: _buildEmojiPanel(),
      morePanel: _buildMoreActionsPanel(),
      readOnly: widget.readOnly,
      readOnlyHint: widget.readOnlyHint,
      onBottomChromeExpanded: widget.onBottomChromeExpanded,
    );
  }

  void _openReplyMedia(ChatMessage reply) {
    if (reply.msgType == 'image') {
      final image = parseImageForChat(AppConfig.mediaBase, reply.content);
      if (image.imageUrl.isNotEmpty) {
        showGvImageViewer(
          context,
          imageUrl: image.imageUrl,
          api: context.read<ImApi>(),
        );
      }
      return;
    }
    if (reply.msgType == 'video') {
      final video = parseVideoForChat(AppConfig.mediaBase, reply.content);
      if (video.playUrl.isNotEmpty) {
        final appHeaders = gvBearerHeaders(context.read<LocalStorage>());
        showGvVideoViewer(
          context,
          videoUrl: video.playUrl,
          api: context.read<ImApi>(),
          httpHeaders: gvMediaRequestHeaders(video.playUrl, appHeaders),
        );
      }
    }
  }
}

/// 合并 Unicode 表情 + 服务端表情包的 Tab 面板（表情 | 表情包 | 最近）。
class _GvEmojiAndStickerPanel extends StatefulWidget {
  const _GvEmojiAndStickerPanel({
    required this.textController,
    required this.onInsertEmoji,
    required this.onSendSticker,
    required this.onClearComposer,
    required this.onAddCustomSticker,
    required this.stickerPanelKey,
  });

  final TextEditingController textController;
  final void Function(String emoji) onInsertEmoji;
  final void Function(String stickerUrl) onSendSticker;
  final VoidCallback onClearComposer;
  final VoidCallback onAddCustomSticker;
  final GlobalKey<GvStickerPackPanelState> stickerPanelKey;

  @override
  State<_GvEmojiAndStickerPanel> createState() =>
      _GvEmojiAndStickerPanelState();
}

class _GvEmojiAndStickerPanelState extends State<_GvEmojiAndStickerPanel> {
  int _tabIndex = 0;

  GvStickerPackSection get _section =>
      _tabIndex == 2 ? GvStickerPackSection.recent : GvStickerPackSection.my;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox.expand(
      child: Column(
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                _tabBtn(l10n.chatEmojiTab, 0),
                const SizedBox(width: 4),
                _tabBtn(l10n.chatStickerPackTab, 1),
                const SizedBox(width: 4),
                _tabBtn(l10n.chatStickerRecentTab, 2),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _tabIndex == 0
                ? _buildUnicodeTabWithClear()
                : _buildStickerArea(),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final isActive = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? CupertinoColors.systemBlue.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color:
                isActive ? CupertinoColors.systemBlue : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildUnicodeTabWithClear() {
    const fontSize = 26.0;
    final cellStyle = gvEmojiPickerCellStyle(fontSize: fontSize);
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
          child: RepaintBoundary(
            child: GridView.builder(
              padding: EdgeInsets.zero,
              addRepaintBoundaries: false,
              addAutomaticKeepAlives: false,
              addSemanticIndexes: false,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 6,
                crossAxisSpacing: 4,
                childAspectRatio: 1,
              ),
              itemCount: kUnicodeEmojiPalette.length,
              itemBuilder: (context, i) {
                final e = kUnicodeEmojiPalette[i];
                return Semantics(
                  button: true,
                  label: e,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onInsertEmoji(e),
                    child: Center(
                      child: Text(
                        e,
                        textAlign: TextAlign.center,
                        style: cellStyle,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 8,
          bottom: 8,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.textController,
            builder: (context, val, _) {
              final empty = val.text.isEmpty;
              final color = empty
                  ? AppColors.textSecondary
                  : Theme.of(context).colorScheme.primary;
              return Material(
                color: Theme.of(context).colorScheme.surface,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                shadowColor: Colors.black26,
                child: InkWell(
                  onTap: empty ? null : widget.onClearComposer,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(LucideIcons.delete, size: 22, color: color),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStickerArea() {
    return Stack(
      children: [
        GvStickerPackPanel(
          key: widget.stickerPanelKey,
          section: _section,
          imApi: context.read<ImApi>(),
          storage: context.read<LocalStorage>(),
          onSendSticker: widget.onSendSticker,
        ),
        if (_tabIndex == 1)
          Positioned(
            right: 12,
            bottom: 12,
            child: Material(
              color: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              elevation: 3,
              child: InkWell(
                onTap: widget.onAddCustomSticker,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(LucideIcons.plus, size: 22, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
