String chatTypeToWire(String value) {
  final normalized = value.trim().toLowerCase();
  return switch (normalized) {
    'private' => 'private',
    'group' => 'group',
    _ => normalized,
  };
}

/// Spring MVC binds enum query parameters through `Enum.valueOf`, so HTTP
/// query values use enum constant names even though JSON/WebSocket uses the
/// lowercase values declared by `@JsonValue`.
String chatTypeToHttpQuery(String value) => chatTypeToWire(value).toUpperCase();

String messageTypeToHttpQuery(String value) => value.trim().toUpperCase();

String chatTypeFromWire(String value) {
  final normalized = value.trim().toUpperCase();
  return switch (normalized) {
    'PRIVATE' => 'private',
    'GROUP' => 'group',
    _ => value.trim().toLowerCase(),
  };
}

Map<String, dynamic> chatPayloadFromWire(Map<String, dynamic> payload) =>
    Map<String, dynamic>.from(_normalizeIncomingChatTypes(payload) as Map);

Object? _normalizeIncomingChatTypes(Object? value) {
  if (value is List) {
    return value.map(_normalizeIncomingChatTypes).toList(growable: false);
  }
  if (value is! Map) return value;
  return {
    for (final entry in value.entries)
      entry.key.toString():
          entry.key.toString() == 'chatType' && entry.value is String
              ? chatTypeFromWire(entry.value as String)
              : _normalizeIncomingChatTypes(entry.value),
  };
}
