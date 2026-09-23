import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../json/json_int.dart';
import '../messages/message_preview.dart';
import '../time/utc_date_time.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

// ignore_for_file: invalid_annotation_target

Object? _readMsgId(Map<dynamic, dynamic> json, String key) =>
    json['msgId'] ?? json['msg_id'];

Object? _readFrom(Map<dynamic, dynamic> json, String key) =>
    json['from'] ?? json['fromUserId'] ?? json['from_user_id'];

Object? _readFromUsername(Map<dynamic, dynamic> json, String key) =>
    json['fromUsername'] ?? json['senderUsername'] ?? json['from_username'];

Object? _readFromAvatar(Map<dynamic, dynamic> json, String key) =>
    json['fromAvatar'] ??
    json['from_avatar'] ??
    json['senderAvatar'] ??
    json['sender_avatar'];

Object? _readToId(Map<dynamic, dynamic> json, String key) =>
    json['toId'] ?? json['to_id'] ?? json['groupId'] ?? json['group_id'];

Object? _readChatType(Map<dynamic, dynamic> json, String key) {
  final chatType = json['chatType'] ?? json['chat_type'];
  if (chatType is String && chatType.trim().isNotEmpty) {
    return chatType.trim().toLowerCase();
  }
  if (json['groupId'] != null || json['group_id'] != null) return 'group';
  return 'private';
}

Object? _readMsgType(Map<dynamic, dynamic> json, String key) =>
    json['msgType'] ?? json['msg_type'];

Object? _readTimestamp(Map<dynamic, dynamic> json, String key) =>
    json['timestamp'] ?? json['createdAt'] ?? json['created_at'];

Object? _readClientMsgId(Map<dynamic, dynamic> json, String key) =>
    json['clientMsgId'] ?? json['client_msg_id'];

Object? _readReplyMsgId(Map<dynamic, dynamic> json, String key) =>
    json['replyMsgId'] ?? json['reply_msg_id'];

Object? _readAtUsers(Map<dynamic, dynamic> json, String key) =>
    json['atUsers'] ?? json['at_users'];

Object? _readSeq(Map<dynamic, dynamic> json, String key) => json['seq'];

Object? _readMediaObjectIds(Map<dynamic, dynamic> json, String key) {
  final direct = json['mediaObjectIds'] ?? json['media_object_ids'];
  if (direct is List) return direct;
  final media = json['media'];
  if (media is! List) return null;
  return media
      .whereType<Map>()
      .map((item) => item['objectId'] ?? item['object_id'])
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .toList(growable: false);
}

Object? _readContent(Map<dynamic, dynamic> json, String key) {
  final raw = json['content']?.toString() ?? '';
  final media = json['media'];
  if (media is! List || media.isEmpty || media.first is! Map) return raw;
  final first = media.first as Map;
  final url = first['url']?.toString().trim() ?? '';
  if (url.isEmpty) return raw;
  final msgType =
      (json['msgType'] ?? json['msg_type'])?.toString().toLowerCase();
  if (msgType == 'image') {
    final metadata = _jsonMapOrEmpty(raw);
    return jsonEncode({
      ...metadata,
      'url': url,
      if (metadata.isEmpty && raw.trim().isNotEmpty) 'caption': raw.trim()
    });
  }
  if (msgType == 'video') {
    return jsonEncode({..._jsonMapOrEmpty(raw), 'url': url});
  }
  if (msgType == 'file') {
    final metadata = _jsonMapOrEmpty(raw);
    return jsonEncode({
      ...metadata,
      'name': metadata['name'] ?? (raw.trim().isEmpty ? 'file' : raw.trim()),
      'url': url
    });
  }
  return url;
}

Map<String, dynamic> _jsonMapOrEmpty(String value) {
  try {
    final decoded = jsonDecode(value);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
  } catch (_) {
    return {};
  }
}

String _stringFromJson(Object? value) => value.toString();

String _stringOrEmpty(Object? value) => value is String ? value : '';

Object? _readEdited(Map<dynamic, dynamic> json, String key) =>
    json['edited'] ?? json['is_edited'];

bool _boolOrFalse(Object? value) => value is bool ? value : false;

String? _trimNullableString(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

DateTime _messageTimestampFromJson(Object? value) {
  return parseUtcDateTime(value) ?? DateTime.now().toUtc();
}

List<dynamic>? _dynamicListFromJson(Object? value) =>
    value is List ? List<dynamic>.from(value) : null;

/// 聊天消息 DTO。
///
/// 消息来自 HTTP 历史、WebSocket 推送和本地 optimistic 发送，字段别名统一在这里处理。
@freezed
abstract class ChatMessage with _$ChatMessage {
  const ChatMessage._();

  const factory ChatMessage({
    @JsonKey(readValue: _readMsgId, fromJson: _stringFromJson)
    required String msgId,
    @JsonKey(readValue: _readFrom, fromJson: jsonIntRequired) required int from,
    @JsonKey(readValue: _readFromUsername, fromJson: _trimNullableString)
    String? fromUsername,

    /// 发送方头像路径（相对或绝对 URL），部分接口会随消息下发。
    @JsonKey(readValue: _readFromAvatar, fromJson: _trimNullableString)
    String? fromAvatar,
    @JsonKey(readValue: _readToId, fromJson: _stringOrEmpty)
    required String toId,
    @JsonKey(readValue: _readChatType, fromJson: _stringOrEmpty)
    required String chatType,
    @JsonKey(readValue: _readMsgType, fromJson: _stringOrEmpty)
    @Default('text')
    String msgType,
    @JsonKey(readValue: _readContent, fromJson: _stringOrEmpty)
    @Default('')
    String content,
    @JsonKey(readValue: _readTimestamp, fromJson: _messageTimestampFromJson)
    required DateTime timestamp,
    @JsonKey(readValue: _readClientMsgId, fromJson: _trimNullableString)
    String? clientMsgId,
    @JsonKey(readValue: _readReplyMsgId, fromJson: _trimNullableString)
    String? replyMsgId,
    @JsonKey(readValue: _readAtUsers, fromJson: _dynamicListFromJson)
    List<dynamic>? atUsers,
    @JsonKey(readValue: _readSeq, fromJson: jsonInt) int? seq,
    @JsonKey(readValue: _readMediaObjectIds, fromJson: _dynamicListFromJson)
    List<dynamic>? mediaObjectIds,
    @Default('sent') String status,
    @JsonKey(readValue: _readEdited, fromJson: _boolOrFalse)
    @Default(false)
    bool edited,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  bool get isRecalled => status == 'recalled' || msgType == 'recall';

  String previewForConv() => previewTextFromContent(msgType, content);
}
