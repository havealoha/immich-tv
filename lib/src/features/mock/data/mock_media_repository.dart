import '../../../core/models/album_summary.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/asset_summary.dart';
import '../../../core/models/media_page.dart';
import '../../../core/repositories/media_repository.dart';

class MockMediaRepository implements MediaRepository {
  MockMediaRepository()
    : _timeline = _buildTimeline(),
      _favorites = _buildFavorites();

  final List<AssetSummary> _timeline;
  final List<AssetSummary> _favorites;

  static const _pageSizeDefault = 60;

  @override
  Future<List<AlbumSummary>> fetchAlbums(AuthenticatedSession session) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    return _buildAlbums();
  }

  @override
  Future<MediaPage<AssetSummary>> fetchFavoritesPage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = _pageSizeDefault,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    return _pageAssets(_favorites, page: page, pageSize: pageSize);
  }

  @override
  Future<MediaPage<AssetSummary>> fetchTimelinePage(
    AuthenticatedSession session, {
    String? page,
    int pageSize = _pageSizeDefault,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 340));
    return _pageAssets(_timeline, page: page, pageSize: pageSize);
  }

  MediaPage<AssetSummary> _pageAssets(
    List<AssetSummary> items, {
    required String? page,
    required int pageSize,
  }) {
    final pageIndex = int.tryParse(page ?? '1') ?? 1;
    final start = (pageIndex - 1) * pageSize;
    if (start >= items.length) {
      return const MediaPage(items: []);
    }

    final end = (start + pageSize).clamp(0, items.length);
    final nextPage = end < items.length ? '${pageIndex + 1}' : null;

    return MediaPage(items: items.sublist(start, end), nextPage: nextPage);
  }
}

List<AssetSummary> _buildTimeline() {
  final items = <AssetSummary>[];
  final start = DateTime(2025, 4, 28, 18);
  final palettes = [
    ('sea-glass', 'Lagoon'),
    ('sunrise', 'Warm Dawn'),
    ('dusk', 'Quiet Blue'),
    ('citrus', 'Citrus'),
    ('ember', 'Ember'),
    ('forest', 'Canopy'),
  ];

  for (var index = 0; index < 180; index++) {
    final createdAt = start.subtract(Duration(hours: index * 7));
    final palette = palettes[index % palettes.length];
    final id = 'mock-asset-${index + 1}';
    items.add(
      AssetSummary(
        id: id,
        thumbnailUrls: [
          'mock://asset/$id?palette=${palette.$1}&variant=thumbnail',
        ],
        displayUrls: ['mock://asset/$id?palette=${palette.$1}&variant=display'],
        type: 'IMAGE',
        createdAt: createdAt,
      ),
    );
  }

  return items;
}

List<AssetSummary> _buildFavorites() {
  final timeline = _buildTimeline();
  return timeline
      .where((asset) => int.parse(asset.id.split('-').last) % 7 == 0)
      .take(24)
      .toList(growable: false);
}

List<AlbumSummary> _buildAlbums() {
  return const [
    AlbumSummary(id: 'album-1', name: 'Summer by the Coast', assetCount: 184),
    AlbumSummary(id: 'album-2', name: 'Family Weekend', assetCount: 96),
    AlbumSummary(id: 'album-3', name: 'Kitchen Experiments', assetCount: 58),
    AlbumSummary(id: 'album-4', name: 'City Walks at Night', assetCount: 132),
    AlbumSummary(id: 'album-5', name: 'Mountains and Cabins', assetCount: 73),
    AlbumSummary(id: 'album-6', name: 'Portrait Favorites', assetCount: 41),
  ];
}
