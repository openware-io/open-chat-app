import '../models/friend_models.dart';
import '../models/im_user.dart';

/// 好友业务边界。
///
/// Provider 维护 UI 状态，Repository 负责远端数据和必要的数据补全。
abstract interface class FriendRepository {
  Future<List<FriendItem>> loadFriends();

  Future<List<FriendRequestItem>> loadPendingRequests();

  Future<void> sendRequest(int userId, String message,
      {String? source, int? groupId});

  Future<void> handleRequest(int requestId, String action);

  Future<void> blockFriend(int friendId);

  Future<void> unblockFriend(int friendId);

  Future<List<FriendItem>> loadBlockedList();

  Future<void> removeFriend(int friendId);

  Future<void> updateFriendRemark(int friendId, String remark);

  Future<List<String>> loadFriendGroups();

  Future<void> setFriendGroup(int friendId, String groupName);

  Future<List<dynamic>> searchUser(String keyword);

  Future<ImUser> loadUserProfile(int userId);
}
