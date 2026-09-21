import 'chat_provider_types.dart';

/// 聊天输入状态协调器。
///
/// 负责维护 WebSocket `typing` 事件的短时展示与过期清理。
class ChatTypingCoordinator {
  ChatTypingCoordinator({
    required Map<String, TypingEntry> typingUsers,
    required void Function() notifyChanged,
  })  : _typingUsers = typingUsers,
        _notifyChanged = notifyChanged;

  final Map<String, TypingEntry> _typingUsers;
  final void Function() _notifyChanged;

  void onTyping(dynamic data) {
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);
    final userId = map['userId']?.toString() ?? '';
    if (userId.isEmpty) return;
    final username = map['username'] as String? ?? '';
    _typingUsers[userId] = TypingEntry(
      username: username,
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    _notifyChanged();
    Future<void>.delayed(const Duration(milliseconds: 3500), () {
      final typing = _typingUsers[userId];
      if (typing != null &&
          DateTime.now().millisecondsSinceEpoch - typing.ts >= 3000) {
        _typingUsers.remove(userId);
        _notifyChanged();
      }
    });
  }
}
