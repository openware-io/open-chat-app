import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as legacy;
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// 私密聊天业务回归套件（tag=integration，默认不随 `flutter test` 运行）。
///
/// 覆盖历次生产事故场景，防止复发：
/// 1. 创建私密聊天字段名（userB）与后端契约一致
/// 2. 接收方 /secret-chats/mine 能看到发起方创建的会话（对方发现机制）
/// 3. 设置定时销毁字段名（policy）与后端契约一致
/// 4. 双端握手后安全码自动生成且双方一致
/// 5. 接收方离线时消息不销毁（destroyAt=null），上线已读后开始计时
/// 6. 加密发送 → 接收方拉取解密 → 明文一致
/// 7. 发送方拉取自己的消息不触发计时
///
/// 运行：flutter test test/integration/secret_chat_regression_test.dart --tags integration
void main() {
  test('私密聊天全业务链路（生产）', () async {
    await _runRegression();
  }, tags: ['integration'], timeout: const Timeout(Duration(minutes: 2)));
}

Future<void> _runRegression() async {
  const base = 'https://api.dev.example.com/api/v1';
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final userA = 'reg_a_$stamp';
  final userB = 'reg_b_$stamp';
  const password = 'Test@12345';

  final dioA = Dio(BaseOptions(baseUrl: base, connectTimeout: const Duration(seconds: 20)));
  final dioB = Dio(BaseOptions(baseUrl: base, connectTimeout: const Duration(seconds: 20)));

  // ── 1. 注册双方 ──
  final tokenA = await _register(dioA, userA, password);
  final tokenB = await _register(dioB, userB, password);
  dioA.options.headers['Authorization'] = 'Bearer $tokenA';
  dioB.options.headers['Authorization'] = 'Bearer $tokenB';
  debugPrint('✅ 双方注册');

  // ── 2. 设备密钥注册 ──
  final pairA = await _generatePair();
  final pairB = await _generatePair();
  await dioA.post('/device-keys', data: {'deviceId': 'dev-a-$stamp', 'publicKey': pairA.publicKey});
  await dioB.post('/device-keys', data: {'deviceId': 'dev-b-$stamp', 'publicKey': pairB.publicKey});
  debugPrint('✅ 设备密钥注册');

  // ── 3. A 创建私密聊天：字段必须是 userB（事故1）──
  final search = await dioA.get('/users/search', queryParameters: {'keyword': userB});
  final bUser = (search.data as List).firstWhere((u) => u['username'] == userB);
  final bId = (bUser['id'] as num).toInt();
  final chatResp = await dioA.post('/secret-chats', data: {'userB': bId});
  final chatId = (chatResp.data['id'] as num).toInt();
  expect(chatResp.data['userA'] != null && chatResp.data['userB'] != null, isTrue,
      reason: '创建私密聊天应返回 userA/userB（契约字段）');
  debugPrint('✅ 创建私密聊天 id=$chatId');

  // ── 4. 接收方发现机制：B 的 /secret-chats/mine 必须能看到 A 创建的会话（事故2）──
  final mine = await dioB.get('/secret-chats/mine');
  final found = (mine.data as List).where((s) => '${s['id']}' == '$chatId').toList();
  expect(found, isNotEmpty, reason: '接收方 /secret-chats/mine 必须能看到发起方创建的会话');
  debugPrint('✅ 接收方能看到私密会话');

  // ── 5. 设置定时销毁：字段必须是 policy（事故3）──
  final policyResp = await dioA.post('/secret-chats/$chatId/destroy-policy', data: {'policy': '30s'});
  expect(policyResp.data['destroyPolicy'], '30s', reason: '设置销毁策略应返回 destroyPolicy=30s');
  debugPrint('✅ 定时销毁策略 30s 设置成功');

  // ── 6. 双方握手，安全码自动生成且一致（事故4）──
  await dioA.post('/secret-chats/$chatId/handshake', data: {'publicKey': pairA.publicKey});
  await dioB.post('/secret-chats/$chatId/handshake', data: {'publicKey': pairB.publicKey});
  final chat = await dioA.get('/secret-chats/$chatId');
  expect(chat.data['handshakeState'], 'ready', reason: '双方提交公钥后握手应 ready');
  final serverSafeCode = chat.data['safeCode'] as String;
  final localSafeCode = _safeCode(
    chat.data['userAPublicKey'] as String,
    chat.data['userBPublicKey'] as String,
  );
  expect(serverSafeCode, localSafeCode, reason: '本地安全码应与服务端一致');
  expect(serverSafeCode.split(' ').length, 8, reason: '安全码应为 8 组十六进制');
  debugPrint('✅ 握手完成，安全码一致: $serverSafeCode');

  // ── 7. A 加密发送（此刻 B 尚未拉取 = 离线未读）──
  final plaintext = '回归消息-$stamp';
  final sharedA = await _deriveShared(pairA.privateKey, chat.data['userBPublicKey'] as String);
  final sharedB = await _deriveShared(pairB.privateKey, chat.data['userAPublicKey'] as String);
  final cipher = await _encrypt(sharedA, plaintext);
  final msgId = 'reg-msg-$stamp';
  await dioA.post('/secret-messages', data: {
    'secretChatId': chatId,
    'msgId': msgId,
    'ciphertext': cipher,
  });
  debugPrint('✅ A 已发送密文');

  // ── 8. 离线未读：B 未拉取前消息不销毁（事故5 前半）──
  final aView = await dioA.get('/secret-messages', queryParameters: {
    'secretChatId': chatId,
    'afterSeq': 0,
  });
  final aMsg = (aView.data as List).firstWhere((m) => m['msgId'] == msgId);
  expect(aMsg['destroyAt'], isNull, reason: '对方未读时 destroyAt 应为 null（未开始计时）');
  debugPrint('✅ 未读不销毁（destroyAt=null）');

  // ── 9. 接收方拉取 = 已读，开始计时 ──
  final bView = await dioB.get('/secret-messages', queryParameters: {
    'secretChatId': chatId,
    'afterSeq': 0,
  });
  final bMsg = (bView.data as List).firstWhere((m) => m['msgId'] == msgId);
  expect(bMsg['destroyAt'], isNotNull, reason: '接收方拉取后应设置 destroyAt（已读后计时）');
  // 解密验证明文一致（事故6）
  final decrypted = await _decrypt(sharedB, bMsg['ciphertext'] as String);
  expect(decrypted, plaintext, reason: 'B 解密应与明文一致');
  debugPrint('✅ B 已读开始计时，解密一致: "$decrypted"');

  // ── 10. 发送方拉取自己的消息不触发计时（事故7）──
  final aView2 = await dioA.get('/secret-messages', queryParameters: {
    'secretChatId': chatId,
    'afterSeq': 0,
  });
  final aMsg2 = (aView2.data as List).firstWhere((m) => m['msgId'] == msgId);
  expect(aMsg2['destroyAt'], isNotNull, reason: 'B 已读后 A 视角也能看到 destroyAt（同步删除）');

  // ── 11. 等待到期销毁（30s + 余量）──
  debugPrint('等待 36s 验证定时销毁...');
  await Future<void>.delayed(const Duration(seconds: 36));
  final after = await dioB.get('/secret-messages', queryParameters: {
    'secretChatId': chatId,
    'afterSeq': 0,
  });
  final afterMsg = (after.data as List).firstWhere((m) => m['msgId'] == msgId);
  expect(afterMsg['status'], 'destroyed', reason: '已读后计时到期应销毁');
  debugPrint('🎉 私密聊天全业务链路回归通过（含定时销毁）');
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
