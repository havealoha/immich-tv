import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../../core/models/immich_auth_method.dart';
import '../../../core/network/immich_headers.dart';
import '../../../core/repositories/asset_image_repository.dart';

class ImmichAssetImageRepository implements AssetImageRepository {
  ImmichAssetImageRepository();

  static const _maxPrefetchedEntries = 24;
  final Queue<_PrefetchedImageEntry> _prefetchedEntries =
      ListQueue<_PrefetchedImageEntry>();
  final Set<String> _inFlightUrls = <String>{};

  @override
  Future<void> prefetchImages({
    required List<List<String>> urls,
    required String accessToken,
    required ImmichAuthMethod authMethod,
  }) async {
    if (kIsWeb) {
      return;
    }

    for (final candidates in urls) {
      final url = candidates.isNotEmpty ? candidates.first.trim() : '';
      if (url.isEmpty || _inFlightUrls.contains(url)) {
        continue;
      }

      final provider = NetworkImage(
        url,
        headers: ImmichHeaders.mediaHeaders(
          token: accessToken,
          authMethod: authMethod,
        ),
      );
      _inFlightUrls.add(url);
      try {
        await _warmImage(provider);
        _prefetchedEntries.removeWhere((entry) => entry.url == url);
        _prefetchedEntries.addLast(
          _PrefetchedImageEntry(url: url, provider: provider),
        );
        await _trimPrefetchQueue();
      } catch (_) {
        // Best-effort prefetch only.
      } finally {
        _inFlightUrls.remove(url);
      }
    }
  }

  Future<void> _warmImage(ImageProvider<Object> provider) {
    final stream = provider.resolve(ImageConfiguration.empty);
    final completer = Completer<void>();
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (image, syncCall) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (error, stackTrace) {
        stream.removeListener(listener);
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );
    stream.addListener(listener);
    return completer.future;
  }

  Future<void> _trimPrefetchQueue() async {
    while (_prefetchedEntries.length > _maxPrefetchedEntries) {
      final evicted = _prefetchedEntries.removeFirst();
      await evicted.provider.evict(
        cache: PaintingBinding.instance.imageCache,
        configuration: ImageConfiguration.empty,
      );
    }
  }
}

class _PrefetchedImageEntry {
  const _PrefetchedImageEntry({required this.url, required this.provider});

  final String url;
  final ImageProvider<Object> provider;
}
