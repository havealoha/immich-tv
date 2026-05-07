import '../models/album_summary.dart';
import '../models/authenticated_session.dart';
import '../models/asset_summary.dart';
import '../models/media_page.dart';

abstract class MediaRepository {
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session);

  Future<MediaPage<AssetSummary>> fetchAlbumAssetsPage(
    AuthenticatedSession session, {
    required String albumId,
    String? page,
    int pageSize = 120,
  });

  Future<MediaPage<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 30,
  });

  Future<MediaPage<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 30,
  });
}
