import 'package:flutter/foundation.dart';
import 'package:open_core/open_core.dart' show jsonInt;

import '../models/group_models.dart';
import '../repositories/group_repository.dart';

class GroupProvider extends ChangeNotifier {
  GroupProvider(this._repository);

  final GroupRepository _repository;

  List<GroupItem> groups = [];
  List<GroupMember> currentGroupMembers = [];
  int? _currentGroupMembersGroupId;

  void resetForLogout() {
    groups = [];
    currentGroupMembers = [];
    _currentGroupMembersGroupId = null;
    _memberViewAccountAllowed.clear();
    _groupOwnerIds.clear();
    notifyListeners();
  }

  Future<void> loadGroups() async {
    final loaded = await _repository.loadGroups();
    groups = loaded.map((group) {
      if (group.memberCount != null) return group;
      final old = _groupById(group.id);
      final cachedCount = _currentGroupMembersGroupId == group.id
          ? currentGroupMembers.length
          : old?.memberCount;
      return cachedCount == null
          ? group
          : group.copyWith(memberCount: cachedCount);
    }).toList();
    notifyListeners();
  }

  Future<GroupItem> createGroup(String name, List<int> memberIds) async {
    var g = await _repository.createGroup(name: name, memberIds: memberIds);
    g = g.copyWith(memberCount: g.memberCount ?? memberIds.length + 1);
    groups = [g, ...groups];
    notifyListeners();
    return g;
  }

  Future<Map<String, dynamic>> loadGroupInfo(int groupId) async {
    final info = await _repository.loadGroupInfo(groupId);
    final raw =
        info['allowMemberFriendRequest'] ?? info['allow_member_friend_request'];
    _memberFriendRequestAllowed[groupId] =
        raw is bool ? raw : raw?.toString().toLowerCase() != 'false';
    final rawViewAccount =
        info['allowMemberViewAccount'] ?? info['allow_member_view_account'];
    _memberViewAccountAllowed[groupId] = rawViewAccount is bool
        ? rawViewAccount
        : rawViewAccount?.toString().toLowerCase() != 'false';
    final ownerId = jsonInt(info['ownerId']) ?? jsonInt(info['owner_id']);
    if (ownerId == null) {
      _groupOwnerIds.remove(groupId);
    } else {
      _groupOwnerIds[groupId] = ownerId;
    }
    notifyListeners();
    return info;
  }

  /// 群级隐私：是否允许群成员互加好友（默认允许）。缓存由 [loadGroupInfo] 填充。
  final Map<int, bool> _memberFriendRequestAllowed = {};

  bool memberFriendRequestAllowed(int groupId) =>
      _memberFriendRequestAllowed[groupId] ?? true;

  /// 群级隐私：是否允许普通群成员查看其他成员的账号资料（默认允许）。
  final Map<int, bool> _memberViewAccountAllowed = {};

  final Map<int, int> _groupOwnerIds = {};

  bool memberViewAccountAllowed(int groupId) =>
      _memberViewAccountAllowed[groupId] ?? true;

  /// 群主不受「允许群成员查看他人账号」开关限制。
  bool canViewOtherMemberAccounts(int groupId, int viewerId) {
    return _groupOwnerIds[groupId] == viewerId ||
        memberViewAccountAllowed(groupId);
  }

  /// 群主不受「允许群成员互加好友」开关限制。
  bool canSendMemberFriendRequest(int groupId, int viewerId) {
    return _groupOwnerIds[groupId] == viewerId ||
        memberFriendRequestAllowed(groupId);
  }

  Future<List<GroupMember>> loadMembers(int groupId) async {
    final res = await _repository.loadMembers(groupId);
    _currentGroupMembersGroupId = groupId;
    currentGroupMembers = res;
    _setMemberCount(groupId, res.length);
    notifyListeners();
    return res;
  }

  /// 群成员变更通知后，同时刷新群列表和当前正在查看群的成员缓存。
  Future<void> refreshAfterMembershipChanged(
    int groupId, {
    bool refreshCurrentMembers = true,
  }) async {
    await loadGroups();
    if (refreshCurrentMembers) {
      if (_currentGroupMembersGroupId == groupId) {
        await loadMembers(groupId);
      } else {
        final members = await _repository.loadMembers(groupId);
        _setMemberCount(groupId, members.length);
        notifyListeners();
      }
    } else if (_currentGroupMembersGroupId == groupId) {
      _currentGroupMembersGroupId = null;
      currentGroupMembers = [];
      notifyListeners();
    }
  }

  Future<void> addMembers(int groupId, List<int> userIds) async {
    await _repository.addMembers(groupId, userIds);
    await loadMembers(groupId);
  }

  Future<void> removeMember(int groupId, int userId) async {
    await _repository.removeMember(groupId, userId);
    if (_currentGroupMembersGroupId == groupId) {
      currentGroupMembers =
          currentGroupMembers.where((m) => m.userId != userId).toList();
      _setMemberCount(groupId, currentGroupMembers.length);
    }
    notifyListeners();
  }

  Future<void> muteMember(int groupId, int userId, int? durationMinutes) async {
    await _repository.muteMember(groupId, userId, durationMinutes);
    await loadMembers(groupId);
  }

  Future<void> setRole(int groupId, int userId, String role) async {
    await _repository.setRole(groupId, userId, role);
    await loadMembers(groupId);
  }

  Future<void> leaveGroup(int groupId) async {
    await _repository.leaveGroup(groupId);
    groups = groups.where((g) => g.id != groupId).toList();
    if (_currentGroupMembersGroupId == groupId) {
      _currentGroupMembersGroupId = null;
      currentGroupMembers = [];
    }
    notifyListeners();
  }

  Future<void> updateGroup(int groupId, Map<String, dynamic> data) async {
    await _repository.updateGroup(groupId, data);
    final rawViewAccount =
        data['allowMemberViewAccount'] ?? data['allow_member_view_account'];
    if (rawViewAccount != null) {
      _memberViewAccountAllowed[groupId] = rawViewAccount is bool
          ? rawViewAccount
          : rawViewAccount.toString().toLowerCase() != 'false';
    }
    final idx = groups.indexWhere((g) => g.id == groupId);
    if (idx >= 0) {
      final g = groups[idx];
      if (data['name'] != null) {
        groups[idx] = g.copyWith(name: data['name'] as String);
      }
    }
    notifyListeners();
  }

  /// 设置当前用户在群内的昵称；成功后刷新成员缓存。
  Future<void> updateMyNickname(int groupId, String nickname) async {
    await _repository.updateMyNickname(groupId, nickname);
    await loadMembers(groupId);
    notifyListeners();
  }

  Future<void> dissolveGroup(int groupId) async {
    await _repository.dissolveGroup(groupId);
    groups = groups.where((g) => g.id != groupId).toList();
    notifyListeners();
  }

  /// 解析 WS `group:dissolve_notify` 中的群数字 id（用于清会话等；列表请 [loadGroups] 与后端对齐）。
  int? tryParseDissolveNotifyGroupId(dynamic data) => _parseNotifyGroupId(data);

  int? _parseNotifyGroupId(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final raw = map['groupId'] ?? map['id'] ?? map['group_id'];
    if (raw is int) return raw;
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  String getGroupName(dynamic groupId) {
    final gid = groupId is int ? groupId : int.tryParse('$groupId') ?? 0;
    final group = _groupById(gid);
    if (group != null) return group.name;
    return '群聊 $groupId';
  }

  /// 群聊展示名统一带「(人数)」后缀：先剥离既有 (N) 后缀，再追加最新成员数，
  /// 避免「群聊(3)(4)」或人数过期；自定义群名与自动生成名都生效。
  String getGroupDisplayName(dynamic groupId) {
    final gid = groupId is int ? groupId : int.tryParse('$groupId') ?? 0;
    final group = _groupById(gid);
    if (group == null) return '群聊 $groupId';
    final count = _currentGroupMembersGroupId == gid
        ? currentGroupMembers.length
        : group.memberCount;
    final name = group.name.trim();
    if (name.isEmpty) return count == null ? '群聊' : '群聊($count)';
    if (count == null) return name;
    final stripped = name.replaceFirst(RegExp(r'\s*[\(（]\d+[\)）]\s*$'), '');
    return '$stripped($count)';
  }

  GroupItem? _groupById(int groupId) {
    for (final group in groups) {
      if (group.id == groupId) return group;
    }
    return null;
  }

  void _setMemberCount(int groupId, int count) {
    final index = groups.indexWhere((group) => group.id == groupId);
    if (index >= 0) {
      groups[index] = groups[index].copyWith(memberCount: count);
    }
  }

  GroupMember? memberByUserId(int userId) {
    for (final m in currentGroupMembers) {
      if (m.userId == userId) return m;
    }
    return null;
  }
}
