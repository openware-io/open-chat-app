import '../models/friend_models.dart';
import '../models/im_user.dart';
import '../services/im_api.dart';
import 'friend_repository.dart';

/// ImApi 版本的好友仓库。
///
/// 申请列表里缺少发起人信息时，在仓库层补齐，避免 Provider 夹杂接口编排逻辑。
class ImFriendRepository implements FriendRepository {
  ImFriendRepository(this._api);

  final ImApi _api;

  @override
  Future<List<FriendItem>> loadFriends() => _api.friendsList();

  @override
  Future<List<FriendRequestItem>> loadPendingRequests() async {
    final list = await _api.pendingRequests();
    return Future.wait(list.map(_fillRequesterIfNeeded));
  }

  @override
  Future<void> sendRequest(int userId, String message,
      {String? source, int? groupId}) {
    return _api.sendFriendRequest(userId, message,
        source: source, groupId: groupId);
  }

  @override
  Future<void> handleRequest(int requestId, String action) {
    return _api.handleFriendRequest(requestId, action);
  }

  @override
  Future<void> blockFriend(int friendId) => _api.blockFriend(friendId);

  @override
  Future<void> unblockFriend(int friendId) => _api.unblockFriend(friendId);

  @override
  Future<List<FriendItem>> loadBlockedList() => _api.blockedFriends();

  @override
  Future<void> removeFriend(int friendId) => _api.removeFriend(friendId);

  @override
  Future<void> updateFriendRemark(int friendId, String remark) {
    return _api.updateFriend(friendId, {'remark': remark});
  }

  @override
  Future<List<String>> loadFriendGroups() => _api.friendGroups();

  @override
  Future<void> setFriendGroup(int friendId, String groupName) {
    return _api.updateFriend(friendId, {'groupName': groupName});
  }

  @override
  Future<List<dynamic>> searchUser(String keyword) => _api.searchUsers(keyword);

  @override
  Future<ImUser> loadUserProfile(int userId) => _api.getUser(userId);

  Future<FriendRequestItem> _fillRequesterIfNeeded(
    FriendRequestItem request,
  ) async {
    if (request.fromUser != null || request.fromUserId <= 0) {
      return request;
    }
    try {
      final user = await _api.getUser(request.fromUserId);
      return request.copyWith(
        fromUser: FriendUserBrief(
          id: user.id,
          username: user.username,
          nickname: user.nickname,
          avatar: user.avatar,
          signature: user.signature,
        ),
      );
    } catch (_) {
      return request;
    }
  }
}
