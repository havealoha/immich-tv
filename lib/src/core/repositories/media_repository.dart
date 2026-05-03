import '../models/album_summary.dart';
import '../models/authenticated_session.dart';
import '../models/asset_summary.dart';
import '../models/media_page.dart';

abstract class MediaRepository {
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session);

  Future<MediaPage<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 60,
  });

  Future<MediaPage<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 60,
  });
}
