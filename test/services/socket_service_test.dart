import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/websocket_protocol.dart';
import 'package:open_chat_app/services/socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  late HttpServer server;
  late List<WebSocket> serverSockets;
  late bool answerHeartbeats;
  late int heartbeatCount;

  setUp(() async {
    serverSockets = <WebSocket>[];
    answerHeartbeats = true;
    heartbeatCount = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      serverSockets.add(socket);
      socket.listen((raw) {
        final frame = decodeWebSocketEvent(raw);
        if (frame.event != 'heartbeat') return;
        heartbeatCount++;
        if (answerHeartbeats) {
          socket.add(
            encodeWebSocketEvent('heartbeat', {
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          );
        }
      });
    });
  });

  tearDown(() async {
    for (final socket in serverSockets) {
      await socket.close();
    }
    await server.close(force: true);
  });

  SocketService createService() => SocketService.test(
        requestWebSocketTicket: () async => 'ticket',
        connectChannel: (uri) => WebSocketChannel.connect(uri),
        socketUri: 'ws://${server.address.host}:${server.port}/ws',
        connectTimeout: const Duration(seconds: 1),
        heartbeatInterval: const Duration(milliseconds: 60),
        heartbeatTimeout: const Duration(milliseconds: 40),
        reconnectDelayForAttempt: (_) => const Duration(milliseconds: 10),
      );

  test('heartbeat response keeps one healthy connection alive', () async {
    final service = createService();
    addTearDown(service.disconnect);

    service.connect('token');

    await _waitFor(() => service.connected && heartbeatCount >= 2);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(service.connected, isTrue);
    expect(serverSockets, hasLength(1));
  });

  test('missing heartbeat response retires and reconnects socket', () async {
    answerHeartbeats = false;
    final service = createService();
    addTearDown(service.disconnect);

    service.connect('token');

    await _waitFor(() => serverSockets.length >= 2);

    expect(heartbeatCount, greaterThanOrEqualTo(1));
    expect(serverSockets.length, greaterThanOrEqualTo(2));
  });

  test('resume health probe detects a half-open connected socket', () async {
    final service = createService();
    addTearDown(service.disconnect);
    service.connect('token');
    await _waitFor(() => service.connected && heartbeatCount >= 1);

    answerHeartbeats = false;
    service.reconnectIfNeeded();

    await _waitFor(() => serverSockets.length >= 2);
    expect(serverSockets.length, greaterThanOrEqualTo(2));
  });
}

Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition was not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
