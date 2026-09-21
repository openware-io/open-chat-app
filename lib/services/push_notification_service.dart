import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:jpush_flutter/jpush_flutter.dart';
import 'package:jpush_flutter/jpush_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';

import '../app/app_routes.dart';
import '../core/config.dart';
import '../core/gv_chat_navigation.dart';
import '../core/gv_root_navigator.dart';
import '../l10n/app_localizations.dart';
import '../models/chat_message.dart';
import '../repositories/app_preferences_repository.dart';
import 'im_api.dart';

const String _pushApnsChannelName = 'com.gv.chat/push_apns';
const String _messageKeepAliveChannelName = 'com.gv.chat/message_keep_alive';

/// 从推送载荷按键列表取首个非空值（大小写不敏感），纯函数便于单测。
String? pushValueFor(Map<String, String> data, Iterable<String> keys) {
  final lower = <String, String>{};
  for (final entry in data.entries) {
    final value = entry.value.trim();
    if (value.isNotEmpty) lower[entry.key.toLowerCase()] = value;
  }
  for (final key in keys) {
    final value = data[key]?.trim();
    if (value != null && value.isNotEmpty) return value;
    final lowerValue = lower[key.toLowerCase()];
    if (lowerValue != null && lowerValue.isNotEmpty) return lowerValue;
  }
  return null;
}

/// Call invites must be classified before ordinary chat target normalization.
/// A call may also carry a private conversationId/peerId for its chat history.
Map<String, String>? normalizeCallInvitePayload(Map<String, String> data) {
  final kind =
      pushValueFor(data, const ['notificationType', 'notification_type']);
  final chatType = pushValueFor(data, const ['chatType', 'chat_type']);
  if (kind?.toLowerCase() != 'call' && chatType?.toLowerCase() != 'call') {
    return null;
  }
  final result = <String, String>{...data, 'chatType': 'call'};
  const aliases = {
    'callId': ['callId', 'call_id'],
    'fromUserId': ['fromUserId', 'from_user_id', 'senderId', 'sender_id'],
    'mediaType': ['mediaType', 'media_type'],
    'fromUsername': ['fromUsername', 'from_username'],
    'fromAvatar': ['fromAvatar', 'from_avatar'],
  };
  for (final entry in aliases.entries) {
    final value = pushValueFor(data, entry.value);
    if (value != null) result[entry.key] = value;
  }
  return result;
}

/// 从推送载荷解析聊天对端 peerId（纯函数便于单测）。
///
/// 注意：推送 extras 的 conversationId 是**归一化会话标识**（如
/// `conv:private:17:32`），不能直接当 peerId（int.tryParse 失败会触发
/// 「不是好友/群解散」误报）。私聊时对接收方而言对方是发送方（fromUserId），
/// 因此私聊优先取 fromUserId，conversationId 仅作最后兜底提取末尾数字 id。
String? resolveChatTargetPeerId(Map<String, String> data, String? chatType) {
  var peerId =
      pushValueFor(data, const ['peerId', 'peer_id', 'targetId', 'target_id']);
  if (chatType == 'private' && (peerId == null || peerId.isEmpty)) {
    peerId = pushValueFor(data, const [
      'fromUserId',
      'from_user_id',
      'fromId',
      'from_id',
      'senderId',
      'sender_id',
      'from',
    ]);
  }
  if (peerId == null || peerId.isEmpty) {
    peerId = pushValueFor(data, const ['toId', 'to_id']);
  }
  if (peerId == null || peerId.isEmpty) {
    final convId =
        pushValueFor(data, const ['conversationId', 'conversation_id']);
    if (convId != null && convId.isNotEmpty) {
      final segments = convId.split(':');
      final last = segments.isNotEmpty ? segments.last : '';
      if (last.isNotEmpty && int.tryParse(last) != null) peerId = last;
    }
  }
  return peerId;
}

/// Android 后台 WebSocket 消息转换出的本地系统通知。
///
/// 该结构只承载通知展示与点击导航所需字段，避免把实时消息的动态 Map
/// 继续传入应用内部。
@immutable
class RealtimeChatNotification {
  const RealtimeChatNotification({
    required this.title,
    required this.body,
    required this.payload,
    required this.msgId,
  });

  final String title;
  final String body;
  final Map<String, String> payload;
  final String msgId;
}

/// 将单条或 batch `chat:receive` 载荷转换为可展示的本地通知。
///
/// 纯函数供 Socket 接线与回归测试共用；自己其它设备同步回来的消息不会通知。
List<RealtimeChatNotification> realtimeChatNotificationsFrom(
  dynamic raw, {
  required int? currentUserId,
  required String fallbackTitle,
  required String fallbackBody,
}) {
  if (raw is! Map) return const <RealtimeChatNotification>[];
  final root = Map<String, dynamic>.from(raw);
  final candidates = root['type'] == 'batch' && root['messages'] is List
      ? List<dynamic>.from(root['messages'] as List)
      : <dynamic>[root];
  final notifications = <RealtimeChatNotification>[];

  for (final candidate in candidates) {
    if (candidate is! Map) continue;
    try {
      final message =
          ChatMessage.fromJson(Map<String, dynamic>.from(candidate));
      if (currentUserId != null && message.from == currentUserId) continue;

      final peerId = message.chatType == 'private'
          ? '${message.from}'
          : message.toId.trim();
      if (peerId.isEmpty || message.msgId.trim().isEmpty) continue;

      final senderName = message.fromUsername?.trim();
      final text =
          message.msgType.toLowerCase() == 'text' ? message.content.trim() : '';
      notifications.add(
        RealtimeChatNotification(
          title: senderName == null || senderName.isEmpty
              ? fallbackTitle
              : senderName,
          body: text.isEmpty ? fallbackBody : _truncateNotificationText(text),
          msgId: message.msgId,
          payload: <String, String>{
            'notificationType': 'chat',
            'chatType': message.chatType,
            'peerId': peerId,
            'msgId': message.msgId,
            'fromUserId': '${message.from}',
          },
        ),
      );
    } catch (_) {
      // 单条格式异常不应阻断同一 batch 内其它有效消息的通知。
    }
  }
  return notifications;
}

String _truncateNotificationText(String value) {
  const maxLength = 240;
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength)}…';
}

class PushNotificationService extends ChangeNotifier {
  PushNotificationService(this._api, this._preferences);

  final ImApi _api;
  final AppPreferencesRepository _preferences;
  Future<void> Function()? onChatNotificationOpened;
  void Function(Map<String, String> data)? onCallInviteOpened;

  /// 会话是否已免打扰（由外层注入，供通知派发处跳过提醒）。
  bool Function(String peerId, String chatType)? isConversationMuted;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  String? _currentToken;
  String? _registeredServerToken;
  Future<void>? _serverRegistrationFuture;

  JPushFlutterInterface? _jpush;
  Future<bool>? _initFuture;
  bool _localNotificationsInitialized = false;
  bool _fullScreenIntentPermissionRequested = false;
  bool _authenticatedForPush = false;
  Map<String, String>? _pendingNavigationPayload;
  bool _navigationFlushScheduled = false;
  int _navigationFlushAttempts = 0;
  String? _lastNavigationKey;
  DateTime? _lastNavigationAt;
  final Set<String> _shownRealtimeMessageIds = <String>{};
  final Set<String> _shownRealtimeCallIds = <String>{};
  final Set<String> _shownFriendNotificationIds = <String>{};

  static const _androidChannel = AndroidNotificationChannel(
    'chat_messages',
    'Chat messages',
    description: 'New messages from private and group chats',
    importance: Importance.high,
  );

  static const _androidIncomingCallChannel = AndroidNotificationChannel(
    'incoming_calls',
    'Incoming calls',
    description: 'Incoming voice and video calls',
    importance: Importance.max,
  );

  static const MethodChannel _iosApnsChannel =
      MethodChannel(_pushApnsChannelName);
  static const MethodChannel _messageKeepAliveChannel =
      MethodChannel(_messageKeepAliveChannelName);

  String? get currentToken => _currentToken;

  String get pushProvider => 'jpush';

  bool get notificationsEnabled => _preferences.notificationsEnabled;

  bool get notificationsSupported => !kIsWeb && !_isDesktop;

  bool get _usesJPush => !Platform.isAndroid || AppConfig.androidJPushEnabled;

  Future<bool> init() async {
    if (!notificationsSupported || !notificationsEnabled) return false;
    if (_localNotificationsInitialized && !_usesJPush) return true;
    if (_jpush != null) return true;

    final existing = _initFuture;
    if (existing != null) return existing;

    final future = _initAfterPermission();
    _initFuture = future;
    try {
      return await future;
    } finally {
      _initFuture = null;
    }
  }

  Future<bool> _initAfterPermission() async {
    if (!notificationsEnabled) return false;
    if (!await _ensureNotificationPermission()) return false;
    if (!notificationsEnabled) return false;

    await _initLocalNotifications();
    await _syncAndroidKeepAlive();
    if (Platform.isIOS) {
      await _listenIosApnsChannelFallback();
    }
    if (!_usesJPush) {
      debugPrint(
        '[Push] Android realtime notification fallback enabled; '
        'JPush initialization skipped',
      );
      return true;
    }
    await _initJPush();
    if (!notificationsEnabled) {
      await _stopJPush();
      return false;
    }
    await _refreshJPushRegistrationId();
    return _jpush != null;
  }

  Future<bool> _ensureNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!_isPushPermissionAllowed(status)) {
      status = await Permission.notification.request();
    }
    if (_isPushPermissionAllowed(status)) return true;

    debugPrint('[Push] Notification permission not granted: $status');
    return false;
  }

  bool _isPushPermissionAllowed(PermissionStatus status) {
    return status.isGranted || status.isLimited || status.isProvisional;
  }

  Future<void> activateForAuthenticatedUser() async {
    _authenticatedForPush = true;
    if (!notificationsEnabled) return;
    if (!await init()) return;
    await _resumeJPush();
    await registerToken();
    await _syncAndroidKeepAlive();
  }

  void deactivateForLogout() {
    _authenticatedForPush = false;
    _registeredServerToken = null;
    unawaited(_syncAndroidKeepAlive());
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (notificationsEnabled == enabled) return;

    await _preferences.setNotificationsEnabled(enabled);
    notifyListeners();
    await _syncAndroidKeepAlive();

    if (enabled) {
      if (!_authenticatedForPush || !await init()) return;
      await _resumeJPush();
      await registerToken();
      return;
    }

    final registration = _serverRegistrationFuture;
    if (registration != null) await registration;
    await unregisterToken();
    await _stopJPush();
  }

  Future<void> registerToken() async {
    final existing = _serverRegistrationFuture;
    if (existing != null) {
      await existing;
      return;
    }

    final future = _registerTokenOnce();
    _serverRegistrationFuture = future;
    try {
      await future;
    } finally {
      if (identical(_serverRegistrationFuture, future)) {
        _serverRegistrationFuture = null;
      }
    }
  }

  Future<void> _registerTokenOnce() async {
    if (!_canRegisterToken) return;
    if (!await init()) return;
    if (!_canRegisterToken) return;
    if (_currentToken == null || _currentToken!.isEmpty) {
      await _refreshJPushRegistrationId();
    }
    if (!_canRegisterToken) return;
    if (_currentToken == null || _currentToken!.isEmpty) return;
    if (_registeredServerToken == _currentToken) return;

    try {
      await _api.registerDeviceToken(
        token: _currentToken!,
        platform: _platformString,
        pushProvider: pushProvider,
        deviceId: _deviceId,
      );
      _registeredServerToken = _currentToken;
      debugPrint('[Push] Token registered on server ($pushProvider)');
      await _syncAndroidKeepAlive();
    } catch (e) {
      debugPrint('[Push] Token register failed: $e');
    }
  }

  Future<void> unregisterToken() async {
    if (_currentToken == null || _currentToken!.isEmpty) return;
    try {
      await _api.removeDeviceToken(_currentToken!, pushProvider: pushProvider);
      if (_registeredServerToken == _currentToken) {
        _registeredServerToken = null;
      }
      debugPrint('[Push] Token unregistered ($pushProvider)');
    } catch (e) {
      debugPrint('[Push] Token unregister failed: $e');
    }
  }

  Future<void> _initJPush() async {
    final jpush = JPush.newJPush();
    _jpush = jpush;

    const appKey = AppConfig.jpushDartAppKey;
    if (appKey.isEmpty && Platform.isIOS) {
      debugPrint(
          '[Push] GV_JPUSH_APPKEY is empty; JPush cannot receive pushes.');
    }

    jpush.addEventHandler(
      onReceiveNotification: (Map<String, dynamic> event) async {
        if (!notificationsEnabled || !Platform.isAndroid) return;
        final title = _jpushTitle(event);
        final body = _jpushBody(event);
        final data = _jpushFlattenedPayload(event);
        if (title == null || body == null || title.isEmpty || body.isEmpty) {
          return;
        }

        // 单会话免打扰：命中 muted 会话时不弹系统通知（角标/列表仍正常累计）。
        final muted = isConversationMuted;
        if (muted != null) {
          final chatType = data['chatType'];
          final peerId = data['peerId'];
          if (chatType != null &&
              peerId != null &&
              peerId.isNotEmpty &&
              muted(peerId, chatType)) {
            return;
          }
        }

        await _local.show(
          id: Object.hash(title, body, data['msgId']).abs(),
          title: title,
          body: body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: _encodePayload(data),
        );
      },
      onOpenNotification: (Map<String, dynamic> event) async {
        if (!notificationsEnabled) return;
        await _clearNotificationBadgeAndTray();
        _navigateFromJPushEvent(event);
      },
      onConnected: (Map<String, dynamic> event) async {
        if (!notificationsEnabled) {
          await _stopJPush();
          return;
        }
        await _refreshJPushRegistrationId(forceRegisterIfNew: true);
        if (_canRegisterToken) {
          await registerToken();
        }
      },
      onReceiveDeviceToken: (Map<String, dynamic> event) async {
        debugPrint('[Push] iOS APNs device token received by JPush');
      },
      onReceiveNotificationAuthorization: (Map<String, dynamic> event) async {
        debugPrint('[Push] Notification authorization: $event');
      },
      onCommandResult: (Map<String, dynamic> event) async {},
    );

    jpush.setup(
      appKey: appKey,
      channel: 'developer-default',
      production: AppConfig.jpushProductionDart,
      debug: kDebugMode,
    );

    if (Platform.isIOS) {
      jpush.applyPushAuthority(
        const NotificationSettingsIOS(sound: true, alert: true, badge: true),
      );
      return;
    }

    if (Platform.isAndroid) {
      jpush.requestRequiredPermission();
      try {
        jpush.setChannelAndSound(
          channel: _androidChannel.name,
          channelID: _androidChannel.id,
          sound: 'default',
        );
      } catch (e, st) {
        debugPrint('[Push] JPush setChannelAndSound: $e\n$st');
      }
    }
  }

  bool get _canRegisterToken =>
      _usesJPush && _authenticatedForPush && notificationsEnabled;

  Future<void> _resumeJPush() async {
    final jpush = _jpush;
    if (jpush == null || !notificationsEnabled) return;
    try {
      await jpush.resumePush();
    } catch (e, st) {
      debugPrint('[Push] JPush resume failed: $e\n$st');
    }
  }

  Future<void> _stopJPush() async {
    final jpush = _jpush;
    if (jpush == null) return;
    try {
      await jpush.stopPush();
    } catch (e, st) {
      debugPrint('[Push] JPush stop failed: $e\n$st');
    }
    await _clearNotificationBadgeAndTray();
  }

  /// 同步 App 图标角标为服务端/本地权威的绝对未读总数。
  Future<void> setBadge(int count) async {
    final jpush = _jpush;
    if (jpush == null) return;
    final value = count < 0 ? 0 : count;
    try {
      await jpush.setBadge(value);
    } catch (e, st) {
      debugPrint('[Push] JPush setBadge($value) failed: $e\n$st');
    }
  }

  Future<void> _clearNotificationBadgeAndTray() async {
    final jpush = _jpush;
    if (jpush != null) {
      try {
        await jpush.setBadge(0);
      } catch (e, st) {
        debugPrint('[Push] JPush badge reset failed: $e\n$st');
      }
      try {
        await jpush.clearAllNotifications();
      } catch (e, st) {
        debugPrint('[Push] JPush notification clear failed: $e\n$st');
      }
    }

    if (_localNotificationsInitialized) {
      try {
        await _local.cancelAll();
      } catch (e, st) {
        debugPrint('[Push] Local notification clear failed: $e\n$st');
      }
    }
  }

  /// Android 临时保活模式下，使用仍存活的 WebSocket 事件展示系统通知。
  ///
  /// 只在 App 后台由调用方触发；启用 Android 极光构建开关后自动停用，防止
  /// 本地通知和极光系统通知重复展示。
  Future<void> showRealtimeMessageNotifications(
    dynamic raw, {
    required int? currentUserId,
  }) async {
    if (!_canShowAndroidRealtimeFallback) return;
    final l10n = _currentLocalizations;
    if (l10n == null) return;

    final notifications = realtimeChatNotificationsFrom(
      raw,
      currentUserId: currentUserId,
      fallbackTitle: l10n.bannerNewMessage,
      fallbackBody: l10n.bannerNewMessage,
    );
    for (final notification in notifications) {
      final muted = isConversationMuted;
      if (muted != null &&
          muted(
            notification.payload['peerId']!,
            notification.payload['chatType']!,
          )) {
        continue;
      }
      if (!_shownRealtimeMessageIds.add(notification.msgId)) continue;
      _trimRecentIds(_shownRealtimeMessageIds);
      try {
        await _local.show(
          id: notification.msgId.hashCode & 0x7fffffff,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: _encodePayload(notification.payload),
        );
      } catch (error, stackTrace) {
        debugPrint(
          '[Push] Realtime message notification failed: '
          '$error\n$stackTrace',
        );
      }
    }
  }

  /// 好友关系事件提醒。前台通过本地通知明确提示，后台仅在没有 JPush
  /// 兜底时展示，避免 WebSocket 与离线推送重复弹窗。
  Future<void> showFriendRequestNotification(
    dynamic raw, {
    required bool isForeground,
  }) async {
    await _showFriendNotification(
      raw,
      isForeground: isForeground,
      accepted: false,
    );
  }

  Future<void> showFriendAcceptedNotification(
    dynamic raw, {
    required bool isForeground,
  }) async {
    await _showFriendNotification(
      raw,
      isForeground: isForeground,
      accepted: true,
    );
  }

  Future<void> _showFriendNotification(
    dynamic raw, {
    required bool isForeground,
    required bool accepted,
  }) async {
    if (!notificationsSupported || !notificationsEnabled) return;
    if (!isForeground && !_canShowAndroidRealtimeFallback) return;
    if (!_localNotificationsInitialized) return;
    if (raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    final eventId =
        (data['event_id'] ?? data['eventId'] ?? '').toString().trim();
    final fallbackId = accepted
        ? (data['friend_id'] ?? data['friendId'] ?? '').toString().trim()
        : (data['request_id'] ?? data['requestId'] ?? '').toString().trim();
    final dedupeId =
        '${accepted ? 'accepted' : 'request'}:${eventId.isNotEmpty ? eventId : fallbackId}';
    if (dedupeId.endsWith(':')) return;
    if (!_shownFriendNotificationIds.add(dedupeId)) return;
    _trimRecentIds(_shownFriendNotificationIds);

    final l10n = _currentLocalizations;
    if (l10n == null) {
      _shownFriendNotificationIds.remove(dedupeId);
      return;
    }
    final id = accepted
        ? (data['friend_id'] ?? data['friendId'] ?? '').toString()
        : (data['from_user_id'] ?? data['fromUserId'] ?? '').toString();
    final title = accepted
        ? l10n.friendAcceptedNotificationTitle
        : l10n.friendRequestNotificationTitle;
    final body = accepted
        ? l10n.friendAcceptedNotificationBody(id)
        : l10n.friendRequestNotificationBody(id);
    final payload = <String, String>{
      'notificationType': 'friend',
      'chatType': accepted ? 'friend_accept' : 'friend_request',
      'friendEvent': accepted ? 'accepted' : 'requested',
      if (eventId.isNotEmpty) 'eventId': eventId,
    };
    try {
      await _local.show(
        id: dedupeId.hashCode & 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: _encodePayload(payload),
      );
    } catch (error, stackTrace) {
      _shownFriendNotificationIds.remove(dedupeId);
      debugPrint('[Push] Friend notification failed: $error\n$stackTrace');
    }
  }

  /// Android 后台来电的本地系统通知；展示效果与现有极光普通来电通知一致。
  Future<void> showRealtimeCallNotification(dynamic raw) async {
    if (!_canShowAndroidRealtimeFallback || raw is! Map) return;
    final data = Map<String, dynamic>.from(raw);
    final action = data['action']?.toString().trim().toLowerCase();
    if (action != 'call') return;
    final callId = data['callId']?.toString().trim() ?? '';
    if (callId.isEmpty || !_shownRealtimeCallIds.add(callId)) return;

    final l10n = _currentLocalizations;
    if (l10n == null) {
      _shownRealtimeCallIds.remove(callId);
      return;
    }
    final video = data['mediaType']?.toString().toLowerCase() == 'video';
    final callType = video ? l10n.contactVideoCall : l10n.contactVoiceCall;
    final senderName = data['fromUsername']?.toString().trim();
    final payload = <String, String>{
      'notificationType': 'call',
      'chatType': 'call',
      'callId': callId,
      'fromUserId': data['fromUserId']?.toString() ?? '',
      'mediaType': video ? 'video' : 'audio',
      if (senderName != null && senderName.isNotEmpty)
        'fromUsername': senderName,
      if (data['fromAvatar']?.toString().trim().isNotEmpty == true)
        'fromAvatar': data['fromAvatar'].toString().trim(),
    };

    try {
      await _local.show(
        id: _callNotificationId(callId),
        title: senderName == null || senderName.isEmpty ? callType : senderName,
        body: '$callType · ${l10n.callStatusIncoming}',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidIncomingCallChannel.id,
            _androidIncomingCallChannel.name,
            channelDescription: _androidIncomingCallChannel.description,
            importance: Importance.max,
            priority: Priority.max,
            category: AndroidNotificationCategory.call,
            fullScreenIntent: true,
            visibility: NotificationVisibility.public,
            autoCancel: true,
          ),
        ),
        payload: _encodePayload(payload),
      );
    } catch (error, stackTrace) {
      _shownRealtimeCallIds.remove(callId);
      debugPrint(
        '[Push] Realtime call notification failed: $error\n$stackTrace',
      );
    }
  }

  Future<void> cancelRealtimeCallNotification(String? callId) async {
    final normalized = callId?.trim();
    if (normalized == null || normalized.isEmpty) return;
    _shownRealtimeCallIds.remove(normalized);
    if (!_localNotificationsInitialized) return;
    try {
      await _local.cancel(id: _callNotificationId(normalized));
    } catch (error, stackTrace) {
      debugPrint(
        '[Push] Cancel realtime call notification failed: '
        '$error\n$stackTrace',
      );
    }
  }

  Future<void> cancelAllRealtimeCallNotifications() async {
    final ids = _shownRealtimeCallIds.toList(growable: false);
    for (final callId in ids) {
      await cancelRealtimeCallNotification(callId);
    }
  }

  bool get _canShowAndroidRealtimeFallback =>
      Platform.isAndroid &&
      !_usesJPush &&
      notificationsEnabled &&
      _localNotificationsInitialized;

  Future<void> _syncAndroidKeepAlive() async {
    if (!Platform.isAndroid) return;
    final shouldRun = _authenticatedForPush &&
        !_usesJPush &&
        notificationsEnabled &&
        _localNotificationsInitialized;
    try {
      await _messageKeepAliveChannel.invokeMethod<void>(
        shouldRun ? 'start' : 'stop',
      );
      debugPrint(
        '[Push] Android message keep-alive ${shouldRun ? 'started' : 'stopped'}',
      );
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        '[Push] Android message keep-alive failed: $error\n$stackTrace',
      );
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint(
        '[Push] Android message keep-alive unavailable: $error\n$stackTrace',
      );
    }
  }

  AppLocalizations? get _currentLocalizations {
    final context = gvRootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return null;
    return AppLocalizations.of(context);
  }

  int _callNotificationId(String callId) =>
      Object.hash('incoming_call', callId) & 0x7fffffff;

  void _trimRecentIds(Set<String> ids) {
    const maxRemembered = 512;
    while (ids.length > maxRemembered) {
      ids.remove(ids.first);
    }
  }

  Future<void> _refreshJPushRegistrationId({
    bool forceRegisterIfNew = false,
  }) async {
    final jpush = _jpush;
    if (jpush == null) return;

    Future<String> tryFetch() async {
      try {
        return (await jpush.getRegistrationID()).trim();
      } catch (e) {
        debugPrint('[Push] JPush getRegistrationID failed: $e');
        return '';
      }
    }

    var rid = await tryFetch();
    for (var i = 0; i < 8 && rid.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      rid = await tryFetch();
    }

    if (rid.isEmpty) {
      debugPrint(
          '[Push] JPush RegistrationID empty (will retry via onConnected)');
      return;
    }

    final changed = _currentToken != rid;
    _currentToken = rid;
    if (changed || forceRegisterIfNew) {
      debugPrint('[Push] JPush RegistrationID: $rid');
    }
  }

  String? _jpushTitle(Map<String, dynamic> event) {
    return _firstEventString(event, const ['title', 'notificationTitle']) ??
        _readAlertValue(event, 'title');
  }

  String? _jpushBody(Map<String, dynamic> event) {
    final alert = event['alert'];
    if (alert is String) return alert;
    if (alert is Map) {
      return alert['body']?.toString() ?? alert['title']?.toString();
    }
    return _firstEventString(
          event,
          const ['content', 'notificationContent', 'body'],
        ) ??
        _readAlertValue(event, 'body');
  }

  String? _firstEventString(
    Map<String, dynamic> event,
    Iterable<String> keys,
  ) {
    for (final key in keys) {
      final value = event[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  String? _readAlertValue(Map<String, dynamic> event, String key) {
    final aps = event['aps'];
    final alert = aps is Map ? aps['alert'] : null;
    if (alert is Map) return alert[key]?.toString();
    if (key == 'body' && alert is String) return alert;
    return null;
  }

  Map<String, String> _jpushFlattenedPayload(Map<String, dynamic> event) {
    final out = <String, String>{};
    _collectPayloadMap(event, out);

    for (final key in const [
      'extras',
      'extra',
      'data',
      'payload',
      'custom',
      'customData',
      'params',
    ]) {
      _collectPayloadMap(event[key], out);
    }

    return _withNormalizedChatTarget(out);
  }

  void _collectPayloadMap(dynamic source, Map<String, String> out) {
    if (source == null) return;

    if (source is String) {
      final decoded = _decodeJsonObject(source);
      if (decoded != null) {
        _collectPayloadMap(decoded, out);
      }
      return;
    }

    if (source is! Map) return;

    for (final entry in source.entries) {
      final key = entry.key?.toString().trim();
      if (key == null || key.isEmpty) continue;
      final value = entry.value;

      if (value is Map) {
        if (key != 'aps') {
          _collectPayloadMap(value, out);
        }
        out.putIfAbsent(key, () => jsonEncode(value));
        continue;
      }

      if (value is List) {
        out[key] = jsonEncode(value);
        continue;
      }

      if (value != null) {
        final text = value.toString();
        out[key] = text;
        final decoded = _decodeJsonObject(text);
        if (decoded != null && _looksLikePayloadContainer(key)) {
          _collectPayloadMap(decoded, out);
        }
      }
    }
  }

  Map<String, dynamic>? _decodeJsonObject(String raw) {
    final text = raw.trim();
    if (!text.startsWith('{') || !text.endsWith('}')) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
    return null;
  }

  bool _looksLikePayloadContainer(String key) {
    final k = key.toLowerCase();
    return k == 'extras' ||
        k == 'extra' ||
        k == 'data' ||
        k == 'payload' ||
        k == 'custom' ||
        k == 'customdata' ||
        k == 'params';
  }

  Map<String, String> _withNormalizedChatTarget(Map<String, String> data) {
    final callInvite = normalizeCallInvitePayload(data);
    if (callInvite != null) return callInvite;
    final normalized = Map<String, String>.from(data);
    final rawChatType = _valueFor(data, const [
      'chatType',
      'chat_type',
      'conversationType',
      'conversation_type',
      'sessionType',
      'session_type',
    ])?.trim().toLowerCase();
    if (rawChatType == 'friend_request' || rawChatType == 'friend_accept') {
      normalized['chatType'] = rawChatType!;
      return normalized;
    }
    var chatType = _normalizeChatType(
      _valueFor(data, const [
        'chatType',
        'chat_type',
        'conversationType',
        'conversation_type',
        'sessionType',
        'session_type',
      ]),
    );

    var peerId = resolveChatTargetPeerId(data, chatType);
    // 注意：conversationId 是归一化会话标识（如 conv:private:17:32），
    // 不能直接当 peerId——解析逻辑见 [resolveChatTargetPeerId]。

    final groupId = _valueFor(data, const [
      'groupId',
      'group_id',
      'roomId',
      'room_id',
    ]);
    if (chatType == 'group') {
      peerId = groupId ?? peerId;
    } else if (chatType == null && groupId != null) {
      chatType = 'group';
      peerId = groupId;
    }

    if (chatType == 'private' && (peerId == null || peerId.isEmpty)) {
      peerId = _valueFor(data, const [
        'fromUserId',
        'from_user_id',
        'fromId',
        'from_id',
        'senderId',
        'sender_id',
        'from',
      ]);
    }

    if (chatType == null && peerId != null && peerId.isNotEmpty) {
      chatType = 'private';
    }

    final msgId = _valueFor(data, const [
      'msgId',
      'msg_id',
      'messageId',
      'message_id',
      '_j_msgid',
    ]);

    if (chatType != null) normalized['chatType'] = chatType;
    if (peerId != null && peerId.isNotEmpty) normalized['peerId'] = peerId;
    if (msgId != null && msgId.isNotEmpty) normalized['msgId'] = msgId;
    return normalized;
  }

  String? _normalizeChatType(String? raw) {
    final v = raw?.trim().toLowerCase();
    if (v == null || v.isEmpty) return null;
    switch (v) {
      case 'group':
      case 'room':
      case 'team':
        return 'group';
      case 'private':
      case 'single':
      case 'user':
      case 'friend':
      case 'p2p':
        return 'private';
    }
    return null;
  }

  String? _valueFor(Map<String, String> data, Iterable<String> keys) =>
      pushValueFor(data, keys);

  void _navigateFromJPushEvent(Map<String, dynamic> event) {
    _navigateFromPayload(_jpushFlattenedPayload(event));
  }

  Future<void> _listenIosApnsChannelFallback() async {
    _iosApnsChannel.setMethodCallHandler(_onIosPushFallbackMethodCall);
  }

  Future<dynamic> _onIosPushFallbackMethodCall(MethodCall call) async {
    if (!notificationsEnabled) return null;
    switch (call.method) {
      case 'onApnsToken':
        debugPrint(
            '[Push] Ignored legacy APNs token; using JPush RegistrationID');
        return null;
      case 'onApnsRegisterFailed':
        debugPrint('[Push] APNS register failed: ${call.arguments}');
        return null;
      case 'onNotificationOpened':
        final args = call.arguments;
        if (args is Map) {
          await _clearNotificationBadgeAndTray();
          _navigateFromPayload(
            _withNormalizedChatTarget(
              args.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
            ),
          );
        }
        return null;
      default:
        return null;
    }
  }

  Future<void> _initLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_androidChannel);
    await androidPlugin?.createNotificationChannel(_androidIncomingCallChannel);
    _localNotificationsInitialized = true;
    if (androidPlugin != null && !_fullScreenIntentPermissionRequested) {
      _fullScreenIntentPermissionRequested = true;
      unawaited(_requestAndroidFullScreenIntentPermission(androidPlugin));
    }

    final launchDetails = await _local.getNotificationAppLaunchDetails();
    final launchResponse = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchResponse?.payload?.isNotEmpty == true) {
      _onLocalNotificationTap(launchResponse!);
    }
  }

  Future<void> _requestAndroidFullScreenIntentPermission(
    AndroidFlutterLocalNotificationsPlugin androidPlugin,
  ) async {
    try {
      final granted =
          await androidPlugin.requestFullScreenIntentPermission() ?? false;
      debugPrint('[Push] Android full-screen call permission: $granted');
    } on PlatformException catch (error, stackTrace) {
      debugPrint(
        '[Push] Android full-screen call permission request failed: '
        '$error\n$stackTrace',
      );
    }
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    if (!notificationsEnabled) return;
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    unawaited(_openFromLocalNotification(payload));
  }

  Future<void> _openFromLocalNotification(String payload) async {
    await _clearNotificationBadgeAndTray();
    _navigateFromPayload(_decodePayload(payload));
  }

  void _navigateFromPayload(Map<String, String> data) {
    final callInvite = normalizeCallInvitePayload(data);
    if (callInvite != null) {
      _openCallInvite(callInvite);
      return;
    }
    final chatType = (data['chatType'] ?? '').trim().toLowerCase();
    // 好友申请：点击后进入「新的朋友」列表（不进入聊天页），由页面刷新拉取最新申请。
    if (chatType == 'friend_request') {
      _openFriendRequests();
      return;
    }
    if (chatType == 'friend_accept') {
      _openContacts();
      return;
    }
    // 来电邀请：普通通知点击后拉起 App 内接听界面（不进入聊天页）。
    if (chatType == 'call') {
      _openCallInvite(data);
      return;
    }
    _navigateToChat(data);
  }

  void _openFriendRequests() {
    final context = gvRootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _queueNavigation(const {'chatType': 'friend_request'});
      return;
    }
    try {
      context.push(AppRoutes.contactsRequests);
    } catch (error, stackTrace) {
      debugPrint('[Push] Open friend requests from notification failed: '
          '$error\n$stackTrace');
      _queueNavigation(const {'chatType': 'friend_request'});
    }
  }

  void _openContacts() {
    final context = gvRootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _queueNavigation(const {'chatType': 'friend_accept'});
      return;
    }
    try {
      context.push(AppRoutes.contacts);
    } catch (error, stackTrace) {
      debugPrint(
          '[Push] Open contacts from notification failed: $error\n$stackTrace');
      _queueNavigation(const {'chatType': 'friend_accept'});
    }
  }

  void _openCallInvite(Map<String, String> data) {
    final context = gvRootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _queueNavigation(data);
      return;
    }
    final handler = onCallInviteOpened;
    if (handler == null) {
      _queueNavigation(data);
      return;
    }
    try {
      handler(data);
    } catch (error, stackTrace) {
      debugPrint('[Push] Open call invite from notification failed: '
          '$error\n$stackTrace');
      _queueNavigation(data);
    }
  }

  void _navigateToChat(Map<String, String> data) {
    final target = _chatTargetFromData(data);
    if (target == null) {
      debugPrint('[Push] Notification payload missing chat target: $data');
      return;
    }
    unawaited(_openChatOrQueue(target));
  }

  _ChatNotificationTarget? _chatTargetFromData(Map<String, String> data) {
    final normalized = _withNormalizedChatTarget(data);
    final chatType = normalized['chatType'];
    final peerId = normalized['peerId'];
    if (chatType == null || peerId == null || peerId.isEmpty) return null;
    return _ChatNotificationTarget(
      chatType: chatType,
      peerId: peerId,
      msgId: normalized['msgId'],
      payload: normalized,
    );
  }

  Future<void> _openChatOrQueue(_ChatNotificationTarget target) async {
    final sync = onChatNotificationOpened;
    if (sync != null) {
      try {
        await sync();
      } catch (error, stackTrace) {
        debugPrint(
          '[Push] Message sync before opening notification failed: '
          '$error\n$stackTrace',
        );
      }
    }
    final context = gvRootNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _queueNavigation(target.payload);
      return;
    }

    final key = '${target.chatType}:${target.peerId}:${target.msgId ?? ''}';
    final now = DateTime.now();
    if (_lastNavigationKey == key &&
        _lastNavigationAt != null &&
        now.difference(_lastNavigationAt!) < const Duration(seconds: 2)) {
      return;
    }
    _lastNavigationKey = key;
    _lastNavigationAt = now;

    try {
      gvOpenChat(
        context,
        chatType: target.chatType,
        peerId: target.peerId,
        anchorMsgId: target.msgId,
      );
    } catch (e, st) {
      debugPrint('[Push] Open chat from notification failed: $e\n$st');
      _queueNavigation(target.payload);
    }
  }

  void _queueNavigation(Map<String, String> payload) {
    _pendingNavigationPayload = payload;
    _scheduleNavigationFlush();
  }

  void _scheduleNavigationFlush() {
    if (_navigationFlushScheduled) return;
    _navigationFlushScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationFlushScheduled = false;
      final payload = _pendingNavigationPayload;
      if (payload == null) return;

      final context = gvRootNavigatorKey.currentContext;
      if (context == null || !context.mounted) {
        if (_navigationFlushAttempts++ < 20) {
          Timer(const Duration(milliseconds: 250), _scheduleNavigationFlush);
        }
        return;
      }

      _pendingNavigationPayload = null;
      _navigationFlushAttempts = 0;
      _navigateFromPayload(payload);
    });
  }

  String _encodePayload(Map<String, String> data) {
    return jsonEncode(data);
  }

  Map<String, String> _decodePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        return decoded
            .map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
      }
    } catch (_) {
      // Fall through to the legacy query-string payload.
    }

    try {
      return Uri.splitQueryString(payload);
    } catch (_) {
      return const <String, String>{};
    }
  }

  String get _platformString {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    return 'android';
  }

  String? get _deviceId => null;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
}

class _ChatNotificationTarget {
  const _ChatNotificationTarget({
    required this.chatType,
    required this.peerId,
    required this.payload,
    this.msgId,
  });

  final String chatType;
  final String peerId;
  final String? msgId;
  final Map<String, String> payload;
}
