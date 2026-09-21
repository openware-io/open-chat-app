import 'dart:math';

int _msgCounter = 0;

/// Generates a client-side message id before the server returns a real id.
///
/// The timestamp keeps ids sortable enough for optimistic UI, the counter
/// avoids same-millisecond collisions, and the random suffix protects against
/// multiple isolates/processes producing the same local sequence.
String genClientMsgId() {
  _msgCounter++;
  final r = Random().nextInt(1 << 30);
  return '${DateTime.now().millisecondsSinceEpoch}-$_msgCounter-${r.toRadixString(36)}';
}
