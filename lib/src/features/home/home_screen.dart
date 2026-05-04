import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/album_summary.dart';
import '../../core/models/asset_summary.dart';
import '../../core/models/authenticated_session.dart';
import '../../core/repositories/asset_image_repository.dart';
import '../../core/repositories/media_repository.dart';
import '../../shared/presentation/app_breakpoints.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/authenticated_asset_image.dart';
import '../../shared/presentation/widgets/tv_focusable.dart';
import '../app_flow/cubit/app_flow_cubit.dart';
import '../library/cubit/library_cubit.dart';
import '../library/cubit/library_state.dart';
import '../slideshow/slideshow_player_screen.dart';
import '../viewer/asset_viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.session});

  final AuthenticatedSession session;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LibraryCubit(context.read<MediaRepository>(), session)..loadInitial(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: BlocListener<LibraryCubit, LibraryState>(
            listenWhen: (previous, current) =>
                previous.selectedTab != current.selectedTab ||
                previous.status != current.status,
            listener: (context, state) {
              if (state.status != LibraryLoadStatus.success) {
                return;
              }

              final urls = switch (state.selectedTab) {
                LibraryTab.timeline =>
                  state.timeline
                      .map((asset) => asset.thumbnailUrls)
                      .toList(growable: false),
                LibraryTab.favorites =>
                  state.favorites
                      .map((asset) => asset.thumbnailUrls)
                      .toList(growable: false),
                LibraryTab.albums ||
                LibraryTab.slideshow => const <List<String>>[],
              };

              if (urls.isEmpty) {
                return;
              }

              context.read<AssetImageRepository>().prefetchImages(
                urls: urls,
                accessToken: session.accessToken,
              );
            },
            child: BlocBuilder<LibraryCubit, LibraryState>(
              builder: (context, state) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final sidebarWidth = _responsiveSidebarWidth(
                      constraints.maxWidth,
                    );

                    return Row(
                      children: [
                        _Sidebar(
                          session: session,
                          state: state,
                          width: sidebarWidth,
                        ),
                        Expanded(
                          child: _ContentPane(session: session, state: state),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.session,
    required this.state,
    required this.width,
  });

  final AuthenticatedSession session;
  final LibraryState state;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 24),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
        gradient: LinearGradient(
          colors: [Color(0xFF0A141A), Color(0xFF0B171D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Immich TV',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(session: session),
                  const SizedBox(height: AppSpacing.xl),
                  _SidebarMenuButton(
                    label: 'Timeline',
                    subtitle: 'All photos',
                    icon: Icons.grid_view_rounded,
                    isSelected: state.selectedTab == LibraryTab.timeline,
                    onPressed: () => context.read<LibraryCubit>().selectTab(
                      LibraryTab.timeline,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SidebarMenuButton(
                    label: 'Albums',
                    subtitle: 'Curated collections',
                    icon: Icons.photo_album_outlined,
                    isSelected: state.selectedTab == LibraryTab.albums,
                    onPressed: () => context.read<LibraryCubit>().selectTab(
                      LibraryTab.albums,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SidebarMenuButton(
                    label: 'Favorites',
                    subtitle: 'Saved highlights',
                    icon: Icons.favorite_border,
                    isSelected: state.selectedTab == LibraryTab.favorites,
                    onPressed: () => context.read<LibraryCubit>().selectTab(
                      LibraryTab.favorites,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SidebarMenuButton(
                    label: 'Slideshow',
                    subtitle: 'Ambient playback',
                    icon: Icons.slideshow_outlined,
                    isSelected: state.selectedTab == LibraryTab.slideshow,
                    onPressed: () => context.read<LibraryCubit>().selectTab(
                      LibraryTab.slideshow,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Connected to ${session.serverConfig.serverUrl}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () => context.read<AppFlowCubit>().signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 0,
                vertical: AppSpacing.sm,
              ),
              foregroundColor: Colors.white,
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.session});

  final AuthenticatedSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = session.user.name.trim().isEmpty
        ? session.user.email
        : session.user.name;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .take(2)
        .map((segment) => segment.characters.first.toUpperCase())
        .join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.focus,
          foregroundColor: AppColors.actionForeground,
          child: Text(
            initials.isEmpty ? 'U' : initials,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          session.user.email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _SidebarMenuButton extends StatefulWidget {
  const _SidebarMenuButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    this.autofocus = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_SidebarMenuButton> createState() => _SidebarMenuButtonState();
}

class _SidebarMenuButtonState extends State<_SidebarMenuButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocusable(
      autofocus: widget.autofocus,
      onPressed: widget.onPressed,
      builder: (context, focusState) {
        final isActive = widget.isSelected || focusState.isActive;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF111F26) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: widget.isSelected ? AppColors.focus : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: isActive ? Colors.white : AppColors.textMuted,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isActive ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContentPane extends StatelessWidget {
  const _ContentPane({required this.session, required this.state});

  final AuthenticatedSession session;
  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth >= AppBreakpoints.tv
            ? 36.0
            : 28.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            20,
            horizontalPadding,
            20,
          ),
          child: _LibraryContent(state: state, session: session),
        );
      },
    );
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({required this.state, required this.session});

  final LibraryState state;
  final AuthenticatedSession session;

  @override
  Widget build(BuildContext context) {
    return switch (state.selectedTab) {
      LibraryTab.timeline => _AssetSectionView(
        session: session,
        title: 'Timeline',
        description: 'A flat explore view of your photo library.',
        status: state.status,
        errorMessage: state.errorMessage,
        assets: state.timeline,
        hasMore: state.hasMoreTimeline,
        isLoadingMore: state.isLoadingMore,
        emptyMessage: 'No timeline assets are available yet.',
      ),
      LibraryTab.albums => _AlbumSectionView(
        session: session,
        status: state.status,
        errorMessage: state.errorMessage,
        albums: state.albums,
      ),
      LibraryTab.favorites => _AssetSectionView(
        session: session,
        title: 'Favorites',
        description: 'Your strongest saved photos in a clean grid.',
        status: state.status,
        errorMessage: state.errorMessage,
        assets: state.favorites,
        hasMore: state.hasMoreFavorites,
        isLoadingMore: state.isLoadingMore,
        emptyMessage: 'No favorite assets are available yet.',
      ),
      LibraryTab.slideshow => _SlideshowSectionView(
        session: session,
        state: state,
      ),
    };
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
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (status == LibraryLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
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
            cacheExtent: 720,
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

class _AssetTile extends StatefulWidget {
  const _AssetTile({
    required this.session,
    required this.asset,
    required this.autofocus,
    required this.onPressed,
  });

  final AuthenticatedSession session;
  final AssetSummary asset;
  final bool autofocus;
  final VoidCallback onPressed;

  @override
  State<_AssetTile> createState() => _AssetTileState();
}

class _AssetTileState extends State<_AssetTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocusable(
      autofocus: widget.autofocus,
      onPressed: widget.onPressed,
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
                  filterQuality: FilterQuality.low,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: focusState.isFocused
                          ? AppColors.focus
                          : Colors.transparent,
                      width: 2,
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
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
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
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(widget.asset.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
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
}

class _VideoBadge extends StatelessWidget {
  const _VideoBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.48),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
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
    return Container(
      color: const Color(0xFF0D1A21),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          else
            const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.textMuted,
              size: 28,
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isLoading ? 'Loading more photos' : 'More photos ahead',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasMore ? 'Keep scrolling' : 'End of section',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumSectionView extends StatelessWidget {
  const _AlbumSectionView({
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
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Albums',
      description: 'Collection-first browsing in a clean left-nav shell.',
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
  Future<List<AssetSummary>>? _albumAssetsFuture;

  @override
  void didUpdateWidget(covariant _AlbumBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.albums.isEmpty) {
      _selectedAlbum = null;
      _albumAssetsFuture = null;
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
      return const Center(child: CircularProgressIndicator());
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
    final albumAssetsFuture =
        _albumAssetsFuture ??
        context.read<MediaRepository>().fetchAlbumAssets(
          widget.session,
          albumId: selectedAlbum.id,
        );

    if (_selectedAlbum == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectAlbum(widget.albums.first);
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout = constraints.maxWidth < 980;
        final albumRail = _AlbumRail(
          albums: widget.albums,
          selectedAlbum: selectedAlbum,
          onAlbumSelected: _selectAlbum,
          horizontal: useStackedLayout,
        );
        final albumContent = FutureBuilder<List<AssetSummary>>(
          future: albumAssetsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }

            final assets = snapshot.data ?? const <AssetSummary>[];
            if (assets.isEmpty) {
              return _InfoPanel(
                title: 'No photos in ${selectedAlbum.name}',
                body:
                    'This album does not contain any photo assets that can be displayed yet.',
                accent: AppColors.textMuted,
              );
            }

            return _AlbumAssetGrid(
              session: widget.session,
              album: selectedAlbum,
              assets: assets,
            );
          },
        );

        if (useStackedLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 172, child: albumRail),
              const SizedBox(height: AppSpacing.lg),
              Expanded(child: albumContent),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(
              width: _responsiveAlbumRailWidth(constraints.maxWidth),
              child: albumRail,
            ),
            const SizedBox(width: AppSpacing.xl),
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
      _albumAssetsFuture = context.read<MediaRepository>().fetchAlbumAssets(
        widget.session,
        albumId: album.id,
      );
    });
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
    return ListView.separated(
      scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
      itemCount: albums.length,
      separatorBuilder: (_, _) => SizedBox(
        width: horizontal ? AppSpacing.sm : 0,
        height: horizontal ? 0 : AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final album = albums[index];
        return SizedBox(
          width: horizontal ? 240 : null,
          // height: horizontal ? null : 140,
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
    return TvFocusable(
      onPressed: widget.onPressed,
      builder: (context, focusState) {
        final isActive = widget.isSelected || focusState.isActive;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF13212A) : const Color(0xFF0D1A21),
            borderRadius: BorderRadius.circular(AppRadii.lg),
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
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${widget.album.assetCount} assets',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
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
  });

  final AuthenticatedSession session;
  final AlbumSummary album;
  final List<AssetSummary> assets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          album.name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${assets.length} photos',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                cacheExtent: 720,
                gridDelegate: _buildAssetGridDelegate(constraints.maxWidth),
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return _AssetTile(
                    session: session,
                    asset: asset,
                    autofocus: index == 0,
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
      ],
    );
  }
}

enum _SlideshowSource { timeline, favorites, albums }

class _SlideshowSectionView extends StatefulWidget {
  const _SlideshowSectionView({required this.session, required this.state});

  final AuthenticatedSession session;
  final LibraryState state;

  @override
  State<_SlideshowSectionView> createState() => _SlideshowSectionViewState();
}

class _SlideshowSectionViewState extends State<_SlideshowSectionView> {
  _SlideshowSource _source = _SlideshowSource.timeline;
  int _durationSeconds = 5;
  bool _shuffle = false;
  Future<List<AlbumSummary>>? _albumsFuture;
  Future<List<AssetSummary>>? _albumAssetsFuture;
  AlbumSummary? _selectedAlbum;

  @override
  void initState() {
    super.initState();
    _albumsFuture = context.read<MediaRepository>().fetchAlbums(widget.session);
  }

  @override
  Widget build(BuildContext context) {
    final timelinePhotos = widget.state.timeline
        .where((asset) => !asset.isVideo)
        .toList(growable: false);
    final favoritePhotos = widget.state.favorites
        .where((asset) => !asset.isVideo)
        .toList(growable: false);
    final sourceAssets = _source == _SlideshowSource.timeline
        ? timelinePhotos
        : _source == _SlideshowSource.favorites
        ? favoritePhotos
        : const <AssetSummary>[];

    return _SectionFrame(
      title: 'Slideshow',
      description:
          'Start an ambient playback session from your photo stream with screen-safe controls.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useStackedLayout = constraints.maxWidth < 860;

          final controls = _SlideshowControlsPanel(
            source: _source,
            durationSeconds: _durationSeconds,
            shuffle: _shuffle,
            timelineCount: timelinePhotos.length,
            favoritesCount: favoritePhotos.length,
            albumsCount: widget.state.albums.length,
            onSourceSelected: (source) {
              setState(() => _source = source);
            },
            onDurationSelected: (seconds) {
              setState(() => _durationSeconds = seconds);
            },
            onShuffleChanged: (value) {
              setState(() => _shuffle = value);
            },
          );

          final content = _source == _SlideshowSource.albums
              ? _AlbumSlideshowSourceView(
                  session: widget.session,
                  albumsFuture: _albumsFuture!,
                  selectedAlbum: _selectedAlbum,
                  albumAssetsFuture: _albumAssetsFuture,
                  durationSeconds: _durationSeconds,
                  shuffle: _shuffle,
                  accessToken: widget.session.accessToken,
                  onAlbumSelected: _selectAlbum,
                  onStart: (assets) {
                    SlideshowPlayerScreen.show(
                      context,
                      assets: assets,
                      accessToken: widget.session.accessToken,
                      initialDurationSeconds: _durationSeconds,
                      shuffle: _shuffle,
                    );
                  },
                )
              : _PhotoSlideshowPreview(
                  title: _source == _SlideshowSource.timeline
                      ? 'Timeline'
                      : 'Favorites',
                  assets: sourceAssets,
                  shuffle: _shuffle,
                  accessToken: widget.session.accessToken,
                  onStart: () {
                    SlideshowPlayerScreen.show(
                      context,
                      assets: sourceAssets,
                      accessToken: widget.session.accessToken,
                      initialDurationSeconds: _durationSeconds,
                      shuffle: _shuffle,
                    );
                  },
                );

          if (useStackedLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                controls,
                const SizedBox(height: AppSpacing.xl),
                Expanded(child: content),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 360, child: controls),
              const SizedBox(width: AppSpacing.xl),
              Expanded(child: content),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectAlbum(AlbumSummary album) async {
    setState(() {
      _selectedAlbum = album;
      _albumAssetsFuture = context.read<MediaRepository>().fetchAlbumAssets(
        widget.session,
        albumId: album.id,
      );
    });
  }
}

class _SlideshowSourceChip extends StatelessWidget {
  const _SlideshowSourceChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onPressed,
    this.isEnabled = true,
  });

  final String label;
  final int count;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return _TvChoiceTile(
      title: label,
      subtitle: '$count photos',
      badge: '$label • $count',
      icon: label == 'Timeline'
          ? Icons.grid_view_rounded
          : label == 'Favorites'
          ? Icons.favorite_rounded
          : Icons.photo_album_outlined,
      isSelected: isSelected,
      isEnabled: isEnabled,
      onPressed: onPressed,
    );
  }
}

class _SlideshowControlsPanel extends StatelessWidget {
  const _SlideshowControlsPanel({
    required this.source,
    required this.durationSeconds,
    required this.shuffle,
    required this.timelineCount,
    required this.favoritesCount,
    required this.albumsCount,
    required this.onSourceSelected,
    required this.onDurationSelected,
    required this.onShuffleChanged,
  });

  final _SlideshowSource source;
  final int durationSeconds;
  final bool shuffle;
  final int timelineCount;
  final int favoritesCount;
  final int albumsCount;
  final ValueChanged<_SlideshowSource> onSourceSelected;
  final ValueChanged<int> onDurationSelected;
  final ValueChanged<bool> onShuffleChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Source',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _SlideshowSourceChip(
            label: 'Timeline',
            count: timelineCount,
            isSelected: source == _SlideshowSource.timeline,
            onPressed: () => onSourceSelected(_SlideshowSource.timeline),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SlideshowSourceChip(
            label: 'Favorites',
            count: favoritesCount,
            isSelected: source == _SlideshowSource.favorites,
            isEnabled: favoritesCount > 0,
            onPressed: () => onSourceSelected(_SlideshowSource.favorites),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SlideshowSourceChip(
            label: 'Albums',
            count: albumsCount,
            isSelected: source == _SlideshowSource.albums,
            isEnabled: albumsCount > 0,
            onPressed: () => onSourceSelected(_SlideshowSource.albums),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Playback',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final seconds in const [3, 5, 8, 12])
                _TvPillOption(
                  label: '${seconds}s',
                  isSelected: durationSeconds == seconds,
                  onPressed: () => onDurationSelected(seconds),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _TvChoiceTile(
            title: 'Shuffle',
            subtitle: shuffle
                ? 'Playback starts in a mixed order.'
                : 'Playback keeps the current order.',
            badge: shuffle ? 'Shuffle on' : 'Shuffle off',
            icon: Icons.shuffle_rounded,
            isSelected: shuffle,
            onPressed: () => onShuffleChanged(!shuffle),
          ),
        ],
      ),
    );
  }
}

class _PhotoSlideshowPreview extends StatelessWidget {
  const _PhotoSlideshowPreview({
    required this.title,
    required this.assets,
    required this.shuffle,
    required this.accessToken,
    required this.onStart,
  });

  final String title;
  final List<AssetSummary> assets;
  final bool shuffle;
  final String accessToken;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (assets.isEmpty) {
      return const _InfoPanel(
        title: 'No photos ready for slideshow',
        body:
            'Slideshow currently uses photo assets only. Open Timeline or Favorites first if you want to load more sources.',
        accent: AppColors.textMuted,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A21),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title • ${assets.length} photos ready',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              shuffle
                  ? 'Playback starts in a shuffled order.'
                  : 'Playback starts in your current library order.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AuthenticatedAssetImage(
                      imageUrls: assets.first.displayUrls,
                      accessToken: accessToken,
                      requiresAuth: assets.first.requiresAuth,
                      borderRadius: AppRadii.xl,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  SizedBox(
                    width: 160,
                    child: Column(
                      children: [
                        for (final asset in assets.take(4))
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: AuthenticatedAssetImage(
                                imageUrls: asset.thumbnailUrls,
                                accessToken: accessToken,
                                requiresAuth: asset.requiresAuth,
                                borderRadius: 20,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.low,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                minimumSize: const Size(260, 60),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start slideshow'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumSlideshowSourceView extends StatelessWidget {
  const _AlbumSlideshowSourceView({
    required this.session,
    required this.albumsFuture,
    required this.selectedAlbum,
    required this.albumAssetsFuture,
    required this.durationSeconds,
    required this.shuffle,
    required this.accessToken,
    required this.onAlbumSelected,
    required this.onStart,
  });

  final AuthenticatedSession session;
  final Future<List<AlbumSummary>> albumsFuture;
  final AlbumSummary? selectedAlbum;
  final Future<List<AssetSummary>>? albumAssetsFuture;
  final int durationSeconds;
  final bool shuffle;
  final String accessToken;
  final ValueChanged<AlbumSummary> onAlbumSelected;
  final ValueChanged<List<AssetSummary>> onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<AlbumSummary>>(
      future: albumsFuture,
      builder: (context, albumSnapshot) {
        if (albumSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final albums = albumSnapshot.data ?? const <AlbumSummary>[];
        if (albums.isEmpty) {
          return const _InfoPanel(
            title: 'No albums available',
            body: 'Albums will appear here once they are available.',
            accent: AppColors.textMuted,
          );
        }

        final selectedAlbumValue = selectedAlbum ?? albums.first;
        final selectedFuture =
            albumAssetsFuture ??
            context.read<MediaRepository>().fetchAlbumAssets(
              session,
              albumId: selectedAlbumValue.id,
            );

        if (selectedAlbum == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              onAlbumSelected(selectedAlbumValue);
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose an album',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: albums.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return SizedBox(
                    width: 240,
                    child: _TvChoiceTile(
                      title: album.name,
                      subtitle: '${album.assetCount} photos',
                      badge: '${album.name} • ${album.assetCount}',
                      icon: Icons.photo_album_outlined,
                      isSelected: album.id == selectedAlbumValue.id,
                      onPressed: () => onAlbumSelected(album),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FutureBuilder<List<AssetSummary>>(
              future: selectedFuture,
              builder: (context, assetSnapshot) {
                if (assetSnapshot.connectionState != ConnectionState.done) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final assets = assetSnapshot.data ?? const <AssetSummary>[];
                if (assets.isEmpty) {
                  return const Expanded(
                    child: _InfoPanel(
                      title: 'This album has no photos for slideshow',
                      body:
                          'Only photo assets are included in slideshow playback right now.',
                      accent: AppColors.textMuted,
                    ),
                  );
                }

                return Expanded(
                  child: _PhotoSlideshowPreview(
                    title: selectedAlbumValue.name,
                    assets: assets,
                    shuffle: shuffle,
                    accessToken: accessToken,
                    onStart: () => onStart(assets),
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

class _TvChoiceTile extends StatefulWidget {
  const _TvChoiceTile({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
    this.isEnabled = true,
  });

  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  State<_TvChoiceTile> createState() => _TvChoiceTileState();
}

class _TvChoiceTileState extends State<_TvChoiceTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocusable(
      enabled: widget.isEnabled,
      onPressed: widget.onPressed,
      mouseCursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      builder: (context, focusState) {
        final isActive = widget.isSelected || focusState.isActive;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF13212A) : const Color(0xFF0D1A21),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.focus
                  : isActive
                  ? AppColors.borderStrong
                  : AppColors.border,
              width: widget.isSelected ? 2 : 1,
            ),
          ),
          child: Opacity(
            opacity: widget.isEnabled ? 1 : 0.45,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadii.md),
                  ),
                  child: Icon(widget.icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
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
}

class _TvPillOption extends StatefulWidget {
  const _TvPillOption({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  State<_TvPillOption> createState() => _TvPillOptionState();
}

class _TvPillOptionState extends State<_TvPillOption> {
  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onPressed: widget.onPressed,
      builder: (context, focusState) {
        final isActive = widget.isSelected || focusState.isActive;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFF0D1A21),
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.focus
                  : isActive
                  ? AppColors.borderStrong
                  : AppColors.border,
            ),
          ),
          child: Text(
            widget.label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        );
      },
    );
  }
}

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: child),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.body,
    required this.accent,
  });

  final String title;
  final String body;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dashboard_customize_outlined, color: accent, size: 34),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _responsiveSidebarWidth(double screenWidth) {
  return (screenWidth * 0.18).clamp(240.0, 420.0).toDouble();
}

double _responsiveAlbumRailWidth(double contentWidth) {
  return (contentWidth * 0.22).clamp(260.0, 360.0).toDouble();
}

SliverGridDelegate _buildAssetGridDelegate(double availableWidth) {
  const spacing = 8.0;
  const targetTileWidth = 320.0;
  final crossAxisCount = (availableWidth / targetTileWidth).floor().clamp(2, 6);

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: spacing,
    crossAxisSpacing: spacing,
    childAspectRatio: 1,
  );
}
