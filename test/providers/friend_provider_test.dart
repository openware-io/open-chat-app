import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/models/friend_models.dart';
import 'package:open_chat_app/models/im_user.dart';
import 'package:open_chat_app/providers/friend_provider.dart';
import 'package:open_chat_app/repositories/friend_repository.dart';

void main() {
  test('friend remark lookup trims values and ignores blank remarks', () {
    final provider = FriendProvider(_FakeFriendRepository())
      ..friends = const [
        FriendItem(
          friendId: 11,
          remark: '  老王  ',
          friendUser: FriendUserBrief(id: 11, nickname: '王明'),
        ),
        FriendItem(
          friendId: 12,
          remark: '   ',
          friendUser: FriendUserBrief(id: 12, nickname: '小李'),
        ),
      ];

    expect(provider.getFriendRemark(11), '老王');
    expect(provider.getFriendRemark(12), isNull);
    expect(provider.getFriendRemark(13), isNull);
  });

  test('friend default name ignores remark and falls back to username', () {
    final provider = FriendProvider(_FakeFriendRepository())
      ..friends = const [
        FriendItem(
          friendId: 11,
          remark: '老王',
          friendUser: FriendUserBrief(
            id: 11,
            username: 'wangming',
            nickname: '王明',
          ),
        ),
        FriendItem(
          friendId: 12,
          remark: '小李备注',
          friendUser: FriendUserBrief(id: 12, username: 'lixiao'),
        ),
      ];

    expect(provider.getFriendDefaultName(11), '王明');
    expect(provider.getFriendDefaultName(12), 'lixiao');
    expect(provider.getFriendDefaultName(13), isNull);
  });

  test('accepting a request updates the pending badge before friends reload',
      () async {
    final repository = _FakeFriendRepository();
    final provider = FriendProvider(repository);
    await provider.loadPendingRequests();
    expect(provider.pendingCount, 2);

    final handling = provider.handleRequest(1, 'accepted');
    await Future<void>.delayed(Duration.zero);

    expect(provider.pendingCount, 1);
    expect(provider.pendingRequests.map((item) => item.id), [2]);
    repository.friendsReload.complete(const <FriendItem>[]);
    await handling;
  });

  test('an older pending refresh cannot restore a rejected request', () async {
    final repository = _FakeFriendRepository();
    final provider = FriendProvider(repository);
    await provider.loadPendingRequests();

    final staleResult = Completer<List<FriendRequestItem>>();
    repository.nextPendingLoad = staleResult.future;
    final staleLoad = provider.loadPendingRequests();
    await provider.handleRequest(1, 'rejected');
    staleResult.complete(repository.requests);
    await staleLoad;

    expect(provider.pendingCount, 1);
    expect(provider.pendingRequests.single.id, 2);
  });

  test('incoming request notification updates badge before delayed refresh',
      () async {
    final repository = _FakeFriendRepository();
    final provider = FriendProvider(repository);
    await provider.loadPendingRequests();

    repository.requests = [
      ...repository.requests,
      const FriendRequestItem(id: 3, fromUserId: 13, toUserId: 20),
    ];
    provider.onFriendRequestNotify(null);

    expect(provider.pendingCount, 3);
    expect(provider.pendingRequests.length, 2);

    await Future<void>.delayed(const Duration(milliseconds: 600));

    expect(provider.pendingCount, 3);
    expect(provider.pendingRequests.map((item) => item.id), [1, 2, 3]);
    provider.dispose();
  });

  test('incoming notification prevents an older refresh hiding its badge',
      () async {
    final repository = _FakeFriendRepository();
    final provider = FriendProvider(repository);
    await provider.loadPendingRequests();

    final staleResult = Completer<List<FriendRequestItem>>();
    repository.nextPendingLoad = staleResult.future;
    final staleLoad = provider.loadPendingRequests();

    provider.onFriendRequestNotify(null);
    staleResult.complete(repository.requests);
    await staleLoad;

    expect(provider.pendingCount, 3);
    expect(provider.pendingRequests.length, 2);
    provider.dispose();
  });

  test('accepted request restores conversation even when friends reload fails',
      () async {
    final repository = _FakeFriendRepository()
      ..friendsLoadError = StateError('reload failed');
    final provider = FriendProvider(repository);
    await provider.loadPendingRequests();
    final acceptedFriendIds = <int>[];
    provider.onFriendAccepted = acceptedFriendIds.add;

    await provider.handleRequest(1, 'accepted');

    expect(acceptedFriendIds, [11]);
    expect(provider.pendingRequests.map((item) => item.id), [2]);
    provider.dispose();
  });

  test('friend accept notification emits the snake-case friend id immediately',
      () async {
    final repository = _FakeFriendRepository();
    final provider = FriendProvider(repository);
    final acceptedFriendIds = <int>[];
    provider.onFriendAccepted = acceptedFriendIds.add;

    provider.onFriendAcceptNotify(const {'friend_id': 31});

    expect(acceptedFriendIds, [31]);
    repository.friendsReload.complete(const <FriendItem>[]);
    await Future<void>.delayed(Duration.zero);
    expect(acceptedFriendIds, [31, 31]);
    provider.dispose();
  });

  test('foreground polling refreshes pending requests immediately', () async {
    final repository = _FakeFriendRepository();
    final provider = FriendProvider(repository);
    repository.requests = const [
      FriendRequestItem(id: 7, fromUserId: 17, toUserId: 20),
    ];

    provider.startPendingRequestPolling();
    await Future<void>.delayed(Duration.zero);

    expect(provider.pendingCount, 1);
    expect(provider.pendingRequests.single.id, 7);
    provider.stopPendingRequestPolling();
    provider.dispose();
  });

  test('sending from a group preserves source metadata', () async {
    final repository = _FakeFriendRepository();
    final provider = FriendProvider(repository);
    await provider.sendRequest(42, 'hello', source: 'group', groupId: 7);

    expect(repository.lastRequest, (userId: 42, source: 'group', groupId: 7));
  });
}

class _FakeFriendRepository implements FriendRepository {
  List<FriendRequestItem> requests = const [
    FriendRequestItem(id: 1, fromUserId: 11, toUserId: 20),
    FriendRequestItem(id: 2, fromUserId: 12, toUserId: 20),
  ];
  Future<List<FriendRequestItem>>? nextPendingLoad;
  final Completer<List<FriendItem>> friendsReload =
      Completer<List<FriendItem>>();
  Object? friendsLoadError;
  ({int userId, String? source, int? groupId})? lastRequest;

  @override
  Future<List<FriendRequestItem>> loadPendingRequests() {
    final next = nextPendingLoad;
    nextPendingLoad = null;
    return next ?? Future<List<FriendRequestItem>>.value(requests);
  }

  @override
  Future<void> handleRequest(int requestId, String action) async {
    requests = requests.where((item) => item.id != requestId).toList();
  }

  @override
  Future<List<FriendItem>> loadFriends() {
    final error = friendsLoadError;
    if (error != null) return Future<List<FriendItem>>.error(error);
    return friendsReload.future;
  }

  @override
  Future<void> blockFriend(int friendId) async {}

  @override
  Future<ImUser> loadUserProfile(int userId) => throw UnimplementedError();

  @override
  Future<void> removeFriend(int friendId) async {}

  @override
  Future<List<dynamic>> searchUser(String keyword) async => const [];

  @override
  Future<void> sendRequest(int userId, String message,
      {String? source, int? groupId}) async {
    lastRequest = (userId: userId, source: source, groupId: groupId);
  }

  @override
  Future<void> updateFriendRemark(int friendId, String remark) async {}

  @override
  Future<void> unblockFriend(int friendId) async {}

  @override
  Future<List<FriendItem>> loadBlockedList() async => const [];

  @override
  Future<List<String>> loadFriendGroups() async => const [];

  @override
  Future<void> setFriendGroup(int friendId, String groupName) async {}
}
