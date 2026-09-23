const gvQrLoginPrefix = 'OPEN_LOGIN:';

/// 扫码登录二维码 payload：`OPEN_LOGIN:{qrToken}`。
/// 桌面端展示此二维码，手机 App 扫码后确认登录（见 scan_screen._handleQrLogin）。
String? parseGvQrLoginPayload(String text) {
  final t = text.trim();
  if (!t.startsWith(gvQrLoginPrefix)) return null;
  final token = t.substring(gvQrLoginPrefix.length).trim();
  return token.isEmpty ? null : token;
}
