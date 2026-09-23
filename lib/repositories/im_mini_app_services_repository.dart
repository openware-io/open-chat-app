import 'dart:convert';

import '../core/local_storage.dart';
import 'package:open_core/open_core.dart';
import '../services/api_client.dart';
import '../services/im_api.dart';
import 'mini_app_services_repository.dart';

/// ImApi 版本的小程序服务仓库。
///
/// Provider 不再直接处理 JSON 缓存细节，只接收已经解析好的分类列表。
class ImMiniAppServicesRepository implements MiniAppServicesRepository {
  ImMiniAppServicesRepository(this._storage, this._api, this._client);

  final LocalStorage _storage;
  final ImApi _api;
  final ApiClient _client;

  @override
  List<MiniAppServiceCategory> loadCachedCategories() {
    final raw = _storage.loadMiniAppServicesCacheRaw();
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => MiniAppServiceCategory.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<MiniAppServiceCategory>> refreshCategories() async {
    final next = await _api.listMiniProgramServicesForClient();
    await _persistCategories(next);
    return next;
  }

  @override
  Future<List<MiniAppServiceItem>> searchServices(String keyword) async {
    return _api.searchMiniProgramServices(keyword);
  }

  @override
  List<MiniAppServiceItem> loadPinnedItems() {
    return _storage
        .loadPinnedMiniAppsRaw()
        .whereType<Map>()
        .map((e) => MiniAppServiceItem.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  @override
  Future<void> savePinnedItems(List<MiniAppServiceItem> items) async {
    await _storage.savePinnedMiniAppsRaw(
      items.map((e) => e.toJson()).toList(),
    );
  }

  @override
  Map<String, List<String>> loadServiceOrders() {
    final raw = _storage.loadMiniAppServiceOrdersRaw();
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is List)
            entry.key as String: (entry.value as List)
                .whereType<String>()
                .where((id) => id.isNotEmpty)
                .toList(growable: false),
      };
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<void> saveServiceOrders(Map<String, List<String>> orders) async {
    await _storage.saveMiniAppServiceOrdersRaw(jsonEncode(orders));
  }

  @override
  String errorMessage(Object error) => _client.extractErrorMessage(error);

  Future<void> _persistCategories(List<MiniAppServiceCategory> list) async {
    try {
      final raw = jsonEncode(list.map((c) => c.toJson()).toList());
      await _storage.saveMiniAppServicesCacheRaw(raw);
    } catch (_) {
      // 缓存失败不影响主流程，下一次仍可直接走网络加载。
    }
  }
}
