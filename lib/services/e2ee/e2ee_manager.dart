import 'package:shared_preferences/shared_preferences.dart';

import '../../models/secret_chat_models.dart';
import '../../models/secret_group_chat_models.dart';
import '../im_api.dart';
import 'e2ee_crypto.dart';
import 'e2ee_session_store.dart';

/// E2EE 编排管理器：设备密钥注册、会话握手、共享密钥推导、消息加解密。
///
/// 职责边界：
/// - 只管 E2EE 密钥与密文转换，不负责消息列表/UI（由 ChatProvider 调用）。
/// - 所有本地密钥经 [E2eeSessionStore] 持久化，服务端仅见公钥与密文。
class E2eeManager {
  E2eeManager({
    required ImApi imApi,
    required SharedPreferences preferences,
  }) : _imApi = imApi,
       _store = E2eeSessionStore(preferences);

  final ImApi _imApi;
  final E2eeSessionStore _store;

  /// 已完成群握手（全员提交公钥）的私密群聊 id 集合。
  final Set<String> _readyGroups = <String>{};

  /// 确保本设备密钥对已生成并注册到服务端；返回本端公钥。
  Future<String> ensureDeviceKey({required String deviceId}) async {
    final existingPublic = _store.publicKeyBase64;
    if (existingPublic != null && existingPublic.isNotEmpty) {
      return existingPublic;
    }
    final pair = await E2eeCrypto.generateKeyPair();
    await _store.saveKeyPair(
      deviceId: deviceId,
      publicKeyBase64: pair.publicKeyBase64,
      privateKeyBase64: pair.privateKeyBase64,
    );
    await _imApi.registerDeviceKey(
      deviceId: deviceId,
      publicKey: pair.publicKeyBase64,
    );
    return pair.publicKeyBase64;
  }

  /// 私密会话握手：提交本端公钥并拉取会话详情（含对端公钥/安全码）。
  ///
  /// 双方都提交后会话 ready，返回带双方公钥的会话信息。
  Future<SecretChatInfo> handshake(String secretChatId, {required String deviceId}) async {
    final myPublicKey =
        await ensureDeviceKey(deviceId: deviceId);
    var info = await _imApi.submitSecretChatHandshake(
      id: secretChatId,
      publicKey: myPublicKey,
    );
    // 服务端返回的会话若未含双方公钥，再拉取一次详情（覆盖双方均提交的场景）。
    if (info.userAPublicKey == null || info.userBPublicKey == null) {
      info = await _imApi.secretChatInfo(secretChatId);
    }
    await _deriveAndPersistSecret(info);
    return info;
  }

  /// 对已有会话尝试建立共享密钥（不抛异常；未 ready 时返回 false）。
  Future<bool> tryEstablishSecret(SecretChatInfo info) async {
    if (info.userAPublicKey == null || info.userBPublicKey == null) {
      return false;
    }
    await _deriveAndPersistSecret(info);
    return true;
  }

  /// 本端视角的安全码：与服务端展示一致时握手有效。
  String? localSafeCode(SecretChatInfo info) {
    if (info.userAPublicKey == null || info.userBPublicKey == null) return null;
    return E2eeCrypto.computeSafeCode(
      info.userAPublicKey!,
      info.userBPublicKey!,
    );
  }

  /// 加密明文为密文；会话未握手或无私钥时返回 null。
  Future<String?> encryptForChat(String secretChatId, String plaintext) async {
    final shared = _store.sharedSecretFor(secretChatId);
    final privateKey = _store.privateKeyBase64;
    if (shared == null || privateKey == null) return null;
    return E2eeCrypto.encrypt(sharedSecret: shared, plaintext: plaintext);
  }

  /// 解密密文；失败（密钥不匹配/被篡改）返回 null。
  Future<String?> decryptFromChat(String secretChatId, String ciphertext) async {
    final shared = _store.sharedSecretFor(secretChatId);
    if (shared == null) return null;
    return E2eeCrypto.decrypt(sharedSecret: shared, ciphertextBase64: ciphertext);
  }

  bool hasSharedSecret(String secretChatId) =>
      _store.sharedSecretFor(secretChatId) != null;

  String? safeCodeFor(String secretChatId) => _store.safeCodeFor(secretChatId);

  // ─── 私密群聊：逐成员 E2EE ───

  /// 私密群聊握手：提交本端公钥，拉回含成员公钥的群信息并派生各成员共享密钥。
  Future<SecretGroupChatInfo> secretGroupHandshake(
    String groupId, {
    required String deviceId,
  }) async {
    final myPublicKey = await ensureDeviceKey(deviceId: deviceId);
    var info = await _imApi.submitSecretGroupHandshake(
      id: groupId,
      publicKey: myPublicKey,
    );
    // 服务端返回的群信息若仍缺成员公钥，再拉一次详情（覆盖全员提交场景）。
    if (!_groupMembersHaveKeys(info)) {
      info = await _imApi.secretGroupChatInfo(groupId);
    }
    await tryEstablishGroup(info);
    return info;
  }

  /// 对已有群信息尝试建立各成员共享密钥（不抛异常；未全员 ready 时返回 false）。
  Future<bool> tryEstablishGroup(SecretGroupChatInfo info) async {
    await _deriveGroupSecrets(info);
    final ready = _groupMembersHaveKeys(info);
    if (ready) {
      _readyGroups.add(info.id);
    }
    return ready;
  }

  /// 加密同一份明文给群内指定成员；未建立共享密钥返回 null。
  Future<String?> encryptForGroupMember(
    String groupId,
    int peerUserId,
    String plaintext,
  ) async {
    final shared = _store.groupSharedSecretFor(groupId, peerUserId);
    if (shared == null) return null;
    return E2eeCrypto.encrypt(sharedSecret: shared, plaintext: plaintext);
  }

  /// 用「我的私钥 + 发送方公钥」派生共享密钥解密；失败返回 null。
  Future<String?> decryptFromGroupMember(
    String groupId,
    int senderUserId,
    String ciphertext,
  ) async {
    final shared = _store.groupSharedSecretFor(groupId, senderUserId);
    if (shared == null) return null;
    return E2eeCrypto.decrypt(sharedSecret: shared, ciphertextBase64: ciphertext);
  }

  /// 群是否已完成全员握手（可发送/接收）。
  bool groupReady(String groupId) => _readyGroups.contains(groupId);

  Future<void> clearForAccount() async {
    _readyGroups.clear();
    await _store.clearForAccount();
  }

  bool _groupMembersHaveKeys(SecretGroupChatInfo info) =>
      info.members.isNotEmpty &&
      info.members.every((m) => (m.devicePublicKey ?? '').isNotEmpty);

  Future<void> _deriveGroupSecrets(SecretGroupChatInfo info) async {
    final privateKey = _store.privateKeyBase64;
    final myPublic = _store.publicKeyBase64;
    if (privateKey == null || myPublic == null) return;
    for (final member in info.members) {
      final peerPublic = member.devicePublicKey;
      if (peerPublic == null || peerPublic.isEmpty) continue;
      // 跳过自己（本端公钥），避免给自己派生无意义的共享密钥。
      if (peerPublic == myPublic) continue;
      final shared = await E2eeCrypto.deriveSharedSecret(
        privateKeyBase64: privateKey,
        peerPublicKeyBase64: peerPublic,
      );
      await _store.saveGroupSharedSecret(info.id, member.userId, shared);
    }
  }

  Future<void> _deriveAndPersistSecret(SecretChatInfo info) async {
    final privateKey = _store.privateKeyBase64;
    final a = info.userAPublicKey;
    final b = info.userBPublicKey;
    if (privateKey == null || a == null || b == null) return;
    final myPublic = _store.publicKeyBase64;
    final peerPublic = myPublic == a ? b : a;
    final shared = await E2eeCrypto.deriveSharedSecret(
      privateKeyBase64: privateKey,
      peerPublicKeyBase64: peerPublic,
    );
    await _store.saveSharedSecret(info.id, shared);
    final localSafeCode = E2eeCrypto.computeSafeCode(a, b);
    await _store.saveSafeCode(info.id, localSafeCode);
  }
}

/// 密文消息（服务端返回形态，供 ChatProvider 解密接入）。
class SecretMessageWire {
  const SecretMessageWire({
    required this.secretChatId,
    required this.msgId,
    required this.fromUserId,
    required this.ciphertext,
    required this.seq,
    required this.status,
    this.destroyAt,
    this.createdAt,
  });

  factory SecretMessageWire.fromJson(Map<String, dynamic> json) {
    return SecretMessageWire(
      secretChatId: (json['secretChatId'] ?? json['secret_chat_id']).toString(),
      msgId: (json['msgId'] ?? json['msg_id']).toString(),
      fromUserId: int.tryParse(
            (json['fromUserId'] ?? json['from_user_id']).toString(),
          ) ??
          0,
      ciphertext: (json['ciphertext'] ?? '').toString(),
      seq: int.tryParse((json['seq'] ?? '0').toString()) ?? 0,
      status: (json['status'] ?? 'active').toString(),
      destroyAt: json['destroyAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  final String secretChatId;
  final String msgId;
  final int fromUserId;
  final String ciphertext;
  final int seq;
  final String status;
  final String? destroyAt;
  final String? createdAt;
}
