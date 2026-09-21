import 'dart:convert';

import 'package:gv_core/gv_core.dart';
import 'package:uuid/uuid.dart';

class ImRealtimeEnvelope {
  const ImRealtimeEnvelope({
    required this.version,
    required this.event,
    required this.eventId,
    required this.requestId,
    required this.sentAt,
    required this.data,
  });

  factory ImRealtimeEnvelope.outgoing(
    String event,
    Map<String, dynamic> data,
  ) {
    const uuid = Uuid();
    return ImRealtimeEnvelope(
      version: 'v1',
      event: event,
      eventId: uuid.v4(),
      requestId: uuid.v4(),
      sentAt: DateTime.now().toUtc(),
      data: data,
    );
  }

  static ImRealtimeEnvelope? tryParse(dynamic raw) {
    try {
      final decoded = switch (raw) {
        String value => jsonDecode(value),
        List<int> value => jsonDecode(utf8.decode(value)),
        _ => raw,
      };
      if (decoded is! Map) return null;
      final map = Map<String, dynamic>.from(decoded);
      final version = map['version']?.toString().trim();
      final event = map['event']?.toString().trim();
      final eventId = map['eventId']?.toString().trim();
      final requestId = map['requestId']?.toString().trim();
      final sentAt = parseUtcDateTime(map['sentAt']);
      final rawData = map['data'];
      if ((version != null && version.isNotEmpty && version != 'v1') ||
          event == null ||
          event.isEmpty ||
          rawData is! Map) {
        return null;
      }
      const uuid = Uuid();
      final resolvedEventId =
          eventId != null && eventId.isNotEmpty ? eventId : uuid.v4();
      return ImRealtimeEnvelope(
        version: 'v1',
        event: event,
        eventId: resolvedEventId,
        requestId: requestId != null && requestId.isNotEmpty
            ? requestId
            : resolvedEventId,
        sentAt: sentAt ?? DateTime.now().toUtc(),
        data: Map<String, dynamic>.from(rawData),
      );
    } catch (_) {
      return null;
    }
  }

  final String version;
  final String event;
  final String eventId;
  final String requestId;
  final DateTime sentAt;
  final Map<String, dynamic> data;

  /// The backend v1 WebSocket contract accepts a minimal event envelope.
  /// Correlation fields are generated server-side and are intentionally not
  /// added to outbound frames.
  Map<String, dynamic> toJson() => {
        'event': event,
        'data': data,
      };

  String encode() => jsonEncode(toJson());
}
