import 'package:freezed_annotation/freezed_annotation.dart';

import '../json/json_int.dart';
import '../time/utc_date_time.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

// ignore_for_file: invalid_annotation_target

String _stringFromJson(Object? value) => value.toString();

DateTime _conversationLastTimeFromJson(Object? value) {
  return parseUtcDateTime(value) ?? DateTime.now().toUtc();
}

int _jsonIntOrZero(Object? value) => jsonInt(value) ?? 0;

bool _boolOrFalse(Object? value) => value is bool ? value : false;

/// 本地会话列表项。
@freezed
abstract class Conversation with _$Conversation {
  const Conversation._();

  const factory Conversation({
    @JsonKey(fromJson: _stringFromJson) required String id,
    @Default('private') String chatType,
    @Default('') String name,
    @Default('') String avatar,
    @Default('') String lastMessage,
    @JsonKey(fromJson: _conversationLastTimeFromJson)
    required DateTime lastTime,
    @JsonKey(fromJson: _jsonIntOrZero) @Default(0) int unread,
    @JsonKey(fromJson: _boolOrFalse) @Default(false) bool pinned,
    @JsonKey(fromJson: _boolOrFalse) @Default(false) bool muted,

    /// 未发送的输入草稿（本地持久化）；为空表示无草稿。
    String? draftText,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
