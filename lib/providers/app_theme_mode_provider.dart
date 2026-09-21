import 'package:flutter/material.dart';

import '../repositories/app_preferences_repository.dart';

/// 界面浅/深色状态。
///
/// 持久化细节由 [AppPreferencesRepository] 处理，Provider 只负责暴露 UI 所需
/// 的 [ThemeMode] 和选中项。
class AppThemeModeController extends ChangeNotifier {
  AppThemeModeController(this._preferences);

  final AppPreferencesRepository _preferences;

  /// 与设置页选项值一致：清除存储表示跟随系统。
  static const followSystem = 'system';

  /// 传给 [MaterialApp.themeMode]。
  ThemeMode get themeMode {
    final c = _preferences.appThemeModeCode;
    if (c == 'light') return ThemeMode.light;
    if (c == 'dark') return ThemeMode.dark;
    return ThemeMode.system;
  }

  /// 当前选项：`followSystem` / `light` / `dark`。
  String get selectedCode => _preferences.appThemeModeCode ?? followSystem;

  Future<void> setThemeModeCode(String code) async {
    await _preferences.setAppThemeModeCode(
      code == followSystem ? null : code,
    );
    notifyListeners();
  }
}
