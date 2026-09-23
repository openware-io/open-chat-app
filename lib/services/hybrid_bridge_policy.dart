import '../core/app_environment.dart';

class HybridBridgePolicy {
  const HybridBridgePolicy._({
    required this.appId,
    required this.origin,
    required this.redirectPath,
    required this.scopes,
  });

  final String appId;
  final String origin;
  final String redirectPath;
  final Set<String> scopes;

  static const _testOrigin = String.fromEnvironment('OPEN_HYBRID_TEST_ORIGIN');

  static Map<String, HybridBridgePolicy> get _policies {
    final origin = _debugTestOrigin ?? 'https://miniservice.dev.example.com';
    return <String, HybridBridgePolicy>{
      'saas-a380-c': HybridBridgePolicy._(
        appId: 'saas-a380-c',
        origin: origin,
        redirectPath: '/a380/',
        scopes: {'profile.basic'},
      ),
      'saas-a380-h5': HybridBridgePolicy._(
        appId: 'saas-a380-h5',
        origin: origin,
        redirectPath: '/b/',
        scopes: {'profile.basic'},
      ),
    };
  }

  static String? get _debugTestOrigin {
    // 测试包也必须以 release 方式签名安装到真机；不能依赖 kDebugMode。
    // 生产包即使被误传 dart-define，也绝不能把桥暴露给 HTTP origin。
    if (AppEnvironment.isProduction || _testOrigin.isEmpty) return null;
    final uri = Uri.tryParse(_testOrigin);
    if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
    return uri.origin;
  }

  static HybridBridgePolicy? forPage(Uri page) {
    final testOrigin = _debugTestOrigin;
    final isTestPage = testOrigin != null && page.origin == testOrigin;
    if ((page.scheme != 'https' && !isTestPage) ||
        page.host.isEmpty ||
        (!isTestPage && page.port != 0 && page.port != 443)) {
      return null;
    }
    for (final policy in _policies.values) {
      if (Uri.parse(policy.origin).host == page.host &&
          pathMatches(page.path, policy.redirectPath)) {
        return policy;
      }
    }
    return null;
  }

  /// 路径匹配：容忍静态托管的常见形态，避免「页面能打开但拿不到桥」。
  ///
  /// 此前用的是**完全相等**（`page.path == redirectPath`），于是 `/b`（缺尾斜杠）、
  /// `/b/index.html`（静态托管默认文档）都匹配不上 → 策略返回 null → 不给桥 →
  /// H5 侧一直停在「登录授权中」（A380 运营后台进不去的典型现象）。
  static bool pathMatches(String path, String redirectPath) {
    if (path == redirectPath) return true;
    final normalized = path.endsWith('/') ? path : '$path/';
    if (normalized == redirectPath) return true;
    // /b/index.html、/b/index.htm、/b/default.html 等默认文档
    final prefix = redirectPath.endsWith('/')
        ? redirectPath.substring(0, redirectPath.length - 1)
        : redirectPath;
    final lower = normalized.toLowerCase();
    return lower == '$prefix/index.html' ||
        lower == '$prefix/index.htm' ||
        lower == '$prefix/default.html';
  }

  bool accepts({
    required String requestedAppId,
    required String scope,
    required Uri redirectUri,
  }) {
    final isTestRedirect =
        _debugTestOrigin != null && redirectUri.origin == _debugTestOrigin;
    return requestedAppId == appId &&
        scopes.contains(scope) &&
        (redirectUri.scheme == 'https' || isTestRedirect) &&
        redirectUri.host == Uri.parse(origin).host &&
        (isTestRedirect || redirectUri.port == 0 || redirectUri.port == 443) &&
        pathMatches(redirectUri.path, redirectPath) &&
        redirectUri.query.isEmpty &&
        redirectUri.fragment.isEmpty;
  }
}
