part of 'home_screen.dart';

class _TimelineSectionView extends StatelessWidget {
  const _TimelineSectionView({
    required this.session,
    required this.title,
    required this.description,
    required this.selectedYear,
    required this.status,
    required this.errorMessage,
    required this.assets,
    required this.hasMore,
    required this.isLoadingMore,
    required this.emptyMessage,
  });

  final AuthenticatedSession session;
  final String title;
  final String description;
  final int selectedYear;
  final LibraryLoadStatus status;
  final String? errorMessage;
  final List<AssetSummary> assets;
  final bool hasMore;
  final bool isLoadingMore;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return _TimelineSectionFrame(
      title: title,
      description: description,
      years: _timelineYearRange(),
      selectedYear: selectedYear,
      onYearSelected: (year) =>
          context.read<LibraryCubit>().selectTimelineYear(year),
      child: _AnimatedSectionSwap(
        switchKey: 'timeline-$selectedYear-${_sectionViewState(status, assets)}',
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (status == LibraryLoadStatus.loading) {
      return const _TimelineLoadingSkeleton();
    }

    if (status == LibraryLoadStatus.failure) {
      return _InfoPanel(
        title: 'This section could not load',
        body: errorMessage ?? 'Try again in a moment.',
        accent: AppColors.error,
      );
    }

    if (assets.isEmpty) {
      return _InfoPanel(
        title: 'No assets in $selectedYear',
        body: 'There are no timeline assets available for this year yet.',
        accent: AppColors.textMuted,
      );
    }
    final groups = _groupTimelineAssets(assets);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!hasMore || isLoadingMore) {
          return false;
        }

        final metrics = notification.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - 600) {
          context.read<LibraryCubit>().loadMore();
        }

        return false;
      },
      child: ListView.builder(
        cacheExtent: 480,
        itemCount: groups.length + (hasMore || isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= groups.length) {
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: SizedBox(
                height: 180,
                child: _LoadMoreTile(
                  isLoading: isLoadingMore,
                  hasMore: hasMore,
                ),
              ),
            );
          }

          final group = groups[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == groups.length - 1 ? 0 : AppSpacing.xl,
            ),
            child: _TimelineDaySection(
              session: session,
              group: group,
              allAssets: assets,
            ),
          );
        },
      ),
    );
  }
}

class _AssetSectionView extends StatelessWidget {
  const _AssetSectionView({
    required this.session,
    required this.title,
    required this.description,
    required this.status,
    required this.errorMessage,
    required this.assets,
    required this.hasMore,
    required this.isLoadingMore,
    required this.emptyMessage,
  });

  final AuthenticatedSession session;
  final String title;
  final String description;
  final LibraryLoadStatus status;
  final String? errorMessage;
  final List<AssetSummary> assets;
  final bool hasMore;
  final bool isLoadingMore;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: title,
      description: description,
      child: _AnimatedSectionSwap(
        switchKey: 'assets-$title-${_sectionViewState(status, assets)}',
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (status == LibraryLoadStatus.loading) {
      return const _AssetGridLoadingSkeleton();
    }

    if (status == LibraryLoadStatus.failure) {
      return _InfoPanel(
        title: 'This section could not load',
        body: errorMessage ?? 'Try again in a moment.',
        accent: AppColors.error,
      );
    }

    if (assets.isEmpty) {
      return _InfoPanel(
        title: 'Nothing here yet',
        body: emptyMessage,
        accent: AppColors.textMuted,
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!hasMore || isLoadingMore) {
          return false;
        }

        final metrics = notification.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - 600) {
          context.read<LibraryCubit>().loadMore();
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
    );
  }
}

class _TimelineDaySection extends StatelessWidget {
  const _TimelineDaySection({
    required this.session,
    required this.group,
    required this.allAssets,
  });

  final AuthenticatedSession session;
  final _TimelineDayGroup group;
  final List<AssetSummary> allAssets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatTimelineDay(group.day),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: scale.text(28, min: 22, max: 28),
              ),
            ),
            SizedBox(height: scale.space(AppSpacing.md, min: 12, max: 16)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              cacheExtent: 240,
              gridDelegate: _buildAssetGridDelegate(constraints.maxWidth),
              itemCount: group.items.length,
              itemBuilder: (context, index) {
                final item = group.items[index];
                return _AssetTile(
                  session: session,
                  asset: item.asset,
                  autofocus: item.globalIndex == 0,
                  prefetchUrls: _nearbyThumbnailUrls(
                    allAssets,
                    item.globalIndex,
                  ),
                  onPressed: () => AssetViewerScreen.show(
                    context,
                    assets: allAssets,
                    initialIndex: item.globalIndex,
                    accessToken: session.accessToken,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _AssetTile extends StatefulWidget {
  const _AssetTile({
    required this.session,
    required this.asset,
    required this.autofocus,
    required this.prefetchUrls,
    required this.onPressed,
  });

  final AuthenticatedSession session;
  final AssetSummary asset;
  final bool autofocus;
  final List<List<String>> prefetchUrls;
  final VoidCallback onPressed;

  @override
  State<_AssetTile> createState() => _AssetTileState();
}

class _AssetTileState extends State<_AssetTile> {
  String? _lastPrefetchKey;

  @override
  void didUpdateWidget(covariant _AssetTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _lastPrefetchKey = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    return TvFocusable(
      autofocus: widget.autofocus,
      onPressed: widget.onPressed,
      onFocusChange: (isFocused) {
        if (isFocused) {
          _prefetchNearbyThumbnails();
        }
      },
      builder: (context, focusState) {
        final isActive = focusState.isActive;

        return AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: isActive ? 0.985 : 1,
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                AuthenticatedAssetImage(
                  imageUrls: widget.asset.thumbnailUrls,
                  accessToken: widget.session.accessToken,
                  requiresAuth: widget.asset.requiresAuth,
                  heroTag: 'asset-${widget.asset.id}',
                  placeholderIcon: widget.asset.isVideo
                      ? Icons.smart_display_outlined
                      : Icons.photo_outlined,
                  filterQuality: FilterQuality.none,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: focusState.isFocused
                          ? AppColors.focus
                          : Colors.transparent,
                      width: scale.sizeOf(2, min: 1.5, max: 2),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(
                            alpha: isActive ? 0.68 : 0.54,
                          ),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                if (widget.asset.isVideo)
                  const Positioned.fill(
                    child: IgnorePointer(child: Center(child: _VideoBadge())),
                  ),
                Positioned(
                  left: scale.space(AppSpacing.sm, min: 10, max: 12),
                  right: scale.space(AppSpacing.sm, min: 10, max: 12),
                  bottom: scale.space(AppSpacing.sm, min: 10, max: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asset ${widget.asset.id}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: scale.text(15, min: 13, max: 15),
                        ),
                      ),
                      SizedBox(height: scale.space(2, min: 2, max: 2)),
                      Text(
                        _formatDate(widget.asset.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: scale.text(12, min: 11, max: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _prefetchNearbyThumbnails() {
    if (widget.prefetchUrls.isEmpty) {
      return;
    }

    final prefetchKey = widget.prefetchUrls
        .map((urls) => urls.isNotEmpty ? urls.first : '')
        .join('|');
    if (_lastPrefetchKey == prefetchKey) {
      return;
    }

    _lastPrefetchKey = prefetchKey;
    context.read<AssetImageRepository>().prefetchImages(
      urls: widget.prefetchUrls,
      accessToken: widget.session.accessToken,
    );
  }
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge();

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: EdgeInsets.all(scale.space(AppSpacing.md, min: 12, max: 16)),
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: scale.sizeOf(32, min: 26, max: 32),
        ),
      ),
    );
  }
}

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile({required this.isLoading, required this.hasMore});

  final bool isLoading;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    return Container(
      color: const Color(0xFF0D1A21),
      padding: EdgeInsets.all(scale.space(AppSpacing.md, min: 14, max: 16)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: scale.sizeOf(24, min: 22, max: 24),
              height: scale.sizeOf(24, min: 22, max: 24),
              child: const CircularProgressIndicator(strokeWidth: 2.4),
            )
          else
            Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textMuted,
              size: scale.sizeOf(28, min: 24, max: 28),
            ),
          SizedBox(height: scale.space(AppSpacing.sm, min: 10, max: 12)),
          Text(
            isLoading ? 'Loading more photos' : 'More photos ahead',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: scale.text(16, min: 14, max: 16),
            ),
          ),
          SizedBox(height: scale.space(4, min: 4, max: 4)),
          Text(
            hasMore ? 'Keep scrolling' : 'End of section',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontSize: scale.text(12, min: 11, max: 12),
            ),
          ),
        ],
      ),
    );
  }
}
