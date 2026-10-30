import 'app_environment.dart';

class EnvConfig {
  EnvConfig._();

  static const appEnv = AppEnvironment.rawName;

  /// Debug-only shared preference key for the local server override.
  static const runtimeApiBaseKey = 'dev_api_base_override';

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

  static String? _runtimeApiBase;

  /// Debug-only, persisted server override. The value is applied before the
  /// dependency graph is created, so every client sees the same origin.
  static String? get runtimeApiBase => _runtimeApiBase;

  static String get apiBase =>
      _runtimeApiBase ?? (_apiBaseOverride == '' ? defaultApiBase : _apiBaseOverride);

  /// Origin used to resolve relative service-board links.
  ///
  /// Local Kind serves `/c/` through the same ingress as the API, while
  /// production keeps the SaaS H5 on its own host. `OPEN_SERVICE_BASE` can
  /// override this independently from the API origin.
  static const _prodServiceBase = 'https://miniservice.dev.example.com';
  static const _testServiceBase = 'https://test-miniservice.example.com';
  static String get serviceBase {
    if (_runtimeApiBase != null) return _runtimeApiBase!;
    if (_serviceBaseOverride.isNotEmpty) return _serviceBaseOverride;
    if (appEnv == 'prod') return _prodServiceBase;
    if (appEnv == 'test') return _testServiceBase;
    return apiBase;
  }

  static String get wsUri {
    if (_runtimeApiBase != null) {
      final scheme = _runtimeApiBase!.startsWith('https://') ? 'wss' : 'ws';
      final host = _runtimeApiBase!.replaceFirst(RegExp(r'^https?://'), '');
      return '$scheme://$host/ws/im/v1';
    }
    return _wsUriOverride == '' ? defaultWsUri : _wsUriOverride;
  }

  static String get mediaBase =>
      _runtimeApiBase ??
      (_mediaBaseOverride == '' ? defaultMediaBase : _mediaBaseOverride);

  /// Applies a runtime API origin. Callers must persist it separately and
  /// restart the app; existing Dio clients are not hot-reconfigured.
  static void applyRuntimeApiBase(String? value) {
    final normalized = value?.trim().replaceFirst(RegExp(r'/+$'), '');
    _runtimeApiBase =
        normalized == null || normalized.isEmpty ? null : normalized;
  }

  static const isProduction = appEnv == 'prod';

  static const jpushProduction = _jpushProductionOverride == ''
      ? isProduction
      : _jpushProductionOverride == 'true';
}
