import '../core/config.dart';
import '../core/local_storage.dart';
import '../models/im_user.dart';
import '../services/api_client.dart';
import '../services/im_api.dart';
import 'auth_repository.dart';

/// 基于现有 ImApi 的认证仓库实现。
///
/// 这一层是“适配器”：以后接口生成器、Mock 数据、离线缓存替换时，
/// AuthProvider 的代码不需要跟着改。
class ImAuthRepository implements AuthRepository {
  ImAuthRepository(this._storage, this._api, this._apiClient);

  final LocalStorage _storage;
  final ImApi _api;
  final ApiClient _apiClient;

  @override
  bool get isLoggedIn => (_storage.token ?? '').isNotEmpty;

  @override
  String? get token => _storage.token;

  @override
  Map<String, dynamic>? get cachedUserJson => _storage.userJson;

  @override
  Future<AuthenticatedSession> login({
    required String username,
    required String password,
  }) async {
    await _storage.setToken(null);
    final res = await _api.login(username: username, password: password);
    return _persistAuthenticatedResponse(res);
  }

  @override
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String nickname,
  }) async {
    await _storage.clearSession();
    await _api.register(
      username: username,
      password: password,
      email: email,
      nickname: nickname,
    );
  }

  @override
  Future<ImUser> fetchProfile() async {
    final user = await _api.getMe();
    await _storage.setUserJson(user.toJson());
    return user;
  }

  @override
  Future<ImUser> updateProfile(Map<String, dynamic> data) async {
    final user = await _api.updateMe(data);
    await _storage.setUserJson(user.toJson());
    return user;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _api.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<void> deleteAccount({required String password}) {
    return _api.deleteAccount(password: password);
  }

  @override
  Future<void> clearSession() => _storage.clearSession();

  @override
  String apiError(Object error) => _apiClient.extractErrorMessage(error);

  Future<AuthenticatedSession> _persistAuthenticatedResponse(
    Map<String, dynamic> res,
  ) async {
    final token =
        (res['accessToken'] ?? res['access_token'] ?? res['token'])?.toString();
    if (token == null || token.isEmpty) {
      throw StateError('登录响应缺少 accessToken');
    }
    final user = ImUser.fromJson(Map<String, dynamic>.from(res['user'] as Map));
    await _storage.setToken(token);
    await _storage.setUserJson(user.toJson());
    await _storage.setApiBaseAtLogin(AppConfig.apiBase);
    return AuthenticatedSession(token: token, user: user);
  }
}
