import 'package:flutter_test/flutter_test.dart';
import 'package:immichtv/src/core/models/album_summary.dart';
import 'package:immichtv/src/core/models/asset_summary.dart';
import 'package:immichtv/src/core/models/authenticated_session.dart';
import 'package:immichtv/src/core/models/media_page.dart';
import 'package:immichtv/src/core/errors/app_exception.dart';
import 'package:immichtv/src/core/models/person_summary.dart';
import 'package:immichtv/src/core/models/server_config.dart';
import 'package:immichtv/src/core/models/user_profile.dart';
import 'package:immichtv/src/core/repositories/media_repository.dart';
import 'package:immichtv/src/features/library/cubit/library_cubit.dart';
import 'package:immichtv/src/features/library/cubit/library_state.dart';

void main() {
  test(
    'refreshContent stays silent when timeline, albums, and favorites are unchanged',
    () async {
      final repository = _FakeMediaRepository();
      final cubit = LibraryCubit(repository, _session());
      addTearDown(cubit.close);

      await cubit.loadInitial();

      final emittedStates = <LibraryState>[];
      final subscription = cubit.stream.listen(emittedStates.add);
      addTearDown(subscription.cancel);

      await cubit.refreshContent();

      expect(emittedStates, isEmpty);
    },
  );

  test(
    'refreshContent prepends refreshed first-page assets and preserves paginated items',
    () async {
      final repository = _FakeMediaRepository();
      final cubit = LibraryCubit(repository, _session());
      addTearDown(cubit.close);

      await cubit.loadInitial();
      await cubit.loadMore();

      expect(cubit.state.timeline.map((asset) => asset.id), [
        'asset-1',
        'asset-2',
        'asset-3',
      ]);

      repository.timelinePages = {
        null: MediaPage(
          items: [_asset('asset-0'), _asset('asset-1')],
          nextPage: '2',
        ),
        '2': MediaPage(items: [_asset('asset-3')]),
      };

      await cubit.refreshContent();

      expect(cubit.state.timeline.map((asset) => asset.id), [
        'asset-0',
        'asset-1',
        'asset-2',
        'asset-3',
      ]);
      expect(cubit.state.timelineNextPage, '2');
    },
  );

  test(
    'loadInitial still succeeds when supporting tabs fail but timeline loads',
    () async {
      final repository = _FakeMediaRepository()
        ..throwAlbums = true
        ..throwFavorites = true
        ..throwPeople = true;
      final cubit = LibraryCubit(repository, _session());
      addTearDown(cubit.close);

      await cubit.loadInitial();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, LibraryLoadStatus.success);
      expect(cubit.state.hasLoadedTimeline, isTrue);
      expect(cubit.state.timeline, isNotEmpty);
      expect(cubit.state.hasLoadedAlbums, isFalse);
      expect(cubit.state.hasLoadedFavorites, isFalse);
      expect(cubit.state.hasLoadedPeople, isFalse);
    },
  );
}

class _FakeMediaRepository implements MediaRepository {
  Map<String?, MediaPage<AssetSummary>> timelinePages = {
    null: MediaPage(
      items: [_asset('asset-1'), _asset('asset-2')],
      nextPage: '2',
    ),
    '2': MediaPage(items: [_asset('asset-3')]),
  };

  Map<String?, MediaPage<AssetSummary>> favoritePages = {
    null: MediaPage(items: [_asset('favorite-1')]),
  };

  List<AlbumSummary> albums = const [
    AlbumSummary(id: 'album-1', name: 'Summer Trip', assetCount: 42),
  ];

  List<PersonSummary> people = const [
    PersonSummary(
      id: 'person-1',
      name: 'Avery',
      assetCount: 3,
      thumbnailUrls: [
        'https://photos.example.com/api/people/person-1/thumbnail',
      ],
    ),
  ];
  bool throwAlbums = false;
  bool throwFavorites = false;
  bool throwPeople = false;

  @override
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session) async {
    if (throwAlbums) {
      throw const AppException('albums failed');
    }
    return albums;
  }

  @override
  Future<List<PersonSummary>> fetchPeople(AuthenticatedSession session) async {
    if (throwPeople) {
      throw const AppException('people failed');
    }
    return people;
  }

  @override
  Future<MediaPage<AssetSummary>> fetchAlbumAssetsPage(
    AuthenticatedSession session, {
    required String albumId,
    String? page,
    int pageSize = 120,
  }) async => MediaPage(items: [_asset('album-$albumId-1')]);

  @override
  Future<MediaPage<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 60,
  }) async {
    if (throwFavorites) {
      throw const AppException('favorites failed');
    }
    return favoritePages[page] ?? const MediaPage(items: []);
  }

  @override
  Future<MediaPage<AssetSummary>> fetchPersonAssetsPage(
    AuthenticatedSession session, {
    required String personId,
    String? page,
    int pageSize = 120,
  }) async => MediaPage(items: [_asset('person-$personId-1')]);

  @override
  Future<MediaPage<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 60,
    int? year,
  }) async => timelinePages[page] ?? const MediaPage(items: []);
}

AuthenticatedSession _session() {
  return AuthenticatedSession(
    serverConfig: ServerConfig(
      rawInput: 'https://photos.example.com',
      serverUrl: Uri.parse('https://photos.example.com'),
      apiUrl: Uri.parse('https://photos.example.com/api'),
    ),
    accessToken: 'token',
    user: const UserProfile(
      id: 'user-1',
      email: 'family@example.com',
      name: 'Living Room',
    ),
  );
}

AssetSummary _asset(String id) {
  final createdAt = switch (id) {
    'asset-0' => DateTime(2026, 11, 12),
    'asset-1' => DateTime(2026, 11, 11),
    'asset-2' => DateTime(2026, 11, 10),
    'asset-3' => DateTime(2026, 11, 9),
    _ => DateTime(2026, 11, 8),
  };

  return AssetSummary(
    id: id,
    thumbnailUrls: [
      'https://photos.example.com/api/assets/$id/thumbnail?size=preview',
      'https://photos.example.com/api/assets/$id/thumbnail?size=thumbnail',
    ],
    displayUrls: ['https://photos.example.com/api/assets/$id/original'],
    type: 'IMAGE',
    createdAt: createdAt,
  );
}
