import 'package:gv_core/gv_core.dart';

/// 小程序服务列表边界，统一处理远端数据、缓存和错误文案。
abstract interface class MiniAppServicesRepository {
  List<MiniAppServiceCategory> loadCachedCategories();

  Future<List<MiniAppServiceCategory>> refreshCategories();

  Future<List<MiniAppServiceItem>> searchServices(String keyword);

  List<MiniAppServiceItem> loadPinnedItems();

  Future<void> savePinnedItems(List<MiniAppServiceItem> items);

  Map<String, List<String>> loadServiceOrders();

  Future<void> saveServiceOrders(Map<String, List<String>> orders);

  String errorMessage(Object error);
}
