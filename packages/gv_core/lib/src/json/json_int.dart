/// Parses integer fields from JSON.
///
/// Nest/MySQL `bigint` values often arrive as [String], while some endpoints
/// still return [num]. Keeping the conversion in `gv_core` gives every model
/// the same tolerant parsing rule.
int? jsonInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }
  return null;
}

int jsonIntRequired(dynamic v) {
  final n = jsonInt(v);
  if (n == null) {
    throw FormatException('Expected integer, got $v (${v.runtimeType})');
  }
  return n;
}
