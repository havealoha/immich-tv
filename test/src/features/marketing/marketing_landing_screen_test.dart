import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immichtv/src/features/marketing/marketing_landing_screen.dart';

void main() {
  testWidgets('renders landing content and opens the web app preview', (
    tester,
  ) async {
    var openedWebApp = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MarketingLandingScreen(
          onOpenWebApp: () {
            openedWebApp = true;
          },
        ),
      ),
    );

    expect(
      find.text(
        'A minimal, TV-first way to enjoy your self-hosted photo library.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open web app preview'), findsOneWidget);
    expect(find.text('Download APK'), findsOneWidget);

    await tester.tap(find.text('Open web app preview'));
    await tester.pumpAndSettle();

    expect(openedWebApp, isTrue);
  });
}
