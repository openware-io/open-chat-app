import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/local_storage.dart';
import 'package:open_chat_app/repositories/local_app_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('notifications default to enabled for existing installations', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = LocalAppPreferencesRepository(
      LocalStorage(await SharedPreferences.getInstance()),
    );

    expect(preferences.notificationsEnabled, isTrue);
  });

  test('notification preference is persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = LocalAppPreferencesRepository(
      LocalStorage(await SharedPreferences.getInstance()),
    );

    await preferences.setNotificationsEnabled(false);

    expect(preferences.notificationsEnabled, isFalse);
  });
}
