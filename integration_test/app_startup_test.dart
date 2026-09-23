import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/open_app.dart';
import 'package:open_chat_app/main.dart' as app;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native app starts without a Flutter exception', (tester) async {
    await app.main();
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(GvChatApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
