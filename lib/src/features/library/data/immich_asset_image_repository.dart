import '../../../core/repositories/asset_image_repository.dart';

class ImmichAssetImageRepository implements AssetImageRepository {
  const ImmichAssetImageRepository();

  @override
  Future<void> prefetchImages({
    required List<List<String>> urls,
    required String accessToken,
  }) async {}
}
