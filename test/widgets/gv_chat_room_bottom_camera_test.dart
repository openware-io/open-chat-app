import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/gv_automation_keys.dart';
import 'package:gv_chat_app/l10n/app_localizations.dart';
import 'package:gv_chat_app/widgets/gv_chat_room_bottom.dart';

void main() {
  testWidgets('camera action opens the combined photo and video camera',
      (tester) async {
    var photoCount = 0;
    var videoCount = 0;

    await tester.pumpWidget(
      _testApp(
        GvChatRoomBottom(
          myId: 1,
          replyTo: null,
          onDismissReply: () {},
          voiceMode: false,
          recording: false,
          onToggleVoiceMode: () {},
          voiceHoldAreaKey: GlobalKey(),
          onVoicePointerDown: (_) {},
          onVoicePointerMove: (_) {},
          onVoicePointerUp: (_) {},
          onVoicePointerCancel: (_) {},
          onTyping: () {},
          ensureChatAllowed: () => true,
          onSendText: (_, __, ___) {},
          onComposerFocusGained: () {},
          onSendSticker: (_) {},
          onAddCustomSticker: () async {},
          onPickImage: () async {},
          onTakePhoto: () async => photoCount++,
          onPickVideo: () async {},
          onRecordVideo: () async => videoCount++,
          onPickFile: () async {},
          onStartPrivateCall: (_) {},
          isPrivateChat: false,
          voiceCallEnabled: false,
          videoCallEnabled: false,
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.circle_plus));
    await tester.pumpAndSettle();

    final camera = find.byKey(GvAutomationKeys.chatMoreCamera);
    expect(camera, findsOneWidget);
    expect(find.text('拍摄'), findsOneWidget);
    expect(find.text('拍视频'), findsNothing);

    await tester.tap(camera);
    await tester.pump();
    expect(photoCount, 1);
    expect(videoCount, 0);

    // Recording now starts by holding the shutter inside the camera screen,
    // not by holding this attachment-panel shortcut.
    expect(videoCount, 0);
  });
}

Widget _testApp(Widget bottom) => MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: const SizedBox.expand(),
        bottomNavigationBar: bottom,
      ),
    );
