part of 'home_screen.dart';

class _AlbumSectionView extends StatelessWidget {
  const _AlbumSectionView({
    required this.session,
    required this.status,
    required this.errorMessage,
    required this.albums,
    required this.isSidebarOpen,
    required this.menuToggleFocusNode,
    required this.onToggleSidebar,
  });

  final AuthenticatedSession session;
  final LibraryLoadStatus status;
  final String? errorMessage;
  final List<AlbumSummary> albums;
  final bool isSidebarOpen;
  final FocusNode menuToggleFocusNode;
  final VoidCallback onToggleSidebar;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Albums',
      description: 'Collection-first browsing in a clean left-nav shell.',
      isSidebarOpen: isSidebarOpen,
      menuToggleFocusNode: menuToggleFocusNode,
      onToggleSidebar: onToggleSidebar,
      child: _AlbumBrowser(
        session: session,
        status: status,
        errorMessage: errorMessage,
        albums: albums,
      ),
    );
  }
}

class _AlbumBrowser extends StatefulWidget {
  const _AlbumBrowser({
    required this.session,
    required this.status,
    required this.errorMessage,
    required this.albums,
  });

  final AuthenticatedSession session;
  final LibraryLoadStatus status;
  final String? errorMessage;
  final List<AlbumSummary> albums;

  @override
  State<_AlbumBrowser> createState() => _AlbumBrowserState();
}

class _AlbumBrowserState extends State<_AlbumBrowser> {
  AlbumSummary? _selectedAlbum;
  List<AssetSummary> _albumAssets = const [];
  String? _albumAssetsNextPage;
  bool _isLoadingAlbumAssets = false;
  String? _albumAssetsError;

  @override
  void didUpdateWidget(covariant _AlbumBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.albums.isEmpty) {
      _selectedAlbum = null;
      _albumAssets = const [];
      _albumAssetsNextPage = null;
      _albumAssetsError = null;
      _isLoadingAlbumAssets = false;
      return;
    }

    final selectedAlbumStillExists =
        _selectedAlbum != null &&
        widget.albums.any((album) => album.id == _selectedAlbum!.id);
    if (!selectedAlbumStillExists) {
      _selectAlbum(widget.albums.first);
    }
  }

  Widget _buildBody(BuildContext context) {
    if (widget.status == LibraryLoadStatus.loading) {
      return const _AlbumBrowserLoadingSkeleton();
    }

    if (widget.status == LibraryLoadStatus.failure) {
      return _InfoPanel(
        title: 'Albums are unavailable right now',
        body: widget.errorMessage ?? 'Try again in a moment.',
        accent: AppColors.error,
      );
    }

    if (widget.albums.isEmpty) {
      return const _InfoPanel(
        title: 'No albums yet',
        body: 'Album collections will appear here.',
        accent: AppColors.textMuted,
      );
    }

    final selectedAlbum = _selectedAlbum ?? widget.albums.first;

    if (_selectedAlbum == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectAlbum(widget.albums.first);
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = AppScale.of(context);
        final useStackedLayout = constraints.maxWidth < 980;
        final albumRail = _AlbumRail(
          albums: widget.albums,
          selectedAlbum: selectedAlbum,
          onAlbumSelected: _selectAlbum,
          horizontal: useStackedLayout,
        );
        final albumContent = _buildAlbumContent(selectedAlbum);

        if (useStackedLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: scale.sizeOf(172, min: 152, max: 172),
                child: albumRail,
              ),
              SizedBox(height: scale.space(AppSpacing.lg, min: 20, max: 24)),
              Expanded(child: albumContent),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(
              width: _responsiveAlbumRailWidth(constraints.maxWidth, scale),
              child: albumRail,
            ),
            SizedBox(width: scale.space(AppSpacing.xl, min: 24, max: 32)),
            Expanded(child: albumContent),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => _buildBody(context);

  void _selectAlbum(AlbumSummary album) {
    setState(() {
      _selectedAlbum = album;
      _albumAssets = const [];
      _albumAssetsNextPage = null;
      _albumAssetsError = null;
      _isLoadingAlbumAssets = false;
    });
    _loadAlbumAssets(album: album, page: null, replace: true);
  }

  Widget _buildAlbumContent(AlbumSummary selectedAlbum) {
    if (_isLoadingAlbumAssets && _albumAssets.isEmpty) {
      return const _AssetGridLoadingSkeleton(
        leadingHeight: 20,
        leadingWidth: 220,
      );
    }

    if (_albumAssetsError != null && _albumAssets.isEmpty) {
      return _InfoPanel(
        title: 'This album could not load',
        body: _albumAssetsError!,
        accent: AppColors.error,
      );
    }

    if (_albumAssets.isEmpty) {
      return _InfoPanel(
        title: 'No assets in ${selectedAlbum.name}',
        body:
            'This album does not contain any assets that can be displayed yet.',
        accent: AppColors.textMuted,
      );
    }

    return _AlbumAssetGrid(
      session: widget.session,
      album: selectedAlbum,
      assets: _albumAssets,
      hasMore: _albumAssetsNextPage != null && _albumAssetsNextPage!.isNotEmpty,
      isLoadingMore: _isLoadingAlbumAssets && _albumAssets.isNotEmpty,
      onLoadMore: _loadMoreAlbumAssets,
    );
  }

  Future<void> _loadMoreAlbumAssets() async {
    final selectedAlbum = _selectedAlbum;
    final nextPage = _albumAssetsNextPage;
    if (selectedAlbum == null || nextPage == null || _isLoadingAlbumAssets) {
      return;
    }

    await _loadAlbumAssets(
      album: selectedAlbum,
      page: nextPage,
      replace: false,
    );
  }

  Future<void> _loadAlbumAssets({
    required AlbumSummary album,
    required String? page,
    required bool replace,
  }) async {
    if (_isLoadingAlbumAssets) {
      return;
    }

    setState(() {
      _isLoadingAlbumAssets = true;
      _albumAssetsError = null;
    });

    try {
      final response = await context
          .read<MediaRepository>()
          .fetchAlbumAssetsPage(widget.session, albumId: album.id, page: page);
      if (!mounted || _selectedAlbum?.id != album.id) {
        return;
      }

      setState(() {
        _albumAssets = replace
            ? response.items
            : [
                ..._albumAssets,
                ..._dedupeAlbumAssets(_albumAssets, response.items),
              ];
        _albumAssetsNextPage = response.nextPage;
        _isLoadingAlbumAssets = false;
      });
    } catch (error) {
      if (!mounted || _selectedAlbum?.id != album.id) {
        return;
      }

      setState(() {
        _isLoadingAlbumAssets = false;
        _albumAssetsError = error is AppException
            ? error.message
            : 'We could not load this album right now.';
      });
    }
  }

  List<AssetSummary> _dedupeAlbumAssets(
    List<AssetSummary> existing,
    List<AssetSummary> incoming,
  ) {
    final existingIds = existing.map((item) => item.id).toSet();
    return incoming
        .where((item) => !existingIds.contains(item.id))
        .toList(growable: false);
  }
}

class _AlbumRail extends StatelessWidget {
  const _AlbumRail({
    required this.albums,
    required this.selectedAlbum,
    required this.onAlbumSelected,
    required this.horizontal,
  });

  final List<AlbumSummary> albums;
  final AlbumSummary selectedAlbum;
  final ValueChanged<AlbumSummary> onAlbumSelected;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);
    return ListView.separated(
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      itemCount: albums.length,
      separatorBuilder: (_, _) => SizedBox(
        width: horizontal ? scale.space(AppSpacing.sm, min: 10, max: 12) : 0,
        height: horizontal ? 0 : scale.space(AppSpacing.sm, min: 10, max: 12),
      ),
      itemBuilder: (context, index) {
        final album = albums[index];
        return SizedBox(
          width: horizontal ? scale.sizeOf(240, min: 220, max: 240) : null,
          child: _AlbumSummaryTile(
            album: album,
            isSelected: album.id == selectedAlbum.id,
            onPressed: () => onAlbumSelected(album),
          ),
        );
      },
    );
  }
}

class _AlbumSummaryTile extends StatefulWidget {
  const _AlbumSummaryTile({
    required this.album,
    required this.isSelected,
    required this.onPressed,
  });

  final AlbumSummary album;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  State<_AlbumSummaryTile> createState() => _AlbumSummaryTileState();
}

class _AlbumSummaryTileState extends State<_AlbumSummaryTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    return TvFocusable(
      onPressed: widget.onPressed,
      builder: (context, focusState) {
        final isActive = widget.isSelected || focusState.isActive;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(scale.space(AppSpacing.lg, min: 20, max: 24)),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF13212A) : const Color(0xFF0D1A21),
            borderRadius: BorderRadius.circular(
              scale.radius(AppRadii.lg, min: 20, max: 24),
            ),
            border: Border.all(
              color: widget.isSelected ? AppColors.focus : AppColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.album.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: scale.text(22, min: 18, max: 22),
                ),
              ),
              SizedBox(height: scale.space(AppSpacing.xs, min: 8, max: 8)),
              Text(
                '${widget.album.assetCount} assets',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: scale.text(14, min: 12, max: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AlbumAssetGrid extends StatelessWidget {
  const _AlbumAssetGrid({
    required this.session,
    required this.album,
    required this.assets,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final AuthenticatedSession session;
  final AlbumSummary album;
  final List<AssetSummary> assets;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          album.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: scale.text(28, min: 22, max: 28),
          ),
        ),
        SizedBox(height: scale.space(AppSpacing.xs, min: 8, max: 8)),
        Text(
          '${assets.length} assets',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            fontSize: scale.text(16, min: 14, max: 16),
          ),
        ),
        SizedBox(height: scale.space(AppSpacing.lg, min: 20, max: 24)),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (!hasMore || isLoadingMore) {
                return false;
              }

              final metrics = notification.metrics;
              if (metrics.pixels >= metrics.maxScrollExtent - 600) {
                onLoadMore();
              }

              return false;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  cacheExtent: 240,
                  gridDelegate: _buildAssetGridDelegate(constraints.maxWidth),
                  itemCount: assets.length + (hasMore || isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= assets.length) {
                      return _LoadMoreTile(
                        isLoading: isLoadingMore,
                        hasMore: hasMore,
                      );
                    }

                    final asset = assets[index];
                    return _AssetTile(
                      session: session,
                      asset: asset,
                      autofocus: index == 0,
                      prefetchUrls: _nearbyThumbnailUrls(assets, index),
                      onPressed: () => AssetViewerScreen.show(
                        context,
                        assets: assets,
                        initialIndex: index,
                        accessToken: session.accessToken,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
