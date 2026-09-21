import '../models/recent_mini_program_entry.dart';

/// 最近使用小程序的持久化边界。
///
/// Provider 只维护内存列表和通知 UI；读取、解析、保存 JSON 由仓库负责。
abstract interface class RecentMiniProgramsRepository {
  List<RecentMiniProgramEntry> loadEntries();

  Future<void> saveEntries(List<RecentMiniProgramEntry> entries);
}
