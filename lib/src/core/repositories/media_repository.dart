import '../models/album_summary.dart';
import '../models/asset_summary.dart';

abstract class MediaRepository {
  Future<List<AlbumSummary>> fetchAlbums();

  Future<List<AssetSummary>> fetchTimelinePage();

  Future<List<AssetSummary>> fetchFavoritesPage();
}
