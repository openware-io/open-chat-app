import '../core/local_storage.dart';
import 'app_preferences_repository.dart';

/// 基于 [LocalStorage] 的本地偏好实现。
class LocalAppPreferencesRepository implements AppPreferencesRepository {
  LocalAppPreferencesRepository(this._storage);

  final LocalStorage _storage;

  @override
  String? get appLocaleCode => _storage.appLocaleCode;

  @override
  Future<void> setAppLocaleCode(String? code) =>
      _storage.setAppLocaleCode(code);

  @override
  String? get appThemeModeCode => _storage.appThemeModeCode;

  @override
  Future<void> setAppThemeModeCode(String? code) =>
      _storage.setAppThemeModeCode(code);

  @override
  bool get notificationsEnabled => _storage.notificationsEnabled;

  @override
  Future<void> setNotificationsEnabled(bool enabled) =>
      _storage.setNotificationsEnabled(enabled);
}
