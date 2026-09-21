import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// E2EE 本地密钥仓库：持久化本机私钥与各私密会话的共享密钥。
///
/// 安全约束：
/// - 私钥/共享密钥仅存本机 SharedPreferences，绝不上报服务端。
/// - 会话共享密钥以 `会话id -> base64` 映射保存；私钥全局唯一（每设备一对）。
/// - 换账号（token 变化）时由上层调用 [clearForAccount] 隔离。
class E2eeSessionStore {
  E2eeSessionStore(this._prefs);

  final SharedPreferences _prefs;

  static const _privateKeyKey = 'e2ee_private_key';
  static const _publicKeyKey = 'e2ee_public_key';
  static const _deviceIdKey = 'e2ee_device_id';
  static const _sharedKeyPrefix = 'e2ee_shared_';
  static const _safeCodePrefix = 'e2ee_safe_code_';
  static const _groupSharedKeyPrefix = 'e2ee_group_shared_';

  String? get privateKeyBase64 => _prefs.getString(_privateKeyKey);
  String? get publicKeyBase64 => _prefs.getString(_publicKeyKey);
  String? get deviceId => _prefs.getString(_deviceIdKey);

  Future<void> saveKeyPair({
    required String deviceId,
    required String publicKeyBase64,
    required String privateKeyBase64,
  }) async {
    await _prefs.setString(_deviceIdKey, deviceId);
    await _prefs.setString(_publicKeyKey, publicKeyBase64);
    await _prefs.setString(_privateKeyKey, privateKeyBase64);
  }

  Future<void> saveSharedSecret(String secretChatId, Uint8List sharedSecret) async {
    await _prefs.setString(_sharedKeyPrefix + secretChatId, base64Encode(sharedSecret));
  }

  Uint8List? sharedSecretFor(String secretChatId) {
    final raw = _prefs.getString(_sharedKeyPrefix + secretChatId);
    if (raw == null || raw.isEmpty) return null;
    return Uint8List.fromList(base64Decode(raw));
  }

  Future<void> saveSafeCode(String secretChatId, String safeCode) async {
    await _prefs.setString(_safeCodePrefix + secretChatId, safeCode);
  }

  String? safeCodeFor(String secretChatId) {
    return _prefs.getString(_safeCodePrefix + secretChatId);
  }

  /// 按 (groupId, peerUserId) 保存私密群聊成员共享密钥，避免每次重算 X25519。
  Future<void> saveGroupSharedSecret(
    String groupId,
    int peerUserId,
    Uint8List sharedSecret,
  ) async {
    await _prefs.setString(
      '$_groupSharedKeyPrefix${groupId}_$peerUserId',
      base64Encode(sharedSecret),
    );
  }

  Uint8List? groupSharedSecretFor(String groupId, int peerUserId) {
    final raw = _prefs.getString(
      '$_groupSharedKeyPrefix${groupId}_$peerUserId',
    );
    if (raw == null || raw.isEmpty) return null;
    return Uint8List.fromList(base64Decode(raw));
  }

  /// 清理本账号 E2EE 状态（退出登录 / 切换账号时调用）。
  Future<void> clearForAccount() async {
    final keys = _prefs.getKeys().where((key) =>
        key == _privateKeyKey ||
        key == _publicKeyKey ||
        key == _deviceIdKey ||
        key.startsWith(_sharedKeyPrefix) ||
        key.startsWith(_safeCodePrefix) ||
        key.startsWith(_groupSharedKeyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }
}
