import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immichtv/src/features/marketing/marketing_landing_screen.dart';

void main() {
  testWidgets('renders landing content and opens the web app preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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
        'A TV-first client for browsing your self-hosted Immich library from the couch.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open web app'), findsWidgets);
    expect(find.text('Get it on Google Play'), findsOneWidget);

    await tester.tap(find.text('Open web app').first);
    await tester.pumpAndSettle();

    expect(openedWebApp, isTrue);
  });

  testWidgets('renders on a phone-sized viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: MarketingLandingScreen(onOpenWebApp: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Immich TV'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
