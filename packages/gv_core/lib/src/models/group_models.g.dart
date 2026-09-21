// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GroupItemImpl _$$GroupItemImplFromJson(Map<String, dynamic> json) =>
    _$GroupItemImpl(
      id: jsonIntRequired(json['id']),
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      memberCount: _jsonIntOrNull(_readGroupMemberCount(json, 'memberCount')),
    );

Map<String, dynamic> _$$GroupItemImplToJson(_$GroupItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatar': instance.avatar,
      'memberCount': instance.memberCount,
    };

_$GroupMemberImpl _$$GroupMemberImplFromJson(Map<String, dynamic> json) =>
    _$GroupMemberImpl(
      userId: _jsonIntOrZero(_readGroupMemberUserId(json, 'user_id')),
      nickname: _trimNullableString(_readGroupMemberNickname(json, 'nickname')),
      username: _trimNullableString(_readGroupMemberUsername(json, 'username')),
      role: _trimNullableString(_readGroupMemberRole(json, 'role')),
      avatar: _trimNullableString(_readGroupMemberAvatar(json, 'avatar')),
    );

Map<String, dynamic> _$$GroupMemberImplToJson(_$GroupMemberImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'nickname': instance.nickname,
      'username': instance.username,
      'role': instance.role,
      'avatar': instance.avatar,
    };
