import '../../models/chat_message.dart';

/// 分页加载在列表中的视觉表现形式（当前仅支持「更新侧边缘」一种）。
///
/// 与 [RoomItem.pagingLoad] 配合，在 reverse 列表中于**视觉底部**插入占位行。
enum RoomPagingLoadKind {
  /// 正在会话「向新」一端追加历史时的加载指示。
  newerEdge,
}

/// 聊天室消息列表中的一行数据：时间分隔、单条消息，或分页加载占位。
///
/// 列表顺序为**新在前、旧在后**（与 [GvChatMessageList] 约定一致）。
class RoomItem {
  /// 内部统一构造：请使用 [RoomItem.time] / [RoomItem.msg] / [RoomItem.pagingLoad]。
  RoomItem._({
    this.timeText,
    this.msg,
    this.timeAnchorMsgId,
    this.pagingLoad,
  });

  /// [firstMsgId]：时间分隔后首条气泡 id（按会话时间序），便于按消息 id 检索行等逻辑使用。
  factory RoomItem.time(String t, {required String firstMsgId}) =>
      RoomItem._(timeText: t, timeAnchorMsgId: firstMsgId);

  /// 一条普通聊天消息对应的一行。
  factory RoomItem.msg(ChatMessage m) => RoomItem._(msg: m);

  /// 分页加载中的占位行。
  factory RoomItem.pagingLoad(RoomPagingLoadKind kind) =>
      RoomItem._(pagingLoad: kind);

  /// 时间分割线展示的文案（如「昨天 10:30」）。
  final String? timeText;

  /// 当本行是消息行时的数据。
  final ChatMessage? msg;

  /// 时间锚点消息 id，供高亮或滚动定位使用。
  final String? timeAnchorMsgId;

  /// 若非空，表示本行为分页加载占位。
  final RoomPagingLoadKind? pagingLoad;

  /// 是否为时间分隔行。
  bool get isTime => timeText != null;

  /// 是否为分页加载占位行。
  bool get isPagingLoad => pagingLoad != null;
}
