import 'package:freezed_annotation/freezed_annotation.dart';

import '../json/json_int.dart';

part 'group_models.freezed.dart';
part 'group_models.g.dart';

// ignore_for_file: invalid_annotation_target

Map<String, dynamic>? _nestedUser(Map<dynamic, dynamic> json) {
  for (final key in <String>[
    'user',
    'User',
    'member',
    'memberUser',
    'friendUser',
    'friend_user',
  ]) {
    final value = json[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return null;
}

String? _pickStr(Map<dynamic, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return null;
}

Object? _readGroupMemberUserId(Map<dynamic, dynamic> json, String key) {
  var userId = jsonInt(json['user_id']) ?? jsonInt(json['userId']);
  final user = _nestedUser(json);
  if ((userId == null || userId == 0) && user != null) {
    userId = jsonInt(user['id']) ??
        jsonInt(user['user_id']) ??
        jsonInt(user['userId']);
  }
  return userId ?? jsonInt(json['id']) ?? 0;
}

Object? _readGroupMemberNickname(Map<dynamic, dynamic> json, String key) {
  const nickKeys = ['nickname', 'nick_name', 'nickName'];
  const displayKeys = ['display_name', 'displayName', 'name'];
  final user = _nestedUser(json);
  return _pickStr(json, nickKeys) ??
      (user != null ? _pickStr(user, nickKeys) : null) ??
      _pickStr(json, displayKeys) ??
      (user != null ? _pickStr(user, displayKeys) : null);
}

Object? _readGroupMemberUsername(Map<dynamic, dynamic> json, String key) {
  const nameKeys = ['username', 'user_name', 'userName'];
  final user = _nestedUser(json);
  return _pickStr(json, nameKeys) ??
      (user != null ? _pickStr(user, nameKeys) : null);
}

Object? _readGroupMemberRole(Map<dynamic, dynamic> json, String key) {
  final user = _nestedUser(json);
  return _pickStr(json, ['role']) ??
      (user != null ? _pickStr(user, ['role']) : null);
}

Object? _readGroupMemberAvatar(Map<dynamic, dynamic> json, String key) {
  const avatarKeys = ['avatar', 'avatar_url', 'avatarUrl'];
  final user = _nestedUser(json);
  return _pickStr(json, avatarKeys) ??
      (user != null ? _pickStr(user, avatarKeys) : null);
}

String? _trimNullableString(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

int _jsonIntOrZero(Object? value) => jsonInt(value) ?? 0;

int? _jsonIntOrNull(Object? value) => jsonInt(value);

Object? _readGroupMemberCount(Map<dynamic, dynamic> json, String _) {
  final direct = json['memberCount'] ??
      json['member_count'] ??
      json['membersCount'] ??
      json['members_count'];
  if (direct != null) return direct;
  final members = json['members'];
  return members is List ? members.length : null;
}

/// 群组列表/详情基础信息。
@freezed
abstract class GroupItem with _$GroupItem {
  const GroupItem._();

  const factory GroupItem({
    @JsonKey(fromJson: jsonIntRequired) required int id,
    @Default('') String name,
    String? avatar,
    @JsonKey(readValue: _readGroupMemberCount, fromJson: _jsonIntOrNull)
    int? memberCount,
  }) = _GroupItem;

  factory GroupItem.fromJson(Map<String, dynamic> json) =>
      _$GroupItemFromJson(json);
}

/// 群成员信息。
///
/// 成员接口历史上有扁平字段和嵌套 user 两种形态，统一在核心模型中兼容。
@freezed
abstract class GroupMember with _$GroupMember {
  const GroupMember._();

  const factory GroupMember({
    @JsonKey(
      name: 'user_id',
      readValue: _readGroupMemberUserId,
      fromJson: _jsonIntOrZero,
    )
    required int userId,
    @JsonKey(readValue: _readGroupMemberNickname, fromJson: _trimNullableString)
    String? nickname,
    @JsonKey(readValue: _readGroupMemberUsername, fromJson: _trimNullableString)
    String? username,
    @JsonKey(readValue: _readGroupMemberRole, fromJson: _trimNullableString)
    String? role,
    @JsonKey(readValue: _readGroupMemberAvatar, fromJson: _trimNullableString)
    String? avatar,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);

  String get displayName {
    String? nonBlank(String? value) {
      if (value == null) return null;
      final text = value.trim();
      return text.isEmpty ? null : text;
    }

    // 群内隐私：不展示聊天账号（username），仅展示昵称/备注；无昵称时用通用兜底。
    return nonBlank(nickname) ?? '用户$userId';
  }
}
