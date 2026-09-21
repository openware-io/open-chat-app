import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/app_lifecycle_observer.dart';
import '../core/config.dart';
import '../core/local_storage.dart';
import '../models/client_remote_settings.dart';
import '../models/shared_media_item.dart';
import '../providers/app_locale_provider.dart';
import '../providers/app_theme_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/call_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/client_remote_config_provider.dart';
import '../providers/client_release_coordinator.dart';
import '../providers/currency_provider.dart';
import '../providers/friend_provider.dart';
import '../providers/group_provider.dart';
import '../providers/mini_app_services_provider.dart';
import '../providers/pending_approval_provider.dart';
import '../repositories/business/ktv_api_client.dart';
import '../repositories/client_release_repository.dart';
import '../repositories/favorite_repository.dart';
import '../services/api_client.dart';
import '../services/im_api.dart';
import '../services/message_notification_sound_service.dart';
import '../services/push_notification_service.dart';
import '../services/share_intent_service.dart';
import '../services/socket_service.dart';
import 'app_routes.dart';
import 'app_service_locator.dart';

class AppDependencies {
  AppDependencies._({
    required this.storage,
    required this.appLocale,
    required this.appThemeMode,
    required this.currency,
    required this.apiClient,
    required this.imApi,
    required this.socket,
    required this.auth,
    required this.friend,
    required this.group,
    required this.chat,
    required this.call,
    required this.remoteConfig,
    required this.miniAppServices,
    required this.favoriteRepository,
    required this.ktvApiClient,
    required this.pendingApproval,
    required this.clientReleaseRepository,
    required this.clientReleaseCoordinator,
    required this.pushService,
    required this.messageNotificationSound,
    required this.shareService,
    required this.router,
    required this.lifecycleObserver,
  });

  final LocalStorage storage;
  final AppLocaleController appLocale;
  final AppThemeModeController appThemeMode;
  final CurrencyController currency;
  final ApiClient apiClient;
  final ImApi imApi;
  final SocketService socket;
  final AuthProvider auth;
  final FriendProvider friend;
  final GroupProvider group;
  final ChatProvider chat;
  final CallProvider call;
  final ClientRemoteConfigProvider remoteConfig;
  final MiniAppServicesProvider miniAppServices;
  final FavoriteRepository favoriteRepository;
  final KtvApiClient ktvApiClient;

  /// 客户「待确认加项」全局提醒（角标 / 横幅 / 处理页共用同一份快照）。
  final PendingApprovalController pendingApproval;
  final ClientReleaseRepository clientReleaseRepository;
  final ClientReleaseCoordinator clientReleaseCoordinator;
  final PushNotificationService pushService;
  final MessageNotificationSoundService messageNotificationSound;
  final ShareIntentService shareService;
  final GoRouter router;
  final AppLifecycleObserver lifecycleObserver;
  bool _handlingUnauthorized = false;
  int _lastBadgeUnread = -1;

  /// 本地未读总数变化时，同步极光 App 图标角标（绝对未读总数，不清零）。
  void _syncBadgeToPush() {
    final total = chat.totalUnread;
    if (total == _lastBadgeUnread) return;
    _lastBadgeUnread = total;
    unawaited(pushService.setBadge(total));
  }

  static Future<AppDependencies> create({GetIt? serviceLocator}) async {
    final locator = serviceLocator ?? gvServiceLocator;
    await locator.reset();
    await configureAppServiceLocator(locator);

    // B 端 KTV 客户端手动注册，避免依赖 injectable 代码生成（不改动
    // app_service_locator.config.dart）；随本地存储懒加载。
    //
    // 全局租户币种（规范 §3.4）：启动先用本地快照兜底（缺省 USD），
    // 之后由 KtvApiClient 拦截器从响应 currencyCode / X-Currency 刷新，
    // 业务屏统一通过 CurrencyController 跟随。
    final currency = CurrencyController(storage: locator<LocalStorage>());
    currency.hydrate();
    locator.registerSingleton<CurrencyController>(currency);

    locator.registerLazySingleton<KtvApiClient>(
      () => KtvApiClient(
        storage: locator<LocalStorage>(),
        onCurrencyResolved: currency.apply,
      ),
    );

    // 客户待确认加项：单一数据源（/business/orders/pending-approval）+ 15s 轮询，
    // 由 A380 收银端各页共用；不随登录态自动启动，进入工作台时 start()。
    final pendingApproval = PendingApprovalController(locator<KtvApiClient>());
    locator.registerSingleton<PendingApprovalController>(pendingApproval);

    final dependencies = AppDependencies._(
      storage: locator<LocalStorage>(),
      appLocale: locator<AppLocaleController>(),
      appThemeMode: locator<AppThemeModeController>(),
      currency: locator<CurrencyController>(),
      apiClient: locator<ApiClient>(),
      imApi: locator<ImApi>(),
      socket: locator<SocketService>(),
      auth: locator<AuthProvider>(),
      friend: locator<FriendProvider>(),
      group: locator<GroupProvider>(),
      chat: locator<ChatProvider>(),
      call: locator<CallProvider>(),
      remoteConfig: locator<ClientRemoteConfigProvider>(),
      miniAppServices: locator<MiniAppServicesProvider>(),
      favoriteRepository: locator<FavoriteRepository>(),
      ktvApiClient: locator<KtvApiClient>(),
      pendingApproval: locator<PendingApprovalController>(),
      clientReleaseRepository: locator<ClientReleaseRepository>(),
      clientReleaseCoordinator: locator<ClientReleaseCoordinator>(),
      pushService: locator<PushNotificationService>(),
      messageNotificationSound: locator<MessageNotificationSoundService>(),
      shareService: ShareIntentService(),
      router: locator<GoRouter>(),
      lifecycleObserver: locator<AppLifecycleObserver>(),
    );
    locator.registerSingleton<AppDependencies>(dependencies);

    await dependencies.initialize();
    return dependencies;
  }

  List<SingleChildWidget> get providers => [
        ChangeNotifierProvider<AppLocaleController>.value(value: appLocale),
        ChangeNotifierProvider<AppThemeModeController>.value(
          value: appThemeMode,
        ),
        ChangeNotifierProvider<CurrencyController>.value(value: currency),
        Provider<LocalStorage>.value(value: storage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<ImApi>.value(value: imApi),
        Provider<SocketService>.value(value: socket),
        ChangeNotifierProvider<PushNotificationService>.value(
          value: pushService,
        ),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<FriendProvider>.value(value: friend),
        ChangeNotifierProvider<GroupProvider>.value(value: group),
        ChangeNotifierProvider<ChatProvider>.value(value: chat),
        ChangeNotifierProvider<CallProvider>.value(value: call),
        ChangeNotifierProvider<ClientRemoteConfigProvider>.value(
          value: remoteConfig,
        ),
        ChangeNotifierProvider<MiniAppServicesProvider>.value(
          value: miniAppServices,
        ),
        Provider<FavoriteRepository>.value(value: favoriteRepository),
        Provider<KtvApiClient>.value(value: ktvApiClient),
        ChangeNotifierProvider<PendingApprovalController>.value(
          value: pendingApproval,
        ),
        Provider<ClientReleaseRepository>.value(value: clientReleaseRepository),
        ChangeNotifierProvider<ClientReleaseCoordinator>.value(
          value: clientReleaseCoordinator,
        ),
      ];

  Future<void> initialize() async {
    await clientReleaseCoordinator.checkOnLaunch();
    call.onOutgoingCallEndedTrace = chat.sendCallTraceMessage;
    call.applyClientRtc(ClientRemoteSettings.defaults.rtc);
    call.isAppForeground = () => lifecycleObserver.isForeground;
    lifecycleObserver.onBackgrounded = () {
      call.handleAppBackgrounded();
      friend.stopPendingRequestPolling();
      // 收银端在后台不再轮询待确认加项；回前台立即补拉（见 onResumed）。
      pendingApproval.setForeground(false);
    };
    lifecycleObserver.onResumed = () async {
      await pushService.cancelAllRealtimeCallNotifications();
      await chat.synchronizeMessages();
      friend.startPendingRequestPolling();
      pendingApproval.setForeground(true);
      _syncBadgeToPush();
    };
    lifecycleObserver.activeConversationId = () => chat.currentChatId;
    chat.isAppForeground = () => lifecycleObserver.isForeground;
    chat.addListener(_syncBadgeToPush);
    friend.onFriendAccepted = chat.restoreFriendConversation;
    pushService.onChatNotificationOpened = chat.synchronizeMessages;
    pushService.isConversationMuted = chat.isConversationMuted;
    // 来电邀请离线推送：点击通知后拉起 App 内接听界面。
    pushService.onCallInviteOpened = (data) {
      final callId = data['callId'];
      final fromUserId = data['fromUserId'];
      if (callId == null ||
          callId.isEmpty ||
          fromUserId == null ||
          int.tryParse(fromUserId) == null) {
        return;
      }
      call.onIncomingCall({
        'callId': callId,
        'fromUserId': fromUserId,
        'mediaType': data['mediaType'] ?? 'video',
        if (data['fromUsername']?.isNotEmpty == true)
          'fromUsername': data['fromUsername'],
        if (data['fromAvatar']?.isNotEmpty == true)
          'fromAvatar': data['fromAvatar'],
      }, showBanner: false);
      // A delayed invite for a different call must not open the active call.
      if (call.callId != callId || !call.inCall) return;
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      if (currentPath != AppRoutes.call) {
        router.push(AppRoutes.call);
      }
    };

    // 系统「分享」进 App：热启动直接打开「发送给」；冷启动内容由 main 首帧后补投。
    shareService.onSharedMediaReceived = (items) => _openSharedMedia(items);
    await shareService.init();

    auth.onAuthenticatedChanged = () {
      unawaited(_handleAuthenticatedChanged());
    };

    auth.onLogoutMemoryClear = () async {
      pushService.deactivateForLogout();
      call.onOutgoingCallEndedTrace = null;
      await call.reset();
      chat.resetForLogout();
      friend.resetForLogout();
      group.resetForLogout();
      miniAppServices.resetForLogout();
      pendingApproval.reset();
      call.clearIcePrefetch();
    };

    apiClient.onUnauthorized = () async {
      if (_handlingUnauthorized) return;
      _handlingUnauthorized = true;
      try {
        pushService.deactivateForLogout();
        await auth.logout();
      } finally {
        _handlingUnauthorized = false;
      }
    };

    await auth.hydrateFromDisk();
    if (auth.isLoggedIn && lifecycleObserver.isForeground) {
      friend.startPendingRequestPolling();
    }
    await _validateApiBaseForLoggedInSession();
    if (auth.isLoggedIn) {
      await auth.refreshProfileSafely();
    }
    await chat.hydrateFromDisk();

    _bindSocketCallbacks();
    lifecycleObserver.register();

    auth.initSocketIfNeeded();
    if (auth.isLoggedIn) {
      await _syncRemoteConfigFromServer();
      if (auth.isLoggedIn) {
        unawaited(pushService.activateForAuthenticatedUser());
      }
    }
  }

  void _openSharedMedia(List<SharedMediaItem> items) {
    if (items.isEmpty) return;
    router.push('/share-media', extra: items);
  }

  /// 冷启动分享：main 首帧后调用，把排队中的分享内容带进「发送给」页。
  void openPendingSharedMedia() {
    final items = shareService.pending;
    if (items == null || items.isEmpty) return;
    shareService.clear();
    _openSharedMedia(items);
  }

  Future<void> _handleAuthenticatedChanged() async {
    if (!auth.isLoggedIn) {
      friend.stopPendingRequestPolling();
      pushService.deactivateForLogout();
      await _syncRemoteConfigFromServer();
      return;
    }

    await chat.hydrateFromDisk();
    if (lifecycleObserver.isForeground) {
      friend.startPendingRequestPolling();
    }
    await _syncRemoteConfigFromServer();
    if (!auth.isLoggedIn) return;
    await pushService.activateForAuthenticatedUser();
  }

  Future<void> _validateApiBaseForLoggedInSession() async {
    if (!auth.isLoggedIn) return;
    final savedBase = storage.apiBaseAtLogin;
    if (savedBase == null || savedBase.isEmpty) {
      await storage.setApiBaseAtLogin(AppConfig.apiBase);
    } else if (savedBase != AppConfig.apiBase) {
      await auth.logout();
    }
  }

  Future<void> _syncRemoteConfigFromServer() async {
    if (!auth.isLoggedIn) {
      remoteConfig.resetToDefaults();
      chat.setReadReceiptEnabled(true);
      call.applyClientRtc(ClientRemoteSettings.defaults.rtc);
      return;
    }
    await remoteConfig.refresh();
    if (!auth.isLoggedIn) return;
    chat.setReadReceiptEnabled(
        remoteConfig.settings.feature.readReceiptEnabled);
    chat.bindRemoteConfig(remoteConfig);
    call.applyClientRtc(remoteConfig.settings.rtc);
  }

  Future<void> _refreshGroupStateAfterNotify({
    required int? groupId,
    required bool refreshCurrentMembers,
  }) async {
    if (groupId == null) {
      await group.loadGroups();
      if (chat.applyDisplayNamesFromContactProviders()) {
        chat.saveConversations();
      }
      return;
    }

    await group.refreshAfterMembershipChanged(
      groupId,
      refreshCurrentMembers: refreshCurrentMembers,
    );
    if (!refreshCurrentMembers ||
        !group.groups.any((item) => item.id == groupId)) {
      return;
    }
    chat.updateConversationDisplay(
      '$groupId',
      'group',
      name: group.getGroupDisplayName(groupId),
    );
  }

  void _bindSocketCallbacks() {
    socket.onConnected = () {
      chat.retryPendingMessages();
      unawaited(chat.synchronizeMessages());
      unawaited(friend.refreshPendingRequestsSafely());
    };
    socket.onChatReceive = (data) {
      final receivedIncoming = chat.onMessageReceived(data);
      if (receivedIncoming &&
          lifecycleObserver.isForeground &&
          pushService.notificationsEnabled &&
          !call.inCall) {
        unawaited(messageNotificationSound.play());
      }
      if (receivedIncoming && !lifecycleObserver.isForeground) {
        unawaited(
          pushService.showRealtimeMessageNotifications(
            data,
            currentUserId: chat.myId,
          ),
        );
      }
    };
    socket.onChatAck = chat.onMessageAck;
    socket.onReadNotify = chat.onReadNotify;
    socket.onRecallNotify = chat.onRecallNotify;
    socket.onMessageDeletedNotify = chat.onMessageDeletedNotify;
    socket.onMessageEditedNotify = chat.onMessageEditedNotify;
    socket.onChatSecretDestroyed = chat.onSecretMessagesDestroyed;
    socket.onChatSecretStored = chat.onSecretMessageStored;
    socket.onChatSecretCreated = chat.onSecretChatCreated;
    socket.onChatSecretDeleted = chat.onSecretChatDeleted;
    socket.onChatSecretGroupStored = chat.onSecretGroupStored;
    socket.onTyping = chat.onTyping;
    socket.onUserStatusChange = friend.onStatusChange;
    socket.onFriendRequestNotify = (data) {
      friend.onFriendRequestNotify(data);
      unawaited(
        pushService.showFriendRequestNotification(
          data,
          isForeground: lifecycleObserver.isForeground,
        ),
      );
    };
    socket.onFriendAcceptNotify = (data) {
      friend.onFriendAcceptNotify(data);
      unawaited(
        pushService.showFriendAcceptedNotification(
          data,
          isForeground: lifecycleObserver.isForeground,
        ),
      );
    };
    socket.onClearPrivateChatNotify = chat.onClearPrivateChatNotify;
    socket.onClearGroupChatNotify = chat.onClearGroupChatNotify;
    socket.onGroupDissolveNotify = (data) {
      final groupId = group.tryParseDissolveNotifyGroupId(data);
      unawaited(group.loadGroups().catchError((_, __) {}));
      if (groupId == null) return;
      final id = '$groupId';
      chat.markGroupDissolved(id);
    };
    socket.onGroupNotify = (data) {
      final map = data is Map
          ? Map<String, dynamic>.from(data)
          : const <String, dynamic>{};
      final groupId = group.tryParseDissolveNotifyGroupId(map);
      final changeType =
          (map['changeType'] ?? map['change_type'])?.toString().toUpperCase();
      final affectedUserId = int.tryParse(
        '${map['affectedUserId'] ?? map['affected_user_id'] ?? ''}',
      );
      final isSelfAffected =
          affectedUserId != null && affectedUserId == chat.myId;
      // 群解散：**保留会话与聊天记录**，只把输入框置为只读（参考微信）。
      // 此前这里把 GROUP_DISSOLVED 也当成“自己不再是成员”，直接 removeConversation +
      // closeChatIfCurrent，把聊天记录一并删掉了 —— 与 chat_room_screen 里
      // isGroupDissolved 驱动的「群聊已解散，不能继续发消息」只读逻辑互相冲突，
      // 表现为“解散后会话直接消失 / 记录看不到”。
      final dissolved = changeType == 'GROUP_DISSOLVED';
      final selfRemovedFromGroup = isSelfAffected &&
          (changeType == 'MEMBER_LEFT' || changeType == 'MEMBER_REMOVED');
      final selfNoLongerMember = dissolved || selfRemovedFromGroup;
      if (groupId != null) {
        final id = '$groupId';
        if (dissolved) {
          chat.markGroupDissolved(id);
        } else if (selfRemovedFromGroup) {
          chat.removeConversation(id, 'group');
          chat.closeChatIfCurrent(id, 'group');
        }
      }
      unawaited(
        _refreshGroupStateAfterNotify(
          groupId: groupId,
          refreshCurrentMembers: !selfNoLongerMember,
        ).catchError((Object error, StackTrace stackTrace) {
          debugPrint(
            'Failed to refresh group state after notification: '
            '$error\n$stackTrace',
          );
        }),
      );
    };
    socket.onRtcSignal = (data) {
      unawaited(call.onSignal(data));
      if (data is! Map) return;
      final signal = Map<String, dynamic>.from(data);
      final action = signal['action']?.toString().trim().toLowerCase();
      final callId = signal['callId']?.toString();
      if (action == 'call' && !lifecycleObserver.isForeground) {
        unawaited(pushService.showRealtimeCallNotification(signal));
        return;
      }
      if (const {
        'hangup',
        'reject',
        'busy',
        'incoming_resolved',
        'call_failed',
      }.contains(action)) {
        unawaited(pushService.cancelRealtimeCallNotification(callId));
      }
    };
    socket.onError = chat.onWsError;
  }
}
