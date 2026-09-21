import 'package:flutter_test/flutter_test.dart';
import 'package:gv_core/gv_core.dart';

void main() {
  test('maps v1 profile aliases into the stable UI model', () {
    final user = ImUser.fromJson({
      'id': 7,
      'username': 'vvv',
      'nickname': 'VVV',
      'avatarUrl': 'https://media.example.com/avatar.jpg',
      'bio': 'hello',
    });

    expect(user.avatar, 'https://media.example.com/avatar.jpg');
    expect(user.signature, 'hello');
    expect(user.displayName, 'VVV');
  });
}
