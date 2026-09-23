import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_chat_app/l10n/app_localizations.dart';
import 'package:open_chat_app/widgets/open_service_shortcut_grid.dart';

void main() {
  testWidgets('local service shortcuts render and respond to taps',
      (tester) async {
    GvServiceShortcutType? tapped;
    await tester.pumpWidget(
      _testApp(
        GvServiceShortcutGrid(onTap: (value) => tapped = value),
      ),
    );

    expect(find.text('酒店'), findsOneWidget);
    expect(find.text('优惠券'), findsNothing);

    await tester.tap(find.text('酒店'));
    expect(tapped, GvServiceShortcutType.hotel);
  });
}

Widget _testApp(Widget child) => MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
