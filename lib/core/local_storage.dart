import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:gv_core/gv_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_message_localizer.dart';

class LocalStorage implements GvSessionStore {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const tokenKey = 'im_token';
  static const userKey = 'im_user';

  /// B 端（SaaS 商户）账号 Token；与 C 端 im_token 分离，避免 B 端鉴权复用 C 端会话。
  static const bizTokenKey = 'biz_token';

  /// B 端经营上下文 Token（X-Tenant-Context，短期签名，30 分钟）。
  static const bizTenantContextKey = 'biz_tenant_context';

  /// 最近一次登录成功时使用的 [AppConfig.apiBase]；与当前编译配置不一致时视为换服，应清会话。
  static const apiBaseAtLoginKey = 'im_api_base_at_login';

  /// 旧版未按用户隔离的 key，仅用于一次性迁移与彻底清理。
  static const convKeyLegacy = 'im_conversations';
  static const hiddenMsgKeyLegacy = 'im_hidden_messages';

  /// UI 语言：`zh` / `en`；未存储表示跟随系统。
  static const appLocaleKey = 'app_ui_locale';

  /// 界面浅/深色：`light` / `dark`；未存储表示跟随系统。
  static const appThemeModeKey = 'app_ui_theme_mode';

  /// 租户币种快照（`CNY` / `USD`）：仅作启动兜底展示，唯一权威仍为服务端响应。
  static const currencyCodeKey = 'app_currency_code';

  /// 是否接收极光推送；旧版本未存储时保持原行为（默认开启）。
  static const notificationsEnabledKey = 'push_notifications_enabled';
  static const clientReleaseInstallationIdKey =
      'client_release_installation_id';

  String? get clientReleaseInstallationId =>
      _prefs.getString(clientReleaseInstallationIdKey);
  Future<void> setClientReleaseInstallationId(String value) =>
      _prefs.setString(clientReleaseInstallationIdKey, value);

  @override
  String? get token => _prefs.getString(tokenKey);

  @override
  Future<void> setToken(String? v) async {
    if (v == null || v.isEmpty) {
      await _prefs.remove(tokenKey);
    } else {
      await _prefs.setString(tokenKey, v);
    }
  }

  /// B 端账号 Token（未设置返回 null）。
  String? get bizToken => _prefs.getString(bizTokenKey);

  Future<void> setBizToken(String? v) async {
    if (v == null || v.isEmpty) {
      await _prefs.remove(bizTokenKey);
    } else {
      await _prefs.setString(bizTokenKey, v);
    }
  }

  /// B 端经营上下文 Token（未设置返回 null）。
  String? get bizTenantContext => _prefs.getString(bizTenantContextKey);

  Future<void> setBizTenantContext(String? v) async {
    if (v == null || v.isEmpty) {
      await _prefs.remove(bizTenantContextKey);
    } else {
      await _prefs.setString(bizTenantContextKey, v);
    }
  }

  @override
  Map<String, dynamic>? get userJson {
    final s = _prefs.getString(userKey);
    if (s == null || s.isEmpty) return null;
    try {
      return jsonDecode(s) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setUserJson(Map<String, dynamic>? u) async {
    if (u == null) {
      await _prefs.remove(userKey);
    } else {
      await _prefs.setString(userKey, jsonEncode(u));
    }
  }

  /// 租户币种快照（`CNY` / `USD`）；未存储表示尚未从服务端拿到，按默认 USD 展示。
  String? get currencyCode => _prefs.getString(currencyCodeKey);

  Future<void> setCurrencyCode(String? v) async {
    if (v == null || v.isEmpty) {
      await _prefs.remove(currencyCodeKey);
    } else {
      await _prefs.setString(currencyCodeKey, v);
    }
  }

  /// 当前会话用户 id（字符串），未登录为 null。
  String? get _sessionUserIdString {
    final j = userJson;
    if (j == null) return null;
    final id = j['id'];
    if (id == null) return null;
    final s = id.toString().trim();
    return s.isEmpty ? null : s;
  }

  String _conversationsKeyForUser(String uid) => 'im_conversations_$uid';

  String _hiddenKeyForUser(String uid) => 'im_hidden_messages_$uid';

  /// 各会话「已看到」的消息时间上界（`chatType:peerId` -> ISO8601），用于冷启动/重放时不重复加未读。
  String _chatReadWatermarksKeyForUser(String uid) =>
      'im_chat_read_watermarks_$uid';

  /// Local-only chat clearing cutoff (`chatType:peerId` -> ISO8601).
  String _chatLocalClearWatermarksKeyForUser(String uid) =>
      'im_chat_local_clear_watermarks_$uid';

  String _miniAppServicesKeyForUser(String uid) => 'im_mini_app_services_$uid';

  /// 小程序服务页列表 JSON 数组缓存（按当前登录用户隔离）。
  String? loadMiniAppServicesCacheRaw() {
    final uid = _sessionUserIdString;
    if (uid == null) return null;
    final s = _prefs.getString(_miniAppServicesKeyForUser(uid));
    if (s == null || s.isEmpty) return null;
    return s;
  }

  Future<void> saveMiniAppServicesCacheRaw(String json) async {
    final uid = _sessionUserIdString;
    if (uid == null) return;
    await _prefs.setString(_miniAppServicesKeyForUser(uid), json);
  }

  String _pinnedMiniAppsKeyForUser(String uid) => 'im_pinned_mini_apps_$uid';

  /// 用户固定（置顶）的服务项快照列表，按登录用户隔离。
  List<dynamic> loadPinnedMiniAppsRaw() {
    final uid = _sessionUserIdString;
    if (uid == null) return [];
    final s = _prefs.getString(_pinnedMiniAppsKeyForUser(uid));
    if (s == null || s.isEmpty) return [];
    try {
      final v = jsonDecode(s);
      return v is List ? v : [];
    } catch (_) {
      return [];
    }
  }

  Future<void> savePinnedMiniAppsRaw(List<dynamic> list) async {
    final uid = _sessionUserIdString;
    if (uid == null) return;
    await _prefs.setString(_pinnedMiniAppsKeyForUser(uid), jsonEncode(list));
  }

  String _miniAppServiceOrdersKeyForUser(String uid) =>
      'im_mini_app_service_orders_$uid';

  /// 服务分类内的自定义排序（分类名 -> 服务 id 列表），按登录用户隔离。
  String? loadMiniAppServiceOrdersRaw() {
    final uid = _sessionUserIdString;
    if (uid == null) return null;
    final s = _prefs.getString(_miniAppServiceOrdersKeyForUser(uid));
    if (s == null || s.isEmpty) return null;
    return s;
  }

  Future<void> saveMiniAppServiceOrdersRaw(String json) async {
    final uid = _sessionUserIdString;
    if (uid == null) return;
    await _prefs.setString(_miniAppServiceOrdersKeyForUser(uid), json);
  }

  /// 将旧的全局 key 迁入当前用户专属 key（仅当专属 key 尚为空时执行一次）。
  Future<void> migrateLegacyUnscopedChatKeysIfNeeded() async {
    final uid = _sessionUserIdString;
    if (uid == null) return;

    final ck = _conversationsKeyForUser(uid);
    if ((_prefs.getString(ck) ?? '').isEmpty) {
      final leg = _prefs.getString(convKeyLegacy);
      if (leg != null && leg.isNotEmpty) {
        await _prefs.setString(ck, leg);
        await _prefs.remove(convKeyLegacy);
      }
    }

    final hk = _hiddenKeyForUser(uid);
    if ((_prefs.getString(hk) ?? '').isEmpty) {
      final hLeg = _prefs.getString(hiddenMsgKeyLegacy);
      if (hLeg != null && hLeg.isNotEmpty) {
        await _prefs.setString(hk, hLeg);
        await _prefs.remove(hiddenMsgKeyLegacy);
      }
    }
  }

  /// 仅结束登录态，不删除按用户隔离的会话列表与隐藏消息（`im_conversations_$uid` 等），
  /// 否则切换账号再切回时消息页会话列表会一直为空。
  @override
  Future<void> clearSession() async {
    await _prefs.remove(tokenKey);
    await _prefs.remove(userKey);
    await _prefs.remove(apiBaseAtLoginKey);
    // 旧版未分用户的 key 仍清掉，避免被下一账号的 migrate 误迁入。
    await _prefs.remove(convKeyLegacy);
    await _prefs.remove(hiddenMsgKeyLegacy);
  }

  @override
  String? get apiBaseAtLogin => _prefs.getString(apiBaseAtLoginKey);

  @override
  Future<void> setApiBaseAtLogin(String base) async {
    await _prefs.setString(apiBaseAtLoginKey, base);
  }

  List<dynamic> loadConversationsRaw() {
    final uid = _sessionUserIdString;
    if (uid == null) return [];
    final s = _prefs.getString(_conversationsKeyForUser(uid));
    if (s == null || s.isEmpty) return [];
    try {
      final v = jsonDecode(s);
      return v is List ? v : [];
    } catch (_) {
      return [];
    }
  }

  Future<void> saveConversationsRaw(List<dynamic> list) async {
    final uid = _sessionUserIdString;
    if (uid == null) return;
    await _prefs.setString(_conversationsKeyForUser(uid), jsonEncode(list));
  }

  Map<String, dynamic> loadHiddenMessagesMap() {
    final uid = _sessionUserIdString;
    if (uid == null) return {};
    final s = _prefs.getString(_hiddenKeyForUser(uid));
    if (s == null || s.isEmpty) return {};
    try {
      final v = jsonDecode(s);
      return v is Map<String, dynamic> ? v : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveHiddenMessagesMap(Map<String, dynamic> map) async {
    final uid = _sessionUserIdString;
    if (uid == null) return;
    await _prefs.setString(_hiddenKeyForUser(uid), jsonEncode(map));
  }

  Map<String, DateTime> loadChatReadWatermarks() {
    final uid = _sessionUserIdString;
    if (uid == null) return {};
    final s = _prefs.getString(_chatReadWatermarksKeyForUser(uid));
    if (s == null || s.isEmpty) return {};
    try {
      final v = jsonDecode(s);
      if (v is! Map) return {};
      final out = <String, DateTime>{};
      for (final e in v.entries) {
        final parsed = DateTime.tryParse(e.value.toString());
        if (parsed != null) out[e.key.toString()] = parsed;
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveChatReadWatermarks(Map<String, DateTime> map) async {
    final uid = _sessionUserIdString;
    if (uid == null) return;
    final json = <String, String>{};
    for (final e in map.entries) {
      json[e.key] = e.value.toIso8601String();
    }
    await _prefs.setString(
        _chatReadWatermarksKeyForUser(uid), jsonEncode(json));
  }

  Map<String, DateTime> loadChatLocalClearWatermarks() {
    final uid = _sessionUserIdString;
    if (uid == null) return {};
    final s = _prefs.getString(_chatLocalClearWatermarksKeyForUser(uid));
    if (s == null || s.isEmpty) return {};
    try {
      final value = jsonDecode(s);
      if (value is! Map) return {};
      final result = <String, DateTime>{};
      for (final entry in value.entries) {
        final parsed = DateTime.tryParse(entry.value.toString());
        if (parsed != null) result[entry.key.toString()] = parsed;
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  Future<void> saveChatLocalClearWatermarks(
    Map<String, DateTime> map,
  ) async {
    final uid = _sessionUserIdString;
    if (uid == null) return;
    final json = <String, String>{};
    for (final entry in map.entries) {
      json[entry.key] = entry.value.toIso8601String();
    }
    await _prefs.setString(
      _chatLocalClearWatermarksKeyForUser(uid),
      jsonEncode(json),
    );
  }

  /// 已保存的界面语言：`zh`、`en`，未设置则为 null（跟随系统）。
  @override
  String? get appLocaleCode => _prefs.getString(appLocaleKey);

  /// 写入 `zh` / `en`；传入 `null` 或 `system` 则清除（跟随系统）。
  @override
  Future<void> setAppLocaleCode(String? code) async {
    if (code == null || code.isEmpty || code == 'system') {
      await _prefs.remove(appLocaleKey);
      return;
    }
    if (code == 'zh' || code == 'en') {
      await _prefs.setString(appLocaleKey, code);
    }
  }

  /// 已保存的外观主题：`light`、`dark`，未设置则为 null（跟随系统）。
  @override
  String? get appThemeModeCode => _prefs.getString(appThemeModeKey);

  /// 写入 `light` / `dark`；传入 `null` 则清除（跟随系统）。
  @override
  Future<void> setAppThemeModeCode(String? code) async {
    if (code == null || code.isEmpty) {
      await _prefs.remove(appThemeModeKey);
      return;
    }
    if (code == 'light' || code == 'dark') {
      await _prefs.setString(appThemeModeKey, code);
    }
  }

  bool get notificationsEnabled =>
      _prefs.getBool(notificationsEnabledKey) ?? true;

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(notificationsEnabledKey, enabled);
  }

  /// 供 HTTP `x-lang` 使用，与服务端 nestjs-i18n 一致。
  ///
  /// 同时同步给 [api_message_localizer]，供没有 BuildContext 的调用方
  /// （如 ApiFailure.messageOf）按同一语言翻译服务端文案。
  @override
  String resolveApiLanguageCode() {
    final c = _prefs.getString(appLocaleKey);
    if (c == 'zh' || c == 'en') {
      setApiMessageZhLocale(c == 'zh');
      return c!;
    }
    final lang = PlatformDispatcher.instance.locale.languageCode;
    final zh = lang.startsWith('zh');
    setApiMessageZhLocale(zh);
    return zh ? 'zh' : 'en';
  }
}
