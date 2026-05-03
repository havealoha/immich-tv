import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immichtv/app.dart';
import 'package:immichtv/src/core/models/album_summary.dart';
import 'package:immichtv/src/core/models/authenticated_session.dart';
import 'package:immichtv/src/core/models/asset_summary.dart';
import 'package:immichtv/src/core/models/media_page.dart';
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

    await tester.pumpAndSettle();

    expect(find.text('Connect your server'), findsOneWidget);
    expect(find.text('Validate server'), findsOneWidget);
  });

  testWidgets('restores a persisted session into the home shell', (
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

    await tester.pumpAndSettle();

    expect(find.text('Timeline'), findsWidgets);
    expect(find.textContaining(restoredSession.user.email), findsOneWidget);
    expect(find.text('Asset asset-1'), findsOneWidget);
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
    await tester.pumpAndSettle();

    expect(find.text('Connect your server'), findsOneWidget);

    await tester.tap(find.text('Validate server'));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to Immich'), findsOneWidget);
    expect(
      find.textContaining('API detected at https://photos.example.com/api'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).at(1), 'family@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'demo-password');
    await tester.ensureVisible(find.text('Continue to library shell'));
    await tester.tap(find.text('Continue to library shell'));
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
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).first);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Sign in to Immich'), findsOneWidget);

    await tester.tap(find.byType(TextField).at(2));
    await tester.enterText(
      find.byType(TextField).at(1),
      'keyboard@example.com',
    );
    await tester.enterText(find.byType(TextField).at(2), 'secret-password');
    await tester.tap(find.byType(TextField).at(2));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Timeline'), findsWidgets);
    expect(find.textContaining('keyboard@example.com'), findsOneWidget);
  });

  testWidgets('switches between library sections and shows empty states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ImmichTvApp(
        authRepository: FakeAuthRepository(restoredSession: _demoSession()),
        assetImageRepository: FakeAssetImageRepository(),
        serverRepository: FakeServerRepository(),
        mediaRepository: FakeMediaRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asset asset-1'), findsOneWidget);

    await tester.tap(find.text('Albums').first);
    await tester.pumpAndSettle();
    expect(find.text('Summer Trip'), findsOneWidget);

    await tester.tap(find.text('Favorites').first);
    await tester.pumpAndSettle();
    expect(find.text('Asset favorite-1'), findsOneWidget);

    await tester.ensureVisible(find.text('Slideshow').first);
    await tester.tap(find.text('Slideshow').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Start slideshow'), findsOneWidget);
    expect(find.text('Timeline • 2'), findsOneWidget);
  });

  testWidgets('loads the next timeline page as the grid scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ImmichTvApp(
        authRepository: FakeAuthRepository(restoredSession: _demoSession()),
        assetImageRepository: FakeAssetImageRepository(),
        serverRepository: FakeServerRepository(),
        mediaRepository: FakeMediaRepository(paginatedTimeline: true),
      ),
    );
    await tester.pumpAndSettle();

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

    await tester.pumpWidget(
      ImmichTvApp(
        authRepository: FakeAuthRepository(restoredSession: _demoSession()),
        assetImageRepository: FakeAssetImageRepository(),
        serverRepository: FakeServerRepository(),
        mediaRepository: FakeMediaRepository(),
      ),
    );
    await tester.pumpAndSettle();

    final firstAssetLabel = find.text('Asset asset-1').first;
    await tester.ensureVisible(firstAssetLabel);
    await tester.tap(firstAssetLabel, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('2024-11-09'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    expect(find.text('2024-11-10'), findsOneWidget);
  });

  testWidgets('starts a slideshow with playback controls', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ImmichTvApp(
        authRepository: FakeAuthRepository(restoredSession: _demoSession()),
        assetImageRepository: FakeAssetImageRepository(),
        serverRepository: FakeServerRepository(),
        mediaRepository: FakeMediaRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Slideshow').first);
    await tester.tap(find.text('Slideshow').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start slideshow'));
    await tester.pumpAndSettle();

    expect(find.text('Photo 1 of 2'), findsOneWidget);
    expect(find.text('Pause'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('starts a slideshow from an album', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ImmichTvApp(
        authRepository: FakeAuthRepository(restoredSession: _demoSession()),
        assetImageRepository: FakeAssetImageRepository(),
        serverRepository: FakeServerRepository(),
        mediaRepository: FakeMediaRepository(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Slideshow').first);
    await tester.tap(find.text('Slideshow').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Albums •'));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Start Summer Trip'));
    await tester.pumpAndSettle();

    expect(find.text('Photo 1 of 2'), findsOneWidget);
  });
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
  Future<AuthenticatedSession?> restoreSession() async => restoredSession;

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
  Future<List<AssetSummary>> fetchAlbumAssets(
    AuthenticatedSession session, {
    required String albumId,
  }) async => _timelinePageOne;

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
          'https://photos.example.com/api/assets/favorite-1/thumbnail?size=preview',
          'https://photos.example.com/api/assets/favorite-1/thumbnail?size=thumbnail',
        ],
        displayUrls: const [
          'https://photos.example.com/api/assets/favorite-1/original',
        ],
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
  Future<Uint8List> fetchImageBytes({
    required List<String> urls,
    required String accessToken,
  }) async {
    return Uint8List.fromList(_transparentImageBytes);
  }

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

const List<int> _transparentImageBytes = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x00,
  0x00,
  0x03,
  0x01,
  0x01,
  0x00,
  0x18,
  0xDD,
  0x8D,
  0xB1,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

final List<AssetSummary> _timelinePageOne = [
  AssetSummary(
    id: 'asset-1',
    thumbnailUrls: const [
      'https://photos.example.com/api/assets/asset-1/thumbnail?size=preview',
      'https://photos.example.com/api/assets/asset-1/thumbnail?size=thumbnail',
    ],
    displayUrls: const [
      'https://photos.example.com/api/assets/asset-1/original',
    ],
    type: 'IMAGE',
    createdAt: DateTime(2024, 11, 9),
  ),
  AssetSummary(
    id: 'asset-2',
    thumbnailUrls: const [
      'https://photos.example.com/api/assets/asset-2/thumbnail?size=preview',
      'https://photos.example.com/api/assets/asset-2/thumbnail?size=thumbnail',
    ],
    displayUrls: const [
      'https://photos.example.com/api/assets/asset-2/original',
    ],
    type: 'IMAGE',
    createdAt: DateTime(2024, 11, 10),
  ),
];

final List<AssetSummary> _timelinePageTwo = [
  AssetSummary(
    id: 'asset-3',
    thumbnailUrls: const [
      'https://photos.example.com/api/assets/asset-3/thumbnail?size=preview',
      'https://photos.example.com/api/assets/asset-3/thumbnail?size=thumbnail',
    ],
    displayUrls: const [
      'https://photos.example.com/api/assets/asset-3/original',
    ],
    type: 'IMAGE',
    createdAt: DateTime(2024, 11, 11),
  ),
];
