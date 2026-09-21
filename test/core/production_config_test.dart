import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/config.dart';

/// 发布制品守卫：只在**发布构建的 dart-define 上下文**里成立。
///
/// `EnvConfig` 按 `APP_ENV` 选择环境（默认 `dev`）。裸跑 `flutter test` 时
/// App 处于 dev 环境，本用例的断言（要求 `prod` + 线上网关地址）必然不成立。
/// 因此发版门禁必须带 define 运行：
///
/// ```
/// flutter test --dart-define=APP_ENV=prod
/// ```
///
/// 未带 define 时**跳过并给出原因**，而不是留下一条会误导人的红灯
/// （本地/CI 的裸 `flutter test` 仍然全绿）。
const String _appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

void main() {
  test('production endpoints match the deployed v1 gateway contract', () {
    expect(AppConfig.appEnv, 'prod');
    expect(
      AppConfig.apiPrefix,
      'https://api.dev.example.com/api/v1',
    );
    expect(
      AppConfig.socketUri,
      'wss://api.dev.example.com/ws/im/v1',
    );
  }, skip: _appEnv == 'prod' ? false : '需要 --dart-define=APP_ENV=prod（发布制品守卫）');
}
