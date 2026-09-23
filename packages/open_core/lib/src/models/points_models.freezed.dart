// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'points_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PointsLedgerItem _$PointsLedgerItemFromJson(Map<String, dynamic> json) {
  return _PointsLedgerItem.fromJson(json);
}

/// @nodoc
mixin _$PointsLedgerItem {
  @JsonKey(fromJson: _jsonIntOrZero)
  int get id => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _dateTimeFromJson)
  DateTime get createdAt => throw _privateConstructorUsedError;
  String get entryType => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _jsonIntOrZero)
  int get amount => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _jsonIntOrZero)
  int get balanceAfter => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;

  /// Serializes this PointsLedgerItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PointsLedgerItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointsLedgerItemCopyWith<PointsLedgerItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointsLedgerItemCopyWith<$Res> {
  factory $PointsLedgerItemCopyWith(
          PointsLedgerItem value, $Res Function(PointsLedgerItem) then) =
      _$PointsLedgerItemCopyWithImpl<$Res, PointsLedgerItem>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _jsonIntOrZero) int id,
      @JsonKey(fromJson: _dateTimeFromJson) DateTime createdAt,
      String entryType,
      @JsonKey(fromJson: _jsonIntOrZero) int amount,
      @JsonKey(fromJson: _jsonIntOrZero) int balanceAfter,
      String reason});
}

/// @nodoc
class _$PointsLedgerItemCopyWithImpl<$Res, $Val extends PointsLedgerItem>
    implements $PointsLedgerItemCopyWith<$Res> {
  _$PointsLedgerItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PointsLedgerItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = null,
    Object? entryType = null,
    Object? amount = null,
    Object? balanceAfter = null,
    Object? reason = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      entryType: null == entryType
          ? _value.entryType
          : entryType // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      balanceAfter: null == balanceAfter
          ? _value.balanceAfter
          : balanceAfter // ignore: cast_nullable_to_non_nullable
              as int,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PointsLedgerItemImplCopyWith<$Res>
    implements $PointsLedgerItemCopyWith<$Res> {
  factory _$$PointsLedgerItemImplCopyWith(_$PointsLedgerItemImpl value,
          $Res Function(_$PointsLedgerItemImpl) then) =
      __$$PointsLedgerItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _jsonIntOrZero) int id,
      @JsonKey(fromJson: _dateTimeFromJson) DateTime createdAt,
      String entryType,
      @JsonKey(fromJson: _jsonIntOrZero) int amount,
      @JsonKey(fromJson: _jsonIntOrZero) int balanceAfter,
      String reason});
}

/// @nodoc
class __$$PointsLedgerItemImplCopyWithImpl<$Res>
    extends _$PointsLedgerItemCopyWithImpl<$Res, _$PointsLedgerItemImpl>
    implements _$$PointsLedgerItemImplCopyWith<$Res> {
  __$$PointsLedgerItemImplCopyWithImpl(_$PointsLedgerItemImpl _value,
      $Res Function(_$PointsLedgerItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of PointsLedgerItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? createdAt = null,
    Object? entryType = null,
    Object? amount = null,
    Object? balanceAfter = null,
    Object? reason = null,
  }) {
    return _then(_$PointsLedgerItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      entryType: null == entryType
          ? _value.entryType
          : entryType // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as int,
      balanceAfter: null == balanceAfter
          ? _value.balanceAfter
          : balanceAfter // ignore: cast_nullable_to_non_nullable
              as int,
      reason: null == reason
          ? _value.reason
          : reason // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointsLedgerItemImpl extends _PointsLedgerItem {
  const _$PointsLedgerItemImpl(
      {@JsonKey(fromJson: _jsonIntOrZero) required this.id,
      @JsonKey(fromJson: _dateTimeFromJson) required this.createdAt,
      this.entryType = '',
      @JsonKey(fromJson: _jsonIntOrZero) this.amount = 0,
      @JsonKey(fromJson: _jsonIntOrZero) this.balanceAfter = 0,
      this.reason = ''})
      : super._();

  factory _$PointsLedgerItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointsLedgerItemImplFromJson(json);

  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  final int id;
  @override
  @JsonKey(fromJson: _dateTimeFromJson)
  final DateTime createdAt;
  @override
  @JsonKey()
  final String entryType;
  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  final int amount;
  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  final int balanceAfter;
  @override
  @JsonKey()
  final String reason;

  @override
  String toString() {
    return 'PointsLedgerItem(id: $id, createdAt: $createdAt, entryType: $entryType, amount: $amount, balanceAfter: $balanceAfter, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointsLedgerItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.entryType, entryType) ||
                other.entryType == entryType) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.balanceAfter, balanceAfter) ||
                other.balanceAfter == balanceAfter) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, createdAt, entryType, amount, balanceAfter, reason);

  /// Create a copy of PointsLedgerItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointsLedgerItemImplCopyWith<_$PointsLedgerItemImpl> get copyWith =>
      __$$PointsLedgerItemImplCopyWithImpl<_$PointsLedgerItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PointsLedgerItemImplToJson(
      this,
    );
  }
}

abstract class _PointsLedgerItem extends PointsLedgerItem {
  const factory _PointsLedgerItem(
      {@JsonKey(fromJson: _jsonIntOrZero) required final int id,
      @JsonKey(fromJson: _dateTimeFromJson) required final DateTime createdAt,
      final String entryType,
      @JsonKey(fromJson: _jsonIntOrZero) final int amount,
      @JsonKey(fromJson: _jsonIntOrZero) final int balanceAfter,
      final String reason}) = _$PointsLedgerItemImpl;
  const _PointsLedgerItem._() : super._();

  factory _PointsLedgerItem.fromJson(Map<String, dynamic> json) =
      _$PointsLedgerItemImpl.fromJson;

  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  int get id;
  @override
  @JsonKey(fromJson: _dateTimeFromJson)
  DateTime get createdAt;
  @override
  String get entryType;
  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  int get amount;
  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  int get balanceAfter;
  @override
  String get reason;

  /// Create a copy of PointsLedgerItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointsLedgerItemImplCopyWith<_$PointsLedgerItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PointsLedgerPage _$PointsLedgerPageFromJson(Map<String, dynamic> json) {
  return _PointsLedgerPage.fromJson(json);
}

/// @nodoc
mixin _$PointsLedgerPage {
  List<PointsLedgerItem> get items => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _jsonIntOrZero)
  int get total => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _jsonIntOrOne)
  int get page => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _jsonIntOrTwenty)
  int get pageSize => throw _privateConstructorUsedError;

  /// Serializes this PointsLedgerPage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PointsLedgerPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointsLedgerPageCopyWith<PointsLedgerPage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointsLedgerPageCopyWith<$Res> {
  factory $PointsLedgerPageCopyWith(
          PointsLedgerPage value, $Res Function(PointsLedgerPage) then) =
      _$PointsLedgerPageCopyWithImpl<$Res, PointsLedgerPage>;
  @useResult
  $Res call(
      {List<PointsLedgerItem> items,
      @JsonKey(fromJson: _jsonIntOrZero) int total,
      @JsonKey(fromJson: _jsonIntOrOne) int page,
      @JsonKey(fromJson: _jsonIntOrTwenty) int pageSize});
}

/// @nodoc
class _$PointsLedgerPageCopyWithImpl<$Res, $Val extends PointsLedgerPage>
    implements $PointsLedgerPageCopyWith<$Res> {
  _$PointsLedgerPageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PointsLedgerPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? pageSize = null,
  }) {
    return _then(_value.copyWith(
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PointsLedgerItem>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PointsLedgerPageImplCopyWith<$Res>
    implements $PointsLedgerPageCopyWith<$Res> {
  factory _$$PointsLedgerPageImplCopyWith(_$PointsLedgerPageImpl value,
          $Res Function(_$PointsLedgerPageImpl) then) =
      __$$PointsLedgerPageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<PointsLedgerItem> items,
      @JsonKey(fromJson: _jsonIntOrZero) int total,
      @JsonKey(fromJson: _jsonIntOrOne) int page,
      @JsonKey(fromJson: _jsonIntOrTwenty) int pageSize});
}

/// @nodoc
class __$$PointsLedgerPageImplCopyWithImpl<$Res>
    extends _$PointsLedgerPageCopyWithImpl<$Res, _$PointsLedgerPageImpl>
    implements _$$PointsLedgerPageImplCopyWith<$Res> {
  __$$PointsLedgerPageImplCopyWithImpl(_$PointsLedgerPageImpl _value,
      $Res Function(_$PointsLedgerPageImpl) _then)
      : super(_value, _then);

  /// Create a copy of PointsLedgerPage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? items = null,
    Object? total = null,
    Object? page = null,
    Object? pageSize = null,
  }) {
    return _then(_$PointsLedgerPageImpl(
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<PointsLedgerItem>,
      total: null == total
          ? _value.total
          : total // ignore: cast_nullable_to_non_nullable
              as int,
      page: null == page
          ? _value.page
          : page // ignore: cast_nullable_to_non_nullable
              as int,
      pageSize: null == pageSize
          ? _value.pageSize
          : pageSize // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PointsLedgerPageImpl extends _PointsLedgerPage {
  const _$PointsLedgerPageImpl(
      {final List<PointsLedgerItem> items = const <PointsLedgerItem>[],
      @JsonKey(fromJson: _jsonIntOrZero) this.total = 0,
      @JsonKey(fromJson: _jsonIntOrOne) this.page = 1,
      @JsonKey(fromJson: _jsonIntOrTwenty) this.pageSize = 20})
      : _items = items,
        super._();

  factory _$PointsLedgerPageImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointsLedgerPageImplFromJson(json);

  final List<PointsLedgerItem> _items;
  @override
  @JsonKey()
  List<PointsLedgerItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  final int total;
  @override
  @JsonKey(fromJson: _jsonIntOrOne)
  final int page;
  @override
  @JsonKey(fromJson: _jsonIntOrTwenty)
  final int pageSize;

  @override
  String toString() {
    return 'PointsLedgerPage(items: $items, total: $total, page: $page, pageSize: $pageSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointsLedgerPageImpl &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.total, total) || other.total == total) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.pageSize, pageSize) ||
                other.pageSize == pageSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_items), total, page, pageSize);

  /// Create a copy of PointsLedgerPage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointsLedgerPageImplCopyWith<_$PointsLedgerPageImpl> get copyWith =>
      __$$PointsLedgerPageImplCopyWithImpl<_$PointsLedgerPageImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PointsLedgerPageImplToJson(
      this,
    );
  }
}

abstract class _PointsLedgerPage extends PointsLedgerPage {
  const factory _PointsLedgerPage(
          {final List<PointsLedgerItem> items,
          @JsonKey(fromJson: _jsonIntOrZero) final int total,
          @JsonKey(fromJson: _jsonIntOrOne) final int page,
          @JsonKey(fromJson: _jsonIntOrTwenty) final int pageSize}) =
      _$PointsLedgerPageImpl;
  const _PointsLedgerPage._() : super._();

  factory _PointsLedgerPage.fromJson(Map<String, dynamic> json) =
      _$PointsLedgerPageImpl.fromJson;

  @override
  List<PointsLedgerItem> get items;
  @override
  @JsonKey(fromJson: _jsonIntOrZero)
  int get total;
  @override
  @JsonKey(fromJson: _jsonIntOrOne)
  int get page;
  @override
  @JsonKey(fromJson: _jsonIntOrTwenty)
  int get pageSize;

  /// Create a copy of PointsLedgerPage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointsLedgerPageImplCopyWith<_$PointsLedgerPageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
