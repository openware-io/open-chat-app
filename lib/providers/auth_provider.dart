import 'package:flutter/foundation.dart';
import 'package:open_core/open_core.dart';

import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository, this._socket);

  final AuthRepository _repository;
  final GvSocketClient _socket;

  /// 登录 / 登出后回调（用于同步远端配置等）。
  void Function()? onAuthenticatedChanged;

  /// 登出后清空聊天/好友/通话等内存态（由 [main] 注入），避免下一账号短暂沿用上一账号数据。
  Future<void> Function()? onLogoutMemoryClear;

  ImUser? user;

  bool get isLoggedIn => _repository.isLoggedIn;

  Future<void> hydrateFromDisk() async {
    final j = _repository.cachedUserJson;
    if (j != null) {
      user = ImUser.fromJson(j);
    }
    notifyListeners();
  }

  void initSocketIfNeeded() {
    final t = _repository.token;
    if (t != null && t.isNotEmpty) {
      _socket.connect(t);
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final session = await _repository.login(
        username: username,
        password: password,
      );
      user = session.user;
      _socket.connect(session.token);
      await refreshProfileSafely();
      notifyListeners();
      onAuthenticatedChanged?.call();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(
      String username, String password, String email, String nickname) async {
    await _repository.register(
      username: username,
      password: password,
      email: email,
      nickname: nickname,
    );
  }

  Future<void> fetchProfile() async {
    final u = await _repository.fetchProfile();
    user = u;
    notifyListeners();
  }

  /// 尝试从服务端刷新完整个人资料；失败时保留当前缓存，不阻断登录或冷启动。
  Future<void> refreshProfileSafely() async {
    try {
      await fetchProfile();
    } catch (error, stackTrace) {
      debugPrint('Failed to refresh current user profile: $error\n$stackTrace');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final u = await _repository.updateProfile(data);
    user = u;
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// 服务端注销账号并清空本地会话。
  Future<void> deleteAccount({required String password}) async {
    await _repository.deleteAccount(password: password);
    await logout();
  }

  Future<void> logout() async {
    await _repository.clearSession();
    _socket.disconnect();
    user = null;
    notifyListeners();
    if (onLogoutMemoryClear != null) {
      await onLogoutMemoryClear!();
    }
    onAuthenticatedChanged?.call();
  }

  String apiError(Object e) => _repository.apiError(e);
}
