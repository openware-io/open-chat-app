import '../models/group_models.dart';

/// 群组业务边界，屏蔽具体 HTTP 接口与字段结构。
abstract interface class GroupRepository {
  Future<List<GroupItem>> loadGroups();

  Future<GroupItem> createGroup({
    required String name,
    required List<int> memberIds,
  });

  Future<Map<String, dynamic>> loadGroupInfo(int groupId);

  Future<List<GroupMember>> loadMembers(int groupId);

  Future<void> addMembers(int groupId, List<int> userIds);

  Future<void> removeMember(int groupId, int userId);

  Future<void> muteMember(int groupId, int userId, int? durationMinutes);

  Future<void> setRole(int groupId, int userId, String role);

  Future<void> leaveGroup(int groupId);

  Future<void> updateGroup(int groupId, Map<String, dynamic> data);

  Future<void> updateMyNickname(int groupId, String nickname);

  Future<void> dissolveGroup(int groupId);
}
