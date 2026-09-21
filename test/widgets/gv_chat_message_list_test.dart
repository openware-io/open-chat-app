import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gv_ui/gv_ui.dart';

void main() {
  testWidgets('short message list does not accept a scroll drag',
      (tester) async {
    final controller = GvChatMessageListController();

    await tester.pumpWidget(_testApp(controller: controller, itemCount: 1));

    final position = controller.scroll.position;
    expect(position.maxScrollExtent, 0);
    expect(position.physics.shouldAcceptUserOffset(position), isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.scroll.dispose();
  });

  testWidgets('overflowing message list remains scrollable', (tester) async {
    final controller = GvChatMessageListController();

    await tester.pumpWidget(_testApp(controller: controller, itemCount: 12));

    final position = controller.scroll.position;
    expect(position.maxScrollExtent, greaterThan(0));
    expect(position.physics.shouldAcceptUserOffset(position), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.scroll.dispose();
  });
}

Widget _testApp({
  required GvChatMessageListController controller,
  required int itemCount,
}) {
  return MaterialApp(
    theme: ThemeData(platform: TargetPlatform.android),
    home: Scaffold(
      body: SizedBox(
        height: 320,
        child: Align(
          alignment: Alignment.topCenter,
          child: GvChatMessageList<int>(
            controller: controller,
            messages: List<int>.generate(itemCount, (index) => index),
            pagingEnabled: false,
            shrinkWrap: true,
            itemBuilder: (context, message, index) => SizedBox(
              height: 64,
              child: Text('$message'),
            ),
          ),
        ),
      ),
    ),
  );
}
