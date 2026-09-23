import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/models/chat_message.dart';
import 'package:open_chat_app/widgets/open_chat_quoted_message_preview.dart';
import 'package:open_chat_app/widgets/open_chat_video_thumbnail.dart';

void main() {
  testWidgets('quoted image uses a thumbnail', (tester) async {
    await tester.pumpWidget(
      _testApp(
        _message(
          msgType: 'image',
          content: 'https://media.example.com/image.jpg',
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    expect(find.textContaining('[图片]'), findsNothing);
  });

  testWidgets('quoted video uses a thumbnail', (tester) async {
    await tester.pumpWidget(
      _testApp(
        _message(
          msgType: 'video',
          content:
              '{"url":"https://media.example.com/video.mp4","p":"https://media.example.com/poster.jpg"}',
        ),
      ),
    );

    expect(find.byType(GvChatVideoThumbnail), findsOneWidget);
    expect(find.textContaining('[视频]'), findsNothing);
  });

  testWidgets('quoted text keeps its text preview', (tester) async {
    await tester.pumpWidget(_testApp(_message(content: '你好')));

    expect(find.textContaining('张三：你好'), findsOneWidget);
  });

  testWidgets('quoted media invokes its open callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      _testApp(
        _message(
          msgType: 'image',
          content: 'https://media.example.com/image.jpg',
        ),
        onMediaTap: () => tapped = true,
      ),
    );

    await tester.tap(find.byType(CachedNetworkImage));

    expect(tapped, isTrue);
  });
}

Widget _testApp(ChatMessage message, {VoidCallback? onMediaTap}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: GvChatQuotedMessagePreview(
          message: message,
          baseUrl: 'https://media.example.com',
          prefix: '张三：',
          color: Colors.grey,
          onMediaTap: onMediaTap,
        ),
      ),
    ),
  );
}

ChatMessage _message({
  String msgType = 'text',
  required String content,
}) {
  return ChatMessage(
    msgId: '1',
    from: 2,
    toId: '3',
    chatType: 'private',
    msgType: msgType,
    content: content,
    timestamp: DateTime(2026),
  );
}
