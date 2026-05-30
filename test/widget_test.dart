import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immichtv/app.dart';
import 'package:immichtv/src/core/models/album_summary.dart';
import 'package:immichtv/src/core/models/authenticated_session.dart';
import 'package:immichtv/src/core/models/asset_summary.dart';
import 'package:immichtv/src/core/models/media_page.dart';
import 'package:immichtv/src/core/models/saved_profile.dart';
import 'package:immichtv/src/core/models/server_config.dart';
import 'package:immichtv/src/core/models/server_validation_result.dart';
import 'package:immichtv/src/core/models/user_profile.dart';
import 'package:immichtv/src/core/repositories/auth_repository.dart';
import 'package:immichtv/src/core/repositories/asset_image_repository.dart';
import 'package:immichtv/src/core/repositories/media_repository.dart';
import 'package:immichtv/src/core/repositories/server_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows onboarding after bootstrap completes', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ImmichTvApp(
        authRepository: FakeAuthRepository(),
        assetImageRepository: FakeAssetImageRepository(),
        serverRepository: FakeServerRepository(),
        mediaRepository: FakeMediaRepository(),
      ),
    );

    await _settleAppFlow(tester);

    expect(find.widgetWithText(TextField, 'Immich server URL'), findsOneWidget);
    expect(find.text('Validate server'), findsOneWidget);
  });

  testWidgets('shows the saved profile picker when profiles exist', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final restoredSession = _demoSession();
    await tester.pumpWidget(
      ImmichTvApp(
        authRepository: FakeAuthRepository(restoredSession: restoredSession),
        assetImageRepository: FakeAssetImageRepository(),
        serverRepository: FakeServerRepository(),
        mediaRepository: FakeMediaRepository(),
      ),
    );

    await _settleAppFlow(tester);

    expect(find.text(restoredSession.user.name), findsOneWidget);
    expect(find.textContaining(restoredSession.user.email), findsOneWidget);
    expect(find.text('Add profile'), findsOneWidget);
  });

  testWidgets('walks through validation and sign-in into home shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ImmichTvApp(
        authRepository: FakeAuthRepository(),
        assetImageRepository: FakeAssetImageRepository(),
        serverRepository: FakeServerRepository(),
        mediaRepository: FakeMediaRepository(),
      ),
    );
    await _settleAppFlow(tester);

    expect(find.widgetWithText(TextField, 'Immich server URL'), findsOneWidget);

    await tester.tap(find.text('Validate server'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'family@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'demo-password',
    );
    await tester.ensureVisible(find.text('Continue to PIN setup'));
    await tester.tap(find.text('Continue to PIN setup'));
    await tester.pumpAndSettle();

    expect(find.text('Create a 4-digit PIN'), findsOneWidget);
    await _enterOtpDigits(tester, '1234');
    await tester.pumpAndSettle();

    expect(find.text('Confirm your 4-digit PIN'), findsOneWidget);
    await _enterOtpDigits(tester, '1234');
    await tester.pumpAndSettle();

    expect(find.text('Timeline'), findsWidgets);
    expect(find.textContaining('family@example.com'), findsOneWidget);
  });

  testWidgets('supports keyboard-style submit flow on onboarding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ImmichTvApp(
        authRepository: FakeAuthRepository(),
        assetImageRepository: FakeAssetImageRepository(),
        serverRepository: FakeServerRepository(),
        mediaRepository: FakeMediaRepository(),
      ),
    );
    await _settleAppFlow(tester);

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'keyboard@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'secret-password',
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Create a 4-digit PIN'), findsOneWidget);
    await _enterOtpDigits(tester, '2468');
    await tester.pumpAndSettle();

    expect(find.text('Confirm your 4-digit PIN'), findsOneWidget);
    await _enterOtpDigits(tester, '2468');
    await tester.pumpAndSettle();

    expect(find.text('Timeline'), findsWidgets);
    expect(find.textContaining('keyboard@example.com'), findsOneWidget);
  });

  testWidgets('supports remote-style navigation in the sidebar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpSignedInApp(tester, mediaRepository: FakeMediaRepository());

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Summer Trip'), findsWidgets);
    expect(find.text('42 assets'), findsOneWidget);
  });

  testWidgets('switches between library sections and shows empty states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpSignedInApp(tester, mediaRepository: FakeMediaRepository());

    expect(find.text('Asset asset-1'), findsOneWidget);

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Summer Trip'), findsWidgets);
    expect(find.text('42 assets'), findsOneWidget);
    expect(find.text('Asset asset-1'), findsOneWidget);

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Asset favorite-1'), findsOneWidget);
  });

  testWidgets('loads the next timeline page as the grid scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpSignedInApp(
      tester,
      mediaRepository: FakeMediaRepository(paginatedTimeline: true),
    );

    expect(find.text('Asset asset-1'), findsOneWidget);
    expect(find.text('Asset asset-3'), findsNothing);

    await tester.drag(find.byType(GridView).first, const Offset(0, -1200));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Asset asset-3'), findsOneWidget);
  });

  testWidgets('opens the fullscreen asset viewer and navigates forward', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpSignedInApp(tester, mediaRepository: FakeMediaRepository());

    final firstAssetLabel = find.text('Asset asset-1').first;
    await tester.ensureVisible(firstAssetLabel);
    await tester.tap(firstAssetLabel, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.close_rounded), findsWidgets);
    expect(find.byIcon(Icons.slideshow_rounded), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.slideshow_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text('2026-11-10'), findsOneWidget);
  });

  testWidgets('starts a slideshow with playback controls', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pumpSignedInApp(tester, mediaRepository: FakeMediaRepository());

    final firstAssetLabel = find.text('Asset asset-1').first;
    await tester.ensureVisible(firstAssetLabel);
    await tester.tap(firstAssetLabel, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.slideshow_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Start slideshow'), findsOneWidget);
    await tester.tap(find.text('5'));
    await tester.pumpAndSettle();

    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(find.text('2026-11-09'), findsOneWidget);
  });
}

Future<void> _settleAppFlow(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1700));
  await tester.pumpAndSettle();
}

Future<void> _enterOtpDigits(WidgetTester tester, String digits) async {
  expect(digits.length, 4);
  final fields = find.byType(TextField);
  for (var index = 0; index < digits.length; index++) {
    await tester.enterText(fields.at(index), digits[index]);
  }
}

Future<void> _pumpSignedInApp(
  WidgetTester tester, {
  required MediaRepository mediaRepository,
}) async {
  await tester.pumpWidget(
    ImmichTvApp(
      authRepository: FakeAuthRepository(),
      assetImageRepository: FakeAssetImageRepository(),
      serverRepository: FakeServerRepository(),
      mediaRepository: mediaRepository,
    ),
  );
  await _settleAppFlow(tester);

  await tester.tap(find.text('Validate server'));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.widgetWithText(TextField, 'Email'),
    'family@example.com',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Password'),
    'demo-password',
  );
  await tester.ensureVisible(find.text('Continue to PIN setup'));
  await tester.tap(find.text('Continue to PIN setup'));
  await tester.pumpAndSettle();

  await _enterOtpDigits(tester, '1234');
  await tester.pumpAndSettle();
  await _enterOtpDigits(tester, '1234');
  await tester.pumpAndSettle();
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.restoredSession});

  final AuthenticatedSession? restoredSession;

  @override
  Future<AuthenticatedSession> signIn({
    required ServerConfig serverConfig,
    required String email,
    required String password,
  }) async {
    return AuthenticatedSession(
      serverConfig: serverConfig,
      accessToken: 'token',
      user: UserProfile(id: '1', email: email, name: 'Living Room'),
    );
  }

  @override
  Future<List<SavedProfile>> getSavedProfiles() async {
    if (restoredSession == null) {
      return const <SavedProfile>[];
    }

    return [
      SavedProfile(
        id: 'saved-profile',
        name: restoredSession!.user.name,
        email: restoredSession!.user.email,
        serverConfig: restoredSession!.serverConfig,
        lastUsedAt: DateTime(2025),
      ),
    ];
  }

  @override
  Future<void> saveProfile({
    required AuthenticatedSession session,
    required String password,
    required String pin,
  }) async {}

  @override
  Future<AuthenticatedSession> signInWithSavedProfile({
    required String profileId,
    required String pin,
  }) async {
    return restoredSession ?? _demoSession();
  }

  @override
  Future<void> signOut() async {}
}

class FakeServerRepository implements ServerRepository {
  @override
  Future<ServerValidationResult> validateServer(String rawInput) async {
    final serverConfig = ServerConfig(
      rawInput: rawInput,
      serverUrl: Uri.parse('https://photos.example.com'),
      apiUrl: Uri.parse('https://photos.example.com/api'),
    );
    return ServerValidationResult(
      serverConfig: serverConfig,
      pingPath: 'server/ping',
    );
  }
}

class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository({this.paginatedTimeline = false});

  final bool paginatedTimeline;

  @override
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session) async =>
      [const AlbumSummary(id: 'album-1', name: 'Summer Trip', assetCount: 42)];

  @override
  Future<MediaPage<AssetSummary>> fetchAlbumAssetsPage(
    AuthenticatedSession session, {
    required String albumId,
    String? page,
    int pageSize = 120,
  }) async => MediaPage(items: _timelinePageOne);

  @override
  Future<MediaPage<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 60,
  }) async => MediaPage(
    items: [
      AssetSummary(
        id: 'favorite-1',
        thumbnailUrls: const [
          'mock://favorite-1?palette=ember&variant=thumbnail',
          'mock://favorite-1?palette=ember&variant=thumbnail',
        ],
        displayUrls: const ['mock://favorite-1?palette=ember&variant=display'],
        type: 'IMAGE',
        createdAt: DateTime(2024, 10, 2),
      ),
    ],
  );

  @override
  Future<MediaPage<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 60,
    int? year,
  }) async {
    if (!paginatedTimeline) {
      return MediaPage(items: _timelinePageOne);
    }

    return switch (page) {
      null => MediaPage(items: _timelinePageOne, nextPage: '2'),
      '2' => MediaPage(items: _timelinePageTwo),
      _ => const MediaPage(items: []),
    };
  }
}

class FakeAssetImageRepository implements AssetImageRepository {
  @override
  Future<void> prefetchImages({
    required List<List<String>> urls,
    required String accessToken,
  }) async {}
}

AuthenticatedSession _demoSession() {
  return AuthenticatedSession(
    serverConfig: ServerConfig(
      rawInput: 'https://photos.example.com',
      serverUrl: Uri.parse('https://photos.example.com'),
      apiUrl: Uri.parse('https://photos.example.com/api'),
    ),
    accessToken: 'token',
    user: const UserProfile(
      id: '1',
      email: 'family@example.com',
      name: 'Living Room',
    ),
  );
}

final List<AssetSummary> _timelinePageOne = [
  AssetSummary(
    id: 'asset-1',
    thumbnailUrls: const [
      'mock://asset-1?palette=sea-glass&variant=thumbnail',
      'mock://asset-1?palette=sea-glass&variant=thumbnail',
    ],
    displayUrls: const ['mock://asset-1?palette=sea-glass&variant=display'],
    type: 'IMAGE',
    createdAt: DateTime(2026, 11, 9),
  ),
  AssetSummary(
    id: 'asset-2',
    thumbnailUrls: const [
      'mock://asset-2?palette=sunrise&variant=thumbnail',
      'mock://asset-2?palette=sunrise&variant=thumbnail',
    ],
    displayUrls: const ['mock://asset-2?palette=sunrise&variant=display'],
    type: 'IMAGE',
    createdAt: DateTime(2026, 11, 10),
  ),
];

final List<AssetSummary> _timelinePageTwo = [
  AssetSummary(
    id: 'asset-3',
    thumbnailUrls: const [
      'mock://asset-3?palette=forest&variant=thumbnail',
      'mock://asset-3?palette=forest&variant=thumbnail',
    ],
    displayUrls: const ['mock://asset-3?palette=forest&variant=display'],
    type: 'IMAGE',
    createdAt: DateTime(2026, 11, 11),
  ),
];
