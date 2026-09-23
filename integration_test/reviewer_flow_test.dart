import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:open_chat_app/core/open_automation_keys.dart';
import 'package:open_chat_app/main.dart' as app;
import 'package:open_chat_app/screens/chat_room/chat_room_message_tile.dart';
import 'package:integration_test/integration_test.dart';

const _config = _ReviewerFlowConfig();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    '机审核心流程：登录、打开会话、输入消息并可选发送后本地删除',
    (tester) async {
      _step('启动应用');
      await app.main();

      await _waitForAny(
        tester,
        const [
          GvAutomationKeys.loginScreen,
          GvAutomationKeys.chatListScreen,
        ],
        timeout: const Duration(seconds: 35),
      );

      if (find.byKey(GvAutomationKeys.loginScreen).evaluate().isNotEmpty) {
        _step('输入测试账号并点击登录');
        expect(
          _config.hasCredentials,
          isTrue,
          reason: '应用当前未登录，请传入 OPEN_TEST_USERNAME 和 OPEN_TEST_PASSWORD。',
        );
        await tester.enterText(
          find.byKey(GvAutomationKeys.loginUsername),
          _config.username,
        );
        await tester.enterText(
          find.byKey(GvAutomationKeys.loginPassword),
          _config.password,
        );
        await tester.tap(find.byKey(GvAutomationKeys.loginAgreement));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.byKey(GvAutomationKeys.loginSubmit));
        await _waitForKey(
          tester,
          GvAutomationKeys.chatListScreen,
          timeout: const Duration(seconds: 40),
          reason: '登录后未进入消息列表，请检查测试账号、网络和服务端地址。',
        );
      } else {
        _step('复用当前登录状态');
      }

      await _dismissAnnouncementIfPresent(tester);

      if (_config.conversationName.isNotEmpty) {
        _step('搜索目标会话：${_config.conversationName}');
        final searchField = find.descendant(
          of: find.byKey(GvAutomationKeys.chatListSearch),
          matching: find.byType(TextField),
        );
        await tester.enterText(searchField, _config.conversationName);
        await tester.pump(const Duration(milliseconds: 800));
      } else {
        _step('等待目标会话加载');
      }

      final conversation = _conversationFinder();
      await _waitForConversation(
        tester,
        conversation,
        timeout: const Duration(seconds: 30),
        reason: '没有找到目标会话。请确认会话名称，或传入正确的 '
            'OPEN_TEST_CHAT_TYPE 和 OPEN_TEST_PEER_ID。',
      );

      _step('点击进入目标会话');
      await tester.ensureVisible(conversation.first);
      await tester.tap(conversation.first);
      await _waitForKey(
        tester,
        GvAutomationKeys.chatRoomScreen,
        timeout: const Duration(seconds: 25),
        reason: '点击会话后未进入聊天室。',
      );

      final message = _config.messagePrefix.isEmpty
          ? 'GV机审测试 ${DateTime.now().millisecondsSinceEpoch}'
          : '${_config.messagePrefix} ${DateTime.now().millisecondsSinceEpoch}';

      _step('在聊天输入框输入测试文字');
      final composer = find.byKey(GvAutomationKeys.chatComposerInput);
      await _waitForFinder(
        tester,
        composer,
        timeout: const Duration(seconds: 20),
        reason: '聊天室输入框未出现。',
      );
      await tester.enterText(composer, message);
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        tester.widget<TextField>(composer).controller?.text,
        message,
      );

      if (!_config.allowSend) {
        _step('安全模式：已验证输入，未向服务端发送');
        await tester.enterText(composer, '');
        return;
      }

      _step('点击发送测试消息');
      final sendButton = find.byKey(GvAutomationKeys.chatComposerSend);
      await _waitForFinder(
        tester,
        sendButton,
        timeout: const Duration(seconds: 5),
        reason: '输入文字后发送按钮未出现。',
      );
      await tester.tap(sendButton);
      await tester.pump(const Duration(milliseconds: 500));

      final sentMessage = _messageFinder(message);
      await _waitForFinder(
        tester,
        sentMessage,
        timeout: const Duration(seconds: 12),
        reason: '点击发送后，消息没有出现在当前聊天室。',
      );

      _step('长按刚发送的消息');
      final messageGestures = find.descendant(
        of: sentMessage,
        matching: find.byType(GestureDetector),
      );
      expect(messageGestures, findsWidgets);
      await tester.longPress(messageGestures.first);
      await _waitForKey(
        tester,
        GvAutomationKeys.messageDeleteMenu,
        timeout: const Duration(seconds: 5),
        reason: '长按消息后没有出现操作菜单。',
      );

      _step('选择删除并确认仅从本机移除');
      await tester.tap(find.byKey(GvAutomationKeys.messageDeleteMenu));
      await _waitForKey(
        tester,
        GvAutomationKeys.messageDeleteConfirm,
        timeout: const Duration(seconds: 5),
        reason: '选择删除后没有出现确认弹窗。',
      );
      await tester.tap(find.byKey(GvAutomationKeys.messageDeleteConfirm));
      await _waitUntilAbsent(
        tester,
        sentMessage,
        timeout: const Duration(seconds: 8),
        reason: '确认删除后，测试消息仍显示在本机聊天记录中。',
      );
      _step('核心机审流程完成');
    },
    skip: !_config.hasTarget,
  );
}

Finder _conversationFinder() {
  if (_config.peerId.isNotEmpty) {
    return find.byKey(
      GvAutomationKeys.conversation(_config.chatType, _config.peerId),
    );
  }
  return find.ancestor(
    of: find.text(_config.conversationName),
    matching: find.byType(Slidable),
  );
}

Finder _messageFinder(String content) => find.byWidgetPredicate(
      (widget) =>
          widget is ChatRoomMessageTile &&
          widget.msg.msgType == 'text' &&
          widget.msg.content == content,
      description: 'text message "$content"',
    );

Future<void> _dismissAnnouncementIfPresent(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 600));
  final dialog = find.byType(AlertDialog);
  if (dialog.evaluate().isEmpty) return;
  final buttons = find.descendant(
    of: dialog,
    matching: find.byType(TextButton),
  );
  if (buttons.evaluate().isEmpty) return;
  _step('关闭登录后的公告弹窗');
  await tester.tap(buttons.last);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _waitForAny(
  WidgetTester tester,
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

Future<void> _waitForKey(
  WidgetTester tester,
  Key key, {
  required Duration timeout,
  required String reason,
}) =>
    _waitForFinder(
      tester,
      find.byKey(key),
      timeout: timeout,
      reason: reason,
    );

Future<void> _waitForFinder(
  WidgetTester tester,
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

Future<void> _waitForConversation(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  required String reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
    final lists = find.descendant(
      of: find.byKey(GvAutomationKeys.chatListScreen),
      matching: find.byType(ListView),
    );
    if (lists.evaluate().isNotEmpty) {
      await tester.drag(lists.last, const Offset(0, -320));
    }
  }
  expect(finder, findsWidgets, reason: reason);
}

Future<void> _waitUntilAbsent(
  WidgetTester tester,
  Finder finder, {
  required Duration timeout,
  required String reason,
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isEmpty) return;
  }
  expect(finder, findsNothing, reason: reason);
}

void _step(String message) => debugPrint('[OPEN_STEP] $message');

class _ReviewerFlowConfig {
  const _ReviewerFlowConfig();

  final String username = const String.fromEnvironment('OPEN_TEST_USERNAME');
  final String password = const String.fromEnvironment('OPEN_TEST_PASSWORD');
  final String conversationName =
      const String.fromEnvironment('OPEN_TEST_CONVERSATION_NAME');
  final String chatType = const String.fromEnvironment(
    'OPEN_TEST_CHAT_TYPE',
    defaultValue: 'group',
  );
  final String peerId = const String.fromEnvironment('OPEN_TEST_PEER_ID');
  final String messagePrefix = const String.fromEnvironment(
    'OPEN_TEST_MESSAGE_PREFIX',
    defaultValue: 'GV机审测试',
  );
  final bool allowSend = const bool.fromEnvironment(
    'OPEN_TEST_ALLOW_SEND',
    defaultValue: false,
  );

  bool get hasCredentials => username.isNotEmpty && password.isNotEmpty;
  bool get hasTarget => conversationName.isNotEmpty || peerId.isNotEmpty;
}
