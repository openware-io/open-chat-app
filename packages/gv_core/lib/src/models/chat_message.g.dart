// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatMessageImpl _$$ChatMessageImplFromJson(Map<String, dynamic> json) =>
    _$ChatMessageImpl(
      msgId: _stringFromJson(_readMsgId(json, 'msgId')),
      from: jsonIntRequired(_readFrom(json, 'from')),
      fromUsername:
          _trimNullableString(_readFromUsername(json, 'fromUsername')),
      fromAvatar: _trimNullableString(_readFromAvatar(json, 'fromAvatar')),
      toId: _stringOrEmpty(_readToId(json, 'toId')),
      chatType: _stringOrEmpty(_readChatType(json, 'chatType')),
      msgType: _readMsgType(json, 'msgType') == null
          ? 'text'
          : _stringOrEmpty(_readMsgType(json, 'msgType')),
      content: _readContent(json, 'content') == null
          ? ''
          : _stringOrEmpty(_readContent(json, 'content')),
      timestamp: _messageTimestampFromJson(_readTimestamp(json, 'timestamp')),
      clientMsgId: _trimNullableString(_readClientMsgId(json, 'clientMsgId')),
      replyMsgId: _trimNullableString(_readReplyMsgId(json, 'replyMsgId')),
      atUsers: _dynamicListFromJson(_readAtUsers(json, 'atUsers')),
      seq: jsonInt(_readSeq(json, 'seq')),
      mediaObjectIds:
          _dynamicListFromJson(_readMediaObjectIds(json, 'mediaObjectIds')),
      status: json['status'] as String? ?? 'sent',
      edited: _readEdited(json, 'edited') == null
          ? false
          : _boolOrFalse(_readEdited(json, 'edited')),
    );

Map<String, dynamic> _$$ChatMessageImplToJson(_$ChatMessageImpl instance) =>
    <String, dynamic>{
      'msgId': instance.msgId,
      'from': instance.from,
      'fromUsername': instance.fromUsername,
      'fromAvatar': instance.fromAvatar,
      'toId': instance.toId,
      'chatType': instance.chatType,
      'msgType': instance.msgType,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
      'clientMsgId': instance.clientMsgId,
      'replyMsgId': instance.replyMsgId,
      'atUsers': instance.atUsers,
      'seq': instance.seq,
      'mediaObjectIds': instance.mediaObjectIds,
      'status': instance.status,
      'edited': instance.edited,
    };
