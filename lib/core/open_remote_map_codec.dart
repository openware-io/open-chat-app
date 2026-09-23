// 服务端下发的地图瓦片 URL、逆地理 URL 模板解析（占位符与 JSON 地址提取）。

import 'dart:convert';

/// 逆地理解析失败或路径无文本时用于展示与下发。
const String kGvReverseGeocodeUnknownAddress = '未知地址';

/// 将 `{lat}`、`{lng}`、`{lon}` 替换为坐标字符串。
String gvExpandLatLngInUrlTemplate(String template, double lat, double lng) {
  return template
      .replaceAll('{lat}', lat.toString())
      .replaceAll('{lng}', lng.toString())
      .replaceAll('{lon}', lng.toString());
}

/// 将 Dio 等返回的 [data] 转为 Map（部分接口 Content-Type 非 JSON，[data] 为字符串）。
Map<String, dynamic>? gvParseReverseGeocodeResponseBody(dynamic data) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    try {
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return null;
    }
  }
  if (data is String) {
    final t = data.trim();
    if (t.isEmpty) return null;
    try {
      final decoded = jsonDecode(t);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
  }
  return null;
}

/// 从逆地理 JSON 根对象按**点路径**取文本。
///
/// 1. [configuredPath] 非空（服务端 `reverseGeocodeAddressPath`）优先，从根起按 `.` 解析。
/// 2. 否则使用 URL 模板 query 里的 **`field`**，视为同一条点路径（如 `result.formatted_address`）。
/// 3. 无路径配置、路径不存在或非空字符串则返回 `null`（由调用方显示 [kGvReverseGeocodeUnknownAddress]）。
String? gvExtractGeocodeAddressFromJson(
  Object? json,
  String? configuredPath,
  String? templateHint,
) {
  if (json is! Map) return null;
  final root = Map<String, dynamic>.from(json);

  final serverPath = configuredPath?.trim();
  if (serverPath != null && serverPath.isNotEmpty) {
    return _asNonEmptyString(_dotPathLookup(root, serverPath));
  }

  final fieldPath = _fieldQueryFromTemplate(templateHint)?.trim();
  if (fieldPath == null || fieldPath.isEmpty) return null;

  return _asNonEmptyString(_dotPathLookup(root, fieldPath));
}

String? _fieldQueryFromTemplate(String? template) {
  if (template == null || template.trim().isEmpty) return null;
  try {
    final u = Uri.parse(template.trim());
    return u.queryParameters['field']?.trim();
  } catch (_) {
    return null;
  }
}

dynamic _dotPathLookup(Map<String, dynamic> root, String path) {
  dynamic cur = root;
  for (final part in path.split('.')) {
    if (part.isEmpty) continue;
    if (cur is! Map) return null;
    final m = Map<String, dynamic>.from(cur);
    if (!m.containsKey(part)) return null;
    cur = m[part];
  }
  return cur;
}

String? _asNonEmptyString(dynamic v) {
  if (v == null) return null;
  if (v is String) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
  return null;
}

/// 百度等：`status` 存在且非 0 视为业务失败；无 `status` 键则不据此判失败。
bool gvReverseGeocodeJsonIndicatesFailure(Map<String, dynamic> json) {
  if (!json.containsKey('status')) return false;
  final s = json['status'];
  if (s is num) return s != 0;
  if (s is String) {
    final n = int.tryParse(s.trim());
    if (n != null) return n != 0;
  }
  return false;
}
