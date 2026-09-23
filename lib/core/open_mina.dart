/// 小程序码 / 扫码 payload 前缀（与「我的二维码」[OPEN_UID:] 并列）。
const gvMinaPrefix = 'OPEN_MINA:';

String buildGvMinaPayload(String miniProgramId) {
  final id = miniProgramId.trim();
  return '$gvMinaPrefix$id';
}

/// 若文本为小程序码则返回小程序 ID，否则返回 `null`。
String? parseGvMinaPayload(String text) {
  final t = text.trim();
  if (!t.startsWith(gvMinaPrefix)) return null;
  final id = t.substring(gvMinaPrefix.length).trim();
  return id.isEmpty ? null : id;
}
