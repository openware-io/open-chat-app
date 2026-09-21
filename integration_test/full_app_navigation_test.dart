import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/gv_automation_keys.dart';
import 'package:gv_chat_app/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'support/gv_e2e_driver.dart';

const _config = GvE2eConfig();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('全功能安全巡检：主导航、功能入口、表单与业务列表', (tester) async {
    final driver = GvE2eDriver(tester);
    driver.step('启动应用并确保已登录');
    await app.main();
    await driver.authenticateIfNeeded(_config);

    await _verifyMessageEntries(driver);
    await _verifyContacts(driver);
    await _verifyServices(driver);
    await _verifyProfileAndSettings(driver);

    driver.step('巡检完成：返回消息首页');
    await driver.tapKey(GvAutomationKeys.tabMessages);
    await driver.waitForKey(
      GvAutomationKeys.chatListScreen,
      timeout: const Duration(seconds: 12),
      reason: '巡检结束时无法返回消息首页。',
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _verifyMessageEntries(GvE2eDriver driver) async {
  driver.step('消息：验证添加好友入口');
  await driver.tapKey(GvAutomationKeys.chatListAdd);
  await driver.tapKey(GvAutomationKeys.chatListAddFriend);
  await driver.waitForKey(
    GvAutomationKeys.addFriendScreen,
    timeout: const Duration(seconds: 12),
    reason: '从消息页无法打开添加好友页面。',
  );
  await driver.backTo(GvAutomationKeys.chatListScreen);

  await _verifyOptionalMessageDialog(
    driver,
    menuKey: GvAutomationKeys.chatListCreateChannel,
    dialogFieldKey: GvAutomationKeys.channelNameField,
    label: '频道：打开创建频道表单（不提交）',
  );
  await _verifyOptionalMessageDialog(
    driver,
    menuKey: GvAutomationKeys.chatListSearchChannel,
    dialogFieldKey: GvAutomationKeys.channelSearchField,
    label: '频道：打开频道搜索表单（不订阅）',
  );
  await _verifyOptionalMessageDialog(
    driver,
    menuKey: GvAutomationKeys.chatListJoinChannel,
    dialogFieldKey: GvAutomationKeys.channelJoinCodeField,
    label: '频道：打开频道号订阅表单（不订阅）',
  );

  if (_config.allowCamera) {
    driver.step('扫码：打开真实相机扫码页');
    await driver.tapKey(GvAutomationKeys.chatListAdd);
    await driver.tapKey(GvAutomationKeys.chatListScan);
    await driver.waitForKey(
      GvAutomationKeys.scanScreen,
      timeout: const Duration(seconds: 15),
      reason: '无法打开扫码页面。',
    );
    await driver.backTo(GvAutomationKeys.chatListScreen);
  } else {
    driver.step('扫码：跳过相机授权（传 GV_TEST_ALLOW_CAMERA=true 可开启）');
  }
}

Future<void> _verifyOptionalMessageDialog(
  GvE2eDriver driver, {
  required Key menuKey,
  required Key dialogFieldKey,
  required String label,
}) async {
  driver.step(label);
  await driver.tapKey(GvAutomationKeys.chatListAdd);
  if (!await driver.hasKey(menuKey)) {
    driver.step('$label：服务端功能开关未启用，已跳过');
    await driver.closeOverlay();
    return;
  }
  await driver.tapKey(menuKey);
  await driver.waitForKey(
    dialogFieldKey,
    timeout: const Duration(seconds: 8),
    reason: '$label：弹窗没有出现。',
  );
  await driver.closeOverlay();
}

Future<void> _verifyContacts(GvE2eDriver driver) async {
  driver.step('通讯录：切换 Tab 并验证搜索');
  await driver.tapKey(GvAutomationKeys.tabContacts);
  await driver.waitForKey(
    GvAutomationKeys.contactsScreen,
    timeout: const Duration(seconds: 15),
    reason: '无法打开通讯录页面。',
  );
  final search = find.descendant(
    of: find.byKey(GvAutomationKeys.contactsSearch),
    matching: find.byType(TextField),
  );
  await driver.waitForFinder(
    search,
    timeout: const Duration(seconds: 8),
    reason: '通讯录搜索框没有出现。',
  );
  await driver.tester.enterText(search, '__gv_e2e_no_match__');
  await driver.tester.pump(const Duration(milliseconds: 500));
  await driver.tester.enterText(search, '');
  await driver.tester.pump(const Duration(milliseconds: 350));

  driver.step('通讯录：打开新的朋友列表');
  await driver.tapKey(GvAutomationKeys.contactsFriendRequests);
  await driver.waitForKey(
    GvAutomationKeys.friendRequestsScreen,
    timeout: const Duration(seconds: 12),
    reason: '无法打开新的朋友列表。',
  );
  await driver.backTo(GvAutomationKeys.contactsScreen);

  if (await driver.hasKey(GvAutomationKeys.contactsCreateGroup)) {
    driver.step('通讯录：打开创建群聊页面（不创建）');
    await driver.tapKey(GvAutomationKeys.contactsCreateGroup);
    await driver.waitForKey(
      GvAutomationKeys.createGroupScreen,
      timeout: const Duration(seconds: 12),
      reason: '无法打开创建群聊页面。',
    );
    await driver.backTo(GvAutomationKeys.contactsScreen);
  } else {
    driver.step('群聊：服务端功能开关未启用，已跳过创建页');
  }

  driver.step('通讯录：打开添加好友页面（不发送申请）');
  await driver.tapKey(GvAutomationKeys.contactsAddFriend);
  await driver.waitForKey(
    GvAutomationKeys.addFriendScreen,
    timeout: const Duration(seconds: 12),
    reason: '无法从通讯录打开添加好友页面。',
  );
  await driver.backTo(GvAutomationKeys.contactsScreen);
}

Future<void> _verifyServices(GvE2eDriver driver) async {
  driver.step('服务：切换 Tab 并验证积分明细');
  await driver.tapKey(GvAutomationKeys.tabServices);
  await driver.waitForKey(
    GvAutomationKeys.servicesScreen,
    timeout: const Duration(seconds: 15),
    reason: '无法打开服务页面。',
  );

  final service = find.text('A380 更多服务');
  final serviceDeadline = DateTime.now().add(const Duration(seconds: 12));
  while (service.evaluate().isEmpty && DateTime.now().isBefore(serviceDeadline)) {
    await driver.tester.pump(const Duration(milliseconds: 250));
  }
  if (service.evaluate().isNotEmpty) {
    driver.step('服务：打开真实 A380 H5 并等待 Bridge 初始化');
    await driver.tester.tap(service.first);
    await driver.waitForKey(
      GvAutomationKeys.protocolWebViewScreen,
      timeout: const Duration(seconds: 15),
      reason: '真实 H5 WebView 没有打开。',
    );
    await driver.tester.pump(const Duration(seconds: 8));
    expect(driver.tester.takeException(), isNull);
    await driver.backTo(GvAutomationKeys.servicesScreen);
  } else {
    driver.step('服务：A380 H5 服务未在目录返回，跳过真实 Bridge 入口');
  }
}

Future<void> _verifyProfileAndSettings(GvE2eDriver driver) async {
  driver.step('我的：切换 Tab 并打开个人二维码');
  await driver.tapKey(GvAutomationKeys.tabProfile);
  await driver.waitForKey(
    GvAutomationKeys.profileScreen,
    timeout: const Duration(seconds: 15),
    reason: '无法打开“我的”页面。',
  );
  await driver.tapKey(GvAutomationKeys.profileQrCode);
  await driver.waitForKey(
    GvAutomationKeys.profileQrDialog,
    timeout: const Duration(seconds: 10),
    reason: '个人二维码弹窗没有出现。',
  );
  await driver.tapKey(GvAutomationKeys.profileQrClose);
  expect(find.byKey(GvAutomationKeys.profileFavorites), findsOneWidget);

  driver.step('设置：打开设置首页');
  await driver.tapKey(GvAutomationKeys.profileSettings);
  await driver.waitForKey(
    GvAutomationKeys.settingsScreen,
    timeout: const Duration(seconds: 12),
    reason: '无法打开设置页面。',
  );

  driver.step('设置：打开个人资料表单（不保存）');
  await driver.tapKey(GvAutomationKeys.settingsProfile);
  await driver.waitForKey(
    GvAutomationKeys.profileEditScreen,
    timeout: const Duration(seconds: 12),
    reason: '无法打开个人资料编辑页面。',
  );
  await driver.backTo(GvAutomationKeys.settingsScreen);

  driver.step('设置：打开修改密码表单（不提交）');
  await driver.tapKey(GvAutomationKeys.settingsPassword);
  await driver.waitForKey(
    GvAutomationKeys.changePasswordScreen,
    timeout: const Duration(seconds: 12),
    reason: '无法打开修改密码页面。',
  );
  await driver.backTo(GvAutomationKeys.settingsScreen);

  if (await driver.hasKey(GvAutomationKeys.settingsNotifications)) {
    driver.step('设置：打开通知详情（不修改开关）');
    await driver.tapKey(GvAutomationKeys.settingsNotifications);
    await driver.waitForKey(
      GvAutomationKeys.notificationSettingsScreen,
      timeout: const Duration(seconds: 12),
      reason: '无法打开通知设置页面。',
    );
    await driver.backTo(GvAutomationKeys.settingsScreen);
  } else {
    driver.step('通知设置：当前平台不支持，已跳过');
  }

  driver.step('设置：打开外观选择并取消');
  await driver.tapKey(GvAutomationKeys.settingsAppearance);
  await driver.closeOverlay();
  driver.step('设置：打开语言选择并取消');
  await driver.tapKey(GvAutomationKeys.settingsLanguage);
  await driver.closeOverlay();

  expect(find.byKey(GvAutomationKeys.settingsLogout), findsOneWidget);
  driver.step('设置：验证退出登录入口存在（不退出）');
  await driver.backTo(GvAutomationKeys.profileScreen);
}
