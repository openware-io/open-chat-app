import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gv_core/gv_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/config.dart';
import '../core/websocket_protocol.dart';
import 'api_client.dart';

/// Native WebSocket client for `/ws/im/v1`.
///
/// Every connection and reconnection requests a fresh one-time ticket through
/// the authenticated REST client. Access tokens are never placed in the URL.
class SocketService implements GvSocketClient {
  SocketService(ApiClient apiClient)
      : this._(
          requestWebSocketTicket: apiClient.requestWebSocketTicket,
          connectChannel: (uri) => WebSocketChannel.connect(uri),
          socketUri: AppConfig.socketUri,
          connectTimeout: const Duration(seconds: 15),
          heartbeatInterval: const Duration(seconds: 30),
          heartbeatTimeout: const Duration(seconds: 15),
          reconnectDelayForAttempt: _defaultReconnectDelay,
        );

  @visibleForTesting
  SocketService.test({
    required Future<String> Function() requestWebSocketTicket,
    required WebSocketChannel Function(Uri uri) connectChannel,
    required String socketUri,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration heartbeatInterval = const Duration(seconds: 30),
    Duration heartbeatTimeout = const Duration(seconds: 15),
    Duration Function(int attempt)? reconnectDelayForAttempt,
  }) : this._(
          requestWebSocketTicket: requestWebSocketTicket,
          connectChannel: connectChannel,
          socketUri: socketUri,
          connectTimeout: connectTimeout,
          heartbeatInterval: heartbeatInterval,
          heartbeatTimeout: heartbeatTimeout,
          reconnectDelayForAttempt:
              reconnectDelayForAttempt ?? _defaultReconnectDelay,
        );

  SocketService._({
    required Future<String> Function() requestWebSocketTicket,
    required WebSocketChannel Function(Uri uri) connectChannel,
    required String socketUri,
    required Duration connectTimeout,
    required Duration heartbeatInterval,
    required Duration heartbeatTimeout,
    required Duration Function(int attempt) reconnectDelayForAttempt,
  })  : _requestWebSocketTicket = requestWebSocketTicket,
        _connectChannel = connectChannel,
        _socketUri = socketUri,
        _connectTimeout = connectTimeout,
        _heartbeatInterval = heartbeatInterval,
        _heartbeatTimeout = heartbeatTimeout,
        _reconnectDelayForAttempt = reconnectDelayForAttempt;

  final Future<String> Function() _requestWebSocketTicket;
  final WebSocketChannel Function(Uri uri) _connectChannel;
  final String _socketUri;
  final Duration _connectTimeout;
  final Duration _heartbeatInterval;
  final Duration _heartbeatTimeout;
  final Duration Function(int attempt) _reconnectDelayForAttempt;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _heartbeat;
  Timer? _heartbeatDeadline;
  Timer? _reconnectTimer;
  String? _authTokenUsed;
  int _connectionGeneration = 0;
  int _reconnectAttempt = 0;
  bool _connected = false;
  bool _connecting = false;

  @override
  void Function(dynamic data)? onChatReceive;
  @override
  void Function(dynamic data)? onChatAck;
  @override
  void Function(dynamic data)? onReadNotify;
  @override
  void Function(dynamic data)? onRecallNotify;
  @override
  void Function(dynamic data)? onMessageDeletedNotify;
  @override
  void Function(dynamic data)? onMessageEditedNotify;
  @override
  void Function(dynamic data)? onChatSecretDestroyed;
  @override
  void Function(dynamic data)? onChatSecretStored;
  @override
  void Function(dynamic data)? onChatSecretCreated;
  @override
  void Function(dynamic data)? onChatSecretDeleted;
  @override
  void Function(dynamic data)? onChatSecretGroupStored;
  @override
  void Function(dynamic data)? onTyping;
  @override
  void Function(dynamic data)? onUserStatusChange;
  @override
  void Function(dynamic data)? onFriendRequestNotify;
  @override
  void Function(dynamic data)? onFriendAcceptNotify;
  @override
  void Function(dynamic data)? onClearPrivateChatNotify;
  @override
  void Function(dynamic data)? onClearGroupChatNotify;
  @override
  void Function(dynamic data)? onGroupDissolveNotify;
  @override
  void Function(dynamic data)? onGroupNotify;
  @override
  void Function(dynamic data)? onRtcSignal;
  @override
  void Function(dynamic data)? onError;
  void Function()? onConnected;

  @override
  bool get connected => _connected;

  @override
  bool get hasClient => _channel != null || _connecting;

  @override
  void connect(String token) {
    if (token.isEmpty) return;
    if (_authTokenUsed == token && (_connected || _connecting)) return;

    _connectionGeneration++;
    _authTokenUsed = token;
    _reconnectAttempt = 0;
    _closeTransport();
    unawaited(_open(_connectionGeneration, token));
  }

  Future<void> _open(int generation, String token) async {
    if (generation != _connectionGeneration || _authTokenUsed != token) return;
    _connecting = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    WebSocketChannel? openingChannel;

    try {
      final ticket = await _requestWebSocketTicket();
      if (generation != _connectionGeneration || _authTokenUsed != token) {
        return;
      }

      final uri = buildWebSocketTicketUri(_socketUri, ticket);
      final channel = _connectChannel(uri);
      openingChannel = channel;
      _channel = channel;
      _subscription = channel.stream.listen(
        (raw) => _handleIncoming(generation, channel, raw),
        onError: (Object error, StackTrace stackTrace) {
          _handleTransportClosed(generation, channel, error: error);
        },
        onDone: () => _handleTransportClosed(generation, channel),
        cancelOnError: true,
      );

      await channel.ready.timeout(_connectTimeout);
      if (generation != _connectionGeneration ||
          _authTokenUsed != token ||
          !identical(_channel, channel)) {
        await channel.sink.close();
        return;
      }

      _connecting = false;
      _connected = true;
      _startHeartbeat(generation, channel);
      _logState('CONNECTED ${_endpointLabel(uri)}');
      onConnected?.call();
    } catch (error) {
      if (generation != _connectionGeneration || _authTokenUsed != token) {
        if (openingChannel != null) {
          unawaited(openingChannel.sink.close());
        }
        return;
      }
      if (openingChannel != null && identical(_channel, openingChannel)) {
        _retireTransport(openingChannel);
      } else {
        _connecting = false;
        _connected = false;
      }
      _logState('CONNECT ERROR', error: error);
      // 传输层连接错误只记录日志并自动重连，不把原始 SocketException 等堆栈泄漏到 UI。
      _scheduleReconnect(generation, token);
    }
  }

  void _handleIncoming(
    int generation,
    WebSocketChannel channel,
    dynamic raw,
  ) {
    if (generation != _connectionGeneration || !identical(_channel, channel)) {
      return;
    }
    _markTransportAlive();
    try {
      final frame = decodeWebSocketEvent(raw);
      _log('RECEIVE ${frame.event}');
      _dispatch(frame.event, frame.data);
    } catch (error) {
      _log('INVALID FRAME $error');
      // 协议解码错误属于客户端内部问题，仅记录日志，不上抛到 UI。
    }
  }

  void _dispatch(String event, dynamic data) {
    switch (event) {
      case 'heartbeat':
        return;
      case 'chat:receive':
        onChatReceive?.call(data);
        return;
      case 'chat:ack':
        onChatAck?.call(data);
        return;
      case 'chat:read_notify':
        onReadNotify?.call(data);
        return;
      case 'chat:recall_notify':
        onRecallNotify?.call(data);
        return;
      case 'chat:delete_notify':
        onMessageDeletedNotify?.call(data);
        return;
      case 'chat:edit_notify':
        onMessageEditedNotify?.call(data);
        return;
      case 'chat:secret_destroyed':
        onChatSecretDestroyed?.call(data);
        return;
      case 'chat:secret_stored':
        onChatSecretStored?.call(data);
        return;
      case 'chat:secret_created':
        onChatSecretCreated?.call(data);
        return;
      case 'chat:secret_deleted':
        onChatSecretDeleted?.call(data);
        return;
      case 'chat:secret_group_stored':
        onChatSecretGroupStored?.call(data);
        return;
      case 'chat:typing':
        onTyping?.call(data);
        return;
      case 'user:status_change':
        onUserStatusChange?.call(data);
        return;
      case 'friend:request_notify':
        onFriendRequestNotify?.call(data);
        return;
      case 'friend:accept_notify':
        onFriendAcceptNotify?.call(data);
        return;
      case 'chat:clear_private_notify':
        onClearPrivateChatNotify?.call(data);
        return;
      case 'chat:clear_group_notify':
        onClearGroupChatNotify?.call(data);
        return;
      case 'group:dissolve_notify':
        onGroupDissolveNotify?.call(data);
        return;
      case 'group:notify':
        onGroupNotify?.call(data);
        return;
      case 'rtc:signal':
        onRtcSignal?.call(data);
        return;
      case 'error':
        onError?.call(data);
        return;
      default:
        _log('UNKNOWN EVENT $event');
    }
  }

  void _handleTransportClosed(
    int generation,
    WebSocketChannel channel, {
    Object? error,
  }) {
    if (generation != _connectionGeneration || !identical(_channel, channel)) {
      return;
    }
    final closeCode = channel.closeCode;
    final closeReason = channel.closeReason?.trim();
    _retireTransport(channel);
    if (error != null) {
      _logState('DISCONNECTED', error: error);
      // 断线只记录日志并进入退避重连，避免离线时把原始异常文本弹到界面。
    } else {
      final details = [
        if (closeCode != null) 'code=$closeCode',
        if (closeReason != null && closeReason.isNotEmpty)
          'reason=${_safeLogValue(closeReason)}',
      ].join(' ');
      _logState('DISCONNECTED${details.isEmpty ? '' : ' $details'}');
    }
    final token = _authTokenUsed;
    if (token != null) _scheduleReconnect(generation, token);
  }

  void _scheduleReconnect(int generation, String token) {
    if (generation != _connectionGeneration || _authTokenUsed != token) return;
    if (_reconnectTimer?.isActive == true) return;
    final delay = _reconnectDelayForAttempt(_reconnectAttempt);
    _reconnectAttempt++;
    _logState('RECONNECT SCHEDULED ${delay.inMilliseconds}ms');
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (generation != _connectionGeneration || _authTokenUsed != token) {
        return;
      }
      unawaited(_open(generation, token));
    });
  }

  void _startHeartbeat(int generation, WebSocketChannel channel) {
    _heartbeat?.cancel();
    _heartbeatDeadline?.cancel();
    _heartbeatDeadline = null;
    _sendHeartbeat(generation, channel);
    _heartbeat = Timer.periodic(
      _heartbeatInterval,
      (_) => _sendHeartbeat(generation, channel),
    );
  }

  void _sendHeartbeat(int generation, WebSocketChannel channel) {
    if (generation != _connectionGeneration ||
        !_connected ||
        !identical(_channel, channel)) {
      return;
    }
    // A pending heartbeat already owns the liveness deadline. Sending more
    // frames would hide a stalled connection instead of proving it healthy.
    if (_heartbeatDeadline?.isActive == true) return;
    try {
      _log('SEND heartbeat');
      channel.sink.add(
        encodeWebSocketEvent('heartbeat', {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      _heartbeatDeadline = Timer(_heartbeatTimeout, () {
        if (generation != _connectionGeneration ||
            !identical(_channel, channel)) {
          return;
        }
        _logState('HEARTBEAT TIMEOUT ${_heartbeatTimeout.inMilliseconds}ms');
        _handleTransportClosed(
          generation,
          channel,
          error: TimeoutException('WebSocket heartbeat response timed out'),
        );
      });
    } catch (error) {
      _handleTransportClosed(generation, channel, error: error);
    }
  }

  void _markTransportAlive() {
    _heartbeatDeadline?.cancel();
    _heartbeatDeadline = null;
    // Do not reset the backoff merely because the HTTP upgrade succeeded.
    // A server that immediately closes every upgraded socket must still back
    // off. The first inbound frame proves the connection is actually usable.
    _reconnectAttempt = 0;
  }

  @override
  void disconnect() {
    _connectionGeneration++;
    _authTokenUsed = null;
    _reconnectAttempt = 0;
    _closeTransport();
  }

  void _closeTransport() {
    _connected = false;
    _connecting = false;
    _heartbeat?.cancel();
    _heartbeat = null;
    _heartbeatDeadline?.cancel();
    _heartbeatDeadline = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(channel.sink.close());
  }

  @override
  void reconnectIfNeeded() {
    final token = _authTokenUsed;
    if (token == null) return;
    if (_connected) {
      final channel = _channel;
      if (channel != null) {
        // Lifecycle resume is also a health probe. This catches a half-open
        // socket even when the platform never delivered onDone/onError.
        _sendHeartbeat(_connectionGeneration, channel);
        return;
      }
    }
    if (_connecting) return;
    _connectionGeneration++;
    _reconnectAttempt = 0;
    _closeTransport();
    unawaited(_open(_connectionGeneration, token));
  }

  @override
  void emitChat(String event, dynamic data) {
    final channel = _channel;
    if (!_connected || channel == null) return;
    _log('SEND $event');
    channel.sink.add(encodeWebSocketEvent(event, data));
  }

  /// 上报设备前后台状态（供后端推送决策）。
  void emitAppState(String appState, {String? activeConversationId}) {
    emitChat('app:state', {
      'appState': appState,
      'activeConversationId': activeConversationId ?? '',
    });
  }

  void _log(String message) {
    if (kDebugMode) debugPrint('[WS DEBUG] $message');
  }

  void _logState(String message, {Object? error}) {
    final errorType = error == null ? '' : ' (${error.runtimeType})';
    debugPrint('[WS] $message$errorType');
    if (kDebugMode && error != null) {
      debugPrint('[WS DEBUG] ${_safeLogValue(error.toString())}');
    }
  }

  void _retireTransport(WebSocketChannel channel) {
    _connected = false;
    _connecting = false;
    _heartbeat?.cancel();
    _heartbeat = null;
    _heartbeatDeadline?.cancel();
    _heartbeatDeadline = null;
    final subscription = _subscription;
    _subscription = null;
    _channel = null;
    if (subscription != null) unawaited(subscription.cancel());
    unawaited(channel.sink.close());
  }

  String _endpointLabel(Uri uri) => '${uri.scheme}://${uri.host}${uri.path}';

  String _safeLogValue(String value) {
    final redacted = value.replaceAll(
      RegExp(r'([?&]ticket=)[^&\s)]+', caseSensitive: false),
      r'$1<redacted>',
    );
    const maxLength = 300;
    return redacted.length <= maxLength
        ? redacted
        : '${redacted.substring(0, maxLength)}…';
  }

  static Duration _defaultReconnectDelay(int attempt) {
    final seconds = (1 << attempt.clamp(0, 3)).clamp(1, 10);
    return Duration(seconds: seconds);
  }
}
