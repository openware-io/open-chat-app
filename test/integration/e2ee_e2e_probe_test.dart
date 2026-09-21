import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as legacy;
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// E2EE 端到端集成探针（tag=integration，默认不随 `flutter test` 运行）。
///
/// 两个虚拟设备走真实生产链路：注册设备密钥 → 创建私密会话 → 双方握手 →
/// A 加密发消息 → B 拉取解密 → 安全码比对。
///
/// 运行：flutter test test/integration/e2ee_e2e_probe_test.dart --tags integration
void main() {
  test('E2EE 端到端链路（生产）', () async {
    await _runProbe();
  }, tags: ['integration']);
}

Future<void> _runProbe() async {
  const base = 'https://api.dev.example.com/api/v1';
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final userA = 'e2ee_a_$stamp';
  final userB = 'e2ee_b_$stamp';
  const password = 'Test@12345';
  final dioA = Dio(BaseOptions(baseUrl: base, connectTimeout: const Duration(seconds: 20)));
  final dioB = Dio(BaseOptions(baseUrl: base, connectTimeout: const Duration(seconds: 20)));

  // 1. 注册两个用户
  final tokenA = await _register(dioA, userA, password);
  final tokenB = await _register(dioB, userB, password);
  dioA.options.headers['Authorization'] = 'Bearer $tokenA';
  dioB.options.headers['Authorization'] = 'Bearer $tokenB';
  debugPrint('✅ 用户注册: A=$userA B=$userB');

  // 2. 各自生成密钥对并注册设备密钥
  final pairA = await _generatePair();
  final pairB = await _generatePair();
  final devA = 'dev-$stamp-a';
  final devB = 'dev-$stamp-b';
  await dioA.post('/device-keys', data: {'deviceId': devA, 'publicKey': pairA.publicKey});
  await dioB.post('/device-keys', data: {'deviceId': devB, 'publicKey': pairB.publicKey});
  debugPrint('✅ 设备密钥注册完成');

  // 3. A 创建私密会话（找 B 的 userId）
  final search = await dioA.get('/users/search', queryParameters: {'keyword': userB});
  final bUser = (search.data as List).firstWhere((u) => u['username'] == userB);
  final bId = (bUser['id'] as num).toInt();
  final chatResp = await dioA.post('/secret-chats', data: {'userB': bId});
  final chatId = (chatResp.data['id'] as num).toInt();
  debugPrint('✅ 私密会话创建: id=$chatId');

  // 4. 双方握手：各自提交公钥
  await dioA.post('/secret-chats/$chatId/handshake', data: {'publicKey': pairA.publicKey});
  await dioB.post('/secret-chats/$chatId/handshake', data: {'publicKey': pairB.publicKey});
  final chat = await dioA.get('/secret-chats/$chatId');
  final userAPub = chat.data['userAPublicKey'] as String;
  final userBPub = chat.data['userBPublicKey'] as String;
  final serverSafeCode = chat.data['safeCode'] as String;
  debugPrint('✅ 握手完成 state=${chat.data['handshakeState']}');

  // 5. 各自本地推导共享密钥 + 计算安全码
  final sharedA = await _deriveShared(pairA.privateKey, userBPub);
  final sharedB = await _deriveShared(pairB.privateKey, userAPub);
  final localSafeCode = _safeCode(userAPub, userBPub);
  expect(_b64(sharedA), _b64(sharedB), reason: '双方共享密钥应一致');
  debugPrint('✅ 双方共享密钥一致（${sharedA.length} bytes）');
  debugPrint('   服务端安全码: $serverSafeCode');
  debugPrint('   本地安全码:   $localSafeCode');
  expect(serverSafeCode, localSafeCode, reason: '本地安全码应与服务端核验一致');

  // 6. A 加密发消息 → B 拉取解密
  final plaintext = '这是端到端加密的私密消息 🔒 secret-$stamp';
  final cipher = await _encrypt(sharedA, plaintext);
  final msgId = 'e2ee-msg-$stamp';
  await dioA.post('/secret-messages', data: {
    'secretChatId': chatId,
    'msgId': msgId,
    'ciphertext': cipher,
  });
  debugPrint('✅ A 已加密发送（密文长度 ${cipher.length}）');

  final list = await dioB.get('/secret-messages', queryParameters: {
    'secretChatId': chatId,
    'afterSeq': 0,
    'limit': 50,
  });
  final items = (list.data as List).where((m) => m['msgId'] == msgId).toList();
  expect(items, isNotEmpty, reason: 'B 应能拉到密文');
  final decrypted = await _decrypt(sharedB, items.first['ciphertext'] as String);
  expect(decrypted, plaintext, reason: 'B 解密应与明文一致');
  debugPrint('✅ B 拉取并解密成功: "$decrypted"');
  debugPrint('🎉 E2EE 端到端链路全部验证通过');
}

Future<String> _register(Dio dio, String username, String password) async {
  try {
    final resp = await dio.post('/auth/register', data: {
      'username': username,
      'password': password,
      'nickname': username,
    });
    return (resp.data['access_token'] as String);
  } catch (_) {
    final resp = await dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    return (resp.data['access_token'] as String);
  }
}

Future<_Pair> _generatePair() async {
  final x = X25519();
  final kp = await x.newKeyPair();
  final pub = await kp.extractPublicKey();
  final priv = await kp.extractPrivateKeyBytes();
  return _Pair(_b64(pub.bytes), _b64(priv));
}

Future<Uint8List> _deriveShared(String privateB64, String peerPublicB64) async {
  final x = X25519();
  final kp = await x.newKeyPairFromSeed(base64Decode(privateB64));
  final shared = await x.sharedSecretKey(
    keyPair: kp,
    remotePublicKey: SimplePublicKey(base64Decode(peerPublicB64), type: KeyPairType.x25519),
  );
  return Uint8List.fromList(await shared.extractBytes());
}

Future<String> _encrypt(Uint8List shared, String plaintext) async {
  final aes = AesGcm.with256bits();
  final nonce = _randomBytes(12);
  final box = await aes.encrypt(
    utf8.encode(plaintext),
    secretKey: SecretKey(shared),
    nonce: nonce,
  );
  final payload = BytesBuilder()
    ..add(nonce)
    ..add(box.cipherText)
    ..add(box.mac.bytes);
  return base64Encode(payload.toBytes());
}

Future<String?> _decrypt(Uint8List shared, String cipherB64) async {
  try {
    final payload = base64Decode(cipherB64);
    if (payload.length < 28) return null;
    final aes = AesGcm.with256bits();
    final nonce = payload.sublist(0, 12);
    final cipherText = payload.sublist(12, payload.length - 16);
    final mac = Mac(payload.sublist(payload.length - 16));
    final clear = await aes.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: mac),
      secretKey: SecretKey(shared),
    );
    return utf8.decode(clear);
  } catch (_) {
    return null;
  }
}

String _safeCode(String pubA, String pubB) {
  final digest = legacy.sha256.convert(utf8.encode('$pubA:$pubB'));
  final parts = <String>[];
  for (var i = 0; i < 8; i++) {
    parts.add(digest.bytes[i].toRadixString(16).padLeft(2, '0').toUpperCase());
  }
  return parts.join(' ');
}

Uint8List _randomBytes(int n) {
  final bytes = Uint8List(n);
  final now = DateTime.now().microsecondsSinceEpoch;
  for (var i = 0; i < n; i++) {
    bytes[i] = ((now >> (i % 24)) & 0xFF);
  }
  return bytes;
}

String _b64(List<int> bytes) => base64Encode(bytes);

class _Pair {
  _Pair(this.publicKey, this.privateKey);
  final String publicKey;
  final String privateKey;
}
