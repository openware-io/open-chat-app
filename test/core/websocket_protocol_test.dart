import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/websocket_protocol.dart';

void main() {
  test('builds the v1 WebSocket URL with an encoded ticket', () {
    final uri = buildWebSocketTicketUri(
      'wss://api.dev.example.com/ws/im/v1',
      'ticket+/=? value',
    );

    expect(uri.scheme, 'wss');
    expect(uri.host, 'api.dev.example.com');
    expect(uri.path, '/ws/im/v1');
    expect(uri.queryParameters['ticket'], 'ticket+/=? value');
    expect(uri.toString(), contains('ticket%2B%2F%3D%3F+value'));
  });

  test('encodes and decodes the native WebSocket event envelope', () {
    final encoded = encodeWebSocketEvent('chat:send', {
      'toId': '3',
      'content': 'hello',
    });
    final decoded = decodeWebSocketEvent(encoded);

    expect(decoded.event, 'chat:send');
    expect(decoded.data, {'toId': '3', 'content': 'hello'});
  });
}
