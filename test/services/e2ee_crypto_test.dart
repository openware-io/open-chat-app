import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/services/e2ee/e2ee_crypto.dart';

void main() {
  group('E2eeCrypto', () {
    test('X25519 ECDH: 双方各自推导出相同共享密钥', () async {
      final alice = await E2eeCrypto.generateKeyPair();
      final bob = await E2eeCrypto.generateKeyPair();

      final aliceShared = await E2eeCrypto.deriveSharedSecret(
        privateKeyBase64: alice.privateKeyBase64,
        peerPublicKeyBase64: bob.publicKeyBase64,
      );
      final bobShared = await E2eeCrypto.deriveSharedSecret(
        privateKeyBase64: bob.privateKeyBase64,
        peerPublicKeyBase64: alice.publicKeyBase64,
      );

      expect(
        base64Encode(aliceShared),
        base64Encode(bobShared),
        reason: 'ECDH 双方应得到相同共享密钥',
      );
      expect(aliceShared.length, 32);
    });

    test('AES-GCM 加密解密往返一致', () async {
      final alice = await E2eeCrypto.generateKeyPair();
      final bob = await E2eeCrypto.generateKeyPair();
      final shared = await E2eeCrypto.deriveSharedSecret(
        privateKeyBase64: alice.privateKeyBase64,
        peerPublicKeyBase64: bob.publicKeyBase64,
      );

      const plaintext = '你好，这是端到端加密消息 🔒';
      final ciphertext = await E2eeCrypto.encrypt(
        sharedSecret: shared,
        plaintext: plaintext,
      );

      // 密文不应含明文
      expect(ciphertext.contains('端到端'), isFalse);
      final decrypted = await E2eeCrypto.decrypt(
        sharedSecret: shared,
        ciphertextBase64: ciphertext,
      );
      expect(decrypted, plaintext);
    });

    test('错误密钥解密返回 null', () async {
      final alice = await E2eeCrypto.generateKeyPair();
      final bob = await E2eeCrypto.generateKeyPair();
      final mallory = await E2eeCrypto.generateKeyPair();

      final sharedAliceBob = await E2eeCrypto.deriveSharedSecret(
        privateKeyBase64: alice.privateKeyBase64,
        peerPublicKeyBase64: bob.publicKeyBase64,
      );
      final sharedAliceMallory = await E2eeCrypto.deriveSharedSecret(
        privateKeyBase64: alice.privateKeyBase64,
        peerPublicKeyBase64: mallory.publicKeyBase64,
      );

      final ciphertext = await E2eeCrypto.encrypt(
        sharedSecret: sharedAliceBob,
        plaintext: 'secret',
      );
      final wrongKey = await E2eeCrypto.decrypt(
        sharedSecret: sharedAliceMallory,
        ciphertextBase64: ciphertext,
      );
      expect(wrongKey, isNull);
    });

    test('安全码：两端同字段顺序计算结果一致且与服务端算法对齐', () {
      const pubA = 'AAAA-public-a'; // userA（userId 小者）公钥
      const pubB = 'BBBB-public-b'; // userB 公钥

      // 两端都从服务端取 userAPublicKey/userBPublicKey（同序字段）
      final aliceView = E2eeCrypto.computeSafeCode(pubA, pubB);
      final bobView = E2eeCrypto.computeSafeCode(pubA, pubB);

      expect(aliceView, bobView);
      expect(aliceView.split(' ').length, 8);
      expect(aliceView, matches(RegExp(r'^[0-9A-F]{2}( [0-9A-F]{2}){7}$')));
      // 与服务端 Java 实现 SHA-256("AAAA-public-a:BBBB-public-b") 前 8 字节一致
      expect(aliceView, 'A5 25 C5 30 63 58 86 A8');
    });

    test('密钥对公钥私钥不同且均可导出', () async {
      final pair = await E2eeCrypto.generateKeyPair();
      expect(pair.publicKeyBase64, isNotEmpty);
      expect(pair.privateKeyBase64, isNotEmpty);
      expect(pair.publicKeyBase64, isNot(pair.privateKeyBase64));
    });

    test('逐成员加密：同一份明文对两个成员各加密，各自共享密钥可解回同一明文', () async {
      final me = await E2eeCrypto.generateKeyPair();
      final memberA = await E2eeCrypto.generateKeyPair();
      final memberB = await E2eeCrypto.generateKeyPair();

      const payload = '{"t":"text","c":"群聊机密"}';
      final sharedA = await E2eeCrypto.deriveSharedSecret(
        privateKeyBase64: me.privateKeyBase64,
        peerPublicKeyBase64: memberA.publicKeyBase64,
      );
      final sharedB = await E2eeCrypto.deriveSharedSecret(
        privateKeyBase64: me.privateKeyBase64,
        peerPublicKeyBase64: memberB.publicKeyBase64,
      );

      final cipherA = await E2eeCrypto.encrypt(
        sharedSecret: sharedA,
        plaintext: payload,
      );
      final cipherB = await E2eeCrypto.encrypt(
        sharedSecret: sharedB,
        plaintext: payload,
      );

      // 同一明文逐成员加密产生不同密文（nonce 不同/密钥不同）。
      expect(cipherA, isNot(cipherB));

      // 成员 A 用「自己私钥 + 发送方公钥」派生共享密钥解密。
      final decryptedByA = await E2eeCrypto.decrypt(
        sharedSecret: await E2eeCrypto.deriveSharedSecret(
          privateKeyBase64: memberA.privateKeyBase64,
          peerPublicKeyBase64: me.publicKeyBase64,
        ),
        ciphertextBase64: cipherA,
      );
      // 成员 B 同理。
      final decryptedByB = await E2eeCrypto.decrypt(
        sharedSecret: await E2eeCrypto.deriveSharedSecret(
          privateKeyBase64: memberB.privateKeyBase64,
          peerPublicKeyBase64: me.publicKeyBase64,
        ),
        ciphertextBase64: cipherB,
      );

      expect(decryptedByA, payload);
      expect(decryptedByB, payload);
    });
  });
}
