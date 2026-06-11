part of 'home_screen.dart';

class _PeopleSectionView extends StatelessWidget {
  const _PeopleSectionView({
    required this.session,
    required this.status,
    required this.errorMessage,
    required this.people,
    required this.isSidebarOpen,
    required this.menuToggleFocusNode,
    required this.primaryContentFocusNode,
    required this.onToggleSidebar,
    required this.onOpenSidebar,
  });

  final AuthenticatedSession session;
  final LibraryLoadStatus status;
  final String? errorMessage;
  final List<PersonSummary> people;
  final bool isSidebarOpen;
  final FocusNode menuToggleFocusNode;
  final FocusNode primaryContentFocusNode;
  final VoidCallback onToggleSidebar;
  final VoidCallback onOpenSidebar;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      title: 'People',
      isSidebarOpen: isSidebarOpen,
      menuToggleFocusNode: menuToggleFocusNode,
      onToggleSidebar: onToggleSidebar,
      child: _PeopleBrowser(
        session: session,
        status: status,
        errorMessage: errorMessage,
        people: people,
        primaryContentFocusNode: primaryContentFocusNode,
        onOpenSidebar: onOpenSidebar,
      ),
    );
  }
}

class _PeopleBrowser extends StatefulWidget {
  const _PeopleBrowser({
    required this.session,
    required this.status,
    required this.errorMessage,
    required this.people,
    required this.primaryContentFocusNode,
    required this.onOpenSidebar,
  });

  final AuthenticatedSession session;
  final LibraryLoadStatus status;
  final String? errorMessage;
  final List<PersonSummary> people;
  final FocusNode primaryContentFocusNode;
  final VoidCallback onOpenSidebar;

  @override
  State<_PeopleBrowser> createState() => _PeopleBrowserState();
}

class _PeopleBrowserState extends State<_PeopleBrowser> {
  static const _personRefreshInterval = Duration(minutes: 1);

  final FocusNode _selectedPersonFocusNode = FocusNode(
    debugLabel: 'people.selected-person',
  );
  PersonSummary? _selectedPerson;
  List<AssetSummary> _personAssets = const [];
  String? _personAssetsNextPage;
  bool _isLoadingPersonAssets = false;
  String? _personAssetsError;
  Timer? _personRefreshTimer;

  @override
  void dispose() {
    _personRefreshTimer?.cancel();
    _selectedPersonFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _PeopleBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.people.isEmpty) {
      _selectedPerson = null;
      _personAssets = const [];
      _personAssetsNextPage = null;
      _personAssetsError = null;
      _isLoadingPersonAssets = false;
      return;
    }

    final selectedPersonStillExists =
        _selectedPerson != null &&
        widget.people.any((person) => person.id == _selectedPerson!.id);
    if (!selectedPersonStillExists) {
      _selectPerson(widget.people.first);
      return;
    }

    if (_selectedPerson != null) {
      final refreshedSelectedPerson = widget.people.firstWhere(
        (person) => person.id == _selectedPerson!.id,
      );
      if (refreshedSelectedPerson != _selectedPerson) {
        _selectedPerson = refreshedSelectedPerson;
      }
    }
  }

  @override
  Widget build(BuildContext context) => _buildBody(context);

  Widget _buildBody(BuildContext context) {
    if (widget.status == LibraryLoadStatus.loading) {
      return const _AlbumBrowserLoadingSkeleton();
    }

    if (widget.status == LibraryLoadStatus.failure) {
      return _InfoPanel(
        title: 'People are unavailable right now',
        body: widget.errorMessage ?? 'Try again in a moment.',
        accent: AppColors.error,
      );
    }

    if (widget.people.isEmpty) {
      return const _InfoPanel(
        title: 'No people yet',
        body: 'Recognized faces will appear here.',
        accent: AppColors.textMuted,
      );
    }

    final selectedPerson = _selectedPerson ?? widget.people.first;

    if (_selectedPerson == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectPerson(widget.people.first);
        }
      });
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = AppScale.of(context);
        final peopleRail = _PeopleRail(
          session: widget.session,
          people: widget.people,
          selectedPerson: selectedPerson,
          onPersonSelected: _selectPerson,
          primaryContentFocusNode: widget.primaryContentFocusNode,
          selectedPersonFocusNode: _selectedPersonFocusNode,
          onOpenDrawer: widget.onOpenSidebar,
        );

        return Row(
          children: [
            SizedBox(
              width: _responsiveAlbumRailWidth(constraints.maxWidth, scale),
              child: peopleRail,
            ),
            SizedBox(width: scale.space(AppSpacing.xl, min: 24, max: 32)),
            Expanded(child: _buildPersonContent(selectedPerson)),
          ],
        );
      },
    );
  }

  void _selectPerson(PersonSummary person) {
    _ensurePersonRefreshPolling();
    setState(() {
      _selectedPerson = person;
      _personAssets = const [];
      _personAssetsNextPage = null;
      _personAssetsError = null;
      _isLoadingPersonAssets = false;
    });
    _loadPersonAssets(person: person, page: null, replace: true);
  }

  Widget _buildPersonContent(PersonSummary selectedPerson) {
    if (_isLoadingPersonAssets && _personAssets.isEmpty) {
      return const _AssetGridLoadingSkeleton(
        leadingHeight: 20,
        leadingWidth: 220,
      );
    }

    if (_personAssetsError != null && _personAssets.isEmpty) {
      return _InfoPanel(
        title: 'This person could not load',
        body: _personAssetsError!,
        accent: AppColors.error,
      );
    }

    if (_personAssets.isEmpty) {
      return _InfoPanel(
        title: 'No assets for ${selectedPerson.name}',
        body:
            'This person does not have any recognized assets that can be displayed yet.',
        accent: AppColors.textMuted,
      );
    }

    return _PersonAssetGrid(
      session: widget.session,
      person: selectedPerson,
      assets: _personAssets,
      hasMore:
          _personAssetsNextPage != null && _personAssetsNextPage!.isNotEmpty,
      isLoadingMore: _isLoadingPersonAssets && _personAssets.isNotEmpty,
      onLoadMore: _loadMorePersonAssets,
      onOpenSidebar: widget.onOpenSidebar,
      onMoveLeftFromGrid: () => _selectedPersonFocusNode.requestFocus(),
    );
  }

  Future<void> _loadMorePersonAssets() async {
    final selectedPerson = _selectedPerson;
    final nextPage = _personAssetsNextPage;
    if (selectedPerson == null || nextPage == null || _isLoadingPersonAssets) {
      return;
    }

    await _loadPersonAssets(
      person: selectedPerson,
      page: nextPage,
      replace: false,
    );
  }

  Future<void> _loadPersonAssets({
    required PersonSummary person,
    required String? page,
    required bool replace,
    bool background = false,
  }) async {
    if (_isLoadingPersonAssets) {
      return;
    }

    if (background) {
      _ensurePersonRefreshPolling();
    } else {
      setState(() {
        _isLoadingPersonAssets = true;
        _personAssetsError = null;
      });
    }

    try {
      final response = await context
          .read<MediaRepository>()
          .fetchPersonAssetsPage(
            widget.session,
            personId: person.id,
            page: page,
          );
      if (!mounted || _selectedPerson?.id != person.id) {
        return;
      }

      final nextAssets = replace
          ? _mergeRefreshedPeopleAssets(
              existing: _personAssets,
              refreshedFirstPage: response.items,
            )
          : [
              ..._personAssets,
              ..._dedupePeopleAssets(_personAssets, response.items),
            ];
      final hasChanges =
          !_listEquals(_personAssets, nextAssets) ||
          _personAssetsNextPage != response.nextPage ||
          _isLoadingPersonAssets;
      if (!hasChanges && background) {
        return;
      }

      setState(() {
        _personAssets = nextAssets;
        _personAssetsNextPage = response.nextPage;
        _isLoadingPersonAssets = false;
        if (!background) {
          _personAssetsError = null;
        }
      });
    } catch (error) {
      if (!mounted || _selectedPerson?.id != person.id) {
        return;
      }

      if (background) {
        return;
      }

      setState(() {
        _isLoadingPersonAssets = false;
        _personAssetsError = error is AppException
            ? error.message
            : 'We could not load this person right now.';
      });
    }
  }

  List<AssetSummary> _dedupePeopleAssets(
    List<AssetSummary> existing,
    List<AssetSummary> incoming,
  ) {
    final existingIds = existing.map((item) => item.id).toSet();
    return incoming
        .where((item) => !existingIds.contains(item.id))
        .toList(growable: false);
  }

  List<AssetSummary> _mergeRefreshedPeopleAssets({
    required List<AssetSummary> existing,
    required List<AssetSummary> refreshedFirstPage,
  }) {
    if (existing.isEmpty) {
      return refreshedFirstPage;
    }

    if (_listEquals(existing, refreshedFirstPage)) {
      return existing;
    }

    final refreshedIds = refreshedFirstPage.map((item) => item.id).toSet();
    return List<AssetSummary>.unmodifiable([
      ...refreshedFirstPage,
      ...existing.where((item) => !refreshedIds.contains(item.id)),
    ]);
  }

  bool _listEquals(List<AssetSummary> left, List<AssetSummary> right) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i++) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }

  void _ensurePersonRefreshPolling() {
    _personRefreshTimer ??= Timer.periodic(_personRefreshInterval, (_) {
      final selectedPerson = _selectedPerson;
      if (!mounted ||
          selectedPerson == null ||
          widget.status != LibraryLoadStatus.success) {
        return;
      }
      unawaited(
        _loadPersonAssets(
          person: selectedPerson,
          page: null,
          replace: true,
          background: true,
        ),
      );
    });
  }
}

class _PeopleRail extends StatelessWidget {
  const _PeopleRail({
    required this.session,
    required this.people,
    required this.selectedPerson,
    required this.onPersonSelected,
    required this.primaryContentFocusNode,
    required this.selectedPersonFocusNode,
    required this.onOpenDrawer,
  });

  final AuthenticatedSession session;
  final List<PersonSummary> people;
  final PersonSummary selectedPerson;
  final ValueChanged<PersonSummary> onPersonSelected;
  final FocusNode primaryContentFocusNode;
  final FocusNode selectedPersonFocusNode;
  final VoidCallback onOpenDrawer;

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);
    return ListView.separated(
      key: const PageStorageKey<String>('people-rail-vertical'),
      itemCount: people.length,
      separatorBuilder: (_, _) =>
          SizedBox(height: scale.space(AppSpacing.sm, min: 10, max: 12)),
      itemBuilder: (context, index) {
        final person = people[index];
        return _PersonSummaryTile(
          session: session,
          person: person,
          isSelected: person.id == selectedPerson.id,
          focusNode: person.id == selectedPerson.id
              ? selectedPersonFocusNode
              : (index == 0 ? primaryContentFocusNode : null),
          onOpenDrawer: onOpenDrawer,
          onPressed: () => onPersonSelected(person),
        );
      },
    );
  }
}

class _PersonSummaryTile extends StatefulWidget {
  const _PersonSummaryTile({
    required this.session,
    required this.person,
    required this.isSelected,
    this.focusNode,
    this.onOpenDrawer,
    required this.onPressed,
  });

  final AuthenticatedSession session;
  final PersonSummary person;
  final bool isSelected;
  final FocusNode? focusNode;
  final VoidCallback? onOpenDrawer;
  final VoidCallback onPressed;

  @override
  State<_PersonSummaryTile> createState() => _PersonSummaryTileState();
}

class _PersonSummaryTileState extends State<_PersonSummaryTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    final tile = TvFocusable(
      focusNode: widget.focusNode,
      onPressed: widget.onPressed,
      builder: (context, focusState) {
        final isFocused = focusState.isFocused;
        final isActive = widget.isSelected || focusState.isActive;

        return AnimatedContainer(
          duration: AppDurations.normal,
          padding: EdgeInsets.all(scale.space(AppSpacing.lg, min: 20, max: 24)),
          decoration: AppFocusDecoration.surface(
            isFocused: isFocused,
            isActive: isActive,
            isSelected: widget.isSelected,
            backgroundColor: const Color(0xFF0D1A21),
            activeBackgroundColor: const Color(0xFF13212A),
            borderRadius: BorderRadius.circular(
              scale.radius(AppRadii.lg, min: 20, max: 24),
            ),
          ),
          child: Row(
            children: [
              _PersonAvatar(session: widget.session, person: widget.person),
              SizedBox(width: scale.space(AppSpacing.md, min: 14, max: 16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: scale.text(22, min: 18, max: 22),
                      ),
                    ),
                    SizedBox(
                      height: scale.space(AppSpacing.xs, min: 6, max: 8),
                    ),
                    Text(
                      '${widget.person.assetCount} assets',
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
        );
      },
    );

    if (widget.onOpenDrawer == null) {
      return tile;
    }

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowLeft): _OpenDrawerIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _OpenDrawerIntent: CallbackAction<_OpenDrawerIntent>(
            onInvoke: (_) {
              widget.onOpenDrawer?.call();
              return null;
            },
          ),
        },
        child: tile,
      ),
    );
  }
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.session, required this.person});

  final AuthenticatedSession session;
  final PersonSummary person;

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);
    final size = scale.sizeOf(68, min: 58, max: 72);
    final primaryUrl = person.thumbnailUrls.isNotEmpty
        ? person.thumbnailUrls.first
        : null;

    if (primaryUrl != null && primaryUrl.startsWith('mock://')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surfaceMuted,
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Center(
          child: Text(
            person.name.characters.first.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: scale.text(24, min: 20, max: 26),
            ),
          ),
        ),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: AuthenticatedAssetImage(
          imageUrls: person.thumbnailUrls,
          accessToken: session.accessToken,
          authMethod: session.authMethod,
          requiresAuth: true,
          fit: BoxFit.cover,
          placeholderIcon: Icons.person_outline_rounded,
        ),
      ),
    );
  }
}

class _PersonAssetGrid extends StatelessWidget {
  const _PersonAssetGrid({
    required this.session,
    required this.person,
    required this.assets,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.onOpenSidebar,
    required this.onMoveLeftFromGrid,
  });

  final AuthenticatedSession session;
  final PersonSummary person;
  final List<AssetSummary> assets;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;
  final VoidCallback onOpenSidebar;
  final VoidCallback onMoveLeftFromGrid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          person.name,
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
                final screenSize = MediaQuery.sizeOf(context);
                final crossAxisCount = _resolveGridCrossAxisCount(screenSize);
                return GridView.builder(
                  key: PageStorageKey<String>('person-grid-${person.id}'),
                  cacheExtent: 240,
                  gridDelegate: _buildAssetGridDelegate(
                    constraints.maxWidth,
                    screenSize,
                  ),
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
                      onMoveLeft: index % crossAxisCount == 0
                          ? onMoveLeftFromGrid
                          : null,
                      openDrawerOnLeft: index % crossAxisCount == 0,
                      onOpenDrawer: onOpenSidebar,
                      prefetchUrls: _nearbyThumbnailUrls(assets, index),
                      onPressed: () => AssetViewerScreen.show(
                        context,
                        assets: assets,
                        initialIndex: index,
                        accessToken: session.accessToken,
                        authMethod: session.authMethod,
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
