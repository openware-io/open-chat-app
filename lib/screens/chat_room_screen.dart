import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/gestures.dart' show kPrimaryButton;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:gal/gal.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:open_core/open_core.dart';
import 'package:open_ui/open_ui.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:record/record.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/open_automation_keys.dart';
import '../core/open_channel_code.dart';
import '../core/open_secondary_navigation.dart';
import '../core/open_toast.dart';
import '../core/config.dart';
import '../core/formatters.dart';
import '../core/open_message_forward.dart';
import '../core/message_preview.dart';
import '../core/upload_mime.dart';
import '../models/channel_models.dart';
import '../models/media_upload_result.dart';
import '../models/secret_chat_models.dart';
import '../models/secret_group_chat_models.dart';
import '../providers/call_provider.dart';
import '../providers/chat_provider.dart';
import '../services/secure_screen.dart';
import '../providers/client_remote_config_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../repositories/favorite_repository.dart';
import '../core/api_failure.dart';
import '../services/api_client.dart';
import '../services/chat_media_clipboard_service.dart';
import '../services/im_api.dart';
import '../widgets/open_avatar.dart';
import '../widgets/open_dialog_actions.dart';
import '../widgets/open_nav_bar.dart';
import '../widgets/open_chat_room_bottom.dart';
import 'chat_room/chat_room_list_models.dart';
import 'chat_room/chat_room_media_helpers.dart';
import 'chat_room/chat_room_message_tile.dart';
import 'chat_room/chat_room_paging_dots.dart';
import 'chat_room/open_chat_camera_screen.dart';

typedef _AtMentionCandidate = ({
  int userId,
  String displayLabel,
  String mentionLabel,
  String? groupNickname,
  String? avatar,
});

/// 私聊或群聊会话的主界面：消息列表 + 底部 composer，可选打开时锚定某条消息。
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.chatType,
    required this.peerId,
    this.anchorMsgId,
    this.anchorSeedMessage,
  });

  final String chatType;
  final String peerId;

  /// 打开时滚动并短暂高亮该消息（如从聊天记录查询页跳入）。
  final String? anchorMsgId;

  /// 与 [anchorMsgId] 对应的一条完整消息（如搜索页 [extra]），合并进内存后再定位，避免仅靠分页拉不到。
  final ChatMessage? anchorSeedMessage;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

/// 单会话聊天页状态：负责历史分页、锚点定位、输入区与语音录制、媒体上传及消息菜单等。
///
/// 展示层尽量委托给 [GvChatRoomBottom]、[ChatRoomMessageTile]；本类聚焦会话生命周期与列表滚动契约。
class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final GlobalKey<GvChatRoomBottomState> _roomBottomKey =
      GlobalKey<GvChatRoomBottomState>();
  final GvChatMediaClipboardService _mediaClipboard =
      const GvChatMediaClipboardService();

  /// 消息列表视口（[ListView] 区域），用于取视口高度。
  final GlobalKey _messageListStackKey =
      GlobalKey(debugLabel: 'message_list_viewport');

  final GvChatMessageListController _msgListController =
      GvChatMessageListController();

  /// 多选模式：长按菜单「多选」进入，点击消息勾选，底部批量删除。
  bool _multiSelect = false;
  final Set<String> _selectedMsgIds = {};

  /// 历史分页请求进行中。
  bool _historyPaging = false;

  /// 正在拉更旧一页：在列表**视觉顶部**（reverse 的末尾）显示三点 loading。
  bool _pagingLoadingOlder = false;

  /// 正在拉更新一页：在列表**视觉底部**（reverse 的开头）显示三点 loading。
  bool _pagingLoadingNewer = false;

  /// 服务端/合并推断：时间上更旧一侧是否已无更多。
  bool _noMoreOlder = false;

  /// 服务端/合并推断：时间上更新一侧是否已无更多。
  bool _noMoreNewer = true;

  /// 锚点首屏定位完成前暂不响应列表边缘分页。
  bool _suppressListPaging = false;

  static const int _kHistoryPageSize = 30;

  /// 从聊天记录搜索锚点进房时，以目标消息为中心向旧/向新各拉取的条数（不含中心则接口语义以服务端为准）。
  static const int _kAnchorHistoryHalfCount = 30;

  /// 锚点定位期间 [_suppressListPaging] 为 true 时传入列表；否则懒加载不建目标行，[_anchorNavTileKey] 永无 [context]，无法滚到搜索结果。
  static const double _kAnchorListCacheExtent = 12000.0;

  /// 挂在锚点消息气泡上，供搜索进房后 [Scrollable.ensureVisible] 使用。
  final GlobalKey _anchorNavTileKey = GlobalKey(debugLabel: 'anchor_nav_tile');

  /// 与列表同宽、同款 padding 的离屏 Column，用于在写入 [messageMap] 前预渲染并测量插入段总高度。
  List<RoomItem> _pagingMeasureSegment = const [];

  final GlobalKey _pagingMeasureKey = GlobalKey(debugLabel: 'paging_measure');

  /// 分页 [await] 期间若用户拖动了列表，则放弃延迟 [jumpTo]，避免视口被拽回。
  bool _abortPagingViewportCompensation = false;

  /// 实时消息测高提交流水线执行中（与 [_historyPaging] 一样参与滚动放弃补偿）。
  bool _realtimeDeferInsertPipelineBusy = false;

  /// 底部键盘/面板连续 [didChangeMetrics] 时合并为一次回底。
  Timer? _scrollToBottomForChromeDebounce;

  /// 距视觉底部（最新一条）超过该值且来新消息时，显示「新消息」贴边按钮。
  static const double _kNewMessageChipAwayFromBottomPx = 50;

  bool _showNewMessagesFloatingChip = false;

  /// 与 [ChatProvider.realtimeIngestEpochForSession] 对齐；仅 WebSocket 写入列表时递增，见 [_syncNewMessageFloatingChipAfterChatNotify]。
  int _lastSeenRealtimeIngestEpoch = 0;

  /// 进房后已同步过当前 [realtimeIngestEpoch]，避免首帧与其它 notify 误出角标。
  bool _newMessageChipBaselineReady = false;

  /// 已对无效会话做过提示并退房，避免重复校验/弹 Toast。
  bool _invalidPeerHandled = false;

  /// 频道详情（订阅者只读判定）；进房时拉取，失败保持 null 时默认只读。
  ChannelInfo? _channelInfo;

  /// 私密会话详情（安全码 / 销毁策略展示）。
  SecretChatInfo? _secretChat;

  /// 私密群聊详情（成员 / 安全码 / 销毁策略展示）。
  SecretGroupChatInfo? _secretGroupChat;

  /// 私密聊天室周期轮询（近似实时同步密文；E2EE 不走 WS 明文推送）。
  Timer? _secretPollTimer;

  /// 私密群聊周期轮询（近似实时同步密文）。
  Timer? _secretGroupPollTimer;

  /// 频道订阅者（非管理员）只读：详情未加载或明确非 owner 时禁用输入。
  bool get _isChannelReadOnly =>
      widget.chatType == 'channel' && !(_channelInfo?.isOwner ?? false);

  bool get _isGroupReadOnly =>
      widget.chatType == 'group' &&
      context.read<ChatProvider>().isGroupDissolved(widget.peerId);

  /// 合并并发的进房校验请求，避免第二次误判为「已在 flight」而直接丢单。
  Future<void>? _enterPeerValidationFuture;

  bool _voiceMode = false;

  /// 最近一次文本发送时刻，用于避免发送后立即因焦点回调再次抢滚。
  DateTime? _lastTextSendAt;
  ChatMessage? _replyTo;
  final TextEditingController _imageCaptionController = TextEditingController();
  final FocusNode _imageCaptionFocus = FocusNode();
  _PendingImageDraft? _pendingImageDraft;
  bool _pendingImageSending = false;
  final _audioRecorder = AudioRecorder();
  bool _recording = false;

  /// 与 H5 `MIN_RECORD_MS` 一致。
  static const int _kMinVoiceRecordMs = 550;

  bool _ensureChatFeatureAllowed() {
    final remote = context.read<ClientRemoteConfigProvider>();
    if (widget.chatType == 'private' && !remote.privateChatEnabled) {
      GvToast.show(
          context, AppLocalizations.of(context)!.featurePrivateChatDisabled);
      return false;
    }
    if (widget.chatType == 'group' && !remote.groupChatEnabled) {
      GvToast.show(
          context, AppLocalizations.of(context)!.featureGroupChatDisabled);
      return false;
    }
    if (widget.chatType == 'channel' && !remote.channelEnabled) {
      GvToast.show(
          context, AppLocalizations.of(context)!.featureChannelDisabled);
      return false;
    }
    if (widget.chatType == 'secret' && !remote.secretChatEnabled) {
      GvToast.show(
          context, AppLocalizations.of(context)!.featureSecretChatDisabled);
      return false;
    }
    if (widget.chatType == 'secret_group' && !remote.secretGroupChatEnabled) {
      GvToast.show(context,
          AppLocalizations.of(context)!.featureSecretGroupChatDisabled);
      return false;
    }
    return true;
  }

  void _onRoomBottomSendText(
    String trimmedText,
    String? replyMsgId,
    List<dynamic>? atUsers,
  ) {
    _lastTextSendAt = DateTime.now();
    final chat = context.read<ChatProvider>();
    if (widget.chatType == 'secret') {
      unawaited(_sendSecretText(chat, trimmedText, replyMsgId: replyMsgId));
    } else if (widget.chatType == 'secret_group') {
      unawaited(_sendSecretGroupText(chat, trimmedText,
          replyMsgId: replyMsgId, atUsers: atUsers));
    } else {
      chat.sendMessage(widget.peerId, widget.chatType, 'text', trimmedText,
          replyMsgId: replyMsgId, atUsers: atUsers);
    }
    setState(() => _replyTo = null);
  }

  /// 当前会话在内存 [Conversation] 中缓存的未发送草稿；无则返回 null。
  String? _conversationDraftText(ChatProvider chat) {
    for (final c in chat.conversations) {
      if (c.id == widget.peerId && c.chatType == widget.chatType) {
        final draft = c.draftText;
        if (draft != null && draft.isNotEmpty) return draft;
        return null;
      }
    }
    return null;
  }

  /// 私密聊天发送：E2EE 加密 → 密文通道；未握手先握手。
  ///
  /// 对方尚未完成握手时短暂等待后自动重试一次（对方可能刚加入完成握手）。
  Future<void> _sendSecretText(
    ChatProvider chat,
    String text, {
    String msgType = 'text',
    List<String>? mediaObjectIds,
    String? convPreview,
    String? replyMsgId,
  }) async {
    SecretSendResult result;
    try {
      result = await chat.sendSecretText(
        secretChatId: widget.peerId,
        text: text,
        msgType: msgType,
        mediaObjectIds: mediaObjectIds,
        convPreview: convPreview,
        replyMsgId: replyMsgId,
      );
      if (result == SecretSendResult.waitingForPeer) {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        result = await chat.sendSecretText(
          secretChatId: widget.peerId,
          text: text,
          msgType: msgType,
          mediaObjectIds: mediaObjectIds,
          convPreview: convPreview,
          replyMsgId: replyMsgId,
        );
      }
    } catch (_) {
      result = SecretSendResult.failed;
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case SecretSendResult.success:
        break;
      case SecretSendResult.waitingForPeer:
        GvToast.show(
          context,
          l10n.toastSecretChatWaitingPeer,
          duration: const Duration(seconds: 2),
        );
      case SecretSendResult.failed:
        GvToast.show(context, l10n.toastSecretChatUnavailable);
    }
  }

  /// 私密群聊发送：逐成员 E2EE 加密 → 密文通道；未握手先握手。
  Future<void> _sendSecretGroupText(
    ChatProvider chat,
    String text, {
    String msgType = 'text',
    List<String>? mediaObjectIds,
    String? convPreview,
    String? replyMsgId,
    List<dynamic>? atUsers,
  }) async {
    SecretSendResult result;
    try {
      result = await chat.sendSecretGroupText(
        groupId: widget.peerId,
        text: text,
        msgType: msgType,
        mediaObjectIds: mediaObjectIds,
        convPreview: convPreview,
        replyMsgId: replyMsgId,
        atUsers: atUsers,
      );
      if (result == SecretSendResult.waitingForPeer) {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        result = await chat.sendSecretGroupText(
          groupId: widget.peerId,
          text: text,
          msgType: msgType,
          mediaObjectIds: mediaObjectIds,
          convPreview: convPreview,
          replyMsgId: replyMsgId,
        );
      }
    } catch (_) {
      result = SecretSendResult.failed;
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    switch (result) {
      case SecretSendResult.success:
        break;
      case SecretSendResult.waitingForPeer:
        GvToast.show(
          context,
          l10n.toastSecretChatWaitingPeer,
          duration: const Duration(seconds: 2),
        );
      case SecretSendResult.failed:
        GvToast.show(context, l10n.toastSecretChatUnavailable);
    }
  }

  OverlayEntry? _voiceOverlayEntry;
  void Function(void Function())? _voiceOverlaySetState;
  final GlobalKey _voiceOverlayListenerKey =
      GlobalKey(debugLabel: 'voice_overlay_listener');
  final GlobalKey _voiceHoldAreaKey = GlobalKey(debugLabel: 'voice_hold');
  int? _voiceActivePointerId;
  String? _voiceTempPath;

  /// Web 上传语音文件名后缀（与 [RecordConfig.encoder] 一致），如 webm / wav / m4a。
  String? _voiceWebUploadExt;
  DateTime? _voiceRecordStartedAt;
  bool _voiceAbortBeforeStart = false;
  bool _voicePointerInCancel = false;

  /// 录音开始时手指的全局 Y，用于「上划超过阈值即进入取消态」（参考微信，无独立取消按钮区）。
  double _voiceStartGlobalY = 0;
  static const double _kVoiceCancelSlideUpDistance = 80;
  StreamSubscription<Amplitude>? _voiceAmplitudeSubscription;
  static const int _kVoiceWaveBarCount = 17;
  List<double> _voiceWaveLevels =
      List<double>.filled(_kVoiceWaveBarCount, 0.12);

  /// 进入页过渡未完成前不构建消息列表，减轻与 [CupertinoPageTransition] 同帧抢 GPU。
  bool _messageListVisible = false;

  /// 进房历史拉取是否已启动（与 [_messageListVisible] 解耦，避免重复请求）。
  bool _roomHistoryBootstrapStarted = false;

  /// 定位完成后高亮对应气泡，超时后清除。
  String? _highlightAnchorMsgId;

  bool _routeEnterListenerAttached = false;
  ModalRoute<dynamic>? _modalRouteForListener;
  AnimationStatusListener? _routeEnterStatusListener;

  /// 根导航 push 的全屏聊天页（[GoRouter] [matchedLocation] 为 `/chat/...`）。
  ///
  /// 桌面双栏里 [ChatRoomScreen] 嵌在右侧 [Navigator] 的 `/` 下，[ModalRoute.of] 会得到**已结束**的父 route，
  /// 不能用它判断转场；此类场景走 [addPostFrameCallback] 即可。
  bool _isRootNavigatorChatPush(BuildContext context) {
    try {
      final loc = GoRouterState.of(context).matchedLocation;
      return loc.startsWith('/chat/');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _applySecureScreen(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<ChatProvider>().addListener(_onChatProviderChatRoom);
      } catch (_) {}
    });
  }

  /// 私密聊天 / 私密群聊进入时开启防截图/录屏，普通会话不开启。
  /// Android 用 FLAG_SECURE 真正阻止；iOS 检测到截图/录屏后弹提醒。
  void _applySecureScreen(bool secure) {
    if (widget.chatType != 'secret' && widget.chatType != 'secret_group') {
      return;
    }
    if (secure) {
      SecureScreen.setCaptureListener(_onCaptureDetected);
    } else {
      SecureScreen.setCaptureListener(null);
    }
    unawaited(SecureScreen.setSecure(secure));
  }

  void _onCaptureDetected(String type) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final msg = type == 'recording'
        ? l10n.secretChatRecordingWarning
        : l10n.secretChatScreenshotWarning;
    GvToast.show(context, msg);
  }

  void _onChatProviderChatRoom() {
    if (!mounted) return;
    final chat = context.read<ChatProvider>();
    final d = chat.deferredRealtimeSessionInsert;
    if (d != null &&
        d.peerId == widget.peerId &&
        d.chatType == widget.chatType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_processDeferredRealtimeInsertPipeline());
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncNewMessageFloatingChipAfterChatNotify();
    });
  }

  /// 在写入 [ChatProvider.messageMap] 前离屏测插入段高度，再提交并做与向新分页相同的视口补偿。
  Future<void> _processDeferredRealtimeInsertPipeline() async {
    if (_realtimeDeferInsertPipelineBusy) return;
    _realtimeDeferInsertPipelineBusy = true;
    try {
      while (mounted) {
        final chat = context.read<ChatProvider>();
        final d = chat.deferredRealtimeSessionInsert;
        if (d == null ||
            d.peerId != widget.peerId ||
            d.chatType != widget.chatType) {
          break;
        }

        if (!_messageListVisible || _historyPaging || !_noMoreNewer) {
          chat.commitDeferredRealtimeSessionInsert(force: true);
          continue;
        }

        final vStart = d.version;
        final flatBefore = List<RoomItem>.from(_flatItemsNewestFirst(chat));
        final flatAfter = _flatItemsNewestFirst(chat, d.mergedSession);
        if (flatAfter.length <= flatBefore.length) {
          chat.commitDeferredRealtimeSessionInsert(force: true);
          continue;
        }

        final segment =
            flatAfter.sublist(0, flatAfter.length - flatBefore.length);
        _abortPagingViewportCompensation = false;
        final h = await _measurePagingInsertHeight(segment);
        if (!mounted) break;

        final d2 = chat.deferredRealtimeSessionInsert;
        if (d2 == null ||
            d2.peerId != widget.peerId ||
            d2.chatType != widget.chatType) {
          break;
        }
        if (d2.version != vStart) {
          continue;
        }

        final committed = chat.commitDeferredRealtimeSessionInsert(
          expectedVersion: vStart,
        );
        if (!committed) continue;

        if (h > 0.5 && !_abortPagingViewportCompensation) {
          _scheduleRealtimeInsertViewportCompensation(h);
        }
      }
    } finally {
      _realtimeDeferInsertPipelineBusy = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeEnterListenerAttached) return;
    _routeEnterListenerAttached = true;

    final chat = context.read<ChatProvider>();
    final session = chat.messagesFor(widget.peerId, widget.chatType);
    final anchorId = widget.anchorMsgId?.trim() ?? '';
    final hasAnchor = anchorId.isNotEmpty;
    final anchorInSession =
        hasAnchor && session.any((m) => m.msgId == anchorId);
    final willReplaceAnchorWindow = hasAnchor && !anchorInSession;
    // 已有可展示数据且不会马上清空换锚点窗时，首帧即挂载列表，不跟全屏 push 转场结束。
    final canShowListWithoutEnterTransition =
        session.isNotEmpty && !willReplaceAnchorWindow;

    if (canShowListWithoutEnterTransition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onEnterTransitionComplete();
      });
      return;
    }

    if (!_isRootNavigatorChatPush(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onEnterTransitionComplete();
      });
      return;
    }

    final route = ModalRoute.of(context);
    if (route == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onEnterTransitionComplete();
      });
      return;
    }

    final anim = route.animation;
    if (anim == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onEnterTransitionComplete();
      });
      return;
    }

    // 首帧后再读 animation：避免在 route 尚未开始 forward 时误用 completed（多为祖先 route）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (anim.status == AnimationStatus.completed) {
        _onEnterTransitionComplete();
        return;
      }
      _modalRouteForListener = route;
      _routeEnterStatusListener = (AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          anim.removeStatusListener(_routeEnterStatusListener!);
          _routeEnterStatusListener = null;
          _modalRouteForListener = null;
          if (mounted) _onEnterTransitionComplete();
        }
      };
      anim.addStatusListener(_routeEnterStatusListener!);
    });
  }

  /// 挂载消息列表并拉历史：无缓存时可等全屏转场结束；已有会话数据则已由 [didChangeDependencies] 首帧触发。
  void _onEnterTransitionComplete() {
    if (!mounted || _messageListVisible || _invalidPeerHandled) return;
    if (_enterPeerValidationFuture != null) {
      unawaited(_enterPeerValidationFuture!);
      return;
    }
    final f = _runEnterPeerValidationThenShowChat();
    _enterPeerValidationFuture = f;
    unawaited(f.whenComplete(() {
      if (identical(_enterPeerValidationFuture, f)) {
        _enterPeerValidationFuture = null;
      }
    }));
  }

  /// 进房前校验对方是否仍为好友 / 群是否仍存在；失败则清理会话与通讯录缓存并退出。
  Future<void> _runEnterPeerValidationThenShowChat() async {
    if (!mounted || _messageListVisible || _invalidPeerHandled) return;
    if (!_ensureChatFeatureAllowed()) return;

    final ok = await _validateChatPeerStillValid();
    if (!mounted) return;
    if (!ok) {
      setState(() => _invalidPeerHandled = true);
      _pruneStalePeerAndLeaveChat();
      return;
    }
    setState(() => _messageListVisible = true);
    unawaited(_bootstrapRoomHistoryLoad());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncNewMessageFloatingChipAfterChatNotify();
    });
  }

  /// `true` 表示可继续进房；网络错误等不确定情况放行，避免误拦离线使用。
  Future<bool> _validateChatPeerStillValid() async {
    final chat = context.read<ChatProvider>();
    final my = chat.myId;

    if (widget.chatType == 'group') {
      final gid = int.tryParse(widget.peerId);
      if (gid == null) return false;
      try {
        final info = await context.read<GroupProvider>().loadGroupInfo(gid);
        final status =
            (info['status'] ?? info['groupStatus'] ?? info['group_status'])
                ?.toString()
                .toUpperCase();
        if (status == 'DISSOLVED') {
          chat.markGroupDissolved(widget.peerId);
        }
        return true;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 404 || code == 403 || code == 410) return false;
        return true;
      } catch (_) {
        return true;
      }
    }

    // 频道：拉详情（顺带完成订阅者角色判定缓存）；404/403 视为已失效。
    if (widget.chatType == 'channel') {
      try {
        final info = await chat.channelInfo(widget.peerId);
        if (!mounted) return true;
        setState(() => _channelInfo = info);
        // 非管理员进房阅读前自动订阅（幂等），失败不阻塞进房。
        if (!info.isOwner) {
          unawaited(chat.subscribeChannel(widget.peerId).catchError((_) {
            return info;
          }));
        }
        return true;
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 404 || code == 403 || code == 410) return false;
        return true;
      } catch (_) {
        return true;
      }
    }

    // 私密聊天：从「我的私密会话」中匹配会话 id，已销毁/不在列表视为失效。
    if (widget.chatType == 'secret') {
      try {
        final list = await chat.mySecretChats();
        if (!mounted) return true;
        for (final s in list) {
          if (s.id == widget.peerId) {
            setState(() => _secretChat = s);
            // E2EE：完成握手（提交本端公钥/推导共享密钥）并拉取密文解密。
            unawaited(_bootstrapSecretE2ee(chat));
            return true;
          }
        }
        return false;
      } on DioException {
        return true;
      } catch (_) {
        return true;
      }
    }

    // 私密群聊：从「我的私密群聊」中匹配会话 id，已解散/不在列表视为失效。
    if (widget.chatType == 'secret_group') {
      try {
        final list = await chat.mySecretGroupChats();
        if (!mounted) return true;
        for (final s in list) {
          if (s.id == widget.peerId) {
            setState(() => _secretGroupChat = s);
            unawaited(_bootstrapSecretGroupE2ee(chat));
            return true;
          }
        }
        return false;
      } on DioException {
        return true;
      } catch (_) {
        return true;
      }
    }

    if (widget.chatType != 'private') return true;

    final pid = int.tryParse(widget.peerId);
    if (pid == null) return false;
    if (my != null && pid == my) return true;

    try {
      await context.read<FriendProvider>().loadFriends();
    } on DioException {
      return true;
    } catch (_) {
      return true;
    }
    if (!mounted) return true;
    return context.read<FriendProvider>().friends.any((f) => f.friendId == pid);
  }

  void _pruneStalePeerAndLeaveChat() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final chat = context.read<ChatProvider>();
    final friend = context.read<FriendProvider>();
    final group = context.read<GroupProvider>();

    // 以接口列表为准刷新通讯录，避免仅改本地与后端不一致。
    if (widget.chatType == 'group') {
      unawaited(group.loadGroups().catchError((_, __) {}));
    } else if (widget.chatType == 'private') {
      unawaited(friend.loadFriends().catchError((_, __) {}));
    }

    chat.removeConversation(widget.peerId, widget.chatType);
    final unavailableMsg = switch (widget.chatType) {
      'group' => l10n.toastGroupDissolved,
      'channel' => l10n.toastChannelUnavailable,
      'secret' => l10n.toastSecretChatUnavailable,
      'secret_group' => l10n.toastSecretChatUnavailable,
      _ => l10n.chatPeerUnavailableToast,
    };
    GvToast.show(context, unavailableMsg);

    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/chats');
    }
  }

  @override
  void deactivate() {
    final peerId = widget.peerId;
    final chatType = widget.chatType;
    ChatProvider? chat;
    try {
      chat = context.read<ChatProvider>();
    } catch (_) {}
    super.deactivate();
    // [deactivate] 可能在 Navigator/Overlay 仍处 build 时调用，同步 notifyListeners 会触发
    //「setState/markNeedsBuild during build」；延后到帧末再清会话指针。
    final chatRef = chat;
    if (chatRef != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatRef.flushDeferredRealtimeIfMatches(peerId, chatType);
        chatRef.closeChatIfCurrent(peerId, chatType);
      });
    }
  }

  @override
  void dispose() {
    _applySecureScreen(false);
    final l = _routeEnterStatusListener;
    if (l != null) {
      _modalRouteForListener?.animation?.removeStatusListener(l);
    }
    _removeVoiceRecordingOverlay();
    if (_voiceTempPath != null) {
      unawaited(_discardTempVoiceFile(_voiceTempPath!));
    }
    unawaited(_audioRecorder.dispose());
    _imageCaptionController.dispose();
    _imageCaptionFocus.dispose();
    _scrollToBottomForChromeDebounce?.cancel();
    _secretPollTimer?.cancel();
    _secretGroupPollTimer?.cancel();
    _msgListController.scroll.dispose();
    try {
      final c = context.read<ChatProvider>();
      c.removeListener(_onChatProviderChatRoom);
      c.flushDeferredRealtimeIfMatches(widget.peerId, widget.chatType);
      c.setAllowRealtimeMergeIntoCurrentChatList(true);
    } catch (_) {}
    super.dispose();
  }

  String _title(
    ChatProvider chat,
    FriendProvider f,
    GroupProvider g,
    AppLocalizations l10n,
  ) {
    if (widget.chatType == 'private') {
      final fd = f.getFriendDisplay(int.tryParse(widget.peerId) ?? 0);
      if (fd != null) return fd.name;
    } else if (widget.chatType == 'group') {
      final n = g.getGroupDisplayName(widget.peerId);
      if (!n.startsWith('群聊 ')) return n;
    } else if (widget.chatType == 'channel' &&
        _channelInfo != null &&
        _channelInfo!.name.isNotEmpty) {
      return _channelInfo!.name;
    } else if (widget.chatType == 'secret_group') {
      final secretName = _secretGroupChat?.name;
      if (secretName != null && secretName.trim().isNotEmpty) {
        return secretName.trim();
      }
    }
    for (final c in chat.conversations) {
      if (c.id == widget.peerId && c.chatType == widget.chatType) return c.name;
    }
    return switch (widget.chatType) {
      'group' => l10n.chatGroupDefaultTitle(widget.peerId),
      'channel' => l10n.chatChannelDefaultTitle(widget.peerId),
      'secret' => l10n.chatSecretDefaultTitle(widget.peerId),
      'secret_group' => l10n.secretGroupChatDefaultTitle,
      _ => l10n.chatUserDefaultTitle(widget.peerId),
    };
  }

  String? _typingText(ChatProvider chat, int? myId, AppLocalizations l10n) {
    if (widget.chatType != 'private' || myId == null) return null;
    for (final e in chat.typingUsers.entries) {
      if (e.key == widget.peerId) {
        final ts = e.value.ts;
        if (DateTime.now().millisecondsSinceEpoch - ts < 3000) {
          return l10n.chatTypingPeer;
        }
      }
    }
    return null;
  }

  /// 与 [_flatItems] 使用同一可见集合；按本页 [peerId]/[chatType] 读 [ChatProvider.messageMap]，避免依赖 [currentChatId] 时序。
  ///
  /// [sessionChronologicalOverride]：分页测高时尚未写入 Provider 的合并后会话列表（时间上 **旧→新**，与 [messageMap] 序一致）。
  List<ChatMessage> _listMessagesForUi(
    ChatProvider chat, [
    List<ChatMessage>? sessionChronologicalOverride,
  ]) {
    final chronological = sessionChronologicalOverride ??
        chat.messagesFor(widget.peerId, widget.chatType);
    return chronological
        .where((m) => !chat.isMessageHidden(
              widget.peerId,
              widget.chatType,
              m.msgId,
              timestamp: m.timestamp,
            ))
        .toList();
  }

  /// 打开表情/更多、输入聚焦、按住说话等：若内存列表尾部落后于会话 [Conversation.lastTime]，拉一页最新数据（不滚动列表）。
  Future<void> _refreshTailIfStaleForComposer() async {
    if (!_messageListVisible) return;
    final chat = context.read<ChatProvider>();
    Conversation? conv;
    for (final c in chat.conversations) {
      if (c.id == widget.peerId && c.chatType == widget.chatType) {
        conv = c;
        break;
      }
    }
    final msgs = _listMessagesForUi(chat);
    var needTailRefresh = msgs.isEmpty;
    if (!needTailRefresh && conv != null) {
      final tail = msgs.last;
      needTailRefresh = tail.timestamp
          .isBefore(conv.lastTime.subtract(const Duration(seconds: 2)));
    }
    if (needTailRefresh) {
      await chat.loadHistory(widget.peerId, widget.chatType);
    }
  }

  bool _onListScrollUserInteraction(ScrollNotification n) {
    if ((_historyPaging || _realtimeDeferInsertPipelineBusy) &&
        n is UserScrollNotification) {
      _abortPagingViewportCompensation = true;
    }
    if (n is UserScrollNotification) {
      _dismissComposerPanelsAndKeyboard();
    } else if (n is ScrollStartNotification && n.dragDetails != null) {
      _dismissComposerPanelsAndKeyboard();
    }
    if (n is ScrollUpdateNotification || n is ScrollEndNotification) {
      _tryDismissNewMessageFloatingChipIfCaughtUp();
    }
    return false;
  }

  List<RoomItem> _flatItems(
    ChatProvider chat, [
    List<ChatMessage>? sessionChronologicalOverride,
  ]) {
    final msgs = _listMessagesForUi(chat, sessionChronologicalOverride);
    final out = <RoomItem>[];
    for (var i = 0; i < msgs.length; i++) {
      if (i == 0 ||
          msgs[i].timestamp.difference(msgs[i - 1].timestamp) >
              const Duration(minutes: 5)) {
        out.add(RoomItem.time(
          formatChatTime(msgs[i].timestamp),
          firstMsgId: msgs[i].msgId,
        ));
      }
      out.add(RoomItem.msg(msgs[i]));
    }
    return out;
  }

  /// 与 [_flatItems] 同一批格子，顺序为 **新→旧**（index 0 = 时间上最新一行），
  /// 配合 [ListView.reverse] 后视觉上仍是 **上旧下新**。
  List<RoomItem> _flatItemsNewestFirst(
    ChatProvider chat, [
    List<ChatMessage>? sessionChronologicalOverride,
  ]) {
    final c = _flatItems(chat, sessionChronologicalOverride);
    if (c.isEmpty) return c;
    return c.reversed.toList(growable: false);
  }

  int? _indexOfRoomItemForMsg(List<RoomItem> items, String msgId) {
    final t = msgId.trim();
    for (var i = 0; i < items.length; i++) {
      final it = items[i];
      if (!it.isTime &&
          !it.isPagingLoad &&
          it.msg != null &&
          it.msg!.msgId.trim() == t) {
        return i;
      }
    }
    return null;
  }

  List<RoomItem> _listItemsForMessageList(ChatProvider chat) {
    if (!_messageListVisible) return const [];
    var items = _flatItemsNewestFirst(chat);
    if (_pagingLoadingNewer) {
      items = [
        RoomItem.pagingLoad(RoomPagingLoadKind.newerEdge),
        ...items,
      ];
    }
    // 拉更旧：loading 不在列表末尾插入（reverse 下会出现在视口上方，用户看不到），改在列表区 Stack 顶部覆盖层展示。
    return items;
  }

  /// [ListView] 数据为 [_flatItemsNewestFirst] 时的行下标（含时间分隔行）。
  int? _indexOfRoomItemForMsgNewestFirst(ChatProvider chat, String msgId) {
    return _indexOfRoomItemForMsg(_flatItemsNewestFirst(chat), msgId);
  }

  /// 仅高亮锚点气泡，不驱动 [GvChatMessageList] 滚动。
  void _highlightAnchorMessage(String msgId) {
    if (!mounted) return;
    setState(() => _highlightAnchorMsgId = msgId);
    Future<void>.delayed(const Duration(milliseconds: 2600), () {
      if (!mounted) return;
      if (_highlightAnchorMsgId == msgId) {
        setState(() => _highlightAnchorMsgId = null);
      }
    });
  }

  /// 搜索/路由锚点进房：先保持 reverse 列表默认偏移（窗口内最新几条在底），再 [Scrollable.ensureVisible] 滚到锚点。
  void _scrollToAnchorMessage(String msgId) {
    void releaseListPaging() {
      Future<void>.delayed(const Duration(milliseconds: 480), () {
        if (mounted) setState(() => _suppressListPaging = false);
      });
    }

    final id = msgId.trim();
    final chat = context.read<ChatProvider>();
    if (_indexOfRoomItemForMsgNewestFirst(chat, id) == null) {
      // 历史可能尚未加载完成（尤其推送点击进房时 loadHistory/锚点窗口还在请求中），
      // 立即报「未找到该消息」会误伤——延迟重试等待加载，超时才报。
      _retryAnchorScrollUntilLoaded(msgId, attempts: 0);
      return;
    }

    var passes = 0;

    /// 锚点气泡挂了 [_anchorNavTileKey]；[ListView.builder] 懒加载，屏外子项可能尚未 build，
    /// 此时 [GlobalKey.currentContext] 为 null，不能直接 [Scrollable.ensureVisible]。
    /// 本闭包在每帧末重试：一旦有 context 则滚到可视区、高亮并 [releaseListPaging]；
    /// 超过重试帧数上限仍无 context 则放弃滚动，仅恢复分页。
    void tryEnsureVisible() {
      if (!mounted) return;
      final ctx = _anchorNavTileKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.35,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
        if (mounted) _highlightAnchorMessage(id);
        if (mounted) releaseListPaging();
        return;
      }
      if (passes < 24) {
        passes++;
        WidgetsBinding.instance.addPostFrameCallback((_) => tryEnsureVisible());
      } else if (mounted) {
        releaseListPaging();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => tryEnsureVisible());
  }

  /// 锚点消息暂不在本地时延迟重试，等待历史/锚点窗口加载完成后再定位。
  /// 超过约 6 秒仍未加载到则**静默降级**：不弹「未找到该消息」，直接停留在
  /// 会话最新消息（推送/搜索点击的入口语义是进入会话，定位是尽力而为——
  /// 业界成熟做法，避免因定位失败阻断用户进入会话）。
  void _retryAnchorScrollUntilLoaded(String msgId, {required int attempts}) {
    const maxAttempts = 20;
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final chat = context.read<ChatProvider>();
      final id = msgId.trim();
      if (_indexOfRoomItemForMsgNewestFirst(chat, id) != null) {
        _scrollToAnchorMessage(id);
        return;
      }
      if (attempts + 1 < maxAttempts) {
        _retryAnchorScrollUntilLoaded(msgId, attempts: attempts + 1);
        return;
      }
      // 锚点不可达（服务端无该消息/历史定位失败）：静默降级到最新消息，不报错。
      Future<void>.delayed(const Duration(milliseconds: 480), () {
        if (mounted) setState(() => _suppressListPaging = false);
      });
    });
  }

  /// 列表可见后处理 [ChatRoomScreen.anchorMsgId]：滚到目标并高亮。
  void _scheduleInitialScrollOrAnchor() {
    void tick(Duration _) {
      if (!mounted) return;
      if (!_messageListVisible) {
        WidgetsBinding.instance.addPostFrameCallback(tick);
        return;
      }
      final anchor = widget.anchorMsgId?.trim();
      if (anchor != null && anchor.isNotEmpty) {
        _scrollToAnchorMessage(anchor);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(tick);
  }

  /// 与 [_noMoreNewer] 同步：向新方向仍有未加载页时禁止实时消息写入 [ChatProvider.messageMap]。
  void _syncAllowRealtimeMergeIntoList(ChatProvider chat) {
    chat.setAllowRealtimeMergeIntoCurrentChatList(_noMoreNewer);
  }

  /// 进房后拉好友/群资料与历史；在 [转场结束、列表可建] 之后启动，避免与 [addPostFrameCallback] 首帧叠加大块网络与 [notifyListeners]。
  ///
  /// 消息并非写在 [scheduleFrameCallback] 里，而是由 [ChatProvider.loadHistory] / [replaceSessionWithAnchorWindow] 内 [notifyListeners] 写入。
  Future<void> _bootstrapRoomHistoryLoad() async {
    if (!mounted || _roomHistoryBootstrapStarted) return;
    _roomHistoryBootstrapStarted = true;

    final anchor = widget.anchorMsgId?.trim() ?? '';
    final hasAnchor = anchor.isNotEmpty;

    final chat = context.read<ChatProvider>();
    // 先于任意 await 绑定当前会话，避免 loadFriends～首包历史 期间 currentChatId 未就绪。
    chat.openChat(widget.peerId, widget.chatType);
    await chat.loadCachedMessages(widget.peerId, widget.chatType);
    if (!mounted) return;

    final f = context.read<FriendProvider>();
    final g = context.read<GroupProvider>();
    final prefetch = <Future<void>>[];
    // 始终刷新好友列表：仅“为空才加载”会在好友缓存过期时，让好友成员显示成「用户{id}」。
    prefetch.add(f.loadFriends().catchError((_, __) {}));
    if (g.groups.isEmpty) prefetch.add(g.loadGroups());
    if (prefetch.isNotEmpty) await Future.wait(prefetch);
    if (!mounted) return;

    if (widget.chatType == 'group') {
      final gid = int.tryParse(widget.peerId);
      if (gid != null) await g.loadMembers(gid);
    }
    if (!mounted) return;

    final name = _title(chat, f, g, AppLocalizations.of(context)!);
    final fd = f.getFriendDisplay(int.tryParse(widget.peerId) ?? 0);
    chat.openChat(
      widget.peerId,
      widget.chatType,
      name: name,
      avatar: widget.chatType == 'private' ? fd?.avatar ?? '' : null,
    );
    final anchorAlreadyInSession = hasAnchor &&
        chat
            .messagesFor(widget.peerId, widget.chatType)
            .any((m) => m.msgId == anchor);
    // 锚点窗口尚未成功返回前保留缓存消息。此前这里会先清空列表，网络错误、
    // 旧服务端不支持 centerMsgId 或目标消息不存在时，页面就会从“短暂有历史”
    // 变成永久空白。
    if (!hasAnchor) {
      final r = await chat.loadHistory(widget.peerId, widget.chatType);
      if (!mounted) return;
      final seed = widget.anchorSeedMessage;
      if (seed != null) {
        await chat.mergeMessageIfAbsent(widget.peerId, widget.chatType, seed);
      }
      if (!mounted) return;
      setState(() {
        _noMoreOlder = r.serverCount == 0 ||
            (r.serverCount < _kHistoryPageSize && r.added == r.serverCount);
        _noMoreNewer = true;
      });
    } else if (anchorAlreadyInSession) {
      _suppressListPaging = true;
      final seed = widget.anchorSeedMessage;
      final anchorResult = await chat.replaceSessionWithAnchorWindow(
        widget.peerId,
        widget.chatType,
        anchor,
        ensurePresent: seed,
        beforeCount: _kAnchorHistoryHalfCount,
        afterCount: _kAnchorHistoryHalfCount,
      );
      if (!mounted) return;
      setState(() {
        _noMoreOlder = anchorResult.noMoreOlder;
        _noMoreNewer = anchorResult.noMoreNewer;
        _showNewMessagesFloatingChip = false;
        _newMessageChipBaselineReady = false;
      });
    } else {
      _suppressListPaging = true;
      final seed = widget.anchorSeedMessage;
      final anchorResult = await chat.replaceSessionWithAnchorWindow(
        widget.peerId,
        widget.chatType,
        anchor,
        ensurePresent: seed,
        beforeCount: _kAnchorHistoryHalfCount,
        afterCount: _kAnchorHistoryHalfCount,
      );
      if (!mounted) return;
      setState(() {
        _noMoreOlder = anchorResult.noMoreOlder;
        _noMoreNewer = anchorResult.noMoreNewer;
        _showNewMessagesFloatingChip = false;
        _newMessageChipBaselineReady = false;
      });
    }
    if (!mounted) return;
    _syncAllowRealtimeMergeIntoList(chat);
    final myId = chat.myId;
    if (myId != null) {
      final unread = chat
          .messagesFor(widget.peerId, widget.chatType)
          .where((m) => m.from != myId && m.status != 'read')
          .map((m) => m.msgId)
          .toList();
      chat.markRead(unread, peerId: widget.peerId, chatType: widget.chatType);
    }
    if (mounted) {
      _scheduleInitialScrollOrAnchor();
    }
  }

  @override
  void didUpdateWidget(covariant ChatRoomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.peerId != widget.peerId ||
        oldWidget.chatType != widget.chatType) {
      try {
        context.read<ChatProvider>().flushDeferredRealtimeIfMatches(
              oldWidget.peerId,
              oldWidget.chatType,
            );
      } catch (_) {}
      _roomHistoryBootstrapStarted = false;
      _historyPaging = false;
      _pagingLoadingOlder = false;
      _pagingLoadingNewer = false;
      _noMoreOlder = false;
      _noMoreNewer = true;
      _suppressListPaging = false;
      _pagingMeasureSegment = const [];
      _showNewMessagesFloatingChip = false;
      _lastSeenRealtimeIngestEpoch = 0;
      _newMessageChipBaselineReady = false;
      _pendingImageDraft = null;
      _pendingImageSending = false;
      _imageCaptionController.clear();
      _imageCaptionFocus.unfocus();
      _channelInfo = null;
      _secretChat = null;
      _secretGroupChat = null;
      try {
        _syncAllowRealtimeMergeIntoList(context.read<ChatProvider>());
      } catch (_) {}
    }
  }

  /// 与 [preparePagingHistoryMerge] 成对：测高结束后再写入 [ChatProvider.messageMap]。
  Future<void> _commitPreparedPagingHistoryMerge(
    ChatProvider chat,
    PreparedPagingHistoryMerge prepared,
  ) async {
    if (prepared.mergedForMeasure == null) return;
    await chat.commitPagingHistoryMerge(
      widget.peerId,
      widget.chatType,
      prepared.parsedMessages,
      beforeMsgId: prepared.beforeMsgId,
      afterMsgId: prepared.afterMsgId,
      suppressPagingNotify: true,
    );
  }

  Future<void> _loadOlderPageForList() async {
    if (_historyPaging) return;
    final chat = context.read<ChatProvider>();
    final session = chat.messagesFor(widget.peerId, widget.chatType);
    final oldest = session.isNotEmpty ? session.first.msgId : null;
    if (oldest == null) return;

    final flatBefore = List<RoomItem>.from(_flatItemsNewestFirst(chat));
    _abortPagingViewportCompensation = false;
    setState(() {
      _historyPaging = true;
      _pagingLoadingOlder = true;
    });
    try {
      final prepared = await chat.preparePagingHistoryMerge(
        widget.peerId,
        widget.chatType,
        beforeMsgId: oldest,
      );
      if (!mounted) {
        await _commitPreparedPagingHistoryMerge(chat, prepared);
        return;
      }
      final page = prepared.page;
      final reachedEndOfOlder = page.serverCount == 0 ||
          (page.serverCount < _kHistoryPageSize &&
              page.added == page.serverCount);
      if (page.added == 0) {
        setState(() {
          if (reachedEndOfOlder) _noMoreOlder = true;
        });
        await _commitPreparedPagingHistoryMerge(chat, prepared);
        if (!mounted) return;
        chat.notifyAfterHistoryPagingMerge();
        return;
      }

      if (prepared.mergedForMeasure == null) {
        setState(() {
          if (reachedEndOfOlder) _noMoreOlder = true;
        });
        await _commitPreparedPagingHistoryMerge(chat, prepared);
        if (!mounted) return;
        chat.notifyAfterHistoryPagingMerge();
        return;
      }

      final flatAfter = _flatItemsNewestFirst(chat, prepared.mergedForMeasure!);
      if (flatAfter.length <= flatBefore.length) {
        setState(() {
          if (reachedEndOfOlder) _noMoreOlder = true;
        });
        await _commitPreparedPagingHistoryMerge(chat, prepared);
        if (!mounted) return;
        chat.notifyAfterHistoryPagingMerge();
        return;
      }

      if (!mounted) {
        await _commitPreparedPagingHistoryMerge(chat, prepared);
        chat.notifyAfterHistoryPagingMerge();
        return;
      }

      await _commitPreparedPagingHistoryMerge(chat, prepared);
      if (!mounted) return;

      setState(() {
        if (reachedEndOfOlder) _noMoreOlder = true;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        chat.notifyAfterHistoryPagingMerge();
      });
    } finally {
      if (mounted) {
        setState(() {
          _historyPaging = false;
          _pagingLoadingOlder = false;
        });
      } else {
        _historyPaging = false;
        _pagingLoadingOlder = false;
      }
    }
  }

  Future<void> _loadMoreNewer() async {
    if (_historyPaging) return;
    final chat = context.read<ChatProvider>();
    final session = chat.messagesFor(widget.peerId, widget.chatType);
    if (session.isEmpty) return;
    final tailBeforeId = session.last.msgId.trim();

    final flatBefore = List<RoomItem>.from(_flatItemsNewestFirst(chat));
    _abortPagingViewportCompensation = false;
    setState(() {
      _historyPaging = true;
      _pagingLoadingNewer = true;
    });
    try {
      final prepared = await chat.preparePagingHistoryMerge(
        widget.peerId,
        widget.chatType,
        afterMsgId: tailBeforeId,
      );
      if (!mounted) {
        await _commitPreparedPagingHistoryMerge(chat, prepared);
        return;
      }
      final page = prepared.page;
      final reachedEndOfNewer = page.serverCount == 0 ||
          (page.serverCount < _kHistoryPageSize &&
              page.added == page.serverCount);
      if (page.added == 0) {
        setState(() {
          if (reachedEndOfNewer) _noMoreNewer = true;
          _noMoreOlder = false;
        });
        await _commitPreparedPagingHistoryMerge(chat, prepared);
        if (!mounted) return;
        chat.notifyAfterHistoryPagingMerge();
        _syncAllowRealtimeMergeIntoList(chat);
        return;
      }

      if (prepared.mergedForMeasure == null) {
        setState(() {
          if (reachedEndOfNewer) _noMoreNewer = true;
          _noMoreOlder = false;
        });
        await _commitPreparedPagingHistoryMerge(chat, prepared);
        if (!mounted) return;
        chat.notifyAfterHistoryPagingMerge();
        _syncAllowRealtimeMergeIntoList(chat);
        return;
      }

      final flatAfter = _flatItemsNewestFirst(chat, prepared.mergedForMeasure!);
      if (flatAfter.length <= flatBefore.length) {
        setState(() {
          if (reachedEndOfNewer) _noMoreNewer = true;
          _noMoreOlder = false;
        });
        await _commitPreparedPagingHistoryMerge(chat, prepared);
        if (!mounted) return;
        chat.notifyAfterHistoryPagingMerge();
        _syncAllowRealtimeMergeIntoList(chat);
        return;
      }

      final segment =
          flatAfter.sublist(0, flatAfter.length - flatBefore.length);
      final insertHeight = await _measurePagingInsertHeight(segment);

      if (!mounted) {
        await _commitPreparedPagingHistoryMerge(chat, prepared);
        chat.notifyAfterHistoryPagingMerge();
        return;
      }

      await _commitPreparedPagingHistoryMerge(chat, prepared);
      if (!mounted) return;

      setState(() {
        if (reachedEndOfNewer) _noMoreNewer = true;
        _noMoreOlder = false;
      });

      if (insertHeight > 0.5 && !_abortPagingViewportCompensation) {
        _msgListController.applyInsertHeightViewportCompensation(insertHeight);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        chat.notifyAfterHistoryPagingMerge();
      });
      _syncAllowRealtimeMergeIntoList(chat);
    } finally {
      if (mounted) {
        setState(() {
          _historyPaging = false;
          _pagingLoadingNewer = false;
        });
      } else {
        _historyPaging = false;
        _pagingLoadingNewer = false;
      }
    }
  }

  Future<void> _discardTempVoiceFile(String path) async {
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  void _removeVoiceRecordingOverlay() {
    _stopVoiceAmplitudeTracking();
    _voiceOverlayEntry?.remove();
    _voiceOverlayEntry = null;
    _voiceOverlaySetState = null;
  }

  void _startVoiceAmplitudeTracking() {
    _stopVoiceAmplitudeTracking();
    _voiceWaveLevels = List<double>.filled(_kVoiceWaveBarCount, 0.12);
    _voiceAmplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amplitude) {
      if (!_recording || !amplitude.current.isFinite) return;

      // dBFS 通常落在 -60 到 0 之间；压缩动态范围，让轻声也能得到可见反馈。
      final normalized =
          ((amplitude.current + 55) / 55).clamp(0.0, 1.0).toDouble();
      final shaped = math.pow(normalized, 0.65).toDouble();
      final previous = _voiceWaveLevels.last;
      final level =
          (previous * 0.35 + shaped * 0.65).clamp(0.12, 1.0).toDouble();

      _voiceWaveLevels = <double>[
        ..._voiceWaveLevels.skip(1),
        level,
      ];
      _voiceOverlaySetState?.call(() {});
    }, onError: (_) {});
  }

  void _stopVoiceAmplitudeTracking() {
    final subscription = _voiceAmplitudeSubscription;
    _voiceAmplitudeSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
  }

  void _showVoiceRecordingOverlay() {
    _voicePointerInCancel = false;
    _voiceOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return StatefulBuilder(
          builder: (context, overlaySetState) {
            _voiceOverlaySetState = overlaySetState;
            return _buildVoiceRecordingOverlay(overlayContext);
          },
        );
      },
    );
    Overlay.of(context).insert(_voiceOverlayEntry!);
  }

  /// 上划超过阈值即进入取消态（参考微信：无独立取消按钮区，按手指位移判断）。
  void _onVoicePointerMove(
      PointerMoveEvent event, BuildContext? receiverContext) {
    if (event.pointer != _voiceActivePointerId) return;
    final inCancel =
        (_voiceStartGlobalY - event.position.dy) > _kVoiceCancelSlideUpDistance;
    if (inCancel != _voicePointerInCancel) {
      _voicePointerInCancel = inCancel;
      _voiceOverlaySetState?.call(() {});
    }
  }

  void _onVoicePointerUpFromHold(PointerEvent event) {
    if (_recording) {
      unawaited(_onVoiceOverlayPointerEnd(event));
    } else {
      if (event.pointer == _voiceActivePointerId) {
        _voiceAbortBeforeStart = true;
      }
    }
  }

  Future<void> _onVoiceOverlayPointerEnd(PointerEvent event) async {
    if (event.pointer != _voiceActivePointerId) return;
    _voiceActivePointerId = null;

    final releaseInCancel = _voicePointerInCancel;
    _voicePointerInCancel = false;
    final path = _voiceTempPath;
    final startedAt = _voiceRecordStartedAt;
    final webVoiceExt = _voiceWebUploadExt;
    _voiceTempPath = null;
    _voiceRecordStartedAt = null;
    _voiceWebUploadExt = null;

    if (mounted) setState(() => _recording = false);
    _removeVoiceRecordingOverlay();

    String? stoppedPath;
    try {
      stoppedPath = await _audioRecorder.stop();
    } catch (_) {}

    final filePath = stoppedPath ?? path;
    if (filePath == null) return;

    final ms = startedAt != null
        ? DateTime.now().difference(startedAt).inMilliseconds
        : 0;

    if (releaseInCancel || ms < _kMinVoiceRecordMs) {
      if (!kIsWeb) {
        try {
          final f = File(filePath);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      return;
    }

    if (kIsWeb && filePath.startsWith('blob:')) {
      try {
        if (!mounted) return;
        final bytes = (await context.read<ApiClient>().dio.get<List<int>>(
                  filePath,
                  options: Options(responseType: ResponseType.bytes),
                ))
            .data;
        if (!mounted || bytes == null || bytes.isEmpty) return;
        await _uploadAndSend(
          'voice',
          File(filePath),
          voiceDurationSec: math.max(1, (ms / 1000).ceil()),
          voiceBytesWeb: bytes,
          voiceFilenameWeb:
              'voice_${DateTime.now().millisecondsSinceEpoch}.${webVoiceExt ?? 'webm'}',
        );
      } catch (e) {
        if (mounted) {
          GvToast.show(
            context,
            AppLocalizations.of(context)!
                .toastVoiceRecordStartFailed(ApiFailure.messageOf(e)),
          );
        }
      }
      return;
    }

    try {
      final f = File(filePath);
      if (mounted) {
        await _uploadAndSend(
          'voice',
          f,
          voiceDurationSec: math.max(1, (ms / 1000).ceil()),
        );
      }
    } catch (_) {
      try {
        final f = File(filePath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }

  static String _voiceFilenameExtension(AudioEncoder encoder) {
    return switch (encoder) {
      AudioEncoder.opus => 'webm',
      AudioEncoder.wav => 'wav',
      AudioEncoder.pcm16bits => 'wav',
      _ => 'm4a',
    };
  }

  /// Web 上 [MediaRecorder] 对 AAC 支持很差，按能力选用 opus / pcm / wav / aac。
  Future<AudioEncoder?> _pickWebVoiceEncoder() async {
    const order = <AudioEncoder>[
      AudioEncoder.opus,
      AudioEncoder.pcm16bits,
      AudioEncoder.wav,
      AudioEncoder.aacLc,
    ];
    for (final e in order) {
      if (await _audioRecorder.isEncoderSupported(e)) return e;
    }
    return null;
  }

  Future<void> _voiceHoldPointerDown(PointerDownEvent event) async {
    if (_recording || event.buttons != kPrimaryButton) return;
    if (_voiceActivePointerId != null) return;

    _voiceActivePointerId = event.pointer;
    _voiceStartGlobalY = event.position.dy;
    _voiceAbortBeforeStart = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_refreshTailIfStaleForComposer());
    });

    // Web：`record_web` 用 Permissions API 预检麦克风，Safari 等环境易误报未授权；
    // 真实授权发生在 start() → getUserMedia，故不在 Web 上挡在 hasPermission。
    final permitted = kIsWeb ? true : await _audioRecorder.hasPermission();
    if (!mounted || _voiceAbortBeforeStart) {
      _voiceActivePointerId = null;
      return;
    }
    if (!permitted) {
      _voiceActivePointerId = null;
      if (mounted) {
        GvToast.show(
          context,
          AppLocalizations.of(context)!.toastMicPermissionRequired,
        );
      }
      return;
    }

    late final AudioEncoder voiceEncoder;
    if (kIsWeb) {
      final picked = await _pickWebVoiceEncoder();
      if (!mounted || _voiceAbortBeforeStart) {
        _voiceActivePointerId = null;
        return;
      }
      if (picked == null) {
        _voiceActivePointerId = null;
        if (mounted) {
          GvToast.show(
            context,
            AppLocalizations.of(context)!.toastVoiceWebNoEncoder,
          );
        }
        return;
      }
      voiceEncoder = picked;
    } else {
      voiceEncoder = AudioEncoder.aacLc;
    }

    try {
      // path_provider 未实现 Web；record 在 Web 上忽略 [path]，仅占位。
      final ext = _voiceFilenameExtension(voiceEncoder);
      final path = kIsWeb
          ? 'voice_${genClientMsgId()}.$ext'
          : '${(await getTemporaryDirectory()).path}/voice_${genClientMsgId()}.m4a';
      await _audioRecorder.start(
        RecordConfig(encoder: voiceEncoder),
        path: path,
      );
      if (!mounted || _voiceAbortBeforeStart) {
        await _audioRecorder.stop();
        if (!kIsWeb) {
          final f = File(path);
          if (await f.exists()) await f.delete();
        }
        _voiceActivePointerId = null;
        return;
      }
      _voiceTempPath = path;
      if (kIsWeb) _voiceWebUploadExt = ext;
      _voiceRecordStartedAt = DateTime.now();
      if (mounted) setState(() => _recording = true);
      _showVoiceRecordingOverlay();
      _startVoiceAmplitudeTracking();
    } catch (e) {
      _voiceActivePointerId = null;
      if (mounted) {
        GvToast.show(
          context,
          AppLocalizations.of(context)!
              .toastVoiceRecordStartFailed(ApiFailure.messageOf(e)),
        );
      }
    }
  }

  Widget _buildVoiceRecordingOverlay(BuildContext overlayContext) {
    final l10n = AppLocalizations.of(overlayContext)!;
    final mq = MediaQuery.of(overlayContext);

    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Listener(
              key: _voiceOverlayListenerKey,
              behavior: HitTestBehavior.translucent,
              onPointerMove: (e) => _onVoicePointerMove(
                  e, _voiceOverlayListenerKey.currentContext),
              onPointerUp: (e) => unawaited(_onVoiceOverlayPointerEnd(e)),
              onPointerCancel: (e) => unawaited(_onVoiceOverlayPointerEnd(e)),
              child: Container(color: const Color(0xBF000000)),
            ),
          ),
          Positioned(
            left: GvSpacing.page,
            right: GvSpacing.page,
            bottom: mq.padding.bottom + 202,
            child: IgnorePointer(
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 224,
                  height: 72,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.34),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: (_voicePointerInCancel
                              ? AppColors.danger.resolveFrom(context)
                              : Colors.white)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _voicePointerInCancel
                              ? AppColors.danger.resolveFrom(context)
                              : Colors.white.withValues(alpha: 0.16),
                        ),
                        child: Icon(
                          _voicePointerInCancel
                              ? LucideIcons.x
                              : LucideIcons.mic,
                          size: 19,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List<Widget>.generate(
                              _voiceWaveLevels.length,
                              (index) {
                                final centerDistance =
                                    (index - (_voiceWaveLevels.length - 1) / 2)
                                        .abs();
                                final envelope = (1 - centerDistance / 16)
                                    .clamp(0.58, 1.0)
                                    .toDouble();
                                final height =
                                    5 + _voiceWaveLevels[index] * 34 * envelope;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 90),
                                  curve: Curves.easeOut,
                                  width: 3,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: (_voicePointerInCancel
                                            ? AppColors.danger
                                                .resolveFrom(context)
                                            : Colors.white)
                                        .withValues(
                                      alpha: _voicePointerInCancel ? 0.72 : 0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: GvSpacing.page,
            right: GvSpacing.page,
            bottom: mq.padding.bottom + 28,
            child: IgnorePointer(
              child: Text(
                _voicePointerInCancel
                    ? l10n.chatVoiceReleaseToCancel
                    : l10n.chatVoiceReleaseToSend,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: GvTypographyScale.bodySmall,
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 2,
                      color: Color(0x59000000),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _uploadAndSend(
    String msgType,
    File file, {
    String? displayName,
    int? voiceDurationSec,
    List<int>? voiceBytesWeb,
    String? voiceFilenameWeb,
    List<int>? imageBytesWeb,
    String? imageFilenameWeb,
    List<int>? fileBytesWeb,
    String? fileFilenameWeb,
    String imageCaption = '',
  }) async {
    if (!_ensureChatFeatureAllowed()) return false;
    final upload = context.read<ClientRemoteConfigProvider>().upload;

    final int len;
    if (voiceBytesWeb != null) {
      len = voiceBytesWeb.length;
    } else if (imageBytesWeb != null) {
      len = imageBytesWeb.length;
    } else if (fileBytesWeb != null) {
      len = fileBytesWeb.length;
    } else {
      len = await file.length();
    }
    if (!mounted) return false;
    final maxBytes = switch (msgType) {
      'image' => upload.maxImageSizeMB * 1024 * 1024,
      'video' => upload.maxVideoSizeMB * 1024 * 1024,
      _ => upload.maxFileSizeMB * 1024 * 1024,
    };
    if (len > maxBytes) {
      final mb = (maxBytes / (1024 * 1024)).round();
      GvToast.show(
        context,
        AppLocalizations.of(context)!.toastFileExceedsLimit(mb),
      );
      return false;
    }

    final api = context.read<ImApi>();
    final chat = context.read<ChatProvider>();

    String? outboundMediaDraftId;
    // 私密聊天不走普通通道的「发送中」占位（无 WS ack，会永久 sending）；
    // 上传完成后直接走加密通道，本地乐观插入非 sending 消息。
    final isSecretChat = widget.chatType == 'secret';
    if (!isSecretChat &&
        (msgType == 'image' || msgType == 'video' || msgType == 'voice')) {
      outboundMediaDraftId = chat.appendOutboundSendingMediaDraft(
        widget.peerId,
        widget.chatType,
        msgType,
        gvChatPendingMediaUploadContent,
        replyMsgId: _replyTo?.msgId,
      );
      if (outboundMediaDraftId == null) return false;
    }

    try {
      final name = voiceBytesWeb != null
          ? (voiceFilenameWeb ?? displayName ?? 'voice.webm')
          : imageBytesWeb != null
              ? (imageFilenameWeb ??
                  displayName ??
                  'image_${DateTime.now().millisecondsSinceEpoch}.jpg')
              : fileBytesWeb != null
                  ? (fileFilenameWeb ?? displayName ?? 'attachment')
                  : (displayName ??
                      file.path.split(Platform.pathSeparator).last);

      var videoUploadFile = file;
      int? videoDurationMs;
      if (msgType == 'video') {
        videoDurationMs = await gvReadVideoDurationMs(file);
        if (videoDurationMs == null) {
          throw StateError('无法读取视频时长');
        }
        videoUploadFile = await gvPrepareChatVideoForUpload(file);
      }

      File imageBody = file;
      Uint8List? imageBytesPrepared;
      if (msgType == 'image') {
        if (imageBytesWeb != null) {
          final Uint8List raw = imageBytesWeb is Uint8List
              ? imageBytesWeb
              : Uint8List.fromList(imageBytesWeb);
          imageBytesPrepared = await gvPrepareChatImageBytesForUpload(raw);
        } else {
          imageBody = await gvPrepareChatImageForUpload(file);
        }
      }

      var uploadName = name;
      if (msgType == 'image') {
        if (imageBytesPrepared != null) {
          uploadName = uploadFilenameForMimeType(
            name,
            uploadMimeTypeForBytes(imageBytesPrepared, name),
          );
        } else if (imageBody.path != file.path) {
          // gvPrepareChatImageForUpload creates a JPEG when it returns a new
          // file, so its upload name must no longer carry the source extension.
          uploadName = uploadFilenameForMimeType(name, 'image/jpeg');
        }
      }

      (int, int)? imageDimPrepared;
      if (msgType == 'image') {
        if (imageBytesPrepared != null) {
          imageDimPrepared =
              await gvDecodeImageSizeFromBytes(imageBytesPrepared);
        } else {
          imageDimPrepared = await gvDecodeImageSize(imageBody);
        }
      }

      late final MediaUploadResult uploaded;
      try {
        if (voiceBytesWeb != null) {
          uploaded = await api.uploadBytes(
            voiceBytesWeb,
            name,
            mediaKind: 'audio',
            durationMs: (voiceDurationSec ?? 1) * 1000,
          );
        } else if (msgType == 'image' && imageBytesPrepared != null) {
          uploaded = await api.uploadBytes(
            imageBytesPrepared,
            uploadName,
            mediaKind: 'image',
          );
        } else if (msgType == 'image') {
          uploaded = await api.uploadFile(
            imageBody.path,
            uploadName,
            mediaKind: 'image',
          );
        } else if (msgType == 'file' && fileBytesWeb != null) {
          uploaded = await api.uploadBytes(
            fileBytesWeb,
            name,
            mediaKind: 'attachment',
          );
        } else {
          uploaded = await api.uploadFile(
            msgType == 'video' ? videoUploadFile.path : file.path,
            name,
            mediaKind: switch (msgType) {
              'voice' => 'audio',
              'video' => 'video',
              _ => 'attachment',
            },
            durationMs: msgType == 'voice'
                ? (voiceDurationSec ?? 1) * 1000
                : videoDurationMs,
          );
        }
      } finally {
        if (voiceBytesWeb == null &&
            msgType == 'image' &&
            imageBytesPrepared == null &&
            imageBody.path != file.path) {
          await gvTryDeleteFile(imageBody);
        }
        if (voiceBytesWeb == null &&
            msgType == 'video' &&
            videoUploadFile.path != file.path) {
          await gvTryDeleteFile(videoUploadFile);
        }
      }

      var stored = uploaded.url;

      if (msgType == 'image') {
        final dim = imageDimPrepared;
        stored = encodeImageForChat(
          storedUrl: stored,
          caption: imageCaption,
          w: dim?.$1,
          h: dim?.$2,
        );
      }

      if (msgType == 'file') {
        final content = jsonEncode({'name': name, 'url': stored});
        if (widget.chatType == 'secret') {
          unawaited(_sendSecretText(
            chat,
            content,
            msgType: 'file',
            mediaObjectIds: [uploaded.objectId],
            convPreview: name,
          ));
        } else {
          chat.sendMessage(
            widget.peerId,
            widget.chatType,
            'file',
            content,
            replyMsgId: _replyTo?.msgId,
            mediaObjectIds: [uploaded.objectId],
            wireContent: name,
          );
        }
      } else if (widget.chatType == 'secret') {
        // 私密聊天：媒体消息走加密通道（密文载荷含媒体对象 id）。
        unawaited(_sendSecretText(
          chat,
          stored,
          msgType: msgType,
          mediaObjectIds: [uploaded.objectId],
          convPreview: msgType == 'image' ? imageCaption : '',
        ));
      } else if (outboundMediaDraftId != null) {
        chat.finalizeOutboundSendingMediaDraft(
          clientMsgId: outboundMediaDraftId,
          toId: widget.peerId,
          chatType: widget.chatType,
          finalContent: stored,
          mediaObjectIds: [uploaded.objectId],
          wireContent: msgType == 'image' ? imageCaption : '',
        );
      } else {
        chat.sendMessage(
          widget.peerId,
          widget.chatType,
          msgType,
          stored,
          replyMsgId: _replyTo?.msgId,
          mediaObjectIds: [uploaded.objectId],
          wireContent: msgType == 'image' ? imageCaption : '',
        );
      }

      outboundMediaDraftId = null;

      if (mounted) {
        setState(() => _replyTo = null);
      }
      return true;
    } catch (e, st) {
      final failedDraftId = outboundMediaDraftId;
      if (failedDraftId != null) {
        chat.discardOutboundSendingMediaDraft(
          clientMsgId: failedDraftId,
          toId: widget.peerId,
          chatType: widget.chatType,
        );
      }
      if (mounted) {
        final message = context.read<ApiClient>().extractErrorMessage(e);
        GvToast.show(
          context,
          message,
        );
      }
      debugPrint('_uploadAndSend failed: $e\n$st');
      return false;
    }
  }

  void _closeComposerPanel() =>
      _roomBottomKey.currentState?.closeComposerPanel();

  /// 点击聊天区域（列表/输入条以上）：收起面板并关掉键盘。
  void _dismissComposerPanelsAndKeyboard() {
    _roomBottomKey.currentState?.dismissPanelsAndKeyboard();
  }

  void _onComposerFocusGained() {
    final recentSend = _lastTextSendAt != null &&
        DateTime.now().difference(_lastTextSendAt!) <
            const Duration(milliseconds: 450);
    if (!recentSend) {
      _scheduleScrollMessageListToBottomForChrome();
    }
  }

  void _scheduleScrollMessageListToBottomForChrome() {
    _scrollToBottomForChromeDebounce?.cancel();
    _scrollToBottomForChromeDebounce =
        Timer(const Duration(milliseconds: 60), () {
      _scrollToBottomForChromeDebounce = null;
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpMessageListToVisualBottom();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _jumpMessageListToVisualBottom();
          _tryDismissNewMessageFloatingChipIfCaughtUp();
        });
      });
    });
  }

  Conversation? _conversationForRoom(ChatProvider chat) {
    for (final c in chat.conversations) {
      if (c.id == widget.peerId && c.chatType == widget.chatType) {
        return c;
      }
    }
    return null;
  }

  /// 当前列表最后一条是否**还不是**本聊天室全局最新消息：是则按重新进房拉整会话最新 [_kHistoryPageSize] 条。
  ///
  /// 含：向新仍有未加载页、[deferredRealtimeSessionInsert] 未写入、会话 [lastTime] 严格新于列表尾部、有预览但内存无条等。
  ///
  /// **搜索锚点进房**同样参与判断：锚点窗「底部」只是当前窗口内最新，若会话行仍更新（或向新仍有页），须拉无游标最新 30 条，否则会只滚到 #42 这类窗口底而非全局最新。
  bool _shouldReenterRoomFetchLatest30(ChatProvider chat) {
    final d = chat.deferredRealtimeSessionInsert;
    if (d != null &&
        d.peerId == widget.peerId &&
        d.chatType == widget.chatType) {
      return true;
    }

    if (!_noMoreNewer) return true;

    final conv = _conversationForRoom(chat);
    final msgs = _listMessagesForUi(chat);

    if (msgs.isEmpty) {
      if (conv == null) return false;
      return conv.lastMessage.trim().isNotEmpty;
    }
    if (conv == null) return false;
    return conv.lastTime.isAfter(msgs.last.timestamp);
  }

  bool _isActiveChatRoom(ChatProvider chat) {
    return chat.currentChatId == widget.peerId &&
        chat.currentChatType == widget.chatType;
  }

  /// [GvChatMessageList.reverse]：视觉底部为 [ScrollPosition.minScrollExtent]。
  double _scrollDistanceFromVisualBottomPx() {
    final c = _msgListController.scroll;
    if (!c.hasClients) return double.infinity;
    final p = c.position;
    return (p.pixels - p.minScrollExtent).clamp(0.0, double.infinity);
  }

  /// 延迟并入实时消息 [commitDeferredRealtimeSessionInsert] 若在**同一调用栈**里立刻
  /// [applyInsertHeightViewportCompensation]，[ListView] 往往仍是旧 [itemCount]，offset+h
  /// 会基于过期几何，短列表可能「闪一下」。改为首帧 [layout] 后再补偿。
  ///
  /// 插入前视口在底（见 [_kNewMessageChipAwayFromBottomPx]）时：**不做** offset+h，由
  /// [_scheduleSmoothScrollToVisualBottomAfterNewMessage] 平滑 [animateTo] 对齐最新底，避免抢跑导致平滑失效。
  void _scheduleRealtimeInsertViewportCompensation(double h) {
    if (h <= 0.5 || _abortPagingViewportCompensation) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final sc = _msgListController.scroll;
      if (!sc.hasClients) return;
      final p = sc.position;
      if (!p.hasContentDimensions) return;
      final dist = _scrollDistanceFromVisualBottomPx();
      if (dist <= _kNewMessageChipAwayFromBottomPx) {
        return;
      }
      _msgListController.applyInsertHeightViewportCompensation(h);
    });
  }

  void _syncNewMessageFloatingChipAfterChatNotify() {
    if (!mounted || !_messageListVisible) return;
    final chat = context.read<ChatProvider>();
    if (!_isActiveChatRoom(chat)) return;

    final epoch =
        chat.realtimeIngestEpochForSession(widget.peerId, widget.chatType);

    if (!_newMessageChipBaselineReady) {
      _lastSeenRealtimeIngestEpoch = epoch;
      _newMessageChipBaselineReady = true;
      return;
    }

    if (epoch == _lastSeenRealtimeIngestEpoch) {
      _tryDismissNewMessageFloatingChipIfCaughtUp();
      return;
    }

    final dist = _scrollDistanceFromVisualBottomPx();

    // 向新方向仍有未加载页：来新消息时不自动滚底（也不做平滑跟随），仅保留离底较远时的角标。
    if (!_noMoreNewer) {
      if (dist > _kNewMessageChipAwayFromBottomPx) {
        setState(() => _showNewMessagesFloatingChip = true);
      } else {
        setState(() {
          _lastSeenRealtimeIngestEpoch = epoch;
        });
      }
      return;
    }

    if (dist > _kNewMessageChipAwayFromBottomPx) {
      setState(() => _showNewMessagesFloatingChip = true);
    } else {
      setState(() {
        _lastSeenRealtimeIngestEpoch = epoch;
        _showNewMessagesFloatingChip = false;
      });
      _scheduleSmoothScrollToVisualBottomAfterNewMessage();
    }
  }

  void _tryDismissNewMessageFloatingChipIfCaughtUp() {
    if (!mounted || !_messageListVisible || !_showNewMessagesFloatingChip) {
      return;
    }
    final chat = context.read<ChatProvider>();
    if (!_isActiveChatRoom(chat)) return;
    final dist = _scrollDistanceFromVisualBottomPx();
    if (dist <= _kNewMessageChipAwayFromBottomPx) {
      setState(() {
        _showNewMessagesFloatingChip = false;
        _lastSeenRealtimeIngestEpoch =
            chat.realtimeIngestEpochForSession(widget.peerId, widget.chatType);
      });
    }
  }

  Future<void> _onNewMessagesFloatingChipTap() async {
    if (!mounted) return;
    setState(() => _showNewMessagesFloatingChip = false);
    await _scrollMessageListToBottomOrReloadForChrome();
    if (!mounted) return;
    final chat = context.read<ChatProvider>();
    setState(() {
      _lastSeenRealtimeIngestEpoch =
          chat.realtimeIngestEpochForSession(widget.peerId, widget.chatType);
    });
  }

  /// [GvChatMessageList] 为 reverse：最新在视觉底部，对应 [ScrollPosition.minScrollExtent]。
  void _jumpMessageListToVisualBottom() {
    final sc = _msgListController.scroll;
    if (!sc.hasClients) return;
    sc.jumpTo(sc.position.minScrollExtent);
  }

  static const Duration _kSmoothScrollToBottomDuration =
      Duration(milliseconds: 280);

  /// 实时新消息到达且已在底部附近时：待列表布局后再平滑对齐到底（两帧确保插入后 [layout] 完成）。
  void _scheduleSmoothScrollToVisualBottomAfterNewMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_animateMessageListToVisualBottomSmooth());
      });
    });
  }

  Future<void> _animateMessageListToVisualBottomSmooth() async {
    final sc = _msgListController.scroll;
    if (!sc.hasClients) return;
    final p = sc.position;
    if (!p.hasContentDimensions) return;
    final target = p.minScrollExtent;
    final delta = (p.pixels - target).abs();
    if (delta < 0.5) return;
    try {
      await sc.animateTo(
        target,
        duration: _kSmoothScrollToBottomDuration,
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      if (mounted) _jumpMessageListToVisualBottom();
    }
  }

  /// 无动画：列表已对齐会话全局最新则只 [jumpTo] 底；否则等同重新进房——删本地会话列表并拉**整会话**最新 [_kHistoryPageSize] 条（无 before/after 游标），再滚到底。
  Future<void> _scrollMessageListToBottomOrReloadForChrome() async {
    if (!mounted || !_messageListVisible) return;
    final chat = context.read<ChatProvider>();
    if (_shouldReenterRoomFetchLatest30(chat) && !_historyPaging) {
      late final ({int added, int serverCount}) r;
      try {
        r = await chat.replaceSessionWithLatestTail(
          widget.peerId,
          widget.chatType,
          pageSize: _kHistoryPageSize,
        );
      } catch (error, stackTrace) {
        debugPrint('replaceSessionWithLatestTail failed: $error\n$stackTrace');
        return;
      }
      if (!mounted) return;
      setState(() {
        _noMoreOlder = r.serverCount == 0 ||
            (r.serverCount < _kHistoryPageSize && r.added == r.serverCount);
        _noMoreNewer = true;
        _suppressListPaging = false;
        _pagingMeasureSegment = const [];
      });
      _syncAllowRealtimeMergeIntoList(chat);
    }
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpMessageListToVisualBottom();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpMessageListToVisualBottom();
        _tryDismissNewMessageFloatingChipIfCaughtUp();
      });
    });
  }

  Future<void> _onMorePickImage() => _pickChatImage(ImageSource.gallery);

  /// 进入聊天相机：快门轻触拍照，长按录像，松手结束。
  Future<void> _onMoreTakePhoto() async {
    _closeComposerPanel();
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      await _pickChatImage(ImageSource.camera);
      return;
    }
    final capture = await Navigator.of(context).push<GvChatCameraCapture>(
      MaterialPageRoute<GvChatCameraCapture>(
        fullscreenDialog: true,
        builder: (_) => const GvChatCameraScreen(),
      ),
    );
    if (capture == null || !mounted) return;
    if (capture.isVideo) {
      await _uploadAndSend('video', File(capture.path));
      return;
    }
    final path = capture.path;
    _setPendingImageDraft(
      _PendingImageDraft(
        file: File(path),
        filename: path.split(Platform.pathSeparator).last,
      ),
    );
  }

  Future<void> _pickChatImage(ImageSource source) async {
    _closeComposerPanel();
    final x = await ImagePicker().pickImage(source: source);
    if (x == null || !mounted) return;
    if (kIsWeb) {
      final bytes = await x.readAsBytes();
      if (!mounted || bytes.isEmpty) return;
      var fname = x.name.trim().isNotEmpty ? x.name.trim() : 'image.jpg';
      if (!fname.contains('.')) {
        fname = '${fname}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      }
      _setPendingImageDraft(
        _PendingImageDraft(
          file: File('stub'),
          bytes: bytes,
          filename: fname,
        ),
      );
      return;
    }
    _setPendingImageDraft(
      _PendingImageDraft(
        file: File(x.path),
        filename: x.name.trim().isEmpty
            ? x.path.split(Platform.pathSeparator).last
            : x.name.trim(),
      ),
    );
  }

  Future<void> _onPasteClipboardImage(Uint8List bytes) async {
    if (bytes.isEmpty || !mounted) return;
    final prepared = await gvPrepareClipboardImageBytes(bytes);
    if (!mounted) return;
    if (prepared == null || prepared.isEmpty) {
      GvToast.show(
        context,
        AppLocalizations.of(context)!.chatClipboardImageReadFailed,
      );
      return;
    }
    final filename = 'clipboard_${DateTime.now().millisecondsSinceEpoch}.jpg';
    _setPendingImageDraft(
      _PendingImageDraft(
        file: File('clipboard-image'),
        bytes: prepared,
        filename: filename,
      ),
    );
  }

  Future<void> _onPasteClipboardVideo(String path) async {
    if (!mounted || path.isEmpty) return;
    final video = File(path);
    if (!await video.exists()) {
      if (mounted) {
        GvToast.show(
          context,
          AppLocalizations.of(context)!.toastFilePickReadFailed,
        );
      }
      return;
    }
    _closeComposerPanel();
    await _uploadAndSend('video', video);
  }

  void _setPendingImageDraft(_PendingImageDraft draft) {
    if (!mounted || _pendingImageSending) return;
    _imageCaptionController.clear();
    setState(() {
      _pendingImageDraft = draft;
      _voiceMode = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingImageDraft == null) return;
      _imageCaptionFocus.requestFocus();
      _scheduleScrollMessageListToBottomForChrome();
    });
  }

  void _clearPendingImageDraft() {
    if (!mounted || _pendingImageSending) return;
    _imageCaptionFocus.unfocus();
    _imageCaptionController.clear();
    setState(() => _pendingImageDraft = null);
  }

  Future<void> _sendPendingImageDraft() async {
    final draft = _pendingImageDraft;
    if (draft == null || _pendingImageSending) return;
    final caption = _imageCaptionController.text.trim();
    setState(() => _pendingImageSending = true);
    var sent = false;
    try {
      sent = await _uploadAndSend(
        'image',
        draft.file,
        imageBytesWeb: draft.bytes,
        imageFilenameWeb: draft.bytes == null ? null : draft.filename,
        imageCaption: caption,
      );
    } catch (error, stackTrace) {
      if (mounted) {
        final message = context.read<ApiClient>().extractErrorMessage(error);
        GvToast.show(
          context,
          message,
        );
      }
      debugPrint('_sendPendingImageDraft failed: $error\n$stackTrace');
    }
    if (!mounted) return;
    setState(() {
      _pendingImageSending = false;
      if (sent) {
        _pendingImageDraft = null;
        _imageCaptionController.clear();
      }
    });
    if (sent) {
      _imageCaptionFocus.unfocus();
      _roomBottomKey.currentState?.maintainComposerFocusAfterSend();
    }
  }

  Widget? _buildPendingImageBanner(BuildContext context) {
    final draft = _pendingImageDraft;
    if (draft == null) return null;
    final l10n = AppLocalizations.of(context)!;
    final bg = AppColors.bgSearchField.resolveFrom(context);
    final border = Theme.of(context).dividerColor;
    final secondary = AppColors.textSecondary.resolveFrom(context);

    final preview = draft.bytes != null
        ? Image.memory(
            draft.bytes!,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              size: 30,
            ),
          )
        : Image.file(
            draft.file,
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              size: 30,
            ),
          );

    return Container(
      key: GvAutomationKeys.pendingImageDraft,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        GvSpacing.sm,
        GvSpacing.sm,
        GvSpacing.sm,
        GvSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(GvRadii.input),
                    child: ColoredBox(
                      color: bg,
                      child: SizedBox(width: 72, height: 72, child: preview),
                    ),
                  ),
                  Positioned(
                    right: -7,
                    top: -7,
                    child: Material(
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      shape: const CircleBorder(),
                      child: InkWell(
                        key: GvAutomationKeys.pendingImageCancel,
                        customBorder: const CircleBorder(),
                        onTap: _pendingImageSending
                            ? null
                            : _clearPendingImageDraft,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_pendingImageSending)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.42),
                          borderRadius: BorderRadius.circular(GvRadii.input),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: GvSpacing.page),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chatImageCaptionTitle,
                      style: GvTypography.body(
                        AppColors.textPrimary.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      draft.filename,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GvTypography.caption(secondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: GvSpacing.sm),
          TextField(
            key: GvAutomationKeys.pendingImageCaption,
            controller: _imageCaptionController,
            focusNode: _imageCaptionFocus,
            enabled: !_pendingImageSending,
            maxLength: 200,
            maxLines: 1,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) {
              if (!_pendingImageSending) unawaited(_sendPendingImageDraft());
            },
            decoration: InputDecoration(
              hintText: l10n.chatImageCaptionHint,
              counterText: '',
              filled: true,
              fillColor: bg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: GvSpacing.page,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(GvRadii.input),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onMorePickVideo() async {
    _closeComposerPanel();
    final x = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (x != null && mounted) await _uploadAndSend('video', File(x.path));
  }

  Future<void> _onMoreRecordVideo() async {
    _closeComposerPanel();
    final x = await ImagePicker().pickVideo(source: ImageSource.camera);
    if (x != null && mounted) await _uploadAndSend('video', File(x.path));
  }

  Future<void> _onMorePickFile() async {
    _closeComposerPanel();
    try {
      debugPrint('[FILE DEBUG] opening document picker');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb,
      );
      if (result == null || result.files.isEmpty) {
        debugPrint('[FILE DEBUG] picker cancelled');
        return;
      }

      final picked = result.files.single;
      debugPrint(
        '[FILE DEBUG] selected name=${picked.name} size=${picked.size} '
        'pathAvailable=${!kIsWeb && picked.path != null} '
        'bytesAvailable=${picked.bytes != null}',
      );
      if (!mounted) return;

      if (kIsWeb) {
        final bytes = picked.bytes;
        if (bytes == null || bytes.isEmpty) {
          GvToast.show(
            context,
            AppLocalizations.of(context)!.toastFilePickReadFailed,
          );
          return;
        }
        await _uploadAndSend(
          'file',
          File(picked.name),
          displayName: picked.name,
          fileBytesWeb: bytes,
          fileFilenameWeb: picked.name,
        );
        return;
      }

      final path = picked.path;
      if (path == null || path.trim().isEmpty) {
        GvToast.show(
          context,
          AppLocalizations.of(context)!.toastFilePickReadFailed,
        );
        return;
      }
      await _uploadAndSend(
        'file',
        File(path),
        displayName: picked.name,
      );
    } catch (error, stackTrace) {
      debugPrint('[FILE DEBUG] pick/upload failed: $error\n$stackTrace');
      if (mounted) {
        final message = context.read<ApiClient>().extractErrorMessage(error);
        GvToast.show(
          context,
          message,
        );
      }
    }
  }

  void _startCallFromChat(String type) {
    unawaited(_startCallFromChatAsync(type));
  }

  Future<void> _startCallFromChatAsync(String type) async {
    if (widget.chatType != 'private' && widget.chatType != 'secret') return;
    final remote = context.read<ClientRemoteConfigProvider>();
    if (type == 'video' && !remote.videoCallEnabled) {
      GvToast.show(
          context, AppLocalizations.of(context)!.toastVideoCallDisabled);
      return;
    }
    if (type != 'video' && !remote.voiceCallEnabled) {
      GvToast.show(
          context, AppLocalizations.of(context)!.toastVoiceCallDisabled);
      return;
    }
    final chat = context.read<ChatProvider>();
    // 私密聊天的 peerId 是 secretChatId，通话目标需取对端用户 id。
    int? fid;
    if (widget.chatType == 'secret') {
      final info = _secretChat ?? chat.cachedSecretChat(widget.peerId);
      fid = info?.peerUserId;
    } else {
      fid = int.tryParse(widget.peerId);
    }
    if (fid == null) return;
    final myId = chat.myId;
    if (myId != null && myId == fid) {
      GvToast.show(context, AppLocalizations.of(context)!.toastCannotCallSelf);
      return;
    }
    _closeComposerPanel();
    final f = context.read<FriendProvider>();
    final g = context.read<GroupProvider>();
    final name = _title(chat, f, g, AppLocalizations.of(context)!);
    final call = context.read<CallProvider>();
    final loc = GoRouterState.of(context).matchedLocation;
    final ok = call.startCall(
      fid,
      name,
      type: type == 'video' ? 'video' : 'audio',
      returnLocation: loc,
      peerIdStr: widget.peerId,
      chatType: widget.chatType,
    );
    if (!ok) {
      GvToast.show(context, AppLocalizations.of(context)!.toastAlreadyInCall);
      return;
    }
    if (kIsWeb) {
      final prep = await call.prepareWebLocalMediaInUserGesture();
      if (!mounted) return;
      if (prep != CallInitMediaOutcome.success) {
        await call.reset();
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        final u = Uri.base;
        final secure = u.isScheme('https') ||
            u.host == 'localhost' ||
            u.host == '127.0.0.1';
        GvToast.show(
          context,
          secure
              ? l10n.callErrorMediaPermission
              : l10n.callErrorMediaNeedsHttps,
        );
        return;
      }
    }
    if (!mounted) return;
    context.push('/call');
  }

  /// 删除消息：发送中仅本机移除（尚无服务端 msgId）；已发送走服务端双方删除并 WS 同步。
  /// 私密聊天走独立 /secret-messages 删除接口（服务端协调双方移除）。
  void _deleteMessageLocally(ChatMessage m) {
    final chat = context.read<ChatProvider>();
    if (!mounted) return;
    if (m.status == 'sending') {
      chat.hideMessageForMe(widget.peerId, widget.chatType, m.msgId);
    } else if (widget.chatType == 'secret') {
      chat.deleteSecretMessageForEveryone(widget.peerId, m.msgId);
    } else if (widget.chatType == 'secret_group') {
      // 私密群聊删除所有人：服务端协调全员移除。
      chat.deleteSecretGroupMessageForEveryone(widget.peerId, m.msgId);
    } else {
      chat.deleteMessageForEveryone(m.msgId);
    }
    setState(() {});
  }

  /// 进入多选批量删除模式。
  void _enterMultiSelect() {
    setState(() {
      _multiSelect = true;
      _selectedMsgIds.clear();
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

  /// 多选底部「删除」：二选一——删除仅我（本机）/ 删除所有人（服务端双方）。
  Future<void> _deleteSelected() async {
    if (_selectedMsgIds.isEmpty || !mounted) return;
    final chat = context.read<ChatProvider>();
    final ids = List<String>.from(_selectedMsgIds);
    final l10n = AppLocalizations.of(context)!;
    final choice = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.chatDeleteSelected),
        content: Text(l10n.chatMultiSelectCount(ids.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, 'me'),
            child: Text(l10n.chatDeleteForMe),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, 'all'),
            child: Text(l10n.chatDeleteForEveryone),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    if (choice != 'all') {
      // 删除仅我：批量落服务端墓碑（本地隐藏随重装丢失，服务端墓碑才是跨重装依据）。
      chat.deleteMessagesForMe(
        peerId: widget.peerId,
        chatType: widget.chatType,
        msgIds: ids,
      );
    } else {
      for (final msgId in ids) {
        chat.deleteMessageForEveryone(msgId);
      }
    }
    _exitMultiSelect();
  }

  /// 多选「引用」：单选直接引用该条；多选按顺序合并为一条引用预览。
  void _quoteSelected() {
    if (_selectedMsgIds.isEmpty || !mounted) return;
    final chat = context.read<ChatProvider>();
    final session = chat.messagesFor(widget.peerId, widget.chatType);
    final selected = session
        .where((m) => _selectedMsgIds.contains(m.msgId))
        .toList()
      ..sort((a, b) => (a.seq ?? 0).compareTo(b.seq ?? 0));
    if (selected.isEmpty) return;
    if (selected.length == 1) {
      setState(() => _replyTo = selected.first);
    } else {
      final first = selected.first;
      final parts = selected.map((m) {
        final preview = getMessagePreview(
          msgType: m.msgType,
          content: m.content,
        );
        final name = m.fromUsername?.trim();
        return (name == null || name.isEmpty) ? preview : '$name: $preview';
      }).toList();
      final synthetic = ChatMessage(
        msgId: first.msgId,
        from: first.from,
        fromUsername: first.fromUsername,
        toId: widget.peerId,
        chatType: widget.chatType,
        msgType: 'text',
        content: parts.join('\n'),
        timestamp: DateTime.now().toUtc(),
        status: 'sent',
      );
      setState(() => _replyTo = synthetic);
    }
    _exitMultiSelect();
  }

  /// 多选「收藏」：所选消息一次请求批量收藏（服务端按 msgId 幂等，重复收藏不产生重复项）。
  Future<void> _favoriteSelected() async {
    if (_selectedMsgIds.isEmpty || !mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final ids = List<String>.from(_selectedMsgIds);
    try {
      final result = await context.read<FavoriteRepository>().addFavorites(
            peerId: widget.peerId,
            chatType: widget.chatType,
            messageIds: ids,
          );
      if (!mounted) return;
      final text = result.created > 0
          ? (result.skipped > 0
              ? l10n.favoritesBatchAddedWithSkipped(
                  result.created,
                  result.skipped,
                )
              : l10n.favoritesBatchAdded(result.created))
          : (result.skipped > 0
              ? l10n.favoritesBatchAlreadySaved
              : l10n.favoritesBatchEmpty);
      GvToast.show(context, text, duration: const Duration(seconds: 1));
    } catch (_) {
      if (!mounted) return;
      GvToast.show(
        context,
        l10n.favoritesBatchFailed,
        duration: const Duration(seconds: 1),
      );
    }
    if (mounted) _exitMultiSelect();
  }

  Widget _buildMultiSelectActionBar(AppLocalizations l10n) {
    final danger = AppColors.danger.resolveFrom(context);
    return SafeArea(
      top: false,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: GvSpacing.page, vertical: 8),
        decoration: BoxDecoration(
          color: gvPageScaffoldBackground(context),
          border: Border(
            top: BorderSide(
              color: AppColors.textHint
                  .resolveFrom(context)
                  .withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _selectedMsgIds.isEmpty ? null : _quoteSelected,
                child: Text(l10n.chatActionReply),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _selectedMsgIds.isEmpty
                    ? null
                    : () => unawaited(_favoriteSelected()),
                child: Text(l10n.chatActionFavorite),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _selectedMsgIds.isEmpty
                    ? null
                    : () => unawaited(_deleteSelected()),
                style: FilledButton.styleFrom(backgroundColor: danger),
                child: Text(l10n.chatDeleteSelected),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 长按消息气泡：弹出操作菜单并分发到复制、回复、转发、撤回等业务分支。
  Future<void> _openMenu(ChatMessage m, Offset globalPosition) async {
    final chat = context.read<ChatProvider>();
    final myId = chat.myId;
    if (myId == null) return;
    if (m.msgType == 'system' || m.msgType == 'recall') return;

    final copyText = _messageMenuCopyPlainText(m);
    final copyMediaUrl = _messageMenuCopyMediaUrl(m);
    final items = _buildMessageLongPressMenuEntries(
      m,
      myId,
      copyText,
      canCopyMedia: copyMediaUrl != null,
    );
    final selected = await _showMessageLongPressMenu(globalPosition, items);
    if (!mounted || selected == null) return;
    await _handleMessageLongPressMenuChoice(
      chat,
      m,
      selected,
      copyText,
      copyMediaUrl,
    );
  }

  /// 仅文本消息可复制：解析 @mention、链接等后的纯剪贴板文案。
  String? _messageMenuCopyPlainText(ChatMessage m) {
    if (m.msgType != 'text') return null;
    return getCopyTextForMessage(
      msgType: m.msgType,
      content: m.content,
      baseUrl: AppConfig.mediaBase,
    );
  }

  /// 图片复制为位图；桌面端视频复制为文件，供输入框直接粘贴发送。
  String? _messageMenuCopyMediaUrl(ChatMessage m) {
    if (m.status == 'sending' || m.status == 'recalled') return null;
    if (m.msgType == 'image' && GvChatMediaClipboardService.supportsImageCopy) {
      final url = parseImageForChat(AppConfig.mediaBase, m.content).imageUrl;
      return url.isEmpty ? null : url;
    }
    if (m.msgType == 'video' &&
        GvChatMediaClipboardService.supportsVideoFileClipboard) {
      final url = parseVideoForChat(AppConfig.mediaBase, m.content).playUrl;
      return url.isEmpty ? null : url;
    }
    return null;
  }

  /// 根据远端配置与消息形态，组装长按菜单项（复制、回复、撤回、举报等）。
  List<PopupMenuEntry<String>> _buildMessageLongPressMenuEntries(
    ChatMessage m,
    int myId,
    String? copyText, {
    required bool canCopyMedia,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final items = <PopupMenuEntry<String>>[];
    if ((copyText != null && copyText.isNotEmpty) || canCopyMedia) {
      items.add(PopupMenuItem<String>(
        value: 'copy',
        child: Text(l10n.chatActionCopy),
      ));
    }
    // 私密群聊编辑：仅发送方自己的文本消息可编辑。
    if (widget.chatType == 'secret_group' &&
        m.from == myId &&
        m.msgType == 'text') {
      items.add(const PopupMenuItem<String>(
        value: 'edit',
        child: Text('编辑'),
      ));
    }
    // 普通会话（私聊/群聊/频道）编辑：仅发送者本人、文本、发送后 2 分钟内。
    if (_canEditRegularMessage(m, myId)) {
      items.add(PopupMenuItem<String>(
        value: 'edit',
        child: Text(l10n.gvMbEditAction),
      ));
    }
    items.add(PopupMenuItem<String>(
      value: 'reply',
      child: Text(l10n.chatActionReply),
    ));
    // 收藏：服务端消息（非发送中占位）可收藏。
    if (m.status != 'sending') {
      items.add(PopupMenuItem<String>(
        value: 'favorite',
        child: Text(l10n.chatActionFavorite),
      ));
    }
    // 私密群聊置顶：仅群主可置顶一条消息（公告性质）。
    if (widget.chatType == 'secret_group' &&
        _secretGroupChat != null &&
        _secretGroupChat!.ownerUserId == myId) {
      items.add(PopupMenuItem<String>(
        value: 'pin',
        child: Text(l10n.chatPinConversation),
      ));
    }
    if (gvChatMessageCanForward(m, chatType: widget.chatType)) {
      items.add(PopupMenuItem<String>(
        value: 'forward',
        child: Text(l10n.chatActionForward),
      ));
    }
    // 与服务端 assertCanDelete 对齐：无权限的消息不展示撤回/删除，避免点击后服务端拒绝无反应。
    // 撤回仅发送方；删除他人消息按 Telegram 语义（单聊对端、群聊群主/管理员、密聊对端、密群群主）。
    // 「发送中」消息删除仅为本地移除，不受会话角色限制。
    final canRecall = _canManageMessage(m, myId) && _canRecall(m, myId);
    final canDelete = m.status == 'sending' || _canDeleteMessage(m, myId);
    final remote = context.read<ClientRemoteConfigProvider>();
    final recallOn = remote.recallEnabled;
    final chatDeleteOn = remote.chatDeleteEnabled;
    // 私密群聊的「删除所有人/撤回」受 groupDeleteEveryoneEnabled 开关控制；普通会话不受影响。
    final groupDeleteOn = widget.chatType != 'secret_group' ||
        context.read<ClientRemoteConfigProvider>().groupDeleteEveryoneEnabled;
    if (recallOn && chatDeleteOn && canRecall && groupDeleteOn) {
      items.add(PopupMenuItem<String>(
        value: 'recall',
        child: Text(l10n.chatActionRecall),
      ));
    }
    if (m.msgType == 'emoji' || m.msgType == 'image') {
      items.add(PopupMenuItem<String>(
        value: 'add_sticker',
        child: Text(l10n.chatAddToStickers),
      ));
    }
    // if (m.from != myId) {
    //   items.add(const PopupMenuItem<String>(
    //     value: 'report',
    //     child: Text('举报'),
    //   ));
    // }
    if (chatDeleteOn && canDelete && groupDeleteOn) {
      items.add(PopupMenuItem<String>(
        key: GvAutomationKeys.messageDeleteMenu,
        value: 'delete',
        child: Text(
          l10n.chatDeleteForEveryone,
          style: TextStyle(color: AppColors.danger.resolveFrom(context)),
        ),
      ));
    }
    // 「删除仅我」：任意消息均可本机移除（不通知对端）。
    if (chatDeleteOn) {
      items.add(PopupMenuItem<String>(
        value: 'delete_me',
        child: Text(l10n.chatDeleteForMe),
      ));
    }
    // 「多选」：进入批量删除模式。
    if (chatDeleteOn) {
      items.add(PopupMenuItem<String>(
        value: 'multi_select',
        child: Text(l10n.chatMultiSelect),
      ));
    }
    return items;
  }

  /// 撤回权限：仅发送方（撤回墓碑为发送方操作）。
  bool _canManageMessage(ChatMessage m, int myId) {
    return m.from == myId;
  }

  /// 删除他人消息权限（参考 Telegram）：发送方、单聊/密聊对端、群聊群主/管理员、密群群主。
  bool _canDeleteMessage(ChatMessage m, int myId) {
    if (m.from == myId) return true;
    switch (widget.chatType) {
      case 'private':
      case 'secret':
        // 1 对 1：对方消息即对端消息，可删。
        return true;
      case 'group':
        final role = context
            .read<GroupProvider>()
            .memberByUserId(myId)
            ?.role
            ?.toLowerCase();
        return role == 'owner' || role == 'admin';
      case 'secret_group':
        return (_secretGroupChat?.ownerUserId ?? -1) == myId;
      default:
        return false;
    }
  }

  /// 撤回状态约束（不含权限，权限由 [_canManageMessage] 判定；不限时）。
  bool _canRecall(ChatMessage m, int myId) {
    if (m.status == 'sending' ||
        m.status == 'recalled' ||
        m.msgType == 'recall' ||
        m.msgType == 'call') {
      return false;
    }
    return true;
  }

  /// 普通会话（私聊/群聊/频道）可编辑：仅发送者本人、文本、发送后 2 分钟内（含已读）。
  /// 私密/私密群聊消息走 E2EE，不适用 /messages/edit。
  bool _canEditRegularMessage(ChatMessage m, int myId) {
    if (widget.chatType == 'secret' || widget.chatType == 'secret_group') {
      return false;
    }
    if (m.from != myId || m.msgType != 'text') return false;
    if (m.status == 'sending' ||
        m.status == 'recalled' ||
        m.msgType == 'recall') {
      return false;
    }
    final age = DateTime.now().toUtc().difference(m.timestamp.toUtc());
    return !age.isNegative && age < const Duration(minutes: 2);
  }

  /// 在长按点旁展示 Cupertino 风格弹出菜单，返回所选 [PopupMenuItem.value]。
  Future<String?> _showMessageLongPressMenu(
    Offset globalPosition,
    List<PopupMenuEntry<String>> items,
  ) {
    final bg = CupertinoColors.systemBackground.resolveFrom(context);
    return showMenu<String>(
      context: context,
      position: gvMenuPositionForGlobalPoint(context, globalPosition),
      color: bg,
      surfaceTintColor: Colors.transparent,
      elevation: kGvPopoverMenuElevation,
      shadowColor: gvPopoverMenuShadowColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GvRadii.button),
      ),
      items: items,
    );
  }

  /// 将菜单选择映射到具体副作用（导航、对话框、剪贴板等）。
  Future<void> _handleMessageLongPressMenuChoice(
    ChatProvider chat,
    ChatMessage m,
    String choice,
    String? copyText,
    String? copyMediaUrl,
  ) async {
    switch (choice) {
      case 'copy':
        await _menuActionCopy(m, copyText, copyMediaUrl);
        break;
      case 'reply':
        setState(() => _replyTo = m);
        break;
      case 'favorite':
        unawaited(_menuActionFavorite(m));
        break;
      case 'edit':
        if (widget.chatType == 'secret_group') {
          unawaited(_editSecretGroupMessage(chat, m));
        } else {
          unawaited(_editRegularMessage(chat, m));
        }
        break;
      case 'pin':
        unawaited(_pinSecretGroupMessage(chat, m));
        break;
      case 'forward':
        if (!mounted) return;
        context.push('/forward-message', extra: m);
        break;
      case 'recall':
        _menuActionRecall(chat, m);
        break;
      case 'add_sticker':
        await _menuActionAddSticker(m.content);
        break;
      // case 'report':
      //   if (!mounted) return;
      //   showReportDialog(
      //     context,
      //     api: context.read<ImApi>(),
      //     targetUserId: m.from,
      //     targetName: m.fromUsername ?? '\u7528\u6237${m.from}',
      //   );
      //   break;
      case 'delete':
        _menuActionConfirmDelete(m);
        break;
      case 'delete_me':
        if (!mounted) return;
        // 删除仅我：落服务端墓碑，卸载重装后重新同步也不会把消息“复活”。
        chat.deleteMessagesForMe(
          peerId: widget.peerId,
          chatType: widget.chatType,
          msgIds: [m.msgId],
        );
        setState(() {});
        break;
      case 'multi_select':
        _enterMultiSelect();
        break;
    }
  }

  /// 菜单项「复制」：文本直接写入，媒体下载后写入系统剪贴板。
  Future<void> _menuActionCopy(
    ChatMessage message,
    String? copyText,
    String? copyMediaUrl,
  ) async {
    if (copyText != null && copyText.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: copyText));
      return;
    }
    if (copyMediaUrl == null || copyMediaUrl.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final api = context.read<ImApi>();
      if (message.msgType == 'image') {
        await _mediaClipboard.copyImage(api: api, imageUrl: copyMediaUrl);
      } else if (message.msgType == 'video') {
        await _mediaClipboard.copyVideo(api: api, videoUrl: copyMediaUrl);
      } else {
        throw StateError('Unsupported clipboard media type');
      }
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      GvToast.show(context, l10n.chatMediaCopied);
    } catch (error, stackTrace) {
      debugPrint('Failed to copy chat media: $error\n$stackTrace');
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      GvToast.show(context, l10n.chatMediaCopyFailed);
    }
  }

  /// 菜单项「收藏」：调收藏仓库写入服务端，成功/失败各弹提示。
  Future<void> _menuActionFavorite(ChatMessage m) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await context.read<FavoriteRepository>().addFavorite(
            msgId: m.msgId,
            peerId: widget.peerId,
            chatType: widget.chatType,
          );
      if (!mounted) return;
      GvToast.show(
        context,
        l10n.favoriteAdded,
        duration: const Duration(seconds: 1),
      );
    } catch (_) {
      if (!mounted) return;
      GvToast.show(
        context,
        l10n.favoriteAddFailed,
        duration: const Duration(seconds: 1),
      );
    }
  }

  /// 私密群聊置顶消息（仅群主）：置顶后群设置里可见。
  Future<void> _pinSecretGroupMessage(ChatProvider chat, ChatMessage m) async {
    try {
      final updated = await chat.pinSecretGroupMessage(
        id: widget.peerId,
        msgId: m.msgId,
      );
      if (mounted) {
        setState(() => _secretGroupChat = updated);
        GvToast.show(context, '已置顶', duration: const Duration(seconds: 1));
      }
    } catch (e) {
      if (mounted) GvToast.show(context, ApiFailure.messageOf(e));
    }
  }

  /// 普通会话编辑消息（仅发送方，2 分钟内）：弹编辑框 → POST /messages/edit → 本地回写。
  Future<void> _editRegularMessage(ChatProvider chat, ChatMessage m) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: m.content);
    final result = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l10n.gvMbEditMessage),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, controller.text),
            child: Text(l10n.gvMbEditSave),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || result == null) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty || trimmed == m.content) return;
    try {
      await chat.editMessage(msgId: m.msgId, newContent: trimmed);
      if (mounted) {
        GvToast.show(
          context,
          l10n.gvMbEditSuccess,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      if (mounted) GvToast.show(context, ApiFailure.messageOf(e));
    }
  }

  /// 私密群聊编辑消息（仅发送方）：弹编辑框 → 逐成员重加密 → 服务端 edit → 本地更新。
  Future<void> _editSecretGroupMessage(ChatProvider chat, ChatMessage m) async {
    final controller = TextEditingController(text: m.content);
    final result = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('编辑消息'),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: Text(AppLocalizations.of(context)!.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(d, controller.text),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || result == null || result.trim().isEmpty) return;
    try {
      final ok = await chat.editSecretGroupText(
        groupId: widget.peerId,
        msgId: m.msgId,
        text: result.trim(),
      );
      if (ok && mounted) {
        setState(() {});
        GvToast.show(context, '已编辑', duration: const Duration(seconds: 1));
      }
    } catch (e) {
      if (mounted) GvToast.show(context, ApiFailure.messageOf(e));
    }
  }

  /// 菜单项「撤回」：二次确认后调用 [ChatProvider.recallMessage]。
  void _menuActionRecall(ChatProvider chat, ChatMessage m) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        actionsPadding: EdgeInsets.zero,
        actionsAlignment: MainAxisAlignment.start,
        buttonPadding: EdgeInsets.zero,
        content: Text(l10n.chatRecallConfirmBody),
        actions: [
          GvDialogActions.weChatFooter(
            d,
            onSecondary: () => Navigator.pop(d),
            onPrimary: () {
              if (widget.chatType == 'secret') {
                chat.recallSecretMessage(widget.peerId, m.msgId);
              } else if (widget.chatType == 'secret_group') {
                // 私密群聊撤回：服务端协调全员移除。
                chat.recallSecretGroupMessage(widget.peerId, m.msgId);
              } else {
                chat.recallMessage(m.msgId);
              }
              Navigator.pop(d);
            },
          ),
        ],
      ),
    );
  }

  /// 菜单项「添加到表情」：优先走面板状态；未挂载则直连 API。
  Future<void> _menuActionAddSticker(String stickerUrl) async {
    final api = context.read<ImApi>();
    final l10n = AppLocalizations.of(context)!;
    final ok = await _roomBottomKey.currentState?.stickerPanelKey.currentState
        ?.addToMyStickers(stickerUrl);
    if (ok == null || !ok) {
      try {
        await api.addUserSticker(stickerUrl);
        if (!mounted) return;
        GvToast.show(
          context,
          l10n.chatStickerAddedToMine,
          duration: const Duration(seconds: 1),
        );
      } catch (_) {
        if (!mounted) return;
        GvToast.show(
          context,
          l10n.chatStickerAddFailed,
          duration: const Duration(seconds: 1),
        );
      }
      return;
    }
    if (!mounted) return;
    GvToast.show(
      context,
      l10n.chatStickerAddedToMine,
      duration: const Duration(seconds: 1),
    );
  }

  /// 菜单项「删除」：根据私聊/群聊与会话状态展示不同提示文案。
  void _menuActionConfirmDelete(ChatMessage m) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (d) => AlertDialog(
        actionsPadding: EdgeInsets.zero,
        actionsAlignment: MainAxisAlignment.start,
        buttonPadding: EdgeInsets.zero,
        content: Text(
          m.status == 'sending'
              ? l10n.chatDeleteMsgSendingBody
              : widget.chatType == 'secret'
                  ? l10n.chatDeleteMsgSecretBody
                  : widget.chatType == 'private'
                      ? l10n.chatDeleteMsgPrivateBody
                      : l10n.chatDeleteMsgGroupBody,
        ),
        actions: [
          GvDialogActions.weChatFooter(
            d,
            secondaryKey: GvAutomationKeys.messageDeleteCancel,
            primaryKey: GvAutomationKeys.messageDeleteConfirm,
            onSecondary: () => Navigator.pop(d),
            onPrimary: () {
              Navigator.pop(d);
              _deleteMessageLocally(m);
            },
          ),
        ],
      ),
    );
  }

  /// 与 [GvChatMessageList] 的 [itemBuilder] 一致；[useAnchorKey] 为 false 时用于离屏测量（无长按菜单、无锚点 key）。
  Widget _chatRoomListTile(
    BuildContext context,
    RoomItem it,
    ChatProvider chat,
    int myId, {
    required bool useAnchorKey,
  }) {
    if (it.isPagingLoad) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ChatRoomPagingDotsRow(
            color: AppColors.textSecondary.resolveFrom(context),
          ),
        ),
      );
    }
    if (it.isTime) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            it.timeText!,
            style: const TextStyle(
              fontSize: GvTypographyScale.small,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }
    final m = it.msg!;
    final tile = ChatRoomMessageTile(
      key: useAnchorKey &&
              widget.anchorMsgId != null &&
              widget.anchorMsgId!.trim() == m.msgId.trim()
          ? _anchorNavTileKey
          : ValueKey<String>(m.msgId),
      msg: m,
      myId: myId,
      chat: chat,
      sessionPeerId: widget.peerId,
      sessionChatType: widget.chatType,
      baseUrl: AppConfig.mediaBase,
      anchorHighlight: useAnchorKey && _highlightAnchorMsgId == m.msgId,
      onLongPressAt: _multiSelect || !useAnchorKey
          ? (_) {}
          : (pos) => unawaited(_openMenu(m, pos)),
      onAvatarLongPressAt: _multiSelect ||
              !useAnchorKey ||
              (widget.chatType != 'group' && widget.chatType != 'secret_group')
          ? null
          : (userId, displayLabel) {
              _roomBottomKey.currentState
                  ?.insertAtMention(userId, displayLabel);
            },
    );
    if (_multiSelect) {
      final selected = _selectedMsgIds.contains(m.msgId);
      return Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (_) => _toggleSelect(m.msgId),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _toggleSelect(m.msgId),
              child: tile,
            ),
          ),
        ],
      );
    }
    return tile;
  }

  /// 离屏 [Column] 预排版，测量插入段总高度（逻辑像素）。
  Future<double> _measurePagingInsertHeight(List<RoomItem> segment) async {
    if (segment.isEmpty) return 0;
    if (!mounted) return 0;
    setState(() => _pagingMeasureSegment = segment);

    await Future.delayed(const Duration(milliseconds: 60));

    final box =
        _pagingMeasureKey.currentContext?.findRenderObject() as RenderBox?;

    final height = box?.size.height ?? 0;
    if (mounted) {
      setState(() => _pagingMeasureSegment = const []);
    }
    return height;
  }

  /// 右侧贴边「新消息」，点击走 [_scrollMessageListToBottomOrReloadForChrome]。
  Widget _buildNewMessagesFloatingChip(BuildContext context) {
    if (!_showNewMessagesFloatingChip) return const SizedBox.shrink();
    final blue = AppColors.primary.resolveFrom(context);
    final radius = BorderRadius.circular(20);
    return Positioned(
      right: 10,
      bottom: 24,
      child: Material(
        elevation: 2,
        shadowColor: Colors.black26,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: blue, width: 1),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => unawaited(_onNewMessagesFloatingChipTap()),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: blue,
                  size: 18,
                ),
                const SizedBox(width: 2),
                Text(
                  AppLocalizations.of(context)!.chatNewMessage,
                  style: TextStyle(
                    color: blue,
                    fontSize: GvTypographyScale.small,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chat = context.watch<ChatProvider>();
    final f = context.watch<FriendProvider>();
    final g = context.watch<GroupProvider>();
    final remoteCfg = context.watch<ClientRemoteConfigProvider>();
    final myId = chat.myId ?? 0;
    final listItems = _listItemsForMessageList(chat);
    final typing = _typingText(chat, myId, l10n);

    final wsErr = chat.popWsError();
    if (wsErr != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) GvToast.show(context, wsErr);
      });
    }

    final page = Scaffold(
      key: GvAutomationKeys.chatRoomScreen,
      resizeToAvoidBottomInset: false,
      // 键盘占位由 [GvChatBottomComposer] 内部与 viewInsets 对齐；勿再包一层 bottom Padding，避免与系统键盘双重位移（Android/iOS）。
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
          : GvNavBar(
              title: _title(chat, f, g, l10n),
              showBack: true,
              right: IconButton(
                style: IconButton.styleFrom(
                  foregroundColor: CupertinoColors.label.resolveFrom(context),
                ),
                icon: const Icon(LucideIcons.ellipsis),
                onPressed: () {
                  if (widget.chatType == 'group') {
                    gvPushGroupInfo(context, widget.peerId);
                  } else if (widget.chatType == 'channel') {
                    _showChannelInfoSheet();
                  } else if (widget.chatType == 'secret') {
                    _showSecretChatSettingsSheet();
                  } else if (widget.chatType == 'secret_group') {
                    _showSecretGroupSettingsSheet();
                  } else {
                    gvPushContactDetail(context, widget.peerId);
                  }
                },
              ),
            ),
      body: Column(
        children: [
          // 私密聊天/私密群聊：顶栏下常驻 E2EE 锁标 + 「不同步到新设备」提示条。
          if (widget.chatType == 'secret' || widget.chatType == 'secret_group')
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.chatType == 'secret'
                  ? _showSecretChatSettingsSheet
                  : _showSecretGroupSettingsSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: GvSpacing.page, vertical: 4),
                color: AppColors.bgInput.resolveFrom(context),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.lock,
                      size: 13,
                      color: AppColors.primary.resolveFrom(context),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.chatType == 'secret'
                            ? l10n.secretChatBanner
                            : l10n.secretGroupChatBanner,
                        style: const TextStyle(
                            fontSize: GvTypographyScale.small,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevron_right,
                      size: 14,
                      color: AppColors.textHint.resolveFrom(context),
                    ),
                  ],
                ),
              ),
            ),
          if (typing != null)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _dismissComposerPanelsAndKeyboard,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: GvSpacing.page, vertical: 4),
                color: AppColors.bgInput.resolveFrom(context),
                child: Text(typing,
                    style: const TextStyle(
                        fontSize: GvTypographyScale.small,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400)),
              ),
            ),
          Expanded(
            child: _messageListVisible
                ? NotificationListener<ScrollNotification>(
                    onNotification: _onListScrollUserInteraction,
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerDown: (_) {
                        final b = _roomBottomKey.currentState;
                        if (b == null || !b.absorbBackgroundPointer) return;
                        b.dismissPanelsAndKeyboard();
                      },
                      child: LayoutBuilder(
                        builder: (context, listConstraints) {
                          final listBg = gvPageScaffoldBackground(context);
                          // 带 anchorMsgId 进房依赖 [Scrollable.ensureVisible]；shrinkWrap 顶对齐视口下 reverse 列表与 ensureVisible 组合易无法滚到锚点，故锚点场景仍用定高视口（与改 shrinkWrap 前一致）。
                          final anchorForList =
                              widget.anchorMsgId?.trim().isNotEmpty ?? false;
                          final messageList = GvChatMessageList<RoomItem>(
                            key:
                                ValueKey('${widget.chatType}:${widget.peerId}'),
                            shrinkWrap: !anchorForList,
                            controller: _msgListController,
                            cacheExtent: _suppressListPaging
                                ? _kAnchorListCacheExtent
                                : null,
                            pagingEnabled:
                                _messageListVisible && !_suppressListPaging,
                            hasMoreOlder: !_noMoreOlder,
                            hasMoreNewer: !_noMoreNewer,
                            onLoadOlder:
                                _noMoreOlder ? null : _loadOlderPageForList,
                            onLoadNewer: _noMoreNewer ? null : _loadMoreNewer,
                            messages: listItems,
                            itemBuilder: (context, it, i) => _chatRoomListTile(
                              context,
                              it,
                              chat,
                              myId,
                              useAnchorKey: true,
                            ),
                            viewportKey: _messageListStackKey,
                          );
                          return Stack(
                            fit: StackFit.expand,
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: ColoredBox(color: listBg),
                              ),
                              Positioned.fill(
                                child: anchorForList
                                    ? Align(
                                        child: SizedBox(
                                          height: listConstraints.maxHeight,
                                          width: listConstraints.maxWidth,
                                          child: messageList,
                                        ),
                                      )
                                    : Align(
                                        alignment: Alignment.topCenter,
                                        child: SizedBox(
                                          width: listConstraints.maxWidth,
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(
                                              maxHeight:
                                                  listConstraints.maxHeight,
                                            ),
                                            child: messageList,
                                          ),
                                        ),
                                      ),
                              ),
                              if (_pagingLoadingOlder)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 6,
                                  child: IgnorePointer(
                                    child: Center(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: listBg.withValues(alpha: 0.92),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          boxShadow: const [
                                            BoxShadow(
                                              blurRadius: 6,
                                              offset: Offset(0, 1),
                                              color: Color(0x14000000),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          child: ChatRoomPagingDotsRow(
                                            color: AppColors.textSecondary
                                                .resolveFrom(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              _buildNewMessagesFloatingChip(context),
                              Positioned(
                                left: -10000,
                                top: 0,
                                child: Opacity(
                                  opacity: 0,
                                  child: SizedBox(
                                    width: listConstraints.maxWidth,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        GvSpacing.sm,
                                        GvSpacing.sm,
                                        GvSpacing.sm,
                                        0,
                                      ),
                                      child: Column(
                                        key: _pagingMeasureKey,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        mainAxisSize: MainAxisSize.min,
                                        children: _pagingMeasureSegment
                                            .map(
                                              (it) => _chatRoomListTile(
                                                context,
                                                it,
                                                chat,
                                                myId,
                                                useAnchorKey: false,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  )
                : Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {
                      final b = _roomBottomKey.currentState;
                      if (b == null || !b.absorbBackgroundPointer) return;
                      b.dismissPanelsAndKeyboard();
                    },
                    child: ColoredBox(
                      color: gvPageScaffoldBackground(context),
                    ),
                  ),
          ),
          if (_multiSelect)
            _buildMultiSelectActionBar(l10n)
          else
            GvChatRoomBottom(
              key: _roomBottomKey,
              myId: myId,
              replyTo: _replyTo,
              onDismissReply: () {
                _closeComposerPanel();
                setState(() => _replyTo = null);
              },
              voiceMode: _voiceMode,
              recording: _recording,
              onToggleVoiceMode: () => setState(() => _voiceMode = !_voiceMode),
              voiceHoldAreaKey: _voiceHoldAreaKey,
              onVoicePointerDown: (e) {
                unawaited(_voiceHoldPointerDown(e));
              },
              onVoicePointerMove: (PointerMoveEvent e) {
                if (_recording) {
                  _onVoicePointerMove(e, _voiceHoldAreaKey.currentContext);
                }
              },
              onVoicePointerUp: _onVoicePointerUpFromHold,
              onVoicePointerCancel: _onVoicePointerUpFromHold,
              onTyping: () => chat.sendTyping(widget.peerId, widget.chatType),
              ensureChatAllowed: _ensureChatFeatureAllowed,
              onSendText: _onRoomBottomSendText,
              initialDraftText: _conversationDraftText(chat),
              atMentionCandidates: _atMentionCandidates()
                  .map((it) => (
                        userId: it.userId,
                        label: it.mentionLabel,
                        avatar: it.avatar,
                      ))
                  .toList(growable: false),
              onDraftChanged: (text) => chat.setConversationDraft(
                widget.peerId,
                widget.chatType,
                text,
              ),
              attachmentBanner: _buildPendingImageBanner(context),
              attachmentFocusNode: _imageCaptionFocus,
              onSendPendingAttachment:
                  _pendingImageDraft == null ? null : _sendPendingImageDraft,
              pendingAttachmentSending: _pendingImageSending,
              onComposerFocusGained: _onComposerFocusGained,
              onBottomChromeExpanded:
                  _scheduleScrollMessageListToBottomForChrome,
              onSendSticker: _sendSticker,
              onAddCustomSticker: _addCustomStickerFromPanel,
              onPickImage: _onMorePickImage,
              onTakePhoto: _onMoreTakePhoto,
              onPasteImage: _onPasteClipboardImage,
              onPasteVideo: _onPasteClipboardVideo,
              onPickVideo: _onMorePickVideo,
              onRecordVideo: _onMoreRecordVideo,
              onPickFile: _onMorePickFile,
              onStartPrivateCall: _startCallFromChat,
              onAtMention: (widget.chatType == 'group' ||
                      widget.chatType == 'secret_group')
                  ? _showAtMentionPicker
                  : null,
              isPrivateChat:
                  widget.chatType == 'private' || widget.chatType == 'secret',
              voiceCallEnabled: remoteCfg.voiceCallEnabled,
              videoCallEnabled: remoteCfg.videoCallEnabled,
              readOnly: _isChannelReadOnly || _isGroupReadOnly,
              readOnlyHint: _isGroupReadOnly
                  ? l10n.groupDissolvedComposerReadOnlyHint
                  : null,
            ),
        ],
      ),
    );

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) {
            return;
          }
          final bottom = _roomBottomKey.currentState;
          if (bottom != null && bottom.absorbBackgroundPointer) {
            bottom.dismissPanelsAndKeyboard();
            return;
          }
          if (!context.mounted) {
            return;
          }
          if (context.canPop()) {
            context.pop();
          }
        },
        child: page,
      );
    }
    return page;
  }

  /// 频道信息弹层：名称 / 简介 / 成员数 / 当前角色（管理员或订阅者）。
  Future<void> _showChannelInfoSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final chat = context.read<ChatProvider>();
    ChannelInfo? info = _channelInfo ?? chat.cachedChannelInfo(widget.peerId);
    if (info == null) {
      try {
        info = await chat.channelInfo(widget.peerId);
        if (mounted) setState(() => _channelInfo = info);
      } catch (_) {}
    }
    if (!mounted) return;
    final resolved = info;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      builder: (sheetCtx) {
        final sl = AppLocalizations.of(sheetCtx)!;
        final secondary = AppColors.textSecondary.resolveFrom(sheetCtx);
        final hint = AppColors.textHint.resolveFrom(sheetCtx);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              GvSpacing.page,
              0,
              GvSpacing.page,
              GvSpacing.page,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      LucideIcons.megaphone,
                      size: 18,
                      color: AppColors.primary.resolveFrom(sheetCtx),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        resolved?.name ??
                            l10n.chatChannelDefaultTitle(widget.peerId),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GvTypography.title(
                          AppColors.textPrimary.resolveFrom(sheetCtx),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GvSpacing.sm),
                Text(
                  resolved == null
                      ? sl.channelRoleSubscriber
                      : (resolved.isOwner
                          ? sl.channelRoleOwner
                          : sl.channelRoleSubscriber),
                  style: GvTypography.caption(secondary),
                ),
                if (resolved != null && resolved.memberCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    sl.channelMemberCount(resolved.memberCount),
                    style: GvTypography.caption(secondary),
                  ),
                ],
                if (resolved != null && resolved.description.isNotEmpty) ...[
                  const SizedBox(height: GvSpacing.sm),
                  Text(
                    resolved.description,
                    style: GvTypography.caption(secondary),
                  ),
                ],
                const SizedBox(height: GvSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(GvSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.bgSearchField.resolveFrom(sheetCtx),
                    borderRadius: BorderRadius.circular(GvRadii.input),
                  ),
                  child: Text(
                    sl.channelInfoHint,
                    style: GvTypography.caption(hint),
                  ),
                ),
                if (resolved != null &&
                    (resolved.code.isNotEmpty || resolved.id.isNotEmpty)) ...[
                  const SizedBox(height: GvSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: GvSpacing.sm,
                            vertical: GvSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color:
                                AppColors.bgSearchField.resolveFrom(sheetCtx),
                            borderRadius: BorderRadius.circular(GvRadii.input),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sl.channelShareCodeLabel,
                                style: GvTypography.caption(hint),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                resolved.code.isNotEmpty
                                    ? resolved.code
                                    : resolved.id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: AppColors.textPrimary
                                      .resolveFrom(sheetCtx),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        key: GvAutomationKeys.channelShareButton,
                        onPressed: () async {
                          final payload = resolved.code.isNotEmpty
                              ? buildGvChannelCodePayload(resolved.code)
                              : '';
                          final parts = <String>[
                            '${sl.channelShareTitle}: ${resolved.name}',
                            if (resolved.code.isNotEmpty)
                              '${sl.channelShareCodeLabel}: ${resolved.code}',
                            if (payload.isNotEmpty) payload,
                          ];
                          await Clipboard.setData(
                            ClipboardData(text: parts.join('\n')),
                          );
                          if (sheetCtx.mounted) {
                            GvToast.show(
                              sheetCtx,
                              sl.toastChannelShareCopied,
                              duration: const Duration(seconds: 1),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.share_2, size: 16),
                        label: Text(sl.channelShareTitle),
                      ),
                    ],
                  ),
                  if (resolved.code.isNotEmpty) ...[
                    const SizedBox(height: GvSpacing.sm),
                    OutlinedButton.icon(
                      key: GvAutomationKeys.channelQrButton,
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        unawaited(_showChannelQrCodeDialog(resolved));
                      },
                      icon: const Icon(LucideIcons.qr_code, size: 16),
                      label: Text(sl.channelQrCodeTitle),
                    ),
                  ],
                  const SizedBox(height: GvSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetCtx);
                      context.push('/share-channel', extra: resolved);
                    },
                    icon: const Icon(LucideIcons.forward, size: 16),
                    label: Text(sl.channelShareToChat),
                  ),
                  if (resolved.isOwner) ...[
                    const SizedBox(height: GvSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: GvAutomationKeys.channelEditButton,
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              unawaited(_showEditChannelDialog(resolved));
                            },
                            icon: const Icon(LucideIcons.pencil, size: 16),
                            label: Text(sl.channelEditAction),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            key: GvAutomationKeys.channelDeleteButton,
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  AppColors.danger.resolveFrom(sheetCtx),
                            ),
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              unawaited(_confirmDeleteChannel(resolved));
                            },
                            icon: const Icon(LucideIcons.trash, size: 16),
                            label: Text(sl.channelDeleteAction),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: GvSpacing.sm),
                    OutlinedButton.icon(
                      key: GvAutomationKeys.channelUnsubscribeButton,
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        unawaited(_confirmUnsubscribeChannel(resolved));
                      },
                      icon: const Icon(LucideIcons.bell_off, size: 16),
                      label: Text(sl.channelUnsubscribeAction),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// 频道二维码弹层：内容为 `OPEN_CHANNEL:{code}`，App 内扫码即可订阅。
  Future<void> _showChannelQrCodeDialog(ChannelInfo info) async {
    final payload = buildGvChannelCodePayload(info.code);
    final qrKey = GlobalKey();
    var saving = false;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final cl = AppLocalizations.of(ctx)!;
        final dialogRadius = BorderRadius.circular(GvRadii.dialogLarge);
        final dialogBg = CupertinoColors.systemBackground.resolveFrom(ctx);
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              shadowColor: GvShadows.card.first.color,
              shape: RoundedRectangleBorder(borderRadius: dialogRadius),
              backgroundColor: dialogBg,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Column(
                      children: [
                        Text(
                          cl.channelQrCodeTitle,
                          textAlign: TextAlign.center,
                          style: GvTypography.navTitle(
                            AppColors.textPrimary.resolveFrom(ctx),
                          ),
                        ),
                        const SizedBox(height: 12),
                        RepaintBoundary(
                          key: qrKey,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: payload,
                              size: 220,
                              padding: EdgeInsets.zero,
                              backgroundColor: CupertinoColors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.H,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          cl.channelQrCodeHint,
                          textAlign: TextAlign.center,
                          style: GvTypography.caption(
                            AppColors.textHint.resolveFrom(ctx),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          info.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GvTypography.title(
                            AppColors.textPrimary.resolveFrom(ctx),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GvDialogActions.weChatFooter(
                    ctx,
                    secondaryText: cl.commonClose,
                    primaryText:
                        saving ? '${cl.commonSave}…' : cl.profileSaveQrCode,
                    onSecondary: () => Navigator.pop(ctx),
                    onPrimary: () async {
                      if (saving) return;
                      setDialogState(() => saving = true);
                      try {
                        await _saveChannelQrCode(ctx, qrKey, info);
                      } finally {
                        if (ctx.mounted) setDialogState(() => saving = false);
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 将频道二维码渲染为 PNG 并保存到系统相册。
  Future<void> _saveChannelQrCode(
    BuildContext ctx,
    GlobalKey qrKey,
    ChannelInfo info,
  ) async {
    final l10n = AppLocalizations.of(ctx)!;
    if (kIsWeb) {
      GvToast.show(ctx, l10n.toastQrSaveNotSupported);
      return;
    }
    try {
      var hasAccess = await Gal.hasAccess();
      if (!hasAccess) hasAccess = await Gal.requestAccess();
      if (!hasAccess) {
        if (ctx.mounted) GvToast.show(ctx, l10n.galErrorAccessDenied);
        return;
      }
      await WidgetsBinding.instance.endOfFrame;
      final boundary =
          qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('QR image is not ready');
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw StateError('Could not encode QR image');
      final safeCode =
          info.code.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      await Gal.putImageBytes(
        data.buffer.asUint8List(),
        name:
            'open_channel_qr_${safeCode.isEmpty ? 'channel' : safeCode}_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (ctx.mounted) GvToast.show(ctx, l10n.toastSavedToGallery);
    } on GalException catch (e) {
      if (!ctx.mounted) return;
      final message = switch (e.type) {
        GalExceptionType.accessDenied => l10n.galErrorAccessDenied,
        GalExceptionType.notEnoughSpace => l10n.galErrorNotEnoughSpace,
        GalExceptionType.notSupportedFormat => l10n.galErrorUnsupportedFormat,
        GalExceptionType.unexpected => l10n.galErrorUnexpected,
      };
      GvToast.show(ctx, message);
    } catch (_) {
      if (ctx.mounted) GvToast.show(ctx, l10n.galErrorUnexpected);
    }
  }

  /// 编辑频道（名称/公告），仅 owner；成功后刷新弹层数据与会话列表显示名。
  Future<void> _showEditChannelDialog(ChannelInfo info) async {
    final nameCtrl = TextEditingController(text: info.name);
    final announceCtrl = TextEditingController(text: info.description);
    try {
      final result = await showDialog<({String name, String announcement})>(
        context: context,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
            actionsPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.start,
            buttonPadding: EdgeInsets.zero,
            title: Text(loc.channelEditAction),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    maxLength: 128,
                    decoration: InputDecoration(
                      labelText: loc.channelEditNameLabel,
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: announceCtrl,
                    maxLength: 2000,
                    maxLines: 4,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: loc.channelEditAnnouncementLabel,
                      hintText: loc.channelEditAnnouncementHint,
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              GvDialogActions.weChatFooter(
                ctx,
                secondaryText: loc.commonCancel,
                primaryText: loc.commonSave,
                onSecondary: () => Navigator.pop(ctx),
                onPrimary: () => Navigator.pop(
                  ctx,
                  (
                    name: nameCtrl.text.trim(),
                    announcement: announceCtrl.text,
                  ),
                ),
              ),
            ],
          );
        },
      );
      if (result == null || !mounted) return;
      if (result.name.isEmpty) {
        GvToast.show(
          context,
          AppLocalizations.of(context)!.toastEnterChannelName,
        );
        return;
      }
      if (result.name == info.name && result.announcement == info.description) {
        return;
      }
      try {
        final chat = context.read<ChatProvider>();
        final updated = await chat.updateChannel(
          info.id,
          name: result.name,
          announcement: result.announcement,
        );
        if (!mounted) return;
        setState(() => _channelInfo = updated);
        chat.updateConversationDisplay(info.id, 'channel', name: updated.name);
        GvToast.show(
            context, AppLocalizations.of(context)!.toastChannelUpdated);
      } catch (e) {
        if (mounted) {
          GvToast.show(
            context,
            context.read<ApiClient>().extractErrorMessage(e),
          );
        }
      }
    } finally {
      nameCtrl.dispose();
      announceCtrl.dispose();
    }
  }

  /// 取消订阅确认：成功后本地移除会话并返回会话列表。
  Future<void> _confirmUnsubscribeChannel(ChannelInfo info) async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          title: Text(cl.channelUnsubscribeConfirmTitle),
          content: Text(cl.channelUnsubscribeConfirmBody),
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: cl.commonCancel,
              primaryText: cl.channelUnsubscribeAction,
              onSecondary: () => Navigator.pop(ctx, false),
              onPrimary: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ChatProvider>().unsubscribeChannel(info.id);
      if (!mounted) return;
      GvToast.show(context, loc.toastChannelUnsubscribed);
      _popChatRoom();
    } catch (e) {
      if (mounted) {
        GvToast.show(
          context,
          context.read<ApiClient>().extractErrorMessage(e),
        );
      }
    }
  }

  /// 删除频道确认：成功后本地移除会话并返回会话列表。
  Future<void> _confirmDeleteChannel(ChannelInfo info) async {
    final loc = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cl = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          title: Text(cl.channelDeleteConfirmTitle),
          content: Text(cl.channelDeleteConfirmBody),
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: cl.commonCancel,
              primaryText: cl.channelDeleteAction,
              onSecondary: () => Navigator.pop(ctx, false),
              onPrimary: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ChatProvider>().deleteChannel(info.id);
      if (!mounted) return;
      GvToast.show(context, loc.toastChannelDeleted);
      _popChatRoom();
    } catch (e) {
      if (mounted) {
        GvToast.show(
          context,
          context.read<ApiClient>().extractErrorMessage(e),
        );
      }
    }
  }

  void _popChatRoom() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  /// E2EE 初始化：确保设备密钥 + 完成会话握手 + 拉取密文解密（进房时触发）。
  Future<void> _bootstrapSecretE2ee(ChatProvider chat) async {
    try {
      await chat.ensureSecretChatHandshake(widget.peerId);
      if (!mounted) return;
      setState(() {});
      await chat.pullSecretMessages(widget.peerId, forceFull: true);
    } catch (e) {
      debugPrint('E2EE bootstrap failed: $e');
    }
    // 周期增量轮询密文（近似实时；拉取即触发服务端「已读后计时」）。
    _secretPollTimer?.cancel();
    _secretPollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (!mounted) return;
        final provider = context.read<ChatProvider>();
        if (!provider.secretReady(widget.peerId)) return;
        unawaited(
            provider.pullSecretMessages(widget.peerId).catchError((_) {}));
      },
    );
  }

  /// 私密群聊 E2EE 初始化：确保设备密钥 + 完成群握手 + 拉取密文解密。
  Future<void> _bootstrapSecretGroupE2ee(ChatProvider chat) async {
    try {
      await chat.ensureSecretGroupHandshake(widget.peerId);
      if (!mounted) return;
      setState(() {});
      await chat.pullSecretGroupMessages(widget.peerId, forceFull: true);
    } catch (e) {
      debugPrint('E2EE group bootstrap failed: $e');
    }
    _secretGroupPollTimer?.cancel();
    _secretGroupPollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (!mounted) return;
        final provider = context.read<ChatProvider>();
        if (!provider.secretGroupReady(widget.peerId)) return;
        unawaited(
            provider.pullSecretGroupMessages(widget.peerId).catchError((_) {}));
      },
    );
  }

  /// 私密群聊设置弹层：成员 + 安全码查看/复制 + 定时销毁（关闭/30秒/5分/1小时/1天）。
  Future<void> _showSecretGroupSettingsSheet() async {
    final chat = context.read<ChatProvider>();
    if (!chat.secretGroupReady(widget.peerId)) {
      unawaited(chat.ensureSecretGroupHandshake(widget.peerId).then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {}));
    }
    SecretGroupChatInfo? info =
        _secretGroupChat ?? chat.cachedSecretGroupChat(widget.peerId);
    if (info == null) {
      try {
        final list = await chat.mySecretGroupChats();
        if (!mounted) return;
        for (final s in list) {
          if (s.id == widget.peerId) {
            info = s;
            setState(() => _secretGroupChat = s);
            break;
          }
        }
      } catch (_) {}
    }
    if (!mounted) return;
    final resolved = info;
    final currentPolicy =
        resolved?.destroyPolicy ?? SecretChatDestroyPolicy.off;
    final safeCode = resolved?.safeCode ?? '';

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      builder: (sheetCtx) {
        final sl = AppLocalizations.of(sheetCtx)!;
        final primary = AppColors.primary.resolveFrom(sheetCtx);
        final secondary = AppColors.textSecondary.resolveFrom(sheetCtx);
        final hint = AppColors.textHint.resolveFrom(sheetCtx);
        final members = resolved?.members ?? const <SecretGroupMember>[];
        final isOwner = resolved?.ownerUserId == chat.myId;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              GvSpacing.page,
              0,
              GvSpacing.page,
              GvSpacing.page,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.lock, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      sl.secretGroupChatSettingsTitle,
                      style: GvTypography.title(
                        AppColors.textPrimary.resolveFrom(sheetCtx),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GvSpacing.xs),
                // ── 群名称 + 群公告 ──
                _secretGroupNameAnnouncementCard(
                  context: sheetCtx,
                  sl: sl,
                  primary: primary,
                  secondary: secondary,
                  hint: hint,
                  name: resolved?.name,
                  announcement: resolved?.announcement,
                  isOwner: isOwner,
                  onEditName: () =>
                      _showEditSecretGroupNameDialog(sheetCtx, chat, resolved),
                  onEditAnnouncement: () =>
                      _showEditSecretGroupAnnouncementDialog(
                          sheetCtx, chat, resolved),
                  onViewAnnouncement: () =>
                      _showSecretGroupAnnouncementViewDialog(
                          sheetCtx, resolved),
                ),
                const SizedBox(height: GvSpacing.sm),
                // ── 置顶消息 ──
                if ((resolved?.pinnedMsgId ?? '').isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: GvSpacing.sm, vertical: GvSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.bgSearchField.resolveFrom(sheetCtx),
                      borderRadius: BorderRadius.circular(GvRadii.input),
                    ),
                    child: Row(
                      children: [
                        Icon(LucideIcons.pin, size: 16, color: primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _pinnedMessagePreview(chat),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GvTypography.caption(secondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: GvSpacing.xs),
                ],
                // ── 成员（微信群风格头像网格） ──
                Text(
                  sl.secretGroupMembersTitle,
                  style: GvTypography.navTitle(
                    AppColors.textPrimary.resolveFrom(sheetCtx),
                  ),
                ),
                const SizedBox(height: GvSpacing.xs),
                _secretGroupMembersGrid(
                  context: sheetCtx,
                  sl: sl,
                  primary: primary,
                  hint: hint,
                  members: members,
                  isOwner: isOwner,
                  onRemove: isOwner
                      ? (m) =>
                          _confirmRemoveSecretGroupMember(sheetCtx, chat, m)
                      : null,
                ),
                const SizedBox(height: GvSpacing.xs),
                // ── 安全码 / 指纹核验 ──
                Text(
                  sl.secretChatSafeCodeTitle,
                  style: GvTypography.navTitle(
                    AppColors.textPrimary.resolveFrom(sheetCtx),
                  ),
                ),
                const SizedBox(height: GvSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: GvSpacing.sm,
                    vertical: GvSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSearchField.resolveFrom(sheetCtx),
                    borderRadius: BorderRadius.circular(GvRadii.input),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.fingerprint_pattern,
                          size: 18, color: secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          safeCode.isEmpty
                              ? sl.secretChatSafeCodeUnavailable
                              : safeCode,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                            color: safeCode.isEmpty
                                ? hint
                                : AppColors.textPrimary.resolveFrom(sheetCtx),
                          ),
                        ),
                      ),
                      if (safeCode.isNotEmpty)
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(LucideIcons.copy,
                              size: 17, color: secondary),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: safeCode),
                            );
                            if (sheetCtx.mounted) {
                              GvToast.show(
                                sheetCtx,
                                sl.toastSecretChatSafeCodeCopied,
                                duration: const Duration(seconds: 1),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
                if (safeCode.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sl.secretChatSafeCodeIntro,
                    style: GvTypography.caption(hint),
                  ),
                ],
                const SizedBox(height: GvSpacing.xs),
                // ── 定时销毁 ──
                Text(
                  sl.secretChatDestroyTitle,
                  style: GvTypography.navTitle(
                    AppColors.textPrimary.resolveFrom(sheetCtx),
                  ),
                ),
                const SizedBox(height: GvSpacing.xs),
                _SecretDestroyPolicyOptions(
                  current: currentPolicy,
                  onSelected: (policy) async {
                    try {
                      final updated = await chat.updateSecretGroupDestroyPolicy(
                        id: widget.peerId,
                        policy: policy,
                      );
                      if (sheetCtx.mounted) {
                        setState(() => _secretGroupChat = updated);
                        Navigator.pop(sheetCtx);
                        GvToast.show(
                          sheetCtx,
                          AppLocalizations.of(sheetCtx)!
                              .toastSecretChatDestroyUpdated,
                          duration: const Duration(seconds: 1),
                        );
                      }
                    } catch (e) {
                      if (sheetCtx.mounted) {
                        GvToast.show(
                          sheetCtx,
                          sheetCtx.read<ApiClient>().extractErrorMessage(e),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: GvSpacing.sm),
                // ── 匿名发言 ──
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '匿名发言',
                    style: GvTypography.navTitle(
                      AppColors.textPrimary.resolveFrom(sheetCtx),
                    ),
                  ),
                  subtitle: Text(
                    '开启后群内消息发送者身份对成员隐藏（仅群主可见）',
                    style: GvTypography.caption(hint),
                  ),
                  value: resolved?.anonymousEnabled ?? false,
                  onChanged: (resolved == null)
                      ? null
                      : (value) async {
                          try {
                            final updated =
                                await chat.updateSecretGroupAnonymous(
                              id: widget.peerId,
                              enabled: value,
                            );
                            if (sheetCtx.mounted) {
                              setState(() => _secretGroupChat = updated);
                            }
                          } catch (e) {
                            if (sheetCtx.mounted) {
                              GvToast.show(
                                sheetCtx,
                                sheetCtx
                                    .read<ApiClient>()
                                    .extractErrorMessage(e),
                              );
                            }
                          }
                        },
                ),
                const SizedBox(height: GvSpacing.sm),
                // ── 邀请链接 ──
                if (resolved?.ownerUserId == chat.myId) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: Icon(LucideIcons.link, size: 18, color: secondary),
                    title: Text(
                      '邀请链接',
                      style: GvTypography.navTitle(
                        AppColors.textPrimary.resolveFrom(sheetCtx),
                      ),
                    ),
                    subtitle: Text(
                      (resolved?.inviteToken?.isNotEmpty ?? false)
                          ? '已生成（7 天有效）'
                          : '生成后可分享令牌邀请好友加入',
                      style: GvTypography.caption(hint),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        try {
                          final updated = await chat
                              .generateSecretGroupInvite(widget.peerId);
                          if (sheetCtx.mounted) {
                            setState(() => _secretGroupChat = updated);
                          }
                          final token = updated.inviteToken ?? '';
                          await Clipboard.setData(ClipboardData(text: token));
                          if (sheetCtx.mounted) {
                            GvToast.show(sheetCtx, '邀请令牌已复制',
                                duration: const Duration(seconds: 1));
                          }
                        } catch (e) {
                          if (sheetCtx.mounted) {
                            GvToast.show(sheetCtx, ApiFailure.messageOf(e));
                          }
                        }
                      },
                      child: const Text('生成/复制'),
                    ),
                  ),
                  const SizedBox(height: GvSpacing.sm),
                ],
                // ── 仅群主可发言 ──
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '仅群主可发言',
                    style: GvTypography.navTitle(
                      AppColors.textPrimary.resolveFrom(sheetCtx),
                    ),
                  ),
                  subtitle: Text(
                    '开启后普通成员不能发送消息',
                    style: GvTypography.caption(hint),
                  ),
                  value: resolved?.ownerOnlyPost ?? false,
                  onChanged: (resolved == null)
                      ? null
                      : (value) async {
                          try {
                            final updated =
                                await chat.updateSecretGroupOwnerOnlyPost(
                              id: widget.peerId,
                              enabled: value,
                            );
                            if (sheetCtx.mounted) {
                              setState(() => _secretGroupChat = updated);
                            }
                          } catch (e) {
                            if (sheetCtx.mounted) {
                              GvToast.show(
                                sheetCtx,
                                sheetCtx
                                    .read<ApiClient>()
                                    .extractErrorMessage(e),
                              );
                            }
                          }
                        },
                ),
                const SizedBox(height: GvSpacing.sm),
                // ── 不同步到新设备 ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(GvSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.bgSearchField.resolveFrom(sheetCtx),
                    borderRadius: BorderRadius.circular(GvRadii.input),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.eye_off, size: 16, color: hint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sl.secretChatNoSyncHint,
                          style: GvTypography.caption(secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 群聊/私密群聊「@」成员候选：列表展示名与实际提及名分开保存。
  List<_AtMentionCandidate> _atMentionCandidates() {
    final chat = context.read<ChatProvider>();
    final friend = context.read<FriendProvider>();
    final group = context.read<GroupProvider>();
    final remote = context.read<ClientRemoteConfigProvider>();
    final l10n = AppLocalizations.of(context)!;
    final items = <_AtMentionCandidate>[];

    if (widget.chatType == 'group') {
      final groupId = int.tryParse(widget.peerId);
      final myId = chat.myId;
      final canViewAccounts = groupId != null && myId != null
          ? group.canViewOtherMemberAccounts(groupId, myId)
          : false;
      for (final m in group.currentGroupMembers) {
        final friendDisplay = friend.getFriendDisplay(m.userId);
        final isSelf = m.userId == myId;
        final showAccount = isSelf ||
            friendDisplay != null ||
            (!remote.hideGroupMemberInfo && canViewAccounts);
        final groupNickname = m.nickname?.trim() ?? '';
        // mentionLabel 会写进消息正文，必须使用公开的默认名字，不能使用好友备注。
        final friendDefaultName = isSelf
            ? chat.userDisplayName(m.userId)
            : friend.getFriendDefaultName(m.userId);
        final mentionLabel = friendDefaultName?.trim().isNotEmpty == true
            ? friendDefaultName!.trim()
            : showAccount && m.username?.trim().isNotEmpty == true
                ? m.username!.trim()
                : l10n.chatUserDefaultTitle('${m.userId}');
        items.add((
          userId: m.userId,
          displayLabel: friend.getFriendRemark(m.userId) ?? mentionLabel,
          mentionLabel: mentionLabel,
          groupNickname: groupNickname.isEmpty ? null : groupNickname,
          avatar: showAccount ? m.avatar : null,
        ));
      }
    } else if (widget.chatType == 'secret_group') {
      final members = chat.cachedSecretGroupChat(widget.peerId)?.members ??
          const <SecretGroupMember>[];
      for (final m in members) {
        final isSelf = m.userId == chat.myId;
        final mentionLabel = (isSelf
                ? chat.userDisplayName(m.userId)
                : friend.getFriendDefaultName(m.userId)) ??
            l10n.chatUserDefaultTitle('${m.userId}');
        items.add((
          userId: m.userId,
          displayLabel: friend.getFriendRemark(m.userId) ?? mentionLabel,
          mentionLabel: mentionLabel,
          groupNickname: null,
          avatar: null,
        ));
      }
    }
    return items;
  }

  /// 群聊/私密群聊「@」成员选择器：列表可展示备注，输入框仅插入默认名字。
  /// 普通群聊额外提供「@所有人」（提交 atUsers 含 "0"）。
  Future<void> _showAtMentionPicker() async {
    final items = _atMentionCandidates();
    final showAll = widget.chatType == 'group';
    if (items.isEmpty && !showAll) return;
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      builder: (sheetCtx) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              if (showAll)
                ListTile(
                  leading: const Icon(LucideIcons.at_sign, size: 28),
                  title: Text(l10n.gvMbMentionAll),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _roomBottomKey.currentState
                        ?.insertAtMention(0, l10n.gvMbMentionAll);
                  },
                ),
              for (final it in items)
                ListTile(
                  leading: GvAvatar(
                    name: it.displayLabel,
                    uid: it.userId,
                    src: it.avatar,
                    size: 40,
                  ),
                  title: Text(it.displayLabel),
                  subtitle: Text(
                    it.groupNickname == null
                        ? l10n.chatMentionGroupNicknameEmpty
                        : l10n.chatMentionGroupNickname(it.groupNickname!),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _roomBottomKey.currentState
                        ?.insertAtMention(it.userId, it.mentionLabel);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  /// 私密群聊置顶消息预览（按 pinnedMsgId 从消息列表查找，找不到回退 msgId）。
  String _pinnedMessagePreview(ChatProvider chat) {
    final msgId = _secretGroupChat?.pinnedMsgId;
    if (msgId == null || msgId.isEmpty) return '';
    final session = chat.messagesFor(widget.peerId, widget.chatType);
    for (final m in session) {
      if (m.msgId == msgId) {
        return getMessagePreview(msgType: m.msgType, content: m.content);
      }
    }
    return msgId;
  }

  /// 私密群聊「群名称 + 群公告」卡片（对齐普通群聊）。
  Widget _secretGroupNameAnnouncementCard({
    required BuildContext context,
    required AppLocalizations sl,
    required Color primary,
    required Color secondary,
    required Color hint,
    required String? name,
    required String? announcement,
    required bool isOwner,
    required VoidCallback onEditName,
    required VoidCallback onEditAnnouncement,
    required VoidCallback onViewAnnouncement,
  }) {
    final displayName = (name == null || name.trim().isEmpty)
        ? sl.secretGroupChatDefaultTitle
        : name.trim();
    final announcementValue =
        (announcement == null || announcement.trim().isEmpty)
            ? sl.groupAnnouncementRowPlaceholder
            : announcement.trim();

    Widget row({
      required String title,
      required String value,
      required VoidCallback onTap,
      required bool editable,
      int valueMaxLines = 1,
    }) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GvSpacing.sm,
        ),
        dense: true,
        title: Text(
          title,
          style: GvTypography.navTitle(
            AppColors.textPrimary.resolveFrom(context),
          ),
        ),
        subtitle: Text(
          value,
          maxLines: valueMaxLines,
          overflow: TextOverflow.ellipsis,
          style: GvTypography.caption(secondary),
        ),
        trailing: editable
            ? Icon(LucideIcons.chevron_right, size: 16, color: hint)
            : null,
        onTap: onTap,
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.bgSearchField.resolveFrom(context),
        borderRadius: BorderRadius.circular(GvRadii.input),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row(
            title: sl.groupNameLabel,
            value: displayName,
            editable: isOwner,
            onTap: isOwner ? onEditName : () {},
          ),
          const Divider(height: 1, thickness: 0.5),
          row(
            title: sl.groupAnnouncementLabel,
            value: announcementValue,
            editable: isOwner,
            valueMaxLines: 2,
            onTap: isOwner ? onEditAnnouncement : onViewAnnouncement,
          ),
        ],
      ),
    );
  }

  /// 私密群聊成员头像网格（微信群风格：头像 + 昵称；群主长按移出）。
  Widget _secretGroupMembersGrid({
    required BuildContext context,
    required AppLocalizations sl,
    required Color primary,
    required Color hint,
    required List<SecretGroupMember> members,
    required bool isOwner,
    void Function(SecretGroupMember m)? onRemove,
  }) {
    final chat = context.read<ChatProvider>();
    final friendProvider = context.read<FriendProvider>();
    final myId = chat.myId;
    return Wrap(
      spacing: GvSpacing.page,
      runSpacing: GvSpacing.page,
      children: members.map((m) {
        final display = chat.userDisplayName(m.userId) ??
            sl.chatUserDefaultTitle('${m.userId}');
        final avatarSrc = m.userId == myId
            ? null
            : friendProvider.getFriendDisplay(m.userId)?.avatar;
        return Semantics(
          label: display,
          child: InkWell(
            borderRadius: BorderRadius.circular(GvRadii.card),
            onLongPress: (onRemove != null && m.userId != myId)
                ? () => onRemove(m)
                : null,
            child: SizedBox(
              width: 56,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GvAvatar(
                      name: display, uid: m.userId, src: avatarSrc, size: 44),
                  const SizedBox(height: 4),
                  Text(
                    display,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GvTypography.small(
                      AppColors.textPrimary.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  Future<void> _showEditSecretGroupNameDialog(
    BuildContext sheetCtx,
    ChatProvider chat,
    SecretGroupChatInfo? info,
  ) async {
    final ctrl = TextEditingController(text: info?.name ?? '');
    try {
      final result = await showDialog<String>(
        context: sheetCtx,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
            actionsPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.start,
            buttonPadding: EdgeInsets.zero,
            title: Text(loc.groupEditNameTitle),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              maxLength: 128,
              decoration: InputDecoration(
                hintText: loc.groupNameFieldHint,
                counterText: '',
              ),
            ),
            actions: [
              GvDialogActions.weChatFooter(
                ctx,
                secondaryText: loc.commonCancel,
                primaryText: loc.commonSave,
                onSecondary: () => Navigator.pop(ctx),
                onPrimary: () => Navigator.pop(ctx, ctrl.text.trim()),
              ),
            ],
          );
        },
      );
      if (result == null || !mounted) return;
      if (result == (info?.name ?? '').trim()) return;
      try {
        final updated = await chat.updateSecretGroupName(
          id: widget.peerId,
          name: result,
        );
        if (mounted) setState(() => _secretGroupChat = updated);
        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      } catch (e) {
        if (sheetCtx.mounted) {
          GvToast.show(
            sheetCtx,
            sheetCtx.read<ApiClient>().extractErrorMessage(e),
          );
        }
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _showEditSecretGroupAnnouncementDialog(
    BuildContext sheetCtx,
    ChatProvider chat,
    SecretGroupChatInfo? info,
  ) async {
    final ctrl = TextEditingController(text: info?.announcement ?? '');
    try {
      final result = await showDialog<String>(
        context: sheetCtx,
        builder: (ctx) {
          final loc = AppLocalizations.of(ctx)!;
          return AlertDialog(
            actionsPadding: EdgeInsets.zero,
            actionsAlignment: MainAxisAlignment.start,
            buttonPadding: EdgeInsets.zero,
            title: Text(loc.groupEditAnnouncementTitle),
            content: SizedBox(
              width: double.maxFinite,
              child: TextField(
                controller: ctrl,
                autofocus: true,
                maxLength: 2000,
                maxLines: 8,
                minLines: 4,
                decoration: InputDecoration(
                  hintText: loc.groupAnnouncementFieldHint,
                  alignLabelWithHint: true,
                ),
              ),
            ),
            actions: [
              GvDialogActions.weChatFooter(
                ctx,
                secondaryText: loc.commonCancel,
                primaryText: loc.commonSave,
                onSecondary: () => Navigator.pop(ctx),
                onPrimary: () => Navigator.pop(ctx, ctrl.text),
              ),
            ],
          );
        },
      );
      if (result == null || !mounted) return;
      final next = result.trim();
      if (next == (info?.announcement ?? '').trim()) return;
      try {
        final updated = await chat.updateSecretGroupAnnouncement(
          id: widget.peerId,
          announcement: next,
        );
        if (mounted) setState(() => _secretGroupChat = updated);
        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
      } catch (e) {
        if (sheetCtx.mounted) {
          GvToast.show(
            sheetCtx,
            sheetCtx.read<ApiClient>().extractErrorMessage(e),
          );
        }
      }
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _showSecretGroupAnnouncementViewDialog(
    BuildContext sheetCtx,
    SecretGroupChatInfo? info,
  ) async {
    final body = info?.announcement?.trim() ?? '';
    await showDialog<void>(
      context: sheetCtx,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          content: SingleChildScrollView(
            child: Text(body.isEmpty ? l.groupAnnouncementViewEmpty : body),
          ),
          actions: [
            GvDialogActions.weChatSingle(
              ctx,
              text: l.commonOk,
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRemoveSecretGroupMember(
    BuildContext sheetCtx,
    ChatProvider chat,
    SecretGroupMember m,
  ) async {
    final loc = AppLocalizations.of(sheetCtx)!;
    final display = chat.userDisplayName(m.userId) ??
        loc.chatUserDefaultTitle('${m.userId}');
    final ok = await showDialog<bool>(
      context: sheetCtx,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx)!;
        return AlertDialog(
          actionsPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.start,
          buttonPadding: EdgeInsets.zero,
          content: Text(l.groupRemoveMemberConfirm(display)),
          actions: [
            GvDialogActions.weChatFooter(
              ctx,
              secondaryText: l.commonCancel,
              primaryText: l.groupRemoveMemberAction,
              onSecondary: () => Navigator.pop(ctx, false),
              onPrimary: () => Navigator.pop(ctx, true),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    try {
      final updated = await chat.removeSecretGroupMember(
        id: widget.peerId,
        userId: m.userId,
      );
      if (mounted) setState(() => _secretGroupChat = updated);
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);
    } catch (e) {
      if (sheetCtx.mounted) {
        GvToast.show(
          sheetCtx,
          sheetCtx.read<ApiClient>().extractErrorMessage(e),
        );
      }
    }
  }

  /// 展示安全码：优先本地计算的 E2EE 指纹（双方公钥 SHA-256），未握手回退服务端值。
  String _displaySafeCode(String unavailableText, SecretChatInfo? info) {
    final chat = context.read<ChatProvider>();
    final local = chat.secretSafeCode(widget.peerId);
    if (local != null && local.isNotEmpty) return local;
    if (info != null && info.safeCode.isNotEmpty) return info.safeCode;
    return unavailableText;
  }

  /// 私密聊天设置弹层：E2EE 锁标识 + 安全码查看/复制 + 定时销毁（关闭/30秒/5分/1小时/1天）+ 不同步提示。
  Future<void> _showSecretChatSettingsSheet() async {
    final chat = context.read<ChatProvider>();
    // 打开设置时主动握手/刷新：双方公钥齐备后安全码自动生成。
    if (!chat.secretReady(widget.peerId)) {
      unawaited(chat.ensureSecretChatHandshake(widget.peerId).then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {}));
    }
    SecretChatInfo? info = _secretChat ?? chat.cachedSecretChat(widget.peerId);
    if (info == null) {
      try {
        final list = await chat.mySecretChats();
        if (!mounted) return;
        for (final s in list) {
          if (s.id == widget.peerId) {
            info = s;
            setState(() => _secretChat = s);
            break;
          }
        }
      } catch (_) {}
    }
    if (!mounted) return;
    final resolved = info;
    final currentPolicy =
        resolved?.destroyPolicy ?? SecretChatDestroyPolicy.off;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      builder: (sheetCtx) {
        final sl = AppLocalizations.of(sheetCtx)!;
        final primary = AppColors.primary.resolveFrom(sheetCtx);
        final secondary = AppColors.textSecondary.resolveFrom(sheetCtx);
        final hint = AppColors.textHint.resolveFrom(sheetCtx);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              GvSpacing.page,
              0,
              GvSpacing.page,
              GvSpacing.page,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.lock, size: 18, color: primary),
                    const SizedBox(width: 8),
                    Text(
                      sl.secretChatSettingsTitle,
                      style: GvTypography.title(
                        AppColors.textPrimary.resolveFrom(sheetCtx),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GvSpacing.xs),
                // ── 安全码 / 指纹核验 ──
                Text(
                  sl.secretChatSafeCodeTitle,
                  style: GvTypography.navTitle(
                    AppColors.textPrimary.resolveFrom(sheetCtx),
                  ),
                ),
                const SizedBox(height: GvSpacing.xs),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: GvSpacing.sm,
                    vertical: GvSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSearchField.resolveFrom(sheetCtx),
                    borderRadius: BorderRadius.circular(GvRadii.input),
                  ),
                  child: Row(
                    children: [
                      Icon(LucideIcons.fingerprint_pattern,
                          size: 18, color: secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _displaySafeCode(
                            sl.secretChatSafeCodeUnavailable,
                            resolved,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'monospace',
                            letterSpacing: 1.2,
                            color: _displaySafeCode(
                                      sl.secretChatSafeCodeUnavailable,
                                      resolved,
                                    ) !=
                                    sl.secretChatSafeCodeUnavailable
                                ? AppColors.textPrimary.resolveFrom(sheetCtx)
                                : hint,
                          ),
                        ),
                      ),
                      if (_displaySafeCode(
                            sl.secretChatSafeCodeUnavailable,
                            resolved,
                          ) !=
                          sl.secretChatSafeCodeUnavailable)
                        IconButton(
                          key: GvAutomationKeys.secretChatSafeCodeCopy,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(LucideIcons.copy,
                              size: 17, color: secondary),
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: _displaySafeCode(
                                  sl.secretChatSafeCodeUnavailable,
                                  resolved,
                                ),
                              ),
                            );
                            if (sheetCtx.mounted) {
                              GvToast.show(
                                sheetCtx,
                                sl.toastSecretChatSafeCodeCopied,
                                duration: const Duration(seconds: 1),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
                if (_displaySafeCode(
                      sl.secretChatSafeCodeUnavailable,
                      resolved,
                    ) !=
                    sl.secretChatSafeCodeUnavailable) ...[
                  const SizedBox(height: 4),
                  Text(
                    sl.secretChatSafeCodeIntro,
                    style: GvTypography.caption(hint),
                  ),
                ],
                const SizedBox(height: GvSpacing.xs),
                // ── 定时销毁 ──
                Text(
                  sl.secretChatDestroyTitle,
                  style: GvTypography.navTitle(
                    AppColors.textPrimary.resolveFrom(sheetCtx),
                  ),
                ),
                const SizedBox(height: GvSpacing.xs),
                _SecretDestroyPolicyOptions(
                  current: currentPolicy,
                  onSelected: (policy) async {
                    try {
                      final updated = await chat.updateSecretChatDestroyPolicy(
                        id: widget.peerId,
                        policy: policy,
                      );
                      if (sheetCtx.mounted) {
                        setState(() => _secretChat = updated);
                        Navigator.pop(sheetCtx);
                        GvToast.show(
                          sheetCtx,
                          AppLocalizations.of(sheetCtx)!
                              .toastSecretChatDestroyUpdated,
                          duration: const Duration(seconds: 1),
                        );
                      }
                    } catch (e) {
                      if (sheetCtx.mounted) {
                        GvToast.show(
                          sheetCtx,
                          sheetCtx.read<ApiClient>().extractErrorMessage(e),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: GvSpacing.sm),
                // ── 不同步到新设备 ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(GvSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.bgSearchField.resolveFrom(sheetCtx),
                    borderRadius: BorderRadius.circular(GvRadii.input),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.eye_off, size: 16, color: hint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sl.secretChatNoSyncHint,
                          style: GvTypography.caption(secondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 从相册添加自定义表情（正方形裁剪 → ≤400px → 上传 scope=emoji）。
  Future<void> _addCustomStickerFromPanel() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 92,
    );
    if (!mounted || x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    final cropped = await gvPushAvatarCropForResult(
      context,
      bytes,
      stickerCrop: true,
    );
    if (!mounted || cropped == null) return;
    final ready = gvPrepareStickerBytes(cropped);
    try {
      final api = context.read<ImApi>();
      final uploaded =
          await api.uploadBytes(ready, 'sticker.jpg', scope: 'emoji');
      await api.addUserSticker(uploaded.url);
      await _roomBottomKey.currentState?.stickerPanelKey.currentState
          ?.reloadMyStickers();
      if (mounted) {
        GvToast.show(context, AppLocalizations.of(context)!.toastStickerAdded);
      }
    } catch (e) {
      if (mounted) {
        GvToast.show(context, context.read<ApiClient>().extractErrorMessage(e));
      }
    }
  }

  void _sendSticker(String stickerUrl) {
    if (!_ensureChatFeatureAllowed()) return;
    final chat = context.read<ChatProvider>();
    if (widget.chatType == 'secret') {
      unawaited(_sendSecretText(
        chat,
        stickerUrl,
        msgType: 'emoji',
        convPreview: AppLocalizations.of(context)!.chatStickerPreview,
      ));
    } else if (widget.chatType == 'secret_group') {
      unawaited(_sendSecretGroupText(
        chat,
        stickerUrl,
        msgType: 'emoji',
        convPreview: AppLocalizations.of(context)!.chatStickerPreview,
      ));
    } else {
      chat.sendMessage(widget.peerId, widget.chatType, 'emoji', stickerUrl,
          replyMsgId: _replyTo?.msgId,
          convPreview: AppLocalizations.of(context)!.chatStickerPreview);
    }
    setState(() => _replyTo = null);
  }
}

class _PendingImageDraft {
  const _PendingImageDraft({
    required this.file,
    required this.filename,
    this.bytes,
  });

  final File file;
  final Uint8List? bytes;
  final String filename;
}

/// 私密聊天「定时销毁」选项列表（关闭 / 30秒 / 5分 / 1小时 / 1天）。
class _SecretDestroyPolicyOptions extends StatelessWidget {
  const _SecretDestroyPolicyOptions({
    required this.current,
    required this.onSelected,
  });

  final String current;
  final void Function(String policy) onSelected;

  String _labelFor(String policy, AppLocalizations l10n) {
    switch (policy) {
      case SecretChatDestroyPolicy.s1:
        return l10n.secretChatDestroy1s;
      case SecretChatDestroyPolicy.s2:
        return l10n.secretChatDestroy2s;
      case SecretChatDestroyPolicy.s5:
        return l10n.secretChatDestroy5s;
      case SecretChatDestroyPolicy.s10:
        return l10n.secretChatDestroy10s;
      case SecretChatDestroyPolicy.s30:
        return l10n.secretChatDestroy30s;
      case SecretChatDestroyPolicy.m1:
        return l10n.secretChatDestroy1m;
      case SecretChatDestroyPolicy.m5:
        return l10n.secretChatDestroy5m;
      case SecretChatDestroyPolicy.h1:
        return l10n.secretChatDestroy1h;
      case SecretChatDestroyPolicy.d1:
        return l10n.secretChatDestroy1d;
      case SecretChatDestroyPolicy.w1:
        return l10n.secretChatDestroy1w;
      default:
        return l10n.secretChatDestroyOff;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = _labelFor(current, l10n);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        current == SecretChatDestroyPolicy.off
            ? LucideIcons.timer_off
            : LucideIcons.timer,
        size: 18,
        color: AppColors.textSecondary.resolveFrom(context),
      ),
      title: Text(
        label,
        style: GvTypography.navTitle(
          AppColors.textPrimary.resolveFrom(context),
        ),
      ),
      trailing: Icon(
        LucideIcons.chevron_right,
        size: 18,
        color: AppColors.textHint.resolveFrom(context),
      ),
      onTap: () => _showPicker(context, l10n),
    );
  }

  Future<void> _showPicker(BuildContext context, AppLocalizations l10n) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      builder: (pickerCtx) {
        final primary = AppColors.primary.resolveFrom(pickerCtx);
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final policy in SecretChatDestroyPolicy.all)
                ListTile(
                  leading: Icon(
                    policy == SecretChatDestroyPolicy.off
                        ? LucideIcons.timer_off
                        : LucideIcons.timer,
                    size: 18,
                    color: AppColors.textSecondary.resolveFrom(pickerCtx),
                  ),
                  title: Text(
                    _labelFor(policy, l10n),
                    style: GvTypography.navTitle(
                      AppColors.textPrimary.resolveFrom(pickerCtx),
                    ),
                  ),
                  trailing: current == policy
                      ? Icon(LucideIcons.check, size: 18, color: primary)
                      : null,
                  onTap: () => Navigator.pop(pickerCtx, policy),
                ),
            ],
          ),
        );
      },
    );
    if (selected == null || selected == current) return;
    onSelected(selected);
  }
}
