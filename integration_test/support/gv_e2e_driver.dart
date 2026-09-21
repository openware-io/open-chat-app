import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/gv_automation_keys.dart';

class GvE2eConfig {
  const GvE2eConfig();

  final String username = const String.fromEnvironment('GV_TEST_USERNAME');
  final String password = const String.fromEnvironment('GV_TEST_PASSWORD');
  final bool allowCamera = const bool.fromEnvironment(
    'GV_TEST_ALLOW_CAMERA',
    defaultValue: false,
  );

  bool get hasCredentials => username.isNotEmpty && password.isNotEmpty;
}

class GvE2eDriver {
  GvE2eDriver(this.tester);

  final WidgetTester tester;

  void step(String message) => debugPrint('[GV_STEP] $message');

  Future<void> authenticateIfNeeded(GvE2eConfig config) async {
    await waitForAny(
      const [
        GvAutomationKeys.loginScreen,
        GvAutomationKeys.chatListScreen,
      ],
      timeout: const Duration(seconds: 40),
    );

    if (find.byKey(GvAutomationKeys.loginScreen).evaluate().isEmpty) {
      step('登录：复用设备中的现有登录状态');
      await dismissAnnouncementIfPresent();
      return;
    }

    step('登录：输入测试账号并提交');
    expect(
      config.hasCredentials,
      isTrue,
      reason: '设备当前未登录，请传入 GV_TEST_USERNAME 和 GV_TEST_PASSWORD。',
    );
    await tester.enterText(
      find.byKey(GvAutomationKeys.loginUsername),
      config.username,
    );
    await tester.enterText(
      find.byKey(GvAutomationKeys.loginPassword),
      config.password,
    );
    await tester.tap(find.byKey(GvAutomationKeys.loginAgreement));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.byKey(GvAutomationKeys.loginSubmit));
    await waitForKey(
      GvAutomationKeys.chatListScreen,
      timeout: const Duration(seconds: 45),
      reason: '登录后没有进入消息列表，请检查账号、网络和后端地址。',
    );
    await dismissAnnouncementIfPresent();
  }

  Future<void> dismissAnnouncementIfPresent() async {
    await tester.pump(const Duration(milliseconds: 700));
    final dialog = find.byType(AlertDialog);
    if (dialog.evaluate().isEmpty) return;
    final buttons = find.descendant(
      of: dialog,
      matching: find.byType(TextButton),
    );
    if (buttons.evaluate().isEmpty) return;
    step('启动：关闭公告弹窗');
    await tester.tap(buttons.last);
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tapKey(
    Key key, {
    Duration timeout = const Duration(seconds: 12),
    String? reason,
  }) async {
    final finder = find.byKey(key);
    await waitForFinder(
      finder,
      timeout: timeout,
      reason: reason ?? '没有找到可点击控件：$key',
    );
    await tester.ensureVisible(finder);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.tap(finder);
    await tester.pump(const Duration(milliseconds: 450));
  }

  Future<bool> hasKey(
    Key key, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byKey(key).evaluate().isNotEmpty) return true;
    }
    return false;
  }

  Future<void> backTo(
    Key key, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 450));
    await waitForKey(
      key,
      timeout: timeout,
      reason: '返回后没有出现目标页面：$key',
    );
  }

  Future<void> closeOverlay() async {
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 450));
  }

  Future<void> waitForAny(
    List<Key> keys, {
    required Duration timeout,
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (keys.any((key) => find.byKey(key).evaluate().isNotEmpty)) return;
    }
    fail('等待页面超时：${keys.join(', ')}');
  }

  Future<void> waitForKey(
    Key key, {
    required Duration timeout,
    required String reason,
  }) =>
      waitForFinder(
        find.byKey(key),
        timeout: timeout,
        reason: reason,
      );

  Future<void> waitForFinder(
    Finder finder, {
    required Duration timeout,
    required String reason,
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return;
    }
    expect(finder, findsWidgets, reason: reason);
  }
}
