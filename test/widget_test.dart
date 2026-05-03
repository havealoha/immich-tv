import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immichtv/app.dart';
import 'package:immichtv/src/core/models/album_summary.dart';
import 'package:immichtv/src/core/models/authenticated_session.dart';
import 'package:immichtv/src/core/models/asset_summary.dart';
import 'package:immichtv/src/core/models/server_config.dart';
import 'package:immichtv/src/core/models/server_validation_result.dart';
import 'package:immichtv/src/core/models/user_profile.dart';
import 'package:immichtv/src/core/repositories/auth_repository.dart';
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
        serverRepository: FakeServerRepository(),
        mediaRepository: FakeMediaRepository(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome to ImmichTV'), findsOneWidget);
    expect(find.textContaining(restoredSession.user.email), findsOneWidget);
    expect(find.text('Timeline'), findsWidgets);
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

    expect(find.text('Welcome to ImmichTV'), findsOneWidget);
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

    expect(find.text('Welcome to ImmichTV'), findsOneWidget);
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

    await tester.tap(find.text('Slideshow').first);
    await tester.pumpAndSettle();
    expect(find.text('Slideshow mode is queued next'), findsOneWidget);
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
  @override
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session) async =>
      [const AlbumSummary(id: 'album-1', name: 'Summer Trip', assetCount: 42)];

  @override
  Future<List<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session,
  ) async => [
    AssetSummary(
      id: 'favorite-1',
      thumbnailUrl:
          'https://photos.example.com/api/assets/favorite-1/thumbnail',
      type: 'IMAGE',
      createdAt: DateTime(2024, 10, 2),
    ),
  ];

  @override
  Future<List<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session,
  ) async => [
    AssetSummary(
      id: 'asset-1',
      thumbnailUrl: 'https://photos.example.com/api/assets/asset-1/thumbnail',
      type: 'IMAGE',
      createdAt: DateTime(2024, 11, 9),
    ),
  ];
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
