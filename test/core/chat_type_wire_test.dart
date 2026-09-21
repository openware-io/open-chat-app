import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/chat_type_wire.dart';

void main() {
  test('maps app chat types to the backend wire values', () {
    expect(chatTypeToWire('private'), 'private');
    expect(chatTypeToWire('group'), 'group');
    expect(chatTypeToWire('PRIVATE'), 'private');
  });

  test('maps enum query values to Spring MVC enum constant names', () {
    expect(chatTypeToHttpQuery('private'), 'PRIVATE');
    expect(chatTypeToHttpQuery('GROUP'), 'GROUP');
    expect(messageTypeToHttpQuery('image'), 'IMAGE');
  });

  test('normalizes nested incoming WebSocket payloads', () {
    final app = chatPayloadFromWire({
      'chatType': 'PRIVATE',
      'message': {'chatType': 'GROUP'},
    });
    expect(app['chatType'], 'private');
    expect((app['message'] as Map)['chatType'], 'group');
  });
}
