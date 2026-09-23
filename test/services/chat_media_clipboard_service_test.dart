import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/services/chat_media_clipboard_service.dart';

void main() {
  group('GvChatMediaClipboardService path classification', () {
    test('recognizes supported image clipboard files', () {
      expect(
        GvChatMediaClipboardService.isImageFilePath(r'C:\Temp\photo.PNG'),
        isTrue,
      );
      expect(
        GvChatMediaClipboardService.isImageFilePath(
          'file:///tmp/photo.webp?cache=1',
        ),
        isTrue,
      );
      expect(
        GvChatMediaClipboardService.isImageFilePath('/tmp/video.mp4'),
        isFalse,
      );
    });

    test('recognizes supported video clipboard files', () {
      expect(
        GvChatMediaClipboardService.isVideoFilePath(r'C:\Temp\clip.MP4'),
        isTrue,
      );
      expect(
        GvChatMediaClipboardService.isVideoFilePath(
          'file:///tmp/clip.mov?download=1',
        ),
        isTrue,
      );
      expect(
        GvChatMediaClipboardService.isVideoFilePath('/tmp/photo.jpg'),
        isFalse,
      );
    });
  });
}
