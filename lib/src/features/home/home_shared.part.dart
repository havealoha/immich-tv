part of 'home_screen.dart';

class _SectionFrame extends StatelessWidget {
  const _SectionFrame({
    required this.title,
    required this.isSidebarOpen,
    required this.menuToggleFocusNode,
    required this.onToggleSidebar,
    required this.child,
  });

  final String title;
  final bool isSidebarOpen;
  final FocusNode menuToggleFocusNode;
  final VoidCallback onToggleSidebar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    final compactChrome = _useCompactTvChrome(scale);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MenuToggleButton(
              focusNode: menuToggleFocusNode,
              icon: isSidebarOpen
                  ? Icons.menu_open_rounded
                  : Icons.menu_rounded,
              tooltip: isSidebarOpen ? 'Hide menu' : 'Show menu',
              compact: true,
              onPressed: onToggleSidebar,
            ),
            SizedBox(width: scale.space(AppSpacing.sm, min: 10, max: 12)),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: compactChrome
                      ? scale.text(28, min: 24, max: 28)
                      : scale.text(34, min: 28, max: 34),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: compactChrome
              ? scale.space(4, min: 4, max: 6)
              : scale.space(AppSpacing.xs, min: 8, max: 8),
        ),
        SizedBox(
          height: compactChrome
              ? scale.space(14, min: 12, max: 16)
              : scale.space(AppSpacing.lg, min: 20, max: 24),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _AnimatedSectionSwap extends StatelessWidget {
  const _AnimatedSectionSwap({
    required this.switchKey,
    required this.child,
  });

  final Object switchKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: offsetAnimation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(key: ValueKey<Object>(switchKey), child: child),
    );
  }
}

class _TimelineLoadingSkeleton extends StatelessWidget {
  const _TimelineLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);

    return ListView.separated(
      itemCount: 4,
      separatorBuilder: (_, _) =>
          SizedBox(height: scale.space(AppSpacing.xl, min: 24, max: 32)),
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const LoadingSkeleton(width: 140, height: 20, borderRadius: 10),
                SizedBox(width: scale.space(AppSpacing.sm, min: 10, max: 12)),
                Expanded(
                  child: LoadingSkeleton(
                    height: 1,
                    borderRadius: 1,
                    baseColor: AppColors.border.withValues(alpha: 0.9),
                    highlightColor: AppColors.border.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
            SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
            SizedBox(
              height: scale.sizeOf(180, min: 156, max: 180),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, itemIndex) {
                  final width = itemIndex == 0 ? 220.0 : 172.0;
                  return LoadingSkeleton(
                    width: width,
                    height: scale.sizeOf(180, min: 156, max: 180),
                    borderRadius: AppRadii.xl,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AssetGridLoadingSkeleton extends StatelessWidget {
  const _AssetGridLoadingSkeleton({
    this.leadingWidth = 180,
    this.leadingHeight = 18,
  });

  final double leadingWidth;
  final double leadingHeight;

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingSkeleton(
          width: leadingWidth,
          height: leadingHeight,
          borderRadius: 10,
        ),
        SizedBox(height: scale.space(AppSpacing.lg, min: 20, max: 24)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenSize = MediaQuery.sizeOf(context);
              return GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: _buildAssetGridDelegate(
                  constraints.maxWidth,
                  screenSize,
                ),
                itemBuilder: (context, index) => const LoadingSkeleton(
                  borderRadius: AppRadii.xl,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AlbumBrowserLoadingSkeleton extends StatelessWidget {
  const _AlbumBrowserLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useStackedLayout = constraints.maxWidth < 980;
        final rail = _AlbumRailLoadingSkeleton(horizontal: useStackedLayout);
        const content = _AssetGridLoadingSkeleton(
          leadingWidth: 240,
          leadingHeight: 20,
        );

        if (useStackedLayout) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: scale.sizeOf(136, min: 124, max: 144),
                child: rail,
              ),
              SizedBox(height: scale.space(AppSpacing.lg, min: 20, max: 24)),
              const Expanded(child: content),
            ],
          );
        }

        return Row(
          children: [
            SizedBox(
              width: _responsiveAlbumRailWidth(constraints.maxWidth, scale),
              child: rail,
            ),
            SizedBox(width: scale.space(AppSpacing.xl, min: 24, max: 32)),
            const Expanded(child: content),
          ],
        );
      },
    );
  }
}

class _AlbumRailLoadingSkeleton extends StatelessWidget {
  const _AlbumRailLoadingSkeleton({required this.horizontal});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);

    if (horizontal) {
      return ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (context, index) =>
            SizedBox(width: scale.space(AppSpacing.md, min: 14, max: 16)),
        itemBuilder: (context, index) => LoadingSkeleton(
          width: scale.sizeOf(196, min: 176, max: 204),
          height: scale.sizeOf(128, min: 116, max: 136),
          borderRadius: AppRadii.xl,
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (context, index) =>
          SizedBox(height: scale.space(AppSpacing.md, min: 14, max: 16)),
      itemBuilder: (context, index) => const LoadingSkeleton(
        height: 110,
        borderRadius: AppRadii.xl,
      ),
    );
  }
}

class _TimelineSectionFrame extends StatelessWidget {
  const _TimelineSectionFrame({
    required this.title,
    required this.years,
    required this.selectedYear,
    required this.onYearSelected,
    required this.isSidebarOpen,
    required this.menuToggleFocusNode,
    required this.onToggleSidebar,
    required this.child,
  });

  final String title;
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<int> onYearSelected;
  final bool isSidebarOpen;
  final FocusNode menuToggleFocusNode;
  final VoidCallback onToggleSidebar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    final compactChrome = _useCompactTvChrome(scale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _MenuToggleButton(
                      focusNode: menuToggleFocusNode,
                      icon: isSidebarOpen
                          ? Icons.menu_open_rounded
                          : Icons.menu_rounded,
                      tooltip: isSidebarOpen ? 'Hide menu' : 'Show menu',
                      compact: true,
                      onPressed: onToggleSidebar,
                    ),
                    SizedBox(
                      width: scale.space(AppSpacing.sm, min: 10, max: 12),
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: compactChrome
                              ? scale.text(28, min: 24, max: 28)
                              : scale.text(34, min: 28, max: 34),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: compactChrome
                      ? scale.space(4, min: 4, max: 6)
                      : scale.space(AppSpacing.xs, min: 8, max: 8),
                ),
              ],
            );

            final yearRail = _TimelineYearRail(
              years: years,
              selectedYear: selectedYear,
              onYearSelected: onYearSelected,
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  flex: 3,
                  child: titleBlock,
                ),
                SizedBox(width: scale.space(AppSpacing.md, min: 12, max: 16)),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: scale.sizeOf(420, min: 260, max: 460),
                      ),
                      child: yearRail,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(
          height: compactChrome
              ? scale.space(14, min: 12, max: 16)
              : scale.space(AppSpacing.lg, min: 20, max: 24),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _TimelineYearRail extends StatelessWidget {
  const _TimelineYearRail({
    required this.years,
    required this.selectedYear,
    required this.onYearSelected,
  });

  final List<int> years;
  final int? selectedYear;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    final compactChrome = _useCompactTvChrome(scale);

    return SizedBox(
      height: compactChrome
          ? scale.sizeOf(46, min: 42, max: 48)
          : scale.sizeOf(52, min: 46, max: 54),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Year:',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              fontSize: compactChrome
                  ? scale.text(15, min: 13, max: 15)
                  : scale.text(16, min: 14, max: 16),
            ),
          ),
          SizedBox(width: scale.space(AppSpacing.sm, min: 10, max: 12)),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: years.length,
              separatorBuilder: (_, _) => SizedBox(
                width: scale.space(AppSpacing.xs, min: 8, max: 10),
              ),
              itemBuilder: (context, index) {
                final year = years[index];
                return _TimelineYearChip(
                  year: year,
                  isSelected: year == selectedYear,
                  autofocus: year == selectedYear,
                  onPressed: () => onYearSelected(year),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineYearChip extends StatefulWidget {
  const _TimelineYearChip({
    required this.year,
    required this.isSelected,
    required this.onPressed,
    this.autofocus = false,
  });

  final int year;
  final bool isSelected;
  final bool autofocus;
  final VoidCallback onPressed;

  @override
  State<_TimelineYearChip> createState() => _TimelineYearChipState();
}

class _TimelineYearChipState extends State<_TimelineYearChip> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);

    return TvFocusable(
      autofocus: widget.autofocus,
      onPressed: widget.onPressed,
      builder: (context, focusState) {
        final isFocused = focusState.isFocused;
        final isSelected = widget.isSelected;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: scale.space(AppSpacing.md, min: 14, max: 16),
            vertical: scale.space(AppSpacing.sm, min: 10, max: 12),
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.focus.withValues(alpha: 0.18)
                : const Color(0xFF0D1A21),
            borderRadius: BorderRadius.circular(
              scale.radius(AppRadii.pill, min: 999, max: 999),
            ),
            border: Border.all(
              color: isFocused || isSelected
                  ? AppColors.focus
                  : AppColors.border,
              width: isFocused ? 2.4 : (isSelected ? 1.8 : 1),
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.focusGlow,
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          child: Center(
            child: Text(
              '${widget.year}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: scale.text(16, min: 14, max: 16),
              ),
            ),
          ),
        );
      },
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
  return (contentWidth * 0.20).toDouble();
}

List<List<String>> _nearbyThumbnailUrls(
  List<AssetSummary> assets,
  int centerIndex,
) {
  const offsets = [-2, -1, 1, 2, 3];
  final nearby = <List<String>>[];

  for (final offset in offsets) {
    final index = centerIndex + offset;
    if (index < 0 || index >= assets.length) {
      continue;
    }

    final thumbnails = assets[index].thumbnailUrls;
    if (thumbnails.isEmpty) {
      continue;
    }
    nearby.add(thumbnails);
  }

  return nearby;
}

List<int> _timelineYearRange() {
  final currentYear = DateTime.now().year;
  return List<int>.generate(51, (index) => currentYear - index);
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

String _sectionViewState(
  LibraryLoadStatus status,
  List<AssetSummary> assets,
) {
  if (status == LibraryLoadStatus.loading) {
    return 'loading';
  }

  if (status == LibraryLoadStatus.failure) {
    return 'failure';
  }

  if (assets.isEmpty) {
    return 'empty';
  }

  return 'content';
}

SliverGridDelegate _buildAssetGridDelegate(
  double availableWidth,
  Size screenSize,
) {
  const spacing = 8.0;
  final crossAxisCount = _resolveGridCrossAxisCount(screenSize);
  final aspectRatio = availableWidth >= 3200
      ? 1.14
      : availableWidth >= 2400
      ? 1.08
      : availableWidth >= 1600
      ? 1.02
      : 1.0;

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: spacing,
    crossAxisSpacing: spacing,
    childAspectRatio: aspectRatio,
  );
}

int _resolveGridCrossAxisCount(Size screenSize) {
  return screenSize.width > screenSize.height ? 8 : 5;
}

bool _useCompactTvChrome(AppScale scale) {
  return scale.isTvLayout && scale.size.height >= 900;
}
