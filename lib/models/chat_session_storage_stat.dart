/// 单个会话在本机的存储占用统计。
///
/// [messageBytes] 为该会话本地消息库（`cached_messages` 文本列）的字节数估计；
/// 媒体缓存当前没有按会话归类的持久化缓存，因此媒体占用由 UI 侧按 0 计入。
class ChatSessionStorageStat {
  const ChatSessionStorageStat({
    required this.peerId,
    required this.chatType,
    required this.messageCount,
    required this.messageBytes,
  });

  final String peerId;
  final String chatType;
  final int messageCount;
  final int messageBytes;
}
