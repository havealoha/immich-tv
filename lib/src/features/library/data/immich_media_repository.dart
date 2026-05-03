import 'package:dio/dio.dart';

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
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return const [];
  }

  @override
  Future<List<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return const [];
  }

  @override
  Future<List<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session,
  ) async {
    final headers = ImmichHeaders.sessionToken(session.accessToken);
    final apiUrl = session.serverConfig.apiUrl;

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
          apiUrl.resolve('timeline/buckets').toString(),
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
      return const [];
    }

    final timeBucket = _extractTimeBucket(buckets.first);
    if (timeBucket == null || timeBucket.isEmpty) {
      return const [];
    }

    final detailResponse = await _dio.get<dynamic>(
      apiUrl.resolve('timeline/bucket').toString(),
      queryParameters: {...chosenQuery, 'timeBucket': timeBucket},
      options: Options(headers: headers),
    );

    final items = _extractAssetMaps(detailResponse.data);
    return items
        .map((item) => _mapAsset(item, session))
        .whereType<AssetSummary>()
        .toList(growable: false);
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
      final nested = payload['assets'] ?? payload['items'];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().toList(growable: false);
      }
    }

    return const [];
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
      thumbnailUrl: session.serverConfig.apiUrl
          .resolve('assets/$id/thumbnail')
          .toString(),
      type: type,
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
