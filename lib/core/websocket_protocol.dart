import 'dart:convert';

Uri buildWebSocketTicketUri(String endpoint, String ticket) {
  final base = Uri.parse(endpoint);
  return base.replace(
    queryParameters: {
      ...base.queryParameters,
      'ticket': ticket,
    },
  );
}

String encodeWebSocketEvent(String event, dynamic data) {
  return jsonEncode({
    'event': event,
    'data': data ?? const <String, dynamic>{},
  });
}

({String event, dynamic data}) decodeWebSocketEvent(dynamic raw) {
  final text = raw is String ? raw : utf8.decode(List<int>.from(raw as List));
  final decoded = jsonDecode(text);
  if (decoded is! Map) {
    throw const FormatException('WebSocket frame must be a JSON object');
  }
  final frame = Map<String, dynamic>.from(decoded);
  final event = frame['event']?.toString().trim() ?? '';
  if (event.isEmpty) {
    throw const FormatException('WebSocket frame is missing event');
  }
  return (event: event, data: frame['data'] ?? const <String, dynamic>{});
}
