import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_exception.dart';
import '../../core/models/album_summary.dart';
import '../../core/models/asset_summary.dart';
import '../../core/models/authenticated_session.dart';
import '../../core/repositories/media_repository.dart';
import '../../shared/presentation/app_breakpoints.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_scale.dart';
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
          child: BlocBuilder<LibraryCubit, LibraryState>(
            builder: (context, state) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final scale = AppScale.of(context);
                  final sidebarWidth = _responsiveSidebarWidth(
                    constraints.maxWidth,
                    scale,
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
    final scale = AppScale.of(context);

    return Container(
      width: width,
      padding: EdgeInsets.fromLTRB(
        scale.space(24, min: 20, max: 24),
        scale.space(24, min: 20, max: 24),
        scale.space(20, min: 18, max: 20),
        scale.space(24, min: 20, max: 24),
      ),
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
              fontSize: scale.text(30, min: 24, max: 30),
            ),
          ),
          SizedBox(height: scale.space(AppSpacing.lg, min: 20, max: 24)),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHeader(session: session),
                  SizedBox(
                    height: scale.space(AppSpacing.xl, min: 24, max: 32),
                  ),
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
                  SizedBox(height: scale.space(AppSpacing.xs, min: 8, max: 8)),
                  _SidebarMenuButton(
                    label: 'Albums',
                    subtitle: 'Curated collections',
                    icon: Icons.photo_album_outlined,
                    isSelected: state.selectedTab == LibraryTab.albums,
                    onPressed: () => context.read<LibraryCubit>().selectTab(
                      LibraryTab.albums,
                    ),
                  ),
                  SizedBox(height: scale.space(AppSpacing.xs, min: 8, max: 8)),
                  _SidebarMenuButton(
                    label: 'Favorites',
                    subtitle: 'Saved highlights',
                    icon: Icons.favorite_border,
                    isSelected: state.selectedTab == LibraryTab.favorites,
                    onPressed: () => context.read<LibraryCubit>().selectTab(
                      LibraryTab.favorites,
                    ),
                  ),
                  SizedBox(height: scale.space(AppSpacing.xs, min: 8, max: 8)),
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
          SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
          Text(
            'Connected to ${session.serverConfig.serverUrl}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              height: 1.5,
              fontSize: scale.text(12, min: 11, max: 12),
            ),
          ),
          SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
          TextButton.icon(
            onPressed: () => context.read<AppFlowCubit>().showProfilePicker(),
            icon: const Icon(Icons.switch_account_rounded),
            label: const Text('Switch user'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 0,
                vertical: scale.space(AppSpacing.sm, min: 10, max: 12),
              ),
              foregroundColor: Colors.white,
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: scale.text(18, min: 15, max: 18),
              ),
            ),
          ),
          SizedBox(height: scale.space(AppSpacing.xs, min: 6, max: 8)),
          TextButton.icon(
            onPressed: () => context.read<AppFlowCubit>().signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: 0,
                vertical: scale.space(AppSpacing.sm, min: 10, max: 12),
              ),
              foregroundColor: Colors.white,
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: scale.text(18, min: 15, max: 18),
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
    final scale = AppScale.of(context);
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
          radius: scale.sizeOf(30, min: 26, max: 30),
          backgroundColor: AppColors.focus,
          foregroundColor: AppColors.actionForeground,
          child: Text(
            initials.isEmpty ? 'U' : initials,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: scale.text(22, min: 18, max: 22),
            ),
          ),
        ),
        SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
        Text(
          name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: scale.text(24, min: 20, max: 24),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          session.user.email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            fontSize: scale.text(14, min: 12, max: 14),
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
    final scale = AppScale.of(context);
    return TvFocusable(
      autofocus: widget.autofocus,
      onPressed: widget.onPressed,
      builder: (context, focusState) {
        final isActive = widget.isSelected || focusState.isActive;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: scale.space(AppSpacing.md, min: 14, max: 16),
            vertical: scale.space(AppSpacing.md, min: 14, max: 16),
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
                size: scale.sizeOf(22, min: 20, max: 22),
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
                        fontSize: scale.text(18, min: 15, max: 18),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        fontSize: scale.text(12, min: 11, max: 12),
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
        final scale = AppScale.of(context);
        final horizontalPadding = scale.space(
          constraints.maxWidth >= AppBreakpoints.tv ? 36 : 28,
          min: 24,
          max: 32,
        );
        final verticalPadding = scale.space(20, min: 16, max: 20);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            verticalPadding,
            horizontalPadding,
            verticalPadding,
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
      LibraryTab.timeline => _TimelineSectionView(
        session: session,
        title: 'Timeline',
        description: 'Browse your library grouped by day.',
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

class _TimelineSectionView extends StatelessWidget {
  const _TimelineSectionView({
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
    final scale = AppScale.of(context);
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
      return const Center(child: CircularProgressIndicator());
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
          final scale = AppScale.of(context);
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
              : _SlideshowLaunchPanel(
                  title: _source == _SlideshowSource.timeline
                      ? 'Timeline'
                      : 'Favorites',
                  description: _source == _SlideshowSource.timeline
                      ? 'Play your full photo timeline in sequence or shuffle.'
                      : 'Play only your favorite photos as a dedicated slideshow.',
                  assetCount: sourceAssets.length,
                  emptyTitle: 'No photos ready for slideshow',
                  emptyBody: _source == _SlideshowSource.timeline
                      ? 'Timeline will become available here once your library has photos.'
                      : 'Favorite some photos first, then start a favorites slideshow from here.',
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
                SizedBox(height: scale.space(AppSpacing.xl, min: 24, max: 32)),
                Expanded(child: content),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: scale.sizeOf(360, min: 300, max: 360),
                child: controls,
              ),
              SizedBox(width: scale.space(AppSpacing.xl, min: 24, max: 32)),
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
      _albumAssetsFuture = context
          .read<MediaRepository>()
          .fetchAlbumAssetsPage(widget.session, albumId: album.id)
          .then(
            (response) => response.items
                .where((asset) => !asset.isVideo)
                .toList(growable: false),
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
    final scale = AppScale.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Source',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: scale.text(24, min: 20, max: 24),
            ),
          ),
          SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
          _SlideshowSourceChip(
            label: 'Timeline',
            count: timelineCount,
            isSelected: source == _SlideshowSource.timeline,
            onPressed: () => onSourceSelected(_SlideshowSource.timeline),
          ),
          SizedBox(height: scale.space(AppSpacing.sm, min: 10, max: 12)),
          _SlideshowSourceChip(
            label: 'Favorites',
            count: favoritesCount,
            isSelected: source == _SlideshowSource.favorites,
            isEnabled: favoritesCount > 0,
            onPressed: () => onSourceSelected(_SlideshowSource.favorites),
          ),
          SizedBox(height: scale.space(AppSpacing.sm, min: 10, max: 12)),
          _SlideshowSourceChip(
            label: 'Albums',
            count: albumsCount,
            isSelected: source == _SlideshowSource.albums,
            isEnabled: albumsCount > 0,
            onPressed: () => onSourceSelected(_SlideshowSource.albums),
          ),
          SizedBox(height: scale.space(AppSpacing.xl, min: 24, max: 32)),
          Text(
            'Playback',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: scale.text(24, min: 20, max: 24),
            ),
          ),
          SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
          Wrap(
            spacing: scale.space(AppSpacing.sm, min: 10, max: 12),
            runSpacing: scale.space(AppSpacing.sm, min: 10, max: 12),
            children: [
              for (final seconds in const [3, 5, 8, 12])
                _TvPillOption(
                  label: '${seconds}s',
                  isSelected: durationSeconds == seconds,
                  onPressed: () => onDurationSelected(seconds),
                ),
            ],
          ),
          SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
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

class _SlideshowLaunchPanel extends StatelessWidget {
  const _SlideshowLaunchPanel({
    required this.title,
    required this.description,
    required this.assetCount,
    required this.emptyTitle,
    required this.emptyBody,
    required this.onStart,
  });

  final String title;
  final String description;
  final int assetCount;
  final String emptyTitle;
  final String emptyBody;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);

    if (assetCount == 0) {
      return _InfoPanel(
        title: emptyTitle,
        body: emptyBody,
        accent: AppColors.textMuted,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1A21),
        borderRadius: BorderRadius.circular(
          scale.radius(AppRadii.xl, min: 24, max: 28),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.all(scale.space(AppSpacing.xl, min: 24, max: 32)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: scale.text(30, min: 24, max: 30),
              ),
            ),
            SizedBox(height: scale.space(AppSpacing.xs, min: 8, max: 8)),
            Text(
              '$assetCount photos ready',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                fontSize: scale.text(16, min: 14, max: 16),
              ),
            ),
            SizedBox(height: scale.space(AppSpacing.lg, min: 20, max: 24)),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: scale.sizeOf(560, min: 420, max: 560),
                  ),
                  child: Text(
                    description,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                      fontSize: scale.text(18, min: 15, max: 18),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: scale.space(AppSpacing.xl, min: 24, max: 32)),
            FilledButton.icon(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                minimumSize: Size(
                  scale.sizeOf(260, min: 220, max: 260),
                  scale.sizeOf(60, min: 52, max: 60),
                ),
                textStyle: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: scale.text(18, min: 15, max: 18),
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
    required this.onAlbumSelected,
    required this.onStart,
  });

  final AuthenticatedSession session;
  final Future<List<AlbumSummary>> albumsFuture;
  final AlbumSummary? selectedAlbum;
  final Future<List<AssetSummary>>? albumAssetsFuture;
  final ValueChanged<AlbumSummary> onAlbumSelected;
  final ValueChanged<List<AssetSummary>> onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);

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
            context
                .read<MediaRepository>()
                .fetchAlbumAssetsPage(session, albumId: selectedAlbumValue.id)
                .then((response) => response.items);

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
                fontSize: scale.text(24, min: 20, max: 24),
              ),
            ),
            SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
            SizedBox(
              height: scale.sizeOf(92, min: 84, max: 92),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: albums.length,
                separatorBuilder: (_, _) => SizedBox(
                  width: scale.space(AppSpacing.sm, min: 10, max: 12),
                ),
                itemBuilder: (context, index) {
                  final album = albums[index];
                  return SizedBox(
                    width: scale.sizeOf(240, min: 220, max: 240),
                    child: _TvChoiceTile(
                      title: album.name,
                      subtitle: '${album.assetCount} assets',
                      badge: '${album.name} • ${album.assetCount}',
                      icon: Icons.photo_album_outlined,
                      isSelected: album.id == selectedAlbumValue.id,
                      onPressed: () => onAlbumSelected(album),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: scale.space(AppSpacing.lg, min: 20, max: 24)),
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
                      title: 'This album has no photos ready',
                      body:
                          'Choose another album or add photo assets to this one before starting a slideshow.',
                      accent: AppColors.textMuted,
                    ),
                  );
                }

                return Expanded(
                  child: _SlideshowLaunchPanel(
                    title: selectedAlbumValue.name,
                    description:
                        'Start playback from this album using your selected duration and shuffle settings.',
                    assetCount: assets.length,
                    emptyTitle: 'This album has no photos ready',
                    emptyBody:
                        'Choose another album or add photo assets to this one before starting a slideshow.',
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
    final scale = AppScale.of(context);
    return TvFocusable(
      enabled: widget.isEnabled,
      onPressed: widget.onPressed,
      mouseCursor: widget.isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      builder: (context, focusState) {
        final isActive = widget.isSelected || focusState.isActive;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompact =
                constraints.maxHeight.isFinite && constraints.maxHeight < 96;
            final iconSize = scale.sizeOf(
              isCompact ? 40 : 48,
              min: isCompact ? 34 : 40,
              max: isCompact ? 40 : 48,
            );
            final padding = scale.space(
              isCompact ? AppSpacing.md : AppSpacing.lg,
              min: isCompact ? 14 : 20,
              max: isCompact ? 16 : 24,
            );
            final gap = scale.space(
              isCompact ? AppSpacing.sm : AppSpacing.md,
              min: 10,
              max: 16,
            );

            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF13212A)
                    : const Color(0xFF0D1A21),
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
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(
                          scale.radius(AppRadii.md, min: 14, max: 18),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white,
                        size: scale.sizeOf(
                          isCompact ? 20 : 24,
                          min: 18,
                          max: 24,
                        ),
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: isCompact
                          ? Text(
                              widget.badge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: scale.text(18, min: 15, max: 18),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.badge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: scale.text(18, min: 15, max: 18),
                                  ),
                                ),
                                SizedBox(
                                  height: scale.space(2, min: 2, max: 2),
                                ),
                                Text(
                                  widget.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: scale.text(14, min: 12, max: 14),
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
    final scale = AppScale.of(context);
    return TvFocusable(
      onPressed: widget.onPressed,
      builder: (context, focusState) {
        final isActive = widget.isSelected || focusState.isActive;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: scale.space(AppSpacing.lg, min: 20, max: 24),
            vertical: scale.space(AppSpacing.md, min: 14, max: 16),
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? Colors.white.withValues(alpha: 0.12)
                : const Color(0xFF0D1A21),
            borderRadius: BorderRadius.circular(
              scale.radius(AppRadii.pill, min: 999, max: 999),
            ),
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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: scale.text(16, min: 14, max: 16),
            ),
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
    final scale = AppScale.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: scale.text(34, min: 28, max: 34),
          ),
        ),
        SizedBox(height: scale.space(AppSpacing.xs, min: 8, max: 8)),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
            fontSize: scale.text(16, min: 14, max: 16),
          ),
        ),
        SizedBox(height: scale.space(AppSpacing.lg, min: 20, max: 24)),
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
    final scale = AppScale.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: scale.sizeOf(560, min: 420, max: 560),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.dashboard_customize_outlined,
              color: accent,
              size: scale.sizeOf(34, min: 28, max: 34),
            ),
            SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: scale.text(28, min: 22, max: 28),
              ),
            ),
            SizedBox(height: scale.space(AppSpacing.sm, min: 10, max: 12)),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
                fontSize: scale.text(16, min: 14, max: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

double _responsiveSidebarWidth(double screenWidth, AppScale scale) {
  return (screenWidth * 0.18)
      .clamp(
        scale.sizeOf(240, min: 220, max: 240),
        scale.sizeOf(420, min: 360, max: 420),
      )
      .toDouble();
}

double _responsiveAlbumRailWidth(double contentWidth, AppScale scale) {
  return (contentWidth * 0.22)
      .clamp(
        scale.sizeOf(260, min: 220, max: 260),
        scale.sizeOf(360, min: 320, max: 360),
      )
      .toDouble();
}

List<_TimelineDayGroup> _groupTimelineAssets(List<AssetSummary> assets) {
  final groups = <_TimelineDayGroup>[];

  for (var i = 0; i < assets.length; i++) {
    final asset = assets[i];
    final day = DateTime(
      asset.createdAt.year,
      asset.createdAt.month,
      asset.createdAt.day,
    );

    if (groups.isEmpty || !_isSameDay(groups.last.day, day)) {
      groups.add(_TimelineDayGroup(day: day, items: []));
    }

    groups.last.items.add(_TimelineAssetEntry(asset: asset, globalIndex: i));
  }

  return groups;
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatTimelineDay(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
}

class _TimelineDayGroup {
  _TimelineDayGroup({required this.day, required this.items});

  final DateTime day;
  final List<_TimelineAssetEntry> items;
}

class _TimelineAssetEntry {
  const _TimelineAssetEntry({required this.asset, required this.globalIndex});

  final AssetSummary asset;
  final int globalIndex;
}

SliverGridDelegate _buildAssetGridDelegate(double availableWidth) {
  const spacing = 8.0;
  // if (availableWidth >= AppBreakpoints.tv - 280) {
  //   return const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6, mainAxisSpacing: spacing, crossAxisSpacing: spacing, childAspectRatio: 1);
  // }

  // const targetTileWidth = 320.0;
  // final crossAxisCount = (availableWidth / targetTileWidth).floor().clamp(2, 6);

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 6,
    mainAxisSpacing: spacing,
    crossAxisSpacing: spacing,
    childAspectRatio: 1,
  );
}
