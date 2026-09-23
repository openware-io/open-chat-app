// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_remote_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ClientRemoteSettingsImpl _$$ClientRemoteSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$ClientRemoteSettingsImpl(
      app: json['app'] == null
          ? const ClientAppBlock(name: 'WV Chat', announcement: '')
          : _appBlockFromJson(json['app']),
      feature: json['feature'] == null
          ? const ClientFeatureBlock()
          : _featureBlockFromJson(json['feature']),
      rtc: json['rtc'] == null
          ? const ClientRtcBlock()
          : _rtcBlockFromJson(json['rtc']),
      upload: json['upload'] == null
          ? const ClientUploadBlock()
          : _uploadBlockFromJson(json['upload']),
      push: json['push'] == null
          ? const ClientPushBlock()
          : _pushBlockFromJson(json['push']),
    );

Map<String, dynamic> _$$ClientRemoteSettingsImplToJson(
        _$ClientRemoteSettingsImpl instance) =>
    <String, dynamic>{
      'app': instance.app,
      'feature': instance.feature,
      'rtc': instance.rtc,
      'upload': instance.upload,
      'push': instance.push,
    };

_$ClientAppBlockImpl _$$ClientAppBlockImplFromJson(Map<String, dynamic> json) =>
    _$ClientAppBlockImpl(
      name: json['name'] == null ? 'WV Chat' : _appNameFromJson(json['name']),
      announcement: json['announcement'] == null
          ? ''
          : _stringOrEmpty(json['announcement']),
    );

Map<String, dynamic> _$$ClientAppBlockImplToJson(
        _$ClientAppBlockImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'announcement': instance.announcement,
    };

_$ClientFeatureBlockImpl _$$ClientFeatureBlockImplFromJson(
        Map<String, dynamic> json) =>
    _$ClientFeatureBlockImpl(
      privateChatEnabled: json['privateChatEnabled'] == null
          ? true
          : _boolOrTrue(json['privateChatEnabled']),
      groupChatEnabled: json['groupChatEnabled'] == null
          ? true
          : _boolOrTrue(json['groupChatEnabled']),
      recallEnabled: json['recallEnabled'] == null
          ? true
          : _boolOrTrue(json['recallEnabled']),
      readReceiptEnabled: json['readReceiptEnabled'] == null
          ? true
          : _boolOrTrue(json['readReceiptEnabled']),
      voiceCallEnabled: json['voiceCallEnabled'] == null
          ? true
          : _boolOrTrue(json['voiceCallEnabled']),
      videoCallEnabled: json['videoCallEnabled'] == null
          ? true
          : _boolOrTrue(json['videoCallEnabled']),
      channelEnabled: json['channelEnabled'] == null
          ? false
          : _boolOrFalse(json['channelEnabled']),
      secretChatEnabled: json['secretChatEnabled'] == null
          ? false
          : _boolOrFalse(json['secretChatEnabled']),
      secretGroupChatEnabled: json['secretGroupChatEnabled'] == null
          ? false
          : _boolOrFalse(json['secretGroupChatEnabled']),
      groupDeleteEveryoneEnabled: json['groupDeleteEveryoneEnabled'] == null
          ? true
          : _boolOrTrue(json['groupDeleteEveryoneEnabled']),
      groupEditMessageEnabled: json['groupEditMessageEnabled'] == null
          ? true
          : _boolOrTrue(json['groupEditMessageEnabled']),
      groupAnonymityEnabled: json['groupAnonymityEnabled'] == null
          ? false
          : _boolOrFalse(json['groupAnonymityEnabled']),
      groupInviteLinkEnabled: json['groupInviteLinkEnabled'] == null
          ? true
          : _boolOrTrue(json['groupInviteLinkEnabled']),
      groupPinnedEnabled: json['groupPinnedEnabled'] == null
          ? true
          : _boolOrTrue(json['groupPinnedEnabled']),
      chatDeleteEnabled: json['chatDeleteEnabled'] == null
          ? true
          : _boolOrTrue(json['chatDeleteEnabled']),
      hideGroupMemberInfo: json['hideGroupMemberInfo'] == null
          ? true
          : _boolOrTrue(json['hideGroupMemberInfo']),
    );

Map<String, dynamic> _$$ClientFeatureBlockImplToJson(
        _$ClientFeatureBlockImpl instance) =>
    <String, dynamic>{
      'privateChatEnabled': instance.privateChatEnabled,
      'groupChatEnabled': instance.groupChatEnabled,
      'recallEnabled': instance.recallEnabled,
      'readReceiptEnabled': instance.readReceiptEnabled,
      'voiceCallEnabled': instance.voiceCallEnabled,
      'videoCallEnabled': instance.videoCallEnabled,
      'channelEnabled': instance.channelEnabled,
      'secretChatEnabled': instance.secretChatEnabled,
      'secretGroupChatEnabled': instance.secretGroupChatEnabled,
      'groupDeleteEveryoneEnabled': instance.groupDeleteEveryoneEnabled,
      'groupEditMessageEnabled': instance.groupEditMessageEnabled,
      'groupAnonymityEnabled': instance.groupAnonymityEnabled,
      'groupInviteLinkEnabled': instance.groupInviteLinkEnabled,
      'groupPinnedEnabled': instance.groupPinnedEnabled,
      'chatDeleteEnabled': instance.chatDeleteEnabled,
      'hideGroupMemberInfo': instance.hideGroupMemberInfo,
    };

_$ClientRtcBlockImpl _$$ClientRtcBlockImplFromJson(Map<String, dynamic> json) =>
    _$ClientRtcBlockImpl(
      videoQuality: json['videoQuality'] == null
          ? '720p'
          : _videoQualityFromJson(json['videoQuality']),
      videoBitrate: json['videoBitrate'] == null
          ? 1500
          : _videoBitrateFromJson(json['videoBitrate']),
      audioBitrate: json['audioBitrate'] == null
          ? 64
          : _audioBitrateFromJson(json['audioBitrate']),
      maxCallDuration: json['maxCallDuration'] == null
          ? 120
          : _maxCallDurationFromJson(json['maxCallDuration']),
    );

Map<String, dynamic> _$$ClientRtcBlockImplToJson(
        _$ClientRtcBlockImpl instance) =>
    <String, dynamic>{
      'videoQuality': instance.videoQuality,
      'videoBitrate': instance.videoBitrate,
      'audioBitrate': instance.audioBitrate,
      'maxCallDuration': instance.maxCallDuration,
    };

_$ClientUploadBlockImpl _$$ClientUploadBlockImplFromJson(
        Map<String, dynamic> json) =>
    _$ClientUploadBlockImpl(
      maxImageSizeMB: json['maxImageSizeMB'] == null
          ? 10
          : _maxImageSizeFromJson(json['maxImageSizeMB']),
      maxFileSizeMB: json['maxFileSizeMB'] == null
          ? 50
          : _maxFileSizeFromJson(json['maxFileSizeMB']),
      maxVideoSizeMB: json['maxVideoSizeMB'] == null
          ? 100
          : _maxVideoSizeFromJson(json['maxVideoSizeMB']),
    );

Map<String, dynamic> _$$ClientUploadBlockImplToJson(
        _$ClientUploadBlockImpl instance) =>
    <String, dynamic>{
      'maxImageSizeMB': instance.maxImageSizeMB,
      'maxFileSizeMB': instance.maxFileSizeMB,
      'maxVideoSizeMB': instance.maxVideoSizeMB,
    };

_$ClientPushBlockImpl _$$ClientPushBlockImplFromJson(
        Map<String, dynamic> json) =>
    _$ClientPushBlockImpl(
      enabled: json['enabled'] == null ? true : _boolOrTrue(json['enabled']),
      apnsEnabled:
          json['apnsEnabled'] == null ? true : _boolOrTrue(json['apnsEnabled']),
      fcmEnabled:
          json['fcmEnabled'] == null ? false : _boolOrFalse(json['fcmEnabled']),
      jpushEnabled: json['jpushEnabled'] == null
          ? true
          : _boolOrTrue(json['jpushEnabled']),
    );

Map<String, dynamic> _$$ClientPushBlockImplToJson(
        _$ClientPushBlockImpl instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'apnsEnabled': instance.apnsEnabled,
      'fcmEnabled': instance.fcmEnabled,
      'jpushEnabled': instance.jpushEnabled,
    };
