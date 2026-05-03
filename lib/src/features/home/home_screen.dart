import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/album_summary.dart';
import '../../core/models/asset_summary.dart';
import '../../core/models/authenticated_session.dart';
import '../../core/repositories/asset_image_repository.dart';
import '../../core/repositories/media_repository.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/authenticated_asset_image.dart';
import '../../shared/presentation/widgets/shortcut_hint.dart';
import '../app_flow/cubit/app_flow_cubit.dart';
import '../library/cubit/library_cubit.dart';
import '../library/cubit/library_state.dart';
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
                return Row(
                  children: [
                    _Sidebar(session: session, state: state),
                    Expanded(
                      child: _ContentPane(session: session, state: state),
                    ),
                  ],
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
  const _Sidebar({required this.session, required this.state});

  final AuthenticatedSession session;
  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 300,
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
            'ImmichTV',
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
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = widget.isSelected || _isFocused || _isHovered;

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (value) => setState(() => _isFocused = value),
      onShowHoverHighlight: (value) => setState(() => _isHovered = value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: Container(
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
        ),
      ),
    );
  }
}

class _ContentPane extends StatelessWidget {
  const _ContentPane({required this.session, required this.state});

  final AuthenticatedSession session;
  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to ImmichTV',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const ShortcutHint(label: 'Enter'),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Select any menu from the left to change this view. Open any asset with Enter, a remote select button, or a click.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: _LibraryContent(state: state, session: session),
          ),
        ],
      ),
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
      LibraryTab.slideshow => const _SlideshowSectionView(),
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
      child: GridView.builder(
        cacheExtent: 1200,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1,
        ),
        itemCount: assets.length + (hasMore || isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= assets.length) {
            return _LoadMoreTile(isLoading: isLoadingMore, hasMore: hasMore);
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
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = _isFocused || _isHovered;

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (value) => setState(() => _isFocused = value),
      onShowHoverHighlight: (value) => setState(() => _isHovered = value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onPressed,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: isActive ? 0.985 : 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AuthenticatedAssetImage(
                imageUrls: widget.asset.thumbnailUrls,
                accessToken: widget.session.accessToken,
                heroTag: 'asset-${widget.asset.id}',
                placeholderIcon: widget.asset.isVideo
                    ? Icons.smart_display_outlined
                    : Icons.photo_outlined,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _isFocused ? AppColors.focus : Colors.transparent,
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
                        Colors.black.withValues(alpha: isActive ? 0.68 : 0.54),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
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
      ),
    );
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
    required this.status,
    required this.errorMessage,
    required this.albums,
  });

  final LibraryLoadStatus status;
  final String? errorMessage;
  final List<AlbumSummary> albums;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'Albums',
      description: 'Collection-first browsing in a clean left-nav shell.',
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = Theme.of(context);

    if (status == LibraryLoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (status == LibraryLoadStatus.failure) {
      return _InfoPanel(
        title: 'Albums are unavailable right now',
        body: errorMessage ?? 'Try again in a moment.',
        accent: AppColors.error,
      );
    }

    if (albums.isEmpty) {
      return const _InfoPanel(
        title: 'No albums yet',
        body: 'Album collections will appear here.',
        accent: AppColors.textMuted,
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return Container(
          color: const Color(0xFF0D1A21),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                album.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${album.assetCount} assets',
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

class _SlideshowSectionView extends StatelessWidget {
  const _SlideshowSectionView();

  @override
  Widget build(BuildContext context) {
    return const _SectionFrame(
      title: 'Slideshow',
      description: 'Ambient playback controls will live here next.',
      child: _InfoPanel(
        title: 'Slideshow mode is queued next',
        body:
            'The left-nav shell is ready. The next pass can build playback on top of it.',
        accent: AppColors.focus,
      ),
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
