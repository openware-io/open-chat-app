import 'package:gv_core/gv_core.dart' show jsonInt;

/// 频道详情（`GET /api/v1/channels/{id}` / 创建 / 我的频道）。
///
/// 后端字段名按 camelCase / snake_case 兼容读取，避免契约微调时静默丢字段。
class ChannelInfo {
  const ChannelInfo({
    required this.id,
    required this.name,
    this.description = '',
    this.code = '',
    this.ownerId,
    this.memberCount = 0,
    this.role = 'subscriber',
    this.subscribed = false,
  });

  /// 频道 id（会话列表中 `Conversation.id` / 聊天室 `peerId` 即该值）。
  final String id;
  final String name;
  final String description;

  /// 频道号（分享码）：分享/输入频道号订阅使用，全局唯一。
  final String code;

  /// 创建者用户 id；聊天页据此判定当前用户是否为管理员（可发布）。
  final int? ownerId;

  /// 订阅者/成员数。
  final int memberCount;

  /// 当前用户在本频道的角色：`owner` / `admin` / `subscriber`。
  final String role;

  /// 当前用户是否已订阅。
  final bool subscribed;

  bool get isOwner =>
      role.toLowerCase() == 'owner' || role.toLowerCase() == 'admin';

  factory ChannelInfo.fromJson(Map<String, dynamic> json) {
    String str(Object? value) => value == null ? '' : '$value'.trim();

    final rawId = json['id'] ?? json['channelId'] ?? json['channel_id'];
    final name = str(json['name'] ?? json['title']);
    final owner = jsonInt(json['ownerId']) ?? jsonInt(json['owner_id']);
    final memberCount = jsonInt(json['memberCount']) ??
        jsonInt(json['member_count']) ??
        jsonInt(json['subscriberCount']) ??
        0;
    final role = str(json['role'] ?? json['myRole'] ?? json['my_role']);
    final subscribed = json['subscribed'] is bool
        ? json['subscribed'] as bool
        : str(json['subscribed']).toLowerCase() == 'true';

    return ChannelInfo(
      id: rawId == null ? '' : '$rawId',
      name: name.isEmpty ? '频道' : name,
      description: str(json['announcement'] ?? json['description'] ?? json['intro']),
      code: str(json['code']),
      ownerId: owner,
      memberCount: memberCount,
      role: role.isEmpty ? 'subscriber' : role.toLowerCase(),
      subscribed: subscribed,
    );
  }
}
