import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gv_core/gv_core.dart';

import '../core/api_failure.dart';
import '../core/app_lifecycle_observer.dart';
import '../core/conversation_preview.dart';
import '../models/channel_models.dart';
import '../models/chat_backup.dart';
import '../models/chat_session_storage_stat.dart';
import '../models/message_sync.dart';
import '../models/outgoing_call_trace.dart';
import '../models/secret_chat_models.dart';
import '../models/secret_group_chat_models.dart';
import '../repositories/chat_repository.dart';
import '../services/e2ee/e2ee_manager.dart';
import 'friend_provider.dart';
import 'group_provider.dart';
import 'client_remote_config_provider.dart';

import 'chat/chat_address_book_sync_coordinator.dart';
import 'chat/chat_message_merge.dart';
import 'chat/chat_history_coordinator.dart';
import 'chat/chat_in_app_banner_controller.dart';
import 'chat/chat_local_store.dart';
import 'chat/chat_message_lifecycle_coordinator.dart';
import 'chat/chat_outbound_message_coordinator.dart';
import 'chat/chat_provider_types.dart';
import 'chat/chat_raw_message_parsing.dart';
import 'chat/chat_realtime_message_coordinator.dart';
import 'chat/chat_typing_coordinator.dart';

export 'chat/chat_provider_types.dart';

/// 会话列表、消息映射、WebSocket 收发与历史分页的集中状态（Clean Architecture 中的应用服务角色）。
class ChatProvider extends ChangeNotifier {
  ChatProvider(
    this._local,
    this._chat,
    this._socket,
    this._friend,
    this._group,
    this._e2ee,
  ) {
    _banner = ChatInAppBannerController(notifyChanged: notifyListeners);
    _addressBookSync = ChatAddressBookSyncCoordinator(
      myId: () => myId,
      hasFriendDisplay: (userId) => _friend.getFriendDisplay(userId) != null,
      hasGroup: (groupId) => _group.groups.any((g) => '${g.id}' == groupId),
      loadFriends: _friend.loadFriends,
      loadGroups: _group.loadGroups,
      applyDisplayNames: applyDisplayNamesFromContactProviders,
      saveConversations: saveConversations,
    );
    _lifecycle = ChatMessageLifecycleCoordinator(
      messageMap: messageMap,
      pendingAcks: pendingAcks,
      myId: () => myId,
      conversations: () => conversations,
      hiddenMessagesByChat: () => hiddenMessagesByChat,
      setHiddenMessagesByChat: (next) {
        hiddenMessagesByChat = next;
      },
      chatKey: chatKey,
      isMessageLocallyCleared: _isMessageLocallyCleared,
      persistConversations: _persistConversations,
      persistHidden: _persistHidden,
      persistMessageUpdate: (message) {
        unawaited(_local.updateMessage(message));
      },
      deletePersistedMessage: (msgId) {
        unawaited(_local.deleteMessage(msgId));
      },
      clearPersistedSession: (peerId, chatType) {
        unawaited(_local.clearSession(peerId, chatType));
      },
      notifyChanged: notifyListeners,
    );
    _outbound = ChatOutboundMessageCoordinator(
      socket: _socket,
      myId: () => myId,
      selfDisplayName: () => _local.selfDisplayName,
      chatKey: chatKey,
      messageMap: messageMap,
      pendingAcks: pendingAcks,
      upsertConversation: upsertConversation,
      refreshConversationLastFromSession:
          _lifecycle.refreshConversationLastFromSession,
      persistPendingMessage: (peerId, message) {
        unawaited(_local.savePendingMessage(peerId, message));
      },
      confirmPendingMessage: (peerId, clientMsgId, confirmed) {
        unawaited(
          _local.confirmPendingMessage(peerId, clientMsgId, confirmed),
        );
      },
      removePendingMessage: (clientMsgId) {
        unawaited(_local.removePendingMessage(clientMsgId));
      },
      enqueueWsError: _wsErrorQueue.add,
      notifyChanged: notifyListeners,
    );
    _realtime = ChatRealtimeMessageCoordinator(
      myId: () => myId,
      currentChatId: () => currentChatId,
      currentChatType: () => currentChatType,
      isForeground: () => isAppForeground(),
      allowRealtimeMergeIntoCurrentChatList: () =>
          allowRealtimeMergeIntoCurrentChatList,
      messageMap: messageMap,
      pendingAcks: pendingAcks,
      chatKey: chatKey,
      deferredRealtimeSessionInsert: () => deferredRealtimeSessionInsert,
      setDeferredRealtimeSessionInsert: (next) {
        deferredRealtimeSessionInsert = next;
      },
      bumpRealtimeIngestEpoch: _bumpRealtimeIngestEpoch,
      isMessageMutedByReadWatermark: _isMessageMutedByReadWatermark,
      isMessageLocallyCleared: _isMessageLocallyCleared,
      upsertConversation: upsertConversation,
      persistMessage: (peerId, message) {
        unawaited(_local.saveMessages(peerId, [message]));
      },
      confirmPendingMessage: (peerId, clientMsgId, confirmed) {
        unawaited(
          _local.confirmPendingMessage(peerId, clientMsgId, confirmed),
        );
      },
      maybeScheduleAddressBookSyncForIncoming:
          _maybeScheduleAddressBookSyncForIncoming,
      markRead: markRead,
      maybeTriggerInAppNewMessageBanner: _banner.trigger,
      notifyChanged: notifyListeners,
    );
    _typing = ChatTypingCoordinator(
      typingUsers: typingUsers,
      notifyChanged: notifyListeners,
    );
  }

  final ChatLocalStore _local;
  final ChatRepository _chat;
  final GvSocketClient _socket;
  final FriendProvider _friend;
  final GroupProvider _group;
  final E2eeManager _e2ee;
  late final ChatAddressBookSyncCoordinator _addressBookSync;
  late final ChatInAppBannerController _banner;
  late final ChatMessageLifecycleCoordinator _lifecycle;
  late final ChatOutboundMessageCoordinator _outbound;
  late final ChatRealtimeMessageCoordinator _realtime;
  late final ChatTypingCoordinator _typing;

  List<Conversation> conversations = [];
  final Map<String, List<ChatMessage>> messageMap = {};

  int _lastSyncedSyncSeq = 0;
  Future<void>? _messageSyncTask;
  bool _messageSyncRequested = false;
  int _messageSyncGeneration = 0;
  Timer? _messageSyncRetryTimer;
  int _messageSyncRetryAttempt = 0;

  bool get isSynchronizingMessages => _messageSyncTask != null;

  /// 用户已浏览到的消息时间上界（持久化）；冷启动时离线/WS 重放若时间不晚于此则不增加未读。
  Map<String, DateTime> _readWatermarkByChat = {};

  /// Per-account, per-device cutoff for local-only chat history clearing.
  Map<String, DateTime> _localClearWatermarkByChat = {};

  /// [chatKey] -> 单调计数。仅实时接收侧向该会话可见列表写入新气泡时递增；
  /// [loadHistory]、分页、[replaceSessionWithAnchorWindow] 等 HTTP 历史**不**递增（与列表尾 [msgId] 解耦）。
  final Map<String, int> _realtimeIngestEpochBySession = {};

  final ChatHistoryCoordinator _historyCoordinator = ChatHistoryCoordinator();
  Map<String, List<dynamic>> hiddenMessagesByChat = {};
  String? currentChatId;
  String currentChatType = 'private';
  final Map<String, TypingEntry> typingUsers = {};
  final Map<String, ChatMessage> pendingAcks = {};
  final Set<String> _dissolvedGroupIds = <String>{};

  bool isGroupDissolved(String groupId) => _dissolvedGroupIds.contains(groupId);

  void markGroupDissolved(String groupId) {
    _dissolvedGroupIds.add(groupId);
    notifyListeners();
  }

  /// App 是否在前台（由 AppLifecycleObserver 注入）；默认 true，避免未接线时行为变化。
  /// 用于「仅前台且当前聊天页可见才自动已读/不累计未读」。
  bool Function() isAppForeground = () => true;

  /// 频道详情内存缓存（含 owner 角色，用于订阅者只读判定）。
  final Map<String, ChannelInfo> _channelInfoCache = {};

  /// 私密会话内存缓存（含安全码与销毁策略）。
  final Map<String, SecretChatInfo> _secretChatCache = {};

  /// 私密群聊会话内存缓存（含成员公钥/安全码与销毁策略）。
  final Map<String, SecretGroupChatInfo> _secretGroupChatCache = {};

  /// 私密群聊消息已拉取的最大 seq（增量游标，避免轮询时全量解密）。
  final Map<String, int> _secretGroupPulledSeq = {};

  /// 私密消息已拉取的最大 seq（增量游标，避免轮询时全量解密）。
  final Map<String, int> _secretPulledSeq = {};

  /// 私密消息已向服务端上报「已读」的最大 seq（销毁计时由已读上报触发，拉取不触发）。
  final Map<String, int> _secretReadReportedSeq = {};

  /// 私密消息已同步的销毁状态游标：secretChatId -> 已处理的最大销毁时刻（destroyAt）。
  /// 销毁计时与执行完全由服务端权威控制，端侧只按服务端返回的 destroyed 标识移除本地消息。
  final Map<String, DateTime> _secretDestroySyncedAt = {};

  /// 私密群聊消息已向服务端上报「已读」的最大 seq（销毁计时由已读上报触发）。
  final Map<String, int> _secretGroupReadReportedSeq = {};

  /// 私密群聊消息已同步的销毁状态游标：groupId -> 已处理的最大销毁时刻（destroyAt）。
  final Map<String, DateTime> _secretGroupDestroySyncedAt = {};

  /// 与 [ClientRemoteConfigProvider.settings.feature.readReceiptEnabled] 同步；为 false 时不向服务端上报已读。
  bool readReceiptEnabled = true;

  /// 当前打开的会话在「向新」方向是否已无未加载历史（由聊天页根据分页状态同步）。
  /// 为 false 时实时/离线补全不入 [messageMap]，避免与后续向新分页错序。
  bool allowRealtimeMergeIntoCurrentChatList = true;

  /// 当前房、且 [allowRealtimeMergeIntoCurrentChatList] 为 true 时，对方推送先入此结构，测高后再提交。
  DeferredRealtimeSessionInsert? deferredRealtimeSessionInsert;

  /// 用于「应用在前台但不在该会话」时，决定是否展示应用内新消息顶栏。
  void bindAppLifecycle(AppLifecycleObserver observer) {
    _banner.bindAppLifecycle(observer);
  }

  /// `true` 时由顶层在屏幕上方绘制短时提示（无点击，约 3s）。
  bool get showInAppNewMessageBanner => _banner.visible;

  void setAllowRealtimeMergeIntoCurrentChatList(bool allowed) {
    allowRealtimeMergeIntoCurrentChatList = allowed;
  }

  void setReadReceiptEnabled(bool enabled) {
    readReceiptEnabled = enabled;
  }

  int? get myId => _local.myId;

  /// 与 [ImUser.displayName] 一致，用于「与自己私聊」等场景无好友记录时的展示。
  String? get selfDisplayNameFromStorage {
    return _local.selfDisplayName;
  }

  List<ChatMessage> get currentMessages {
    if (currentChatId == null) return [];
    final key = chatKey(currentChatType, currentChatId!);
    return List<ChatMessage>.from(messageMap[key] ?? []);
  }

  /// 服务端返回的权威未读总数；接口失败时回退到本地会话合计。
  int _serverTotalUnread = 0;
  bool _hasServerUnread = false;

  /// tab 角标：服务端权威总数，但**永不小于列表内会话角标之和**。
  ///
  /// 两个数据源来自两次独立请求（总数 / 按会话），网络时序或本地乐观扣减都可能让总数
  /// 短暂偏小，出现「tab 角标 1、群会话角标 2」这种自相矛盾的展示。列表角标是用户眼睛
  /// 能直接核对的下限，因此这里取两者较大值，保证展示上永远不矛盾。
  int get totalUnread {
    final visibleSum = conversations
        .where(_isUnreadCountEnabled)
        .fold<int>(0, (sum, conversation) => sum + conversation.unread);
    if (!_hasServerUnread) return visibleSum;
    return visibleSum > _serverTotalUnread ? visibleSum : _serverTotalUnread;
  }

  /// 会话角标也遵循后台聊天类型开关；关闭类型时立即隐藏本地旧值。
  int unreadForConversation(Conversation conversation) =>
      _isUnreadCountEnabled(conversation) ? conversation.unread : 0;

  ClientRemoteConfigProvider? _boundRemoteConfig;

  void bindRemoteConfig(ClientRemoteConfigProvider provider) {
    if (identical(_boundRemoteConfig, provider)) return;
    _boundRemoteConfig?.removeListener(_onRemoteConfigChanged);
    _boundRemoteConfig = provider;
    provider.addListener(_onRemoteConfigChanged);
  }

  void _onRemoteConfigChanged() {
    _serverTotalUnread = 0;
    _hasServerUnread = false;
    notifyListeners();
    _scheduleUnreadSync();
  }

  @override
  void dispose() {
    _boundRemoteConfig?.removeListener(_onRemoteConfigChanged);
    _unreadSyncDebounce?.cancel();
    _messageSyncRetryTimer?.cancel();
    super.dispose();
  }

  bool _isUnreadCountEnabled(Conversation conversation) {
    final remote = _boundRemoteConfig;
    if (remote == null) return true;
    return switch (conversation.chatType) {
      'private' => remote.privateChatEnabled,
      'group' => remote.groupChatEnabled,
      'channel' => remote.channelEnabled,
      'secret' => remote.secretChatEnabled,
      'secret_group' => remote.secretGroupChatEnabled,
      _ => false,
    };
  }

  List<Conversation> get sortedConversations {
    final list = List<Conversation>.from(conversations);
    list.sort((a, b) {
      if (a.pinned && !b.pinned) return -1;
      if (!a.pinned && b.pinned) return 1;
      return b.lastTime.compareTo(a.lastTime);
    });
    return list;
  }

  String chatKey(String chatType, String peerId) => '$chatType:$peerId';

  void _bumpRealtimeIngestEpoch(String sessionKey) {
    _realtimeIngestEpochBySession[sessionKey] =
        (_realtimeIngestEpochBySession[sessionKey] ?? 0) + 1;
  }

  /// 供聊天室「新消息」角标：仅随 WebSocket 推送写入列表变大。
  int realtimeIngestEpochForSession(String peerId, String chatType) =>
      _realtimeIngestEpochBySession[chatKey(chatType, peerId)] ?? 0;

  void _persistConversations() {
    unawaited(_local.saveConversations(conversations));
  }

  void _persistMessages(String peerId, Iterable<ChatMessage> messages) {
    unawaited(_local.saveMessages(peerId, messages));
  }

  /// After mutating conversation rows in place (e.g. name refresh from friend list).
  void saveConversations() {
    _persistConversations();
    notifyListeners();
  }

  /// Updates one cached conversation's display identity after its contact/group
  /// data changes.
  ///
  /// Returns false without persisting or notifying when the row is absent or
  /// already has the requested values. A null [avatar] preserves the current
  /// avatar, while an empty value clears it.
  bool updateConversationDisplay(
    String peerId,
    String chatType, {
    required String name,
    String? avatar,
  }) {
    final nextName = name.trim();
    if (nextName.isEmpty) return false;
    final index = conversations.indexWhere(
      (conversation) =>
          conversation.id == peerId && conversation.chatType == chatType,
    );
    if (index < 0) return false;
    final current = conversations[index];
    final nextAvatar = avatar?.trim();
    if (current.name == nextName &&
        (nextAvatar == null || current.avatar == nextAvatar)) {
      return false;
    }
    conversations[index] = current.copyWith(
      name: nextName,
      avatar: nextAvatar ?? current.avatar,
    );
    _persistConversations();
    notifyListeners();
    return true;
  }

  void _persistHidden() {
    unawaited(_local.saveHiddenMessages(hiddenMessagesByChat));
  }

  DateTime? _readWatermarkAt(String sessionKey) =>
      _readWatermarkByChat[sessionKey];

  void _bumpReadWatermark(String sessionKey, DateTime at) {
    final prev = _readWatermarkByChat[sessionKey];
    if (prev != null && !at.isAfter(prev)) return;
    _readWatermarkByChat[sessionKey] = at;
    _local.saveReadWatermarksLater(_readWatermarkByChat);
  }

  bool _isMessageMutedByReadWatermark(String sessionKey, ChatMessage msg) {
    final w = _readWatermarkAt(sessionKey);
    return w != null && !msg.timestamp.isAfter(w);
  }

  bool _isMessageLocallyCleared(String sessionKey, ChatMessage msg) {
    return _isMessageLocallyClearedAt(sessionKey, msg.timestamp);
  }

  bool _isMessageLocallyClearedAt(String sessionKey, DateTime timestamp) {
    final cutoff = _localClearWatermarkByChat[sessionKey];
    return cutoff != null && !timestamp.isAfter(cutoff);
  }

  void _bumpReadWatermarkFromMsgIds(
    List<String> msgIds, {
    String? peerId,
    String? chatType,
  }) {
    if (msgIds.isEmpty) return;
    if (peerId != null && chatType != null) {
      final key = chatKey(chatType, peerId);
      final list = messageMap[key] ?? [];
      DateTime? maxTs;
      for (final m in list) {
        if (msgIds.contains(m.msgId)) {
          if (maxTs == null || m.timestamp.isAfter(maxTs)) maxTs = m.timestamp;
        }
      }
      if (maxTs != null) _bumpReadWatermark(key, maxTs);
      return;
    }
    final byKey = <String, DateTime>{};
    for (final e in messageMap.entries) {
      for (final m in e.value) {
        if (msgIds.contains(m.msgId)) {
          final prev = byKey[e.key];
          if (prev == null || m.timestamp.isAfter(prev)) {
            byKey[e.key] = m.timestamp;
          }
        }
      }
    }
    for (final e in byKey.entries) {
      _bumpReadWatermark(e.key, e.value);
    }
  }

  Future<void> hydrateFromDisk() async {
    final syncGeneration = ++_messageSyncGeneration;
    final accountId = myId;
    _messageSyncRetryTimer?.cancel();
    _messageSyncRetryTimer = null;
    _messageSyncRetryAttempt = 0;
    _messageSyncRequested = false;
    _messageSyncTask = null;
    await _local.migrateLegacyChatKeysIfNeeded();
    conversations = await _local.loadConversations();
    hiddenMessagesByChat = _local.loadHiddenMessages();
    _readWatermarkByChat = _local.loadReadWatermarks();
    _localClearWatermarkByChat = _local.loadLocalClearWatermarks();
    final pending = await _local.loadPendingMessages();
    final lastSyncedSyncSeq =
        accountId == null ? 0 : await _local.loadLastSyncedSyncSeq(accountId);
    if (syncGeneration != _messageSyncGeneration || accountId != myId) return;
    _lastSyncedSyncSeq = lastSyncedSyncSeq;
    for (final message in pending) {
      final peerId = message.toId;
      final key = chatKey(message.chatType, peerId);
      // 私密聊天消息走 HTTP /secret-messages（E2EE 密文链路），不依赖 WS ack；
      // 历史版本遗留的 secret pending 必须清理，否则每次重连都会以 chat:send 重发
      // 并被服务端拒绝（甚至曾导致连接被踢、普通消息一直「发送中」）。
      if (message.chatType == 'secret') {
        final staleClientId = message.clientMsgId ?? '';
        if (staleClientId.isNotEmpty) {
          unawaited(_local.removePendingMessage(staleClientId));
        }
        continue;
      }
      messageMap.putIfAbsent(key, () => []);
      if (!messageMap[key]!.any(
        (item) => item.clientMsgId == message.clientMsgId,
      )) {
        insertChatMessageChronologically(messageMap[key]!, message);
      }
      final clientId = message.clientMsgId;
      if (clientId != null && clientId.isNotEmpty) {
        pendingAcks[clientId] = message;
      }
    }
    var watermarksDirty = false;
    for (final c in conversations) {
      if (c.unread == 0) {
        final key = chatKey(c.chatType, c.id);
        final prev = _readWatermarkByChat[key];
        final lt = c.lastTime;
        if (prev == null || lt.isAfter(prev)) {
          _readWatermarkByChat[key] = lt;
          watermarksDirty = true;
        }
      }
    }
    if (watermarksDirty) {
      _local.saveReadWatermarksLater(_readWatermarkByChat);
    }
    notifyListeners();
    unawaited(syncMutedConversations());
    unawaited(syncUnreadCounts());
  }

  Future<void> loadCachedMessages(
    String peerId,
    String chatType, {
    int limit = 100,
  }) async {
    final cached = await _local.loadLatestMessages(
      peerId,
      chatType,
      limit: limit,
    );
    if (cached.isEmpty) return;
    final key = chatKey(chatType, peerId);
    await _historyCoordinator.withMergeLock<void>(key, () {
      final byId = <String, ChatMessage>{};
      final byClientId = <String, String>{};
      final visibleCached = cached
          .where((message) => !_isMessageLocallyCleared(key, message))
          .toList();
      for (final message in [
        ...visibleCached,
        ...(messageMap[key] ?? const <ChatMessage>[]),
      ]) {
        final clientId = message.clientMsgId?.trim();
        if (clientId != null && clientId.isNotEmpty) {
          final previousId = byClientId[clientId];
          if (previousId != null && previousId != message.msgId) {
            byId.remove(previousId);
          }
          byClientId[clientId] = message.msgId;
        }
        byId[message.msgId] = message;
      }
      final merged = byId.values.toList();
      sortChatMessagesChronological(merged);
      messageMap[key] = merged;
      notifyListeners();
    });
  }

  void retryPendingMessages() => _outbound.retryPendingMessages();

  /// 登出或 token 失效时清空内存态，避免下一账号短暂看到上一账号列表。
  void resetForLogout() {
    _dissolvedGroupIds.clear();
    _messageSyncGeneration++;
    _messageSyncRequested = false;
    _messageSyncTask = null;
    _lastSyncedSyncSeq = 0;
    _messageSyncRetryTimer?.cancel();
    _messageSyncRetryTimer = null;
    _messageSyncRetryAttempt = 0;
    _serverTotalUnread = 0;
    _hasServerUnread = false;
    _unreadSyncGeneration++;
    conversations = [];
    messageMap.clear();
    _readWatermarkByChat = {};
    _localClearWatermarkByChat = {};
    hiddenMessagesByChat = {};
    _channelInfoCache.clear();
    _secretChatCache.clear();
    _secretGroupChatCache.clear();
    _secretGroupPulledSeq.clear();
    _secretPulledSeq.clear();
    _secretReadReportedSeq.clear();
    _secretDestroySyncedAt.clear();
    _secretGroupReadReportedSeq.clear();
    _secretGroupDestroySyncedAt.clear();
    currentChatId = null;
    currentChatType = 'private';
    typingUsers.clear();
    pendingAcks.clear();
    _historyCoordinator.clear();
    allowRealtimeMergeIntoCurrentChatList = true;
    deferredRealtimeSessionInsert = null;
    _banner.reset();
    _addressBookSync.reset();
    notifyListeners();
  }

  /// 用好友列表、群列表与本地登录用户**回填**各会话展示名/头像（私聊非己）。
  ///
  /// 与消息页首帧拉通讯录后的逻辑一致；返回是否改动过任意会话以便 [saveConversations]。
  bool applyDisplayNamesFromContactProviders() {
    var changed = false;
    final myId = this.myId;
    ImUser? self;
    self = _local.selfUser;
    for (var i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      if (conv.chatType == 'private') {
        final uid = int.tryParse(conv.id) ?? 0;
        if (myId != null && uid == myId && self != null) {
          final n = self.displayName.isNotEmpty
              ? self.displayName
              : (self.username.isNotEmpty ? self.username : '我');
          if (conv.name != n || (self.avatar ?? '') != conv.avatar) {
            conversations[i] =
                conv.copyWith(name: n, avatar: self.avatar ?? '');
            changed = true;
          }
          continue;
        }
        final fd = _friend.getFriendDisplay(uid);
        if (fd != null &&
            (conv.name != fd.name || (fd.avatar ?? '') != conv.avatar)) {
          conversations[i] =
              conv.copyWith(name: fd.name, avatar: fd.avatar ?? '');
          changed = true;
        }
      } else if (conv.chatType == 'secret') {
        // 私密聊天：以对端好友显示名回填（无好友记录时保留默认「私密聊天」）。
        final peerId = _secretChatCache[conv.id]?.peerUserId;
        if (peerId != null) {
          final fd = _friend.getFriendDisplay(peerId);
          if (fd != null && conv.name != fd.name) {
            conversations[i] = conv.copyWith(name: fd.name);
            changed = true;
          }
        }
      } else {
        for (final gr in _group.groups) {
          if ('${gr.id}' == conv.id && conv.name != gr.name) {
            conversations[i] = conv.copyWith(name: gr.name);
            changed = true;
          }
        }
      }
    }
    return changed;
  }

  void _maybeScheduleAddressBookSyncForIncoming(
    String peerId,
    String chatType,
  ) =>
      _addressBookSync.maybeScheduleForIncoming(peerId, chatType);

  /// 离开会话或切房时：若仍有未提交的实时合并，直接写入 [messageMap]（不测高）。
  void flushDeferredRealtimeIfMatches(String peerId, String chatType) {
    final d = deferredRealtimeSessionInsert;
    if (d == null || d.peerId != peerId || d.chatType != chatType) return;
    commitDeferredRealtimeSessionInsert(force: true);
  }

  /// 将 [deferredRealtimeSessionInsert] 写入 [messageMap] 并清空。
  /// [expectedVersion] 与 [force] 二选一语义：测高完成后用 [expectedVersion] 避免并发推送覆盖。
  bool commitDeferredRealtimeSessionInsert({
    int? expectedVersion,
    bool force = false,
  }) {
    final d = deferredRealtimeSessionInsert;
    if (d == null) return false;
    if (!force && expectedVersion != null && d.version != expectedVersion) {
      return false;
    }
    final key = chatKey(d.chatType, d.peerId);
    messageMap[key] = List<ChatMessage>.from(d.mergedSession);
    deferredRealtimeSessionInsert = null;
    final last = d.mergedSession.last;
    upsertConversation(
      d.peerId,
      d.chatType,
      conversationPreviewForMessage(last, viewerId: myId),
      incrementUnread: false,
      name: last.fromUsername,
      lastTime: last.timestamp,
    );
    _maybeScheduleAddressBookSyncForIncoming(d.peerId, d.chatType);
    if (d.readMsgIds.isNotEmpty) {
      markRead(List<String>.from(d.readMsgIds),
          peerId: d.peerId, chatType: d.chatType);
    }
    notifyListeners();
    return true;
  }

  /// 清空本会话内存消息（如从搜索锚点进房），避免与旧缓存合并后时间轴错乱。
  void clearSessionMessages(String peerId, String chatType) {
    messageMap[chatKey(chatType, peerId)] = [];
    final d = deferredRealtimeSessionInsert;
    if (d != null && d.peerId == peerId && d.chatType == chatType) {
      deferredRealtimeSessionInsert = null;
    }
    notifyListeners();
  }

  /// 拉取一页并向新/向旧分页，**不写入** [messageMap]；测高完成后请 [commitPagingHistoryMerge]。
  ///
  /// 提交时用当前内存列表再次合并 [parsedMessages]，避免测高期间实时消息插队后被旧快照覆盖。
  Future<PreparedPagingHistoryMerge> preparePagingHistoryMerge(
    String peerId,
    String chatType, {
    String? beforeMsgId,
    String? afterMsgId,
  }) async {
    assert(beforeMsgId == null || afterMsgId == null,
        'beforeMsgId and afterMsgId cannot both be set');
    assert(beforeMsgId != null || afterMsgId != null,
        'beforeMsgId or afterMsgId is required');
    final key = chatKey(chatType, peerId);
    return _historyCoordinator
        .runExclusiveFetch<PreparedPagingHistoryMerge>(key, () async {
      final raw = await _chat.messageHistory(
        peerId: peerId,
        chatType: chatType,
        beforeMsgId: beforeMsgId,
        afterMsgId: afterMsgId,
      );
      final parsed = parseChatHistoryRaw(raw);
      _persistMessages(peerId, parsed);
      return _historyCoordinator.withMergeLock<PreparedPagingHistoryMerge>(key,
          () {
        final latest = List<ChatMessage>.from(messageMap[key] ?? []);
        final snap = mergeBeforeOrAfterHistoryPage(
          latest,
          parsed,
          beforeMsgId: beforeMsgId,
          afterMsgId: afterMsgId,
        );
        return (
          page: (added: snap.added, serverCount: snap.serverCount),
          parsedMessages: parsed,
          beforeMsgId: beforeMsgId,
          afterMsgId: afterMsgId,
          mergedForMeasure: snap.merged,
        );
      });
    });
  }

  /// 将 [preparePagingHistoryMerge] 得到的 [parsedMessages] 按当前会话列表合并写入（与 [loadHistory] 规则一致）。
  Future<void> commitPagingHistoryMerge(
    String peerId,
    String chatType,
    List<ChatMessage> parsedMessages, {
    String? beforeMsgId,
    String? afterMsgId,
    bool suppressPagingNotify = false,
  }) async {
    assert(beforeMsgId == null || afterMsgId == null,
        'beforeMsgId and afterMsgId cannot both be set');
    assert(beforeMsgId != null || afterMsgId != null,
        'beforeMsgId or afterMsgId is required');
    final key = chatKey(chatType, peerId);
    await _historyCoordinator.withMergeLock<void>(key, () {
      final latest = List<ChatMessage>.from(messageMap[key] ?? []);
      final snap = mergeBeforeOrAfterHistoryPage(
        latest,
        List<ChatMessage>.from(parsedMessages),
        beforeMsgId: beforeMsgId,
        afterMsgId: afterMsgId,
      );
      if (snap.merged != null) {
        messageMap[key] = snap.merged!;
        if (!suppressPagingNotify) notifyListeners();
      }
    });
  }

  void openChat(
    String peerId,
    String chatType, {
    String? name,
    String? avatar,
  }) {
    final currentChanged =
        currentChatId != peerId || currentChatType != chatType;
    currentChatId = peerId;
    currentChatType = chatType;
    final key = chatKey(chatType, peerId);
    final nextName = name?.trim();
    final nextAvatar = avatar?.trim();
    var conversationChanged = false;
    for (var i = 0; i < conversations.length; i++) {
      final c = conversations[i];
      if (c.id == peerId && c.chatType == chatType) {
        final resolvedName =
            nextName == null || nextName.isEmpty ? c.name : nextName;
        final resolvedAvatar = nextAvatar ?? c.avatar;
        if (c.unread != 0 ||
            c.name != resolvedName ||
            c.avatar != resolvedAvatar) {
          conversations[i] = c.copyWith(
            unread: 0,
            name: resolvedName,
            avatar: resolvedAvatar,
          );
          conversationChanged = true;
        }
        _bumpReadWatermark(key, c.lastTime);
        break;
      }
    }
    final messageMapChanged = !messageMap.containsKey(key);
    if (messageMapChanged) messageMap[key] = [];
    if (conversationChanged) _persistConversations();
    if (currentChanged || conversationChanged || messageMapChanged) {
      notifyListeners();
    }
  }

  /// 离开聊天室时清除 [currentChatId]。
  ///
  /// 若 [peerId]/[chatType] 与当前会话不一致则忽略，避免「退房帧后回调晚于新房 openChat」误清状态。
  void closeChatIfCurrent(String peerId, String chatType) {
    if (currentChatId != peerId || currentChatType != chatType) return;
    currentChatId = null;
    notifyListeners();
  }

  /// 将 [msg] 按 (timestamp, msgId) 升序插入 [list]，与历史合并后的时间序一致。
  ///
  /// 推送/离线入库不得一律 [List.add]：底部「向新分页」未拉全时，实时消息时间可能早于当前列表尾部，
  /// 追加到末尾会破坏顺序，气泡会出现在时间轴中间。
  void insertChatMessageChronologically(
      List<ChatMessage> list, ChatMessage msg) {
    final idx = list.indexWhere((x) {
      return compareChatMessagesChronological(x, msg) > 0;
    });
    if (idx < 0) {
      list.add(msg);
    } else {
      list.insert(idx, msg);
    }
  }

  /// 若列表中尚无该 [msgId]，按时间插入（旧→新），用于从聊天记录搜索跳入等场景。
  Future<void> mergeMessageIfAbsent(
      String peerId, String chatType, ChatMessage m) async {
    final key = chatKey(chatType, peerId);
    await _historyCoordinator.withMergeLock<void>(key, () {
      messageMap.putIfAbsent(key, () => []);
      final list = messageMap[key]!;
      if (list.any((x) => x.msgId == m.msgId)) return;
      final idx = list.indexWhere((x) => x.timestamp.isAfter(m.timestamp));
      if (idx < 0) {
        list.add(m);
      } else {
        list.insert(idx, m);
      }
      notifyListeners();
    });
  }

  /// 以 [anchorMsgId] 为中心拉一页窗口：优先 [ImApi.messageHistoryCentered] 一次请求，否则 before/after 各一页。
  ///
  /// [noMoreOlder]：更旧一侧本批无数据；[mayHaveMoreNewer]：较新一侧本批可能截断（仍建议再拉一节最新页）。
  Future<({bool noMoreOlder, bool mayHaveMoreNewer})> loadHistoryAround(
    String peerId,
    String chatType,
    String anchorMsgId, {
    int pageSize = 30,
    int centerBefore = 20,
    int centerAfter = 35,
  }) async {
    final anchor = anchorMsgId.trim();
    if (anchor.isEmpty) {
      return (noMoreOlder: true, mayHaveMoreNewer: false);
    }

    ({bool noMoreOlder, bool mayHaveMoreNewer}) mergeIncoming(
      String key,
      List<ChatMessage> incoming, {
      required bool noMoreOlder,
      required bool mayHaveMoreNewer,
    }) {
      if (incoming.isEmpty) {
        return (noMoreOlder: noMoreOlder, mayHaveMoreNewer: mayHaveMoreNewer);
      }
      final byId = <String, ChatMessage>{};
      for (final m in messageMap[key] ?? []) {
        byId[m.msgId] = m;
      }
      for (final m in incoming) {
        byId.putIfAbsent(m.msgId, () => m);
      }
      final merged = byId.values.toList();
      sortChatMessagesChronological(merged);
      messageMap[key] = merged;
      notifyListeners();
      return (noMoreOlder: noMoreOlder, mayHaveMoreNewer: mayHaveMoreNewer);
    }

    final key = chatKey(chatType, peerId);

    return _historyCoordinator
        .runExclusiveFetch<({bool noMoreOlder, bool mayHaveMoreNewer})>(key,
            () async {
      final rawCentered = await _chat.messageHistoryCentered(
        peerId: peerId,
        chatType: chatType,
        centerMsgId: anchor,
        beforeCount: centerBefore,
        afterCount: centerAfter,
      );
      if (rawCentered.isNotEmpty) {
        final incoming = parseChatHistoryRaw(rawCentered);
        _persistMessages(peerId, incoming);
        return _historyCoordinator
            .withMergeLock<({bool noMoreOlder, bool mayHaveMoreNewer})>(key,
                () {
          return mergeIncoming(
            key,
            incoming,
            noMoreOlder: false,
            mayHaveMoreNewer: incoming.length >= centerBefore + centerAfter,
          );
        });
      }

      final olderFuture = _chat.messageHistory(
        peerId: peerId,
        chatType: chatType,
        beforeMsgId: anchor,
        pageSize: pageSize,
      );
      final newerFuture = _chat
          .messageHistory(
            peerId: peerId,
            chatType: chatType,
            afterMsgId: anchor,
            pageSize: pageSize,
          )
          .catchError((Object _) => <dynamic>[]);

      final results = await Future.wait([olderFuture, newerFuture]);
      final olderList = (results[0] as List?) ?? const [];
      final newerList = (results[1] as List?) ?? const [];
      final newerParsed = parseChatHistoryRaw(List<dynamic>.from(newerList));

      return _historyCoordinator
          .withMergeLock<({bool noMoreOlder, bool mayHaveMoreNewer})>(key, () {
        final incoming = [
          ...parseChatHistoryRaw(List<dynamic>.from(olderList)),
          ...newerParsed,
        ];
        _persistMessages(peerId, incoming);
        if (incoming.isEmpty) {
          return (
            noMoreOlder: olderList.isEmpty,
            mayHaveMoreNewer: false,
          );
        }
        return mergeIncoming(
          key,
          incoming,
          noMoreOlder: olderList.isEmpty,
          mayHaveMoreNewer: newerParsed.length >= pageSize,
        );
      });
    });
  }

  /// 搜索/推送锚点进房：优先将本会话替换为以 [anchorMsgId] 为中心的一窗消息。
  /// 若居中查询不可用、返回内容不含锚点或请求失败，则合并降级历史并保留当前
  /// 缓存，避免点击通知后聊天记录被清空。
  ///
  /// [ensurePresent]：搜索页带来的完整气泡，接口未返回该 id 时并入列表。
  ///
  /// 返回：更旧 / 更新两侧是否「很可能已无更多」（根据本批条数与窗口大小推断）。
  Future<({bool noMoreOlder, bool noMoreNewer})> replaceSessionWithAnchorWindow(
    String peerId,
    String chatType,
    String anchorMsgId, {
    ChatMessage? ensurePresent,
    int beforeCount = 30,
    int afterCount = 30,
  }) async {
    final anchor = anchorMsgId.trim();
    final key = chatKey(chatType, peerId);

    return _historyCoordinator
        .runExclusiveFetch<({bool noMoreOlder, bool noMoreNewer})>(key,
            () async {
      if (anchor.isEmpty) {
        return _historyCoordinator
            .withMergeLock<({bool noMoreOlder, bool noMoreNewer})>(key, () {
          if (ensurePresent != null) {
            messageMap[key] = [ensurePresent];
          } else {
            messageMap[key] = [];
          }
          notifyListeners();
          return (noMoreOlder: true, noMoreNewer: true);
        });
      }

      List<dynamic> rawCentered;
      try {
        rawCentered = await _chat.messageHistoryCentered(
          peerId: peerId,
          chatType: chatType,
          centerMsgId: anchor,
          beforeCount: beforeCount,
          afterCount: afterCount,
        );
      } catch (_) {
        rawCentered = const [];
      }

      List<ChatMessage> incoming;
      var usedCenteredWindow = false;
      var dualNoOlder = false;
      var dualNoNewer = false;

      if (rawCentered.isNotEmpty) {
        final centered = parseChatHistoryRaw(rawCentered);
        sortChatMessagesChronological(centered);
        // 旧服务端可能忽略 centerMsgId，直接返回最新一页。只有响应确实包含
        // 锚点时才允许它替换当前会话，否则继续走兼容降级路径。
        if (centered.any((m) => m.msgId.trim() == anchor)) {
          incoming = centered;
          usedCenteredWindow = true;
        } else {
          incoming = const [];
        }
      } else {
        incoming = const [];
      }

      if (!usedCenteredWindow) {
        final olderFuture = _chat
            .messageHistory(
              peerId: peerId,
              chatType: chatType,
              beforeMsgId: anchor,
              pageSize: beforeCount,
            )
            .catchError((Object _) => <dynamic>[]);
        final newerFuture = _chat
            .messageHistory(
              peerId: peerId,
              chatType: chatType,
              afterMsgId: anchor,
              pageSize: afterCount,
            )
            .catchError((Object _) => <dynamic>[]);
        final dual = await Future.wait([olderFuture, newerFuture]);
        final olderRaw = dual[0];
        final newerRaw = dual[1];
        final byId = <String, ChatMessage>{};
        for (final m in parseChatHistoryRaw(List<dynamic>.from(olderRaw))) {
          byId[m.msgId] = m;
        }
        for (final m in parseChatHistoryRaw(List<dynamic>.from(newerRaw))) {
          byId[m.msgId] = m;
        }
        incoming = byId.values.toList();
        sortChatMessagesChronological(incoming);
        dualNoOlder = olderRaw.length < beforeCount;
        dualNoNewer = newerRaw.length < afterCount;
      }
      _persistMessages(
        peerId,
        ensurePresent == null ? incoming : [...incoming, ensurePresent],
      );

      return _historyCoordinator
          .withMergeLock<({bool noMoreOlder, bool noMoreNewer})>(key, () {
        final byId = <String, ChatMessage>{};
        final current = List<ChatMessage>.from(messageMap[key] ?? const []);
        if (!usedCenteredWindow) {
          // 降级请求不能保证服务端支持 before/after 游标，因此不能用它覆盖
          // 当前缓存；合并可确保失败时仍展示原历史和同步得到的锚点消息。
          for (final m in current) {
            byId[m.msgId] = m;
          }
        }
        for (final m in incoming) {
          byId[m.msgId] = m;
        }
        ChatMessage? currentAnchor;
        for (final m in current) {
          if (m.msgId.trim() == anchor) {
            currentAnchor = m;
            break;
          }
        }
        final anchorSeed = ensurePresent ?? currentAnchor;
        if (anchorSeed != null) {
          byId.putIfAbsent(anchorSeed.msgId, () => anchorSeed);
        }
        final merged = byId.values.toList();
        sortChatMessagesChronological(merged);
        // 任何远端失败路径都不能把已有的非空消息列表覆盖为空。
        if (merged.isNotEmpty || current.isEmpty) {
          messageMap[key] = merged;
          notifyListeners();
        }

        if (usedCenteredWindow) {
          final ai = merged.indexWhere((m) => m.msgId.trim() == anchor);
          if (ai < 0) {
            return (noMoreOlder: true, noMoreNewer: true);
          }
          return (
            noMoreOlder: ai < beforeCount,
            noMoreNewer: (merged.length - 1 - ai) < afterCount,
          );
        }
        return (noMoreOlder: dualNoOlder, noMoreNewer: dualNoNewer);
      });
    });
  }

  /// 与 [loadHistory] 的 [suppressPagingNotify] 配套，在聊天页完成滚动补偿后再刷新依赖本 Provider 的组件。
  void notifyAfterHistoryPagingMerge() => notifyListeners();

  /// [suppressPagingNotify]：`before`/`after` 合并后不立刻 [notifyListeners]，由调用方在滚动补偿后 [notifyAfterHistoryPagingMerge]。
  Future<LoadHistoryPage> loadHistory(String peerId, String chatType,
      {String? beforeMsgId,
      String? afterMsgId,
      bool suppressPagingNotify = false}) async {
    assert(beforeMsgId == null || afterMsgId == null,
        'beforeMsgId and afterMsgId cannot both be set');
    final key = chatKey(chatType, peerId);
    return _historyCoordinator.runExclusiveFetch<LoadHistoryPage>(key,
        () async {
      final raw = await _chat.messageHistory(
        peerId: peerId,
        chatType: chatType,
        beforeMsgId: beforeMsgId,
        afterMsgId: afterMsgId,
      );
      final parsed = parseChatHistoryRaw(raw);
      _persistMessages(peerId, parsed);
      return _historyCoordinator.withMergeLock<LoadHistoryPage>(key, () {
        void pagingNotify() {
          if (!suppressPagingNotify) notifyListeners();
        }

        final serverCount = parsed.length;
        final latest = List<ChatMessage>.from(messageMap[key] ?? []);
        final ids = latest.map((m) => m.msgId).toSet();

        if (beforeMsgId != null) {
          final snap = mergeBeforeOrAfterHistoryPage(
            latest,
            parsed,
            beforeMsgId: beforeMsgId,
            afterMsgId: null,
          );
          if (snap.merged != null) {
            messageMap[key] = snap.merged!;
            pagingNotify();
          }
          return (added: snap.added, serverCount: snap.serverCount);
        }

        if (afterMsgId != null) {
          final snap = mergeBeforeOrAfterHistoryPage(
            latest,
            parsed,
            beforeMsgId: null,
            afterMsgId: afterMsgId,
          );
          if (snap.merged != null) {
            messageMap[key] = snap.merged!;
            pagingNotify();
          }
          return (added: snap.added, serverCount: snap.serverCount);
        }

        return _mergeLoadHistoryLatestWindow(
          key,
          parsed,
          latest,
          ids,
          serverCount,
          pagingNotify,
        );
      });
    });
  }

  /// 无 [beforeMsgId]/[afterMsgId]：视为拉「最新一页」；仅在可与当前内存窗口衔接时合并。
  LoadHistoryPage _mergeLoadHistoryLatestWindow(
    String key,
    List<ChatMessage> parsed,
    List<ChatMessage> latest,
    Set<String> ids,
    int serverCount,
    void Function() pagingNotify,
  ) {
    if (parsed.isEmpty) {
      return (added: 0, serverCount: 0);
    }
    final parsedSorted = List<ChatMessage>.from(parsed);
    sortChatMessagesChronological(parsedSorted);
    final dedupedParsed = <ChatMessage>[];
    final seenP = <String>{};
    for (final m in parsedSorted) {
      if (seenP.add(m.msgId)) dedupedParsed.add(m);
    }

    if (latest.isEmpty) {
      messageMap[key] = dedupedParsed;
      notifyListeners();
      return (added: dedupedParsed.length, serverCount: serverCount);
    }

    final parsedIdSet = dedupedParsed.map((m) => m.msgId).toSet();
    final hasOverlap = latest.any((m) => parsedIdSet.contains(m.msgId));

    if (hasOverlap) {
      final byId = <String, ChatMessage>{};
      for (final m in latest) {
        byId[m.msgId] = m;
      }
      for (final m in dedupedParsed) {
        final existing = byId[m.msgId];
        byId[m.msgId] = existing == null
            ? m
            : mergeByMsgIdPreferringEdit(existing, m);
      }
      final merged = byId.values.toList();
      sortChatMessagesChronological(merged);
      messageMap[key] = merged;
      final added = dedupedParsed.where((m) => !ids.contains(m.msgId)).length;
      notifyListeners();
      return (added: added, serverCount: serverCount);
    }

    if (compareChatMessagesChronological(latest.last, dedupedParsed.first) <=
        0) {
      final newMsgs =
          dedupedParsed.where((m) => !ids.contains(m.msgId)).toList();
      messageMap[key] = [...latest, ...newMsgs];
      sortChatMessagesChronological(messageMap[key]!);
      notifyListeners();
      return (added: newMsgs.length, serverCount: serverCount);
    }

    if (compareChatMessagesChronological(dedupedParsed.last, latest.first) <
        0) {
      return (added: 0, serverCount: serverCount);
    }

    return (added: 0, serverCount: serverCount);
  }

  /// 等同「重新进房」拉首屏：请求 **不带** [beforeMsgId]/[afterMsgId]，取**整会话时间序上最新**的 [pageSize] 条（非向新分页游标）。
  ///
  /// 拿到非空服务端窗口后再替换本会话列表；空响应可能来自消息落库短暂延迟，
  /// 不得清空已经由 WebSocket 或本地缓存展示的消息。
  Future<LoadHistoryPage> replaceSessionWithLatestTail(
    String peerId,
    String chatType, {
    int pageSize = 30,
  }) async {
    final key = chatKey(chatType, peerId);
    return _historyCoordinator.runExclusiveFetch<LoadHistoryPage>(key,
        () async {
      final raw = await _chat.messageHistory(
        peerId: peerId,
        chatType: chatType,
        pageSize: pageSize,
      );
      final parsed = parseChatHistoryRaw(raw);
      _persistMessages(peerId, parsed);
      return _historyCoordinator.withMergeLock<LoadHistoryPage>(key, () {
        final serverCount = parsed.length;
        final oldList = messageMap[key];
        if (parsed.isEmpty) {
          if (oldList == null) {
            messageMap[key] = [];
            notifyListeners();
          }
          return (added: 0, serverCount: 0);
        }

        final d = deferredRealtimeSessionInsert;
        if (d != null && d.peerId == peerId && d.chatType == chatType) {
          deferredRealtimeSessionInsert = null;
        }

        if (oldList != null) {
          for (final m in oldList) {
            final cid = m.clientMsgId?.trim();
            if (cid != null && cid.isNotEmpty && m.status != 'sending') {
              pendingAcks.remove(cid);
            }
          }
        }
        final sorted = List<ChatMessage>.from(parsed);
        sortChatMessagesChronological(sorted);
        final deduped = <ChatMessage>[];
        final seen = <String>{};
        for (final m in sorted) {
          if (seen.add(m.msgId)) deduped.add(m);
        }
        if (oldList != null) {
          final serverClientIds = deduped
              .map((message) => message.clientMsgId?.trim())
              .whereType<String>()
              .where((value) => value.isNotEmpty)
              .toSet();
          for (final message in deduped) {
            final clientMsgId = message.clientMsgId?.trim();
            if (clientMsgId != null &&
                clientMsgId.isNotEmpty &&
                pendingAcks.remove(clientMsgId) != null) {
              unawaited(
                _local.confirmPendingMessage(
                  peerId,
                  clientMsgId,
                  message,
                ),
              );
            }
          }
          for (final message in oldList) {
            final clientMsgId = message.clientMsgId?.trim();
            if (message.status == 'sending' &&
                clientMsgId != null &&
                clientMsgId.isNotEmpty &&
                !serverClientIds.contains(clientMsgId) &&
                seen.add(message.msgId)) {
              deduped.add(message);
            }
          }
          sortChatMessagesChronological(deduped);
        }
        messageMap[key] = deduped;
        notifyListeners();
        return (added: deduped.length, serverCount: serverCount);
      });
    });
  }

  void sendMessage(
    String toId,
    String chatType,
    String msgType,
    String content, {
    String? replyMsgId,
    List<dynamic>? atUsers,
    String? convPreview,
    List<String>? mediaObjectIds,
    String? wireContent,
  }) {
    _outbound.sendMessage(
      toId,
      chatType,
      msgType,
      content,
      replyMsgId: replyMsgId,
      atUsers: atUsers,
      convPreview: convPreview,
      mediaObjectIds: mediaObjectIds,
      wireContent: wireContent,
    );
  }

  /// 仅写入本地列表的「发送中」媒体占位，不记入 [pendingAcks]、不发出 `chat:send`。
  ///
  /// 上传完成后调用 [finalizeOutboundSendingMediaDraft]，失败则调用 [discardOutboundSendingMediaDraft]。
  String? appendOutboundSendingMediaDraft(
    String toId,
    String chatType,
    String msgType,
    String provisionalContent, {
    String? replyMsgId,
    List<dynamic>? atUsers,
    String? convPreview,
  }) =>
      _outbound.appendSendingMediaDraft(
        toId,
        chatType,
        msgType,
        provisionalContent,
        replyMsgId: replyMsgId,
        atUsers: atUsers,
        convPreview: convPreview,
      );

  void finalizeOutboundSendingMediaDraft({
    required String clientMsgId,
    required String toId,
    required String chatType,
    required String finalContent,
    required List<String> mediaObjectIds,
    String? wireContent,
    String? convPreview,
  }) =>
      _outbound.finalizeSendingMediaDraft(
        clientMsgId: clientMsgId,
        toId: toId,
        chatType: chatType,
        finalContent: finalContent,
        mediaObjectIds: mediaObjectIds,
        wireContent: wireContent,
        convPreview: convPreview,
      );

  void discardOutboundSendingMediaDraft({
    required String clientMsgId,
    required String toId,
    required String chatType,
  }) =>
      _outbound.discardSendingMediaDraft(
        clientMsgId: clientMsgId,
        toId: toId,
        chatType: chatType,
      );

  void onMessageAck(dynamic data) => _outbound.onMessageAck(data);

  String? _resolvePeerName(
      String peerId, String chatType, String? fallbackName) {
    if (chatType == 'private') {
      final my = myId;
      final peer = int.tryParse(peerId) ?? 0;
      if (my != null && peer == my) {
        final self = selfDisplayNameFromStorage;
        if (self != null && self.isNotEmpty) return self;
        if (fallbackName != null && fallbackName.trim().isNotEmpty) {
          return fallbackName.trim();
        }
        return '我';
      }
      final f = _friend.getFriendDisplay(peer);
      if (f?.name != null) return f!.name;
    }
    if (chatType == 'group') {
      final gName = _group.getGroupName(peerId);
      if (!gName.startsWith('群聊 ')) return gName;
    }
    if (chatType == 'channel') {
      final cName = cachedChannelInfo(peerId)?.name;
      if (cName != null && cName.isNotEmpty) return cName;
    }
    return fallbackName;
  }

  bool onMessageReceived(dynamic raw) {
    final receivedIncoming = _realtime.onMessageReceived(raw);
    unawaited(synchronizeMessages());
    _scheduleUnreadSync();
    return receivedIncoming;
  }

  void onReadNotify(dynamic data) => _lifecycle.onReadNotify(data);

  void onRecallNotify(dynamic data) => _lifecycle.onRecallNotify(data);

  void onMessageDeletedNotify(dynamic data) =>
      _lifecycle.onMessageDeletedNotify(data);

  void onMessageEditedNotify(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final msgId = (map['msgId'] ?? map['msg_id'])?.toString();
    if (msgId == null || msgId.isEmpty) return;
    _applyMessageEdit(msgId, (map['content'] ?? '').toString());
  }

  /// 服务端已删除该条消息（发送者 HTTP 或其它端 WS）：从本地列表与会话预览移除。
  void applyMessageDeleted(String msgId) =>
      _lifecycle.applyMessageDeleted(msgId);

  /// 双方私聊已在服务端清空后的本地同步（发起方在 HTTP 成功后调用；对方由 [onClearPrivateChatNotify] 触发）。
  void applyPrivateChatCleared(String peerId) =>
      _lifecycle.applyPrivateChatCleared(peerId);

  void onClearPrivateChatNotify(dynamic data) =>
      _lifecycle.onClearPrivateChatNotify(data);

  /// 群聊天记录已在服务端清空后的本地同步（群主 HTTP 成功后调用；其他成员由 [onClearGroupChatNotify] 触发）。
  void applyGroupChatCleared(String groupId) =>
      _lifecycle.applyGroupChatCleared(groupId);

  void onClearGroupChatNotify(dynamic data) =>
      _lifecycle.onClearGroupChatNotify(data);

  /// 本机结束、取消或拒绝通话后写入一条 `msgType: call` 的会话记录。
  void sendCallTraceMessage(OutgoingCallTrace t) {
    final payload = jsonEncode({
      'v': 1,
      'media': t.media,
      'kind': t.kind,
      'durationSec': t.durationSec,
      if (t.callId != null) 'callId': t.callId,
    });
    final preview = t.media == 'video' ? '[视频通话]' : '[语音通话]';
    if (t.chatType == 'secret') {
      unawaited(sendSecretText(
        secretChatId: t.peerId,
        text: payload,
        msgType: 'call',
        convPreview: preview,
      ));
      return;
    }
    if (t.chatType == 'secret_group') {
      unawaited(sendSecretGroupText(
        groupId: t.peerId,
        text: payload,
        msgType: 'call',
        convPreview: preview,
      ));
      return;
    }
    sendMessage(t.peerId, t.chatType, 'call', payload);
  }

  void onTyping(dynamic data) => _typing.onTyping(data);

  final List<String> _wsErrorQueue = [];

  /// 消费一条待展示的 WS 错误提示（供 UI 弹 Toast）。
  String? popWsError() {
    if (_wsErrorQueue.isEmpty) return null;
    return _wsErrorQueue.removeAt(0);
  }

  /// 服务端 WS `error` 事件回调（敏感词拦截等）。
  void onWsError(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final cidAny = map['clientMsgId'] ?? map['client_msg_id'];
    final clientId = cidAny?.toString();
    if (clientId != null && clientId.isNotEmpty) {
      pendingAcks.remove(clientId);
      unawaited(_local.removePendingMessage(clientId));
      for (final e in messageMap.entries) {
        final before = e.value.length;
        e.value.removeWhere((m) => m.clientMsgId == clientId);
        if (e.value.length != before) {
          _lifecycle.refreshConversationLastFromSession(e.key);
        }
      }
    }

    final msgDyn = map['message'];
    final msgOut = msgDyn is String ? msgDyn : msgDyn?.toString();
    if (msgOut != null && msgOut.isNotEmpty) {
      _wsErrorQueue.add(msgOut);
    }
    notifyListeners();
  }

  void sendTyping(String toId, String chatType) {
    // WS v1 typing is not part of the first frozen realtime contract.
  }

  void recallMessage(String msgId) {
    unawaited(_recallMessage(msgId));
  }

  Future<void> _recallMessage(String msgId) async {
    try {
      await _chat.recallMessage(msgId);
    } catch (error) {
      _wsErrorQueue.add(ApiFailure.messageOf(error));
      notifyListeners();
    }
  }

  bool isMessageHidden(
    String peerId,
    String chatType,
    String msgId, {
    DateTime? timestamp,
  }) {
    if (_lifecycle.isMessageHidden(peerId, chatType, msgId)) return true;
    if (timestamp == null) return false;
    return _isMessageLocallyClearedAt(
      chatKey(chatType, peerId),
      timestamp,
    );
  }

  /// 会话内可见消息（不含撤回、不含本机「删除」隐藏），顺序与时间轴一致（旧→新）。
  List<ChatMessage> visibleMessagesFor(String peerId, String chatType) =>
      _lifecycle.visibleMessagesFor(peerId, chatType);

  void hideMessageForMe(String peerId, String chatType, String msgId) =>
      _lifecycle.hideMessageForMe(peerId, chatType, msgId);

  Future<void> deleteMessageForEveryone(String msgId) =>
      _chat.deleteMessageForEveryone(msgId);

  /// 「删除仅我」：**先落服务端墓碑再本地隐藏**。
  /// 本地隐藏随重装丢失，服务端墓碑才是跨端一致、跨重装保留的依据。
  /// 服务端失败时仍做本地隐藏（用户已确认删除，不应因为网络问题“删不掉”）。
  Future<void> deleteMessagesForMe({
    required String peerId,
    required String chatType,
    required List<String> msgIds,
  }) async {
    final ids = msgIds.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return;
    try {
      await _chat.deleteMessagesForMe(ids);
    } catch (error, stackTrace) {
      debugPrint(
        'delete-for-me failed on server, keep local hide: $error\n$stackTrace',
      );
    }
    for (final id in ids) {
      hideMessageForMe(peerId, chatType, id);
    }
  }

  /// 编辑消息正文（发送后 2 分钟内仅发送者本人）：POST /messages/edit。
  /// 成功后本地立即回写正文与 `edited` 标记并落库，避免等待 WS 编辑下行。
  Future<Map<String, dynamic>> editMessage({
    required String msgId,
    required String newContent,
  }) async {
    final result = await _chat.editMessage(
      msgId: msgId,
      newContent: newContent,
    );
    _applyMessageEdit(msgId, newContent);
    return result;
  }

  /// 把编辑后的正文与 `edited` 标记写回内存列表与本地库。
  ///
  /// 同时刷新**会话列表预览**：编辑前这里只改了会话内的气泡，退出到主界面时
  /// 列表仍显示编辑前的旧内容（发送方与接收方都会出现）。删除/撤回路径一直有做这步，
  /// 编辑路径遗漏，导致同一类操作在不同场景表现不一致。
  void _applyMessageEdit(String msgId, String newContent) {
    for (final entry in messageMap.entries) {
      final list = entry.value;
      final idx = list.indexWhere((m) => m.msgId == msgId);
      if (idx < 0) continue;
      final current = list[idx];
      if (current.content == newContent && current.edited) return;
      final next = current.copyWith(content: newContent, edited: true);
      list[idx] = next;
      unawaited(_local.updateMessage(next));
      _lifecycle.refreshConversationLastFromSession(entry.key);
      notifyListeners();
      return;
    }
  }

  /// 撤回私密消息（仅发送方，窗口内）：调独立 /secret-messages 接口，服务端协调
  /// 双方（含发起方）通过销毁事件渲染撤回墓碑。成功后本地立即落墓碑，避免等待 WS 往返。
  void recallSecretMessage(String secretChatId, String msgId) {
    unawaited(_recallSecretMessage(secretChatId, msgId));
  }

  Future<void> _recallSecretMessage(String secretChatId, String msgId) async {
    try {
      await _chat.recallSecretMessage(
        secretChatId: int.tryParse(secretChatId) ?? 0,
        msgId: msgId,
      );
      _lifecycle.markMessageRecalled(msgId, content: '消息已撤回');
    } catch (error) {
      _wsErrorQueue.add(ApiFailure.messageOf(error));
      notifyListeners();
    }
  }

  /// 删除私密消息（任意参与方）：调独立 /secret-messages 接口，服务端协调双方移除。
  Future<void> deleteSecretMessageForEveryone(
      String secretChatId, String msgId) async {
    try {
      await _chat.deleteSecretMessage(
        secretChatId: int.tryParse(secretChatId) ?? 0,
        msgId: msgId,
      );
      _lifecycle.applyMessageDeleted(msgId);
    } catch (error) {
      _wsErrorQueue.add(ApiFailure.messageOf(error));
      notifyListeners();
    }
  }

  /// 撤回私密群聊消息（仅发送方，不限时）：调 /secret-group-messages 撤回接口，服务端协调全员移除。
  void recallSecretGroupMessage(String secretGroupId, String msgId) {
    unawaited(_recallSecretGroupMessage(secretGroupId, msgId));
  }

  Future<void> _recallSecretGroupMessage(
      String secretGroupId, String msgId) async {
    try {
      await _chat.recallSecretGroupMessage(
        secretGroupId: int.tryParse(secretGroupId) ?? 0,
        msgId: msgId,
      );
      _lifecycle.markMessageRecalled(msgId, content: '消息已撤回');
    } catch (error) {
      _wsErrorQueue.add(ApiFailure.messageOf(error));
      notifyListeners();
    }
  }

  /// 删除私密群聊消息所有人（仅发送方，不限时）：服务端协调全员移除。
  Future<void> deleteSecretGroupMessageForEveryone(
      String secretGroupId, String msgId) async {
    try {
      await _chat.deleteSecretGroupMessage(
        secretGroupId: int.tryParse(secretGroupId) ?? 0,
        msgId: msgId,
      );
      _lifecycle.applyMessageDeleted(msgId);
    } catch (error) {
      _wsErrorQueue.add(ApiFailure.messageOf(error));
      notifyListeners();
    }
  }

  void clearChatLocally(String peerId, String chatType) {
    final key = chatKey(chatType, peerId);
    final now = DateTime.now();
    _localClearWatermarkByChat = {
      ..._localClearWatermarkByChat,
      key: now,
    };
    unawaited(
      _local.saveLocalClearWatermarks(_localClearWatermarkByChat),
    );

    messageMap[key] = [];
    final deferred = deferredRealtimeSessionInsert;
    if (deferred != null &&
        deferred.peerId == peerId &&
        deferred.chatType == chatType) {
      deferredRealtimeSessionInsert = null;
    }
    pendingAcks.removeWhere((_, message) {
      if (message.chatType != chatType) return false;
      if (chatType == 'group') return message.toId == peerId;
      final my = myId;
      if (my == null) return false;
      final messagePeer = message.from == my ? message.toId : '${message.from}';
      return messagePeer == peerId;
    });

    if (hiddenMessagesByChat.containsKey(key)) {
      hiddenMessagesByChat = {...hiddenMessagesByChat}..remove(key);
      _persistHidden();
    }

    for (var i = 0; i < conversations.length; i++) {
      final conversation = conversations[i];
      if (conversation.id == peerId && conversation.chatType == chatType) {
        conversations[i] = conversation.copyWith(
          lastMessage: '',
          unread: 0,
          lastTime: DateTime.fromMillisecondsSinceEpoch(0),
        );
        break;
      }
    }
    _persistConversations();
    notifyListeners();
  }

  /// 清空私聊并删除服务端记录（勾选「同时删除服务端」时调用）。
  Future<void> clearPrivateChatOnServer(String peerId) async {
    try {
      await _chat.clearPrivateChat(peerId);
    } catch (error) {
      _wsErrorQueue.add(ApiFailure.messageOf(error));
    }
    clearChatLocally(peerId, 'private');
  }

  /// 应用**服务端持久清空标记**（同步响应 `clearedConversations`）。
  ///
  /// 必要性：清空的实时 WS 通知在**本端离线时会丢失**（服务端走 Redis 房间广播，
  /// 无订阅者也视作成功），而消息已被删除、增量同步又不会告知删除，
  /// 因此本端本地库会一直残留旧记录（卸载重装后也照样出现）。
  ///
  /// 与 [clearChatLocally] 的关键区别：水位线用**服务端 clearedAt** 而不是 `now`。
  /// 若用 `now`，会把「清空之后、本次同步之前」正常收到的消息一并误删。
  void applyServerClearedConversation({
    required String conversationId,
    required String chatType,
    required DateTime clearedAt,
  }) {
    final peerId = _peerIdFromConversationId(conversationId, chatType);
    if (peerId == null || peerId.isEmpty) return;
    final key = chatKey(chatType, peerId);
    final existing = _localClearWatermarkByChat[key];
    if (existing != null && !clearedAt.isAfter(existing)) {
      // 已有更新的水位线（例如本端后来自己也清空过），无需回退。
      return;
    }
    _localClearWatermarkByChat = {
      ..._localClearWatermarkByChat,
      key: clearedAt,
    };
    unawaited(_local.saveLocalClearWatermarks(_localClearWatermarkByChat));

    // 只删除不晚于 clearedAt 的本地消息，保留清空之后新收到的。
    final list = messageMap[key];
    if (list != null) {
      final kept = list.where((m) => m.timestamp.isAfter(clearedAt)).toList();
      final removed = list.where((m) => !m.timestamp.isAfter(clearedAt)).toList();
      if (removed.isNotEmpty) {
        messageMap[key] = kept;
        for (final message in removed) {
          unawaited(_local.deleteMessage(message.msgId));
        }
      }
    }

    for (var i = 0; i < conversations.length; i++) {
      final conversation = conversations[i];
      if (conversation.id != peerId || conversation.chatType != chatType) {
        continue;
      }
      final remaining = messageMap[key];
      if (remaining == null || remaining.isEmpty) {
        conversations[i] = conversation.copyWith(
          lastMessage: '',
          unread: 0,
          lastTime: DateTime.fromMillisecondsSinceEpoch(0),
        );
      } else {
        final last = remaining.last;
        conversations[i] = conversation.copyWith(
          lastMessage: conversationPreviewForMessage(last, viewerId: myId),
          lastTime: last.timestamp,
          unread: 0,
        );
      }
      break;
    }
    _persistConversations();
    notifyListeners();
  }

  /// 应用服务端下发的「删除仅我」墓碑：删除**本端已存在**的对应消息并刷新会话预览。
  ///
  /// 必要性：同步已排除这些消息，但排除只能阻止重新插入，无法清掉设备上已有的旧副本
  /// （同一账号的其它设备，或本机通过其它入口删除时）。此前表现为「删了但重启后列表预览还在」。
  ///
  /// ⚠️ 真机实测教训：**不能只遍历 [messageMap]** —— 未打开该会话时内存里根本没有消息，
  /// 只清内存会导致本地库与已持久化的会话预览双双残留。因此：
  /// 1) 无条件按 msgId 删本地库；2) 用服务端下发的会话定位信息逐个会话刷新预览。
  void applyServerDeletedMsgIds(List<DeletedMessage> deleted) {
    if (deleted.isEmpty) return;
    final targets =
        deleted.map((d) => d.msgId).where((id) => id.isNotEmpty).toSet();
    if (targets.isEmpty) return;
    for (final id in targets) {
      unawaited(_local.deleteMessage(id));
    }
    _removeMsgIdFromAllHiddenForServerDelete(targets.toList());

    final affectedKeys = <String>{};
    for (final item in deleted) {
      final peerId = _peerIdFromConversationId(item.conversationId, item.chatType);
      if (peerId == null || peerId.isEmpty) continue;
      final key = chatKey(item.chatType, peerId);
      final list = messageMap[key];
      if (list != null) {
        final kept = list.where((m) => !targets.contains(m.msgId)).toList();
        if (kept.length != list.length) {
          messageMap[key] = kept;
        }
      }
      affectedKeys.add(key);
    }
    for (final key in affectedKeys) {
      _lifecycle.refreshConversationLastFromSession(key);
    }
    _persistConversations();
    notifyListeners();
  }

  void _removeMsgIdFromAllHiddenForServerDelete(List<String> msgIds) {
    if (msgIds.isEmpty || hiddenMessagesByChat.isEmpty) return;
    final targets = msgIds.toSet();
    var changed = false;
    final next = <String, List<dynamic>>{};
    hiddenMessagesByChat.forEach((key, ids) {
      final kept = ids.where((id) => !targets.contains(id)).toList();
      if (kept.length != ids.length) changed = true;
      next[key] = kept;
    });
    if (!changed) return;
    hiddenMessagesByChat = next;
    _persistHidden();
  }

  /// 从服务端会话 id 解析出会话对端标识。
  ///
  /// private: `conv:private:<a>:<b>` → 取「不是我」的那一方；
  /// group/channel: `conv:group:<id>` / `conv:channel:<id>` → 取 id 本身。
  String? _peerIdFromConversationId(String conversationId, String chatType) {
    final parts = conversationId.split(':');
    if (chatType == 'group' || chatType == 'channel') {
      return parts.isEmpty ? null : parts.last;
    }
    if (chatType == 'private') {
      if (parts.length < 4) return null;
      final my = myId;
      final a = parts[2];
      final b = parts[3];
      if (my == null) return b;
      return a == '$my' ? b : a;
    }
    return null;
  }

  /// 清空群聊并删除服务端记录（勾选「同时删除服务端」时调用）。
  Future<void> clearGroupChatOnServer(String groupId) async {
    try {
      await _chat.clearGroupChat(groupId);
    } catch (error) {
      _wsErrorQueue.add(ApiFailure.messageOf(error));
    }
    clearChatLocally(groupId, 'group');
  }

  /// 本机存储空间：按会话聚合的消息库字节数。
  /// 媒体缓存当前无按会话归类的持久化缓存，UI 侧按 0 计入媒体占用。
  Future<List<ChatSessionStorageStat>> loadSessionStorageStats() =>
      _local.loadSessionStorageStats();

  /// 清空单个会话的全部本机记录（消息库 + 媒体缓存），不影响云端。
  ///
  /// 先走 [clearChatLocally] 设置本地清空水位并刷新内存态与会话预览，
  /// 再物理删除该会话的本地消息与待发送队列，真正释放磁盘占用。
  Future<void> clearSessionStorage(String peerId, String chatType) async {
    clearChatLocally(peerId, chatType);
    await _local.clearSession(peerId, chatType);
  }

  /// 仅清理单个会话的本机媒体缓存。
  ///
  /// 当前版本没有按会话归类的持久化媒体缓存（图片/视频走网络加载，语音为临时缓存），
  /// 因此这里仅刷新界面；未来接入媒体缓存后在此真正删除对应文件。
  Future<void> clearSessionMediaStorage(String peerId, String chatType) async {
    notifyListeners();
  }

  /// 清空全部会话的本机记录（消息库 + 媒体缓存），不影响云端。
  Future<void> clearAllStorage() async {
    final now = DateTime.now();
    _localClearWatermarkByChat = <String, DateTime>{
      for (final key in messageMap.keys) key: now,
      for (final c in conversations) chatKey(c.chatType, c.id): now,
    };
    unawaited(_local.saveLocalClearWatermarks(_localClearWatermarkByChat));

    await _local.clearAllSessionRecords();

    messageMap.clear();
    hiddenMessagesByChat = {};
    _persistHidden();
    pendingAcks.clear();
    deferredRealtimeSessionInsert = null;
    for (var i = 0; i < conversations.length; i++) {
      conversations[i] = conversations[i].copyWith(
        lastMessage: '',
        unread: 0,
        lastTime: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }
    _persistConversations();
    notifyListeners();
  }

  Future<List<dynamic>> searchChatMessages({
    String? peerId,
    String? chatType,
    required String keyword,
    String msgType = 'text',
    int page = 1,
    int pageSize = 30,
    String? beforeMsgId,
  }) async {
    final result = await _chat.searchChatMessages(
      peerId: peerId,
      chatType: chatType,
      keyword: keyword,
      msgType: msgType,
      page: page,
      pageSize: pageSize,
      beforeMsgId: beforeMsgId,
    );
    if (peerId == null || chatType == null) return result;
    final key = chatKey(chatType, peerId);
    return result.where((raw) {
      if (raw is! Map) return false;
      try {
        final message = ChatMessage.fromJson(
          Map<String, dynamic>.from(raw),
        );
        return !_isMessageLocallyCleared(key, message) &&
            !_lifecycle.isMessageHidden(peerId, chatType, message.msgId);
      } catch (_) {
        return false;
      }
    }).toList();
  }

  void markRead(List<String> msgIds, {String? peerId, String? chatType}) {
    if (msgIds.isEmpty) return;
    // 已读上报用于清除接收方未读状态；readReceiptEnabled 仅控制发送方
    // 是否展示“对方已读”回执，不能阻止本端清除自己的未读角标。
    // ⚠️ 角标此前**只认服务端值**（syncUnreadCounts 异步回填），因此进入会话后
    // 角标要等一次网络往返才变化，表现为「有操作延迟」。这里先做**乐观本地更新**：
    // 按本次已读条数立即扣减，随后仍以服务端值校准。
    final clearedCount = _applyOptimisticReadDecrement(msgIds, peerId, chatType);
    if (clearedCount > 0) {
      notifyListeners();
    }
    _chat.markRead(msgIds).catchError((_) => null);
    _bumpReadWatermarkFromMsgIds(msgIds, peerId: peerId, chatType: chatType);
    _scheduleUnreadSync();
    Future<void>.delayed(const Duration(seconds: 3), _scheduleUnreadSync);
  }

  /// 乐观更新：把本次已读的消息数从服务端角标里立即扣掉，避免等待网络往返。
  ///
  /// 返回实际扣减的数量（0 表示无需刷新）。服务端值随后由 [syncUnreadCounts] 校准，
  /// 因此即使多扣/少扣也会在下一个同步周期纠正。
  int _applyOptimisticReadDecrement(List<String> msgIds, String? peerId, String? chatType) {
    if (!_hasServerUnread || _serverTotalUnread <= 0) return 0;
    final my = myId;
    if (my == null) return 0;
    // 只统计「别人发给我」的未读候选：自己发的消息不计入未读。
    var candidates = 0;
    for (final id in msgIds) {
      if (id.isEmpty) continue;
      candidates++;
    }
    if (candidates == 0) return 0;
    final decrement = candidates < _serverTotalUnread ? candidates : _serverTotalUnread;
    _serverTotalUnread = _serverTotalUnread - decrement;
    // 同步把本地会话未读清零，保证 tab 与列表一致（列表本来就会清零，这里兜住时序）。
    if (peerId != null && chatType != null) {
      final key = chatKey(chatType, peerId);
      for (var i = 0; i < conversations.length; i++) {
        final conv = conversations[i];
        if (conv.id == peerId && conv.chatType == chatType && conv.unread != 0) {
          conversations[i] = conv.copyWith(unread: 0);
          _persistConversations();
          break;
        }
      }
      // 便于排查：key 参与计算，避免未使用告警。
      assert(key.isNotEmpty);
    }
    return decrement;
  }

  /// 从服务端拉取已按后台开关过滤的普通会话未读，并对齐本地会话列表。
  /// 服务端接口已统一返回普通与私密未读，并按后台功能开关过滤。
  ///
  /// ⚠️ 角标一致性（tab 与会话列表必须同源）：未读总数与「按会话未读」是两次独立请求，
  /// 若两次之间正好有新消息落库，先返回的总数会偏小，于是出现「tab 角标 1、群会话角标 2」
  /// 这种互相矛盾的展示。这里改为两次请求都拿到后再一起结算，并用「按会话合计」托底，
  /// 保证 tab 角标不小于任何一个会话角标；两者取大值可同时覆盖反向的时序窗口。
  Future<void> syncUnreadCounts() async {
    if (myId == null) return;
    final syncGeneration = ++_unreadSyncGeneration;
    final accountId = myId;

    int? total;
    try {
      total = await _chat.unreadCount();
    } catch (_) {
      total = null;
    }
    if (syncGeneration != _unreadSyncGeneration || accountId != myId) return;

    List<({String conversationId, int count})>? perConv;
    try {
      perConv = await _chat.unreadByConversation();
    } catch (_) {
      perConv = null;
    }
    if (syncGeneration != _unreadSyncGeneration || accountId != myId) return;

    if (perConv == null) {
      // 按会话对齐失败：能拿到总数就用总数，否则回退本地合计，避免沿用上一账号快照。
      if (total != null) {
        if (!_hasServerUnread || _serverTotalUnread != total) {
          _serverTotalUnread = total;
          _hasServerUnread = true;
          notifyListeners();
        }
      } else if (_hasServerUnread) {
        _hasServerUnread = false;
        notifyListeners();
      }
      return;
    }

    final byId = <String, int>{
      for (final e in perConv) e.conversationId: e.count,
    };
    var dirty = false;
    for (var i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      final cid = conversationIdOf(conv.id, conv.chatType);
      if (cid == null) continue;
      final count = byId[cid] ?? 0;
      if (conv.unread != count) {
        conversations[i] = conv.copyWith(unread: count);
        dirty = true;
      }
    }
    var perConvSum = 0;
    for (final e in perConv) {
      if (e.count > 0) perConvSum += e.count;
    }
    final authoritative = total == null
        ? perConvSum
        : (total > perConvSum ? total : perConvSum);
    final totalChanged =
        !_hasServerUnread || _serverTotalUnread != authoritative;
    _serverTotalUnread = authoritative;
    _hasServerUnread = true;
    if (dirty) {
      _persistConversations();
    }
    if (dirty || totalChanged) {
      notifyListeners();
    }
  }

  /// 已读/新消息事件后的防抖刷新未读（合并短时间内的多次触发）。
  Timer? _unreadSyncDebounce;
  int _unreadSyncGeneration = 0;

  void _scheduleUnreadSync() {
    _unreadSyncDebounce?.cancel();
    _unreadSyncDebounce = Timer(const Duration(seconds: 1), () {
      _unreadSyncDebounce = null;
      unawaited(syncUnreadCounts());
    });
  }

  void upsertConversation(
    String peerId,
    String chatType,
    String lastMsg, {
    bool incrementUnread = false,
    String? name,
    DateTime? lastTime,
    bool persist = true,
    bool notify = true,
  }) {
    final idx = conversations
        .indexWhere((c) => c.id == peerId && c.chatType == chatType);
    final now = lastTime ?? DateTime.now();
    if (idx >= 0) {
      final conv = conversations[idx];
      var next = conv.copyWith(
        lastMessage: lastMsg.isNotEmpty ? lastMsg : conv.lastMessage,
        lastTime: now,
        unread: incrementUnread ? conv.unread + 1 : conv.unread,
      );
      final my = myId;
      if (chatType == 'private' &&
          my != null &&
          (int.tryParse(peerId) ?? -1) == my) {
        final nm = selfDisplayNameFromStorage;
        if (nm != null && nm.isNotEmpty && conv.name != nm) {
          next = next.copyWith(name: nm);
        }
      }
      if (idx > 0) {
        conversations.removeAt(idx);
        conversations.insert(0, next);
      } else {
        conversations[idx] = next;
      }
    } else {
      final resolved = _resolvePeerName(peerId, chatType, name);
      conversations.insert(
        0,
        Conversation(
          id: peerId,
          chatType: chatType,
          name: resolved ?? (chatType == 'group' ? '群聊 $peerId' : '用户 $peerId'),
          lastMessage: lastMsg,
          lastTime: now,
          unread: incrementUnread ? 1 : 0,
        ),
      );
    }
    if (persist) _persistConversations();
    if (notify) notifyListeners();
  }

  /// 好友重新建立后恢复此前被删除的私聊会话。
  ///
  /// 首次通知先用已有通讯录信息（或默认名）插入，好友列表刷新完成后的
  /// 再次调用只校准名称和头像，不重复插入或改变最后消息。
  void restoreFriendConversation(int friendId) {
    if (friendId <= 0 || friendId == myId) return;
    final peerId = '$friendId';
    final exists = conversations.any(
      (conversation) =>
          conversation.id == peerId && conversation.chatType == 'private',
    );
    final display = _friend.getFriendDisplay(friendId);
    if (!exists) {
      upsertConversation(
        peerId,
        'private',
        '',
        incrementUnread: false,
        name: display?.name,
      );
      return;
    }
    if (display != null) {
      updateConversationDisplay(
        peerId,
        'private',
        name: display.name,
        avatar: display.avatar,
      );
    }
  }

  void togglePin(String peerId, String chatType) {
    for (var i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      if (conv.id == peerId && conv.chatType == chatType) {
        conversations[i] = conv.copyWith(pinned: !conv.pinned);
        _persistConversations();
        notifyListeners();
        return;
      }
    }
  }

  /// 单会话免打扰开关：切换 [Conversation.muted]、落库，并同步到服务端（跨端一致 + 离线推送过滤）。
  void toggleMute(String peerId, String chatType) {
    for (var i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      if (conv.id == peerId && conv.chatType == chatType) {
        final nextMuted = !conv.muted;
        conversations[i] = conv.copyWith(muted: nextMuted);
        _persistConversations();
        notifyListeners();
        final conversationId = conversationIdOf(peerId, chatType);
        if (conversationId != null) {
          unawaited(
            _chat
                .muteConversation(conversationId, nextMuted)
                .catchError((_) => null),
          );
        }
        return;
      }
    }
  }

  /// 将会话标识归一化为服务端 conversationId（私聊按双方 userId 排序）。
  String? conversationIdOf(String peerId, String chatType) {
    final my = myId;
    if (my == null) return null;
    switch (chatType) {
      case 'private':
        final peer = int.tryParse(peerId);
        if (peer == null) return null;
        final lo = my < peer ? my : peer;
        final hi = my < peer ? peer : my;
        return 'conv:private:$lo:$hi';
      case 'group':
        return 'conv:group:$peerId';
      case 'channel':
        return 'conv:channel:$peerId';
      case 'secret':
        return 'secret:$peerId';
      case 'secret_group':
        return 'secret_group:$peerId';
      default:
        return null;
    }
  }

  /// 从服务端拉取免打扰会话并应用到本地（登录/启动后同步其它设备改动）。
  Future<void> syncMutedConversations() async {
    if (myId == null) return;
    try {
      final mutedIds = await _chat.mutedConversations();
      if (mutedIds.isEmpty) return;
      var dirty = false;
      for (var i = 0; i < conversations.length; i++) {
        final conv = conversations[i];
        if (conv.muted) continue;
        final cid = conversationIdOf(conv.id, conv.chatType);
        if (cid != null && mutedIds.contains(cid)) {
          conversations[i] = conv.copyWith(muted: true);
          dirty = true;
        }
      }
      if (dirty) {
        _persistConversations();
        notifyListeners();
      }
    } catch (_) {
      // 离线或接口失败时保留本地状态。
    }
  }

  /// 该会话是否已开启免打扰（供通知派发处过滤提醒）。
  bool isConversationMuted(String peerId, String chatType) {
    for (final c in conversations) {
      if (c.id == peerId && c.chatType == chatType) return c.muted;
    }
    return false;
  }

  /// 会话是否存在「未读的 @提及我」消息（供会话列表「有人@我」角标）。
  bool hasUnreadAtMention(String peerId, String chatType) {
    final my = myId;
    if (my == null) return false;
    final key = chatKey(chatType, peerId);
    final msgs = messageMap[key];
    if (msgs == null || msgs.isEmpty) return false;
    final watermark = _readWatermarkByChat[key];
    for (final m in msgs) {
      if (m.from == my) continue; // 只看他人消息
      if (watermark != null && !m.timestamp.isAfter(watermark)) continue; // 已读
      final atUsers = m.atUsers;
      if (atUsers != null && atUsers.any((e) => e.toString() == '$my')) {
        return true;
      }
    }
    return false;
  }

  /// 更新单个会话的输入草稿：同步内存列表（供列表页「[草稿]」预览）并定向落库。
  void setConversationDraft(
    String peerId,
    String chatType,
    String? draftText,
  ) {
    final normalized =
        (draftText == null || draftText.trim().isEmpty) ? null : draftText;
    for (var i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      if (conv.id == peerId && conv.chatType == chatType) {
        if (conv.draftText == normalized) {
          unawaited(_local.saveConversationDraft(peerId, chatType, normalized));
          return;
        }
        conversations[i] = conv.copyWith(draftText: normalized);
        unawaited(_local.saveConversationDraft(peerId, chatType, normalized));
        notifyListeners();
        return;
      }
    }
    unawaited(_local.saveConversationDraft(peerId, chatType, normalized));
  }

  /// 私密消息到达时累加未读数（对方发来的新消息；己方消息不计）。
  void bumpUnread(String peerId, String chatType, int delta) {
    if (delta <= 0) return;
    for (var i = 0; i < conversations.length; i++) {
      final conv = conversations[i];
      if (conv.id == peerId && conv.chatType == chatType) {
        conversations[i] = conv.copyWith(unread: conv.unread + delta);
        _persistConversations();
        return;
      }
    }
  }

  void removeConversation(String peerId, String chatType) {
    conversations = conversations
        .where((c) => !(c.id == peerId && c.chatType == chatType))
        .toList();
    _persistConversations();
    notifyListeners();
  }

  /// 离线补全：新写入列表、对端、非已读、且晚于本地已读水位线时才加未读。
  bool _shouldIncrementUnreadForOfflineMerge({
    required String peerId,
    required ChatMessage msg,
    required int my,
    required DateTime? readAt,
    required bool didInsert,
    required bool isCurrent,
    required bool suppressListInsert,
  }) {
    final ck = chatKey(msg.chatType, peerId);
    if (_isMessageMutedByReadWatermark(ck, msg)) return false;
    if (!didInsert) return false;
    if (msg.from == my) return false;
    // 系统消息不计入未读，与服务端口径一致（服务端过滤 `msg_type <> 'SYSTEM'`），
    // 否则「同意好友」这类系统提示会在本地留下一个永远不会被服务端校准掉的角标。
    if (msg.msgType.toLowerCase() == 'system') return false;
    if (readAt != null) return false;
    if (msg.status == 'read') return false;
    return (!isCurrent || suppressListInsert);
  }

  Future<void> synchronizeMessages() {
    final accountId = myId;
    if (accountId == null) return Future<void>.value();

    // 登录后尽早注册本端设备公钥（幂等），消除私密会话「等待对方加入」的体验。
    unawaited(ensureDeviceKeyRegistered());

    _messageSyncRequested = true;
    final active = _messageSyncTask;
    if (active != null) return active;

    final generation = _messageSyncGeneration;
    final task = _drainMessageSyncRequests(accountId, generation);
    _messageSyncTask = task;
    unawaited(task.whenComplete(() {
      if (!identical(_messageSyncTask, task)) return;
      _messageSyncTask = null;
      // 消息同步完成时顺带同步私密会话（对方新建的私密聊天进入本端列表）。
      unawaited(syncSecretChatsIntoConversations());
      // 同步私密群聊（对方新建的私密群聊进入本端列表并完成握手）。
      unawaited(syncSecretGroupChatsIntoConversations());
      notifyListeners();
      if (_messageSyncRequested &&
          generation == _messageSyncGeneration &&
          accountId == myId) {
        unawaited(synchronizeMessages());
      }
    }));
    notifyListeners();
    return task;
  }

  Future<void> _drainMessageSyncRequests(
    int accountId,
    int generation,
  ) async {
    while (_messageSyncRequested &&
        generation == _messageSyncGeneration &&
        accountId == myId) {
      _messageSyncRequested = false;
      try {
        await _synchronizeAllMessagePages(accountId, generation);
        _messageSyncRetryTimer?.cancel();
        _messageSyncRetryTimer = null;
        _messageSyncRetryAttempt = 0;
      } catch (error, stackTrace) {
        debugPrint('ChatProvider message sync failed: $error\n$stackTrace');
        _scheduleMessageSyncRetry(accountId, generation);
        return;
      }
    }
  }

  void _scheduleMessageSyncRetry(int accountId, int generation) {
    if (generation != _messageSyncGeneration ||
        accountId != myId ||
        _messageSyncRetryTimer?.isActive == true) {
      return;
    }
    final exponent =
        _messageSyncRetryAttempt > 5 ? 5 : _messageSyncRetryAttempt;
    _messageSyncRetryAttempt++;
    _messageSyncRetryTimer = Timer(Duration(seconds: 1 << exponent), () {
      _messageSyncRetryTimer = null;
      if (generation == _messageSyncGeneration && accountId == myId) {
        unawaited(synchronizeMessages());
      }
    });
  }

  Future<void> _synchronizeAllMessagePages(
    int accountId,
    int generation,
  ) async {
    var cursor = _lastSyncedSyncSeq;
    while (generation == _messageSyncGeneration && accountId == myId) {
      final page = await _chat.syncMessages(
        afterSyncSeq: cursor,
        limit: 200,
      );
      if (generation != _messageSyncGeneration || accountId != myId) return;
      if (page.nextSyncSeq < cursor ||
          (page.hasMore && page.nextSyncSeq <= cursor)) {
        throw StateError('message sync cursor did not advance');
      }

      // 先应用服务端持久清空标记：本端离线期间错过的清空在此补齐。
      // 必须在处理 items 之前执行，否则已被清空的消息会被重新插回本地列表。
      for (final cleared in page.clearedConversations) {
        applyServerClearedConversation(
          conversationId: cleared.conversationId,
          chatType: cleared.chatType,
          clearedAt: cleared.clearedAt,
        );
      }

      final persisted = <({String peerId, ChatMessage message})>[];
      for (final item in page.items) {
        if (item.syncSeq <= cursor || item.syncSeq > page.nextSyncSeq) {
          throw StateError('message sync item is outside the response page');
        }
        final msg = ChatMessage.fromJson(item.message);
        // 私聊的会话对端标识：
        // - 普通消息：发送方是我 → toId；否则 → from。
        // - **系统消息（from == 0）**：不能用 toId —— 那在「同意方」视角下等于我自己，
        //   会凭空多出一个「自聊会话」（真机实测：B 端多出 vb047 会话）。
        //   此时从**同步原始报文的 conversationId**（conv:private:A:B）解析出「不是我」的那一方。
        final rawConversationId = '${item.message['conversationId'] ?? ''}';
        final peerId = msg.chatType == 'private'
            ? (msg.from == 0
                ? (_peerIdFromConversationId(rawConversationId, 'private') ??
                    msg.toId)
                : (msg.from == accountId ? msg.toId : '${msg.from}'))
            : msg.toId;
        final key = chatKey(msg.chatType, peerId);
        if (_isMessageLocallyCleared(key, msg)) continue;

        messageMap.putIfAbsent(key, () => []);
        final list = messageMap[key]!;
        final isCurrent = isAppForeground() &&
            currentChatId == peerId &&
            currentChatType == msg.chatType;
        final suppressListInsert =
            isCurrent && !allowRealtimeMergeIntoCurrentChatList;
        // 去重需同时匹配 msgId 与 clientMsgId：本地乐观/媒体占位的 msgId=clientMsgId，
        // 服务端确认后 msgId 为服务端雪花 id——只按 msgId 去重会把同一条消息插成两条
        // （上传视频耗时期间 ack 未达时最易触发）。
        final existingIdx = list.indexWhere(
          (message) =>
              message.msgId == msg.msgId ||
              (message.clientMsgId != null &&
                  msg.clientMsgId != null &&
                  message.clientMsgId == msg.clientMsgId),
        );
        if (existingIdx >= 0) {
          // 用服务端权威数据替换本地占位（消除 sending、补齐服务端 msgId）；
          // 编辑下行（同步携带 edited + 新正文）也在此覆盖本地正文。
          final local = list[existingIdx];
          final editedChanged =
              msg.edited && (!local.edited || local.content != msg.content);
          if (local.msgId != msg.msgId ||
              local.status == 'sending' ||
              editedChanged) {
            list[existingIdx] = msg;
          }
        } else if (!suppressListInsert) {
          insertChatMessageChronologically(list, msg);
        }
        final didInsert = existingIdx < 0 && !suppressListInsert;

        persisted.add((peerId: peerId, message: msg));
        upsertConversation(
          peerId,
          msg.chatType,
          conversationPreviewForMessage(msg, viewerId: accountId),
          incrementUnread: _shouldIncrementUnreadForOfflineMerge(
            peerId: peerId,
            msg: msg,
            my: accountId,
            readAt: item.readAt,
            didInsert: didInsert,
            isCurrent: isCurrent,
            suppressListInsert: suppressListInsert,
          ),
          name: _resolvePeerName(peerId, msg.chatType, msg.fromUsername),
          lastTime: msg.timestamp,
          persist: false,
          notify: false,
        );
        _maybeScheduleAddressBookSyncForIncoming(peerId, msg.chatType);
      }

      await _local.applyMessageSyncPage(
        accountId: accountId,
        messages: persisted,
        conversations: List<Conversation>.from(conversations),
        nextSyncSeq: page.nextSyncSeq,
      );
      if (generation != _messageSyncGeneration || accountId != myId) return;
      _lastSyncedSyncSeq = page.nextSyncSeq;
      cursor = page.nextSyncSeq;
      notifyListeners();
      if (!page.hasMore) return;
    }
  }

  ChatMessage? findMessageInCurrent(String? replyMsgId) {
    if (replyMsgId == null) return null;
    for (final m in currentMessages) {
      if (m.msgId == replyMsgId) return m;
    }
    return null;
  }

  /// 指定会话的消息列表（不依赖 [currentChatId]，避免进房后 [openChat] 尚未执行时读错会话）。
  List<ChatMessage> messagesFor(String peerId, String chatType) {
    final key = chatKey(chatType, peerId);
    return List<ChatMessage>.from(messageMap[key] ?? []);
  }

  // ─── Chat backup / restore（聊天记录备份与迁移） ───

  /// 构建当前账号的聊天记录备份（会话元数据 + 全部本地消息），返回可序列化 JSON。
  Future<Map<String, dynamic>> buildChatBackup() async {
    final storedConversations = await _local.loadConversations();
    final sessions = <ChatBackupSession>[];
    for (final conversation in storedConversations) {
      final messages =
          await _local.loadAllMessages(conversation.id, conversation.chatType);
      if (messages.isEmpty) continue;
      sessions.add(
        ChatBackupSession(
          peerId: conversation.id,
          chatType: conversation.chatType,
          messages: messages,
        ),
      );
    }
    return ChatBackup(
      uid: myId,
      exportedAt: DateTime.now().toUtc(),
      conversations: storedConversations,
      sessions: sessions,
    ).toJson();
  }

  /// 恢复聊天记录备份：覆盖合并会话、按 msgId 去重合并消息，并刷新会话列表。
  ///
  /// 返回实际合并的会话数与消息数；文件格式不合法时抛出 [FormatException]。
  Future<({int conversationCount, int messageCount})> restoreChatBackup(
    Map<String, dynamic> json,
  ) async {
    final backup = ChatBackup.tryParse(json);
    if (backup == null) {
      throw const FormatException('invalid chat backup file');
    }

    // 1) 会话「覆盖合并」：以磁盘会话为基线（而非内存态，避免内存空/过期时误删本机会话），
    //    (chatType, peerId) 为键，导入项覆盖本机项，本机独有项保留。
    final diskConversations = await _local.loadConversations();
    final mergedByKey = <String, Conversation>{
      for (final conversation in diskConversations)
        '${conversation.chatType}:${conversation.id}': conversation,
    };
    for (final conversation in backup.conversations) {
      mergedByKey['${conversation.chatType}:${conversation.id}'] = conversation;
    }
    final mergedConversations = mergedByKey.values.toList(growable: false);
    await _local.saveConversations(mergedConversations);
    conversations = List<Conversation>.from(mergedConversations);

    // 2) 消息按 msgId 去重合并（upsertMessages 内部为 insertOnConflictUpdate，
    //    主键 (scopeId, msgId) 天然去重；同时合并 clientMsgId 冲突）。
    var messageCount = 0;
    final seenImportMsgIds = <String>{};
    for (final session in backup.sessions) {
      if (session.messages.isEmpty) continue;
      // 防御损坏备份：消息 chatType 与会话不一致时强制对齐，避免内存/DB key 发散产生孤儿消息。
      final normalized = session.messages
          .map((m) => m.chatType == session.chatType
              ? m
              : m.copyWith(chatType: session.chatType))
          .toList(growable: false);
      // 导入内部按 msgId 去重，避免重复条目多计（返回的 messageCount = 实际落库条数）。
      final unique = normalized
          .where((m) => seenImportMsgIds.add(m.msgId))
          .toList(growable: false);
      if (unique.isEmpty) continue;
      await _local.saveMessages(session.peerId, unique);
      messageCount += unique.length;

      final key = chatKey(session.chatType, session.peerId);
      final current = messageMap[key];
      final byId = <String, ChatMessage>{
        if (current != null)
          for (final message in current) message.msgId: message,
      };
      for (final message in unique) {
        byId[message.msgId] = message;
      }
      final merged = byId.values.toList();
      sortChatMessagesChronological(merged);
      messageMap[key] = merged;
    }

    notifyListeners();
    return (
      conversationCount: mergedConversations.length,
      messageCount: messageCount,
    );
  }

  // ─── Channels / Secret Chats（频道 · 私密聊天会话域） ───
  //
  // UI 通过 [ChatProvider] 访问这些能力：screen → provider → repository → api，
  // 不越层、不在 screen 裸调网络。

  ChannelInfo? cachedChannelInfo(String id) => _channelInfoCache[id];

  SecretChatInfo? cachedSecretChat(String id) => _secretChatCache[id];

  /// 创建频道并插入会话列表（名称回填）。
  Future<ChannelInfo> createChannel({
    required String name,
    String? description,
  }) async {
    final info = await _chat.createChannel(
      name: name,
      description: description,
    );
    _channelInfoCache[info.id] = info;
    upsertConversation(
      info.id,
      'channel',
      '',
      incrementUnread: false,
      name: info.name,
    );
    notifyListeners();
    return info;
  }

  /// 我的频道（创建 + 已订阅）。
  Future<List<ChannelInfo>> myChannels() async {
    final list = await _chat.myChannels();
    for (final info in list) {
      _channelInfoCache[info.id] = info;
    }
    return list;
  }

  /// 频道详情；结果入缓存供订阅者只读判定复用，并确保会话列表有该频道（名称回填）。
  Future<ChannelInfo> channelInfo(String id) async {
    final info = await _chat.channelInfo(id);
    _channelInfoCache[info.id] = info;
    upsertConversation(
      info.id,
      'channel',
      '',
      incrementUnread: false,
      name: info.name,
    );
    notifyListeners();
    return info;
  }

  /// 订阅频道（进房阅读前对非管理员调用，服务端幂等）；订阅后进会话列表（名称回填）。
  Future<ChannelInfo> subscribeChannel(String id) async {
    final info = await _chat.subscribeChannel(id);
    _channelInfoCache[info.id] = info;
    upsertConversation(
      info.id,
      'channel',
      '',
      incrementUnread: false,
      name: info.name,
    );
    notifyListeners();
    return info;
  }

  /// 取消订阅频道：服务端删除订阅 + 本地移除会话/缓存。
  Future<void> unsubscribeChannel(String id) async {
    try {
      await _chat.unsubscribeChannel(id);
    } catch (_) {
      // 服务端失败不阻塞本地移除（幂等语义）。
    }
    _channelInfoCache.remove(id);
    removeConversation(id, 'channel');
    messageMap.remove(chatKey('channel', id));
    notifyListeners();
  }

  /// 更新频道信息（名称/公告），仅 owner。
  Future<ChannelInfo> updateChannel(
    String id, {
    String? name,
    String? announcement,
  }) async {
    final info =
        await _chat.updateChannel(id, name: name, announcement: announcement);
    _channelInfoCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 删除频道（硬删除），仅 owner。
  Future<void> deleteChannel(String id) async {
    await _chat.deleteChannel(id);
    _channelInfoCache.remove(id);
    removeConversation(id, 'channel');
    messageMap.remove(chatKey('channel', id));
    notifyListeners();
  }

  /// 按名称搜索公开频道。
  Future<List<ChannelInfo>> searchChannels(String keyword,
      {int limit = 20}) async {
    final list = await _chat.searchChannels(keyword, limit: limit);
    for (final info in list) {
      _channelInfoCache[info.id] = info;
    }
    return list;
  }

  /// 通过频道号（分享码）查频道。
  Future<ChannelInfo> channelByCode(String code) async {
    final info = await _chat.channelByCode(code);
    _channelInfoCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 发起私密聊天并插入会话列表（名称回填对端展示名）。
  Future<SecretChatInfo> createSecretChat({
    required int peerUserId,
    String? name,
    String? deviceId,
  }) async {
    // 创建时带上本端设备公钥：后端预填双方公钥，双方齐备即 ready，
    // 无需等对方接受/在线即可加密发送（Signal 式模型）。
    final resolvedDeviceId = deviceId ?? _local.clientReleaseInstallationId;
    String? myPublicKey;
    if (resolvedDeviceId != null && resolvedDeviceId.isNotEmpty) {
      myPublicKey = await _e2ee.ensureDeviceKey(deviceId: resolvedDeviceId);
    }
    final info = await _chat.createSecretChat(
      peerUserId: peerUserId,
      publicKey: myPublicKey,
    );
    _secretChatCache[info.id] = info;
    // 后端已回填双方公钥：立即派生共享密钥，本端马上可发送。
    await _e2ee.tryEstablishSecret(info);
    final resolvedName =
        (name == null || name.trim().isEmpty) ? '私密聊天' : name.trim();
    upsertConversation(
      info.id,
      'secret',
      '',
      incrementUnread: false,
      name: resolvedName,
    );
    notifyListeners();
    return info;
  }

  /// 我的私密会话列表。
  Future<List<SecretChatInfo>> mySecretChats() async {
    final list = await _chat.mySecretChats();
    for (final info in list) {
      _secretChatCache[info.id] = info;
    }
    return list;
  }

  /// 同步私密会话进会话列表：拉取「我的私密会话」并补齐缺失的会话条目，
  /// 使接收方（对方）也能看到发起方创建的私密聊天并进入握手。
  Future<void> syncSecretChatsIntoConversations() async {
    final accountId = myId;
    if (accountId == null) return;
    try {
      final list = await _chat.mySecretChats();
      for (final info in list) {
        _secretChatCache[info.id] = info;
        final existing = conversations
            .where((c) => c.chatType == 'secret' && c.id == info.id)
            .toList();
        if (existing.isEmpty) {
          upsertConversation(
            info.id,
            'secret',
            '',
            incrementUnread: false,
            name: '私密聊天',
          );
        }
      }
      notifyListeners();
    } catch (_) {
      // 拉取失败不阻塞会话列表；下次刷新重试。
    }
  }

  /// 更新私密会话定时销毁策略（off / 30s / 5m / 1h / 1d）。
  Future<SecretChatInfo> updateSecretChatDestroyPolicy({
    required String id,
    required String policy,
  }) async {
    final info = await _chat.destroySecretChatPolicy(id: id, policy: policy);
    _secretChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 删除私密会话：服务端硬删除（任意一方删除即终止，双方列表都不再返回）。
  /// 服务端失败也本地移除（可能对方已删除），避免「删不掉又回来」。
  Future<void> deleteSecretChat(String secretChatId) async {
    try {
      await _chat.deleteSecretChat(secretChatId);
    } catch (_) {
      // 忽略：服务端删除失败不阻塞本地移除。
    }
    _clearSecretChatLocally(secretChatId);
    notifyListeners();
  }

  /// 服务端推送的「私密聊天已终止」信号：对方删除私密聊天时本端收到，
  /// 同步移除会话并清空本地密文消息（Telegram 语义：双向删除 + 终止）。
  void onSecretChatDeleted(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final secretChatId = (map['secretChatId'] ?? '').toString();
    if (secretChatId.isEmpty) return;
    _clearSecretChatLocally(secretChatId);
    notifyListeners();
  }

  void _clearSecretChatLocally(String secretChatId) {
    removeConversation(secretChatId, 'secret');
    _secretChatCache.remove(secretChatId);
    _secretPulledSeq.remove(secretChatId);
    _secretReadReportedSeq.remove(secretChatId);
    _secretDestroySyncedAt.remove(secretChatId);
    messageMap.remove(chatKey('secret', secretChatId));
  }

  // ─── 私密群聊（逐成员 E2EE）会话域 ───

  SecretGroupChatInfo? cachedSecretGroupChat(String id) =>
      _secretGroupChatCache[id];

  /// 发起私密群聊：`memberUserIds` 不含群主（群主=当前用户）；创建后插入会话列表。
  Future<SecretGroupChatInfo> createSecretGroupChat({
    required List<int> memberUserIds,
  }) async {
    final info =
        await _chat.createSecretGroupChat(memberUserIds: memberUserIds);
    _secretGroupChatCache[info.id] = info;
    upsertConversation(
      info.id,
      'secret_group',
      '',
      incrementUnread: false,
      name: '私密群聊',
    );
    notifyListeners();
    return info;
  }

  /// 我的私密群聊列表（入缓存）。
  Future<List<SecretGroupChatInfo>> mySecretGroupChats() async {
    final list = await _chat.mySecretGroupChats();
    for (final info in list) {
      _secretGroupChatCache[info.id] = info;
    }
    return list;
  }

  /// 同步私密群聊进会话列表：拉取「我的私密群聊」并补齐缺失的会话条目，
  /// 使接收方（成员）也能看到发起方创建的私密群聊并进入握手。
  Future<void> syncSecretGroupChatsIntoConversations() async {
    final accountId = myId;
    if (accountId == null) return;
    try {
      final list = await _chat.mySecretGroupChats();
      for (final info in list) {
        _secretGroupChatCache[info.id] = info;
        // 尝试派生各成员共享密钥并标记 ready（不阻塞会话列表）。
        unawaited(_e2ee.tryEstablishGroup(info).catchError((_) => false));
        final existing = conversations
            .where((c) => c.chatType == 'secret_group' && c.id == info.id)
            .toList();
        if (existing.isEmpty) {
          final display =
              (info.name ?? '').trim().isEmpty ? '私密群聊' : info.name!;
          upsertConversation(
            info.id,
            'secret_group',
            '',
            incrementUnread: false,
            name: display,
          );
        }
      }
      notifyListeners();
    } catch (_) {
      // 拉取失败不阻塞会话列表；下次刷新重试。
    }
  }

  /// 确保设备密钥已注册并完成群握手（提交本端公钥、派生各成员共享密钥）。
  Future<SecretGroupChatInfo?> ensureSecretGroupHandshake(
    String groupId, {
    String? deviceId,
  }) async {
    final resolvedDeviceId = deviceId ?? _local.clientReleaseInstallationId;
    if (resolvedDeviceId == null || resolvedDeviceId.isEmpty) return null;
    final info = await _e2ee.secretGroupHandshake(
      groupId,
      deviceId: resolvedDeviceId,
    );
    _secretGroupChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 更新私密群聊定时销毁策略（off / 30s / 5m / 1h / 1d）。
  Future<SecretGroupChatInfo> updateSecretGroupDestroyPolicy({
    required String id,
    required String policy,
  }) async {
    final info =
        await _chat.setSecretGroupDestroyPolicy(id: id, policy: policy);
    _secretGroupChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 更新私密群聊匿名发言开关（仅群主）。
  Future<SecretGroupChatInfo> updateSecretGroupAnonymous({
    required String id,
    required bool enabled,
  }) async {
    final info = await _chat.setSecretGroupAnonymous(id: id, enabled: enabled);
    _secretGroupChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 置顶私密群聊消息（仅群主）。
  Future<SecretGroupChatInfo> pinSecretGroupMessage({
    required String id,
    required String msgId,
  }) async {
    final info = await _chat.pinSecretGroupMessage(id: id, msgId: msgId);
    _secretGroupChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 取消置顶（仅群主）。
  Future<SecretGroupChatInfo> unpinSecretGroupMessage(String id) async {
    final info = await _chat.unpinSecretGroupMessage(id);
    _secretGroupChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 生成私密群聊邀请令牌（仅群主）。
  Future<SecretGroupChatInfo> generateSecretGroupInvite(String id) async {
    final info = await _chat.generateSecretGroupInvite(id);
    _secretGroupChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 凭邀请令牌加入私密群聊。
  Future<SecretGroupChatInfo> joinSecretGroupByInvite(String token) async {
    final info = await _chat.joinSecretGroupByInvite(token);
    _secretGroupChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 设置私密群聊「仅群主可发言」（仅群主）。
  Future<SecretGroupChatInfo> updateSecretGroupOwnerOnlyPost({
    required String id,
    required bool enabled,
  }) async {
    final info =
        await _chat.setSecretGroupOwnerOnlyPost(id: id, enabled: enabled);
    _secretGroupChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 修改私密群聊名称（仅群主）；同步会话列表显示名。
  Future<SecretGroupChatInfo> updateSecretGroupName({
    required String id,
    required String name,
  }) async {
    final info = await _chat.setSecretGroupName(id: id, name: name);
    _secretGroupChatCache[info.id] = info;
    final display = (info.name ?? '').trim().isEmpty ? '私密群聊' : info.name!;
    updateConversationDisplay(id, 'secret_group', name: display);
    notifyListeners();
    return info;
  }

  /// 修改私密群聊公告（仅群主）。
  Future<SecretGroupChatInfo> updateSecretGroupAnnouncement({
    required String id,
    required String announcement,
  }) async {
    final info = await _chat.setSecretGroupAnnouncement(
        id: id, announcement: announcement);
    _secretGroupChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 移除私密群聊成员（仅群主）。
  Future<SecretGroupChatInfo> removeSecretGroupMember({
    required String id,
    required int userId,
  }) async {
    final info = await _chat.removeSecretGroupMember(id: id, userId: userId);
    _secretGroupChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 删除（解散）私密群聊：服务端失败也本地移除（可能已被群主解散）。
  Future<void> deleteSecretGroupChat(String groupId) async {
    try {
      await _chat.deleteSecretGroupChat(groupId);
    } catch (_) {
      // 忽略：服务端删除失败不阻塞本地移除。
    }
    removeConversation(groupId, 'secret_group');
    _secretGroupChatCache.remove(groupId);
    _secretGroupPulledSeq.remove(groupId);
    _secretGroupReadReportedSeq.remove(groupId);
    _secretGroupDestroySyncedAt.remove(groupId);
    messageMap.remove(chatKey('secret_group', groupId));
    notifyListeners();
  }

  /// 私密群聊是否已完成全员握手（可发送/接收）。
  bool secretGroupReady(String groupId) => _e2ee.groupReady(groupId);

  /// 按 userId 解析展示名（复用好友通讯录缓存）；无记录返回 null。
  String? userDisplayName(int userId) {
    if (userId == myId) {
      final self = selfDisplayNameFromStorage;
      if (self != null && self.isNotEmpty) return self;
    }
    final fd = _friend.getFriendDisplay(userId);
    final name = fd?.name.trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  /// 私密群聊发送文本：对每个非我成员逐成员加密 → POST /secret-group-messages →
  /// 本地乐观插入。返回发送结果（语义对齐 1 对 1 私密聊天）。
  Future<SecretSendResult> sendSecretGroupText({
    required String groupId,
    required String text,
    String? deviceId,
    String msgType = 'text',
    String? wireContent,
    List<String>? mediaObjectIds,
    String? replyMsgId,
    String? convPreview,
    List<dynamic>? atUsers,
  }) async {
    final myId = this.myId;
    if (myId == null) return SecretSendResult.failed;
    if (!_e2ee.groupReady(groupId)) {
      await ensureSecretGroupHandshake(groupId, deviceId: deviceId);
    }
    final payload = jsonEncode({
      't': msgType,
      'c': text,
      if (wireContent != null) 'w': wireContent,
      if (mediaObjectIds != null && mediaObjectIds.isNotEmpty)
        'm': mediaObjectIds,
      if (replyMsgId != null && replyMsgId.isNotEmpty) 'r': replyMsgId,
    });

    final info = _secretGroupChatCache[groupId];
    final members = info?.members ?? const <SecretGroupMember>[];
    final recipients = <Map<String, dynamic>>[];
    for (final member in members) {
      if (member.userId == myId) continue; // 跳过自己（发送方不含自己）。
      final ciphertext = await _e2ee.encryptForGroupMember(
        groupId,
        member.userId,
        payload,
      );
      if (ciphertext == null) continue; // 成员尚未提交公钥。
      recipients.add({'userId': member.userId, 'ciphertext': ciphertext});
    }
    final msgId = _newClientMessageId();
    final message = ChatMessage(
      msgId: msgId,
      from: myId,
      toId: groupId,
      chatType: 'secret_group',
      msgType: msgType,
      content: text, // 本地明文仅存本机展示；远端仅存逐成员密文
      mediaObjectIds: mediaObjectIds,
      replyMsgId: replyMsgId,
      timestamp: DateTime.now().toUtc(),
      status: recipients.isEmpty ? 'pending' : 'sent',
    );
    if (recipients.isEmpty) {
      // 没有任何成员完成握手：本地乐观展示 + 入队，握手完成后自动补发。
      _insertLocalSecretMessage(
          'secret_group', groupId, message, convPreview ?? text);
      _enqueuePendingSecretSend(_PendingSecretSend(
        msgId: msgId,
        chatId: groupId,
        isGroup: true,
        text: text,
        msgType: msgType,
        wireContent: wireContent,
        mediaObjectIds: mediaObjectIds,
        replyMsgId: replyMsgId,
        convPreview: convPreview,
        atUsers: atUsers,
      ));
      return SecretSendResult.success;
    }

    await _chat.postSecretGroupMessage(
      secretGroupId: int.tryParse(groupId) ?? 0,
      msgId: msgId,
      recipients: recipients,
      mediaObjectIds: mediaObjectIds,
      atUsers: atUsers,
    );

    _insertLocalSecretMessage(
        'secret_group', groupId, message, convPreview ?? text);
    return SecretSendResult.success;
  }

  /// 编辑私密群聊文本消息（仅发送方）：逐成员重加密 → POST /edit → 本地更新明文。
  Future<bool> editSecretGroupText({
    required String groupId,
    required String msgId,
    required String text,
  }) async {
    final myId = this.myId;
    if (myId == null) return false;
    if (!_e2ee.groupReady(groupId)) {
      await ensureSecretGroupHandshake(groupId);
    }
    final payload = jsonEncode({'t': 'text', 'c': text});
    final info = _secretGroupChatCache[groupId];
    final members = info?.members ?? const <SecretGroupMember>[];
    final recipients = <Map<String, dynamic>>[];
    for (final member in members) {
      if (member.userId == myId) continue;
      final ciphertext = await _e2ee.encryptForGroupMember(
        groupId,
        member.userId,
        payload,
      );
      if (ciphertext == null) continue;
      recipients.add({'userId': member.userId, 'ciphertext': ciphertext});
    }
    if (recipients.isEmpty) return false;
    await _chat.editSecretGroupMessage(
      secretGroupId: int.tryParse(groupId) ?? 0,
      msgId: msgId,
      recipients: recipients,
    );
    final key = chatKey('secret_group', groupId);
    final list = messageMap[key];
    if (list != null) {
      final idx = list.indexWhere((m) => m.msgId == msgId);
      if (idx >= 0) {
        list[idx] = list[idx].copyWith(content: text);
        notifyListeners();
      }
    }
    return true;
  }

  /// 拉取私密群聊密文并按成员解密合并到会话（游标 `_secretGroupPulledSeq`）。
  ///
  /// 解密失败的消息不推进游标，保留重试，杜绝消息永久丢失。
  Future<void> pullSecretGroupMessages(
    String groupId, {
    int? afterSeq,
    bool forceFull = false,
  }) async {
    if (!_e2ee.groupReady(groupId)) {
      await ensureSecretGroupHandshake(groupId);
    }
    final cursor =
        afterSeq ?? (forceFull ? 0 : (_secretGroupPulledSeq[groupId] ?? 0));
    final wireList = await _chat.listSecretGroupMessages(
      secretGroupId: int.tryParse(groupId) ?? 0,
      afterSeq: cursor,
      limit: 100,
    );
    final decrypted = <ChatMessage>[];
    var maxProcessedSeq = cursor;
    var maxReadSeq = _secretGroupReadReportedSeq[groupId] ?? 0;
    for (final wire in wireList) {
      final seq = int.tryParse((wire['seq'] ?? '0').toString()) ?? 0;
      if (seq <= maxProcessedSeq) continue;
      final status = (wire['status'] ?? 'active').toString();
      final msgId = (wire['msgId'] ?? wire['msg_id'] ?? '').toString();
      if (status == 'destroyed' || status == 'recalled') {
        _applySecretDestroyState(msgId, status);
        maxProcessedSeq = seq;
        continue;
      }
      final ciphertext = (wire['ciphertext'] ?? '').toString();
      final from = int.tryParse(
            (wire['fromUserId'] ?? wire['from_user_id'] ?? '0').toString(),
          ) ??
          0;
      final plain =
          await _e2ee.decryptFromGroupMember(groupId, from, ciphertext);
      if (plain == null) {
        // 密文无法解密（成员公钥未就绪/会话未握手完成）：不推进游标，保留重试。
        break;
      }
      final createdAt =
          parseUtcDateTime(wire['createdAt']) ?? DateTime.now().toUtc();
      String resolvedMsgType = 'text';
      String resolvedContent = plain;
      List<dynamic>? resolvedMedia;
      String? resolvedReplyMsgId;
      final decoded = _tryDecodeSecretPayload(plain);
      if (decoded != null) {
        resolvedMsgType = decoded['t'] as String? ?? 'text';
        resolvedContent = decoded['c'] as String? ?? plain;
        resolvedMedia = decoded['m'] as List<dynamic>?;
        final rawReply = decoded['r'];
        if (rawReply is String && rawReply.isNotEmpty) {
          resolvedReplyMsgId = rawReply;
        }
      }
      decrypted.add(ChatMessage(
        msgId: msgId,
        from: from,
        toId: groupId,
        chatType: 'secret_group',
        msgType: resolvedMsgType,
        content: resolvedContent,
        mediaObjectIds: resolvedMedia,
        replyMsgId: resolvedReplyMsgId,
        timestamp: createdAt.toUtc(),
        seq: seq,
        status: 'active',
      ));
      maxProcessedSeq = seq;
      // 只有前台正在查看该私密群时，解密消息才算真正查阅。
      if (isAppForeground() && currentChatId == groupId &&
          currentChatType == 'secret_group' && from != myId && seq > maxReadSeq) {
        maxReadSeq = seq;
      }
    }
    await _refreshSecretMediaUrls(groupId, decrypted, group: true);
    _secretGroupPulledSeq[groupId] = maxProcessedSeq;
    // 已读上报（服务端权威计时）：本端确实看到对方消息后通知服务端开始倒计时。
    if (maxReadSeq > (_secretGroupReadReportedSeq[groupId] ?? 0)) {
      unawaited(_chat
          .markSecretGroupRead(
            secretGroupId: int.tryParse(groupId) ?? 0,
            afterSeq: maxReadSeq,
          )
          .then((_) {
        if (maxReadSeq > (_secretGroupReadReportedSeq[groupId] ?? 0)) {
          _secretGroupReadReportedSeq[groupId] = maxReadSeq;
        }
      }).catchError((_) {}));
    }
    // 销毁状态增量同步（服务端权威）：撤回/删除痕迹按 msgId 移除本地消息。
    final afterDestroy = _secretGroupDestroySyncedAt[groupId];
    unawaited(_chat
        .listSecretGroupDestroyedStates(
      int.tryParse(groupId) ?? 0,
      afterDestroyAt: afterDestroy?.toIso8601String(),
    )
        .then((states) {
      DateTime? maxDestroyAt = afterDestroy;
      for (final state in states) {
        final msgId = (state['msgId'] ?? '').toString();
        if (msgId.isEmpty) continue;
        final reason = (state['reason'] ?? '').toString();
        _applySecretDestroyState(msgId, reason);
        final destroyAt = parseUtcDateTime(state['destroyAt']);
        if (destroyAt != null &&
            (maxDestroyAt == null || destroyAt.isAfter(maxDestroyAt))) {
          maxDestroyAt = destroyAt;
        }
      }
      if (maxDestroyAt != null) {
        _secretGroupDestroySyncedAt[groupId] = maxDestroyAt;
      }
    }).catchError((_) {}));
    if (decrypted.isEmpty) return;
    final key = chatKey('secret_group', groupId);
    messageMap.putIfAbsent(key, () => []);
    final list = messageMap[key]!;
    final newlyInserted = <ChatMessage>[];
    for (final message in decrypted) {
      final idx = list.indexWhere((m) => m.msgId == message.msgId);
      if (idx < 0) {
        insertChatMessageChronologically(list, message);
        newlyInserted.add(message);
      } else {
        final local = list[idx];
        if (local.seq == null && message.seq != null) {
          list[idx] = message;
          newlyInserted.add(message);
        }
      }
    }
    if (newlyInserted.isNotEmpty) {
      unawaited(_local.saveMessages(groupId, newlyInserted));
    }
    final latest = decrypted.last; // 服务端 seq 升序，末条为最新。
    upsertConversation(
      groupId,
      'secret_group',
      conversationPreviewForMessage(latest, viewerId: myId),
      incrementUnread: false,
    );
    final incomingCount = (isAppForeground() && currentChatId == groupId &&
            currentChatType == 'secret_group')
        ? 0
        : newlyInserted.where((m) => m.from != myId).length;
    if (incomingCount > 0) {
      bumpUnread(groupId, 'secret_group', incomingCount);
    }
    notifyListeners();
  }

  /// 服务端推送的「私密群聊消息已存储」轻量信号：仅含元数据，无内容。
  /// 在线接收方收到后若群已 ready 则立即增量拉取密文并解密。
  void onSecretGroupStored(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final groupId = (map['secretGroupId'] ?? '').toString();
    if (groupId.isEmpty) return;
    if (!secretGroupReady(groupId)) return;
    unawaited(pullSecretGroupMessages(groupId).catchError((_) {}));
  }

  // ─── E2EE：私密聊天加解密 ───

  /// 私密聊天/群聊待发送队列：握手未完成时本地乐观展示并暂存，握手完成后按原 msgId 自动补发。
  final Map<String, List<_PendingSecretSend>> _pendingSecretSends = {};

  void _insertLocalSecretMessage(
    String chatType,
    String chatId,
    ChatMessage message,
    String preview,
  ) {
    final key = chatKey(chatType, chatId);
    messageMap.putIfAbsent(key, () => []);
    insertChatMessageChronologically(messageMap[key]!, message);
    unawaited(_local.saveMessages(chatId, [message]));
    upsertConversation(chatId, chatType, preview, incrementUnread: false);
    notifyListeners();
  }

  void _enqueuePendingSecretSend(_PendingSecretSend item) {
    _pendingSecretSends.putIfAbsent(item.chatId, () => []).add(item);
    for (final delay in const [
      Duration(seconds: 2),
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 20),
    ]) {
      Future<void>.delayed(delay, () {
        unawaited(_flushPendingSecretSends(item.chatId).catchError((_) {}));
      });
    }
  }

  Future<void> _flushPendingSecretSends(String chatId) async {
    final queue = _pendingSecretSends[chatId];
    if (queue == null || queue.isEmpty) return;
    final isGroup = queue.first.isGroup;
    if (isGroup) {
      if (!_e2ee.groupReady(chatId)) {
        await ensureSecretGroupHandshake(chatId);
      }
    } else {
      if (!_e2ee.hasSharedSecret(chatId)) {
        await ensureSecretChatHandshake(chatId);
      }
    }
    final ready =
        isGroup ? _e2ee.groupReady(chatId) : _e2ee.hasSharedSecret(chatId);
    if (!ready) return;
    _pendingSecretSends.remove(chatId);
    for (final item in queue) {
      if (isGroup) {
        await _postQueuedSecretGroupSend(item);
      } else {
        await _postQueuedSecretSend(item);
      }
    }
  }

  Future<void> _postQueuedSecretSend(_PendingSecretSend item) async {
    final payload = jsonEncode({
      't': item.msgType,
      'c': item.text,
      if (item.wireContent != null) 'w': item.wireContent,
      if (item.mediaObjectIds != null && item.mediaObjectIds!.isNotEmpty)
        'm': item.mediaObjectIds,
      if (item.replyMsgId != null && item.replyMsgId!.isNotEmpty)
        'r': item.replyMsgId,
    });
    final ciphertext = await _e2ee.encryptForChat(item.chatId, payload);
    if (ciphertext == null) return;
    await _chat.postSecretMessage(
      secretChatId: int.tryParse(item.chatId) ?? 0,
      msgId: item.msgId,
      ciphertext: ciphertext,
      mediaObjectIds: item.mediaObjectIds,
    );
  }

  Future<void> _postQueuedSecretGroupSend(_PendingSecretSend item) async {
    final myId = this.myId;
    if (myId == null) return;
    final payload = jsonEncode({
      't': item.msgType,
      'c': item.text,
      if (item.wireContent != null) 'w': item.wireContent,
      if (item.mediaObjectIds != null && item.mediaObjectIds!.isNotEmpty)
        'm': item.mediaObjectIds,
      if (item.replyMsgId != null && item.replyMsgId!.isNotEmpty)
        'r': item.replyMsgId,
    });
    final info = _secretGroupChatCache[item.chatId];
    final members = info?.members ?? const <SecretGroupMember>[];
    final recipients = <Map<String, dynamic>>[];
    for (final member in members) {
      if (member.userId == myId) continue;
      final ciphertext = await _e2ee.encryptForGroupMember(
        item.chatId,
        member.userId,
        payload,
      );
      if (ciphertext == null) continue;
      recipients.add({'userId': member.userId, 'ciphertext': ciphertext});
    }
    if (recipients.isEmpty) return;
    await _chat.postSecretGroupMessage(
      secretGroupId: int.tryParse(item.chatId) ?? 0,
      msgId: item.msgId,
      recipients: recipients,
      mediaObjectIds: item.mediaObjectIds,
      atUsers: item.atUsers,
    );
  }

  /// 确保设备密钥已注册并完成会话握手（提交本端公钥、推导共享密钥）。
  ///
  /// [deviceId] 缺省使用安装 ID；返回握手后的会话信息。会话未 ready（对方未提交公钥）
  /// 时共享密钥暂不可用，发送将等待对方握手后重试。
  Future<SecretChatInfo?> ensureSecretChatHandshake(
    String secretChatId, {
    String? deviceId,
  }) async {
    final provided = deviceId ?? _local.clientReleaseInstallationId;
    // 安装 ID 为空时回退到稳定占位 deviceId：确保本端密钥对仍能生成/复用并完成握手，
    // 否则接收方首条消息会因「共享密钥未建立」而无法解密、无法展示/建会话/加角标。
    final resolvedDeviceId =
        (provided == null || provided.isEmpty) ? 'device-primary' : provided;
    final info =
        await _e2ee.handshake(secretChatId, deviceId: resolvedDeviceId);
    _secretChatCache[info.id] = info;
    notifyListeners();
    return info;
  }

  /// 登录后尽早注册本端设备公钥：使对端创建私密聊天/群聊时服务端可直接预填本端公钥，
  /// 实现「创建即发、无需等对方接受/在线」。注册失败不阻塞（后续握手仍会重试）。
  Future<void> ensureDeviceKeyRegistered() async {
    final deviceId = _local.clientReleaseInstallationId;
    if (deviceId == null || deviceId.isEmpty || myId == null) return;
    try {
      await _e2ee.ensureDeviceKey(deviceId: deviceId);
    } catch (_) {
      // 忽略：网络异常时下次同步/握手重试。
    }
  }

  /// 私密聊天发送文本：AES-GCM 加密 → POST /secret-messages → 本地乐观插入。
  ///
  /// 返回发送结果：`success` 已发送；`waitingForPeer` 对方尚未完成握手（无法建立共享密钥，
  /// 等待对方加入后自动可发）；`failed` 其他错误。
  /// 私密聊天发送消息：AES-GCM 加密载荷 → POST /secret-messages → 本地乐观插入。
  ///
  /// 载荷为 JSON：`{"t":msgType,"c":content,"w":wireContent,"m":[mediaObjectIds]}`，
  /// 服务端只存密文；本地明文仅本机展示。返回发送结果。
  Future<SecretSendResult> sendSecretText({
    required String secretChatId,
    required String text,
    String? deviceId,
    String msgType = 'text',
    String? wireContent,
    List<String>? mediaObjectIds,
    String? replyMsgId,
    String? convPreview,
  }) async {
    if (!_e2ee.hasSharedSecret(secretChatId)) {
      await ensureSecretChatHandshake(secretChatId, deviceId: deviceId);
    }
    final payload = jsonEncode({
      't': msgType,
      'c': text,
      if (wireContent != null) 'w': wireContent,
      if (mediaObjectIds != null && mediaObjectIds.isNotEmpty)
        'm': mediaObjectIds,
      if (replyMsgId != null && replyMsgId.isNotEmpty) 'r': replyMsgId,
    });
    final ciphertext = await _e2ee.encryptForChat(secretChatId, payload);
    final msgId = _newClientMessageId();
    final message = ChatMessage(
      msgId: msgId,
      from: myId ?? 0,
      toId: secretChatId,
      chatType: 'secret',
      msgType: msgType,
      content: text, // 本地明文仅存本机展示；远端仅存密文
      mediaObjectIds: mediaObjectIds,
      replyMsgId: replyMsgId,
      timestamp: DateTime.now().toUtc(),
      status: ciphertext == null ? 'pending' : 'sent',
    );
    if (ciphertext == null) {
      // 本端已提交公钥但对方未提交 → 共享密钥未建立：本地乐观展示 + 入队，握手完成后自动补发。
      _insertLocalSecretMessage(
          'secret', secretChatId, message, convPreview ?? text);
      _enqueuePendingSecretSend(_PendingSecretSend(
        msgId: msgId,
        chatId: secretChatId,
        isGroup: false,
        text: text,
        msgType: msgType,
        wireContent: wireContent,
        mediaObjectIds: mediaObjectIds,
        replyMsgId: replyMsgId,
        convPreview: convPreview,
      ));
      return SecretSendResult.success;
    }

    await _chat.postSecretMessage(
      secretChatId: int.tryParse(secretChatId) ?? 0,
      msgId: msgId,
      ciphertext: ciphertext,
      mediaObjectIds: mediaObjectIds,
    );

    _insertLocalSecretMessage(
        'secret', secretChatId, message, convPreview ?? text);
    return SecretSendResult.success;
  }

  /// 拉取私密消息密文并解密合并到会话。
  ///
  /// 销毁计时只由「已读上报」（本端真正解密看到对方消息后调用
  /// [markSecretMessagesRead]）触发，拉取本身绝不触发——杜绝「消息还没被查阅就销毁」。
  /// 解密失败（密钥未就绪）的消息不推进游标，保留重试，杜绝消息永久丢失。
  ///
  /// 默认从上次已拉取的最大 seq 增量拉取；[forceFull] 为 true 时全量（首次进房用）。
  Future<void> pullSecretMessages(String secretChatId,
      {int? afterSeq, bool forceFull = false}) async {
    if (!_e2ee.hasSharedSecret(secretChatId)) {
      await ensureSecretChatHandshake(secretChatId);
    }
    final cursor =
        afterSeq ?? (forceFull ? 0 : (_secretPulledSeq[secretChatId] ?? 0));
    final wireList = await _chat.listSecretMessages(
      secretChatId: int.tryParse(secretChatId) ?? 0,
      afterSeq: cursor,
      limit: 100,
    );
    if (wireList.isEmpty) return;

    final decrypted = <ChatMessage>[];
    // 游标只推进到「已成功处理」的最大 seq；解密失败的消息卡住游标，下次重试。
    var maxProcessedSeq = cursor;
    // 本端真正解密看到对方消息的最大 seq（已读上报候选）。
    var maxReadSeq = _secretReadReportedSeq[secretChatId] ?? 0;
    for (final wire in wireList) {
      final seq = int.tryParse((wire['seq'] ?? '0').toString()) ?? 0;
      if (seq <= maxProcessedSeq) continue;
      final status = (wire['status'] ?? 'active').toString();
      final msgId = (wire['msgId'] ?? wire['msg_id'] ?? '').toString();
      if (status == 'destroyed' || status == 'recalled') {
        // 服务端已销毁/已撤回：本地同步（recalled=墓碑，destroyed=移除），推进游标。
        _applySecretDestroyState(msgId, status);
        maxProcessedSeq = seq;
        continue;
      }
      final ciphertext = (wire['ciphertext'] ?? '').toString();
      final plain = await _e2ee.decryptFromChat(secretChatId, ciphertext);
      if (plain == null) {
        // 密文无法解密（密钥未就绪/会话未握手完成）：不推进游标、不上报已读，
        // 消息保留在服务端等待密钥就绪后重试，避免「对方收不到且未查阅就销毁」。
        break;
      }
      final from = int.tryParse(
            (wire['fromUserId'] ?? wire['from_user_id'] ?? '0').toString(),
          ) ??
          0;
      // 服务端返回无时区后缀的 UTC 时间串：用 parseUtcDateTime 按 UTC 解析
      // （裸 DateTime.tryParse 会当作本地时间，导致时区差 8 小时、日期错一天）。
      final createdAt =
          parseUtcDateTime(wire['createdAt']) ?? DateTime.now().toUtc();
      // 解密载荷：{"t":msgType,"c":content,"w":wireContent,"m":[mediaObjectIds],"r":replyMsgId}
      // 兼容旧格式（直接加密文本）：非 JSON 时按纯文本 text 处理。
      String resolvedMsgType = 'text';
      String resolvedContent = plain;
      List<dynamic>? resolvedMedia;
      String? resolvedReplyMsgId;
      final decoded = _tryDecodeSecretPayload(plain);
      if (decoded != null) {
        resolvedMsgType = decoded['t'] as String? ?? 'text';
        resolvedContent = decoded['c'] as String? ?? plain;
        resolvedMedia = decoded['m'] as List<dynamic>?;
        final rawReply = decoded['r'];
        if (rawReply is String && rawReply.isNotEmpty) {
          resolvedReplyMsgId = rawReply;
        }
      }
      decrypted.add(ChatMessage(
        msgId: msgId,
        from: from,
        toId: secretChatId,
        chatType: 'secret',
        msgType: resolvedMsgType,
        content: resolvedContent,
        mediaObjectIds: resolvedMedia,
        replyMsgId: resolvedReplyMsgId,
        timestamp: createdAt.toUtc(),
        seq: seq,
        status: 'active',
      ));
      maxProcessedSeq = seq;
      // 只有前台正在查看该私密会话时，解密消息才算真正查阅。
      if (isAppForeground() && currentChatId == secretChatId &&
          currentChatType == 'secret' && from != myId && seq > maxReadSeq) {
        maxReadSeq = seq;
      }
    }
    await _refreshSecretMediaUrls(secretChatId, decrypted);
    _secretPulledSeq[secretChatId] = maxProcessedSeq;
    // 已读上报（服务端权威计时）：本端确实看到对方消息后通知服务端开始倒计时。
    // 未查阅/未解密成功的消息绝不触发（服务端 markRead 也会过滤己方消息）。
    if (maxReadSeq > (_secretReadReportedSeq[secretChatId] ?? 0)) {
      final chatId = int.tryParse(secretChatId) ?? 0;
      unawaited(_chat
          .markSecretMessagesRead(secretChatId: chatId, afterSeq: maxReadSeq)
          .then((_) {
        if (maxReadSeq > (_secretReadReportedSeq[secretChatId] ?? 0)) {
          _secretReadReportedSeq[secretChatId] = maxReadSeq;
        }
      }).catchError((_) {}));
    }
    // 销毁状态增量同步（服务端权威）：销毁计时与执行完全在服务端，端侧只按
    // 服务端返回的 destroyed 标识移除本地消息——在线轮询与离线重连走同一增量，
    // 数据/展示始终与服务端一致，不依赖端侧定时器。
    final syncChatId = int.tryParse(secretChatId) ?? 0;
    final afterDestroy = _secretDestroySyncedAt[secretChatId];
    unawaited(_chat
        .secretChatDestroyStates(
      syncChatId,
      afterDestroyAt: afterDestroy?.toIso8601String(),
    )
        .then((states) {
      DateTime? maxDestroyAt = afterDestroy;
      for (final state in states) {
        final msgId = (state['msgId'] ?? '').toString();
        if (msgId.isEmpty) continue;
        final reason = (state['reason'] ?? '').toString();
        _applySecretDestroyState(msgId, reason);
        final destroyAt = parseUtcDateTime(state['destroyAt']);
        if (destroyAt != null &&
            (maxDestroyAt == null || destroyAt.isAfter(maxDestroyAt))) {
          maxDestroyAt = destroyAt;
        }
      }
      if (maxDestroyAt != null) {
        _secretDestroySyncedAt[secretChatId] = maxDestroyAt;
      }
    }).catchError((_) {
      // 同步失败不阻塞；下次轮询重试。
    }));
    if (decrypted.isEmpty) {
      // 解密失败（共享密钥/对方公钥尚未就绪）：仍要建立会话并重试握手，
      // 避免首条消息时「无会话、无角标」。未读计数留待解密成功后再累加，避免重试重复计数。
      await ensureSecretChatHandshake(secretChatId);
      upsertConversation(secretChatId, 'secret', '', incrementUnread: false);
      notifyListeners();
      return;
    }
    final key = chatKey('secret', secretChatId);
    messageMap.putIfAbsent(key, () => []);
    final list = messageMap[key]!;
    final newlyInserted = <ChatMessage>[];
    for (final message in decrypted) {
      final idx = list.indexWhere((m) => m.msgId == message.msgId);
      if (idx < 0) {
        // 新消息：直接插入。
        insertChatMessageChronologically(list, message);
        newlyInserted.add(message);
      } else {
        // 已存在（发送方乐观插入的本地版本）：用服务端数据补齐 seq，
        // 让消息从「未确认」变为「已确认」（消除发送中状态）。
        final local = list[idx];
        if (local.seq == null && message.seq != null) {
          list[idx] = message;
          newlyInserted.add(message);
        }
      }
    }
    if (newlyInserted.isNotEmpty) {
      unawaited(_local.saveMessages(secretChatId, newlyInserted));
    }
    if (decrypted.isNotEmpty) {
      final latest = decrypted.last; // 按服务端 seq 升序，末条为最新。
      upsertConversation(
        secretChatId,
        'secret',
        conversationPreviewForMessage(latest, viewerId: myId),
        incrementUnread: false,
      );
      // 对方发来的新消息计入未读角标（己方消息只做发送确认，不计未读）。
      final incomingCount = (isAppForeground() && currentChatId == secretChatId &&
              currentChatType == 'secret')
          ? 0
          : newlyInserted.where((m) => m.from != myId).length;
      if (incomingCount > 0) {
        bumpUnread(secretChatId, 'secret', incomingCount);
      }
    }
    notifyListeners();
  }

  /// 重新换取私密消息媒体访问 URL：媒体签名 URL 过期后按消息引用换新鲜 URL，
  /// 让历史图片/视频/语音/文件长期可看（失败不阻塞展示，下次拉取重试）。
  Future<void> _refreshSecretMediaUrls(
    String chatId,
    List<ChatMessage> messages, {
    bool group = false,
  }) async {
    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final objectIds = message.mediaObjectIds
              ?.whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .toList() ??
          const [];
      if (objectIds.isEmpty) continue;
      try {
        final fresh = group
            ? await _chat.resolveSecretGroupMessageMediaUrls(
                secretGroupId: int.tryParse(chatId) ?? 0,
                msgId: message.msgId,
                objectIds: objectIds,
              )
            : await _chat.resolveSecretMessageMediaUrls(
                secretChatId: int.tryParse(chatId) ?? 0,
                msgId: message.msgId,
                objectIds: objectIds,
              );
        if (fresh.isEmpty) continue;
        final freshUrlByObject = <String, String>{
          for (final entry in fresh)
            if (entry['objectId']?.toString().isNotEmpty == true)
              entry['objectId']!.toString(): entry['url']?.toString() ?? '',
        };
        final freshUrl = freshUrlByObject[objectIds.first];
        if (freshUrl == null || freshUrl.isEmpty) continue;
        messages[i] = message.copyWith(
          content: _rewriteMediaContentUrl(
              message.msgType, message.content, freshUrl),
        );
      } catch (_) {
        // 换 URL 失败不阻塞展示；下次拉取重试。
      }
    }
  }

  /// 将媒体消息内容里的过期 URL 替换为新鲜 URL，保留展示元数据（宽高/时长/海报/文件名）。
  String _rewriteMediaContentUrl(
      String msgType, String content, String freshUrl) {
    final trimmed = content.trim();
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          map['url'] = freshUrl;
          return jsonEncode(map);
        }
      } catch (_) {}
    }
    // 纯 URL（视频/语音可能带 ?d=/?w=/?h=/?p= 展示参数）：换签名的同时保留展示参数。
    final old = Uri.tryParse(trimmed);
    final fresh = Uri.tryParse(freshUrl);
    if (old == null || fresh == null) return freshUrl;
    final display = <String, String>{};
    for (final key in const ['d', 'w', 'h', 'p']) {
      final value = old.queryParameters[key];
      if (value != null && value.isNotEmpty) display[key] = value;
    }
    if (display.isEmpty) return freshUrl;
    return fresh.replace(
        queryParameters: {...fresh.queryParameters, ...display}).toString();
  }

  /// 本端视角安全码（与服务端比对一致即握手有效）。
  String? secretSafeCode(String secretChatId) =>
      _e2ee.safeCodeFor(secretChatId);

  /// 会话是否已建立共享密钥（可加解密）。
  bool secretReady(String secretChatId) => _e2ee.hasSharedSecret(secretChatId);

  /// 按服务端销毁原因路由本地动作：recalled → 渲染撤回墓碑；destroyed/deleted →
  /// 移除本地消息（含会话预览）。销毁状态始终以服务端为准，端侧不持有销毁定时器。
  void _applySecretDestroyState(String msgId, String? reason) {
    if (reason == 'recalled') {
      _lifecycle.markMessageRecalled(msgId, content: '消息已撤回');
    } else {
      _lifecycle.applyMessageDeleted(msgId);
    }
  }

  /// 服务端推送的「私密聊天已创建」信号：对方新建私密聊天时本端收到，
  /// 立即同步会话列表并自动完成 E2EE 握手（提交本端公钥），消除首条消息滞后。
  void onSecretChatCreated(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final secretChatId = (map['secretChatId'] ?? '').toString();
    if (secretChatId.isEmpty) return;
    unawaited(syncSecretChatsIntoConversations().catchError((_) {}));
    unawaited(
      ensureSecretChatHandshake(secretChatId).catchError((_) => null),
    );
  }

  /// 服务端推送的「私密消息已存储」轻量信号：仅含 secretChatId 等元数据，无内容。
  /// 在线接收方收到后立即增量拉取密文并解密，实现近似实时触达（对齐普通消息）。
  void onSecretMessageStored(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final secretChatId = (map['secretChatId'] ?? '').toString();
    if (secretChatId.isEmpty) return;
    // 收到信号即增量拉取密文；pullSecretMessages 内部会在未握手时先握手，
    // 不再因 secretReady 早退导致「必须点进聊天才能收到」。
    unawaited(pullSecretMessages(secretChatId).catchError((_) {}));
  }

  /// 服务端主动推送的私密消息销毁事件：按 reason 同步本地（recalled=撤回墓碑，
  /// 其余=移除）。离线端由 states 增量拉取兜底。
  void onSecretMessagesDestroyed(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final secretChatId = (map['secretChatId'] ?? '').toString();
    final rawMsgIds = map['msgIds'];
    if (secretChatId.isEmpty || rawMsgIds is! List || rawMsgIds.isEmpty) return;
    final reason = (map['reason'] ?? '').toString();
    for (final raw in rawMsgIds) {
      final msgId = raw?.toString() ?? '';
      if (msgId.isNotEmpty) {
        _applySecretDestroyState(msgId, reason);
      }
    }
  }

  /// 解析私密消息解密载荷；非本格式（旧版直接加密文本）时返回 null。
  Map<String, dynamic>? _tryDecodeSecretPayload(String plain) {
    if (!plain.startsWith('{') || !plain.endsWith('}')) return null;
    try {
      final decoded = jsonDecode(plain);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  String _newClientMessageId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    return 'sc_${myId ?? 0}_$ts';
  }

  ChatMessage? findMessageInSession(
    String peerId,
    String chatType,
    String? replyMsgId,
  ) {
    if (replyMsgId == null) return null;
    for (final m in messagesFor(peerId, chatType)) {
      if (m.msgId == replyMsgId) return m;
    }
    return null;
  }
}

/// 私密聊天/群聊握手未完成时的待发送项。
class _PendingSecretSend {
  const _PendingSecretSend({
    required this.msgId,
    required this.chatId,
    required this.isGroup,
    required this.text,
    required this.msgType,
    this.wireContent,
    this.mediaObjectIds,
    this.replyMsgId,
    this.convPreview,
    this.atUsers,
  });

  final String msgId;
  final String chatId;
  final bool isGroup;
  final String text;
  final String msgType;
  final String? wireContent;
  final List<String>? mediaObjectIds;
  final String? replyMsgId;
  final String? convPreview;
  final List<dynamic>? atUsers;
}

/// 私密消息发送结果。
enum SecretSendResult {
  /// 已加密并提交服务端。
  success,

  /// 对方尚未完成 E2EE 握手（无法建立共享密钥），等待对方加入后自动可发。
  waitingForPeer,

  /// 其他错误（网络/服务端异常）。
  failed,
}
