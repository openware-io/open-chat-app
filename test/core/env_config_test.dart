import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/config.dart';
import 'package:open_chat_app/core/env_config.dart';

void main() {
  tearDown(() => EnvConfig.applyRuntimeApiBase(null));

  test('runtime server override drives every endpoint for one launch', () {
    EnvConfig.applyRuntimeApiBase('http://192.168.3.35:30080/');

    expect(AppConfig.apiBase, 'http://192.168.3.35:30080');
    expect(AppConfig.apiPrefix, 'http://192.168.3.35:30080/api/v1');
    expect(AppConfig.wsUri, 'ws://192.168.3.35:30080/ws/im/v1');
    expect(AppConfig.mediaBase, 'http://192.168.3.35:30080');
    expect(AppConfig.serviceBase, 'http://192.168.3.35:30080');
  });

  test('runtime server override is cleared back to compiled defaults', () {
    const compiled = EnvConfig.defaultApiBase;
    EnvConfig.applyRuntimeApiBase('https://example.test');
    expect(AppConfig.apiBase, 'https://example.test');

    EnvConfig.applyRuntimeApiBase(null);
    expect(AppConfig.apiBase, compiled);
  });
}
