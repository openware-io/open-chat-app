/// App 本地偏好设置边界。
///
/// Provider 只关心“当前选择是什么”，不直接读取 SharedPreferences /
/// LocalStorage 的 key，也不处理清空表示跟随系统这类持久化细节。
abstract interface class AppPreferencesRepository {
  String? get appLocaleCode;

  Future<void> setAppLocaleCode(String? code);

  String? get appThemeModeCode;

  Future<void> setAppThemeModeCode(String? code);

  bool get notificationsEnabled;

  Future<void> setNotificationsEnabled(bool enabled);
}
