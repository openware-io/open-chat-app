import '../models/group_models.dart';
import '../services/im_api.dart';
import 'group_repository.dart';

/// ImApi 版本的群组仓库，后续可替换为代码生成的接口客户端。
class ImGroupRepository implements GroupRepository {
  ImGroupRepository(this._api);

  final ImApi _api;

  @override
  Future<List<GroupItem>> loadGroups() => _api.myGroups();

  @override
  Future<GroupItem> createGroup({
    required String name,
    required List<int> memberIds,
  }) {
    return _api.createGroup(name: name, memberIds: memberIds);
  }

  @override
  Future<Map<String, dynamic>> loadGroupInfo(int groupId) {
    return _api.groupInfo(groupId);
  }

  @override
  Future<List<GroupMember>> loadMembers(int groupId) {
    return _api.groupMembers(groupId);
  }

  @override
  Future<void> addMembers(int groupId, List<int> userIds) {
    return _api.addGroupMembers(groupId, userIds);
  }

  @override
  Future<void> removeMember(int groupId, int userId) {
    return _api.removeGroupMember(groupId, userId);
  }

  @override
  Future<void> muteMember(int groupId, int userId, int? durationMinutes) {
    return _api.muteGroupMember(groupId, userId, durationMinutes);
  }

  @override
  Future<void> setRole(int groupId, int userId, String role) {
    return _api.setGroupMemberRole(groupId, userId, role);
  }

  @override
  Future<void> leaveGroup(int groupId) => _api.leaveGroup(groupId);

  @override
  Future<void> updateGroup(int groupId, Map<String, dynamic> data) {
    return _api.updateGroup(groupId, data);
  }

  @override
  Future<void> updateMyNickname(int groupId, String nickname) {
    return _api.updateMyGroupNickname(groupId, nickname);
  }

  @override
  Future<void> dissolveGroup(int groupId) => _api.dissolveGroup(groupId);
}
