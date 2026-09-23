// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'conversation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Conversation _$ConversationFromJson(Map<String, dynamic> json) {
  return _Conversation.fromJson(json);
}

/// @nodoc
mixin _$Conversation {
  @JsonKey(fromJson: _stringFromJson)
  String get id => throw _privateConstructorUsedError;
  String get chatType => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get avatar => throw _privateConstructorUsedError;
  String get lastMessage => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _conversationLastTimeFromJson)
  DateTime get lastTime => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _jsonIntOrZero)
  int get unread => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolOrFalse)
  bool get pinned => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolOrFalse)
  bool get muted => throw _privateConstructorUsedError;

  /// 未发送的输入草稿（本地持久化）；为空表示无草稿。
  String? get draftText => throw _privateConstructorUsedError;

  /// Serializes this Conversation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ConversationCopyWith<Conversation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ConversationCopyWith<$Res> {
  factory $ConversationCopyWith(
          Conversation value, $Res Function(Conversation) then) =
      _$ConversationCopyWithImpl<$Res, Conversation>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _stringFromJson) String id,
      String chatType,
      String name,
      String avatar,
      String lastMessage,
      @JsonKey(fromJson: _conversationLastTimeFromJson) DateTime lastTime,
      @JsonKey(fromJson: _jsonIntOrZero) int unread,
      @JsonKey(fromJson: _boolOrFalse) bool pinned,
      @JsonKey(fromJson: _boolOrFalse) bool muted,
      String? draftText});
}

/// @nodoc
class _$ConversationCopyWithImpl<$Res, $Val extends Conversation>
    implements $ConversationCopyWith<$Res> {
  _$ConversationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chatType = null,
    Object? name = null,
    Object? avatar = null,
    Object? lastMessage = null,
    Object? lastTime = null,
    Object? unread = null,
    Object? pinned = null,
    Object? muted = null,
    Object? draftText = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      chatType: null == chatType
          ? _value.chatType
          : chatType // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: null == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String,
      lastMessage: null == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String,
      lastTime: null == lastTime
          ? _value.lastTime
          : lastTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unread: null == unread
          ? _value.unread
          : unread // ignore: cast_nullable_to_non_nullable
              as int,
      pinned: null == pinned
          ? _value.pinned
          : pinned // ignore: cast_nullable_to_non_nullable
              as bool,
      muted: null == muted
          ? _value.muted
          : muted // ignore: cast_nullable_to_non_nullable
              as bool,
      draftText: freezed == draftText
          ? _value.draftText
          : draftText // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ConversationImplCopyWith<$Res>
    implements $ConversationCopyWith<$Res> {
  factory _$$ConversationImplCopyWith(
          _$ConversationImpl value, $Res Function(_$ConversationImpl) then) =
      __$$ConversationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _stringFromJson) String id,
      String chatType,
      String name,
      String avatar,
      String lastMessage,
      @JsonKey(fromJson: _conversationLastTimeFromJson) DateTime lastTime,
      @JsonKey(fromJson: _jsonIntOrZero) int unread,
      @JsonKey(fromJson: _boolOrFalse) bool pinned,
      @JsonKey(fromJson: _boolOrFalse) bool muted,
      String? draftText});
}

/// @nodoc
class __$$ConversationImplCopyWithImpl<$Res>
    extends _$ConversationCopyWithImpl<$Res, _$ConversationImpl>
    implements _$$ConversationImplCopyWith<$Res> {
  __$$ConversationImplCopyWithImpl(
      _$ConversationImpl _value, $Res Function(_$ConversationImpl) _then)
      : super(_value, _then);

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? chatType = null,
    Object? name = null,
    Object? avatar = null,
    Object? lastMessage = null,
    Object? lastTime = null,
    Object? unread = null,
    Object? pinned = null,
    Object? muted = null,
    Object? draftText = freezed,
  }) {
    return _then(_$ConversationImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      chatType: null == chatType
          ? _value.chatType
          : chatType // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: null == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String,
      lastMessage: null == lastMessage
          ? _value.lastMessage
          : lastMessage // ignore: cast_nullable_to_non_nullable
              as String,
      lastTime: null == lastTime
          ? _value.lastTime
          : lastTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      unread: null == unread
          ? _value.unread
          : unread // ignore: cast_nullable_to_non_nullable
              as int,
      pinned: null == pinned
          ? _value.pinned
          : pinned // ignore: cast_nullable_to_non_nullable
              as bool,
      muted: null == muted
          ? _value.muted
          : muted // ignore: cast_nullable_to_non_nullable
              as bool,
      draftText: freezed == draftText
          ? _value.draftText
          : draftText // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ConversationImpl extends _Conversation {
  const _$ConversationImpl(
      {@JsonKey(fromJson: _stringFromJson) required this.id,
      this.chatType = 'private',
      this.name = '',
      this.avatar = '',
      this.lastMessage = '',
      @JsonKey(fromJson: _conversationLastTimeFromJson) required this.lastTime,
      @JsonKey(fromJson: _jsonIntOrZero) this.unread = 0,
      @JsonKey(fromJson: _boolOrFalse) this.pinned = false,
      @JsonKey(fromJson: _boolOrFalse) this.muted = false,
      this.draftText})
      : super._();

  factory _$ConversationImpl.fromJson(Map<String, dynamic> json) =>
      _$$ConversationImplFromJson(json);

  @override
  @JsonKey(fromJson: _stringFromJson)
  final String id;
  @override
  @JsonKey()
  final String chatType;
  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String avatar;
  @override
  @JsonKey()
  final String lastMessage;
  @override
  @JsonKey(fromJson: _conversationLastTimeFromJson)
  final DateTime lastTime;
  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  final int unread;
  @override
  @JsonKey(fromJson: _boolOrFalse)
  final bool pinned;
  @override
  @JsonKey(fromJson: _boolOrFalse)
  final bool muted;

  /// 未发送的输入草稿（本地持久化）；为空表示无草稿。
  @override
  final String? draftText;

  @override
  String toString() {
    return 'Conversation(id: $id, chatType: $chatType, name: $name, avatar: $avatar, lastMessage: $lastMessage, lastTime: $lastTime, unread: $unread, pinned: $pinned, muted: $muted, draftText: $draftText)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ConversationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.chatType, chatType) ||
                other.chatType == chatType) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.lastMessage, lastMessage) ||
                other.lastMessage == lastMessage) &&
            (identical(other.lastTime, lastTime) ||
                other.lastTime == lastTime) &&
            (identical(other.unread, unread) || other.unread == unread) &&
            (identical(other.pinned, pinned) || other.pinned == pinned) &&
            (identical(other.muted, muted) || other.muted == muted) &&
            (identical(other.draftText, draftText) ||
                other.draftText == draftText));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, chatType, name, avatar,
      lastMessage, lastTime, unread, pinned, muted, draftText);

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      __$$ConversationImplCopyWithImpl<_$ConversationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ConversationImplToJson(
      this,
    );
  }
}

abstract class _Conversation extends Conversation {
  const factory _Conversation(
      {@JsonKey(fromJson: _stringFromJson) required final String id,
      final String chatType,
      final String name,
      final String avatar,
      final String lastMessage,
      @JsonKey(fromJson: _conversationLastTimeFromJson)
      required final DateTime lastTime,
      @JsonKey(fromJson: _jsonIntOrZero) final int unread,
      @JsonKey(fromJson: _boolOrFalse) final bool pinned,
      @JsonKey(fromJson: _boolOrFalse) final bool muted,
      final String? draftText}) = _$ConversationImpl;
  const _Conversation._() : super._();

  factory _Conversation.fromJson(Map<String, dynamic> json) =
      _$ConversationImpl.fromJson;

  @override
  @JsonKey(fromJson: _stringFromJson)
  String get id;
  @override
  String get chatType;
  @override
  String get name;
  @override
  String get avatar;
  @override
  String get lastMessage;
  @override
  @JsonKey(fromJson: _conversationLastTimeFromJson)
  DateTime get lastTime;
  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  int get unread;
  @override
  @JsonKey(fromJson: _boolOrFalse)
  bool get pinned;
  @override
  @JsonKey(fromJson: _boolOrFalse)
  bool get muted;

  /// 未发送的输入草稿（本地持久化）；为空表示无草稿。
  @override
  String? get draftText;

  /// Create a copy of Conversation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ConversationImplCopyWith<_$ConversationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
