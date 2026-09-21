// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GroupItem _$GroupItemFromJson(Map<String, dynamic> json) {
  return _GroupItem.fromJson(json);
}

/// @nodoc
mixin _$GroupItem {
  @JsonKey(fromJson: jsonIntRequired)
  int get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readGroupMemberCount, fromJson: _jsonIntOrNull)
  int? get memberCount => throw _privateConstructorUsedError;

  /// Serializes this GroupItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupItemCopyWith<GroupItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupItemCopyWith<$Res> {
  factory $GroupItemCopyWith(GroupItem value, $Res Function(GroupItem) then) =
      _$GroupItemCopyWithImpl<$Res, GroupItem>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: jsonIntRequired) int id,
      String name,
      String? avatar,
      @JsonKey(readValue: _readGroupMemberCount, fromJson: _jsonIntOrNull)
      int? memberCount});
}

/// @nodoc
class _$GroupItemCopyWithImpl<$Res, $Val extends GroupItem>
    implements $GroupItemCopyWith<$Res> {
  _$GroupItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? avatar = freezed,
    Object? memberCount = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      memberCount: freezed == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupItemImplCopyWith<$Res>
    implements $GroupItemCopyWith<$Res> {
  factory _$$GroupItemImplCopyWith(
          _$GroupItemImpl value, $Res Function(_$GroupItemImpl) then) =
      __$$GroupItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: jsonIntRequired) int id,
      String name,
      String? avatar,
      @JsonKey(readValue: _readGroupMemberCount, fromJson: _jsonIntOrNull)
      int? memberCount});
}

/// @nodoc
class __$$GroupItemImplCopyWithImpl<$Res>
    extends _$GroupItemCopyWithImpl<$Res, _$GroupItemImpl>
    implements _$$GroupItemImplCopyWith<$Res> {
  __$$GroupItemImplCopyWithImpl(
      _$GroupItemImpl _value, $Res Function(_$GroupItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of GroupItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? avatar = freezed,
    Object? memberCount = freezed,
  }) {
    return _then(_$GroupItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      memberCount: freezed == memberCount
          ? _value.memberCount
          : memberCount // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupItemImpl extends _GroupItem {
  const _$GroupItemImpl(
      {@JsonKey(fromJson: jsonIntRequired) required this.id,
      this.name = '',
      this.avatar,
      @JsonKey(readValue: _readGroupMemberCount, fromJson: _jsonIntOrNull)
      this.memberCount})
      : super._();

  factory _$GroupItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupItemImplFromJson(json);

  @override
  @JsonKey(fromJson: jsonIntRequired)
  final int id;
  @override
  @JsonKey()
  final String name;
  @override
  final String? avatar;
  @override
  @JsonKey(readValue: _readGroupMemberCount, fromJson: _jsonIntOrNull)
  final int? memberCount;

  @override
  String toString() {
    return 'GroupItem(id: $id, name: $name, avatar: $avatar, memberCount: $memberCount)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.memberCount, memberCount) ||
                other.memberCount == memberCount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, avatar, memberCount);

  /// Create a copy of GroupItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupItemImplCopyWith<_$GroupItemImpl> get copyWith =>
      __$$GroupItemImplCopyWithImpl<_$GroupItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupItemImplToJson(
      this,
    );
  }
}

abstract class _GroupItem extends GroupItem {
  const factory _GroupItem(
      {@JsonKey(fromJson: jsonIntRequired) required final int id,
      final String name,
      final String? avatar,
      @JsonKey(readValue: _readGroupMemberCount, fromJson: _jsonIntOrNull)
      final int? memberCount}) = _$GroupItemImpl;
  const _GroupItem._() : super._();

  factory _GroupItem.fromJson(Map<String, dynamic> json) =
      _$GroupItemImpl.fromJson;

  @override
  @JsonKey(fromJson: jsonIntRequired)
  int get id;
  @override
  String get name;
  @override
  String? get avatar;
  @override
  @JsonKey(readValue: _readGroupMemberCount, fromJson: _jsonIntOrNull)
  int? get memberCount;

  /// Create a copy of GroupItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupItemImplCopyWith<_$GroupItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) {
  return _GroupMember.fromJson(json);
}

/// @nodoc
mixin _$GroupMember {
  @JsonKey(
      name: 'user_id',
      readValue: _readGroupMemberUserId,
      fromJson: _jsonIntOrZero)
  int get userId => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readGroupMemberNickname, fromJson: _trimNullableString)
  String? get nickname => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readGroupMemberUsername, fromJson: _trimNullableString)
  String? get username => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readGroupMemberRole, fromJson: _trimNullableString)
  String? get role => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readGroupMemberAvatar, fromJson: _trimNullableString)
  String? get avatar => throw _privateConstructorUsedError;

  /// Serializes this GroupMember to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroupMemberCopyWith<GroupMember> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroupMemberCopyWith<$Res> {
  factory $GroupMemberCopyWith(
          GroupMember value, $Res Function(GroupMember) then) =
      _$GroupMemberCopyWithImpl<$Res, GroupMember>;
  @useResult
  $Res call(
      {@JsonKey(
          name: 'user_id',
          readValue: _readGroupMemberUserId,
          fromJson: _jsonIntOrZero)
      int userId,
      @JsonKey(
          readValue: _readGroupMemberNickname, fromJson: _trimNullableString)
      String? nickname,
      @JsonKey(
          readValue: _readGroupMemberUsername, fromJson: _trimNullableString)
      String? username,
      @JsonKey(readValue: _readGroupMemberRole, fromJson: _trimNullableString)
      String? role,
      @JsonKey(readValue: _readGroupMemberAvatar, fromJson: _trimNullableString)
      String? avatar});
}

/// @nodoc
class _$GroupMemberCopyWithImpl<$Res, $Val extends GroupMember>
    implements $GroupMemberCopyWith<$Res> {
  _$GroupMemberCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? nickname = freezed,
    Object? username = freezed,
    Object? role = freezed,
    Object? avatar = freezed,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroupMemberImplCopyWith<$Res>
    implements $GroupMemberCopyWith<$Res> {
  factory _$$GroupMemberImplCopyWith(
          _$GroupMemberImpl value, $Res Function(_$GroupMemberImpl) then) =
      __$$GroupMemberImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(
          name: 'user_id',
          readValue: _readGroupMemberUserId,
          fromJson: _jsonIntOrZero)
      int userId,
      @JsonKey(
          readValue: _readGroupMemberNickname, fromJson: _trimNullableString)
      String? nickname,
      @JsonKey(
          readValue: _readGroupMemberUsername, fromJson: _trimNullableString)
      String? username,
      @JsonKey(readValue: _readGroupMemberRole, fromJson: _trimNullableString)
      String? role,
      @JsonKey(readValue: _readGroupMemberAvatar, fromJson: _trimNullableString)
      String? avatar});
}

/// @nodoc
class __$$GroupMemberImplCopyWithImpl<$Res>
    extends _$GroupMemberCopyWithImpl<$Res, _$GroupMemberImpl>
    implements _$$GroupMemberImplCopyWith<$Res> {
  __$$GroupMemberImplCopyWithImpl(
      _$GroupMemberImpl _value, $Res Function(_$GroupMemberImpl) _then)
      : super(_value, _then);

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? nickname = freezed,
    Object? username = freezed,
    Object? role = freezed,
    Object? avatar = freezed,
  }) {
    return _then(_$GroupMemberImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      username: freezed == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String?,
      role: freezed == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroupMemberImpl extends _GroupMember {
  const _$GroupMemberImpl(
      {@JsonKey(
          name: 'user_id',
          readValue: _readGroupMemberUserId,
          fromJson: _jsonIntOrZero)
      required this.userId,
      @JsonKey(
          readValue: _readGroupMemberNickname, fromJson: _trimNullableString)
      this.nickname,
      @JsonKey(
          readValue: _readGroupMemberUsername, fromJson: _trimNullableString)
      this.username,
      @JsonKey(readValue: _readGroupMemberRole, fromJson: _trimNullableString)
      this.role,
      @JsonKey(readValue: _readGroupMemberAvatar, fromJson: _trimNullableString)
      this.avatar})
      : super._();

  factory _$GroupMemberImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroupMemberImplFromJson(json);

  @override
  @JsonKey(
      name: 'user_id',
      readValue: _readGroupMemberUserId,
      fromJson: _jsonIntOrZero)
  final int userId;
  @override
  @JsonKey(readValue: _readGroupMemberNickname, fromJson: _trimNullableString)
  final String? nickname;
  @override
  @JsonKey(readValue: _readGroupMemberUsername, fromJson: _trimNullableString)
  final String? username;
  @override
  @JsonKey(readValue: _readGroupMemberRole, fromJson: _trimNullableString)
  final String? role;
  @override
  @JsonKey(readValue: _readGroupMemberAvatar, fromJson: _trimNullableString)
  final String? avatar;

  @override
  String toString() {
    return 'GroupMember(userId: $userId, nickname: $nickname, username: $username, role: $role, avatar: $avatar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroupMemberImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.avatar, avatar) || other.avatar == avatar));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, nickname, username, role, avatar);

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroupMemberImplCopyWith<_$GroupMemberImpl> get copyWith =>
      __$$GroupMemberImplCopyWithImpl<_$GroupMemberImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroupMemberImplToJson(
      this,
    );
  }
}

abstract class _GroupMember extends GroupMember {
  const factory _GroupMember(
      {@JsonKey(
          name: 'user_id',
          readValue: _readGroupMemberUserId,
          fromJson: _jsonIntOrZero)
      required final int userId,
      @JsonKey(
          readValue: _readGroupMemberNickname, fromJson: _trimNullableString)
      final String? nickname,
      @JsonKey(
          readValue: _readGroupMemberUsername, fromJson: _trimNullableString)
      final String? username,
      @JsonKey(readValue: _readGroupMemberRole, fromJson: _trimNullableString)
      final String? role,
      @JsonKey(readValue: _readGroupMemberAvatar, fromJson: _trimNullableString)
      final String? avatar}) = _$GroupMemberImpl;
  const _GroupMember._() : super._();

  factory _GroupMember.fromJson(Map<String, dynamic> json) =
      _$GroupMemberImpl.fromJson;

  @override
  @JsonKey(
      name: 'user_id',
      readValue: _readGroupMemberUserId,
      fromJson: _jsonIntOrZero)
  int get userId;
  @override
  @JsonKey(readValue: _readGroupMemberNickname, fromJson: _trimNullableString)
  String? get nickname;
  @override
  @JsonKey(readValue: _readGroupMemberUsername, fromJson: _trimNullableString)
  String? get username;
  @override
  @JsonKey(readValue: _readGroupMemberRole, fromJson: _trimNullableString)
  String? get role;
  @override
  @JsonKey(readValue: _readGroupMemberAvatar, fromJson: _trimNullableString)
  String? get avatar;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroupMemberImplCopyWith<_$GroupMemberImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
