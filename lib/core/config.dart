import 'env_config.dart';

/// REST base URL without a trailing slash, the native WebSocket endpoint,
/// and managed media configuration.
///
/// Select the app environment with `--dart-define=APP_ENV=dev|test|prod`.
/// Override each endpoint through managed build parameters, e.g.:
/// `flutter run --dart-define=OPEN_API_BASE=http://10.0.2.2:3002
/// --dart-define=OPEN_WS_URI=ws://10.0.2.2:3002/ws/im/v1
/// --dart-define=OPEN_MEDIA_BASE=http://10.0.2.2:9000`
/// (Android emulator → host machine).
///
/// 若媒体地址为 **同机 HTTPS 自签名**（如 Vite `https://IP:5173/uploads/...`），
/// Debug 下会对与 [apiBase] **相同 host** 自动放行证书校验。
/// Profile/Release 连内网 HTTPS 时请加上：
/// `--dart-define=OPEN_TRUST_SELF_SIGNED=true`（仅建议内测使用）。
class AppConfig {
  AppConfig._();

  static const String appEnv = EnvConfig.appEnv;

  static const String apiBase = EnvConfig.apiBase;

  static String get apiPrefix {
    final normalized = apiBase.endsWith('/')
        ? apiBase.substring(0, apiBase.length - 1)
        : apiBase;
    return '$normalized/api/v1';
  }

  static const String wsUri = EnvConfig.wsUri;

  static const String socketUri = EnvConfig.wsUri;

  static const String mediaBase = EnvConfig.mediaBase;

  /// 极光：`flutter run --dart-define=OPEN_JPUSH_APPKEY=...`。
  /// Android 需与 `android/local.properties` 的 `jpush.appKey` 保持一致；
  /// iOS 需与极光控制台中该 Bundle ID 绑定的应用 AppKey 保持一致。
  static const String jpushDartAppKey =
      String.fromEnvironment('OPEN_JPUSH_APPKEY', defaultValue: '');

  /// Android 默认使用极光（包含已配置的 FCM 厂商通道）接收后台消息。
  /// 本地调试如需使用 WebSocket 前台保活回退，可显式传入
  /// `--dart-define=OPEN_ANDROID_JPUSH_ENABLED=false`。
  static const bool androidJPushEnabled = bool.fromEnvironment(
    'OPEN_ANDROID_JPUSH_ENABLED',
    defaultValue: true,
  );

  /// 默认 prod 为 true，dev/test 为 false；也可用 `OPEN_JPUSH_PRODUCTION` 显式覆盖。
  static const bool jpushProductionDart = EnvConfig.jpushProduction;
}
