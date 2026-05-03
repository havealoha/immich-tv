import '../../../core/models/album_summary.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/asset_summary.dart';
import '../../../core/models/media_page.dart';
import '../../../core/repositories/media_repository.dart';

class NoopMediaRepository implements MediaRepository {
  @override
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const [];
  }

  @override
  Future<MediaPage<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 60,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const MediaPage(items: []);
  }

  @override
  Future<MediaPage<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = 60,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const MediaPage(items: []);
  }
}
