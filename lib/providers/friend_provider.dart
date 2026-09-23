import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:open_core/open_core.dart';
import '../repositories/friend_repository.dart';

/// Debug/profile only: append 500 synthetic [FriendItem]s after each friends load
/// to stress-test the contacts screen. Set to `false` when finished testing.
const bool kContactsStressTestAppend500MockFriends = false;

const Duration _friendRequestRefreshDelay = Duration(milliseconds: 500);
const Duration _pendingRequestPollInterval = Duration(seconds: 15);

List<FriendItem> _contactsStressMockFriends500() {
  const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  return List<FriendItem>.generate(500, (i) {
    final id = 1000000 + i;
    final L = letters[i % letters.length];
    return FriendItem(
      friendId: id,
      userId: id,
      friendUser: FriendUserBrief(
        id: id,
        username: 'stress_$i',
        nickname: '$L模拟好友${i.toString().padLeft(3, '0')}',
      ),
    );
  });
}

class FriendProvider extends ChangeNotifier {
  FriendProvider(this._repository);

  final FriendRepository _repository;

  /// 好友关系建立后的应用内事件。由启动接线层绑定到会话恢复逻辑，
  /// 让本机接受和服务端实时通知走同一条幂等路径。
  ValueChanged<int>? onFriendAccepted;

  List<FriendItem> friends = [];
  List<FriendRequestItem> pendingRequests = [];
  List<FriendItem> blockedFriends = [];
  List<String> friendGroups = [];
  int pendingCount = 0;
  final Map<int, bool> onlineMap = {};
  final Set<int> _handlingRequestIds = <int>{};
  Timer? _pendingRequestRefreshTimer;
  Timer? _pendingRequestPollTimer;
  int _pendingLoadSequence = 0;
  int _lastAppliedPendingLoadSequence = 0;
  int _pendingMutationRevision = 0;

  bool isHandlingRequest(int requestId) =>
      _handlingRequestIds.contains(requestId);

  bool isBlocked(int friendId) =>
      blockedFriends.any((f) => f.friendId == friendId);

  FriendDisplay? getFriendDisplay(int userId) {
    for (final f in friends) {
      if (f.friendId == userId) {
        return FriendDisplay(
          name: f.displayName,
          avatar: f.friendUser?.avatar,
          id: f.friendId,
        );
      }
    }
    return null;
  }

  /// 好友备注；无好友记录或备注为空时返回 null。
  String? getFriendRemark(int userId) {
    for (final f in friends) {
      if (f.friendId == userId) {
        final remark = f.remark?.trim() ?? '';
        return remark.isNotEmpty ? remark : null;
      }
    }
    return null;
  }

  /// 好友个人信息昵称（不含备注）；无好友记录或无昵称返回 null。
  String? getPersonalNickname(int userId) {
    for (final f in friends) {
      if (f.friendId == userId) {
        final nickname = f.friendUser?.nickname?.trim() ?? '';
        return nickname.isNotEmpty ? nickname : null;
      }
    }
    return null;
  }

  /// 好友默认名字（不含仅自己可见的备注）：个人昵称优先，其次用户名。
  String? getFriendDefaultName(int userId) {
    for (final f in friends) {
      if (f.friendId == userId) {
        final nickname = f.friendUser?.nickname?.trim() ?? '';
        if (nickname.isNotEmpty) return nickname;
        final username = f.friendUser?.username.trim() ?? '';
        return username.isNotEmpty ? username : null;
      }
    }
    return null;
  }

  /// 登出或切换账号前清空，避免 UI 仍用上一账号的好友缓存解析昵称/头像。
  void resetForLogout() {
    _pendingRequestRefreshTimer?.cancel();
    _pendingRequestRefreshTimer = null;
    stopPendingRequestPolling();
    friends = [];
    pendingRequests = [];
    blockedFriends = [];
    friendGroups = [];
    pendingCount = 0;
    _handlingRequestIds.clear();
    _pendingLoadSequence++;
    _lastAppliedPendingLoadSequence = _pendingLoadSequence;
    _pendingMutationRevision++;
    onlineMap.clear();
    notifyListeners();
  }

  Future<void> loadFriends() async {
    friends = await _repository.loadFriends();
    if (kContactsStressTestAppend500MockFriends) {
      friends = [...friends, ..._contactsStressMockFriends500()];
    }
    notifyListeners();
  }

  Future<void> loadPendingRequests() async {
    final loadSequence = ++_pendingLoadSequence;
    final mutationRevision = _pendingMutationRevision;
    final list = await _repository.loadPendingRequests();
    if (loadSequence < _lastAppliedPendingLoadSequence ||
        mutationRevision != _pendingMutationRevision) {
      return;
    }
    _lastAppliedPendingLoadSequence = loadSequence;
    pendingRequests = list;
    pendingCount = pendingRequests.length;
    notifyListeners();
  }

  /// 在 Socket 重连、App 回前台等兜底时安全校准好友申请数量。
  Future<void> refreshPendingRequestsSafely() async {
    try {
      await loadPendingRequests();
    } catch (error, stackTrace) {
      debugPrint(
        'FriendProvider pending request refresh failed: '
        '$error\n$stackTrace',
      );
    }
  }

  /// 登录且处于前台时低频校准待处理申请，兜底 Socket 通知偶发丢失。
  void startPendingRequestPolling() {
    if (_pendingRequestPollTimer?.isActive == true) return;
    unawaited(refreshPendingRequestsSafely());
    _pendingRequestPollTimer = Timer.periodic(
      _pendingRequestPollInterval,
      (_) => unawaited(refreshPendingRequestsSafely()),
    );
  }

  /// App 进入后台或退出登录后停止轮询，避免无意义网络请求。
  void stopPendingRequestPolling() {
    _pendingRequestPollTimer?.cancel();
    _pendingRequestPollTimer = null;
  }

  Future<void> sendRequest(int userId, String message,
      {String? source, int? groupId}) async {
    await _repository.sendRequest(userId, message,
        source: source, groupId: groupId);
  }

  Future<void> handleRequest(int requestId, String action) async {
    if (!_handlingRequestIds.add(requestId)) return;
    final acceptedFriendId =
        action == 'accepted' ? _pendingRequestFromUserId(requestId) : null;
    notifyListeners();
    try {
      await _repository.handleRequest(requestId, action);
      _pendingMutationRevision++;
      pendingRequests =
          pendingRequests.where((r) => r.id != requestId).toList();
      pendingCount = pendingRequests.length;
      notifyListeners();
      if (action == 'accepted') {
        if (acceptedFriendId != null) {
          onFriendAccepted?.call(acceptedFriendId);
        }
        try {
          await loadFriends();
          if (acceptedFriendId != null) {
            onFriendAccepted?.call(acceptedFriendId);
          }
        } catch (error, stackTrace) {
          // 接受接口已经成功时，好友列表刷新失败不能再把本次操作判定为失败，
          // 否则页面会跳过后续问候消息，会话也无法恢复。
          debugPrint(
            'FriendProvider friends refresh after accept failed: '
            '$error\n$stackTrace',
          );
        }
      }
    } finally {
      _handlingRequestIds.remove(requestId);
      notifyListeners();
    }
  }

  Future<void> blockFriend(int friendId) async {
    await _repository.blockFriend(friendId);
    await loadFriends();
  }

  Future<void> unblockFriend(int friendId) async {
    await _repository.unblockFriend(friendId);
    blockedFriends =
        blockedFriends.where((f) => f.friendId != friendId).toList();
    notifyListeners();
    await loadFriends();
  }

  Future<void> loadBlockedList() async {
    blockedFriends = await _repository.loadBlockedList();
    notifyListeners();
  }

  Future<void> loadFriendGroups() async {
    friendGroups = await _repository.loadFriendGroups();
    notifyListeners();
  }

  Future<void> setFriendGroup(int friendId, String groupName) async {
    await _repository.setFriendGroup(friendId, groupName);
    await loadFriends();
  }

  /// 重命名分组：把该分组下所有好友的 groupName 改为新名称。
  Future<void> renameFriendGroup(String oldName, String newName) async {
    final targets =
        friends.where((f) => (f.groupName?.trim() ?? '') == oldName).toList();
    for (final f in targets) {
      await _repository.setFriendGroup(f.friendId, newName);
    }
    await loadFriends();
    await loadFriendGroups();
  }

  /// 删除分组：把该分组下所有好友移回「无分组」，好友关系保持不变。
  Future<void> deleteFriendGroup(String groupName) async {
    final targets =
        friends.where((f) => (f.groupName?.trim() ?? '') == groupName).toList();
    for (final f in targets) {
      await _repository.setFriendGroup(f.friendId, '');
    }
    await loadFriends();
    await loadFriendGroups();
  }

  Future<void> removeFriend(int friendId) async {
    await _repository.removeFriend(friendId);
    friends = friends.where((f) => f.friendId != friendId).toList();
    notifyListeners();
  }

  Future<void> updateFriendRemark(int friendId, String remark) async {
    await _repository.updateFriendRemark(friendId, remark);
    await loadFriends();
  }

  Future<List<dynamic>> searchUser(String keyword) =>
      _repository.searchUser(keyword);

  Future<ImUser> loadUserProfile(int userId) {
    return _repository.loadUserProfile(userId);
  }

  void onStatusChange(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    final uid = jsonInt(map['userId']);
    final isOnline = map['isOnline'] as bool? ?? map['is_online'] as bool?;
    if (uid != null && isOnline != null) {
      onlineMap[uid] = isOnline;
      notifyListeners();
    }
  }

  void onFriendRequestNotify(dynamic _) {
    // 通知可能早于好友申请事务提交：先即时展示徽标，并让通知前发起的旧列表请求失效。
    // 稍后再以服务端列表校准，重复通知造成的临时多计数也会被修正。
    _pendingMutationRevision++;
    pendingCount++;
    notifyListeners();

    _pendingRequestRefreshTimer?.cancel();
    _pendingRequestRefreshTimer = Timer(_friendRequestRefreshDelay, () {
      _pendingRequestRefreshTimer = null;
      unawaited(refreshPendingRequestsSafely());
    });
  }

  void onFriendAcceptNotify(dynamic data) {
    final friendId = _friendIdFromAcceptNotify(data);
    if (friendId != null) {
      onFriendAccepted?.call(friendId);
    }
    unawaited(_refreshFriendsAfterAcceptNotify(friendId));
  }

  int? _pendingRequestFromUserId(int requestId) {
    for (final request in pendingRequests) {
      if (request.id == requestId) return request.fromUserId;
    }
    return null;
  }

  int? _friendIdFromAcceptNotify(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    return jsonInt(map['friend_id'] ?? map['friendId']);
  }

  Future<void> _refreshFriendsAfterAcceptNotify(int? friendId) async {
    try {
      await loadFriends();
      if (friendId != null) {
        onFriendAccepted?.call(friendId);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'FriendProvider friends refresh after notification failed: '
        '$error\n$stackTrace',
      );
    }
  }

  @override
  void dispose() {
    _pendingRequestRefreshTimer?.cancel();
    _pendingRequestPollTimer?.cancel();
    super.dispose();
  }
}

class FriendDisplay {
  FriendDisplay({required this.name, this.avatar, required this.id});
  final String name;
  final String? avatar;
  final int id;
}
