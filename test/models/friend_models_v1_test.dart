import 'package:flutter_test/flutter_test.dart';
import 'package:gv_core/gv_core.dart';

void main() {
  test('parses flat friend fields returned by the Java API', () {
    final friend = FriendItem.fromJson({
      'id': 10,
      'userId': 2,
      'friendId': 3,
      'friendUsername': 'xch11',
      'friendNickname': '小陈',
      'friendAvatar': 'https://media.example.com/avatar.jpg',
      'remark': '',
      'status': 'normal',
    });

    expect(friend.friendId, 3);
    expect(friend.userId, 2);
    expect(friend.friendUser?.id, 3);
    expect(friend.friendUser?.username, 'xch11');
    expect(friend.friendUser?.nickname, '小陈');
    expect(friend.friendUser?.avatar, 'https://media.example.com/avatar.jpg');
    expect(friend.displayName, '小陈');
  });

  test('falls back to username when the flat nickname is blank', () {
    final friend = FriendItem.fromJson({
      'userId': 2,
      'friendId': 3,
      'friendUsername': 'xch11',
      'friendNickname': '',
      'remark': '',
    });

    expect(friend.displayName, 'xch11');
  });

  test('parses the groupName field (camelCase and snake_case)', () {
    final camel = FriendItem.fromJson({
      'userId': 2,
      'friendId': 3,
      'groupName': 'colleagues',
    });
    expect(camel.groupName, 'colleagues');

    final snake = FriendItem.fromJson({
      'userId': 2,
      'friendId': 3,
      'group_name': 'family',
    });
    expect(snake.groupName, 'family');
  });
}
