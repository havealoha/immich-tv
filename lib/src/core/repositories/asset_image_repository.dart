import 'dart:typed_data';

abstract class AssetImageRepository {
  Future<Uint8List> fetchImageBytes({
    required List<String> urls,
    required String accessToken,
  });

  Future<void> prefetchImages({
    required List<List<String>> urls,
    required String accessToken,
  });
}
