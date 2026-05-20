import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session});

  final AuthenticatedSession session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FocusNode _menuToggleFocusNode;
  late final List<FocusNode> _drawerFocusNodes;
  late final FocusNode _timelineContentFocusNode;
  late final FocusNode _albumsContentFocusNode;
  late final FocusNode _favoritesContentFocusNode;
  bool _isSidebarOpen = false;

  @override
  void initState() {
    super.initState();
    _menuToggleFocusNode = FocusNode(debugLabel: 'home-menu-toggle');
    _drawerFocusNodes = List<FocusNode>.generate(
      5,
      (index) => FocusNode(debugLabel: 'home-drawer-$index'),
    );
    _timelineContentFocusNode = FocusNode(debugLabel: 'home-timeline-content');
    _albumsContentFocusNode = FocusNode(debugLabel: 'home-albums-content');
    _favoritesContentFocusNode = FocusNode(debugLabel: 'home-favorites-content');
  }

  @override
  void dispose() {
    _menuToggleFocusNode.dispose();
    for (final node in _drawerFocusNodes) {
      node.dispose();
    }
    _timelineContentFocusNode.dispose();
    _albumsContentFocusNode.dispose();
    _favoritesContentFocusNode.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    if (_isSidebarOpen) {
      _closeSidebar();
      return;
    }
    _openSidebar();
  }

  void _openSidebar({int? focusIndex}) {
    setState(() => _isSidebarOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final drawerIndex = switch (focusIndex) {
        final int index when index >= 0 && index < _drawerFocusNodes.length => index,
        _ => 0,
      };
      _drawerFocusNodes[drawerIndex].requestFocus();
    });
  }

  void _openSidebarForTab(LibraryTab tab) {
    _openSidebar(
      focusIndex: switch (tab) {
        LibraryTab.timeline => 0,
        LibraryTab.albums => 1,
        LibraryTab.favorites => 2,
      },
    );
  }

  void _closeSidebar({
    bool focusMenuToggle = true,
    LibraryTab? focusContentTab,
  }) {
    if (!_isSidebarOpen) {
      return;
    }
    setState(() => _isSidebarOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (focusContentTab != null && _requestContentFocus(focusContentTab)) {
        return;
      }
      if (focusMenuToggle) {
        _menuToggleFocusNode.requestFocus();
      }
    });
  }

  bool _requestContentFocus(LibraryTab tab) {
    final focusNode = switch (tab) {
      LibraryTab.timeline => _timelineContentFocusNode,
      LibraryTab.albums => _albumsContentFocusNode,
      LibraryTab.favorites => _favoritesContentFocusNode,
    };

    if (focusNode.context == null || !focusNode.canRequestFocus) {
      return false;
    }
    focusNode.requestFocus();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          LibraryCubit(
            context.read<MediaRepository>(),
            widget.session,
          )..loadInitial(),
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

                  return Stack(
                    children: [
                      Positioned.fill(
                        child: _ContentPane(
                          session: widget.session,
                          state: state,
                          isSidebarOpen: _isSidebarOpen,
                          menuToggleFocusNode: _menuToggleFocusNode,
                          timelineContentFocusNode: _timelineContentFocusNode,
                          albumsContentFocusNode: _albumsContentFocusNode,
                          favoritesContentFocusNode: _favoritesContentFocusNode,
                          onToggleSidebar: _toggleSidebar,
                          onOpenSidebarForTab: _openSidebarForTab,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        child: ClipRect(
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.centerLeft,
                            widthFactor: _isSidebarOpen ? 1 : 0,
                            child: ExcludeFocus(
                              excluding: !_isSidebarOpen,
                              child: IgnorePointer(
                                ignoring: !_isSidebarOpen,
                                child: SizedBox(
                                  width: sidebarWidth,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 160),
                                    opacity: _isSidebarOpen ? 1 : 0,
                                    child: _Sidebar(
                                      session: widget.session,
                                      state: state,
                                      width: sidebarWidth,
                                      focusNodes: _drawerFocusNodes,
                                      onCloseSidebar: _closeSidebar,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
    required this.focusNodes,
    required this.onCloseSidebar,
  });

  final AuthenticatedSession session;
  final LibraryState state;
  final double width;
  final List<FocusNode> focusNodes;
  final void Function({
    bool focusMenuToggle,
    LibraryTab? focusContentTab,
  }) onCloseSidebar;

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp): _DrawerMoveIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowDown): _DrawerMoveIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _CloseDrawerIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _DrawerMoveIntent: CallbackAction<_DrawerMoveIntent>(
            onInvoke: (intent) {
              final currentIndex = _currentDrawerFocusIndex();
              if (currentIndex == null) {
                return null;
              }
              final nextIndex = currentIndex + intent.delta;
              if (nextIndex < 0 || nextIndex >= focusNodes.length) {
                return null;
              }
              focusNodes[nextIndex].requestFocus();
              return null;
            },
          ),
          _CloseDrawerIntent: CallbackAction<_CloseDrawerIntent>(
            onInvoke: (_) {
              onCloseSidebar(
                focusMenuToggle: false,
                focusContentTab: state.selectedTab,
              );
              return null;
            },
          ),
        },
        child: Container(
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
                        onPressed: () {
                          context.read<LibraryCubit>().selectTab(LibraryTab.timeline);
                          onCloseSidebar(
                            focusMenuToggle: false,
                            focusContentTab: LibraryTab.timeline,
                          );
                        },
                        focusNode: focusNodes[0],
                      ),
                      SizedBox(height: scale.space(AppSpacing.xs, min: 8, max: 8)),
                      _SidebarMenuButton(
                        label: 'Albums',
                        subtitle: 'Curated collections',
                        icon: Icons.photo_album_outlined,
                        isSelected: state.selectedTab == LibraryTab.albums,
                        onPressed: () {
                          context.read<LibraryCubit>().selectTab(LibraryTab.albums);
                          onCloseSidebar(
                            focusMenuToggle: false,
                            focusContentTab: LibraryTab.albums,
                          );
                        },
                        focusNode: focusNodes[1],
                      ),
                      SizedBox(height: scale.space(AppSpacing.xs, min: 8, max: 8)),
                      _SidebarMenuButton(
                        label: 'Favorites',
                        subtitle: 'Saved highlights',
                        icon: Icons.favorite_border,
                        isSelected: state.selectedTab == LibraryTab.favorites,
                        onPressed: () {
                          context.read<LibraryCubit>().selectTab(
                            LibraryTab.favorites,
                          );
                          onCloseSidebar(
                            focusMenuToggle: false,
                            focusContentTab: LibraryTab.favorites,
                          );
                        },
                        focusNode: focusNodes[2],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
          _SidebarActionButton(
            icon: Icons.switch_account_rounded,
            label: 'Switch user',
            focusNode: focusNodes[3],
            onPressed: () => context.read<AppFlowCubit>().showProfilePicker(),
          ),
          SizedBox(height: scale.space(AppSpacing.xs, min: 6, max: 8)),
          _SidebarActionButton(
            icon: Icons.logout_rounded,
            label: 'Sign out',
            focusNode: focusNodes[4],
            onPressed: () => context.read<AppFlowCubit>().signOut(),
          ),
        ],
      ),
        ),
      ),
    );
  }

  int? _currentDrawerFocusIndex() {
    for (var i = 0; i < focusNodes.length; i++) {
      if (focusNodes[i].hasFocus) {
        return i;
      }
    }
    return null;
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
        SizedBox(width: scale.space(AppSpacing.md, min: 14, max: 16)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: scale.text(24, min: 20, max: 24),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                session.user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: scale.text(14, min: 12, max: 14),
                ),
              ),
            ],
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
    this.focusNode,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  @override
  State<_SidebarMenuButton> createState() => _SidebarMenuButtonState();
}

class _SidebarMenuButtonState extends State<_SidebarMenuButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    return TvFocusable(
      focusNode: widget.focusNode,
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

class _SidebarActionButton extends StatelessWidget {
  const _SidebarActionButton({
    required this.icon,
    required this.label,
    required this.focusNode,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final FocusNode focusNode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);

    return TvFocusable(
      focusNode: focusNode,
      onPressed: onPressed,
      builder: (context, focusState) {
        final isActive = focusState.isActive;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: 0,
            vertical: scale.space(AppSpacing.sm, min: 10, max: 12),
          ),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF111F26) : Colors.transparent,
            border: Border(
              left: BorderSide(
                color: focusState.isFocused ? AppColors.focus : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: scale.sizeOf(22, min: 20, max: 22),
              ),
              SizedBox(width: scale.space(AppSpacing.sm, min: 10, max: 12)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: scale.text(18, min: 15, max: 18),
                  ),
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
  const _ContentPane({
    required this.session,
    required this.state,
    required this.isSidebarOpen,
    required this.menuToggleFocusNode,
    required this.timelineContentFocusNode,
    required this.albumsContentFocusNode,
    required this.favoritesContentFocusNode,
    required this.onToggleSidebar,
    required this.onOpenSidebarForTab,
  });

  final AuthenticatedSession session;
  final LibraryState state;
  final bool isSidebarOpen;
  final FocusNode menuToggleFocusNode;
  final FocusNode timelineContentFocusNode;
  final FocusNode albumsContentFocusNode;
  final FocusNode favoritesContentFocusNode;
  final VoidCallback onToggleSidebar;
  final ValueChanged<LibraryTab> onOpenSidebarForTab;

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
          child: _LibraryContent(
            state: state,
            session: session,
            isSidebarOpen: isSidebarOpen,
            menuToggleFocusNode: menuToggleFocusNode,
            timelineContentFocusNode: timelineContentFocusNode,
            albumsContentFocusNode: albumsContentFocusNode,
            favoritesContentFocusNode: favoritesContentFocusNode,
            onToggleSidebar: onToggleSidebar,
            onOpenSidebarForTab: onOpenSidebarForTab,
          ),
        );
      },
    );
  }
}

class _MenuToggleButton extends StatelessWidget {
  const _MenuToggleButton({
    required this.focusNode,
    required this.icon,
    required this.tooltip,
    this.compact = false,
    required this.onPressed,
  });

  final FocusNode? focusNode;
  final IconData icon;
  final String tooltip;
  final bool compact;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);

    return TvFocusable(
      focusNode: focusNode,
      onPressed: onPressed,
      builder: (context, focusState) {
        final isActive = focusState.isActive;

        return Tooltip(
          message: tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: scale.sizeOf(compact ? 42 : 48, min: 40, max: 48),
            height: scale.sizeOf(compact ? 42 : 48, min: 40, max: 48),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF111F26)
                  : const Color(0xFF0D1A21),
              borderRadius: BorderRadius.circular(
                scale.radius(compact ? AppRadii.md : AppRadii.lg, min: 14, max: 18),
              ),
              border: Border.all(
                color: focusState.isFocused ? AppColors.focus : AppColors.border,
                width: focusState.isFocused ? 2 : 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.white,
                size: scale.sizeOf(
                  compact ? 18 : 20,
                  min: compact ? 16 : 18,
                  max: compact ? 18 : 20,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({
    required this.state,
    required this.session,
    required this.isSidebarOpen,
    required this.menuToggleFocusNode,
    required this.timelineContentFocusNode,
    required this.albumsContentFocusNode,
    required this.favoritesContentFocusNode,
    required this.onToggleSidebar,
    required this.onOpenSidebarForTab,
  });

  final LibraryState state;
  final AuthenticatedSession session;
  final bool isSidebarOpen;
  final FocusNode menuToggleFocusNode;
  final FocusNode timelineContentFocusNode;
  final FocusNode albumsContentFocusNode;
  final FocusNode favoritesContentFocusNode;
  final VoidCallback onToggleSidebar;
  final ValueChanged<LibraryTab> onOpenSidebarForTab;

  @override
  Widget build(BuildContext context) {
    return switch (state.selectedTab) {
      LibraryTab.timeline => _TimelineSectionView(
        session: session,
        title: 'Timeline',
        selectedYear: state.selectedTimelineYear,
        status: state.status,
        errorMessage: state.errorMessage,
        assets: state.timeline,
        hasMore: state.hasMoreTimeline,
        isLoadingMore: state.isLoadingMore,
        emptyMessage: 'No timeline assets are available yet.',
        isSidebarOpen: isSidebarOpen,
        menuToggleFocusNode: menuToggleFocusNode,
        primaryContentFocusNode: timelineContentFocusNode,
        onToggleSidebar: onToggleSidebar,
        onOpenSidebar: () => onOpenSidebarForTab(LibraryTab.timeline),
      ),
      LibraryTab.albums => _AlbumSectionView(
        session: session,
        status: state.status,
        errorMessage: state.errorMessage,
        albums: state.albums,
        isSidebarOpen: isSidebarOpen,
        menuToggleFocusNode: menuToggleFocusNode,
        primaryContentFocusNode: albumsContentFocusNode,
        onToggleSidebar: onToggleSidebar,
        onOpenSidebar: () => onOpenSidebarForTab(LibraryTab.albums),
      ),
      LibraryTab.favorites => _AssetSectionView(
        session: session,
        title: 'Favorites',
        status: state.status,
        errorMessage: state.errorMessage,
        assets: state.favorites,
        hasMore: state.hasMoreFavorites,
        isLoadingMore: state.isLoadingMore,
        emptyMessage: 'No favorite assets are available yet.',
        isSidebarOpen: isSidebarOpen,
        menuToggleFocusNode: menuToggleFocusNode,
        primaryContentFocusNode: favoritesContentFocusNode,
        onToggleSidebar: onToggleSidebar,
        onOpenSidebar: () => onOpenSidebarForTab(LibraryTab.favorites),
      ),
    };
  }
}

class _CloseDrawerIntent extends Intent {
  const _CloseDrawerIntent();
}

class _DrawerMoveIntent extends Intent {
  const _DrawerMoveIntent(this.delta);

  final int delta;
}

class _OpenDrawerIntent extends Intent {
  const _OpenDrawerIntent();
}
