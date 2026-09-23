// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mini_app_service_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MiniAppServiceItemImpl _$$MiniAppServiceItemImplFromJson(
        Map<String, dynamic> json) =>
    _$MiniAppServiceItemImpl(
      id: json['id'] as String? ?? '',
      name: json['name'] as String,
      iconPath: json['icon'] as String,
      introduction: json['introduction'] as String? ?? '',
      entryUrl: json['link'] as String? ?? '',
      audience: json['audience'] as String? ?? kMiniAppAudienceConsumer,
    );

Map<String, dynamic> _$$MiniAppServiceItemImplToJson(
        _$MiniAppServiceItemImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'icon': instance.iconPath,
      'introduction': instance.introduction,
      'link': instance.entryUrl,
      'audience': instance.audience,
    };

_$MiniAppServiceCategoryImpl _$$MiniAppServiceCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$MiniAppServiceCategoryImpl(
      typeName: json['typeName'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => MiniAppServiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MiniAppServiceCategoryImplToJson(
        _$MiniAppServiceCategoryImpl instance) =>
    <String, dynamic>{
      'typeName': instance.typeName,
      'items': instance.items,
    };
