import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/upload_mime.dart';

void main() {
  test('maps supported voice extensions to their real MIME types', () {
    expect(uploadMimeTypeForFilename('voice.mp3'), 'audio/mpeg');
    expect(uploadMimeTypeForFilename('voice.aac'), 'audio/aac');
    expect(uploadMimeTypeForFilename('voice.ogg'), 'audio/ogg');
    expect(uploadMimeTypeForFilename('voice.opus'), 'audio/ogg');
    expect(uploadMimeTypeForFilename('voice.wav'), 'audio/wav');
    expect(uploadMimeTypeForFilename('voice.m4a'), 'audio/mp4');
    expect(uploadMimeTypeForFilename('voice.webm'), 'audio/webm');
  });

  test('uses image signatures when byte uploads were re-encoded', () {
    expect(
      uploadMimeTypeForBytes([0xff, 0xd8, 0xff, 0x00], 'original.png'),
      'image/jpeg',
    );
    expect(
      uploadMimeTypeForBytes(
        [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
        'avatar.jpg',
      ),
      'image/png',
    );
  });

  test('normalizes an image filename after its encoding changes', () {
    expect(
      uploadFilenameForMimeType('camera_capture.png', 'image/jpeg'),
      'camera_capture.jpg',
    );
    expect(
      uploadFilenameForMimeType('camera_capture', 'image/png'),
      'camera_capture.png',
    );
    expect(
      uploadFilenameForMimeType('camera_capture.jpg', 'application/pdf'),
      'camera_capture.jpg',
    );
  });
}
