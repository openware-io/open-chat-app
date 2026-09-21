import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as legacy;
import 'package:cryptography/cryptography.dart';

/// E2EE 加密原语封装：X25519 密钥协商 + AES-GCM 消息加解密 + 安全码指纹。
///
/// 设计约束：
/// - 私钥只存在本机，绝不上报服务端；服务端仅登记公钥与设备指纹。
/// - 共享密钥由双方公钥经 X25519 ECDH 推导，两端本地各自计算，服务端不可见。
/// - 安全码 = SHA-256(公钥A:公钥B) 前 8 字节十六进制（与服务端展示指纹一致，
///   真加密后由客户端本地计算并与服务端比对）。
class E2eeCrypto {
  E2eeCrypto._();

  static final X25519 _x25519 = X25519();
  static final AesGcm _aesGcm = AesGcm.with256bits();
  static final Random _secureRandom = Random.secure();

  /// 生成一对 X25519 密钥（base64 编码，用于持久化与上报）。
  static Future<E2eeKeyPair> generateKeyPair() async {
    final keyPair = await _x25519.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKey = await keyPair.extractPrivateKeyBytes();
    return E2eeKeyPair(
      publicKeyBase64: base64Encode(publicKey.bytes),
      privateKeyBase64: base64Encode(privateKey),
    );
  }

  /// 由本端私钥 + 对端公钥推导共享密钥（X25519 ECDH）。
  ///
  /// cryptography 包 `newKeyPairFromSeed` 的 seed 即私钥字节（X25519 私钥即 32 字节种子）。
  static Future<Uint8List> deriveSharedSecret({
    required String privateKeyBase64,
    required String peerPublicKeyBase64,
  }) async {
    final privateBytes = base64Decode(privateKeyBase64);
    final peerPublicBytes = base64Decode(peerPublicKeyBase64);
    final keyPair = await _x25519.newKeyPairFromSeed(privateBytes);
    final shared = await _x25519.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: SimplePublicKey(
        peerPublicBytes,
        type: KeyPairType.x25519,
      ),
    );
    return Uint8List.fromList(await shared.extractBytes());
  }

  /// AES-GCM 加密明文，返回 base64 密文（前缀 12 字节随机 nonce）。
  static Future<String> encrypt({
    required Uint8List sharedSecret,
    required String plaintext,
  }) async {
    final nonce = _randomBytes(12);
    final secretKey = SecretKey(sharedSecret);
    final box = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
      nonce: nonce,
    );
    final payload = BytesBuilder()
      ..add(nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return base64Encode(payload.toBytes());
  }

  /// AES-GCM 解密 base64 密文（nonce 前缀），失败返回 null。
  static Future<String?> decrypt({
    required Uint8List sharedSecret,
    required String ciphertextBase64,
  }) async {
    try {
      final payload = base64Decode(ciphertextBase64);
      if (payload.length < 12 + 16) return null;
      final nonce = payload.sublist(0, 12);
      final cipherText = payload.sublist(12, payload.length - 16);
      final mac = Mac(payload.sublist(payload.length - 16));
      final secretKey = SecretKey(sharedSecret);
      final clear = await _aesGcm.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: mac),
        secretKey: secretKey,
      );
      return utf8.decode(clear);
    } catch (_) {
      return null;
    }
  }

  /// 安全码：SHA-256(公钥A:公钥B) 前 8 字节，大写十六进制、空格分隔。
  ///
  /// 调用方必须传 `userAPublicKey`（userId 小者）在前、`userBPublicKey` 在后，
  /// 与服务端 `computeSafeCode` 的规范化拼接语义一致；两端从服务端取同序字段，
  /// 本地计算的安全码必然一致，可互相比对核验。
  static String computeSafeCode(String publicKeyA, String publicKeyB) {
    final digest = legacy.sha256.convert(utf8.encode('$publicKeyA:$publicKeyB'));
    final parts = <String>[];
    for (var i = 0; i < 8; i++) {
      parts.add(digest.bytes[i].toRadixString(16).padLeft(2, '0').toUpperCase());
    }
    return parts.join(' ');
  }

  static Uint8List _randomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return bytes;
  }
}

/// 密钥对（base64 编码）。
class E2eeKeyPair {
  const E2eeKeyPair({
    required this.publicKeyBase64,
    required this.privateKeyBase64,
  });

  final String publicKeyBase64;
  final String privateKeyBase64;
}
