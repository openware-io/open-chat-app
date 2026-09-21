import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../core/config.dart';

/// IM 开放平台 OAuth 2.0（Authorization Code + PKCE）客户端骨架。
///
/// 对接 im-user-service 挂在网关上的 /oauth/** 与 /open/** 端点（无 /api 前缀、
/// 无 StripPrefix），用于「服务 Tab」KTV 入口的两层授权：
/// 应用级（种子应用 saas-ktv，脚手架直接 APPROVED）+ 用户级（本次 OAuth 授权）。
///
/// 注意：真实 SaaS KTV 业务 H5/深链尚未提供，本类仅覆盖授权链路骨架
/// （authorize -> token -> userinfo），后续接入业务时再扩展刷新/撤销。
class ImOAuthService {
  ImOAuthService({Dio? dio, String? apiBase})
      : _apiBase = apiBase ?? AppConfig.apiBase,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: apiBase ?? AppConfig.apiBase,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  final String _apiBase;
  final Dio _dio;

  /// 冻结契约：种子应用（Flyway/启动引导直接 APPROVED）。
  static const String appId = 'saas-ktv';

  static const String redirectUri = 'gvchat://oauth/callback';
  static const String scope = 'profile.basic';

  /// PKCE unreserved 字符集：A-Z a-z 0-9 - . _ ~。
  static const String _verifierCharset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  /// 生成 PKCE code_verifier（43~128 个 unreserved 字符）。
  String generateCodeVerifier({int length = 64}) {
    final rng = Random.secure();
    final codeUnits = List<int>.generate(
      length,
      (_) => _verifierCharset.codeUnitAt(rng.nextInt(_verifierCharset.length)),
    );
    return String.fromCharCodes(codeUnits);
  }

  /// S256 挑战：base64url(sha256(ascii(code_verifier)))，并去掉填充 '='。
  String codeChallenge(String codeVerifier) {
    final digest = sha256.convert(utf8.encode(codeVerifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// 生成随机 state（防 CSRF）。
  String generateState() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// GET /oauth/authorize 的完整 URL，交给 WebView 打开。
  String buildAuthorizeUrl({
    required String codeVerifier,
    required String state,
    String? nonce,
  }) {
    return Uri.parse('$_apiBase/oauth/authorize').replace(
      queryParameters: {
        'client_id': appId,
        'response_type': 'code',
        'redirect_uri': redirectUri,
        'scope': scope,
        'state': state,
        'code_challenge': codeChallenge(codeVerifier),
        'code_challenge_method': 'S256',
        'nonce': nonce ?? generateState(),
      },
    ).toString();
  }

  /// 从回调地址（gvchat://oauth/callback?code=...&state=...）解析 code/state。
  ({String? code, String? state}) parseRedirect(String redirect) {
    final uri = Uri.tryParse(redirect);
    if (uri == null) return (code: null, state: null);
    return (
      code: uri.queryParameters['code'],
      state: uri.queryParameters['state'],
    );
  }

  /// POST /oauth/token：code + code_verifier 换取 access_token。
  ///
  /// 字段名遵循冻结契约；body 采用与 App 其余接口一致的 JSON 编码。
  Future<ImOAuthToken> exchangeCode({
    required String code,
    required String codeVerifier,
  }) async {
    final response = await _dio.post<dynamic>(
      '/oauth/token',
      data: {
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': codeVerifier,
        'client_id': appId,
        'redirect_uri': redirectUri,
      },
    );
    return ImOAuthToken.fromJson(_asMap(response.data));
  }

  /// GET /oauth/userinfo：Bearer access_token 换取用户信息（open_id 等）。
  Future<ImOAuthUserInfo> fetchUserInfo(String accessToken) async {
    final response = await _dio.get<dynamic>(
      '/oauth/userinfo',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return ImOAuthUserInfo.fromJson(_asMap(response.data));
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nested = map['data'];
      if (nested is Map) return Map<String, dynamic>.from(nested);
      return map;
    }
    return <String, dynamic>{};
  }
}

/// /oauth/token 响应。
class ImOAuthToken {
  const ImOAuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.openId,
    required this.scope,
  });

  factory ImOAuthToken.fromJson(Map<String, dynamic> json) {
    return ImOAuthToken(
      accessToken:
          (json['access_token'] ?? json['accessToken'])?.toString() ?? '',
      refreshToken:
          (json['refresh_token'] ?? json['refreshToken'])?.toString() ?? '',
      expiresIn: _asInt(json['expires_in'] ?? json['expiresIn']),
      openId: (json['open_id'] ?? json['openId'])?.toString() ?? '',
      scope: json['scope']?.toString() ?? '',
    );
  }

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String openId;
  final String scope;

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }
}

/// /oauth/userinfo 响应。
class ImOAuthUserInfo {
  const ImOAuthUserInfo({
    required this.openId,
    required this.nickname,
    required this.avatar,
    required this.phone,
  });

  factory ImOAuthUserInfo.fromJson(Map<String, dynamic> json) {
    return ImOAuthUserInfo(
      openId: (json['open_id'] ?? json['openId'])?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  final String openId;
  final String nickname;
  final String avatar;
  final String phone;
}
