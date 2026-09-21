import 'dart:convert';

/// Validates an absolute media URL against the configured managed media host.
String resolveMediaUrl(String managedBaseUrl, String? src) {
  final value = src?.trim() ?? '';
  if (value.isEmpty) return '';
  if (value.startsWith('data:')) return value;

  final uri = Uri.tryParse(value);
  final managed = Uri.tryParse(managedBaseUrl);
  if (uri == null ||
      managed == null ||
      !uri.isAbsolute ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      managed.host.isEmpty) {
    return '';
  }
  final trustedHost =
      uri.host == managed.host || uri.host.endsWith('.${managed.host}');
  return trustedHost ? uri.toString() : '';
}

String storedMediaPathFromUploadResponse(String url) {
  final t = url.trim();
  if (t.startsWith('data:')) return t;
  final uri = Uri.tryParse(t);
  if (uri == null ||
      !uri.isAbsolute ||
      (uri.scheme != 'http' && uri.scheme != 'https')) {
    return '';
  }
  return uri.toString();
}

int? parseMediaDurationSecondsFromUrl(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return null;
  return int.tryParse(u.queryParameters['d'] ?? '');
}

(int?, int?) parseMediaWhFromUrl(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return (null, null);
  final w = int.tryParse(u.queryParameters['w'] ?? '');
  final h = int.tryParse(u.queryParameters['h'] ?? '');
  return (w, h);
}

String? parseVideoPosterPathFromUrl(String url) {
  final u = Uri.tryParse(url);
  final p = u?.queryParameters['p'];
  if (p == null || p.isEmpty) return null;
  return p;
}

String stripChatMediaDisplayQueryParams(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return url;
  final next = Map<String, String>.from(u.queryParameters);
  next.remove('d');
  next.remove('w');
  next.remove('h');
  next.remove('p');
  final stripped = u.replace(queryParameters: next).toString();
  return stripped.replaceFirst(RegExp(r'\?(?=#|$)'), '');
}

/// Image message envelope. Legacy messages keep using a plain URL in
/// [content]; newer captioned images use a versioned JSON object.
({String imageUrl, int? w, int? h, String caption}) parseImageForChat(
  String baseUrl,
  String content,
) {
  final trimmed = content.trim();
  if (trimmed.startsWith('{')) {
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        final source = decoded['url']?.toString().trim() ?? '';
        if (source.isNotEmpty) {
          return (
            imageUrl: resolveMediaUrl(baseUrl, source),
            w: int.tryParse(decoded['w']?.toString() ?? ''),
            h: int.tryParse(decoded['h']?.toString() ?? ''),
            caption: decoded['caption']?.toString().trim() ?? '',
          );
        }
      }
    } catch (_) {}
  }

  final imageUrl = resolveMediaUrl(baseUrl, trimmed);
  final dimensions = parseMediaWhFromUrl(imageUrl);
  return (
    imageUrl: imageUrl,
    w: dimensions.$1,
    h: dimensions.$2,
    caption: '',
  );
}

String encodeImageForChat({
  required String storedUrl,
  required String caption,
  int? w,
  int? h,
}) {
  final normalizedCaption = caption.trim();
  if (normalizedCaption.isEmpty && w == null && h == null) return storedUrl;
  final payload = <String, dynamic>{
    'v': 1,
    'url': stripChatMediaDisplayQueryParams(storedUrl),
    if (w != null) 'w': w,
    if (h != null) 'h': h,
    if (normalizedCaption.isNotEmpty) 'caption': normalizedCaption,
  };
  return jsonEncode(payload);
}

({String playUrl, String? posterResolved, int? w, int? h}) parseVideoForChat(
  String baseUrl,
  String content,
) {
  final trimmed = content.trim();
  if (trimmed.startsWith('{')) {
    try {
      final m = jsonDecode(trimmed);
      if (m is Map) {
        final urlStr = m['url']?.toString() ?? '';
        if (urlStr.isNotEmpty) {
          final playUrl = resolveMediaUrl(baseUrl, urlStr);
          final pStr = m['p']?.toString();
          final posterResolved = (pStr != null && pStr.isNotEmpty)
              ? resolveMediaUrl(baseUrl, pStr)
              : null;
          final w0 = int.tryParse(m['w']?.toString() ?? '');
          final h0 = int.tryParse(m['h']?.toString() ?? '');
          return (
            playUrl: playUrl,
            posterResolved: posterResolved,
            w: w0,
            h: h0,
          );
        }
      }
    } catch (_) {}
  }

  final full = resolveMediaUrl(baseUrl, content);
  final pRel = parseVideoPosterPathFromUrl(full);
  final (w0, h0) = parseMediaWhFromUrl(full);
  final playUrl = stripChatMediaDisplayQueryParams(full);
  final posterResolved =
      (pRel != null && pRel.isNotEmpty) ? resolveMediaUrl(baseUrl, pRel) : null;
  return (
    playUrl: playUrl,
    posterResolved: posterResolved,
    w: w0,
    h: h0,
  );
}
