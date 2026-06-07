import 'package:dio/dio.dart';

import '../../../core/config/demo_mode.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/models/album_summary.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/asset_summary.dart';
import '../../../core/models/media_page.dart';
import '../../../core/network/immich_headers.dart';
import '../../../core/repositories/media_repository.dart';
import '../../mock/data/mock_media_repository.dart';

class ImmichMediaRepository implements MediaRepository {
  ImmichMediaRepository({required Dio dio})
    : _dio = dio,
      _mockMediaRepository = MockMediaRepository();

  final Dio _dio;
  final MockMediaRepository _mockMediaRepository;

  @override
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session) async {
    if (DemoMode.matchesServerUrl(session.serverConfig.serverUrl)) {
      return _mockMediaRepository.fetchAlbums(session);
    }

    final response = await _dio.get<List<dynamic>>(
      session.serverConfig.apiEndpoint('albums').toString(),
      options: Options(
        headers: ImmichHeaders.sessionToken(session.accessToken),
      ),
    );

    final items = response.data ?? const [];
    final albums = items
        .whereType<Map<String, dynamic>>()
        .map(_mapAlbum)
        .whereType<AlbumSummary>()
        .toList(growable: false);
    final sortedAlbums = albums.toList(growable: false)
      ..sort((a, b) {
        final assetCountCompare = b.assetCount.compareTo(a.assetCount);
        if (assetCountCompare != 0) {
          return assetCountCompare;
        }

        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return sortedAlbums;
  }

  @override
  Future<MediaPage<AssetSummary>> fetchAlbumAssetsPage(
    AuthenticatedSession session, {
    required String albumId,
    String? page,
    int pageSize = 120,
  }) async {
    if (DemoMode.matchesServerUrl(session.serverConfig.serverUrl)) {
      return _mockMediaRepository.fetchAlbumAssetsPage(
        session,
        albumId: albumId,
        page: page,
        pageSize: pageSize,
      );
    }

    final pageNumber = int.tryParse(page ?? '1') ?? 1;
    final response = await _dio.post<dynamic>(
      session.serverConfig.apiEndpoint('search/metadata').toString(),
      data: {
        'albumIds': [albumId],
        'page': pageNumber,
        'size': pageSize,
        'withArchived': false,
      },
      options: Options(
        headers: {
          ...ImmichHeaders.sessionToken(session.accessToken),
          'Content-Type': 'application/json',
        },
      ),
    );

    final items = _extractAssetMaps(response.data);
    return MediaPage(
      items: items
          .map((item) => _mapAsset(item, session))
          .whereType<AssetSummary>()
          .toList(growable: false),
      nextPage: _extractCountBasedNextPage(
        response.data,
        currentPage: pageNumber,
        pageSize: pageSize,
        currentItemCount: items.length,
      ),
    );
  }

  @override
  Future<MediaPage<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 30,
  }) async {
    if (DemoMode.matchesServerUrl(session.serverConfig.serverUrl)) {
      return _mockMediaRepository.fetchFavoritesPage(
        session,
        page: page,
        pageSize: pageSize,
      );
    }

    logger.info(
      'Fetching favorite assets for ${session.user.email} page ${page ?? '1'}',
    );
    final Map<String, dynamic> requestBody = {
      'isFavorite': true,
      'size': pageSize,
    };
    if (page != null) {
      requestBody['page'] = page;
    }
    final response = await _dio.post<dynamic>(
      session.serverConfig.apiEndpoint('search/metadata').toString(),
      data: requestBody,
      options: Options(
        headers: {
          ...ImmichHeaders.sessionToken(session.accessToken),
          'Content-Type': 'application/json',
        },
      ),
    );

    final items = _extractAssetMaps(response.data);
    logger.info('Favorite assets payload returned ${items.length} items');
    return MediaPage(
      items: items
          .map((item) => _mapAsset(item, session))
          .whereType<AssetSummary>()
          .toList(growable: false),
      nextPage: _extractNextPage(response.data),
    );
  }

  @override
  Future<MediaPage<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 30,
    int? year,
  }) async {
    if (DemoMode.matchesServerUrl(session.serverConfig.serverUrl)) {
      return _mockMediaRepository.fetchTimelinePage(
        session,
        page: page,
        pageSize: pageSize,
        year: year,
      );
    }

    logger.info(
      'Fetching timeline assets for ${session.user.email} page ${page ?? '1'} year ${year?.toString() ?? 'all'}',
    );
    final searchTimeline = await _fetchTimelineViaSearchMetadata(
      session,
      page: page,
      pageSize: pageSize,
      year: year,
    );
    if (searchTimeline.items.isNotEmpty || page != null) {
      logger.info(
        'Timeline asset search returned ${searchTimeline.items.length} assets',
      );
      return searchTimeline;
    }

      logger.warning(
        'Timeline search returned no assets, falling back to timeline bucket API',
      );
      if (year != null) {
        return const MediaPage(items: []);
      }
      final headers = ImmichHeaders.sessionToken(session.accessToken);

    final bucketCandidates = [
      {
        'size': 'MONTH',
        'withPartners': true,
        'withStacked': true,
        'isArchived': false,
      },
      {
        'size': 'MONTH',
        'withPartners': true,
        'withStacked': true,
        'visibility': 'timeline',
      },
    ];

    List<dynamic> buckets = const [];
    Map<String, dynamic>? chosenQuery;

    for (final query in bucketCandidates) {
      try {
        final response = await _dio.get<List<dynamic>>(
          session.serverConfig.apiEndpoint('timeline/buckets').toString(),
          queryParameters: query,
          options: Options(headers: headers),
        );
        buckets = response.data ?? const [];
        chosenQuery = query;
        break;
      } on DioException catch (error) {
        final statusCode = error.response?.statusCode;
        if (statusCode == 400 || statusCode == 404) {
          continue;
        }
        rethrow;
      }
    }

    if (chosenQuery == null || buckets.isEmpty) {
      logger.warning('Timeline bucket API returned no buckets');
      return const MediaPage(items: []);
    }

    final timeBucket = _extractTimeBucket(buckets.first);
    if (timeBucket == null || timeBucket.isEmpty) {
      return const MediaPage(items: []);
    }

    final detailResponse = await _dio.get<dynamic>(
      session.serverConfig.apiEndpoint('timeline/bucket').toString(),
      queryParameters: {...chosenQuery, 'timeBucket': timeBucket},
      options: Options(headers: headers),
    );

    final items = _extractAssetMaps(detailResponse.data);
    logger.info('Timeline bucket API returned ${items.length} assets');
    return MediaPage(
      items: items
          .map((item) => _mapAsset(item, session))
          .whereType<AssetSummary>()
          .toList(growable: false),
    );
  }

  Future<MediaPage<AssetSummary>> _fetchTimelineViaSearchMetadata(
    AuthenticatedSession session, {
    String? page,
    required int pageSize,
    int? year,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'size': pageSize,
        'withArchived': false,
        'order': 'desc',
      };
      if (page != null) {
        requestBody['page'] = page;
      }
      if (year != null) {
        requestBody['takenAfter'] = DateTime(year, 1, 1).toIso8601String();
        requestBody['takenBefore'] = DateTime(
          year + 1,
          1,
          1,
        ).subtract(const Duration(milliseconds: 1)).toIso8601String();
      }
      final response = await _dio.post<dynamic>(
        session.serverConfig.apiEndpoint('search/metadata').toString(),
        data: requestBody,
        options: Options(
          headers: {
            ...ImmichHeaders.sessionToken(session.accessToken),
            'Content-Type': 'application/json',
          },
        ),
      );

      final items = _extractAssetMaps(response.data);
      return MediaPage(
        items: items
            .map((item) => _mapAsset(item, session))
            .whereType<AssetSummary>()
            .toList(growable: false),
        nextPage: _extractNextPage(response.data),
      );
    } on DioException catch (error) {
      logger.warning(
        'Timeline asset search failed with ${error.response?.statusCode ?? error.type.name}',
      );
      return const MediaPage(items: []);
    }
  }

  String? _extractNextPage(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final directNextPage = payload['nextPage'];
      if (directNextPage != null && directNextPage.toString().isNotEmpty) {
        return directNextPage.toString();
      }

      for (final key in const ['assets', 'items', 'results', 'data']) {
        final nested = payload[key];
        if (nested is Map<String, dynamic>) {
          final nestedNextPage = _extractNextPage(nested);
          if (nestedNextPage != null && nestedNextPage.isNotEmpty) {
            return nestedNextPage;
          }
        }
      }
    }

    return null;
  }

  String? _extractCountBasedNextPage(
    dynamic payload, {
    required int currentPage,
    required int pageSize,
    required int currentItemCount,
  }) {
    if (payload is Map<String, dynamic>) {
      final rawCount = payload['count'];
      final count = rawCount is int
          ? rawCount
          : int.tryParse(rawCount?.toString() ?? '');
      if (count != null) {
        return count > currentPage * pageSize ? '${currentPage + 1}' : null;
      }
    }

    return currentItemCount >= pageSize ? '${currentPage + 1}' : null;
  }

  String? _extractTimeBucket(dynamic bucket) {
    if (bucket is String) {
      return bucket;
    }

    if (bucket is Map<String, dynamic>) {
      for (final key in const ['timeBucket', 'bucket', 'date']) {
        final value = bucket[key];
        if (value is String && value.isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _extractAssetMaps(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    if (payload is Map<String, dynamic>) {
      final directItems = payload['items'];
      if (directItems is List) {
        return directItems.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
      }

      final candidates = <dynamic>[
        payload['assets'],
        payload['items'],
        payload['results'],
        payload['data'],
      ];

      for (final nested in candidates) {
        if (nested is List) {
          return nested.whereType<Map<String, dynamic>>().toList(
            growable: false,
          );
        }

        if (nested is Map<String, dynamic>) {
          final nestedItems = _extractAssetMaps(nested);
          if (nestedItems.isNotEmpty) {
            return nestedItems;
          }
        }
      }
    }

    return const [];
  }

  AlbumSummary? _mapAlbum(Map<String, dynamic> item) {
    final id = item['id'] as String?;
    final name = (item['albumName'] ?? item['name'] ?? item['title'])
        ?.toString();
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      return null;
    }

    final assetCountValue = item['assetCount'];
    final assetCount = assetCountValue is int
        ? assetCountValue
        : int.tryParse(assetCountValue?.toString() ?? '') ?? 0;

    return AlbumSummary(id: id, name: name, assetCount: assetCount);
  }

  AssetSummary? _mapAsset(
    Map<String, dynamic> item,
    AuthenticatedSession session,
  ) {
    final id = item['id'] as String?;
    if (id == null || id.isEmpty) {
      return null;
    }

    final type = (item['type'] ?? item['originalPath'] ?? 'asset').toString();
    final createdAtRaw =
        item['localDateTime'] ??
        item['fileCreatedAt'] ??
        item['createdAt'] ??
        item['date'];
    final createdAt = DateTime.tryParse(createdAtRaw?.toString() ?? '');

    return AssetSummary(
      id: id,
      thumbnailUrls: _buildThumbnailUrls(session, id, type),
      displayUrls: _buildDisplayUrls(session, id, type),
      type: type,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  List<String> _buildThumbnailUrls(
    AuthenticatedSession session,
    String id,
    String type,
  ) {
    final baseThumbnail = session.serverConfig.apiEndpoint(
      'assets/$id/thumbnail',
    );
    return <String>[
      baseThumbnail
          .replace(queryParameters: const {'size': 'preview'})
          .toString(),
      baseThumbnail
          .replace(queryParameters: const {'size': 'thumbnail'})
          .toString(),
    ];
  }

  List<String> _buildDisplayUrls(
    AuthenticatedSession session,
    String id,
    String type,
  ) {
    if (type.toUpperCase().contains('VIDEO')) {
      return [
        session.serverConfig.apiEndpoint('assets/$id/original').toString(),
        session.serverConfig
            .apiEndpoint('assets/$id/thumbnail')
            .replace(queryParameters: const {'size': 'preview'})
            .toString(),
        session.serverConfig
            .apiEndpoint('assets/$id/video/playback')
            .toString(),
      ];
    }

    return [
      session.serverConfig.apiEndpoint('assets/$id/original').toString(),
      session.serverConfig
          .apiEndpoint('assets/$id/thumbnail')
          .replace(queryParameters: const {'size': 'preview'})
          .toString(),
      session.serverConfig
          .apiEndpoint('assets/$id/thumbnail')
          .replace(queryParameters: const {'size': 'thumbnail'})
          .toString(),
    ];
  }
}
