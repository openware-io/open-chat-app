import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/gv_automation_keys.dart';
import 'package:gv_chat_app/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'support/gv_e2e_driver.dart';

const _config = GvE2eConfig();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('A380 H5 Bridge completes a native OIDC callback',
      (tester) async {
    final driver = GvE2eDriver(tester);
    driver.step('启动应用并使用一次性账号登录');
    await app.main();
    await driver.authenticateIfNeeded(_config);

    driver.step('打开 A380 H5，等待原生 Bridge 完成 OIDC 回调');
    await driver.tapKey(GvAutomationKeys.tabServices);
    await driver.waitForKey(
      GvAutomationKeys.servicesScreen,
      timeout: const Duration(seconds: 15),
      reason: '服务页面未打开。',
    );
    final service = find.text('A380 更多服务');
    await driver.waitForFinder(
      service,
      timeout: const Duration(seconds: 15),
      reason: '服务目录未返回 A380 H5 入口。',
    );
    await tester.tap(service.first);
    await driver.waitForKey(
      GvAutomationKeys.protocolWebViewScreen,
      timeout: const Duration(seconds: 15),
      reason: 'A380 H5 WebView 未打开。',
    );
    await tester.pump(const Duration(seconds: 12));
    expect(tester.takeException(), isNull);

    driver.step('Bridge 回调完成，返回服务目录');
    await driver.backTo(GvAutomationKeys.servicesScreen);
  });
}
