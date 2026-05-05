abstract class AssetImageRepository {
  Future<void> prefetchImages({
    required List<List<String>> urls,
    required String accessToken,
  });
}
