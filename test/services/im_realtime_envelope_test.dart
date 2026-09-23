import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/services/im_realtime_envelope.dart';

void main() {
  test('encodes the minimal outbound envelope from the v1 contract', () {
    final envelope = ImRealtimeEnvelope.outgoing(
      'chat:send',
      {'clientMsgId': 'client-1', 'toId': '8'},
    );
    final json = jsonDecode(envelope.encode()) as Map<String, dynamic>;

    expect(json['event'], 'chat:send');
    expect(json['data'], {'clientMsgId': 'client-1', 'toId': '8'});
    expect(json.keys, unorderedEquals(['event', 'data']));
  });

  test('parses a complete inbound envelope', () {
    final valid = jsonEncode({
      'version': 'v1',
      'event': 'chat:ack',
      'eventId': 'event-1',
      'requestId': 'request-1',
      'sentAt': '2026-07-31T08:00:00Z',
      'data': {'clientMsgId': 'client-1', 'msgId': 'server-1', 'seq': 7},
    });

    final parsed = ImRealtimeEnvelope.tryParse(valid);
    expect(parsed, isNotNull);
    expect(parsed!.event, 'chat:ack');
    expect(parsed.data['seq'], 7);
  });

  test('interprets legacy bare sentAt as UTC', () {
    final parsed = ImRealtimeEnvelope.tryParse({
      'version': 'v1',
      'event': 'chat:receive',
      'sentAt': '2026-07-31T08:00:00',
      'data': <String, dynamic>{},
    });

    expect(parsed?.sentAt, DateTime.utc(2026, 7, 31, 8));
  });

  test('parses the minimal event and data envelope from the v1 contract', () {
    final parsed = ImRealtimeEnvelope.tryParse(
      jsonEncode({
        'event': 'chat:receive',
        'data': {'msgId': 'server-1', 'content': 'hello'},
      }),
    );

    expect(parsed, isNotNull);
    expect(parsed!.version, 'v1');
    expect(parsed.event, 'chat:receive');
    expect(parsed.eventId, isNotEmpty);
    expect(parsed.requestId, isNotEmpty);
    expect(parsed.data['msgId'], 'server-1');
  });

  test('rejects frames without an event or map data', () {
    expect(
      ImRealtimeEnvelope.tryParse(jsonEncode({'data': <String, dynamic>{}})),
      isNull,
    );
    expect(
      ImRealtimeEnvelope.tryParse(
        jsonEncode({'event': 'chat:receive', 'data': 'invalid'}),
      ),
      isNull,
    );
  });
}
