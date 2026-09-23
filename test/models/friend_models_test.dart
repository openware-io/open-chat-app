import 'package:flutter_test/flutter_test.dart';
import 'package:open_core/open_core.dart';

void main() {
  group('FriendItem', () {
    test('reads flat friend profile fields returned by the friends API', () {
      final friend = FriendItem.fromJson({
        'id': 10,
        'userId': 2,
        'friendId': 3,
        'friendUsername': 'xch11',
        'friendNickname': 'XCH 11',
        'friendAvatar': 'https://example.com/avatar.jpg',
        'remark': '',
      });

      expect(friend.friendId, 3);
      expect(friend.friendUser?.id, 3);
      expect(friend.friendUser?.username, 'xch11');
      expect(friend.friendUser?.nickname, 'XCH 11');
      expect(friend.friendUser?.avatar, 'https://example.com/avatar.jpg');
      expect(friend.displayName, 'XCH 11');
    });

    test('falls back to username when nickname is blank', () {
      final friend = FriendItem.fromJson({
        'friendId': 3,
        'friendUsername': 'xch11',
        'friendNickname': '',
      });

      expect(friend.displayName, 'xch11');
    });
  });
}
