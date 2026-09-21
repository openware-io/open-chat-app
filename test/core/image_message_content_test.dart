import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gv_core/gv_core.dart';

void main() {
  group('image message content', () {
    test('keeps dimensions outside the managed signed URL', () {
      const stored =
          'https://media.example.com/uploads/photo.jpg?signature=abc';

      final content = encodeImageForChat(
        storedUrl: stored,
        caption: '   ',
        w: 1080,
        h: 720,
      );
      final json = jsonDecode(content) as Map<String, dynamic>;
      expect(json['url'], stored);
      expect(json['w'], 1080);
      expect(json['h'], 720);

      final parsed = parseImageForChat('https://media.example.com', content);
      expect(parsed.imageUrl, stored);
      expect(parsed.w, 1080);
      expect(parsed.h, 720);
      expect(parsed.caption, isEmpty);
    });

    test('encodes and parses a caption in the existing content field', () {
      final content = encodeImageForChat(
        storedUrl: 'https://media.example.com/uploads/photo.jpg?w=1080&h=720',
        caption: '  项目 789  ',
        w: 1080,
        h: 720,
      );
      final json = jsonDecode(content) as Map<String, dynamic>;
      expect(json['v'], 1);
      expect(json['url'], 'https://media.example.com/uploads/photo.jpg');
      expect(json['caption'], '项目 789');

      final parsed = parseImageForChat('https://media.example.com', content);
      expect(parsed.imageUrl, 'https://media.example.com/uploads/photo.jpg');
      expect(parsed.w, 1080);
      expect(parsed.h, 720);
      expect(parsed.caption, '项目 789');
    });

    test('rejects relative and malformed legacy media content', () {
      final parsed = parseImageForChat('https://media.example.com', '{bad');
      expect(parsed.caption, isEmpty);
      expect(parsed.imageUrl, isEmpty);
      expect(
        resolveMediaUrl(
          'https://media.example.com',
          'https://untrusted.example.net/photo.jpg',
        ),
        isEmpty,
      );
    });
  });

}
