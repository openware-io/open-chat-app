import 'package:flutter/foundation.dart';

import '../models/mini_program_route_args.dart';
import '../models/recent_mini_program_entry.dart';
import '../repositories/recent_mini_programs_repository.dart';

/// 最近使用小程序状态。
///
/// JSON 解析和磁盘存取交给 [RecentMiniProgramsRepository]，这里只负责排序、
/// 去重、截断和通知 UI。
class RecentMiniProgramsProvider extends ChangeNotifier {
  RecentMiniProgramsProvider(this._repository);

  final RecentMiniProgramsRepository _repository;
  static const int _maxEntries = 24;
  final List<RecentMiniProgramEntry> _entries = [];

  List<RecentMiniProgramEntry> get entries =>
      List<RecentMiniProgramEntry>.unmodifiable(_entries);

  void hydrateFromDisk() {
    _entries.clear();
    _entries.addAll(_repository.loadEntries());
    _sort();
    notifyListeners();
  }

  void resetForLogout() {
    _entries.clear();
    notifyListeners();
  }

  void _sort() {
    _entries.sort((a, b) => b.lastUsedAtMs.compareTo(a.lastUsedAtMs));
  }

  Future<void> recordOpen(MiniProgramRouteArgs args) async {
    final url = args.url.trim();
    if (url.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final key =
        args.miniProgramId.trim().isNotEmpty ? args.miniProgramId.trim() : url;
    _entries.removeWhere((e) => e.dedupeKey == key);
    _entries.add(
      RecentMiniProgramEntry(
        url: args.url,
        title: args.title,
        introduction: args.introduction,
        iconUrl: args.iconUrl,
        miniProgramId: args.miniProgramId,
        lastUsedAtMs: now,
      ),
    );
    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    _sort();
    notifyListeners();
    await _repository.saveEntries(_entries);
  }
}
