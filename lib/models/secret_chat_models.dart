import 'package:gv_core/gv_core.dart' show jsonInt, parseUtcDateTime;

/// 私密聊天销毁策略取值（与后端 `destroy_policy` 契约一致）。
abstract final class SecretChatDestroyPolicy {
  static const String off = 'off';
  static const String s1 = '1s';
  static const String s2 = '2s';
  static const String s5 = '5s';
  static const String s10 = '10s';
  static const String s30 = '30s';
  static const String m1 = '1m';
  static const String m5 = '5m';
  static const String h1 = '1h';
  static const String d1 = '1d';
  static const String w1 = '1w';

  static const List<String> all = [off, s1, s2, s5, s10, s30, m1, m5, h1, d1, w1];

  /// 归一化后端可能返回的变体（如 `30_SECONDS` / `30_sec`）为契约值。
  static String normalize(Object? value) {
    final raw = '$value'.trim().toLowerCase().replaceAll('_', '');
    return switch (raw) {
      '' || 'null' => off,
      'off' || 'none' || 'disabled' => off,
      '1s' || '1sec' || '1second' => s1,
      '2s' || '2sec' || '2seconds' => s2,
      '5s' || '5sec' || '5seconds' => s5,
      '10s' || '10sec' || '10seconds' => s10,
      '30s' || '30sec' || '30seconds' => s30,
      '1m' || '1min' || '1minute' || '60s' => m1,
      '5m' || '5min' || '5minutes' => m5,
      '1h' || '1hour' || '60m' => h1,
      '1d' || '1day' || '24h' => d1,
      '1w' || '1week' || '7d' => w1,
      _ => off,
    };
  }
}

/// 私密聊天会话（`POST /api/v1/secret-chats` / `GET /api/v1/secret-chats/mine`）。
///
/// 形态先行：`safeCode` 为服务端生成的安全码（真 E2EE 后改为双方公钥指纹本地计算）。
class SecretChatInfo {
  const SecretChatInfo({
    required this.id,
    this.peerUserId,
    this.safeCode = '',
    this.destroyPolicy = SecretChatDestroyPolicy.off,
    this.userAPublicKey,
    this.userBPublicKey,
    this.handshakeState,
    this.createdAt,
  });

  /// 私密会话 id（聊天室 `peerId` 即该值）。
  final String id;

  /// 对端用户 id（会话名由此回填）。
  final int? peerUserId;

  /// 安全码/指纹；查看页展示并支持复制。
  final String safeCode;

  /// 定时销毁策略：`off` / `30s` / `5m` / `1h` / `1d`。
  final String destroyPolicy;

  /// E2EE 握手：userA/userB 公钥（base64），齐备后客户端本地推导共享密钥。
  final String? userAPublicKey;
  final String? userBPublicKey;

  /// 握手状态：`pending` / `ready`。
  final String? handshakeState;

  final DateTime? createdAt;

  factory SecretChatInfo.fromJson(Map<String, dynamic> json) {
    String str(Object? value) => value == null ? '' : '$value'.trim();

    final rawId = json['id'] ?? json['secretChatId'] ?? json['secret_chat_id'];
    final peer = jsonInt(json['peerUserId']) ??
        jsonInt(json['peer_user_id']) ??
        jsonInt(json['userId']) ??
        jsonInt(json['user_id']) ??
        jsonInt(json['otherUserId']) ??
        jsonInt(json['other_user_id']);
    String? optStr(Object? value) {
      final s = str(value);
      return s.isEmpty ? null : s;
    }

    return SecretChatInfo(
      id: rawId == null ? '' : '$rawId',
      peerUserId: peer,
      safeCode: str(json['safeCode'] ?? json['safe_code']),
      destroyPolicy: SecretChatDestroyPolicy.normalize(
        json['destroyPolicy'] ?? json['destroy_policy'],
      ),
      userAPublicKey: optStr(json['userAPublicKey'] ?? json['user_a_public_key']),
      userBPublicKey: optStr(json['userBPublicKey'] ?? json['user_b_public_key']),
      handshakeState: optStr(json['handshakeState'] ?? json['handshake_state']),
      createdAt: parseUtcDateTime(
        json['createdAt'] ?? json['created_at'],
      ),
    );
  }
}
