import 'package:flutter/material.dart';

import '../repositories/app_preferences_repository.dart';

/// 界面语言状态。
///
/// 持久化细节由 [AppPreferencesRepository] 处理，Provider 只负责把选择转换为
/// [MaterialApp.locale] 需要的值。
class AppLocaleController extends ChangeNotifier {
  AppLocaleController(this._preferences);

  final AppPreferencesRepository _preferences;

  /// 与设置页选项值一致：清除存储表示跟随系统。
  static const followSystem = 'system';

  /// 传给 [MaterialApp.locale]：`null` 表示跟随系统。
  Locale? get materialLocale {
    final c = _preferences.appLocaleCode;
    if (c == 'zh') return const Locale('zh');
    if (c == 'en') return const Locale('en');
    return null;
  }

  /// 当前选项：`followSystem` / `zh` / `en`。
  String get selectedCode => _preferences.appLocaleCode ?? followSystem;

  Future<void> setLocaleCode(String code) async {
    await _preferences.setAppLocaleCode(
      code == followSystem ? null : code,
    );
    notifyListeners();
  }
}
