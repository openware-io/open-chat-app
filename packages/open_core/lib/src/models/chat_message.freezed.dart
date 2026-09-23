// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) {
  return _ChatMessage.fromJson(json);
}

/// @nodoc
mixin _$ChatMessage {
  @JsonKey(readValue: _readMsgId, fromJson: _stringFromJson)
  String get msgId => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readFrom, fromJson: jsonIntRequired)
  int get from => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readFromUsername, fromJson: _trimNullableString)
  String? get fromUsername => throw _privateConstructorUsedError;

  /// 发送方头像路径（相对或绝对 URL），部分接口会随消息下发。
  @JsonKey(readValue: _readFromAvatar, fromJson: _trimNullableString)
  String? get fromAvatar => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readToId, fromJson: _stringOrEmpty)
  String get toId => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readChatType, fromJson: _stringOrEmpty)
  String get chatType => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readMsgType, fromJson: _stringOrEmpty)
  String get msgType => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readContent, fromJson: _stringOrEmpty)
  String get content => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readTimestamp, fromJson: _messageTimestampFromJson)
  DateTime get timestamp => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readClientMsgId, fromJson: _trimNullableString)
  String? get clientMsgId => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readReplyMsgId, fromJson: _trimNullableString)
  String? get replyMsgId => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readAtUsers, fromJson: _dynamicListFromJson)
  List<dynamic>? get atUsers => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readSeq, fromJson: jsonInt)
  int? get seq => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readMediaObjectIds, fromJson: _dynamicListFromJson)
  List<dynamic>? get mediaObjectIds => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readEdited, fromJson: _boolOrFalse)
  bool get edited => throw _privateConstructorUsedError;

  /// Serializes this ChatMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call(
      {@JsonKey(readValue: _readMsgId, fromJson: _stringFromJson) String msgId,
      @JsonKey(readValue: _readFrom, fromJson: jsonIntRequired) int from,
      @JsonKey(readValue: _readFromUsername, fromJson: _trimNullableString)
      String? fromUsername,
      @JsonKey(readValue: _readFromAvatar, fromJson: _trimNullableString)
      String? fromAvatar,
      @JsonKey(readValue: _readToId, fromJson: _stringOrEmpty) String toId,
      @JsonKey(readValue: _readChatType, fromJson: _stringOrEmpty)
      String chatType,
      @JsonKey(readValue: _readMsgType, fromJson: _stringOrEmpty)
      String msgType,
      @JsonKey(readValue: _readContent, fromJson: _stringOrEmpty)
      String content,
      @JsonKey(readValue: _readTimestamp, fromJson: _messageTimestampFromJson)
      DateTime timestamp,
      @JsonKey(readValue: _readClientMsgId, fromJson: _trimNullableString)
      String? clientMsgId,
      @JsonKey(readValue: _readReplyMsgId, fromJson: _trimNullableString)
      String? replyMsgId,
      @JsonKey(readValue: _readAtUsers, fromJson: _dynamicListFromJson)
      List<dynamic>? atUsers,
      @JsonKey(readValue: _readSeq, fromJson: jsonInt) int? seq,
      @JsonKey(readValue: _readMediaObjectIds, fromJson: _dynamicListFromJson)
      List<dynamic>? mediaObjectIds,
      String status,
      @JsonKey(readValue: _readEdited, fromJson: _boolOrFalse) bool edited});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? msgId = null,
    Object? from = null,
    Object? fromUsername = freezed,
    Object? fromAvatar = freezed,
    Object? toId = null,
    Object? chatType = null,
    Object? msgType = null,
    Object? content = null,
    Object? timestamp = null,
    Object? clientMsgId = freezed,
    Object? replyMsgId = freezed,
    Object? atUsers = freezed,
    Object? seq = freezed,
    Object? mediaObjectIds = freezed,
    Object? status = null,
    Object? edited = null,
  }) {
    return _then(_value.copyWith(
      msgId: null == msgId
          ? _value.msgId
          : msgId // ignore: cast_nullable_to_non_nullable
              as String,
      from: null == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as int,
      fromUsername: freezed == fromUsername
          ? _value.fromUsername
          : fromUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      fromAvatar: freezed == fromAvatar
          ? _value.fromAvatar
          : fromAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      toId: null == toId
          ? _value.toId
          : toId // ignore: cast_nullable_to_non_nullable
              as String,
      chatType: null == chatType
          ? _value.chatType
          : chatType // ignore: cast_nullable_to_non_nullable
              as String,
      msgType: null == msgType
          ? _value.msgType
          : msgType // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      clientMsgId: freezed == clientMsgId
          ? _value.clientMsgId
          : clientMsgId // ignore: cast_nullable_to_non_nullable
              as String?,
      replyMsgId: freezed == replyMsgId
          ? _value.replyMsgId
          : replyMsgId // ignore: cast_nullable_to_non_nullable
              as String?,
      atUsers: freezed == atUsers
          ? _value.atUsers
          : atUsers // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      seq: freezed == seq
          ? _value.seq
          : seq // ignore: cast_nullable_to_non_nullable
              as int?,
      mediaObjectIds: freezed == mediaObjectIds
          ? _value.mediaObjectIds
          : mediaObjectIds // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      edited: null == edited
          ? _value.edited
          : edited // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(readValue: _readMsgId, fromJson: _stringFromJson) String msgId,
      @JsonKey(readValue: _readFrom, fromJson: jsonIntRequired) int from,
      @JsonKey(readValue: _readFromUsername, fromJson: _trimNullableString)
      String? fromUsername,
      @JsonKey(readValue: _readFromAvatar, fromJson: _trimNullableString)
      String? fromAvatar,
      @JsonKey(readValue: _readToId, fromJson: _stringOrEmpty) String toId,
      @JsonKey(readValue: _readChatType, fromJson: _stringOrEmpty)
      String chatType,
      @JsonKey(readValue: _readMsgType, fromJson: _stringOrEmpty)
      String msgType,
      @JsonKey(readValue: _readContent, fromJson: _stringOrEmpty)
      String content,
      @JsonKey(readValue: _readTimestamp, fromJson: _messageTimestampFromJson)
      DateTime timestamp,
      @JsonKey(readValue: _readClientMsgId, fromJson: _trimNullableString)
      String? clientMsgId,
      @JsonKey(readValue: _readReplyMsgId, fromJson: _trimNullableString)
      String? replyMsgId,
      @JsonKey(readValue: _readAtUsers, fromJson: _dynamicListFromJson)
      List<dynamic>? atUsers,
      @JsonKey(readValue: _readSeq, fromJson: jsonInt) int? seq,
      @JsonKey(readValue: _readMediaObjectIds, fromJson: _dynamicListFromJson)
      List<dynamic>? mediaObjectIds,
      String status,
      @JsonKey(readValue: _readEdited, fromJson: _boolOrFalse) bool edited});
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? msgId = null,
    Object? from = null,
    Object? fromUsername = freezed,
    Object? fromAvatar = freezed,
    Object? toId = null,
    Object? chatType = null,
    Object? msgType = null,
    Object? content = null,
    Object? timestamp = null,
    Object? clientMsgId = freezed,
    Object? replyMsgId = freezed,
    Object? atUsers = freezed,
    Object? seq = freezed,
    Object? mediaObjectIds = freezed,
    Object? status = null,
    Object? edited = null,
  }) {
    return _then(_$ChatMessageImpl(
      msgId: null == msgId
          ? _value.msgId
          : msgId // ignore: cast_nullable_to_non_nullable
              as String,
      from: null == from
          ? _value.from
          : from // ignore: cast_nullable_to_non_nullable
              as int,
      fromUsername: freezed == fromUsername
          ? _value.fromUsername
          : fromUsername // ignore: cast_nullable_to_non_nullable
              as String?,
      fromAvatar: freezed == fromAvatar
          ? _value.fromAvatar
          : fromAvatar // ignore: cast_nullable_to_non_nullable
              as String?,
      toId: null == toId
          ? _value.toId
          : toId // ignore: cast_nullable_to_non_nullable
              as String,
      chatType: null == chatType
          ? _value.chatType
          : chatType // ignore: cast_nullable_to_non_nullable
              as String,
      msgType: null == msgType
          ? _value.msgType
          : msgType // ignore: cast_nullable_to_non_nullable
              as String,
      content: null == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      clientMsgId: freezed == clientMsgId
          ? _value.clientMsgId
          : clientMsgId // ignore: cast_nullable_to_non_nullable
              as String?,
      replyMsgId: freezed == replyMsgId
          ? _value.replyMsgId
          : replyMsgId // ignore: cast_nullable_to_non_nullable
              as String?,
      atUsers: freezed == atUsers
          ? _value._atUsers
          : atUsers // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      seq: freezed == seq
          ? _value.seq
          : seq // ignore: cast_nullable_to_non_nullable
              as int?,
      mediaObjectIds: freezed == mediaObjectIds
          ? _value._mediaObjectIds
          : mediaObjectIds // ignore: cast_nullable_to_non_nullable
              as List<dynamic>?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      edited: null == edited
          ? _value.edited
          : edited // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatMessageImpl extends _ChatMessage {
  const _$ChatMessageImpl(
      {@JsonKey(readValue: _readMsgId, fromJson: _stringFromJson)
      required this.msgId,
      @JsonKey(readValue: _readFrom, fromJson: jsonIntRequired)
      required this.from,
      @JsonKey(readValue: _readFromUsername, fromJson: _trimNullableString)
      this.fromUsername,
      @JsonKey(readValue: _readFromAvatar, fromJson: _trimNullableString)
      this.fromAvatar,
      @JsonKey(readValue: _readToId, fromJson: _stringOrEmpty)
      required this.toId,
      @JsonKey(readValue: _readChatType, fromJson: _stringOrEmpty)
      required this.chatType,
      @JsonKey(readValue: _readMsgType, fromJson: _stringOrEmpty)
      this.msgType = 'text',
      @JsonKey(readValue: _readContent, fromJson: _stringOrEmpty)
      this.content = '',
      @JsonKey(readValue: _readTimestamp, fromJson: _messageTimestampFromJson)
      required this.timestamp,
      @JsonKey(readValue: _readClientMsgId, fromJson: _trimNullableString)
      this.clientMsgId,
      @JsonKey(readValue: _readReplyMsgId, fromJson: _trimNullableString)
      this.replyMsgId,
      @JsonKey(readValue: _readAtUsers, fromJson: _dynamicListFromJson)
      final List<dynamic>? atUsers,
      @JsonKey(readValue: _readSeq, fromJson: jsonInt) this.seq,
      @JsonKey(readValue: _readMediaObjectIds, fromJson: _dynamicListFromJson)
      final List<dynamic>? mediaObjectIds,
      this.status = 'sent',
      @JsonKey(readValue: _readEdited, fromJson: _boolOrFalse)
      this.edited = false})
      : _atUsers = atUsers,
        _mediaObjectIds = mediaObjectIds,
        super._();

  factory _$ChatMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatMessageImplFromJson(json);

  @override
  @JsonKey(readValue: _readMsgId, fromJson: _stringFromJson)
  final String msgId;
  @override
  @JsonKey(readValue: _readFrom, fromJson: jsonIntRequired)
  final int from;
  @override
  @JsonKey(readValue: _readFromUsername, fromJson: _trimNullableString)
  final String? fromUsername;

  /// 发送方头像路径（相对或绝对 URL），部分接口会随消息下发。
  @override
  @JsonKey(readValue: _readFromAvatar, fromJson: _trimNullableString)
  final String? fromAvatar;
  @override
  @JsonKey(readValue: _readToId, fromJson: _stringOrEmpty)
  final String toId;
  @override
  @JsonKey(readValue: _readChatType, fromJson: _stringOrEmpty)
  final String chatType;
  @override
  @JsonKey(readValue: _readMsgType, fromJson: _stringOrEmpty)
  final String msgType;
  @override
  @JsonKey(readValue: _readContent, fromJson: _stringOrEmpty)
  final String content;
  @override
  @JsonKey(readValue: _readTimestamp, fromJson: _messageTimestampFromJson)
  final DateTime timestamp;
  @override
  @JsonKey(readValue: _readClientMsgId, fromJson: _trimNullableString)
  final String? clientMsgId;
  @override
  @JsonKey(readValue: _readReplyMsgId, fromJson: _trimNullableString)
  final String? replyMsgId;
  final List<dynamic>? _atUsers;
  @override
  @JsonKey(readValue: _readAtUsers, fromJson: _dynamicListFromJson)
  List<dynamic>? get atUsers {
    final value = _atUsers;
    if (value == null) return null;
    if (_atUsers is EqualUnmodifiableListView) return _atUsers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey(readValue: _readSeq, fromJson: jsonInt)
  final int? seq;
  final List<dynamic>? _mediaObjectIds;
  @override
  @JsonKey(readValue: _readMediaObjectIds, fromJson: _dynamicListFromJson)
  List<dynamic>? get mediaObjectIds {
    final value = _mediaObjectIds;
    if (value == null) return null;
    if (_mediaObjectIds is EqualUnmodifiableListView) return _mediaObjectIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(readValue: _readEdited, fromJson: _boolOrFalse)
  final bool edited;

  @override
  String toString() {
    return 'ChatMessage(msgId: $msgId, from: $from, fromUsername: $fromUsername, fromAvatar: $fromAvatar, toId: $toId, chatType: $chatType, msgType: $msgType, content: $content, timestamp: $timestamp, clientMsgId: $clientMsgId, replyMsgId: $replyMsgId, atUsers: $atUsers, seq: $seq, mediaObjectIds: $mediaObjectIds, status: $status, edited: $edited)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.msgId, msgId) || other.msgId == msgId) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.fromUsername, fromUsername) ||
                other.fromUsername == fromUsername) &&
            (identical(other.fromAvatar, fromAvatar) ||
                other.fromAvatar == fromAvatar) &&
            (identical(other.toId, toId) || other.toId == toId) &&
            (identical(other.chatType, chatType) ||
                other.chatType == chatType) &&
            (identical(other.msgType, msgType) || other.msgType == msgType) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.clientMsgId, clientMsgId) ||
                other.clientMsgId == clientMsgId) &&
            (identical(other.replyMsgId, replyMsgId) ||
                other.replyMsgId == replyMsgId) &&
            const DeepCollectionEquality().equals(other._atUsers, _atUsers) &&
            (identical(other.seq, seq) || other.seq == seq) &&
            const DeepCollectionEquality()
                .equals(other._mediaObjectIds, _mediaObjectIds) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.edited, edited) || other.edited == edited));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      msgId,
      from,
      fromUsername,
      fromAvatar,
      toId,
      chatType,
      msgType,
      content,
      timestamp,
      clientMsgId,
      replyMsgId,
      const DeepCollectionEquality().hash(_atUsers),
      seq,
      const DeepCollectionEquality().hash(_mediaObjectIds),
      status,
      edited);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatMessageImplToJson(
      this,
    );
  }
}

abstract class _ChatMessage extends ChatMessage {
  const factory _ChatMessage(
      {@JsonKey(readValue: _readMsgId, fromJson: _stringFromJson)
      required final String msgId,
      @JsonKey(readValue: _readFrom, fromJson: jsonIntRequired)
      required final int from,
      @JsonKey(readValue: _readFromUsername, fromJson: _trimNullableString)
      final String? fromUsername,
      @JsonKey(readValue: _readFromAvatar, fromJson: _trimNullableString)
      final String? fromAvatar,
      @JsonKey(readValue: _readToId, fromJson: _stringOrEmpty)
      required final String toId,
      @JsonKey(readValue: _readChatType, fromJson: _stringOrEmpty)
      required final String chatType,
      @JsonKey(readValue: _readMsgType, fromJson: _stringOrEmpty)
      final String msgType,
      @JsonKey(readValue: _readContent, fromJson: _stringOrEmpty)
      final String content,
      @JsonKey(readValue: _readTimestamp, fromJson: _messageTimestampFromJson)
      required final DateTime timestamp,
      @JsonKey(readValue: _readClientMsgId, fromJson: _trimNullableString)
      final String? clientMsgId,
      @JsonKey(readValue: _readReplyMsgId, fromJson: _trimNullableString)
      final String? replyMsgId,
      @JsonKey(readValue: _readAtUsers, fromJson: _dynamicListFromJson)
      final List<dynamic>? atUsers,
      @JsonKey(readValue: _readSeq, fromJson: jsonInt) final int? seq,
      @JsonKey(readValue: _readMediaObjectIds, fromJson: _dynamicListFromJson)
      final List<dynamic>? mediaObjectIds,
      final String status,
      @JsonKey(readValue: _readEdited, fromJson: _boolOrFalse)
      final bool edited}) = _$ChatMessageImpl;
  const _ChatMessage._() : super._();

  factory _ChatMessage.fromJson(Map<String, dynamic> json) =
      _$ChatMessageImpl.fromJson;

  @override
  @JsonKey(readValue: _readMsgId, fromJson: _stringFromJson)
  String get msgId;
  @override
  @JsonKey(readValue: _readFrom, fromJson: jsonIntRequired)
  int get from;
  @override
  @JsonKey(readValue: _readFromUsername, fromJson: _trimNullableString)
  String? get fromUsername;

  /// 发送方头像路径（相对或绝对 URL），部分接口会随消息下发。
  @override
  @JsonKey(readValue: _readFromAvatar, fromJson: _trimNullableString)
  String? get fromAvatar;
  @override
  @JsonKey(readValue: _readToId, fromJson: _stringOrEmpty)
  String get toId;
  @override
  @JsonKey(readValue: _readChatType, fromJson: _stringOrEmpty)
  String get chatType;
  @override
  @JsonKey(readValue: _readMsgType, fromJson: _stringOrEmpty)
  String get msgType;
  @override
  @JsonKey(readValue: _readContent, fromJson: _stringOrEmpty)
  String get content;
  @override
  @JsonKey(readValue: _readTimestamp, fromJson: _messageTimestampFromJson)
  DateTime get timestamp;
  @override
  @JsonKey(readValue: _readClientMsgId, fromJson: _trimNullableString)
  String? get clientMsgId;
  @override
  @JsonKey(readValue: _readReplyMsgId, fromJson: _trimNullableString)
  String? get replyMsgId;
  @override
  @JsonKey(readValue: _readAtUsers, fromJson: _dynamicListFromJson)
  List<dynamic>? get atUsers;
  @override
  @JsonKey(readValue: _readSeq, fromJson: jsonInt)
  int? get seq;
  @override
  @JsonKey(readValue: _readMediaObjectIds, fromJson: _dynamicListFromJson)
  List<dynamic>? get mediaObjectIds;
  @override
  String get status;
  @override
  @JsonKey(readValue: _readEdited, fromJson: _boolOrFalse)
  bool get edited;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
