import 'package:flutter/foundation.dart';

import 'package:open_core/open_core.dart';
import '../repositories/mini_app_services_repository.dart';

class MiniAppServicesProvider extends ChangeNotifier {
  MiniAppServicesProvider(this._repository);

  final MiniAppServicesRepository _repository;

  List<MiniAppServiceCategory> categories = [];
  bool loading = false;
  String? loadError;

  List<MiniAppServiceItem> searchResults = [];
  bool searching = false;
  String? searchError;
  String lastSearchKeyword = '';

  List<MiniAppServiceItem> pinnedItems = [];
  Map<String, List<String>> _serviceOrders = const {};

  /// 从本地缓存恢复列表，页面先展示旧数据，再由 [refresh] 拉取新数据替换。
  void hydrateFromCache() {
    final parsed = _repository.loadCachedCategories();
    if (parsed.isEmpty) return;
    categories = _applySavedOrders(parsed);
    loadError = null;
    notifyListeners();
  }

  /// [silentIfHasCache] 为 true 且已有数据时，不打断整页展示，只静默刷新。
  Future<void> refresh({bool silentIfHasCache = false}) async {
    final hadData = categories.isNotEmpty;
    final blockUi = !silentIfHasCache || !hadData;
    if (blockUi) {
      loading = true;
      loadError = null;
      notifyListeners();
    } else {
      loadError = null;
      notifyListeners();
    }
    try {
      final next = await _repository.refreshCategories();
      categories = _applySavedOrders(next);
      loadError = null;
    } catch (e) {
      if (!hadData) {
        loadError = _repository.errorMessage(e);
        categories = [];
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// 关键词搜索小程序服务项（后端按 name/introduction 模糊匹配，含运营后台）。
  Future<void> search(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }
    searching = true;
    searchError = null;
    lastSearchKeyword = trimmed;
    notifyListeners();
    try {
      final next = await _repository.searchServices(trimmed);
      if (lastSearchKeyword != trimmed) return;
      searchResults = next;
    } catch (e) {
      if (lastSearchKeyword != trimmed) return;
      searchResults = [];
      searchError = _repository.errorMessage(e);
    } finally {
      if (lastSearchKeyword == trimmed) {
        searching = false;
        notifyListeners();
      }
    }
  }

  void clearSearch() {
    searchResults = [];
    searching = false;
    searchError = null;
    lastSearchKeyword = '';
    notifyListeners();
  }

  bool isPinned(String id) => pinnedItems.any((i) => i.id == id);

  /// 从本地存储恢复用户固定（置顶）的服务项。
  void hydratePinnedFromCache() {
    pinnedItems = _repository.loadPinnedItems();
    notifyListeners();
  }

  /// 从本地恢复每个服务分类内的用户自定义顺序。
  void hydrateServiceOrdersFromCache() {
    _serviceOrders = _repository.loadServiceOrders();
    categories = _applySavedOrders(categories);
    notifyListeners();
  }

  /// 固定 / 取消固定一个服务项；变更后持久化到本地（按登录用户隔离）。
  Future<void> togglePin(MiniAppServiceItem item) async {
    if (isPinned(item.id)) {
      pinnedItems = pinnedItems.where((i) => i.id != item.id).toList();
    } else {
      pinnedItems = [...pinnedItems, item];
    }
    notifyListeners();
    await _repository.savePinnedItems(pinnedItems);
  }

  /// 拖动调整固定项顺序；变更后持久化到本地（与固定关系一起存）。
  Future<void> reorderPinned(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= pinnedItems.length) return;
    if (newIndex < 0 || newIndex > pinnedItems.length) return;
    final item = pinnedItems.removeAt(oldIndex);
    pinnedItems.insert(newIndex, item);
    notifyListeners();
    await _repository.savePinnedItems(pinnedItems);
  }

  /// 调整同一分类内的服务顺序，并按当前登录用户持久化。
  Future<void> reorderCategoryItem(
    String categoryName,
    int oldIndex,
    int newIndex,
  ) async {
    final categoryIndex = categories.indexWhere(
      (category) => category.typeName == categoryName,
    );
    if (categoryIndex < 0) return;

    final category = categories[categoryIndex];
    if (oldIndex < 0 || oldIndex >= category.items.length) return;
    if (newIndex < 0 || newIndex >= category.items.length) return;
    if (oldIndex == newIndex) return;

    final reordered = category.items.toList();
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    final nextCategories = categories.toList();
    nextCategories[categoryIndex] = category.copyWith(items: reordered);
    categories = nextCategories;
    _serviceOrders = {
      ..._serviceOrders,
      categoryName: reordered
          .map((item) => item.id)
          .where((id) => id.isNotEmpty)
          .toList(growable: false),
    };
    notifyListeners();

    await _repository.saveServiceOrders(_serviceOrders);
  }

  void resetForLogout() {
    categories = [];
    loadError = null;
    loading = false;
    searchResults = [];
    searching = false;
    searchError = null;
    lastSearchKeyword = '';
    pinnedItems = [];
    _serviceOrders = const {};
    notifyListeners();
  }

  /// 按后台配置的 [MiniAppServiceItem.id] 查找，与 `OPEN_MINA:` 扫码逻辑一致。
  MiniAppServiceItem? findMiniProgramById(String id) {
    final want = id.trim();
    if (want.isEmpty) return null;
    for (final c in categories) {
      for (final i in c.items) {
        if (i.id == want) return i;
      }
    }
    return null;
  }

  List<MiniAppServiceCategory> _applySavedOrders(
    List<MiniAppServiceCategory> source,
  ) {
    return source.map((category) {
      final savedOrder = _serviceOrders[category.typeName];
      if (savedOrder == null || savedOrder.isEmpty) return category;

      final ranks = <String, int>{
        for (var i = 0; i < savedOrder.length; i++) savedOrder[i]: i,
      };
      final indexed = category.items.indexed.toList();
      indexed.sort((a, b) {
        final aRank = ranks[a.$2.id];
        final bRank = ranks[b.$2.id];
        if (aRank != null && bRank != null) return aRank.compareTo(bRank);
        if (aRank != null) return -1;
        if (bRank != null) return 1;
        return a.$1.compareTo(b.$1);
      });
      return category.copyWith(
        items: indexed.map((entry) => entry.$2).toList(growable: false),
      );
    }).toList(growable: false);
  }
}
