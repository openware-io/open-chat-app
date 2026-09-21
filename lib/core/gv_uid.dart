const gvUidPrefix = 'GV_UID:';

String buildGvUidPayload(String username) {
  final u = username.trim();
  return '$gvUidPrefix$u';
}

String? parseGvUidPayload(String text) {
  final t = text.trim();
  if (!t.startsWith(gvUidPrefix)) return null;
  final u = t.substring(gvUidPrefix.length).trim();
  return u.isEmpty ? null : u;
}
