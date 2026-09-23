import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:gv_ui/gv_ui.dart' show GvTypographyScale;

import '../core/app_colors.dart';
import '../core/gv_automation_keys.dart';
import '../core/unicode_emoji_palette.dart';

/// 表情 / 功能面板展开后的固定高度。
const double kGvChatComposerPanelHeight = 248;

/// 当前展开的底部面板类型（与系统键盘互斥，由 [GvChatBottomComposer] 协调）。
enum GvChatComposerPanelKind { none, emoji, more }

/// 聊天室底部输入区：工具栏 + 键盘/面板槽 + **底侧系统安全区**。
///
/// 纵向顺序：**输入栏 → 键盘或表情/更多面板槽（[viewInsets] / 面板高）→ Home 条等**。
/// 键盘收起时用 [MediaQuery.viewPadding] 底边；键盘展开时用 [MediaQuery.padding] 底边，
/// 避免与 [viewInsets] 重叠区域（如 iOS Home 条）被算两次，输入栏与键盘之间出现一条空隙。
///
/// 使用 [Scaffold.resizeToAvoidBottomInset] = false，占位只在组件内计算，**勿**在页面再包
/// `Padding(bottom: viewInsets)`，否则与系统键盘双重位移（Android 尤其明显）。
///
/// **表情/仅面板**（键盘已收起）：槽高仅为 [panelTrackH]，不把上一帧键盘高度垫在表情下。
/// **键盘抬起过程**：用 [_frozenKeyboardInset] 与 `vi` 取 max，避免中间帧槽高塌到远小于键盘。
///
/// 从键盘切到表情：**先** [setState] 展开面板，**下一帧**再 [unfocus]。
///
/// 仅依赖 Flutter SDK + 工程内主题色，不包含第三方 UI 包。

/// 点表情/更多后，在多久内忽略「键盘收起」触发的 [closePanel]。
/// 须大于 iOS 等设备上键盘收起动画时长，否则高概率在键盘尚未落完时误关面板。
const Duration _kGvComposerIgnoreKeyboardDismissClose =
    Duration(milliseconds: 2800);

class GvChatBottomComposer extends StatefulWidget {
  const GvChatBottomComposer({
    super.key,
    this.toolbarKey,
    required this.textController,
    required this.focusNode,
    required this.voiceMode,
    required this.recording,
    required this.onToggleVoiceMode,
    required this.voiceHoldAreaKey,
    required this.onVoicePointerDown,
    required this.onVoicePointerMove,
    required this.onVoicePointerUp,
    required this.onVoicePointerCancel,
    required this.onTextChanged,
    required this.onSubmitted,
    required this.onSend,
    required this.onTapOutside,
    this.attachmentBanner,
    required this.replyBanner,
    required this.emojiPanel,
    required this.morePanel,
    this.forceSendVisible = false,
    this.sendEnabled = true,

    /// 只读态（如频道订阅者）：隐藏语音/表情/更多/发送，仅展示一条提示条。
    /// 为 true 时 [readOnlyHint] 作为提示文案，缺省回退到频道「仅管理员可发布」。
    this.readOnly = false,
    this.readOnlyHint,

    /// 键盘或表情/更多面板使底部垫高后回调（由聊天页滚到底等）。
    this.onBottomChromeExpanded,
  });

  final GlobalKey? toolbarKey;

  final TextEditingController textController;
  final FocusNode focusNode;

  final bool voiceMode;
  final bool recording;
  final VoidCallback onToggleVoiceMode;

  final GlobalKey voiceHoldAreaKey;
  final void Function(PointerDownEvent event) onVoicePointerDown;
  final void Function(PointerMoveEvent event) onVoicePointerMove;
  final void Function(PointerEvent event) onVoicePointerUp;
  final void Function(PointerEvent event) onVoicePointerCancel;

  final ValueChanged<String> onTextChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSend;

  /// 与 [TextField.onTapOutside] 一致：返回 true 表示事件已处理、不应再 unfocus。
  final void Function(PointerDownEvent event) onTapOutside;

  /// Pending media shown above the regular composer input.
  final Widget? attachmentBanner;

  final Widget? replyBanner;

  /// 高度由 [GvChatBottomComposer] 内 [SizedBox] 约束（移动端 [kGvChatComposerPanelHeight]，PC 为一半）；一般为 [GridView]。
  final Widget emojiPanel;
  final Widget morePanel;

  /// Keeps the send action visible for a pending attachment even when the
  /// regular text composer is empty.
  final bool forceSendVisible;

  /// Disables the send action while a pending attachment is uploading.
  final bool sendEnabled;

  /// 只读态：不渲染输入/语音/表情/发送，仅展示 [readOnlyHint] 提示条。
  final bool readOnly;

  /// 只读态提示文案（如「仅管理员可发布」）。
  final String? readOnlyHint;

  final VoidCallback? onBottomChromeExpanded;

  @override
  State<GvChatBottomComposer> createState() => GvChatBottomComposerState();
}

class GvChatBottomComposerState extends State<GvChatBottomComposer>
    with WidgetsBindingObserver {
  /// 键盘收起或切面板过程中，垫在槽内的下限高度（避免 vi 动画中间帧过小）。
  double _frozenKeyboardInset = 0;

  /// 刚从「键盘 + 点表情/更多」切过来时，忽略一次「键盘收起」触发的自动关面板（避免刚打开就被关掉）。
  DateTime? _ignoreKeyboardDismissCloseUntil;

  double _lastViewInsetBottom = 0;

  GvChatComposerPanelKind _panelKind = GvChatComposerPanelKind.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _lastViewInsetBottom = MediaQuery.viewInsetsOf(context).bottom;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _notifyBottomChromeExpandedAfterLayout() {
    final cb = widget.onBottomChromeExpanded;
    if (cb == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      cb();
    });
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final vi = MediaQuery.viewInsetsOf(context).bottom;
      if (vi > _lastViewInsetBottom + 8) {
        _notifyBottomChromeExpandedAfterLayout();
      }
      // 键盘从展开变为收起：若表情/功能仍开着且非「刚打开面板」的保护期，则收起面板。
      if (_lastViewInsetBottom > 8 && vi < 8) {
        final guard = _ignoreKeyboardDismissCloseUntil;
        final withinGuard = guard != null && DateTime.now().isBefore(guard);
        if (hasVisiblePanel && !widget.focusNode.hasFocus && !withinGuard) {
          closePanel();
        }
      }
      _lastViewInsetBottom = vi;
    });
  }

  void _captureKeyboardInsetBeforePanel() {
    final h = MediaQuery.viewInsetsOf(context).bottom;
    if (h > 2) _frozenKeyboardInset = h;
  }

  void _clearFrozenKeyboardInset() {
    if (_frozenKeyboardInset == 0) return;
    setState(() => _frozenKeyboardInset = 0);
  }

  /// 点输入框：关面板；键盘尚未给出 viewInsets 前用 frozen 顶住槽高。
  void _dismissPanelForKeyboardInput() {
    if (_panelKind == GvChatComposerPanelKind.none) return;
    final vi = MediaQuery.viewInsetsOf(context).bottom;
    setState(() {
      _panelKind = GvChatComposerPanelKind.none;
      if (vi < 2) {
        // 原生桌面与常见宽屏 Web 无底部 IME inset，vi 持续为 0；若 frozen 成面板高度，
        // [build] 里「已聚焦且 belowFrozen」会一直用 [_frozenKeyboardInset] 撑 [chromeH]，底部灰块不消。
        final wideWeb =
            kIsWeb && MediaQuery.sizeOf(context).shortestSide >= 600;
        if (wideWeb) {
          _frozenKeyboardInset = 0;
        } else {
          _frozenKeyboardInset = math.max(
            _frozenKeyboardInset,
            _panelTrackHeight,
          );
        }
      } else {
        _frozenKeyboardInset = 0;
      }
    });
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      _ignoreKeyboardDismissCloseUntil = null;
      if (_panelKind != GvChatComposerPanelKind.none) {
        _dismissPanelForKeyboardInput();
      }
    }
  }

  double get _panelHeight => kGvChatComposerPanelHeight;

  /// 分隔线 1px + 表情/功能区高度。
  double get _panelTrackHeight => _panelHeight + 1;

  /// 是否有展开中的表情/功能面板（用于列表点击时判断是否需处理）。
  bool get hasVisiblePanel => _panelKind != GvChatComposerPanelKind.none;

  /// 仅收起表情/功能面板（不收起键盘）。
  void closePanel() {
    if (_panelKind == GvChatComposerPanelKind.none) {
      return;
    }
    _ignoreKeyboardDismissCloseUntil = null;
    setState(() {
      _panelKind = GvChatComposerPanelKind.none;
      _frozenKeyboardInset = 0;
    });
  }

  /// 收起面板并关闭键盘（点列表空白等）。
  void dismissPanelsAndKeyboard() {
    widget.focusNode.unfocus();
    closePanel();
  }

  /// 表情 / 更多：先展开面板再失焦。同步 [unfocus] 会在本帧 [build] 之前触发键盘 inset 变化，
  /// 易有一帧 chromeH 未带上面板高度；故在 **post-frame** 再 [unfocus]。
  void _openPanel(GvChatComposerPanelKind kind) {
    assert(kind != GvChatComposerPanelKind.none);
    _captureKeyboardInsetBeforePanel();
    _ignoreKeyboardDismissCloseUntil =
        DateTime.now().add(_kGvComposerIgnoreKeyboardDismissClose);
    setState(() => _panelKind = kind);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.focusNode.unfocus();
      _notifyBottomChromeExpandedAfterLayout();
    });
  }

  void _onEmojiButton() {
    if (_panelKind == GvChatComposerPanelKind.emoji) {
      closePanel();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.focusNode.canRequestFocus) {
          widget.focusNode.requestFocus();
        }
      });
      return;
    }
    _openPanel(GvChatComposerPanelKind.emoji);
  }

  void _onMoreButton() {
    if (_panelKind == GvChatComposerPanelKind.more) {
      closePanel();
      return;
    }
    _openPanel(GvChatComposerPanelKind.more);
  }

  static const double _inputVPad = 10;
  static const double _fontSize = GvTypographyScale.bodySmall;
  static const double _lineHeight = 1.25;
  static const double _oneLineH = _inputVPad * 2 + _fontSize * _lineHeight;
  static const double _barIconSize = 26;
  static const double _iconSlot = 30;

  Widget _tapIcon({
    Key? key,
    required VoidCallback onTap,
    required Color color,
    required IconData icon,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    String? semanticsLabel,
    bool fireOnDown = false,
  }) {
    final child = Padding(
      padding: padding,
      child: SizedBox(
        width: _iconSlot,
        height: _iconSlot,
        child: Center(child: Icon(icon, size: _barIconSize, color: color)),
      ),
    );
    return Semantics(
      key: key,
      button: true,
      label: semanticsLabel,
      child: fireOnDown
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => onTap(),
              child: child,
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: child,
            ),
    );
  }

  /// 只读态（频道订阅者等）：用一条与输入框同高的提示条替换整个输入区。
  ///
  /// 不渲染语音切换 / 表情 / 更多 / 发送按钮，也不挂 [TextField]，避免误聚焦弹键盘。
  Widget _buildReadOnlyBar(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fieldBg = AppColors.bgSearchField.resolveFrom(context);
    final fg = AppColors.textSecondary.resolveFrom(context);
    final hint = widget.readOnlyHint ?? l10n.channelComposerReadOnlyHint;
    return SizedBox(
      height: _oneLineH,
      child: Container(
        decoration: BoxDecoration(
          color: fieldBg,
          borderRadius: BorderRadius.circular(GvRadii.input),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.lock, size: 15, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _fontSize,
                  height: _lineHeight,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final viewPaddingBottom = MediaQuery.viewPaddingOf(context).bottom;
    final paddingBottom = MediaQuery.paddingOf(context).bottom;
    final panelH = _panelHeight;
    final panelOpen = hasVisiblePanel;
    final panelTrackH =
        _panelKind != GvChatComposerPanelKind.none ? _panelTrackHeight : 0.0;

    // 槽高：键盘 vi、面板轨道、以及 frozen 桥接（仅非「纯面板稳态」时与 frozen 合并）。
    double chromeH;
    if (panelOpen) {
      if (viewInsetsBottom > 2) {
        // 键盘尚在收起：槽随 vi 缩小，但不小于面板高度。
        chromeH = math.max(viewInsetsBottom, panelTrackH);
      } else {
        // 键盘已收起：仅面板高度，避免把上一档键盘高度垫在表情下（大空白）。
        chromeH = panelTrackH;
      }
    } else {
      chromeH = math.max(viewInsetsBottom, panelTrackH);
      if (_frozenKeyboardInset > 2) {
        final belowFrozen = viewInsetsBottom < _frozenKeyboardInset - 0.5;
        if (widget.focusNode.hasFocus && belowFrozen) {
          chromeH = math.max(chromeH, _frozenKeyboardInset);
        } else if (!widget.focusNode.hasFocus && viewInsetsBottom < 2) {
          chromeH = math.max(chromeH, _frozenKeyboardInset);
        }
      }
    }

    if (!panelOpen &&
        _frozenKeyboardInset > 2 &&
        viewInsetsBottom > 2 &&
        viewInsetsBottom >= _frozenKeyboardInset - 8) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _clearFrozenKeyboardInset();
      });
    }

    // 键盘可见时 viewInsets 已占满与 Home 条重叠的底边；再用 viewPadding.bottom 会多垫一层。
    final bottomSafeBarHeight =
        viewInsetsBottom > 2 ? paddingBottom : viewPaddingBottom;
    final showPanelChrome = _panelKind != GvChatComposerPanelKind.none;
    final barBg = CupertinoColors.systemBackground.resolveFrom(context);
    final pageBg = AppColors.bgPage.resolveFrom(context);
    final fieldBg = AppColors.bgSearchField.resolveFrom(context);
    final fg = AppColors.textPrimary.resolveFrom(context);

    Widget panelChild;
    switch (_panelKind) {
      case GvChatComposerPanelKind.emoji:
        panelChild = widget.emojiPanel;
        break;
      case GvChatComposerPanelKind.more:
        panelChild = widget.morePanel;
        break;
      case GvChatComposerPanelKind.none:
        panelChild = const SizedBox.shrink();
        break;
    }

    final panelBox = SizedBox(
      height: panelH,
      width: double.infinity,
      child: ColoredBox(
        color: pageBg,
        child: panelChild,
      ),
    );

    final panelSlide = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          height: 1,
          thickness: 0.5,
          color: Theme.of(context).dividerColor,
        ),
        panelBox,
      ],
    );

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: barBg,
              boxShadow: GvShadows.bar,
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: GvSpacing.sm),
              child: KeyedSubtree(
                key: widget.toolbarKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.readOnly && widget.attachmentBanner != null)
                      widget.attachmentBanner!,
                    if (!widget.readOnly && widget.replyBanner != null)
                      widget.replyBanner!,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        GvSpacing.sm,
                        GvSpacing.xs,
                        GvSpacing.sm,
                        GvSpacing.sm,
                      ),
                      child: TapRegion(
                        groupId: EditableText,
                        behavior: HitTestBehavior.opaque,
                        child: widget.readOnly
                            ? _buildReadOnlyBar(context)
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                            _tapIcon(
                              onTap: () {
                                closePanel();
                                widget.onToggleVoiceMode();
                              },
                              color: fg,
                              padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                              semanticsLabel: widget.voiceMode
                                  ? l10n.composerKeyboardInput
                                  : l10n.composerVoiceInput,
                              icon: widget.voiceMode
                                  ? LucideIcons.keyboard
                                  : LucideIcons.mic,
                            ),
                            Expanded(
                              child: widget.voiceMode
                                  ? Listener(
                                      key: widget.voiceHoldAreaKey,
                                      behavior: HitTestBehavior.opaque,
                                      onPointerDown: (e) =>
                                          widget.onVoicePointerDown(e),
                                      onPointerMove: widget.onVoicePointerMove,
                                      onPointerUp: widget.onVoicePointerUp,
                                      onPointerCancel:
                                          widget.onVoicePointerCancel,
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 160),
                                        height: _oneLineH,
                                        decoration: BoxDecoration(
                                          color: widget.recording
                                              ? AppColors.danger
                                                  .resolveFrom(context)
                                              : fieldBg,
                                          borderRadius: BorderRadius.circular(
                                              GvRadii.input),
                                          border: Border.all(
                                            color: widget.recording
                                                ? Colors.white
                                                    .withValues(alpha: 0.18)
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Center(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 120),
                                            child: Row(
                                              key: ValueKey(widget.recording),
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  LucideIcons.mic,
                                                  size: 16,
                                                  color: widget.recording
                                                      ? Colors.white
                                                      : fg,
                                                ),
                                                const SizedBox(width: 6),
                                                Flexible(
                                                  child: Text(
                                                    widget.recording
                                                        ? l10n
                                                            .chatVoiceReleaseToSend
                                                        : l10n
                                                            .composerHoldToTalk,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: widget.recording
                                                          ? 13
                                                          : _fontSize,
                                                      height: _lineHeight,
                                                      fontWeight:
                                                          widget.recording
                                                              ? FontWeight.w600
                                                              : FontWeight.w400,
                                                      color: widget.recording
                                                          ? Colors.white
                                                          : fg,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minHeight: _oneLineH,
                                      ),
                                      child: TextField(
                                        key: GvAutomationKeys.chatComposerInput,
                                        controller: widget.textController,
                                        focusNode: widget.focusNode,
                                        minLines: 1,
                                        maxLines: 5,
                                        // 不要用 [TextInputAction.send] / done 等：[EditableText] 在 [onSubmitted] 之后会
                                        // [_scheduleRestartConnection]，IME 重连会像失焦再聚焦。unspecified 走 shouldUnfocus:false，
                                        // 不触发重连，键盘「发送」仍通常可用（由系统按多行输入配置）。
                                        textInputAction:
                                            TextInputAction.unspecified,
                                        onTap: _dismissPanelForKeyboardInput,
                                        onTapOutside: widget.onTapOutside,
                                        onSubmitted: widget.onSubmitted,
                                        onEditingComplete: () {
                                          widget.textController
                                              .clearComposing();
                                        },
                                        style: (!kIsWeb &&
                                                defaultTargetPlatform ==
                                                    TargetPlatform.iOS)
                                            ? TextStyle(
                                                fontSize: _fontSize,
                                                height: _lineHeight,
                                                color: fg,
                                              )
                                            : gvChatComposerTextFieldStyle(
                                                TextStyle(
                                                  fontSize: _fontSize,
                                                  height: _lineHeight,
                                                  color: fg,
                                                ),
                                              ),
                                        strutStyle: gvChatBubbleStrutIosOnly(
                                          fontSize: _fontSize,
                                          height: _lineHeight,
                                        ),
                                        onChanged: widget.onTextChanged,
                                        decoration: InputDecoration(
                                          hintText: l10n.composerHint,
                                          filled: true,
                                          isDense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: _inputVPad,
                                          ),
                                          fillColor: fieldBg,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                                GvRadii.input),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                            if (!widget.voiceMode) ...[
                              const SizedBox(width: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _tapIcon(
                                    onTap: _onEmojiButton,
                                    color: fg,
                                    padding:
                                        const EdgeInsets.fromLTRB(0, 2, 4, 2),
                                    semanticsLabel:
                                        l10n.chatSemanticEmojiPicker,
                                icon: LucideIcons.face_slightly_smiling,
                                    fireOnDown: true,
                                  ),
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: widget.textController,
                                    builder: (context, value, _) {
                                      final hasText =
                                          value.text.trim().isNotEmpty;
                                      final showSend =
                                          hasText || widget.forceSendVisible;
                                      const edgePad =
                                          EdgeInsets.fromLTRB(0, 2, 4, 2);
                                      final slotW =
                                          _iconSlot + edgePad.horizontal;
                                      final slotH =
                                          _iconSlot + edgePad.vertical;
                                      return SizedBox(
                                        width: slotW,
                                        height: slotH,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          fit: StackFit.expand,
                                          children: [
                                            Offstage(
                                              offstage: showSend,
                                              child: IgnorePointer(
                                                ignoring: showSend,
                                                child: _tapIcon(
                                                  onTap: _onMoreButton,
                                                  color: fg,
                                                  padding: edgePad,
                                                  semanticsLabel:
                                                      l10n.commonMore,
                                                  icon: LucideIcons.circle_plus,
                                                  fireOnDown: true,
                                                ),
                                              ),
                                            ),
                                            Offstage(
                                              offstage: !showSend,
                                              child: IgnorePointer(
                                                ignoring: !showSend ||
                                                    !widget.sendEnabled,
                                                child: _tapIcon(
                                                  key: GvAutomationKeys
                                                      .chatComposerSend,
                                                  onTap: widget.onSend,
                                                  color: widget.sendEnabled
                                                      ? CupertinoColors
                                                          .systemBlue
                                                      : AppColors.textHint
                                                          .resolveFrom(context),
                                                  padding: edgePad,
                                                  semanticsLabel:
                                                      l10n.commonSend,
                                                  icon: Icons.send_rounded,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ClipRect(
            child: SizedBox(
              height: chromeH,
              width: double.infinity,
              child: ColoredBox(
                color: pageBg,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: _panelKind == GvChatComposerPanelKind.none
                      ? const SizedBox.shrink()
                      : panelSlide,
                ),
              ),
            ),
          ),
          ColoredBox(
            color: showPanelChrome ? pageBg : barBg,
            child: SizedBox(
              width: double.infinity,
              height: bottomSafeBarHeight,
            ),
          ),
        ],
      ),
    );
  }
}
