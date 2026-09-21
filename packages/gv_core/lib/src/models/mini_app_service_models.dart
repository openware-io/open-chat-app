// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mini_app_service_models.freezed.dart';
part 'mini_app_service_models.g.dart';

/// 面向对象：消费者服务（固定展示 + 可搜索）。
const String kMiniAppAudienceConsumer = 'consumer';

/// 面向对象：运营后台（仅搜索展示，不进固定展示）。
const String kMiniAppAudienceOperator = 'operator';

/// 小程序服务项 DTO。
///
/// 标准 [fromJson]/[toJson] 由代码生成器负责；[fromApiJson] 额外兼容后端历史字段名。
@freezed
abstract class MiniAppServiceItem with _$MiniAppServiceItem {
  const MiniAppServiceItem._();

  /// 是否运营后台小程序（仅搜索展示，不进固定展示）。
  bool get isOperatorBackend => audience == kMiniAppAudienceOperator;

  const factory MiniAppServiceItem({
    @Default('') String id,
    required String name,
    @JsonKey(name: 'icon') required String iconPath,
    @Default('') String introduction,
    @JsonKey(name: 'link') @Default('') String entryUrl,
    @Default(kMiniAppAudienceConsumer) String audience,
  }) = _MiniAppServiceItem;

  factory MiniAppServiceItem.fromJson(Map<String, dynamic> json) =>
      _$MiniAppServiceItemFromJson(json);

  factory MiniAppServiceItem.fromApiJson(Map<String, dynamic> json) {
    return MiniAppServiceItem(
      id: _pickId(json),
      name: _pickString(json, const ['name', 'title', 'appName', 'label']),
      iconPath: _pickString(
        json,
        const ['icon', 'iconUrl', 'logo', 'cover', 'avatar'],
      ),
      introduction:
          _pickRawString(json, const ['introduction', 'intro']).trim(),
      entryUrl: _pickRawString(
        json,
        const ['link', 'url', 'entryUrl', 'h5Url', 'webUrl', 'path', 'href'],
      ),
      audience: _pickString(
        json,
        const ['audience'],
        fallback: kMiniAppAudienceConsumer,
      ),
    );
  }
}

/// 小程序服务分组 DTO。
@freezed
abstract class MiniAppServiceCategory with _$MiniAppServiceCategory {
  const MiniAppServiceCategory._();

  const factory MiniAppServiceCategory({
    required String typeName,
    required List<MiniAppServiceItem> items,
  }) = _MiniAppServiceCategory;

  factory MiniAppServiceCategory.fromJson(Map<String, dynamic> json) =>
      _$MiniAppServiceCategoryFromJson(json);

  factory MiniAppServiceCategory.fromApiJson(Map<String, dynamic> json) {
    return MiniAppServiceCategory(
      typeName: _pickString(
        json,
        const [
          'typeName',
          'type',
          'category',
          'categoryName',
          'groupName',
          'name',
        ],
        fallback: '服务',
      ),
      items: [
        for (final item in _rawItems(json))
          if (item is Map)
            MiniAppServiceItem.fromApiJson(Map<String, dynamic>.from(item)),
      ],
    );
  }

  /// 解析 `GET /miniapp/services` 响应：支持顶层 List，或 `{data|list|categories|items}` 包一层。
  static List<MiniAppServiceCategory> parseResponse(dynamic data) {
    if (data == null) return [];
    if (data is List) return _parseCategoryList(data);
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final inner =
          map['data'] ?? map['list'] ?? map['categories'] ?? map['items'];
      if (inner is List) return _parseCategoryList(inner);
    }
    return [];
  }

  static List<MiniAppServiceCategory> _parseCategoryList(List<dynamic> list) {
    if (list.isEmpty) return [];
    final first = list.first;
    if (first is Map) {
      final map = Map<String, dynamic>.from(first);
      final hasNested = map['items'] is List ||
          map['services'] is List ||
          map['children'] is List ||
          map['list'] is List;
      if (!hasNested &&
          (map.containsKey('icon') ||
              map.containsKey('iconUrl') ||
              map.containsKey('logo'))) {
        return [
          MiniAppServiceCategory(
            typeName: '服务',
            items: [
              for (final item in list)
                if (item is Map)
                  MiniAppServiceItem.fromApiJson(
                    Map<String, dynamic>.from(item),
                  ),
            ],
          ),
        ];
      }
    }
    return [
      for (final item in list)
        if (item is Map)
          MiniAppServiceCategory.fromApiJson(Map<String, dynamic>.from(item)),
    ];
  }
}

String _pickString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return fallback;
}

String _pickRawString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
  }
  return '';
}

String _pickId(Map<String, dynamic> json) {
  for (final key in const [
    'id',
    'appId',
    'serviceId',
    'miniappId',
    'miniProgramId',
    'code',
  ]) {
    final value = json[key];
    if (value == null) continue;
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num) return value.toString();
  }
  return '';
}

List<dynamic> _rawItems(Map<String, dynamic> json) {
  for (final key in const ['items', 'services', 'children', 'list', 'apps']) {
    final value = json[key];
    if (value is List) return value;
  }
  return const [];
}
