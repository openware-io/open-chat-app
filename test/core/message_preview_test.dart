import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/core/message_preview.dart';

void main() {
  group('previewTextFromContent', () {
    test('normalizes text emoji markup', () {
      expect(
        previewTextFromContent('text', '你好 [emoji]12[/emoji]'),
        '你好 [表情]',
      );
    });

    test('describes common media message types', () {
      expect(previewTextFromContent('image', '/image.jpg'), '[图片]');
      expect(previewTextFromContent('video', '/video.mp4'), '[视频]');
      expect(previewTextFromContent('voice', '/voice.mp3'), '[语音]');
    });

    test('includes an image caption in the conversation preview', () {
      expect(
        previewTextFromContent(
          'image',
          '{"v":1,"url":"/image.jpg","caption":"项目 789"}',
        ),
        '[图片] 项目 789',
      );
    });

    test('extracts a file name from valid JSON', () {
      expect(
        previewTextFromContent('file', '{"name":"release.apk"}'),
        '[文件] release.apk',
      );
    });

    test('falls back safely when file JSON is malformed', () {
      expect(previewTextFromContent('file', 'not-json'), '[文件]');
    });
  });

  group('canRecallMessage', () {
    test('allows the sender to recall a sent message regardless of age', () {
      expect(
        canRecallMessage(
          myId: 7,
          from: 7,
          msgType: 'text',
          status: 'sent',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        isTrue,
      );
    });

    test('rejects foreign, sending, and call messages', () {
      final recent = DateTime.now().subtract(const Duration(seconds: 30));

      expect(
        canRecallMessage(
          myId: 7,
          from: 8,
          msgType: 'text',
          status: 'sent',
          timestamp: recent,
        ),
        isFalse,
      );
      expect(
        canRecallMessage(
          myId: 7,
          from: 7,
          msgType: 'text',
          status: 'sending',
          timestamp: recent,
        ),
        isFalse,
      );
      expect(
        canRecallMessage(
          myId: 7,
          from: 7,
          msgType: 'call',
          status: 'sent',
          timestamp: recent,
        ),
        isFalse,
      );
    });
  });
}
