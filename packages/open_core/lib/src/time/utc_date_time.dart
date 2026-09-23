/// Parses API timestamps as UTC instants.
///
/// New responses must include `Z` or an explicit offset. Bare timestamps are
/// accepted temporarily and interpreted as UTC for compatibility with older
/// message-service responses.
DateTime? parseUtcDateTime(Object? value) {
  if (value is DateTime) return value.toUtc();
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final hasOffset =
      text.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(text);
  final parsed = DateTime.tryParse(hasOffset ? text : '${text}Z');
  return parsed?.toUtc();
}
