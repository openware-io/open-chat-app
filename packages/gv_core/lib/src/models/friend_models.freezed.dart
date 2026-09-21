// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'friend_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FriendUserBrief _$FriendUserBriefFromJson(Map<String, dynamic> json) {
  return _FriendUserBrief.fromJson(json);
}

/// @nodoc
mixin _$FriendUserBrief {
  @JsonKey(fromJson: _jsonIntOrZero)
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get nickname => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;
  String? get signature => throw _privateConstructorUsedError;

  /// Serializes this FriendUserBrief to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FriendUserBrief
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FriendUserBriefCopyWith<FriendUserBrief> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendUserBriefCopyWith<$Res> {
  factory $FriendUserBriefCopyWith(
          FriendUserBrief value, $Res Function(FriendUserBrief) then) =
      _$FriendUserBriefCopyWithImpl<$Res, FriendUserBrief>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _jsonIntOrZero) int id,
      String username,
      String? nickname,
      String? avatar,
      String? signature});
}

/// @nodoc
class _$FriendUserBriefCopyWithImpl<$Res, $Val extends FriendUserBrief>
    implements $FriendUserBriefCopyWith<$Res> {
  _$FriendUserBriefCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FriendUserBrief
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? nickname = freezed,
    Object? avatar = freezed,
    Object? signature = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      signature: freezed == signature
          ? _value.signature
          : signature // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FriendUserBriefImplCopyWith<$Res>
    implements $FriendUserBriefCopyWith<$Res> {
  factory _$$FriendUserBriefImplCopyWith(_$FriendUserBriefImpl value,
          $Res Function(_$FriendUserBriefImpl) then) =
      __$$FriendUserBriefImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _jsonIntOrZero) int id,
      String username,
      String? nickname,
      String? avatar,
      String? signature});
}

/// @nodoc
class __$$FriendUserBriefImplCopyWithImpl<$Res>
    extends _$FriendUserBriefCopyWithImpl<$Res, _$FriendUserBriefImpl>
    implements _$$FriendUserBriefImplCopyWith<$Res> {
  __$$FriendUserBriefImplCopyWithImpl(
      _$FriendUserBriefImpl _value, $Res Function(_$FriendUserBriefImpl) _then)
      : super(_value, _then);

  /// Create a copy of FriendUserBrief
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? nickname = freezed,
    Object? avatar = freezed,
    Object? signature = freezed,
  }) {
    return _then(_$FriendUserBriefImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      nickname: freezed == nickname
          ? _value.nickname
          : nickname // ignore: cast_nullable_to_non_nullable
              as String?,
      avatar: freezed == avatar
          ? _value.avatar
          : avatar // ignore: cast_nullable_to_non_nullable
              as String?,
      signature: freezed == signature
          ? _value.signature
          : signature // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FriendUserBriefImpl extends _FriendUserBrief {
  const _$FriendUserBriefImpl(
      {@JsonKey(fromJson: _jsonIntOrZero) required this.id,
      this.username = '',
      this.nickname,
      this.avatar,
      this.signature})
      : super._();

  factory _$FriendUserBriefImpl.fromJson(Map<String, dynamic> json) =>
      _$$FriendUserBriefImplFromJson(json);

  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  final int id;
  @override
  @JsonKey()
  final String username;
  @override
  final String? nickname;
  @override
  final String? avatar;
  @override
  final String? signature;

  @override
  String toString() {
    return 'FriendUserBrief(id: $id, username: $username, nickname: $nickname, avatar: $avatar, signature: $signature)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendUserBriefImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.nickname, nickname) ||
                other.nickname == nickname) &&
            (identical(other.avatar, avatar) || other.avatar == avatar) &&
            (identical(other.signature, signature) ||
                other.signature == signature));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, username, nickname, avatar, signature);

  /// Create a copy of FriendUserBrief
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendUserBriefImplCopyWith<_$FriendUserBriefImpl> get copyWith =>
      __$$FriendUserBriefImplCopyWithImpl<_$FriendUserBriefImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FriendUserBriefImplToJson(
      this,
    );
  }
}

abstract class _FriendUserBrief extends FriendUserBrief {
  const factory _FriendUserBrief(
      {@JsonKey(fromJson: _jsonIntOrZero) required final int id,
      final String username,
      final String? nickname,
      final String? avatar,
      final String? signature}) = _$FriendUserBriefImpl;
  const _FriendUserBrief._() : super._();

  factory _FriendUserBrief.fromJson(Map<String, dynamic> json) =
      _$FriendUserBriefImpl.fromJson;

  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  int get id;
  @override
  String get username;
  @override
  String? get nickname;
  @override
  String? get avatar;
  @override
  String? get signature;

  /// Create a copy of FriendUserBrief
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FriendUserBriefImplCopyWith<_$FriendUserBriefImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FriendItem _$FriendItemFromJson(Map<String, dynamic> json) {
  return _FriendItem.fromJson(json);
}

/// @nodoc
mixin _$FriendItem {
  @JsonKey(
      name: 'friend_id', readValue: _readFriendId, fromJson: jsonIntRequired)
  int get friendId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id', readValue: _readUserId, fromJson: jsonInt)
  int? get userId => throw _privateConstructorUsedError;
  String? get remark => throw _privateConstructorUsedError;
  @JsonKey(name: 'group_name', readValue: _readGroupName)
  String? get groupName => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readFriendUser, fromJson: _friendUserFromJson)
  FriendUserBrief? get friendUser => throw _privateConstructorUsedError;

  /// Serializes this FriendItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FriendItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FriendItemCopyWith<FriendItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendItemCopyWith<$Res> {
  factory $FriendItemCopyWith(
          FriendItem value, $Res Function(FriendItem) then) =
      _$FriendItemCopyWithImpl<$Res, FriendItem>;
  @useResult
  $Res call(
      {@JsonKey(
          name: 'friend_id',
          readValue: _readFriendId,
          fromJson: jsonIntRequired)
      int friendId,
      @JsonKey(name: 'user_id', readValue: _readUserId, fromJson: jsonInt)
      int? userId,
      String? remark,
      @JsonKey(name: 'group_name', readValue: _readGroupName) String? groupName,
      @JsonKey(readValue: _readFriendUser, fromJson: _friendUserFromJson)
      FriendUserBrief? friendUser});

  $FriendUserBriefCopyWith<$Res>? get friendUser;
}

/// @nodoc
class _$FriendItemCopyWithImpl<$Res, $Val extends FriendItem>
    implements $FriendItemCopyWith<$Res> {
  _$FriendItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FriendItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friendId = null,
    Object? userId = freezed,
    Object? remark = freezed,
    Object? groupName = freezed,
    Object? friendUser = freezed,
  }) {
    return _then(_value.copyWith(
      friendId: null == friendId
          ? _value.friendId
          : friendId // ignore: cast_nullable_to_non_nullable
              as int,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int?,
      remark: freezed == remark
          ? _value.remark
          : remark // ignore: cast_nullable_to_non_nullable
              as String?,
      groupName: freezed == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String?,
      friendUser: freezed == friendUser
          ? _value.friendUser
          : friendUser // ignore: cast_nullable_to_non_nullable
              as FriendUserBrief?,
    ) as $Val);
  }

  /// Create a copy of FriendItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FriendUserBriefCopyWith<$Res>? get friendUser {
    if (_value.friendUser == null) {
      return null;
    }

    return $FriendUserBriefCopyWith<$Res>(_value.friendUser!, (value) {
      return _then(_value.copyWith(friendUser: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FriendItemImplCopyWith<$Res>
    implements $FriendItemCopyWith<$Res> {
  factory _$$FriendItemImplCopyWith(
          _$FriendItemImpl value, $Res Function(_$FriendItemImpl) then) =
      __$$FriendItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(
          name: 'friend_id',
          readValue: _readFriendId,
          fromJson: jsonIntRequired)
      int friendId,
      @JsonKey(name: 'user_id', readValue: _readUserId, fromJson: jsonInt)
      int? userId,
      String? remark,
      @JsonKey(name: 'group_name', readValue: _readGroupName) String? groupName,
      @JsonKey(readValue: _readFriendUser, fromJson: _friendUserFromJson)
      FriendUserBrief? friendUser});

  @override
  $FriendUserBriefCopyWith<$Res>? get friendUser;
}

/// @nodoc
class __$$FriendItemImplCopyWithImpl<$Res>
    extends _$FriendItemCopyWithImpl<$Res, _$FriendItemImpl>
    implements _$$FriendItemImplCopyWith<$Res> {
  __$$FriendItemImplCopyWithImpl(
      _$FriendItemImpl _value, $Res Function(_$FriendItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of FriendItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? friendId = null,
    Object? userId = freezed,
    Object? remark = freezed,
    Object? groupName = freezed,
    Object? friendUser = freezed,
  }) {
    return _then(_$FriendItemImpl(
      friendId: null == friendId
          ? _value.friendId
          : friendId // ignore: cast_nullable_to_non_nullable
              as int,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as int?,
      remark: freezed == remark
          ? _value.remark
          : remark // ignore: cast_nullable_to_non_nullable
              as String?,
      groupName: freezed == groupName
          ? _value.groupName
          : groupName // ignore: cast_nullable_to_non_nullable
              as String?,
      friendUser: freezed == friendUser
          ? _value.friendUser
          : friendUser // ignore: cast_nullable_to_non_nullable
              as FriendUserBrief?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FriendItemImpl extends _FriendItem {
  const _$FriendItemImpl(
      {@JsonKey(
          name: 'friend_id',
          readValue: _readFriendId,
          fromJson: jsonIntRequired)
      required this.friendId,
      @JsonKey(name: 'user_id', readValue: _readUserId, fromJson: jsonInt)
      this.userId,
      this.remark,
      @JsonKey(name: 'group_name', readValue: _readGroupName) this.groupName,
      @JsonKey(readValue: _readFriendUser, fromJson: _friendUserFromJson)
      this.friendUser})
      : super._();

  factory _$FriendItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$FriendItemImplFromJson(json);

  @override
  @JsonKey(
      name: 'friend_id', readValue: _readFriendId, fromJson: jsonIntRequired)
  final int friendId;
  @override
  @JsonKey(name: 'user_id', readValue: _readUserId, fromJson: jsonInt)
  final int? userId;
  @override
  final String? remark;
  @override
  @JsonKey(name: 'group_name', readValue: _readGroupName)
  final String? groupName;
  @override
  @JsonKey(readValue: _readFriendUser, fromJson: _friendUserFromJson)
  final FriendUserBrief? friendUser;

  @override
  String toString() {
    return 'FriendItem(friendId: $friendId, userId: $userId, remark: $remark, groupName: $groupName, friendUser: $friendUser)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendItemImpl &&
            (identical(other.friendId, friendId) ||
                other.friendId == friendId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.remark, remark) || other.remark == remark) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.friendUser, friendUser) ||
                other.friendUser == friendUser));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, friendId, userId, remark, groupName, friendUser);

  /// Create a copy of FriendItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendItemImplCopyWith<_$FriendItemImpl> get copyWith =>
      __$$FriendItemImplCopyWithImpl<_$FriendItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FriendItemImplToJson(
      this,
    );
  }
}

abstract class _FriendItem extends FriendItem {
  const factory _FriendItem(
      {@JsonKey(
          name: 'friend_id',
          readValue: _readFriendId,
          fromJson: jsonIntRequired)
      required final int friendId,
      @JsonKey(name: 'user_id', readValue: _readUserId, fromJson: jsonInt)
      final int? userId,
      final String? remark,
      @JsonKey(name: 'group_name', readValue: _readGroupName)
      final String? groupName,
      @JsonKey(readValue: _readFriendUser, fromJson: _friendUserFromJson)
      final FriendUserBrief? friendUser}) = _$FriendItemImpl;
  const _FriendItem._() : super._();

  factory _FriendItem.fromJson(Map<String, dynamic> json) =
      _$FriendItemImpl.fromJson;

  @override
  @JsonKey(
      name: 'friend_id', readValue: _readFriendId, fromJson: jsonIntRequired)
  int get friendId;
  @override
  @JsonKey(name: 'user_id', readValue: _readUserId, fromJson: jsonInt)
  int? get userId;
  @override
  String? get remark;
  @override
  @JsonKey(name: 'group_name', readValue: _readGroupName)
  String? get groupName;
  @override
  @JsonKey(readValue: _readFriendUser, fromJson: _friendUserFromJson)
  FriendUserBrief? get friendUser;

  /// Create a copy of FriendItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FriendItemImplCopyWith<_$FriendItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FriendRequestItem _$FriendRequestItemFromJson(Map<String, dynamic> json) {
  return _FriendRequestItem.fromJson(json);
}

/// @nodoc
mixin _$FriendRequestItem {
  @JsonKey(fromJson: jsonIntRequired)
  int get id => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'from_user_id',
      readValue: _readFromUserId,
      fromJson: jsonIntRequired)
  int get fromUserId => throw _privateConstructorUsedError;
  @JsonKey(
      name: 'to_user_id', readValue: _readToUserId, fromJson: jsonIntRequired)
  int get toUserId => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  @JsonKey(readValue: _readEmbeddedFromUser, fromJson: _fromUserBriefFromJson)
  FriendUserBrief? get fromUser => throw _privateConstructorUsedError;

  /// Serializes this FriendRequestItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FriendRequestItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FriendRequestItemCopyWith<FriendRequestItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendRequestItemCopyWith<$Res> {
  factory $FriendRequestItemCopyWith(
          FriendRequestItem value, $Res Function(FriendRequestItem) then) =
      _$FriendRequestItemCopyWithImpl<$Res, FriendRequestItem>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: jsonIntRequired) int id,
      @JsonKey(
          name: 'from_user_id',
          readValue: _readFromUserId,
          fromJson: jsonIntRequired)
      int fromUserId,
      @JsonKey(
          name: 'to_user_id',
          readValue: _readToUserId,
          fromJson: jsonIntRequired)
      int toUserId,
      String? message,
      String? status,
      @JsonKey(
          readValue: _readEmbeddedFromUser, fromJson: _fromUserBriefFromJson)
      FriendUserBrief? fromUser});

  $FriendUserBriefCopyWith<$Res>? get fromUser;
}

/// @nodoc
class _$FriendRequestItemCopyWithImpl<$Res, $Val extends FriendRequestItem>
    implements $FriendRequestItemCopyWith<$Res> {
  _$FriendRequestItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FriendRequestItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? message = freezed,
    Object? status = freezed,
    Object? fromUser = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      fromUserId: null == fromUserId
          ? _value.fromUserId
          : fromUserId // ignore: cast_nullable_to_non_nullable
              as int,
      toUserId: null == toUserId
          ? _value.toUserId
          : toUserId // ignore: cast_nullable_to_non_nullable
              as int,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      fromUser: freezed == fromUser
          ? _value.fromUser
          : fromUser // ignore: cast_nullable_to_non_nullable
              as FriendUserBrief?,
    ) as $Val);
  }

  /// Create a copy of FriendRequestItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $FriendUserBriefCopyWith<$Res>? get fromUser {
    if (_value.fromUser == null) {
      return null;
    }

    return $FriendUserBriefCopyWith<$Res>(_value.fromUser!, (value) {
      return _then(_value.copyWith(fromUser: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FriendRequestItemImplCopyWith<$Res>
    implements $FriendRequestItemCopyWith<$Res> {
  factory _$$FriendRequestItemImplCopyWith(_$FriendRequestItemImpl value,
          $Res Function(_$FriendRequestItemImpl) then) =
      __$$FriendRequestItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: jsonIntRequired) int id,
      @JsonKey(
          name: 'from_user_id',
          readValue: _readFromUserId,
          fromJson: jsonIntRequired)
      int fromUserId,
      @JsonKey(
          name: 'to_user_id',
          readValue: _readToUserId,
          fromJson: jsonIntRequired)
      int toUserId,
      String? message,
      String? status,
      @JsonKey(
          readValue: _readEmbeddedFromUser, fromJson: _fromUserBriefFromJson)
      FriendUserBrief? fromUser});

  @override
  $FriendUserBriefCopyWith<$Res>? get fromUser;
}

/// @nodoc
class __$$FriendRequestItemImplCopyWithImpl<$Res>
    extends _$FriendRequestItemCopyWithImpl<$Res, _$FriendRequestItemImpl>
    implements _$$FriendRequestItemImplCopyWith<$Res> {
  __$$FriendRequestItemImplCopyWithImpl(_$FriendRequestItemImpl _value,
      $Res Function(_$FriendRequestItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of FriendRequestItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fromUserId = null,
    Object? toUserId = null,
    Object? message = freezed,
    Object? status = freezed,
    Object? fromUser = freezed,
  }) {
    return _then(_$FriendRequestItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      fromUserId: null == fromUserId
          ? _value.fromUserId
          : fromUserId // ignore: cast_nullable_to_non_nullable
              as int,
      toUserId: null == toUserId
          ? _value.toUserId
          : toUserId // ignore: cast_nullable_to_non_nullable
              as int,
      message: freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      fromUser: freezed == fromUser
          ? _value.fromUser
          : fromUser // ignore: cast_nullable_to_non_nullable
              as FriendUserBrief?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FriendRequestItemImpl extends _FriendRequestItem {
  const _$FriendRequestItemImpl(
      {@JsonKey(fromJson: jsonIntRequired) required this.id,
      @JsonKey(
          name: 'from_user_id',
          readValue: _readFromUserId,
          fromJson: jsonIntRequired)
      required this.fromUserId,
      @JsonKey(
          name: 'to_user_id',
          readValue: _readToUserId,
          fromJson: jsonIntRequired)
      required this.toUserId,
      this.message,
      this.status,
      @JsonKey(
          readValue: _readEmbeddedFromUser, fromJson: _fromUserBriefFromJson)
      this.fromUser})
      : super._();

  factory _$FriendRequestItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$FriendRequestItemImplFromJson(json);

  @override
  @JsonKey(fromJson: jsonIntRequired)
  final int id;
  @override
  @JsonKey(
      name: 'from_user_id',
      readValue: _readFromUserId,
      fromJson: jsonIntRequired)
  final int fromUserId;
  @override
  @JsonKey(
      name: 'to_user_id', readValue: _readToUserId, fromJson: jsonIntRequired)
  final int toUserId;
  @override
  final String? message;
  @override
  final String? status;
  @override
  @JsonKey(readValue: _readEmbeddedFromUser, fromJson: _fromUserBriefFromJson)
  final FriendUserBrief? fromUser;

  @override
  String toString() {
    return 'FriendRequestItem(id: $id, fromUserId: $fromUserId, toUserId: $toUserId, message: $message, status: $status, fromUser: $fromUser)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendRequestItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fromUserId, fromUserId) ||
                other.fromUserId == fromUserId) &&
            (identical(other.toUserId, toUserId) ||
                other.toUserId == toUserId) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.fromUser, fromUser) ||
                other.fromUser == fromUser));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, fromUserId, toUserId, message, status, fromUser);

  /// Create a copy of FriendRequestItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendRequestItemImplCopyWith<_$FriendRequestItemImpl> get copyWith =>
      __$$FriendRequestItemImplCopyWithImpl<_$FriendRequestItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FriendRequestItemImplToJson(
      this,
    );
  }
}

abstract class _FriendRequestItem extends FriendRequestItem {
  const factory _FriendRequestItem(
      {@JsonKey(fromJson: jsonIntRequired) required final int id,
      @JsonKey(
          name: 'from_user_id',
          readValue: _readFromUserId,
          fromJson: jsonIntRequired)
      required final int fromUserId,
      @JsonKey(
          name: 'to_user_id',
          readValue: _readToUserId,
          fromJson: jsonIntRequired)
      required final int toUserId,
      final String? message,
      final String? status,
      @JsonKey(
          readValue: _readEmbeddedFromUser, fromJson: _fromUserBriefFromJson)
      final FriendUserBrief? fromUser}) = _$FriendRequestItemImpl;
  const _FriendRequestItem._() : super._();

  factory _FriendRequestItem.fromJson(Map<String, dynamic> json) =
      _$FriendRequestItemImpl.fromJson;

  @override
  @JsonKey(fromJson: jsonIntRequired)
  int get id;
  @override
  @JsonKey(
      name: 'from_user_id',
      readValue: _readFromUserId,
      fromJson: jsonIntRequired)
  int get fromUserId;
  @override
  @JsonKey(
      name: 'to_user_id', readValue: _readToUserId, fromJson: jsonIntRequired)
  int get toUserId;
  @override
  String? get message;
  @override
  String? get status;
  @override
  @JsonKey(readValue: _readEmbeddedFromUser, fromJson: _fromUserBriefFromJson)
  FriendUserBrief? get fromUser;

  /// Create a copy of FriendRequestItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FriendRequestItemImplCopyWith<_$FriendRequestItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
