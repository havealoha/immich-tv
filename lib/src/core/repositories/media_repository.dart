import '../models/album_summary.dart';
import '../models/authenticated_session.dart';
import '../models/asset_summary.dart';

abstract class MediaRepository {
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session);

  Future<List<AssetSummary>> fetchTimelinePage(AuthenticatedSession session);

  Future<List<AssetSummary>> fetchFavoritesPage(AuthenticatedSession session);
}
