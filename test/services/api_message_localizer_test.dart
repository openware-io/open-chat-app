import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/services/api_message_localizer.dart';

void main() {
  group('localizeServerMessage', () {
    tearDown(() => setApiMessageZhLocale(true));

    test('中文界面：服务端英文文案被翻译', () {
      setApiMessageZhLocale(true);
      expect(localizeServerMessage('New password must differ from the current password'),
          '新密码不能与当前密码相同');
      expect(localizeServerMessage('Password incorrect'), '当前密码错误');
      expect(localizeServerMessage('Not friends'), '对方不是你的好友');
      expect(localizeServerMessage('Chat deletion is disabled'), '聊天删除功能已关闭');
      expect(localizeServerMessage('Username already exists'), '用户名已存在');
    });

    test('英文界面：英文文案保持英文，不会被翻成中文', () {
      setApiMessageZhLocale(false);
      expect(localizeServerMessage('New password must differ from the current password'),
          'New password must differ from the current password');
      expect(localizeServerMessage('Password incorrect'), 'Password incorrect');
      expect(localizeServerMessage('Not friends'), 'Not friends');
    });

    test('英文界面：服务端历史硬编码中文被反查为英文（避免中英混排）', () {
      setApiMessageZhLocale(false);
      expect(localizeServerMessage('头像仅支持上传图片文件'),
          'Avatar only supports image files');
      expect(localizeServerMessage('已禁用添加群成员为好友'),
          'Adding group members as friends is disabled');
    });

    test('中文界面：服务端历史硬编码中文保持不变', () {
      setApiMessageZhLocale(true);
      expect(localizeServerMessage('头像仅支持上传图片文件'), '头像仅支持上传图片文件');
    });

    test('未收录文案原样返回（不误翻译）', () {
      setApiMessageZhLocale(true);
      expect(localizeServerMessage('Some brand new server message'),
          'Some brand new server message');
      setApiMessageZhLocale(false);
      expect(localizeServerMessage('Some brand new server message'),
          'Some brand new server message');
    });
  });
}
