// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FriendUserBriefImpl _$$FriendUserBriefImplFromJson(
        Map<String, dynamic> json) =>
    _$FriendUserBriefImpl(
      id: _jsonIntOrZero(json['id']),
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String?,
      avatar: json['avatar'] as String?,
      signature: json['signature'] as String?,
    );

Map<String, dynamic> _$$FriendUserBriefImplToJson(
        _$FriendUserBriefImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'nickname': instance.nickname,
      'avatar': instance.avatar,
      'signature': instance.signature,
    };

_$FriendItemImpl _$$FriendItemImplFromJson(Map<String, dynamic> json) =>
    _$FriendItemImpl(
      friendId: jsonIntRequired(_readFriendId(json, 'friend_id')),
      userId: jsonInt(_readUserId(json, 'user_id')),
      remark: json['remark'] as String?,
      groupName: _readGroupName(json, 'group_name') as String?,
      friendUser: _friendUserFromJson(_readFriendUser(json, 'friendUser')),
    );

Map<String, dynamic> _$$FriendItemImplToJson(_$FriendItemImpl instance) =>
    <String, dynamic>{
      'friend_id': instance.friendId,
      'user_id': instance.userId,
      'remark': instance.remark,
      'group_name': instance.groupName,
      'friendUser': instance.friendUser,
    };

_$FriendRequestItemImpl _$$FriendRequestItemImplFromJson(
        Map<String, dynamic> json) =>
    _$FriendRequestItemImpl(
      id: jsonIntRequired(json['id']),
      fromUserId: jsonIntRequired(_readFromUserId(json, 'from_user_id')),
      toUserId: jsonIntRequired(_readToUserId(json, 'to_user_id')),
      message: json['message'] as String?,
      status: json['status'] as String?,
      fromUser: _fromUserBriefFromJson(_readEmbeddedFromUser(json, 'fromUser')),
    );

Map<String, dynamic> _$$FriendRequestItemImplToJson(
        _$FriendRequestItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'from_user_id': instance.fromUserId,
      'to_user_id': instance.toUserId,
      'message': instance.message,
      'status': instance.status,
      'fromUser': instance.fromUser,
    };
