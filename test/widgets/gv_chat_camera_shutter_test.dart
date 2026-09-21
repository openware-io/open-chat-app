import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gv_chat_app/core/gv_automation_keys.dart';
import 'package:gv_chat_app/screens/chat_room/gv_chat_camera_screen.dart';

void main() {
  testWidgets('shutter taps for photo and holds for video', (tester) async {
    var photos = 0;
    var recordingStarts = 0;
    var recordingEnds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GvChatCameraShutter(
              key: GvAutomationKeys.chatCameraShutter,
              enabled: true,
              recording: false,
              semanticsLabel: '轻触拍照，长按录像',
              onTap: () => photos++,
              onLongPressStart: () => recordingStarts++,
              onLongPressEnd: () => recordingEnds++,
            ),
          ),
        ),
      ),
    );

    final shutter = find.byKey(GvAutomationKeys.chatCameraShutter);
    await tester.tap(shutter);
    await tester.pump();
    expect(photos, 1);
    expect(recordingStarts, 0);
    expect(recordingEnds, 0);

    await tester.longPress(shutter);
    await tester.pump();
    expect(photos, 1);
    expect(recordingStarts, 1);
    expect(recordingEnds, 1);

    // Releasing after the finger has drifted outside the shutter must still
    // stop the recording on a real touch device.
    final gesture = await tester.startGesture(tester.getCenter(shutter));
    await tester.pump(const Duration(milliseconds: 600));
    expect(recordingStarts, 2);
    await gesture.moveTo(Offset.zero);
    await gesture.up();
    await tester.pump();
    expect(recordingEnds, 2);
  });
}
