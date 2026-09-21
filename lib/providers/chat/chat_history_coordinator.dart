import 'dart:async';

/// 聊天历史分页的并发协调器。
///
/// 同一个会话里，历史接口拉取、分页测高后的合并、实时消息插入可能交错发生。
/// 这里统一保证“同一会话串行、不同会话互不阻塞”，让 ChatProvider 专注状态变更。
class ChatHistoryCoordinator {
  final Map<String, Future<void>> _mergeTailBySession = {};
  final Map<String, Future<void>> _fetchTailBySession = {};

  Future<T> withMergeLock<T>(String sessionKey, T Function() syncWork) {
    final previous = _mergeTailBySession[sessionKey] ?? Future<void>.value();
    final completer = Completer<T>();
    final chain = previous.then((_) {
      try {
        completer.complete(syncWork());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    _mergeTailBySession[sessionKey] = chain.then((_) {}, onError: (_, __) {});
    return completer.future;
  }

  Future<T> runExclusiveFetch<T>(
    String sessionKey,
    Future<T> Function() body,
  ) {
    final previous = _fetchTailBySession[sessionKey] ?? Future<void>.value();
    final out = previous.then((_) => body());
    _fetchTailBySession[sessionKey] = out.then((_) {}, onError: (_, __) {});
    return out;
  }

  void clear() {
    _mergeTailBySession.clear();
    _fetchTailBySession.clear();
  }
}
