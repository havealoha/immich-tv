import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../core/network/immich_dio_factory.dart';
import '../../core/network/immich_headers.dart';
import 'browser_blob_url.dart';

class WebAuthenticatedVideoCache {
  WebAuthenticatedVideoCache._();

  static final WebAuthenticatedVideoCache instance = WebAuthenticatedVideoCache._();

  static const int _maxEntries = 4;

  final Dio _dio = ImmichDioFactory.create();
  final Map<String, _CachedWebVideo> _cache = <String, _CachedWebVideo>{};
  final Map<String, Future<String>> _inFlight = <String, Future<String>>{};

  Future<String> getObjectUrl({
    required String sourceUrl,
    required String accessToken,
    void Function(int received, int total)? onReceiveProgress,
  }) {
    final key = _cacheKey(sourceUrl, accessToken);
    final cached = _cache[key];
    if (cached != null) {
      cached.lastAccessedAt = DateTime.now();
      onReceiveProgress?.call(cached.byteLength, cached.byteLength);
      return Future<String>.value(cached.objectUrl);
    }

    final activeRequest = _inFlight[key];
    if (activeRequest != null) {
      return activeRequest;
    }

    final request = _downloadObjectUrl(
      sourceUrl: sourceUrl,
      accessToken: accessToken,
      onReceiveProgress: onReceiveProgress,
    );
    _inFlight[key] = request;
    return request.whenComplete(() {
      _inFlight.remove(key);
    });
  }

  void clear() {
    for (final entry in _cache.values) {
      revokeBrowserBlobUrl(entry.objectUrl);
    }
    _cache.clear();
  }

  Future<String> _downloadObjectUrl({
    required String sourceUrl,
    required String accessToken,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    final response = await _dio.get<List<int>>(
      sourceUrl,
      options: Options(
        headers: ImmichHeaders.mediaSessionToken(accessToken),
        responseType: ResponseType.bytes,
      ),
      onReceiveProgress: onReceiveProgress,
    );

    final data = response.data;
    if (data == null || data.isEmpty) {
      throw const FormatException('No video bytes returned.');
    }

    final mimeType = response.headers.value(Headers.contentTypeHeader) ?? inferVideoMimeType(sourceUrl);
    final objectUrl = createBrowserBlobUrl(Uint8List.fromList(data), mimeType: mimeType);
    _cache[_cacheKey(sourceUrl, accessToken)] = _CachedWebVideo(
      objectUrl: objectUrl,
      byteLength: data.length,
      lastAccessedAt: DateTime.now(),
    );
    _trimCache();
    return objectUrl;
  }

  void _trimCache() {
    if (_cache.length <= _maxEntries) {
      return;
    }

    final entries = _cache.entries.toList()
      ..sort((left, right) => left.value.lastAccessedAt.compareTo(right.value.lastAccessedAt));

    while (_cache.length > _maxEntries && entries.isNotEmpty) {
      final oldest = entries.removeAt(0);
      final removed = _cache.remove(oldest.key);
      if (removed != null) {
        revokeBrowserBlobUrl(removed.objectUrl);
      }
    }
  }

  String _cacheKey(String sourceUrl, String accessToken) => '$sourceUrl::$accessToken';
}

class _CachedWebVideo {
  _CachedWebVideo({
    required this.objectUrl,
    required this.byteLength,
    required this.lastAccessedAt,
  });

  final String objectUrl;
  final int byteLength;
  DateTime lastAccessedAt;
}

String inferVideoMimeType(String playableUrl) {
  final uri = Uri.tryParse(playableUrl);
  final path = uri?.path.toLowerCase() ?? playableUrl.toLowerCase();

  if (path.endsWith('.webm')) {
    return 'video/webm';
  }
  if (path.endsWith('.mov')) {
    return 'video/quicktime';
  }
  if (path.endsWith('.m3u8')) {
    return 'application/vnd.apple.mpegurl';
  }

  return 'video/mp4';
}
