enum AppEnvironment {
  dev,
  test,
  prod;

  static const rawName = String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  static AppEnvironment get current {
    switch (rawName) {
      case 'prod':
        return AppEnvironment.prod;
      case 'test':
      case 'staging':
        return AppEnvironment.test;
      case 'dev':
      default:
        return AppEnvironment.dev;
    }
  }

  static const bool isProduction = rawName == 'prod';
}
