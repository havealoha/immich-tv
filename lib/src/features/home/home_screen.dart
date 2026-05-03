import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/authenticated_session.dart';
import '../../core/models/album_summary.dart';
import '../../core/models/asset_summary.dart';
import '../../core/repositories/media_repository.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/focusable_surface.dart';
import '../../shared/presentation/widgets/shortcut_hint.dart';
import '../app_flow/cubit/app_flow_cubit.dart';
import '../library/cubit/library_cubit.dart';
import '../library/cubit/library_state.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.session});

  final AuthenticatedSession session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final tileWidth = viewportWidth > 1500 ? 300.0 : 260.0;

    return BlocProvider(
      create: (context) =>
          LibraryCubit(context.read<MediaRepository>(), session)..loadInitial(),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A1820), Color(0xFF102C36), Color(0xFF08131A)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: BlocBuilder<LibraryCubit, LibraryState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome to ImmichTV',
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Connected to ${session.serverConfig.serverUrl} as ${session.user.email}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: const Color(0xFFB8C8CF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              context.read<AppFlowCubit>().signOut();
                            },
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const ShortcutHint(label: 'Enter'),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Focused cards can be opened with a remote select button, Enter, or a click.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _LibraryTile(
                            title: 'Timeline',
                            subtitle:
                                'Chronological stream for recent and favorite memories.',
                            icon: Icons.view_stream_outlined,
                            width: tileWidth,
                            isSelected:
                                state.selectedTab == LibraryTab.timeline,
                            onPressed: () => context
                                .read<LibraryCubit>()
                                .selectTab(LibraryTab.timeline),
                          ),
                          _LibraryTile(
                            title: 'Albums',
                            subtitle:
                                'Collection-driven browsing for trips, events, and family stories.',
                            icon: Icons.photo_album_outlined,
                            width: tileWidth,
                            isSelected: state.selectedTab == LibraryTab.albums,
                            onPressed: () => context
                                .read<LibraryCubit>()
                                .selectTab(LibraryTab.albums),
                          ),
                          _LibraryTile(
                            title: 'Favorites',
                            subtitle:
                                'Quick access to the best shots for relaxing slideshow playback.',
                            icon: Icons.favorite_border,
                            width: tileWidth,
                            isSelected:
                                state.selectedTab == LibraryTab.favorites,
                            onPressed: () => context
                                .read<LibraryCubit>()
                                .selectTab(LibraryTab.favorites),
                          ),
                          _LibraryTile(
                            title: 'Slideshow',
                            subtitle:
                                'Full-screen playback mode for ambient living-room photo display.',
                            icon: Icons.slideshow_outlined,
                            width: tileWidth,
                            isSelected:
                                state.selectedTab == LibraryTab.slideshow,
                            onPressed: () => context
                                .read<LibraryCubit>()
                                .selectTab(LibraryTab.slideshow),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundElevated,
                            borderRadius: BorderRadius.circular(AppRadii.xl),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: _LibraryContent(state: state),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.width,
    required this.isSelected,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double width;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FocusableSurface(
      width: width,
      autofocus: title == 'Timeline',
      onPressed: onPressed,
      borderColor: isSelected ? AppColors.focus : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.focus, size: 30),
          const SizedBox(height: 18),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSelected ? 'Selected' : 'Open section',
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected ? AppColors.focus : AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({required this.state});

  final LibraryState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.selectedTab) {
      LibraryTab.timeline => _AssetSectionView(
        title: 'Timeline',
        description:
            'Your main chronological feed will land here, tuned for fast browsing on TVs and desktops.',
        status: state.status,
        errorMessage: state.errorMessage,
        assets: state.timeline,
        emptyMessage:
            'No timeline assets are available yet. Once the media API is wired, this section will stream your library in chronological order.',
      ),
      LibraryTab.albums => _AlbumSectionView(
        status: state.status,
        errorMessage: state.errorMessage,
        albums: state.albums,
      ),
      LibraryTab.favorites => _AssetSectionView(
        title: 'Favorites',
        description:
            'This section is reserved for your best shots and slideshow-ready moments.',
        status: state.status,
        errorMessage: state.errorMessage,
        assets: state.favorites,
        emptyMessage:
            'No favorite assets are available yet. Favorited photos and videos will appear here.',
      ),
      LibraryTab.slideshow => const _SlideshowSectionView(),
    };
  }
}

class _AssetSectionView extends StatelessWidget {
  const _AssetSectionView({
    required this.title,
    required this.description,
    required this.status,
    required this.errorMessage,
    required this.assets,
    required this.emptyMessage,
  });

  final String title;
  final String description;
  final LibraryLoadStatus status;
  final String? errorMessage;
  final List<AssetSummary> assets;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return _SectionScaffold(
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

    return ListView.separated(
      itemCount: assets.length,
      separatorBuilder: (_, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final asset = assets[index];
        return FocusableSurface(
          onPressed: () {},
          child: Row(
            children: [
              Container(
                width: 128,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asset ${asset.id}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${asset.type} • ${_formatDate(asset.createdAt)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
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

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
    return _SectionScaffold(
      title: 'Albums',
      description:
          'Albums will become the high-signal way to browse events, trips, and curated collections.',
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
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
        body:
            'Once album data is connected, this area will show large-format collections suited for remote navigation.',
        accent: AppColors.textMuted,
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: albums.length,
      itemBuilder: (context, index) {
        final album = albums[index];
        return FocusableSurface(
          onPressed: () {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                album.name,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                '${album.assetCount} assets',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    return const _SectionScaffold(
      title: 'Slideshow',
      description:
          'The slideshow experience will live here with full-screen playback, pacing controls, and ambient display behavior.',
      child: _InfoPanel(
        title: 'Slideshow mode is queued next',
        body:
            'The focus/navigation groundwork is in place. The next implementation pass can now build slideshow playback on top of it.',
        accent: AppColors.focus,
      ),
    );
  }
}

class _SectionScaffold extends StatelessWidget {
  const _SectionScaffold({
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
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
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
        constraints: const BoxConstraints(maxWidth: 700),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dashboard_customize_outlined, color: accent, size: 36),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
