import 'app_environment.dart';

class EnvConfig {
  EnvConfig._();

  static const appEnv = AppEnvironment.rawName;

  static const _apiBaseOverride =
      String.fromEnvironment('OPEN_API_BASE', defaultValue: '');

  static const _wsUriOverride =
      String.fromEnvironment('OPEN_WS_URI', defaultValue: '');

  static const _mediaBaseOverride =
      String.fromEnvironment('OPEN_MEDIA_BASE', defaultValue: '');
  static const _serviceBaseOverride =
      String.fromEnvironment('OPEN_SERVICE_BASE', defaultValue: '');
  static const _jpushProductionOverride =
      String.fromEnvironment('OPEN_JPUSH_PRODUCTION', defaultValue: '');

  static const defaultApiBase = appEnv == 'prod'
      ? 'https://api.dev.example.com'
      : appEnv == 'test'
          ? 'https://test-api.example.com'
          : 'http://192.168.1.3:3002';

  static const defaultWsUri = appEnv == 'prod'
      ? 'wss://api.dev.example.com/ws/im/v1'
      : appEnv == 'test'
          ? 'wss://test-api.example.com/ws/im/v1'
          : 'ws://192.168.1.3:3002/ws/im/v1';

  static const defaultMediaBase = appEnv == 'prod'
      ? 'https://api.dev.example.com'
      : appEnv == 'test'
          ? 'https://test-media.example.com'
          : 'http://192.168.1.3:9000';

  static const apiBase =
      _apiBaseOverride == '' ? defaultApiBase : _apiBaseOverride;

  /// Origin used to resolve relative service-board links.
  ///
  /// Local Kind serves `/c/` through the same ingress as the API, while
  /// production keeps the SaaS H5 on its own host. `OPEN_SERVICE_BASE` can
  /// override this independently from the API origin.
  static const _prodServiceBase = 'https://miniservice.dev.example.com';
  static const _testServiceBase = 'https://test-miniservice.example.com';
  static String get serviceBase {
    if (_serviceBaseOverride.isNotEmpty) return _serviceBaseOverride;
    if (appEnv == 'prod') return _prodServiceBase;
    if (appEnv == 'test') return _testServiceBase;
    return apiBase;
  }

  static const wsUri = _wsUriOverride == '' ? defaultWsUri : _wsUriOverride;

  static const mediaBase =
      _mediaBaseOverride == '' ? defaultMediaBase : _mediaBaseOverride;
  static const isProduction = appEnv == 'prod';

  static const jpushProduction = _jpushProductionOverride == ''
      ? isProduction
      : _jpushProductionOverride == 'true';
}
