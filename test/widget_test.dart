import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:immichtv/app.dart';

void main() {
  testWidgets('shows onboarding after bootstrap completes', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ImmichTvApp());

    expect(find.text('ImmichTV'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Connect your server'), findsOneWidget);
    expect(find.text('Validate server'), findsOneWidget);
  });

  testWidgets('walks through the first-time flow into home shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ImmichTvApp());
    await tester.pump(const Duration(milliseconds: 700));

    await tester.tap(find.text('Validate server'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Sign in to Immich'), findsOneWidget);

    await tester.tap(find.text('Continue to library shell'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Welcome to ImmichTV'), findsOneWidget);
    expect(
      find.textContaining('Connected to https://photos.example.com'),
      findsOneWidget,
    );
  });
}
