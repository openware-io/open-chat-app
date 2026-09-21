// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mini_app_service_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MiniAppServiceItem _$MiniAppServiceItemFromJson(Map<String, dynamic> json) {
  return _MiniAppServiceItem.fromJson(json);
}

/// @nodoc
mixin _$MiniAppServiceItem {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'icon')
  String get iconPath => throw _privateConstructorUsedError;
  String get introduction => throw _privateConstructorUsedError;
  @JsonKey(name: 'link')
  String get entryUrl => throw _privateConstructorUsedError;
  String get audience => throw _privateConstructorUsedError;

  /// Serializes this MiniAppServiceItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MiniAppServiceItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MiniAppServiceItemCopyWith<MiniAppServiceItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MiniAppServiceItemCopyWith<$Res> {
  factory $MiniAppServiceItemCopyWith(
          MiniAppServiceItem value, $Res Function(MiniAppServiceItem) then) =
      _$MiniAppServiceItemCopyWithImpl<$Res, MiniAppServiceItem>;
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'icon') String iconPath,
      String introduction,
      @JsonKey(name: 'link') String entryUrl,
      String audience});
}

/// @nodoc
class _$MiniAppServiceItemCopyWithImpl<$Res, $Val extends MiniAppServiceItem>
    implements $MiniAppServiceItemCopyWith<$Res> {
  _$MiniAppServiceItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MiniAppServiceItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? iconPath = null,
    Object? introduction = null,
    Object? entryUrl = null,
    Object? audience = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      iconPath: null == iconPath
          ? _value.iconPath
          : iconPath // ignore: cast_nullable_to_non_nullable
              as String,
      introduction: null == introduction
          ? _value.introduction
          : introduction // ignore: cast_nullable_to_non_nullable
              as String,
      entryUrl: null == entryUrl
          ? _value.entryUrl
          : entryUrl // ignore: cast_nullable_to_non_nullable
              as String,
      audience: null == audience
          ? _value.audience
          : audience // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MiniAppServiceItemImplCopyWith<$Res>
    implements $MiniAppServiceItemCopyWith<$Res> {
  factory _$$MiniAppServiceItemImplCopyWith(_$MiniAppServiceItemImpl value,
          $Res Function(_$MiniAppServiceItemImpl) then) =
      __$$MiniAppServiceItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      @JsonKey(name: 'icon') String iconPath,
      String introduction,
      @JsonKey(name: 'link') String entryUrl,
      String audience});
}

/// @nodoc
class __$$MiniAppServiceItemImplCopyWithImpl<$Res>
    extends _$MiniAppServiceItemCopyWithImpl<$Res, _$MiniAppServiceItemImpl>
    implements _$$MiniAppServiceItemImplCopyWith<$Res> {
  __$$MiniAppServiceItemImplCopyWithImpl(_$MiniAppServiceItemImpl _value,
      $Res Function(_$MiniAppServiceItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of MiniAppServiceItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? iconPath = null,
    Object? introduction = null,
    Object? entryUrl = null,
    Object? audience = null,
  }) {
    return _then(_$MiniAppServiceItemImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      iconPath: null == iconPath
          ? _value.iconPath
          : iconPath // ignore: cast_nullable_to_non_nullable
              as String,
      introduction: null == introduction
          ? _value.introduction
          : introduction // ignore: cast_nullable_to_non_nullable
              as String,
      entryUrl: null == entryUrl
          ? _value.entryUrl
          : entryUrl // ignore: cast_nullable_to_non_nullable
              as String,
      audience: null == audience
          ? _value.audience
          : audience // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MiniAppServiceItemImpl extends _MiniAppServiceItem {
  const _$MiniAppServiceItemImpl(
      {this.id = '',
      required this.name,
      @JsonKey(name: 'icon') required this.iconPath,
      this.introduction = '',
      @JsonKey(name: 'link') this.entryUrl = '',
      this.audience = kMiniAppAudienceConsumer})
      : super._();

  factory _$MiniAppServiceItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MiniAppServiceItemImplFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  final String name;
  @override
  @JsonKey(name: 'icon')
  final String iconPath;
  @override
  @JsonKey()
  final String introduction;
  @override
  @JsonKey(name: 'link')
  final String entryUrl;
  @override
  @JsonKey()
  final String audience;

  @override
  String toString() {
    return 'MiniAppServiceItem(id: $id, name: $name, iconPath: $iconPath, introduction: $introduction, entryUrl: $entryUrl, audience: $audience)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MiniAppServiceItemImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.iconPath, iconPath) ||
                other.iconPath == iconPath) &&
            (identical(other.introduction, introduction) ||
                other.introduction == introduction) &&
            (identical(other.entryUrl, entryUrl) ||
                other.entryUrl == entryUrl) &&
            (identical(other.audience, audience) ||
                other.audience == audience));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, iconPath, introduction, entryUrl, audience);

  /// Create a copy of MiniAppServiceItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MiniAppServiceItemImplCopyWith<_$MiniAppServiceItemImpl> get copyWith =>
      __$$MiniAppServiceItemImplCopyWithImpl<_$MiniAppServiceItemImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MiniAppServiceItemImplToJson(
      this,
    );
  }
}

abstract class _MiniAppServiceItem extends MiniAppServiceItem {
  const factory _MiniAppServiceItem(
      {final String id,
      required final String name,
      @JsonKey(name: 'icon') required final String iconPath,
      final String introduction,
      @JsonKey(name: 'link') final String entryUrl,
      final String audience}) = _$MiniAppServiceItemImpl;
  const _MiniAppServiceItem._() : super._();

  factory _MiniAppServiceItem.fromJson(Map<String, dynamic> json) =
      _$MiniAppServiceItemImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'icon')
  String get iconPath;
  @override
  String get introduction;
  @override
  @JsonKey(name: 'link')
  String get entryUrl;
  @override
  String get audience;

  /// Create a copy of MiniAppServiceItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MiniAppServiceItemImplCopyWith<_$MiniAppServiceItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MiniAppServiceCategory _$MiniAppServiceCategoryFromJson(
    Map<String, dynamic> json) {
  return _MiniAppServiceCategory.fromJson(json);
}

/// @nodoc
mixin _$MiniAppServiceCategory {
  String get typeName => throw _privateConstructorUsedError;
  List<MiniAppServiceItem> get items => throw _privateConstructorUsedError;

  /// Serializes this MiniAppServiceCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MiniAppServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MiniAppServiceCategoryCopyWith<MiniAppServiceCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MiniAppServiceCategoryCopyWith<$Res> {
  factory $MiniAppServiceCategoryCopyWith(MiniAppServiceCategory value,
          $Res Function(MiniAppServiceCategory) then) =
      _$MiniAppServiceCategoryCopyWithImpl<$Res, MiniAppServiceCategory>;
  @useResult
  $Res call({String typeName, List<MiniAppServiceItem> items});
}

/// @nodoc
class _$MiniAppServiceCategoryCopyWithImpl<$Res,
        $Val extends MiniAppServiceCategory>
    implements $MiniAppServiceCategoryCopyWith<$Res> {
  _$MiniAppServiceCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MiniAppServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? typeName = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      typeName: null == typeName
          ? _value.typeName
          : typeName // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MiniAppServiceItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MiniAppServiceCategoryImplCopyWith<$Res>
    implements $MiniAppServiceCategoryCopyWith<$Res> {
  factory _$$MiniAppServiceCategoryImplCopyWith(
          _$MiniAppServiceCategoryImpl value,
          $Res Function(_$MiniAppServiceCategoryImpl) then) =
      __$$MiniAppServiceCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String typeName, List<MiniAppServiceItem> items});
}

/// @nodoc
class __$$MiniAppServiceCategoryImplCopyWithImpl<$Res>
    extends _$MiniAppServiceCategoryCopyWithImpl<$Res,
        _$MiniAppServiceCategoryImpl>
    implements _$$MiniAppServiceCategoryImplCopyWith<$Res> {
  __$$MiniAppServiceCategoryImplCopyWithImpl(
      _$MiniAppServiceCategoryImpl _value,
      $Res Function(_$MiniAppServiceCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of MiniAppServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? typeName = null,
    Object? items = null,
  }) {
    return _then(_$MiniAppServiceCategoryImpl(
      typeName: null == typeName
          ? _value.typeName
          : typeName // ignore: cast_nullable_to_non_nullable
              as String,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<MiniAppServiceItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MiniAppServiceCategoryImpl extends _MiniAppServiceCategory {
  const _$MiniAppServiceCategoryImpl(
      {required this.typeName, required final List<MiniAppServiceItem> items})
      : _items = items,
        super._();

  factory _$MiniAppServiceCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$MiniAppServiceCategoryImplFromJson(json);

  @override
  final String typeName;
  final List<MiniAppServiceItem> _items;
  @override
  List<MiniAppServiceItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'MiniAppServiceCategory(typeName: $typeName, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MiniAppServiceCategoryImpl &&
            (identical(other.typeName, typeName) ||
                other.typeName == typeName) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, typeName, const DeepCollectionEquality().hash(_items));

  /// Create a copy of MiniAppServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MiniAppServiceCategoryImplCopyWith<_$MiniAppServiceCategoryImpl>
      get copyWith => __$$MiniAppServiceCategoryImplCopyWithImpl<
          _$MiniAppServiceCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MiniAppServiceCategoryImplToJson(
      this,
    );
  }
}

abstract class _MiniAppServiceCategory extends MiniAppServiceCategory {
  const factory _MiniAppServiceCategory(
          {required final String typeName,
          required final List<MiniAppServiceItem> items}) =
      _$MiniAppServiceCategoryImpl;
  const _MiniAppServiceCategory._() : super._();

  factory _MiniAppServiceCategory.fromJson(Map<String, dynamic> json) =
      _$MiniAppServiceCategoryImpl.fromJson;

  @override
  String get typeName;
  @override
  List<MiniAppServiceItem> get items;

  /// Create a copy of MiniAppServiceCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MiniAppServiceCategoryImplCopyWith<_$MiniAppServiceCategoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}
