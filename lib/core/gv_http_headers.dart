import 'local_storage.dart';
import 'config.dart';

/// 与 [ApiClient] 一致的 Bearer，用于 [VideoPlayer]、[VideoThumbnail] 等原生 HTTP 请求。
Map<String, String>? gvBearerHeaders(LocalStorage storage) {
  final t = storage.token;
  if (t == null || t.isEmpty) return null;
  return {'Authorization': 'Bearer $t'};
}

/// Managed media URLs are already authorized by their signed query string.
/// Sending the app Bearer token as well makes MinIO reject the request as
/// conflicting authentication.
Map<String, String>? gvMediaRequestHeaders(
  String url,
  Map<String, String>? appHeaders, {
  String managedMediaBase = AppConfig.mediaBase,
}) {
  if (appHeaders == null || appHeaders.isEmpty) return null;
  final target = Uri.tryParse(url);
  final managed = Uri.tryParse(managedMediaBase);
  if (target == null || managed == null) return appHeaders;
  final isManagedOrigin = target.hasScheme &&
      target.scheme.toLowerCase() == managed.scheme.toLowerCase() &&
      target.host.toLowerCase() == managed.host.toLowerCase() &&
      target.port == managed.port;
  return isManagedOrigin ? null : appHeaders;
}
