import 'dart:collection';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../core/network/immich_headers.dart';
import '../../../core/repositories/asset_image_repository.dart';

class ImmichAssetImageRepository implements AssetImageRepository {
  ImmichAssetImageRepository({required Dio dio, this.maxEntries = 160})
    : _dio = dio;

  final Dio _dio;
  final int maxEntries;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();
  final Map<String, Future<Uint8List>> _inflight = {};

  @override
  Future<Uint8List> fetchImageBytes({
    required List<String> urls,
    required String accessToken,
  }) {
    final normalizedUrls = urls
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: false);
    if (normalizedUrls.isEmpty) {
      return Future.error(
        StateError('No media URLs were provided for the asset image request.'),
      );
    }

    final cacheKey = _cacheKey(normalizedUrls, accessToken);
    final cached = _cache.remove(cacheKey);
    if (cached != null) {
      _cache[cacheKey] = cached;
      return Future.value(cached);
    }

    final pending = _inflight[cacheKey];
    if (pending != null) {
      return pending;
    }

    final future = _loadBytes(
      urls: normalizedUrls,
      accessToken: accessToken,
      cacheKey: cacheKey,
    );
    _inflight[cacheKey] = future;
    return future;
  }

  @override
  Future<void> prefetchImages({
    required List<List<String>> urls,
    required String accessToken,
  }) async {
    for (final imageUrls in urls.take(4)) {
      await fetchImageBytes(
        urls: imageUrls,
        accessToken: accessToken,
      ).catchError((_) => Uint8List(0));
    }
  }

  Future<Uint8List> _loadBytes({
    required List<String> urls,
    required String accessToken,
    required String cacheKey,
  }) async {
    try {
      Object? lastError;

      for (final url in urls) {
        try {
          final response = await _dio.get<dynamic>(
            url,
            options: Options(
              responseType: ResponseType.bytes,
              headers: ImmichHeaders.mediaSessionToken(accessToken),
            ),
          );

          final bytes = _normalizeBytes(response.data);
          if (bytes.isEmpty) {
            continue;
          }

          _cache[cacheKey] = bytes;
          _trimCache();
          return bytes;
        } on DioException catch (error) {
          final statusCode = error.response?.statusCode;
          if (statusCode == 404 || statusCode == 400) {
            lastError = error;
            continue;
          }

          rethrow;
        } on StateError catch (error) {
          lastError = error;
        }
      }

      if (lastError != null) {
        throw lastError;
      }

      throw StateError('No image bytes were returned for the provided URLs.');
    } finally {
      _inflight.remove(cacheKey);
    }
  }

  Uint8List _normalizeBytes(dynamic data) {
    if (data is Uint8List) {
      return data;
    }

    if (data is List<int>) {
      return Uint8List.fromList(data);
    }

    throw StateError('Unexpected media response type: ${data.runtimeType}');
  }

  String _cacheKey(List<String> urls, String accessToken) {
    return '${accessToken.hashCode}:${urls.join('|')}';
  }

  void _trimCache() {
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}
