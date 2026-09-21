import 'dart:async';

/// 收到陌生会话消息后的通讯录同步协调器。
///
/// 对连续推送做 debounce，并串行执行好友/群列表刷新，避免消息风暴时打爆接口。
class ChatAddressBookSyncCoordinator {
  ChatAddressBookSyncCoordinator({
    required int? Function() myId,
    required bool Function(int userId) hasFriendDisplay,
    required bool Function(String groupId) hasGroup,
    required Future<void> Function() loadFriends,
    required Future<void> Function() loadGroups,
    required bool Function() applyDisplayNames,
    required void Function() saveConversations,
  })  : _myId = myId,
        _hasFriendDisplay = hasFriendDisplay,
        _hasGroup = hasGroup,
        _loadFriends = loadFriends,
        _loadGroups = loadGroups,
        _applyDisplayNames = applyDisplayNames,
        _saveConversations = saveConversations;

  final int? Function() _myId;
  final bool Function(int userId) _hasFriendDisplay;
  final bool Function(String groupId) _hasGroup;
  final Future<void> Function() _loadFriends;
  final Future<void> Function() _loadGroups;
  final bool Function() _applyDisplayNames;
  final void Function() _saveConversations;

  Timer? _debounceTimer;
  Future<void> _tail = Future<void>.value();

  void maybeScheduleForIncoming(String peerId, String chatType) {
    final my = _myId();
    if (my == null) return;
    if (chatType == 'private') {
      final userId = int.tryParse(peerId) ?? 0;
      if (userId == my) return;
      if (_hasFriendDisplay(userId)) return;
    } else if (chatType == 'group') {
      if (_hasGroup(peerId)) return;
    } else {
      return;
    }
    _schedule();
  }

  void reset() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _tail = Future<void>.value();
  }

  void _schedule() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _debounceTimer = null;
      _tail = _tail.then((_) => _syncAndRefreshNames());
    });
  }

  Future<void> _syncAndRefreshNames() async {
    try {
      await Future.wait<void>([
        _loadFriends().catchError((_, __) {}),
        _loadGroups().catchError((_, __) {}),
      ]);
    } catch (_) {}
    if (_applyDisplayNames()) {
      _saveConversations();
    }
  }
}
