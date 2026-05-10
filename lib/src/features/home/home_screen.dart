import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/errors/app_exception.dart';
import '../../core/models/album_summary.dart';
import '../../core/models/asset_summary.dart';
import '../../core/models/authenticated_session.dart';
import '../../core/repositories/asset_image_repository.dart';
import '../../core/repositories/media_repository.dart';
import '../../shared/presentation/app_breakpoints.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_scale.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/authenticated_asset_image.dart';
import '../../shared/presentation/widgets/loading_skeleton.dart';
import '../../shared/presentation/widgets/tv_focusable.dart';
import '../app_flow/cubit/app_flow_cubit.dart';
import '../library/cubit/library_cubit.dart';
import '../library/cubit/library_state.dart';
import '../viewer/asset_viewer_screen.dart';

part 'home_sections.part.dart';
part 'home_albums.part.dart';
part 'home_shared.part.dart';

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
        final verticalPadding = constraints.maxWidth >= AppBreakpoints.tv
            ? scale.space(12, min: 10, max: 14)
            : scale.space(20, min: 16, max: 20);

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
        selectedYear: state.selectedTimelineYear,
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
    };
  }
}
