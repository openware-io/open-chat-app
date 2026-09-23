import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/models/group_models.dart';
import 'package:open_chat_app/providers/group_provider.dart';
import 'package:open_chat_app/repositories/group_repository.dart';

void main() {
  test('group item accepts camelCase and snake_case member counts', () {
    expect(
      GroupItem.fromJson(
        const {'id': 1, 'name': '群聊(2)', 'memberCount': '2'},
      ).memberCount,
      2,
    );
    expect(
      GroupItem.fromJson(
        const {'id': 2, 'name': '群聊(3)', 'member_count': 3},
      ).memberCount,
      3,
    );
  });

  test('membership refresh replaces the stale default group-name count',
      () async {
    final repository = _FakeGroupRepository(
      groups: [
        const GroupItem(id: 7, name: '群聊(3)', memberCount: 3),
      ],
      members: const [
        GroupMember(userId: 1),
        GroupMember(userId: 2),
        GroupMember(userId: 3),
      ],
    );
    final provider = GroupProvider(repository);

    await provider.loadGroups();
    await provider.loadMembers(7);
    expect(provider.getGroupDisplayName(7), '群聊(3)');

    repository.members = const [
      GroupMember(userId: 1),
      GroupMember(userId: 2),
    ];
    await provider.refreshAfterMembershipChanged(7);

    expect(provider.getGroupDisplayName(7), '群聊(2)');
    expect(provider.groups.single.memberCount, 2);
  });

  test('membership refresh updates a group not opened in the chat room',
      () async {
    final repository = _FakeGroupRepository(
      groups: [
        const GroupItem(id: 8, name: '群聊(3)', memberCount: 3),
      ],
      members: const [
        GroupMember(userId: 1),
        GroupMember(userId: 2),
      ],
    );
    final provider = GroupProvider(repository);

    await provider.loadGroups();
    await provider.refreshAfterMembershipChanged(8);

    expect(provider.getGroupDisplayName(8), '群聊(2)');
    expect(provider.currentGroupMembers, isEmpty);
  });

  test('group owner can view account details when members cannot', () async {
    final repository = _FakeGroupRepository(
      groups: const [],
      members: const [],
      groupInfo: const {
        'owner_id': '1',
        'allow_member_friend_request': false,
        'allow_member_view_account': false,
      },
    );
    final provider = GroupProvider(repository);

    await provider.loadGroupInfo(7);

    expect(provider.canViewOtherMemberAccounts(7, 1), isTrue);
    expect(provider.canViewOtherMemberAccounts(7, 2), isFalse);
    expect(provider.canSendMemberFriendRequest(7, 1), isTrue);
    expect(provider.canSendMemberFriendRequest(7, 2), isFalse);

    await provider.updateGroup(7, {'allowMemberViewAccount': true});
    expect(provider.canViewOtherMemberAccounts(7, 2), isTrue);
  });
}

class _FakeGroupRepository implements GroupRepository {
  _FakeGroupRepository({
    required this.groups,
    required this.members,
    this.groupInfo = const {},
  });

  List<GroupItem> groups;
  List<GroupMember> members;
  Map<String, dynamic> groupInfo;

  @override
  Future<List<GroupItem>> loadGroups() async => groups;

  @override
  Future<List<GroupMember>> loadMembers(int groupId) async => members;

  @override
  Future<GroupItem> createGroup({
    required String name,
    required List<int> memberIds,
  }) async =>
      GroupItem(id: 1, name: name);

  @override
  Future<Map<String, dynamic>> loadGroupInfo(int groupId) async => groupInfo;

  @override
  Future<void> addMembers(int groupId, List<int> userIds) async {}

  @override
  Future<void> removeMember(int groupId, int userId) async {}

  @override
  Future<void> leaveGroup(int groupId) async {}

  @override
  Future<void> updateGroup(int groupId, Map<String, dynamic> data) async {}

  @override
  Future<void> dissolveGroup(int groupId) async {}

  @override
  Future<void> updateMyNickname(int groupId, String nickname) async {}

  @override
  Future<void> muteMember(
      int groupId, int userId, int? durationMinutes) async {}

  @override
  Future<void> setRole(int groupId, int userId, String role) async {}
}
