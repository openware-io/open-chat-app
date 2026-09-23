import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/models/im_user.dart';
import 'package:open_chat_app/providers/auth_provider.dart';
import 'package:open_chat_app/repositories/auth_repository.dart';
import 'package:open_core/open_core.dart' show GvSocketClient;

void main() {
  test('login refreshes and exposes the complete user profile', () async {
    final repository = _FakeAuthRepository();
    final socket = _RecordingSocket();
    final provider = AuthProvider(repository, socket);

    await provider.login('xch1400', 'password');

    expect(repository.fetchProfileCalls, 1);
    expect(provider.user?.email, 'xch1400@example.com');
    expect(socket.connectedToken, 'token');
  });

  test('registration creates the account without authenticating', () async {
    final repository = _FakeAuthRepository();
    final socket = _RecordingSocket();
    final provider = AuthProvider(repository, socket);
    var authenticatedChangedCalls = 0;
    provider.onAuthenticatedChanged = () => authenticatedChangedCalls++;

    await provider.register('xch1400', 'password', 'xch1400@example.com', '');

    expect(repository.registerCalls, 1);
    expect(repository.fetchProfileCalls, 0);
    expect(provider.user, isNull);
    expect(socket.connectedToken, isNull);
    expect(authenticatedChangedCalls, 0);
  });

  test('profile refresh failure does not turn login into a failure', () async {
    final repository = _FakeAuthRepository()
      ..profileError = StateError('offline');
    final socket = _RecordingSocket();
    final provider = AuthProvider(repository, socket);

    await expectLater(
      provider.login('xch1400', 'password'),
      completes,
    );

    expect(provider.user?.username, 'xch1400');
    expect(provider.user?.email, isNull);
    expect(socket.connectedToken, 'token');
  });
}

class _FakeAuthRepository implements AuthRepository {
  int fetchProfileCalls = 0;
  int registerCalls = 0;
  Object? profileError;

  @override
  Future<AuthenticatedSession> login({
    required String username,
    required String password,
  }) async {
    return AuthenticatedSession(
      token: 'token',
      user: ImUser(id: 1400, username: username),
    );
  }

  @override
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String nickname,
  }) async {
    registerCalls++;
  }

  @override
  Future<ImUser> fetchProfile() async {
    fetchProfileCalls++;
    final error = profileError;
    if (error != null) throw error;
    return const ImUser(
      id: 1400,
      username: 'xch1400',
      email: 'xch1400@example.com',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingSocket implements GvSocketClient {
  String? connectedToken;

  @override
  void connect(String token) => connectedToken = token;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
