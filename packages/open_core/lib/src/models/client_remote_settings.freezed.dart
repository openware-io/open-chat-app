// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_remote_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ClientRemoteSettings _$ClientRemoteSettingsFromJson(Map<String, dynamic> json) {
  return _ClientRemoteSettings.fromJson(json);
}

/// @nodoc
mixin _$ClientRemoteSettings {
  @JsonKey(fromJson: _appBlockFromJson)
  ClientAppBlock get app => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _featureBlockFromJson)
  ClientFeatureBlock get feature => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _rtcBlockFromJson)
  ClientRtcBlock get rtc => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _uploadBlockFromJson)
  ClientUploadBlock get upload => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _pushBlockFromJson)
  ClientPushBlock get push => throw _privateConstructorUsedError;

  /// Serializes this ClientRemoteSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientRemoteSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientRemoteSettingsCopyWith<ClientRemoteSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientRemoteSettingsCopyWith<$Res> {
  factory $ClientRemoteSettingsCopyWith(ClientRemoteSettings value,
          $Res Function(ClientRemoteSettings) then) =
      _$ClientRemoteSettingsCopyWithImpl<$Res, ClientRemoteSettings>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _appBlockFromJson) ClientAppBlock app,
      @JsonKey(fromJson: _featureBlockFromJson) ClientFeatureBlock feature,
      @JsonKey(fromJson: _rtcBlockFromJson) ClientRtcBlock rtc,
      @JsonKey(fromJson: _uploadBlockFromJson) ClientUploadBlock upload,
      @JsonKey(fromJson: _pushBlockFromJson) ClientPushBlock push});

  $ClientAppBlockCopyWith<$Res> get app;
  $ClientFeatureBlockCopyWith<$Res> get feature;
  $ClientRtcBlockCopyWith<$Res> get rtc;
  $ClientUploadBlockCopyWith<$Res> get upload;
  $ClientPushBlockCopyWith<$Res> get push;
}

/// @nodoc
class _$ClientRemoteSettingsCopyWithImpl<$Res,
        $Val extends ClientRemoteSettings>
    implements $ClientRemoteSettingsCopyWith<$Res> {
  _$ClientRemoteSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientRemoteSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? app = null,
    Object? feature = null,
    Object? rtc = null,
    Object? upload = null,
    Object? push = null,
  }) {
    return _then(_value.copyWith(
      app: null == app
          ? _value.app
          : app // ignore: cast_nullable_to_non_nullable
              as ClientAppBlock,
      feature: null == feature
          ? _value.feature
          : feature // ignore: cast_nullable_to_non_nullable
              as ClientFeatureBlock,
      rtc: null == rtc
          ? _value.rtc
          : rtc // ignore: cast_nullable_to_non_nullable
              as ClientRtcBlock,
      upload: null == upload
          ? _value.upload
          : upload // ignore: cast_nullable_to_non_nullable
              as ClientUploadBlock,
      push: null == push
          ? _value.push
          : push // ignore: cast_nullable_to_non_nullable
              as ClientPushBlock,
    ) as $Val);
  }

  /// Create a copy of ClientRemoteSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClientAppBlockCopyWith<$Res> get app {
    return $ClientAppBlockCopyWith<$Res>(_value.app, (value) {
      return _then(_value.copyWith(app: value) as $Val);
    });
  }

  /// Create a copy of ClientRemoteSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClientFeatureBlockCopyWith<$Res> get feature {
    return $ClientFeatureBlockCopyWith<$Res>(_value.feature, (value) {
      return _then(_value.copyWith(feature: value) as $Val);
    });
  }

  /// Create a copy of ClientRemoteSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClientRtcBlockCopyWith<$Res> get rtc {
    return $ClientRtcBlockCopyWith<$Res>(_value.rtc, (value) {
      return _then(_value.copyWith(rtc: value) as $Val);
    });
  }

  /// Create a copy of ClientRemoteSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClientUploadBlockCopyWith<$Res> get upload {
    return $ClientUploadBlockCopyWith<$Res>(_value.upload, (value) {
      return _then(_value.copyWith(upload: value) as $Val);
    });
  }

  /// Create a copy of ClientRemoteSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ClientPushBlockCopyWith<$Res> get push {
    return $ClientPushBlockCopyWith<$Res>(_value.push, (value) {
      return _then(_value.copyWith(push: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ClientRemoteSettingsImplCopyWith<$Res>
    implements $ClientRemoteSettingsCopyWith<$Res> {
  factory _$$ClientRemoteSettingsImplCopyWith(_$ClientRemoteSettingsImpl value,
          $Res Function(_$ClientRemoteSettingsImpl) then) =
      __$$ClientRemoteSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _appBlockFromJson) ClientAppBlock app,
      @JsonKey(fromJson: _featureBlockFromJson) ClientFeatureBlock feature,
      @JsonKey(fromJson: _rtcBlockFromJson) ClientRtcBlock rtc,
      @JsonKey(fromJson: _uploadBlockFromJson) ClientUploadBlock upload,
      @JsonKey(fromJson: _pushBlockFromJson) ClientPushBlock push});

  @override
  $ClientAppBlockCopyWith<$Res> get app;
  @override
  $ClientFeatureBlockCopyWith<$Res> get feature;
  @override
  $ClientRtcBlockCopyWith<$Res> get rtc;
  @override
  $ClientUploadBlockCopyWith<$Res> get upload;
  @override
  $ClientPushBlockCopyWith<$Res> get push;
}

/// @nodoc
class __$$ClientRemoteSettingsImplCopyWithImpl<$Res>
    extends _$ClientRemoteSettingsCopyWithImpl<$Res, _$ClientRemoteSettingsImpl>
    implements _$$ClientRemoteSettingsImplCopyWith<$Res> {
  __$$ClientRemoteSettingsImplCopyWithImpl(_$ClientRemoteSettingsImpl _value,
      $Res Function(_$ClientRemoteSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientRemoteSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? app = null,
    Object? feature = null,
    Object? rtc = null,
    Object? upload = null,
    Object? push = null,
  }) {
    return _then(_$ClientRemoteSettingsImpl(
      app: null == app
          ? _value.app
          : app // ignore: cast_nullable_to_non_nullable
              as ClientAppBlock,
      feature: null == feature
          ? _value.feature
          : feature // ignore: cast_nullable_to_non_nullable
              as ClientFeatureBlock,
      rtc: null == rtc
          ? _value.rtc
          : rtc // ignore: cast_nullable_to_non_nullable
              as ClientRtcBlock,
      upload: null == upload
          ? _value.upload
          : upload // ignore: cast_nullable_to_non_nullable
              as ClientUploadBlock,
      push: null == push
          ? _value.push
          : push // ignore: cast_nullable_to_non_nullable
              as ClientPushBlock,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientRemoteSettingsImpl extends _ClientRemoteSettings {
  const _$ClientRemoteSettingsImpl(
      {@JsonKey(fromJson: _appBlockFromJson)
      this.app = const ClientAppBlock(name: 'WV Chat', announcement: ''),
      @JsonKey(fromJson: _featureBlockFromJson)
      this.feature = const ClientFeatureBlock(),
      @JsonKey(fromJson: _rtcBlockFromJson) this.rtc = const ClientRtcBlock(),
      @JsonKey(fromJson: _uploadBlockFromJson)
      this.upload = const ClientUploadBlock(),
      @JsonKey(fromJson: _pushBlockFromJson)
      this.push = const ClientPushBlock()})
      : super._();

  factory _$ClientRemoteSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientRemoteSettingsImplFromJson(json);

  @override
  @JsonKey(fromJson: _appBlockFromJson)
  final ClientAppBlock app;
  @override
  @JsonKey(fromJson: _featureBlockFromJson)
  final ClientFeatureBlock feature;
  @override
  @JsonKey(fromJson: _rtcBlockFromJson)
  final ClientRtcBlock rtc;
  @override
  @JsonKey(fromJson: _uploadBlockFromJson)
  final ClientUploadBlock upload;
  @override
  @JsonKey(fromJson: _pushBlockFromJson)
  final ClientPushBlock push;

  @override
  String toString() {
    return 'ClientRemoteSettings(app: $app, feature: $feature, rtc: $rtc, upload: $upload, push: $push)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientRemoteSettingsImpl &&
            (identical(other.app, app) || other.app == app) &&
            (identical(other.feature, feature) || other.feature == feature) &&
            (identical(other.rtc, rtc) || other.rtc == rtc) &&
            (identical(other.upload, upload) || other.upload == upload) &&
            (identical(other.push, push) || other.push == push));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, app, feature, rtc, upload, push);

  /// Create a copy of ClientRemoteSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientRemoteSettingsImplCopyWith<_$ClientRemoteSettingsImpl>
      get copyWith =>
          __$$ClientRemoteSettingsImplCopyWithImpl<_$ClientRemoteSettingsImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientRemoteSettingsImplToJson(
      this,
    );
  }
}

abstract class _ClientRemoteSettings extends ClientRemoteSettings {
  const factory _ClientRemoteSettings(
      {@JsonKey(fromJson: _appBlockFromJson) final ClientAppBlock app,
      @JsonKey(fromJson: _featureBlockFromJson)
      final ClientFeatureBlock feature,
      @JsonKey(fromJson: _rtcBlockFromJson) final ClientRtcBlock rtc,
      @JsonKey(fromJson: _uploadBlockFromJson) final ClientUploadBlock upload,
      @JsonKey(fromJson: _pushBlockFromJson)
      final ClientPushBlock push}) = _$ClientRemoteSettingsImpl;
  const _ClientRemoteSettings._() : super._();

  factory _ClientRemoteSettings.fromJson(Map<String, dynamic> json) =
      _$ClientRemoteSettingsImpl.fromJson;

  @override
  @JsonKey(fromJson: _appBlockFromJson)
  ClientAppBlock get app;
  @override
  @JsonKey(fromJson: _featureBlockFromJson)
  ClientFeatureBlock get feature;
  @override
  @JsonKey(fromJson: _rtcBlockFromJson)
  ClientRtcBlock get rtc;
  @override
  @JsonKey(fromJson: _uploadBlockFromJson)
  ClientUploadBlock get upload;
  @override
  @JsonKey(fromJson: _pushBlockFromJson)
  ClientPushBlock get push;

  /// Create a copy of ClientRemoteSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientRemoteSettingsImplCopyWith<_$ClientRemoteSettingsImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ClientAppBlock _$ClientAppBlockFromJson(Map<String, dynamic> json) {
  return _ClientAppBlock.fromJson(json);
}

/// @nodoc
mixin _$ClientAppBlock {
  @JsonKey(fromJson: _appNameFromJson)
  String get name => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _stringOrEmpty)
  String get announcement => throw _privateConstructorUsedError;

  /// Serializes this ClientAppBlock to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientAppBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientAppBlockCopyWith<ClientAppBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientAppBlockCopyWith<$Res> {
  factory $ClientAppBlockCopyWith(
          ClientAppBlock value, $Res Function(ClientAppBlock) then) =
      _$ClientAppBlockCopyWithImpl<$Res, ClientAppBlock>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _appNameFromJson) String name,
      @JsonKey(fromJson: _stringOrEmpty) String announcement});
}

/// @nodoc
class _$ClientAppBlockCopyWithImpl<$Res, $Val extends ClientAppBlock>
    implements $ClientAppBlockCopyWith<$Res> {
  _$ClientAppBlockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientAppBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? announcement = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      announcement: null == announcement
          ? _value.announcement
          : announcement // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClientAppBlockImplCopyWith<$Res>
    implements $ClientAppBlockCopyWith<$Res> {
  factory _$$ClientAppBlockImplCopyWith(_$ClientAppBlockImpl value,
          $Res Function(_$ClientAppBlockImpl) then) =
      __$$ClientAppBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _appNameFromJson) String name,
      @JsonKey(fromJson: _stringOrEmpty) String announcement});
}

/// @nodoc
class __$$ClientAppBlockImplCopyWithImpl<$Res>
    extends _$ClientAppBlockCopyWithImpl<$Res, _$ClientAppBlockImpl>
    implements _$$ClientAppBlockImplCopyWith<$Res> {
  __$$ClientAppBlockImplCopyWithImpl(
      _$ClientAppBlockImpl _value, $Res Function(_$ClientAppBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientAppBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? announcement = null,
  }) {
    return _then(_$ClientAppBlockImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      announcement: null == announcement
          ? _value.announcement
          : announcement // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientAppBlockImpl implements _ClientAppBlock {
  const _$ClientAppBlockImpl(
      {@JsonKey(fromJson: _appNameFromJson) this.name = 'WV Chat',
      @JsonKey(fromJson: _stringOrEmpty) this.announcement = ''});

  factory _$ClientAppBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientAppBlockImplFromJson(json);

  @override
  @JsonKey(fromJson: _appNameFromJson)
  final String name;
  @override
  @JsonKey(fromJson: _stringOrEmpty)
  final String announcement;

  @override
  String toString() {
    return 'ClientAppBlock(name: $name, announcement: $announcement)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientAppBlockImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.announcement, announcement) ||
                other.announcement == announcement));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, announcement);

  /// Create a copy of ClientAppBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientAppBlockImplCopyWith<_$ClientAppBlockImpl> get copyWith =>
      __$$ClientAppBlockImplCopyWithImpl<_$ClientAppBlockImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientAppBlockImplToJson(
      this,
    );
  }
}

abstract class _ClientAppBlock implements ClientAppBlock {
  const factory _ClientAppBlock(
          {@JsonKey(fromJson: _appNameFromJson) final String name,
          @JsonKey(fromJson: _stringOrEmpty) final String announcement}) =
      _$ClientAppBlockImpl;

  factory _ClientAppBlock.fromJson(Map<String, dynamic> json) =
      _$ClientAppBlockImpl.fromJson;

  @override
  @JsonKey(fromJson: _appNameFromJson)
  String get name;
  @override
  @JsonKey(fromJson: _stringOrEmpty)
  String get announcement;

  /// Create a copy of ClientAppBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientAppBlockImplCopyWith<_$ClientAppBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClientFeatureBlock _$ClientFeatureBlockFromJson(Map<String, dynamic> json) {
  return _ClientFeatureBlock.fromJson(json);
}

/// @nodoc
mixin _$ClientFeatureBlock {
  @JsonKey(fromJson: _boolOrTrue)
  bool get privateChatEnabled => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolOrTrue)
  bool get groupChatEnabled => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolOrTrue)
  bool get recallEnabled => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolOrTrue)
  bool get readReceiptEnabled => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolOrTrue)
  bool get voiceCallEnabled => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolOrTrue)
  bool get videoCallEnabled => throw _privateConstructorUsedError;

  /// 频道（单向广播）能力开关；后端未下发时默认关闭，避免误展示未就绪入口。
  @JsonKey(fromJson: _boolOrFalse)
  bool get channelEnabled => throw _privateConstructorUsedError;

  /// 私密聊天（E2EE 形态）能力开关；后端未下发时默认关闭。
  @JsonKey(fromJson: _boolOrFalse)
  bool get secretChatEnabled => throw _privateConstructorUsedError;

  /// 私密群聊（逐成员 E2EE）能力开关；后端未下发时默认关闭。
  @JsonKey(fromJson: _boolOrFalse)
  bool get secretGroupChatEnabled => throw _privateConstructorUsedError;

  /// 私密群聊删除所有人/撤回开关。
  @JsonKey(fromJson: _boolOrTrue)
  bool get groupDeleteEveryoneEnabled => throw _privateConstructorUsedError;

  /// 私密群聊编辑消息开关。
  @JsonKey(fromJson: _boolOrTrue)
  bool get groupEditMessageEnabled => throw _privateConstructorUsedError;

  /// 私密群聊匿名发言开关。
  @JsonKey(fromJson: _boolOrFalse)
  bool get groupAnonymityEnabled => throw _privateConstructorUsedError;

  /// 私密群聊邀请链接开关。
  @JsonKey(fromJson: _boolOrTrue)
  bool get groupInviteLinkEnabled => throw _privateConstructorUsedError;

  /// 私密群聊置顶/公告开关。
  @JsonKey(fromJson: _boolOrTrue)
  bool get groupPinnedEnabled => throw _privateConstructorUsedError;

  /// 删除聊天/撤回/删除消息/清空聊天总开关；后端未下发时默认开启。
  @JsonKey(fromJson: _boolOrTrue)
  bool get chatDeleteEnabled => throw _privateConstructorUsedError;

  /// 群成员隐私保护：隐藏非好友群成员的昵称/头像（平台级，admin 后台控制）。
  @JsonKey(fromJson: _boolOrTrue)
  bool get hideGroupMemberInfo => throw _privateConstructorUsedError;

  /// Serializes this ClientFeatureBlock to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientFeatureBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientFeatureBlockCopyWith<ClientFeatureBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientFeatureBlockCopyWith<$Res> {
  factory $ClientFeatureBlockCopyWith(
          ClientFeatureBlock value, $Res Function(ClientFeatureBlock) then) =
      _$ClientFeatureBlockCopyWithImpl<$Res, ClientFeatureBlock>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _boolOrTrue) bool privateChatEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool groupChatEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool recallEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool readReceiptEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool voiceCallEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool videoCallEnabled,
      @JsonKey(fromJson: _boolOrFalse) bool channelEnabled,
      @JsonKey(fromJson: _boolOrFalse) bool secretChatEnabled,
      @JsonKey(fromJson: _boolOrFalse) bool secretGroupChatEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool groupDeleteEveryoneEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool groupEditMessageEnabled,
      @JsonKey(fromJson: _boolOrFalse) bool groupAnonymityEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool groupInviteLinkEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool groupPinnedEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool chatDeleteEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool hideGroupMemberInfo});
}

/// @nodoc
class _$ClientFeatureBlockCopyWithImpl<$Res, $Val extends ClientFeatureBlock>
    implements $ClientFeatureBlockCopyWith<$Res> {
  _$ClientFeatureBlockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientFeatureBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? privateChatEnabled = null,
    Object? groupChatEnabled = null,
    Object? recallEnabled = null,
    Object? readReceiptEnabled = null,
    Object? voiceCallEnabled = null,
    Object? videoCallEnabled = null,
    Object? channelEnabled = null,
    Object? secretChatEnabled = null,
    Object? secretGroupChatEnabled = null,
    Object? groupDeleteEveryoneEnabled = null,
    Object? groupEditMessageEnabled = null,
    Object? groupAnonymityEnabled = null,
    Object? groupInviteLinkEnabled = null,
    Object? groupPinnedEnabled = null,
    Object? chatDeleteEnabled = null,
    Object? hideGroupMemberInfo = null,
  }) {
    return _then(_value.copyWith(
      privateChatEnabled: null == privateChatEnabled
          ? _value.privateChatEnabled
          : privateChatEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupChatEnabled: null == groupChatEnabled
          ? _value.groupChatEnabled
          : groupChatEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      recallEnabled: null == recallEnabled
          ? _value.recallEnabled
          : recallEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      readReceiptEnabled: null == readReceiptEnabled
          ? _value.readReceiptEnabled
          : readReceiptEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      voiceCallEnabled: null == voiceCallEnabled
          ? _value.voiceCallEnabled
          : voiceCallEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      videoCallEnabled: null == videoCallEnabled
          ? _value.videoCallEnabled
          : videoCallEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      channelEnabled: null == channelEnabled
          ? _value.channelEnabled
          : channelEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      secretChatEnabled: null == secretChatEnabled
          ? _value.secretChatEnabled
          : secretChatEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      secretGroupChatEnabled: null == secretGroupChatEnabled
          ? _value.secretGroupChatEnabled
          : secretGroupChatEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupDeleteEveryoneEnabled: null == groupDeleteEveryoneEnabled
          ? _value.groupDeleteEveryoneEnabled
          : groupDeleteEveryoneEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupEditMessageEnabled: null == groupEditMessageEnabled
          ? _value.groupEditMessageEnabled
          : groupEditMessageEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupAnonymityEnabled: null == groupAnonymityEnabled
          ? _value.groupAnonymityEnabled
          : groupAnonymityEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupInviteLinkEnabled: null == groupInviteLinkEnabled
          ? _value.groupInviteLinkEnabled
          : groupInviteLinkEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupPinnedEnabled: null == groupPinnedEnabled
          ? _value.groupPinnedEnabled
          : groupPinnedEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      chatDeleteEnabled: null == chatDeleteEnabled
          ? _value.chatDeleteEnabled
          : chatDeleteEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      hideGroupMemberInfo: null == hideGroupMemberInfo
          ? _value.hideGroupMemberInfo
          : hideGroupMemberInfo // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClientFeatureBlockImplCopyWith<$Res>
    implements $ClientFeatureBlockCopyWith<$Res> {
  factory _$$ClientFeatureBlockImplCopyWith(_$ClientFeatureBlockImpl value,
          $Res Function(_$ClientFeatureBlockImpl) then) =
      __$$ClientFeatureBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _boolOrTrue) bool privateChatEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool groupChatEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool recallEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool readReceiptEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool voiceCallEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool videoCallEnabled,
      @JsonKey(fromJson: _boolOrFalse) bool channelEnabled,
      @JsonKey(fromJson: _boolOrFalse) bool secretChatEnabled,
      @JsonKey(fromJson: _boolOrFalse) bool secretGroupChatEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool groupDeleteEveryoneEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool groupEditMessageEnabled,
      @JsonKey(fromJson: _boolOrFalse) bool groupAnonymityEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool groupInviteLinkEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool groupPinnedEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool chatDeleteEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool hideGroupMemberInfo});
}

/// @nodoc
class __$$ClientFeatureBlockImplCopyWithImpl<$Res>
    extends _$ClientFeatureBlockCopyWithImpl<$Res, _$ClientFeatureBlockImpl>
    implements _$$ClientFeatureBlockImplCopyWith<$Res> {
  __$$ClientFeatureBlockImplCopyWithImpl(_$ClientFeatureBlockImpl _value,
      $Res Function(_$ClientFeatureBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientFeatureBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? privateChatEnabled = null,
    Object? groupChatEnabled = null,
    Object? recallEnabled = null,
    Object? readReceiptEnabled = null,
    Object? voiceCallEnabled = null,
    Object? videoCallEnabled = null,
    Object? channelEnabled = null,
    Object? secretChatEnabled = null,
    Object? secretGroupChatEnabled = null,
    Object? groupDeleteEveryoneEnabled = null,
    Object? groupEditMessageEnabled = null,
    Object? groupAnonymityEnabled = null,
    Object? groupInviteLinkEnabled = null,
    Object? groupPinnedEnabled = null,
    Object? chatDeleteEnabled = null,
    Object? hideGroupMemberInfo = null,
  }) {
    return _then(_$ClientFeatureBlockImpl(
      privateChatEnabled: null == privateChatEnabled
          ? _value.privateChatEnabled
          : privateChatEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupChatEnabled: null == groupChatEnabled
          ? _value.groupChatEnabled
          : groupChatEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      recallEnabled: null == recallEnabled
          ? _value.recallEnabled
          : recallEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      readReceiptEnabled: null == readReceiptEnabled
          ? _value.readReceiptEnabled
          : readReceiptEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      voiceCallEnabled: null == voiceCallEnabled
          ? _value.voiceCallEnabled
          : voiceCallEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      videoCallEnabled: null == videoCallEnabled
          ? _value.videoCallEnabled
          : videoCallEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      channelEnabled: null == channelEnabled
          ? _value.channelEnabled
          : channelEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      secretChatEnabled: null == secretChatEnabled
          ? _value.secretChatEnabled
          : secretChatEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      secretGroupChatEnabled: null == secretGroupChatEnabled
          ? _value.secretGroupChatEnabled
          : secretGroupChatEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupDeleteEveryoneEnabled: null == groupDeleteEveryoneEnabled
          ? _value.groupDeleteEveryoneEnabled
          : groupDeleteEveryoneEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupEditMessageEnabled: null == groupEditMessageEnabled
          ? _value.groupEditMessageEnabled
          : groupEditMessageEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupAnonymityEnabled: null == groupAnonymityEnabled
          ? _value.groupAnonymityEnabled
          : groupAnonymityEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupInviteLinkEnabled: null == groupInviteLinkEnabled
          ? _value.groupInviteLinkEnabled
          : groupInviteLinkEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      groupPinnedEnabled: null == groupPinnedEnabled
          ? _value.groupPinnedEnabled
          : groupPinnedEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      chatDeleteEnabled: null == chatDeleteEnabled
          ? _value.chatDeleteEnabled
          : chatDeleteEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      hideGroupMemberInfo: null == hideGroupMemberInfo
          ? _value.hideGroupMemberInfo
          : hideGroupMemberInfo // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientFeatureBlockImpl implements _ClientFeatureBlock {
  const _$ClientFeatureBlockImpl(
      {@JsonKey(fromJson: _boolOrTrue) this.privateChatEnabled = true,
      @JsonKey(fromJson: _boolOrTrue) this.groupChatEnabled = true,
      @JsonKey(fromJson: _boolOrTrue) this.recallEnabled = true,
      @JsonKey(fromJson: _boolOrTrue) this.readReceiptEnabled = true,
      @JsonKey(fromJson: _boolOrTrue) this.voiceCallEnabled = true,
      @JsonKey(fromJson: _boolOrTrue) this.videoCallEnabled = true,
      @JsonKey(fromJson: _boolOrFalse) this.channelEnabled = false,
      @JsonKey(fromJson: _boolOrFalse) this.secretChatEnabled = false,
      @JsonKey(fromJson: _boolOrFalse) this.secretGroupChatEnabled = false,
      @JsonKey(fromJson: _boolOrTrue) this.groupDeleteEveryoneEnabled = true,
      @JsonKey(fromJson: _boolOrTrue) this.groupEditMessageEnabled = true,
      @JsonKey(fromJson: _boolOrFalse) this.groupAnonymityEnabled = false,
      @JsonKey(fromJson: _boolOrTrue) this.groupInviteLinkEnabled = true,
      @JsonKey(fromJson: _boolOrTrue) this.groupPinnedEnabled = true,
      @JsonKey(fromJson: _boolOrTrue) this.chatDeleteEnabled = true,
      @JsonKey(fromJson: _boolOrTrue) this.hideGroupMemberInfo = true});

  factory _$ClientFeatureBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientFeatureBlockImplFromJson(json);

  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool privateChatEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool groupChatEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool recallEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool readReceiptEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool voiceCallEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool videoCallEnabled;

  /// 频道（单向广播）能力开关；后端未下发时默认关闭，避免误展示未就绪入口。
  @override
  @JsonKey(fromJson: _boolOrFalse)
  final bool channelEnabled;

  /// 私密聊天（E2EE 形态）能力开关；后端未下发时默认关闭。
  @override
  @JsonKey(fromJson: _boolOrFalse)
  final bool secretChatEnabled;

  /// 私密群聊（逐成员 E2EE）能力开关；后端未下发时默认关闭。
  @override
  @JsonKey(fromJson: _boolOrFalse)
  final bool secretGroupChatEnabled;

  /// 私密群聊删除所有人/撤回开关。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool groupDeleteEveryoneEnabled;

  /// 私密群聊编辑消息开关。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool groupEditMessageEnabled;

  /// 私密群聊匿名发言开关。
  @override
  @JsonKey(fromJson: _boolOrFalse)
  final bool groupAnonymityEnabled;

  /// 私密群聊邀请链接开关。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool groupInviteLinkEnabled;

  /// 私密群聊置顶/公告开关。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool groupPinnedEnabled;

  /// 删除聊天/撤回/删除消息/清空聊天总开关；后端未下发时默认开启。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool chatDeleteEnabled;

  /// 群成员隐私保护：隐藏非好友群成员的昵称/头像（平台级，admin 后台控制）。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool hideGroupMemberInfo;

  @override
  String toString() {
    return 'ClientFeatureBlock(privateChatEnabled: $privateChatEnabled, groupChatEnabled: $groupChatEnabled, recallEnabled: $recallEnabled, readReceiptEnabled: $readReceiptEnabled, voiceCallEnabled: $voiceCallEnabled, videoCallEnabled: $videoCallEnabled, channelEnabled: $channelEnabled, secretChatEnabled: $secretChatEnabled, secretGroupChatEnabled: $secretGroupChatEnabled, groupDeleteEveryoneEnabled: $groupDeleteEveryoneEnabled, groupEditMessageEnabled: $groupEditMessageEnabled, groupAnonymityEnabled: $groupAnonymityEnabled, groupInviteLinkEnabled: $groupInviteLinkEnabled, groupPinnedEnabled: $groupPinnedEnabled, chatDeleteEnabled: $chatDeleteEnabled, hideGroupMemberInfo: $hideGroupMemberInfo)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientFeatureBlockImpl &&
            (identical(other.privateChatEnabled, privateChatEnabled) ||
                other.privateChatEnabled == privateChatEnabled) &&
            (identical(other.groupChatEnabled, groupChatEnabled) ||
                other.groupChatEnabled == groupChatEnabled) &&
            (identical(other.recallEnabled, recallEnabled) ||
                other.recallEnabled == recallEnabled) &&
            (identical(other.readReceiptEnabled, readReceiptEnabled) ||
                other.readReceiptEnabled == readReceiptEnabled) &&
            (identical(other.voiceCallEnabled, voiceCallEnabled) ||
                other.voiceCallEnabled == voiceCallEnabled) &&
            (identical(other.videoCallEnabled, videoCallEnabled) ||
                other.videoCallEnabled == videoCallEnabled) &&
            (identical(other.channelEnabled, channelEnabled) ||
                other.channelEnabled == channelEnabled) &&
            (identical(other.secretChatEnabled, secretChatEnabled) ||
                other.secretChatEnabled == secretChatEnabled) &&
            (identical(other.secretGroupChatEnabled, secretGroupChatEnabled) ||
                other.secretGroupChatEnabled == secretGroupChatEnabled) &&
            (identical(other.groupDeleteEveryoneEnabled,
                    groupDeleteEveryoneEnabled) ||
                other.groupDeleteEveryoneEnabled ==
                    groupDeleteEveryoneEnabled) &&
            (identical(
                    other.groupEditMessageEnabled, groupEditMessageEnabled) ||
                other.groupEditMessageEnabled == groupEditMessageEnabled) &&
            (identical(other.groupAnonymityEnabled, groupAnonymityEnabled) ||
                other.groupAnonymityEnabled == groupAnonymityEnabled) &&
            (identical(other.groupInviteLinkEnabled, groupInviteLinkEnabled) ||
                other.groupInviteLinkEnabled == groupInviteLinkEnabled) &&
            (identical(other.groupPinnedEnabled, groupPinnedEnabled) ||
                other.groupPinnedEnabled == groupPinnedEnabled) &&
            (identical(other.chatDeleteEnabled, chatDeleteEnabled) ||
                other.chatDeleteEnabled == chatDeleteEnabled) &&
            (identical(other.hideGroupMemberInfo, hideGroupMemberInfo) ||
                other.hideGroupMemberInfo == hideGroupMemberInfo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      privateChatEnabled,
      groupChatEnabled,
      recallEnabled,
      readReceiptEnabled,
      voiceCallEnabled,
      videoCallEnabled,
      channelEnabled,
      secretChatEnabled,
      secretGroupChatEnabled,
      groupDeleteEveryoneEnabled,
      groupEditMessageEnabled,
      groupAnonymityEnabled,
      groupInviteLinkEnabled,
      groupPinnedEnabled,
      chatDeleteEnabled,
      hideGroupMemberInfo);

  /// Create a copy of ClientFeatureBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientFeatureBlockImplCopyWith<_$ClientFeatureBlockImpl> get copyWith =>
      __$$ClientFeatureBlockImplCopyWithImpl<_$ClientFeatureBlockImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientFeatureBlockImplToJson(
      this,
    );
  }
}

abstract class _ClientFeatureBlock implements ClientFeatureBlock {
  const factory _ClientFeatureBlock(
          {@JsonKey(fromJson: _boolOrTrue) final bool privateChatEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool groupChatEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool recallEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool readReceiptEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool voiceCallEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool videoCallEnabled,
          @JsonKey(fromJson: _boolOrFalse) final bool channelEnabled,
          @JsonKey(fromJson: _boolOrFalse) final bool secretChatEnabled,
          @JsonKey(fromJson: _boolOrFalse) final bool secretGroupChatEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool groupDeleteEveryoneEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool groupEditMessageEnabled,
          @JsonKey(fromJson: _boolOrFalse) final bool groupAnonymityEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool groupInviteLinkEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool groupPinnedEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool chatDeleteEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool hideGroupMemberInfo}) =
      _$ClientFeatureBlockImpl;

  factory _ClientFeatureBlock.fromJson(Map<String, dynamic> json) =
      _$ClientFeatureBlockImpl.fromJson;

  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get privateChatEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get groupChatEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get recallEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get readReceiptEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get voiceCallEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get videoCallEnabled;

  /// 频道（单向广播）能力开关；后端未下发时默认关闭，避免误展示未就绪入口。
  @override
  @JsonKey(fromJson: _boolOrFalse)
  bool get channelEnabled;

  /// 私密聊天（E2EE 形态）能力开关；后端未下发时默认关闭。
  @override
  @JsonKey(fromJson: _boolOrFalse)
  bool get secretChatEnabled;

  /// 私密群聊（逐成员 E2EE）能力开关；后端未下发时默认关闭。
  @override
  @JsonKey(fromJson: _boolOrFalse)
  bool get secretGroupChatEnabled;

  /// 私密群聊删除所有人/撤回开关。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get groupDeleteEveryoneEnabled;

  /// 私密群聊编辑消息开关。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get groupEditMessageEnabled;

  /// 私密群聊匿名发言开关。
  @override
  @JsonKey(fromJson: _boolOrFalse)
  bool get groupAnonymityEnabled;

  /// 私密群聊邀请链接开关。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get groupInviteLinkEnabled;

  /// 私密群聊置顶/公告开关。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get groupPinnedEnabled;

  /// 删除聊天/撤回/删除消息/清空聊天总开关；后端未下发时默认开启。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get chatDeleteEnabled;

  /// 群成员隐私保护：隐藏非好友群成员的昵称/头像（平台级，admin 后台控制）。
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get hideGroupMemberInfo;

  /// Create a copy of ClientFeatureBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientFeatureBlockImplCopyWith<_$ClientFeatureBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClientRtcBlock _$ClientRtcBlockFromJson(Map<String, dynamic> json) {
  return _ClientRtcBlock.fromJson(json);
}

/// @nodoc
mixin _$ClientRtcBlock {
  @JsonKey(fromJson: _videoQualityFromJson)
  String get videoQuality => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _videoBitrateFromJson)
  int get videoBitrate => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _audioBitrateFromJson)
  int get audioBitrate => throw _privateConstructorUsedError;

  /// 分钟，0 表示不限制。
  @JsonKey(fromJson: _maxCallDurationFromJson)
  int get maxCallDuration => throw _privateConstructorUsedError;

  /// Serializes this ClientRtcBlock to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientRtcBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientRtcBlockCopyWith<ClientRtcBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientRtcBlockCopyWith<$Res> {
  factory $ClientRtcBlockCopyWith(
          ClientRtcBlock value, $Res Function(ClientRtcBlock) then) =
      _$ClientRtcBlockCopyWithImpl<$Res, ClientRtcBlock>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _videoQualityFromJson) String videoQuality,
      @JsonKey(fromJson: _videoBitrateFromJson) int videoBitrate,
      @JsonKey(fromJson: _audioBitrateFromJson) int audioBitrate,
      @JsonKey(fromJson: _maxCallDurationFromJson) int maxCallDuration});
}

/// @nodoc
class _$ClientRtcBlockCopyWithImpl<$Res, $Val extends ClientRtcBlock>
    implements $ClientRtcBlockCopyWith<$Res> {
  _$ClientRtcBlockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientRtcBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoQuality = null,
    Object? videoBitrate = null,
    Object? audioBitrate = null,
    Object? maxCallDuration = null,
  }) {
    return _then(_value.copyWith(
      videoQuality: null == videoQuality
          ? _value.videoQuality
          : videoQuality // ignore: cast_nullable_to_non_nullable
              as String,
      videoBitrate: null == videoBitrate
          ? _value.videoBitrate
          : videoBitrate // ignore: cast_nullable_to_non_nullable
              as int,
      audioBitrate: null == audioBitrate
          ? _value.audioBitrate
          : audioBitrate // ignore: cast_nullable_to_non_nullable
              as int,
      maxCallDuration: null == maxCallDuration
          ? _value.maxCallDuration
          : maxCallDuration // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClientRtcBlockImplCopyWith<$Res>
    implements $ClientRtcBlockCopyWith<$Res> {
  factory _$$ClientRtcBlockImplCopyWith(_$ClientRtcBlockImpl value,
          $Res Function(_$ClientRtcBlockImpl) then) =
      __$$ClientRtcBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _videoQualityFromJson) String videoQuality,
      @JsonKey(fromJson: _videoBitrateFromJson) int videoBitrate,
      @JsonKey(fromJson: _audioBitrateFromJson) int audioBitrate,
      @JsonKey(fromJson: _maxCallDurationFromJson) int maxCallDuration});
}

/// @nodoc
class __$$ClientRtcBlockImplCopyWithImpl<$Res>
    extends _$ClientRtcBlockCopyWithImpl<$Res, _$ClientRtcBlockImpl>
    implements _$$ClientRtcBlockImplCopyWith<$Res> {
  __$$ClientRtcBlockImplCopyWithImpl(
      _$ClientRtcBlockImpl _value, $Res Function(_$ClientRtcBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientRtcBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? videoQuality = null,
    Object? videoBitrate = null,
    Object? audioBitrate = null,
    Object? maxCallDuration = null,
  }) {
    return _then(_$ClientRtcBlockImpl(
      videoQuality: null == videoQuality
          ? _value.videoQuality
          : videoQuality // ignore: cast_nullable_to_non_nullable
              as String,
      videoBitrate: null == videoBitrate
          ? _value.videoBitrate
          : videoBitrate // ignore: cast_nullable_to_non_nullable
              as int,
      audioBitrate: null == audioBitrate
          ? _value.audioBitrate
          : audioBitrate // ignore: cast_nullable_to_non_nullable
              as int,
      maxCallDuration: null == maxCallDuration
          ? _value.maxCallDuration
          : maxCallDuration // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientRtcBlockImpl implements _ClientRtcBlock {
  const _$ClientRtcBlockImpl(
      {@JsonKey(fromJson: _videoQualityFromJson) this.videoQuality = '720p',
      @JsonKey(fromJson: _videoBitrateFromJson) this.videoBitrate = 1500,
      @JsonKey(fromJson: _audioBitrateFromJson) this.audioBitrate = 64,
      @JsonKey(fromJson: _maxCallDurationFromJson) this.maxCallDuration = 120});

  factory _$ClientRtcBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientRtcBlockImplFromJson(json);

  @override
  @JsonKey(fromJson: _videoQualityFromJson)
  final String videoQuality;
  @override
  @JsonKey(fromJson: _videoBitrateFromJson)
  final int videoBitrate;
  @override
  @JsonKey(fromJson: _audioBitrateFromJson)
  final int audioBitrate;

  /// 分钟，0 表示不限制。
  @override
  @JsonKey(fromJson: _maxCallDurationFromJson)
  final int maxCallDuration;

  @override
  String toString() {
    return 'ClientRtcBlock(videoQuality: $videoQuality, videoBitrate: $videoBitrate, audioBitrate: $audioBitrate, maxCallDuration: $maxCallDuration)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientRtcBlockImpl &&
            (identical(other.videoQuality, videoQuality) ||
                other.videoQuality == videoQuality) &&
            (identical(other.videoBitrate, videoBitrate) ||
                other.videoBitrate == videoBitrate) &&
            (identical(other.audioBitrate, audioBitrate) ||
                other.audioBitrate == audioBitrate) &&
            (identical(other.maxCallDuration, maxCallDuration) ||
                other.maxCallDuration == maxCallDuration));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, videoQuality, videoBitrate, audioBitrate, maxCallDuration);

  /// Create a copy of ClientRtcBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientRtcBlockImplCopyWith<_$ClientRtcBlockImpl> get copyWith =>
      __$$ClientRtcBlockImplCopyWithImpl<_$ClientRtcBlockImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientRtcBlockImplToJson(
      this,
    );
  }
}

abstract class _ClientRtcBlock implements ClientRtcBlock {
  const factory _ClientRtcBlock(
      {@JsonKey(fromJson: _videoQualityFromJson) final String videoQuality,
      @JsonKey(fromJson: _videoBitrateFromJson) final int videoBitrate,
      @JsonKey(fromJson: _audioBitrateFromJson) final int audioBitrate,
      @JsonKey(fromJson: _maxCallDurationFromJson)
      final int maxCallDuration}) = _$ClientRtcBlockImpl;

  factory _ClientRtcBlock.fromJson(Map<String, dynamic> json) =
      _$ClientRtcBlockImpl.fromJson;

  @override
  @JsonKey(fromJson: _videoQualityFromJson)
  String get videoQuality;
  @override
  @JsonKey(fromJson: _videoBitrateFromJson)
  int get videoBitrate;
  @override
  @JsonKey(fromJson: _audioBitrateFromJson)
  int get audioBitrate;

  /// 分钟，0 表示不限制。
  @override
  @JsonKey(fromJson: _maxCallDurationFromJson)
  int get maxCallDuration;

  /// Create a copy of ClientRtcBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientRtcBlockImplCopyWith<_$ClientRtcBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClientUploadBlock _$ClientUploadBlockFromJson(Map<String, dynamic> json) {
  return _ClientUploadBlock.fromJson(json);
}

/// @nodoc
mixin _$ClientUploadBlock {
  @JsonKey(fromJson: _maxImageSizeFromJson)
  int get maxImageSizeMB => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _maxFileSizeFromJson)
  int get maxFileSizeMB => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _maxVideoSizeFromJson)
  int get maxVideoSizeMB => throw _privateConstructorUsedError;

  /// Serializes this ClientUploadBlock to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientUploadBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientUploadBlockCopyWith<ClientUploadBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientUploadBlockCopyWith<$Res> {
  factory $ClientUploadBlockCopyWith(
          ClientUploadBlock value, $Res Function(ClientUploadBlock) then) =
      _$ClientUploadBlockCopyWithImpl<$Res, ClientUploadBlock>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _maxImageSizeFromJson) int maxImageSizeMB,
      @JsonKey(fromJson: _maxFileSizeFromJson) int maxFileSizeMB,
      @JsonKey(fromJson: _maxVideoSizeFromJson) int maxVideoSizeMB});
}

/// @nodoc
class _$ClientUploadBlockCopyWithImpl<$Res, $Val extends ClientUploadBlock>
    implements $ClientUploadBlockCopyWith<$Res> {
  _$ClientUploadBlockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientUploadBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxImageSizeMB = null,
    Object? maxFileSizeMB = null,
    Object? maxVideoSizeMB = null,
  }) {
    return _then(_value.copyWith(
      maxImageSizeMB: null == maxImageSizeMB
          ? _value.maxImageSizeMB
          : maxImageSizeMB // ignore: cast_nullable_to_non_nullable
              as int,
      maxFileSizeMB: null == maxFileSizeMB
          ? _value.maxFileSizeMB
          : maxFileSizeMB // ignore: cast_nullable_to_non_nullable
              as int,
      maxVideoSizeMB: null == maxVideoSizeMB
          ? _value.maxVideoSizeMB
          : maxVideoSizeMB // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClientUploadBlockImplCopyWith<$Res>
    implements $ClientUploadBlockCopyWith<$Res> {
  factory _$$ClientUploadBlockImplCopyWith(_$ClientUploadBlockImpl value,
          $Res Function(_$ClientUploadBlockImpl) then) =
      __$$ClientUploadBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _maxImageSizeFromJson) int maxImageSizeMB,
      @JsonKey(fromJson: _maxFileSizeFromJson) int maxFileSizeMB,
      @JsonKey(fromJson: _maxVideoSizeFromJson) int maxVideoSizeMB});
}

/// @nodoc
class __$$ClientUploadBlockImplCopyWithImpl<$Res>
    extends _$ClientUploadBlockCopyWithImpl<$Res, _$ClientUploadBlockImpl>
    implements _$$ClientUploadBlockImplCopyWith<$Res> {
  __$$ClientUploadBlockImplCopyWithImpl(_$ClientUploadBlockImpl _value,
      $Res Function(_$ClientUploadBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientUploadBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxImageSizeMB = null,
    Object? maxFileSizeMB = null,
    Object? maxVideoSizeMB = null,
  }) {
    return _then(_$ClientUploadBlockImpl(
      maxImageSizeMB: null == maxImageSizeMB
          ? _value.maxImageSizeMB
          : maxImageSizeMB // ignore: cast_nullable_to_non_nullable
              as int,
      maxFileSizeMB: null == maxFileSizeMB
          ? _value.maxFileSizeMB
          : maxFileSizeMB // ignore: cast_nullable_to_non_nullable
              as int,
      maxVideoSizeMB: null == maxVideoSizeMB
          ? _value.maxVideoSizeMB
          : maxVideoSizeMB // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientUploadBlockImpl implements _ClientUploadBlock {
  const _$ClientUploadBlockImpl(
      {@JsonKey(fromJson: _maxImageSizeFromJson) this.maxImageSizeMB = 10,
      @JsonKey(fromJson: _maxFileSizeFromJson) this.maxFileSizeMB = 50,
      @JsonKey(fromJson: _maxVideoSizeFromJson) this.maxVideoSizeMB = 100});

  factory _$ClientUploadBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientUploadBlockImplFromJson(json);

  @override
  @JsonKey(fromJson: _maxImageSizeFromJson)
  final int maxImageSizeMB;
  @override
  @JsonKey(fromJson: _maxFileSizeFromJson)
  final int maxFileSizeMB;
  @override
  @JsonKey(fromJson: _maxVideoSizeFromJson)
  final int maxVideoSizeMB;

  @override
  String toString() {
    return 'ClientUploadBlock(maxImageSizeMB: $maxImageSizeMB, maxFileSizeMB: $maxFileSizeMB, maxVideoSizeMB: $maxVideoSizeMB)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientUploadBlockImpl &&
            (identical(other.maxImageSizeMB, maxImageSizeMB) ||
                other.maxImageSizeMB == maxImageSizeMB) &&
            (identical(other.maxFileSizeMB, maxFileSizeMB) ||
                other.maxFileSizeMB == maxFileSizeMB) &&
            (identical(other.maxVideoSizeMB, maxVideoSizeMB) ||
                other.maxVideoSizeMB == maxVideoSizeMB));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, maxImageSizeMB, maxFileSizeMB, maxVideoSizeMB);

  /// Create a copy of ClientUploadBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientUploadBlockImplCopyWith<_$ClientUploadBlockImpl> get copyWith =>
      __$$ClientUploadBlockImplCopyWithImpl<_$ClientUploadBlockImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientUploadBlockImplToJson(
      this,
    );
  }
}

abstract class _ClientUploadBlock implements ClientUploadBlock {
  const factory _ClientUploadBlock(
          {@JsonKey(fromJson: _maxImageSizeFromJson) final int maxImageSizeMB,
          @JsonKey(fromJson: _maxFileSizeFromJson) final int maxFileSizeMB,
          @JsonKey(fromJson: _maxVideoSizeFromJson) final int maxVideoSizeMB}) =
      _$ClientUploadBlockImpl;

  factory _ClientUploadBlock.fromJson(Map<String, dynamic> json) =
      _$ClientUploadBlockImpl.fromJson;

  @override
  @JsonKey(fromJson: _maxImageSizeFromJson)
  int get maxImageSizeMB;
  @override
  @JsonKey(fromJson: _maxFileSizeFromJson)
  int get maxFileSizeMB;
  @override
  @JsonKey(fromJson: _maxVideoSizeFromJson)
  int get maxVideoSizeMB;

  /// Create a copy of ClientUploadBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientUploadBlockImplCopyWith<_$ClientUploadBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ClientPushBlock _$ClientPushBlockFromJson(Map<String, dynamic> json) {
  return _ClientPushBlock.fromJson(json);
}

/// @nodoc
mixin _$ClientPushBlock {
  @JsonKey(fromJson: _boolOrTrue)
  bool get enabled => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolOrTrue)
  bool get apnsEnabled => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolOrFalse)
  bool get fcmEnabled => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _boolOrTrue)
  bool get jpushEnabled => throw _privateConstructorUsedError;

  /// Serializes this ClientPushBlock to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ClientPushBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ClientPushBlockCopyWith<ClientPushBlock> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ClientPushBlockCopyWith<$Res> {
  factory $ClientPushBlockCopyWith(
          ClientPushBlock value, $Res Function(ClientPushBlock) then) =
      _$ClientPushBlockCopyWithImpl<$Res, ClientPushBlock>;
  @useResult
  $Res call(
      {@JsonKey(fromJson: _boolOrTrue) bool enabled,
      @JsonKey(fromJson: _boolOrTrue) bool apnsEnabled,
      @JsonKey(fromJson: _boolOrFalse) bool fcmEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool jpushEnabled});
}

/// @nodoc
class _$ClientPushBlockCopyWithImpl<$Res, $Val extends ClientPushBlock>
    implements $ClientPushBlockCopyWith<$Res> {
  _$ClientPushBlockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ClientPushBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? apnsEnabled = null,
    Object? fcmEnabled = null,
    Object? jpushEnabled = null,
  }) {
    return _then(_value.copyWith(
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      apnsEnabled: null == apnsEnabled
          ? _value.apnsEnabled
          : apnsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      fcmEnabled: null == fcmEnabled
          ? _value.fcmEnabled
          : fcmEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      jpushEnabled: null == jpushEnabled
          ? _value.jpushEnabled
          : jpushEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ClientPushBlockImplCopyWith<$Res>
    implements $ClientPushBlockCopyWith<$Res> {
  factory _$$ClientPushBlockImplCopyWith(_$ClientPushBlockImpl value,
          $Res Function(_$ClientPushBlockImpl) then) =
      __$$ClientPushBlockImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(fromJson: _boolOrTrue) bool enabled,
      @JsonKey(fromJson: _boolOrTrue) bool apnsEnabled,
      @JsonKey(fromJson: _boolOrFalse) bool fcmEnabled,
      @JsonKey(fromJson: _boolOrTrue) bool jpushEnabled});
}

/// @nodoc
class __$$ClientPushBlockImplCopyWithImpl<$Res>
    extends _$ClientPushBlockCopyWithImpl<$Res, _$ClientPushBlockImpl>
    implements _$$ClientPushBlockImplCopyWith<$Res> {
  __$$ClientPushBlockImplCopyWithImpl(
      _$ClientPushBlockImpl _value, $Res Function(_$ClientPushBlockImpl) _then)
      : super(_value, _then);

  /// Create a copy of ClientPushBlock
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? enabled = null,
    Object? apnsEnabled = null,
    Object? fcmEnabled = null,
    Object? jpushEnabled = null,
  }) {
    return _then(_$ClientPushBlockImpl(
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      apnsEnabled: null == apnsEnabled
          ? _value.apnsEnabled
          : apnsEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      fcmEnabled: null == fcmEnabled
          ? _value.fcmEnabled
          : fcmEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      jpushEnabled: null == jpushEnabled
          ? _value.jpushEnabled
          : jpushEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ClientPushBlockImpl implements _ClientPushBlock {
  const _$ClientPushBlockImpl(
      {@JsonKey(fromJson: _boolOrTrue) this.enabled = true,
      @JsonKey(fromJson: _boolOrTrue) this.apnsEnabled = true,
      @JsonKey(fromJson: _boolOrFalse) this.fcmEnabled = false,
      @JsonKey(fromJson: _boolOrTrue) this.jpushEnabled = true});

  factory _$ClientPushBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$ClientPushBlockImplFromJson(json);

  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool enabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool apnsEnabled;
  @override
  @JsonKey(fromJson: _boolOrFalse)
  final bool fcmEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  final bool jpushEnabled;

  @override
  String toString() {
    return 'ClientPushBlock(enabled: $enabled, apnsEnabled: $apnsEnabled, fcmEnabled: $fcmEnabled, jpushEnabled: $jpushEnabled)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ClientPushBlockImpl &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.apnsEnabled, apnsEnabled) ||
                other.apnsEnabled == apnsEnabled) &&
            (identical(other.fcmEnabled, fcmEnabled) ||
                other.fcmEnabled == fcmEnabled) &&
            (identical(other.jpushEnabled, jpushEnabled) ||
                other.jpushEnabled == jpushEnabled));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, enabled, apnsEnabled, fcmEnabled, jpushEnabled);

  /// Create a copy of ClientPushBlock
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ClientPushBlockImplCopyWith<_$ClientPushBlockImpl> get copyWith =>
      __$$ClientPushBlockImplCopyWithImpl<_$ClientPushBlockImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ClientPushBlockImplToJson(
      this,
    );
  }
}

abstract class _ClientPushBlock implements ClientPushBlock {
  const factory _ClientPushBlock(
          {@JsonKey(fromJson: _boolOrTrue) final bool enabled,
          @JsonKey(fromJson: _boolOrTrue) final bool apnsEnabled,
          @JsonKey(fromJson: _boolOrFalse) final bool fcmEnabled,
          @JsonKey(fromJson: _boolOrTrue) final bool jpushEnabled}) =
      _$ClientPushBlockImpl;

  factory _ClientPushBlock.fromJson(Map<String, dynamic> json) =
      _$ClientPushBlockImpl.fromJson;

  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get enabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get apnsEnabled;
  @override
  @JsonKey(fromJson: _boolOrFalse)
  bool get fcmEnabled;
  @override
  @JsonKey(fromJson: _boolOrTrue)
  bool get jpushEnabled;

  /// Create a copy of ClientPushBlock
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ClientPushBlockImplCopyWith<_$ClientPushBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
