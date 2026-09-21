import '../../models/chat_message.dart';

/// 聊天记录查询页「分月 + ListView.builder」使用的扁平行抽象。
abstract class HistoryFlatItem {
  const HistoryFlatItem();
}

/// 按月分组的标题行。
class HistoryMonthHeader extends HistoryFlatItem {
  const HistoryMonthHeader(this.label);

  /// 展示文案，如 `2025年4月`。
  final String label;
}

/// 单条消息行（与 [HistoryMonthHeader] 交替出现）。
class HistoryMessageRow extends HistoryFlatItem {
  const HistoryMessageRow(this.msg);

  final ChatMessage msg;
}

/// 将 `月 -> 消息列表` 展开为 [HistoryFlatItem] 序列（先标题再该月消息）。
List<HistoryFlatItem> flattenHistoryGroupsForSearch(
  Map<String, List<ChatMessage>> groups,
) {
  final out = <HistoryFlatItem>[];
  for (final e in groups.entries) {
    out.add(HistoryMonthHeader(e.key));
    for (final m in e.value) {
      out.add(HistoryMessageRow(m));
    }
  }
  return out;
}
