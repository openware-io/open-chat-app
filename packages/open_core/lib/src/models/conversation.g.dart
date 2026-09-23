// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ConversationImpl _$$ConversationImplFromJson(Map<String, dynamic> json) =>
    _$ConversationImpl(
      id: _stringFromJson(json['id']),
      chatType: json['chatType'] as String? ?? 'private',
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastTime: _conversationLastTimeFromJson(json['lastTime']),
      unread: json['unread'] == null ? 0 : _jsonIntOrZero(json['unread']),
      pinned: json['pinned'] == null ? false : _boolOrFalse(json['pinned']),
      muted: json['muted'] == null ? false : _boolOrFalse(json['muted']),
      draftText: json['draftText'] as String?,
    );

Map<String, dynamic> _$$ConversationImplToJson(_$ConversationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chatType': instance.chatType,
      'name': instance.name,
      'avatar': instance.avatar,
      'lastMessage': instance.lastMessage,
      'lastTime': instance.lastTime.toIso8601String(),
      'unread': instance.unread,
      'pinned': instance.pinned,
      'muted': instance.muted,
      'draftText': instance.draftText,
    };
