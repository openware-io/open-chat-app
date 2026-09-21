import 'package:freezed_annotation/freezed_annotation.dart';

import '../json/json_int.dart';

part 'client_remote_settings.freezed.dart';
part 'client_remote_settings.g.dart';

// ignore_for_file: invalid_annotation_target

Map<String, dynamic>? _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _stringOr(Object? value, String fallback) {
  if (value is String) return value;
  if (value != null) return value.toString();
  return fallback;
}

String _appNameFromJson(Object? value) => _stringOr(value, 'WV Chat');

String _stringOrEmpty(Object? value) => _stringOr(value, '');

String _videoQualityFromJson(Object? value) => _stringOr(value, '720p');

int _intOr(Object? value, int fallback) => jsonInt(value) ?? fallback;

int _videoBitrateFromJson(Object? value) => _intOr(value, 1500);

int _audioBitrateFromJson(Object? value) => _intOr(value, 64);

int _maxCallDurationFromJson(Object? value) => _intOr(value, 120);

int _maxImageSizeFromJson(Object? value) => _intOr(value, 10);

int _maxFileSizeFromJson(Object? value) => _intOr(value, 50);

int _maxVideoSizeFromJson(Object? value) => _intOr(value, 100);

bool _boolOr(Object? value, bool fallback) {
  if (value is bool) return value;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  if (value is num) return value != 0;
  return fallback;
}

bool _boolOrTrue(Object? value) => _boolOr(value, true);

bool _boolOrFalse(Object? value) => _boolOr(value, false);

ClientAppBlock _appBlockFromJson(Object? value) {
  final map = _asStringMap(value);
  return map == null
      ? ClientRemoteSettings.defaults.app
      : ClientAppBlock.fromJson(map);
}

ClientFeatureBlock _featureBlockFromJson(Object? value) {
  final map = _asStringMap(value);
  return map == null
      ? ClientRemoteSettings.defaults.feature
      : ClientFeatureBlock.fromJson(map);
}

ClientRtcBlock _rtcBlockFromJson(Object? value) {
  final map = _asStringMap(value);
  return map == null
      ? ClientRemoteSettings.defaults.rtc
      : ClientRtcBlock.fromJson(map);
}

ClientUploadBlock _uploadBlockFromJson(Object? value) {
  final map = _asStringMap(value);
  return map == null
      ? ClientRemoteSettings.defaults.upload
      : ClientUploadBlock.fromJson(map);
}

ClientPushBlock _pushBlockFromJson(Object? value) {
  final map = _asStringMap(value);
  return map == null
      ? ClientRemoteSettings.defaults.push
      : ClientPushBlock.fromJson(map);
}

/// 与后端 `GET /config/client` 响应结构一致。
///
/// 这里是客户端运行时能力开关的核心 DTO：页面、通话、上传、推送等配置
/// 都从这里读取。字段兜底集中在模型层，避免 Provider/UI 直接判断后端缺字段。
@freezed
abstract class ClientRemoteSettings with _$ClientRemoteSettings {
  const ClientRemoteSettings._();

  const factory ClientRemoteSettings({
    @JsonKey(fromJson: _appBlockFromJson)
    @Default(ClientAppBlock(name: 'WV Chat', announcement: ''))
    ClientAppBlock app,
    @JsonKey(fromJson: _featureBlockFromJson)
    @Default(ClientFeatureBlock())
    ClientFeatureBlock feature,
    @JsonKey(fromJson: _rtcBlockFromJson)
    @Default(ClientRtcBlock())
    ClientRtcBlock rtc,
    @JsonKey(fromJson: _uploadBlockFromJson)
    @Default(ClientUploadBlock())
    ClientUploadBlock upload,
    @JsonKey(fromJson: _pushBlockFromJson)
    @Default(ClientPushBlock())
    ClientPushBlock push,
  }) = _ClientRemoteSettings;

  static const ClientRemoteSettings defaults = ClientRemoteSettings();

  factory ClientRemoteSettings.fromJson(Map<String, dynamic> json) =>
      _$ClientRemoteSettingsFromJson(json);
}

@freezed
abstract class ClientAppBlock with _$ClientAppBlock {
  const factory ClientAppBlock({
    @JsonKey(fromJson: _appNameFromJson) @Default('WV Chat') String name,
    @JsonKey(fromJson: _stringOrEmpty) @Default('') String announcement,
  }) = _ClientAppBlock;

  factory ClientAppBlock.fromJson(Map<String, dynamic> json) =>
      _$ClientAppBlockFromJson(json);
}

@freezed
abstract class ClientFeatureBlock with _$ClientFeatureBlock {
  const factory ClientFeatureBlock({
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool privateChatEnabled,
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool groupChatEnabled,
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool recallEnabled,
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool readReceiptEnabled,
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool voiceCallEnabled,
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool videoCallEnabled,

    /// 频道（单向广播）能力开关；后端未下发时默认关闭，避免误展示未就绪入口。
    @JsonKey(fromJson: _boolOrFalse) @Default(false) bool channelEnabled,

    /// 私密聊天（E2EE 形态）能力开关；后端未下发时默认关闭。
    @JsonKey(fromJson: _boolOrFalse) @Default(false) bool secretChatEnabled,

    /// 私密群聊（逐成员 E2EE）能力开关；后端未下发时默认关闭。
    @JsonKey(fromJson: _boolOrFalse) @Default(false) bool secretGroupChatEnabled,

    /// 私密群聊删除所有人/撤回开关。
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool groupDeleteEveryoneEnabled,

    /// 私密群聊编辑消息开关。
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool groupEditMessageEnabled,

    /// 私密群聊匿名发言开关。
    @JsonKey(fromJson: _boolOrFalse) @Default(false) bool groupAnonymityEnabled,

    /// 私密群聊邀请链接开关。
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool groupInviteLinkEnabled,

    /// 私密群聊置顶/公告开关。
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool groupPinnedEnabled,

    /// 删除聊天/撤回/删除消息/清空聊天总开关；后端未下发时默认开启。
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool chatDeleteEnabled,

    /// 群成员隐私保护：隐藏非好友群成员的昵称/头像（平台级，admin 后台控制）。
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool hideGroupMemberInfo,
  }) = _ClientFeatureBlock;

  factory ClientFeatureBlock.fromJson(Map<String, dynamic> json) =>
      _$ClientFeatureBlockFromJson(json);
}

@freezed
abstract class ClientRtcBlock with _$ClientRtcBlock {
  const factory ClientRtcBlock({
    @JsonKey(fromJson: _videoQualityFromJson)
    @Default('720p')
    String videoQuality,
    @JsonKey(fromJson: _videoBitrateFromJson) @Default(1500) int videoBitrate,
    @JsonKey(fromJson: _audioBitrateFromJson) @Default(64) int audioBitrate,

    /// 分钟，0 表示不限制。
    @JsonKey(fromJson: _maxCallDurationFromJson)
    @Default(120)
    int maxCallDuration,
  }) = _ClientRtcBlock;

  factory ClientRtcBlock.fromJson(Map<String, dynamic> json) =>
      _$ClientRtcBlockFromJson(json);
}

@freezed
abstract class ClientUploadBlock with _$ClientUploadBlock {
  const factory ClientUploadBlock({
    @JsonKey(fromJson: _maxImageSizeFromJson) @Default(10) int maxImageSizeMB,
    @JsonKey(fromJson: _maxFileSizeFromJson) @Default(50) int maxFileSizeMB,
    @JsonKey(fromJson: _maxVideoSizeFromJson) @Default(100) int maxVideoSizeMB,
  }) = _ClientUploadBlock;

  factory ClientUploadBlock.fromJson(Map<String, dynamic> json) =>
      _$ClientUploadBlockFromJson(json);
}

/// 与后端 `GET /config/client` 的 `push` 字段一致。
///
/// `fcmEnabled` 仍存在以兼容服务端 JSON；客户端已不接 Firebase FCM。
@freezed
abstract class ClientPushBlock with _$ClientPushBlock {
  const factory ClientPushBlock({
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool enabled,
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool apnsEnabled,
    @JsonKey(fromJson: _boolOrFalse) @Default(false) bool fcmEnabled,
    @JsonKey(fromJson: _boolOrTrue) @Default(true) bool jpushEnabled,
  }) = _ClientPushBlock;

  factory ClientPushBlock.fromJson(Map<String, dynamic> json) =>
      _$ClientPushBlockFromJson(json);
}
