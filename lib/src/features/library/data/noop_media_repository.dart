import '../../../core/models/album_summary.dart';
import '../../../core/models/asset_summary.dart';
import '../../../core/repositories/media_repository.dart';

class NoopMediaRepository implements MediaRepository {
  @override
  Future<List<AlbumSummary>> fetchAlbums() async => const [];

  @override
  Future<List<AssetSummary>> fetchFavoritesPage() async => const [];

  @override
  Future<List<AssetSummary>> fetchTimelinePage() async => const [];
}
