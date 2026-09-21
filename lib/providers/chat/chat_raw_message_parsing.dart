import '../../models/chat_message.dart';

/// 将 IM 历史接口返回的 [List]（元素为 Map）转为 [ChatMessage] 列表。
///
/// 与各处内联的 [ChatMessage.fromJson] 逻辑保持一致，避免重复与漏改。
List<ChatMessage> parseChatHistoryRaw(List<dynamic> raw) => raw
    .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map)))
    .toList();
