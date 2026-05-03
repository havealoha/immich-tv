import '../../../core/models/album_summary.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/asset_summary.dart';
import '../../../core/repositories/media_repository.dart';

class NoopMediaRepository implements MediaRepository {
  @override
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const [];
  }

  @override
  Future<List<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const [];
  }

  @override
  Future<List<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return const [];
  }
}
