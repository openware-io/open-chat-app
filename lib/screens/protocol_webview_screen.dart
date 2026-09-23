import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../services/hybrid_bridge_contract.dart';
import '../services/hybrid_bridge_dispatcher.dart';
import '../services/hybrid_bridge_policy.dart';
import '../services/api_client.dart';
import '../core/app_environment.dart';
import '../core/open_automation_keys.dart';
import '../widgets/open_nav_bar.dart';

bool _platformSupportsProtocolWebView() {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// 注入到 WebView 的 JS 桥：容器（IM App）用自己的登录态出授权码，第三方 H5 拿 code 换 SaaS 登录态。
/// 对齐微信小程序模型：wx.login() <-> GVBridge.login()。
const String _gvBridgeScript = r'''
(function () {
  if (window.GVBridge && window.GVBridge.login) return;
  window.__gvBridgeCallbacks = {};
  window.__gvBridgeSeq = 0;
  window.GVBridge = {
    login: function (opts) {
      return new Promise(function (resolve, reject) {
        var id = ++window.__gvBridgeSeq;
        window.__gvBridgeCallbacks[id] = { resolve: resolve, reject: reject };
        var nonce = (opts && opts.nonce) || (String(id) + '-' + Date.now() + '-' + Math.random());
        GVBridgeNative.postMessage(JSON.stringify({
          id: String(id),
          method: 'login',
          params: {
            appId: (opts && opts.appId) || '',
            scope: (opts && opts.scope) || 'profile.basic',
            redirectUri: (opts && opts.redirectUri) || '',
            state: (opts && opts.state) || '',
            nonce: nonce
          },
          nonce: nonce
        }));
      });
    },
    exitApp: function () {
      return new Promise(function (resolve, reject) {
        var id = ++window.__gvBridgeSeq;
        window.__gvBridgeCallbacks[id] = { resolve: resolve, reject: reject };
        var nonce = String(id) + '-' + Date.now() + '-' + Math.random();
        GVBridgeNative.postMessage(JSON.stringify({
          id: String(id), method: 'exitApp', params: {}, nonce: nonce
        }));
      });
    }
  };
  window.__gvBridgeResolve = function (id, result) {
    var cb = window.__gvBridgeCallbacks[id];
    if (cb) { cb.resolve(result); delete window.__gvBridgeCallbacks[id]; }
  };
  window.__gvBridgeReject = function (id, err) {
    var cb = window.__gvBridgeCallbacks[id];
    if (cb) { cb.reject(err); delete window.__gvBridgeCallbacks[id]; }
  };
  window.__gvBridgeHandleResponse = function (response) {
    if (!response || !response.id) return;
    if (response.ok) window.__gvBridgeResolve(response.id, response.result);
    else window.__gvBridgeReject(response.id, response.error || { code: 'bridge_error' });
  };
})();
''';

/// 应用内打开协议类 H5；不支持内嵌 WebView 的平台改为系统浏览器。
class ProtocolWebViewScreen extends StatefulWidget {
  const ProtocolWebViewScreen({
    super.key,
    required this.title,
    required this.url,
    this.interceptScheme,
    this.imToken,
  });

  final String title;
  final String url;

  /// 非空时，WebView 导航到该 scheme（如 gvchat）会被拦截，
  /// 以完整 URL 作为 [open] 的返回值 pop 回调用方；否则保持原行为。
  final String? interceptScheme;

  /// IM 登录 JWT：供 GVBridge.login() 原生调用 /oauth/authorize 出授权码，绝不进入 H5 的 JS。
  final String? imToken;

  static Future<String?> open(
    BuildContext context, {
    required String title,
    required String url,
    String? interceptScheme,
    String? imToken,
    bool useRootNavigator = false,
  }) async {
    if (_platformSupportsProtocolWebView()) {
      if (!context.mounted) return null;
      final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
      return await navigator.push<String>(
        MaterialPageRoute<String>(
          builder: (_) => ProtocolWebViewScreen(
            title: title,
            url: url,
            interceptScheme: interceptScheme,
            imToken: imToken,
          ),
        ),
      );
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    return null;
  }

  @override
  State<ProtocolWebViewScreen> createState() => _ProtocolWebViewScreenState();
}

class _ProtocolWebViewScreenState extends State<ProtocolWebViewScreen> {
  late final WebViewController _controller;
  late final HybridBridgeDispatcher _bridgeDispatcher;
  var _loading = true;

  /// 最近一次顶层导航完成的 URL（F1：桥能力与安全判定一律基于“当前页”而非初始 widget.url）。
  Uri? _currentPage;
  bool _bridgeRejectedOnce = false;

  Uri? get _currentUri => _currentPage ?? Uri.tryParse(widget.url);

  /// 当前页是否落在已登记（白名单）的 Hybrid Bridge 页面。
  HybridBridgePolicy? _currentPolicy() {
    final page = _currentUri;
    if (page == null) return null;
    return HybridBridgePolicy.forPage(page);
  }

  /// 仅当页面已登记时才注入桥脚本；未登记页面不注入（避免把桥能力带给攻击者页）。
  void _injectBridgeIfAllowed(Uri? page) {
    if (page != null && HybridBridgePolicy.forPage(page) != null) {
      _controller.runJavaScript(_gvBridgeScript);
    }
  }

  /// F1 导航白名单：桥模式下仅放行已登记页面自身的初始/同前缀导航；
  /// 其它目标一律阻止（不把授权码回调带出可信域）。
  bool _isNavigationAllowed(String url) {
    final initial = Uri.tryParse(widget.url);
    final base = HybridBridgePolicy.forPage(initial ?? Uri());
    if (widget.imToken == null || widget.imToken!.isEmpty || base == null) {
      // 非桥模式：保持原行为（interceptScheme 逻辑在下方处理）。
      return true;
    }
    final target = Uri.tryParse(url);
    if (target == null) return false;
    if (HybridBridgePolicy.forPage(target) != null) return true;
    final testOrigin = _debugTestOriginValue;
    final allowedHost = Uri.parse(base.origin).host;
    final isTestTarget = testOrigin != null && target.origin == testOrigin;
    final secure = target.scheme == 'https' || isTestTarget;
    return secure &&
        target.host == allowedHost &&
        (target.path == base.redirectPath ||
            target.path.startsWith(base.redirectPath) ||
            // OAuth 授权运行时路径（/oauth/authorize、/oauth/consent）在同源网关下，
            // 放行后 B 端桥失败时可回退到 H5 的 /oauth/authorize 重定向，避免卡死。
            target.path.startsWith('/oauth/'));
  }

  @override
  void initState() {
    super.initState();
    _bridgeDispatcher = HybridBridgeDispatcher(
      handlers: {'login': _handleLogin, 'exitApp': _handleExitApp},
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'GVBridgeNative',
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            final page = Uri.tryParse(url);
            _injectBridgeIfAllowed(page);
          },
          onPageFinished: (url) {
            final page = Uri.tryParse(url);
            _currentPage = page;
            _injectBridgeIfAllowed(page);
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            final scheme = widget.interceptScheme;
            if (scheme != null &&
                scheme.isNotEmpty &&
                uri != null &&
                uri.scheme == scheme) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop(request.url);
              });
              return NavigationDecision.prevent;
            }
            if (_isNavigationAllowed(request.url)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// 每次桥消息都按“当前页”重新校验：页面离开白名单后即使通道被调用也拒绝。
  Future<void> _onBridgeMessage(JavaScriptMessage message) async {
    final policy = _currentPolicy();
    if (policy == null) {
      if (!_bridgeRejectedOnce) {
        _bridgeRejectedOnce = true;
        await _controller.runJavaScript(
          'window.__gvBridgeHandleResponse('
          '${jsonEncode({
                'id': null,
                'ok': false,
                'error': {'code': 'bridge_unavailable'},
              })});',
        );
      }
      return;
    }
    final response = await _bridgeDispatcher.dispatch(message.message);
    await _controller.runJavaScript(
      'window.__gvBridgeHandleResponse(${jsonEncode(response)});',
    );
  }

  Future<dynamic> _handleLogin(HybridBridgeRequest request) async {
    final page = _currentUri;
    final policy = page == null ? null : HybridBridgePolicy.forPage(page);
    if (policy == null) throw StateError('Bridge 来源未登记或已离开白名单');
    final appId = request.params['appId']?.toString() ?? '';
    final scope = request.params['scope']?.toString() ?? 'profile.basic';
    final redirectUri = request.params['redirectUri']?.toString() ?? '';
    final state = request.params['state']?.toString() ?? '';
    final nonce = request.params['nonce']?.toString() ?? request.nonce;
    if (nonce != request.nonce) throw StateError('Bridge nonce 不一致');
    final requestedRedirect = Uri.tryParse(redirectUri);
    if (requestedRedirect == null ||
        !policy.accepts(
          requestedAppId: appId,
          scope: scope,
          redirectUri: requestedRedirect,
        )) {
      throw StateError('Bridge 请求未登记');
    }
    return _authorize(
      appId: appId,
      scope: scope,
      redirectUri: redirectUri,
      state: state,
      nonce: nonce,
    );
  }

  Future<dynamic> _handleExitApp(HybridBridgeRequest request) async {
    if (mounted) Navigator.of(context).pop();
    return true;
  }

  /// 原生完成 OAuth 授权码：PKCE + 用 App 自己的 JWT 调 /oauth/authorize，拿到 code 返回给 H5。
  Future<Map<String, String>> _authorize({
    required String appId,
    required String scope,
    required String redirectUri,
    required String state,
    required String nonce,
  }) async {
    final token = widget.imToken;
    if (token == null || token.isEmpty) {
      throw StateError('IM 登录态缺失');
    }
    if (appId.isEmpty) {
      throw StateError('缺少 appId');
    }
    if (redirectUri.isEmpty) {
      throw StateError('缺少 redirect_uri');
    }
    if (state.isEmpty || nonce.isEmpty) {
      throw StateError('缺少 OAuth state/nonce');
    }
    final target = Uri.tryParse(redirectUri);
    final page = _currentUri;
    final policy = page == null ? null : HybridBridgePolicy.forPage(page);
    if (target == null ||
        policy == null ||
        !policy.accepts(
          requestedAppId: appId,
          scope: scope,
          redirectUri: target,
        )) {
      throw StateError('redirect_uri 未登记或不安全');
    }
    final verifier = _randomString(64);
    final challenge = _base64url(sha256.convert(utf8.encode(verifier)).bytes);
    // OAuth 授权端点必须落在 H5 的 origin 上（miniservice 网关），
    // 与 H5 自身的 /oauth/authorize 跳转、consent 回调保持一致；
    // 用 apiBase(api.dev.example.com) 会被网关拦成 401，导致 B 端卡在「验证授权中」。
    final dio = Dio(
      BaseOptions(
        followRedirects: false,
        baseUrl: target.origin,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    late final Response<dynamic> resp;
    try {
      resp = await dio.get<dynamic>(
        '/oauth/authorize',
        queryParameters: {
          'client_id': appId,
          'response_type': 'code',
          'redirect_uri': redirectUri,
          'scope': scope,
          'code_challenge': challenge,
          'code_challenge_method': 'S256',
          'state': state,
          'nonce': nonce,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 400,
        ),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        if (mounted) context.read<ApiClient>().onUnauthorized?.call();
        throw const HybridBridgeException(
          'im_session_expired',
          'IM login session has expired',
        );
      }
      throw HybridBridgeException(
        'oauth_authorize_failed',
        'OAuth authorization failed: HTTP ${error.response?.statusCode ?? 'network'}',
      );
    }
    var location = resp.headers.value('location') ?? '';
    var code = _oauthCodeFromLocation(location);
    if (code.isEmpty) {
      final consentRequestId = _consentRequestIdFromLocation(location);
      if (consentRequestId.isEmpty) {
        throw StateError('授权码获取失败: HTTP ${resp.statusCode}');
      }
      final approval = await dio.post<dynamic>(
        '/oauth/consent/approve',
        queryParameters: {'request_id': consentRequestId, 'scope': scope},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 400,
        ),
      );
      location = approval.headers.value('location') ?? '';
      code = _oauthCodeFromLocation(location);
    }
    if (code.isEmpty || _oauthStateFromLocation(location) != state) {
      throw StateError('OAuth state 校验失败');
    }
    return {
      'code': code,
      'code_verifier': verifier,
      'redirect_uri': redirectUri,
      'state': state,
      'nonce': nonce,
    };
  }

  String _randomString(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(
      length,
      (_) => chars[rng.nextInt(chars.length)],
    ).join();
  }

  String _base64url(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        key: GvAutomationKeys.protocolWebViewScreen,
        children: [
          GvNavBar(title: widget.title, showBack: true),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_loading) const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _oauthCodeFromLocation(String location) {
  return Uri.tryParse(location)?.queryParameters['code']?.trim() ?? '';
}

String _consentRequestIdFromLocation(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null || uri.path != '/oauth/consent') return '';
  return uri.queryParameters['request_id']?.trim() ?? '';
}

String _oauthStateFromLocation(String location) {
  return Uri.tryParse(location)?.queryParameters['state']?.trim() ?? '';
}

/// 与 HybridBridgePolicy 保持一致的联调测试 origin（仅 debug 且显式定义时启用）。
String? get _debugTestOriginValue {
  const value = String.fromEnvironment('OPEN_HYBRID_TEST_ORIGIN');
  if (AppEnvironment.isProduction || value.isEmpty) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) return null;
  return uri.origin;
}
