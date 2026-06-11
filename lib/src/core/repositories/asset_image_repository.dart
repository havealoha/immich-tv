import '../models/immich_auth_method.dart';

abstract class AssetImageRepository {
  Future<void> prefetchImages({
    required List<List<String>> urls,
    required String accessToken,
    required ImmichAuthMethod authMethod,
  });
}
