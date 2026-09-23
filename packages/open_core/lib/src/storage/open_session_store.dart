abstract interface class GvSessionStore {
  String? get token;

  Future<void> setToken(String? value);

  Map<String, dynamic>? get userJson;

  Future<void> setUserJson(Map<String, dynamic>? user);

  String? get apiBaseAtLogin;

  Future<void> setApiBaseAtLogin(String base);

  Future<void> clearSession();

  String? get appLocaleCode;

  Future<void> setAppLocaleCode(String? code);

  String? get appThemeModeCode;

  Future<void> setAppThemeModeCode(String? code);

  String resolveApiLanguageCode();
}
