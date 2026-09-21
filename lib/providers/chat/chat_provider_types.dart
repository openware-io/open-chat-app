import '../../models/chat_message.dart';

/// 输入框「正在输入」提示：展示用昵称与时间戳（用于过期判断）。
class TypingEntry {
  /// 创建一条输入状态。
  TypingEntry({required this.username, required this.ts});

  /// 对方显示名或用户名片段。
  final String username;

  /// 服务端或本地记录的时间戳（毫秒或秒，与现有 WS 载荷一致即可比较新旧）。
  final int ts;
}

/// [serverCount] 为本批接口返回条数（解析后、合并前），与 [ImApi.messageHistory] 的 pageSize 对齐用于判断是否到达分页末端；
/// [added] 为实际并入列表的条数。合并去重或锚点失配时二者常不等，勿仅用 [added] 判定「已无更多」。
typedef LoadHistoryPage = ({int added, int serverCount});

/// [preparePagingHistoryMerge] 的返回值：[commitPagingHistoryMerge] 写入前用于离屏测高。
/// [mergedForMeasure] 为 null 表示锚点未命中，调用方不得提交合并。
typedef PreparedPagingHistoryMerge = ({
  LoadHistoryPage page,
  List<ChatMessage> parsedMessages,
  String? beforeMsgId,
  String? afterMsgId,
  List<ChatMessage>? mergedForMeasure,
});

/// 当前会话实时消息：在写入 [messageMap] 前由聊天页离屏测高，再 [commitDeferredRealtimeSessionInsert]。
class DeferredRealtimeSessionInsert {
  /// 构造待提交的合并结果。
  DeferredRealtimeSessionInsert({
    required this.peerId,
    required this.chatType,
    required this.mergedSession,
    required this.version,
    required this.readMsgIds,
  });

  final String peerId;
  final String chatType;

  /// 时间上 **旧→新**，与 [messageMap] 会话列表一致。
  final List<ChatMessage> mergedSession;

  /// 单调版本，用于测高完成后与并发推送区分。
  final int version;

  /// 合入后需上报已读的服务端消息 id 列表。
  final List<String> readMsgIds;
}
