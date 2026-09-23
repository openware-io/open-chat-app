import 'package:freezed_annotation/freezed_annotation.dart';

import '../json/json_int.dart';

part 'friend_models.freezed.dart';
part 'friend_models.g.dart';

// ignore_for_file: invalid_annotation_target

Object? _readFriendId(Map<dynamic, dynamic> json, String key) =>
    json['friend_id'] ?? json['friendId'];

Object? _readUserId(Map<dynamic, dynamic> json, String key) =>
    json['user_id'] ?? json['userId'];

Object? _readFromUserId(Map<dynamic, dynamic> json, String key) =>
    json['from_user_id'] ?? json['fromUserId'];

Object? _readToUserId(Map<dynamic, dynamic> json, String key) =>
    json['to_user_id'] ?? json['toUserId'];

Object? _readGroupName(Map<dynamic, dynamic> json, String key) =>
    json['group_name'] ?? json['groupName'];

Object? _readFriendUser(Map<dynamic, dynamic> json, String key) {
  final embedded = json['friendUser'] ?? json['friend_user'];
  if (embedded is Map) return embedded;

  final friendId = json['friendId'] ?? json['friend_id'];
  final username = json['friendUsername'] ?? json['friend_username'];
  final nickname = json['friendNickname'] ?? json['friend_nickname'];
  final avatar = json['friendAvatar'] ?? json['friend_avatar'];
  final signature = json['friendSignature'] ?? json['friend_signature'];
  if (friendId == null &&
      username == null &&
      nickname == null &&
      avatar == null &&
      signature == null) {
    return null;
  }
  return {
    'id': friendId ?? 0,
    'username': username ?? '',
    'nickname': nickname,
    'avatar': avatar,
    'signature': signature,
  };
}

Map<String, dynamic>? _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

int _jsonIntOrZero(dynamic value) => jsonInt(value) ?? 0;

FriendUserBrief? _friendUserFromJson(Object? value) {
  final map = _asStringMap(value);
  return map == null ? null : FriendUserBrief.fromApiJson(map);
}

/// 好友相关接口中的用户摘要。
///
/// 标准 JSON 序列化由生成器负责，[fromApiJson] 额外兼容空对象和历史字段。
@freezed
abstract class FriendUserBrief with _$FriendUserBrief {
  const FriendUserBrief._();

  const factory FriendUserBrief({
    @JsonKey(fromJson: _jsonIntOrZero) required int id,
    @Default('') String username,
    String? nickname,
    String? avatar,
    String? signature,
  }) = _FriendUserBrief;

  factory FriendUserBrief.fromJson(Map<String, dynamic> json) =>
      _$FriendUserBriefFromJson(json);

  factory FriendUserBrief.fromApiJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const FriendUserBrief(id: 0);
    }
    final normalized = Map<String, dynamic>.from(json)
      ..putIfAbsent('id', () => 0);
    return FriendUserBrief.fromJson(normalized);
  }
}

/// 好友列表条目。
///
/// API 兼容 snake_case/camelCase 两种字段名，UI 直接读取 [displayName]。
@freezed
abstract class FriendItem with _$FriendItem {
  const FriendItem._();

  const factory FriendItem({
    @JsonKey(
      name: 'friend_id',
      readValue: _readFriendId,
      fromJson: jsonIntRequired,
    )
    required int friendId,
    @JsonKey(
      name: 'user_id',
      readValue: _readUserId,
      fromJson: jsonInt,
    )
    int? userId,
    String? remark,
    @JsonKey(name: 'group_name', readValue: _readGroupName)
    String? groupName,
    @JsonKey(readValue: _readFriendUser, fromJson: _friendUserFromJson)
    FriendUserBrief? friendUser,
  }) = _FriendItem;

  factory FriendItem.fromJson(Map<String, dynamic> json) =>
      _$FriendItemFromJson(json);

  String get displayName {
    final friendRemark = remark?.trim() ?? '';
    if (friendRemark.isNotEmpty) return friendRemark;
    final nickname = friendUser?.nickname?.trim() ?? '';
    if (nickname.isNotEmpty) return nickname;
    final username = friendUser?.username.trim() ?? '';
    return username.isNotEmpty ? username : '未知';
  }
}

Object? _readEmbeddedFromUser(Map<dynamic, dynamic> json, String key) {
  for (final alias in ['fromUser', 'from_user', 'sender', 'user', 'from']) {
    final value = json[alias];
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final fromUserId =
          jsonInt(json['from_user_id']) ?? jsonInt(json['fromUserId']);
      if (fromUserId != null &&
          (jsonInt(map['id']) == null || jsonInt(map['id']) == 0)) {
        map['id'] = fromUserId;
      }
      return map;
    }
  }

  final username = json['from_username'] ?? json['fromUsername'];
  final nickname = json['from_nickname'] ?? json['fromNickname'];
  final fromUserId =
      jsonInt(json['from_user_id']) ?? jsonInt(json['fromUserId']);
  if (fromUserId != null && (username != null || nickname != null)) {
    return {
      'id': fromUserId,
      'username': username ?? '',
      'nickname': nickname,
    };
  }
  return null;
}

FriendUserBrief? _fromUserBriefFromJson(Object? value) {
  final map = _asStringMap(value);
  if (map == null) return null;

  final brief = FriendUserBrief.fromApiJson(map);
  final id = brief.id != 0 ? brief.id : jsonInt(map['from_user_id']) ?? 0;
  if (id == 0 && brief.username.isEmpty && brief.nickname == null) return null;
  return brief.copyWith(id: id);
}

/// 好友申请条目。
///
/// 这里保留后端多种历史返回格式，避免解析规则散落在 Provider/UI 中。
@freezed
abstract class FriendRequestItem with _$FriendRequestItem {
  const FriendRequestItem._();

  const factory FriendRequestItem({
    @JsonKey(fromJson: jsonIntRequired) required int id,
    @JsonKey(
      name: 'from_user_id',
      readValue: _readFromUserId,
      fromJson: jsonIntRequired,
    )
    required int fromUserId,
    @JsonKey(
      name: 'to_user_id',
      readValue: _readToUserId,
      fromJson: jsonIntRequired,
    )
    required int toUserId,
    String? message,
    String? status,
    @JsonKey(readValue: _readEmbeddedFromUser, fromJson: _fromUserBriefFromJson)
    FriendUserBrief? fromUser,
  }) = _FriendRequestItem;

  factory FriendRequestItem.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestItemFromJson(json);

  /// 用于列表主文案：昵称优先，否则用户名；无资料时为空（由 UI 用 id 兜底）。
  String get requesterDisplayLabel {
    final user = fromUser;
    if (user == null) return '';
    final nickname = user.nickname?.trim();
    if (nickname != null && nickname.isNotEmpty) return nickname;
    final username = user.username.trim();
    if (username.isNotEmpty) return username;
    return '';
  }
}
