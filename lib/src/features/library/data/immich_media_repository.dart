import 'package:dio/dio.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/models/album_summary.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/asset_summary.dart';
import '../../../core/network/immich_headers.dart';
import '../../../core/repositories/media_repository.dart';

class ImmichMediaRepository implements MediaRepository {
  ImmichMediaRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  @override
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session) async {
    final response = await _dio.get<List<dynamic>>(
      session.serverConfig.apiEndpoint('albums').toString(),
      options: Options(
        headers: ImmichHeaders.sessionToken(session.accessToken),
      ),
    );

    final items = response.data ?? const [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(_mapAlbum)
        .whereType<AlbumSummary>()
        .toList(growable: false);
  }

  @override
  Future<List<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session,
  ) async {
    logger.info('Fetching favorite assets for ${session.user.email}');
    final response = await _dio.post<dynamic>(
      session.serverConfig.apiEndpoint('search/metadata').toString(),
      data: {'isFavorite': true},
      options: Options(
        headers: {
          ...ImmichHeaders.sessionToken(session.accessToken),
          'Content-Type': 'application/json',
        },
      ),
    );

    final items = _extractAssetMaps(response.data);
    logger.info('Favorite assets payload returned ${items.length} items');
    return items
        .map((item) => _mapAsset(item, session))
        .whereType<AssetSummary>()
        .toList(growable: false);
  }

  @override
  Future<List<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session,
  ) async {
    logger.info('Fetching timeline photos for ${session.user.email}');
    final searchTimeline = await _fetchTimelineViaSearchMetadata(session);
    if (searchTimeline.isNotEmpty) {
      logger.info(
        'Timeline photo search returned ${searchTimeline.length} assets',
      );
      return searchTimeline;
    }

    logger.warning(
      'Timeline search returned no assets, falling back to timeline bucket API',
    );
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
      return const [];
    }

    final timeBucket = _extractTimeBucket(buckets.first);
    if (timeBucket == null || timeBucket.isEmpty) {
      return const [];
    }

    final detailResponse = await _dio.get<dynamic>(
      session.serverConfig.apiEndpoint('timeline/bucket').toString(),
      queryParameters: {...chosenQuery, 'timeBucket': timeBucket},
      options: Options(headers: headers),
    );

    final items = _extractAssetMaps(detailResponse.data);
    logger.info('Timeline bucket API returned ${items.length} assets');
    return items
        .map((item) => _mapAsset(item, session))
        .whereType<AssetSummary>()
        .toList(growable: false);
  }

  Future<List<AssetSummary>> _fetchTimelineViaSearchMetadata(
    AuthenticatedSession session,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        session.serverConfig.apiEndpoint('search/metadata').toString(),
        data: const {'size': 120, 'withArchived': false},
        options: Options(
          headers: {
            ...ImmichHeaders.sessionToken(session.accessToken),
            'Content-Type': 'application/json',
          },
        ),
      );

      final items = _extractAssetMaps(response.data);
      return items
          .map((item) => _mapAsset(item, session))
          .whereType<AssetSummary>()
          .where((asset) => !asset.isVideo)
          .toList(growable: false);
    } on DioException catch (error) {
      logger.warning(
        'Timeline photo search failed with ${error.response?.statusCode ?? error.type.name}',
      );
      return const [];
    }
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
    final urls = <String>[
      baseThumbnail
          .replace(queryParameters: const {'size': 'preview'})
          .toString(),
      baseThumbnail
          .replace(queryParameters: const {'size': 'thumbnail'})
          .toString(),
    ];

    if (!type.toUpperCase().contains('VIDEO')) {
      urls.add(
        session.serverConfig.apiEndpoint('assets/$id/original').toString(),
      );
    }

    return urls;
  }

  List<String> _buildDisplayUrls(
    AuthenticatedSession session,
    String id,
    String type,
  ) {
    if (type.toUpperCase().contains('VIDEO')) {
      return [
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
