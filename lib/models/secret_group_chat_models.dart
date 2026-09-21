import 'package:gv_core/gv_core.dart' show jsonInt, parseUtcDateTime;

import 'secret_chat_models.dart';

String? _optStr(Object? value) {
  final s = value == null ? '' : '$value'.trim();
  return s.isEmpty ? null : s;
}

/// 私密群聊成员（`SecretGroupChatResult.members` 数组项）。
///
/// [devicePublicKey] 为该成员设备提交的全局 X25519 公钥（与 1 对 1 私密聊天一致）；
/// 全员提交后 `safeCode` 才会由服务端生成。
class SecretGroupMember {
  const SecretGroupMember({
    required this.userId,
    this.devicePublicKey,
    this.joinedAt,
  });

  final int userId;
  final String? devicePublicKey;
  final DateTime? joinedAt;

  factory SecretGroupMember.fromJson(Map<String, dynamic> json) {
    String? optStr(Object? value) {
      final s = value == null ? '' : '$value'.trim();
      return s.isEmpty ? null : s;
    }

    return SecretGroupMember(
      userId: jsonInt(json['userId'] ?? json['user_id']) ?? 0,
      devicePublicKey:
          optStr(json['devicePublicKey'] ?? json['device_public_key']),
      joinedAt: parseUtcDateTime(json['joinedAt'] ?? json['joined_at']),
    );
  }
}

/// 私密群聊会话（`POST /secret-group-chats` / `GET /secret-group-chats/mine`）。
///
/// 逐成员 E2EE：群内每个非我成员各加密一份密文；[safeCode] 由服务端计算并下发，
/// 客户端仅展示不重算。
class SecretGroupChatInfo {
  const SecretGroupChatInfo({
    required this.id,
    this.ownerUserId,
    this.status = 'active',
    this.name,
    this.announcement,
    this.safeCode = '',
    this.destroyPolicy = SecretChatDestroyPolicy.off,
    this.anonymousEnabled = false,
    this.pinnedMsgId,
    this.pinnedAt,
    this.inviteToken,
    this.inviteExpiresAt,
    this.ownerOnlyPost = false,
    this.members = const [],
    this.createdBy,
    this.createdAt,
    this.updatedBy,
    this.updatedAt,
  });

  /// 私密群聊 id（聊天室 `peerId` 即该值）。
  final String id;

  /// 群主用户 id（创建者）。
  final int? ownerUserId;

  /// 会话状态（如 `active`）。
  final String status;

  /// 群名称（群主可设置；为空时客户端展示默认「私密群聊」）。
  final String? name;

  /// 群公告（群主可设置）。
  final String? announcement;

  /// 安全码（服务端计算，全员提交公钥前可能为 null → 归一化为空串）。
  final String safeCode;

  /// 定时销毁策略：`off` / `30s` / `5m` / `1h` / `1d`。
  final String destroyPolicy;

  /// 匿名发言：开启后群内消息发送者身份对成员隐藏（仅群主可见）。
  final bool anonymousEnabled;

  /// 置顶消息 msgId（仅群主可设置）。
  final String? pinnedMsgId;

  /// 置顶时间。
  final DateTime? pinnedAt;

  /// 邀请令牌（群主生成）。
  final String? inviteToken;

  /// 邀请过期时间。
  final DateTime? inviteExpiresAt;

  /// 仅群主可发言。
  final bool ownerOnlyPost;

  /// 群成员（含群主）。
  final List<SecretGroupMember> members;

  final int? createdBy;
  final DateTime? createdAt;
  final int? updatedBy;
  final DateTime? updatedAt;

  factory SecretGroupChatInfo.fromJson(Map<String, dynamic> json) {
    String str(Object? value) => value == null ? '' : '$value'.trim();

    final rawId =
        json['id'] ?? json['secretGroupId'] ?? json['secret_group_id'];
    final rawMembers = json['members'];
    final members = <SecretGroupMember>[];
    if (rawMembers is List) {
      for (final raw in rawMembers) {
        if (raw is Map) {
          members.add(
            SecretGroupMember.fromJson(Map<String, dynamic>.from(raw)),
          );
        }
      }
    }

    return SecretGroupChatInfo(
      id: rawId == null ? '' : '$rawId',
      ownerUserId: jsonInt(json['ownerUserId'] ?? json['owner_user_id']),
      status: str(json['status']).isEmpty ? 'active' : str(json['status']),
      name: _optStr(json['name']),
      announcement: _optStr(json['announcement']),
      safeCode: str(json['safeCode'] ?? json['safe_code']),
      destroyPolicy: SecretChatDestroyPolicy.normalize(
        json['destroyPolicy'] ?? json['destroy_policy'],
      ),
      anonymousEnabled: json['anonymousEnabled'] == true ||
          json['anonymous_enabled'] == true,
      pinnedMsgId: _optStr(json['pinnedMsgId'] ?? json['pinned_msg_id']),
      pinnedAt: parseUtcDateTime(json['pinnedAt'] ?? json['pinned_at']),
      inviteToken: _optStr(json['inviteToken'] ?? json['invite_token']),
      inviteExpiresAt:
          parseUtcDateTime(json['inviteExpiresAt'] ?? json['invite_expires_at']),
      ownerOnlyPost: json['ownerOnlyPost'] == true ||
          json['owner_only_post'] == true,
      members: members,
      createdBy: jsonInt(json['createdBy'] ?? json['created_by']),
      createdAt: parseUtcDateTime(json['createdAt'] ?? json['created_at']),
      updatedBy: jsonInt(json['updatedBy'] ?? json['updated_by']),
      updatedAt: parseUtcDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }
}
