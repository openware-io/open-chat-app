import '../models/im_user.dart';

/// 登录领域的统一入口。
///
/// Provider 只关心“当前用户状态如何变化”，token 落盘、接口响应解析、
/// 错误文案转换等基础设施细节都收敛到 Repository。
abstract interface class AuthRepository {
  bool get isLoggedIn;

  String? get token;

  Map<String, dynamic>? get cachedUserJson;

  Future<AuthenticatedSession> login({
    required String username,
    required String password,
  });

  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String nickname,
  });

  Future<ImUser> fetchProfile();

  Future<ImUser> updateProfile(Map<String, dynamic> data);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> deleteAccount({required String password});

  Future<void> clearSession();

  String apiError(Object error);
}

class AuthenticatedSession {
  const AuthenticatedSession({
    required this.token,
    required this.user,
  });

  final String token;
  final ImUser user;
}
