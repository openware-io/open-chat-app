// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'im_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ImUserImpl _$$ImUserImplFromJson(Map<String, dynamic> json) => _$ImUserImpl(
      id: jsonIntRequired(json['id']),
      username: json['username'] as String? ?? '',
      nickname: json['nickname'] as String?,
      avatar: _trimNullableString(_readAvatar(json, 'avatar')),
      signature: _trimNullableString(_readSignature(json, 'signature')),
      phone: _trimNullableString(_readPhone(json, 'phone')),
      email: _trimNullableString(_readEmail(json, 'email')),
    );

Map<String, dynamic> _$$ImUserImplToJson(_$ImUserImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      if (instance.nickname case final value?) 'nickname': value,
      if (instance.avatar case final value?) 'avatar': value,
      if (instance.signature case final value?) 'signature': value,
      if (instance.phone case final value?) 'phone': value,
      if (instance.email case final value?) 'email': value,
    };
