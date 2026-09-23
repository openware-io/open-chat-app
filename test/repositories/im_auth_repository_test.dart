import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:open_chat_app/core/local_storage.dart';
import 'package:open_chat_app/repositories/im_auth_repository.dart';
import 'package:open_chat_app/services/api_client.dart';
import 'package:open_chat_app/services/im_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registration clears any session and ignores returned credentials',
      () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = LocalStorage(preferences);
    await storage.setToken('old-token');
    await storage.setUserJson(const {'id': 1, 'username': 'old-user'});

    final apiClient = ApiClient(storage);
    String? authorizationHeader;
    apiClient.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          authorizationHeader = options.headers['Authorization']?.toString();
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: const {
                'accessToken': 'new-token',
                'user': {'id': 2, 'username': 'new-user'},
              },
            ),
          );
        },
      ),
    );
    final repository = ImAuthRepository(
      storage,
      ImApi(apiClient),
      apiClient,
    );

    await repository.register(
      username: 'new-user',
      password: 'password',
      email: 'new-user@example.com',
      nickname: '',
    );

    expect(authorizationHeader, isNull);
    expect(storage.token, isNull);
    expect(storage.userJson, isNull);
  });
}
