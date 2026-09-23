import '../models/chat_message.dart';

/// 是否可在聊天室长按菜单中「转发」（系统/撤回等除外）。
///
/// Telegram 秘密聊天语义：私密聊天 / 私密群聊消息不可转发（E2EE 内容禁止流出会话）。
bool gvChatMessageCanForward(ChatMessage m, {String? chatType}) {
  if (m.msgType == 'system' || m.msgType == 'recall' || m.msgType == 'call') {
    return false;
  }
  if (m.status == 'recalled') return false;
  if (chatType == 'secret' || chatType == 'secret_group') return false;
  return true;
}
