import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/album_summary.dart';
import '../../../core/models/asset_summary.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/media_page.dart';
import '../../../core/models/person_summary.dart';
import '../../../core/repositories/media_repository.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(
    this._mediaRepository,
    this._session, {
    Duration refreshInterval = const Duration(minutes: 1),
  }) : _refreshInterval = refreshInterval,
       super(LibraryState(selectedTimelineYear: DateTime.now().year));

  final MediaRepository _mediaRepository;
  final AuthenticatedSession _session;
  final Duration _refreshInterval;
  Timer? _refreshTimer;
  bool _isRefreshing = false;

  Future<void> loadInitial() async {
    emit(state.copyWith(status: LibraryLoadStatus.loading, clearError: true));

    try {
      final timeline = await _mediaRepository.fetchTimelinePage(
        _session,
        year: state.selectedTimelineYear,
      );

      emit(
        state.copyWith(
          status: LibraryLoadStatus.success,
          timeline: timeline.items,
          timelineNextPage: timeline.nextPage,
          clearTimelineNextPage: timeline.nextPage == null,
          hasLoadedTimeline: true,
          isLoadingMore: false,
          clearError: true,
        ),
      );
      _ensureRefreshPolling();
      unawaited(_preloadInitialSupportingSections());
    } catch (error) {
      emit(
        state.copyWith(
          status: LibraryLoadStatus.failure,
          errorMessage: error is AppException
              ? error.message
              : 'We could not load your library right now.',
        ),
      );
    }
  }

  Future<void> _preloadInitialSupportingSections() async {
    final nextAlbums = await _safeFetchAlbums();
    final nextFavorites = await _safeFetchFavorites();
    final nextPeople = await _safeFetchPeople();

    if (isClosed) {
      return;
    }

    final nextState = state.copyWith(
      albums: nextAlbums ?? state.albums,
      hasLoadedAlbums: nextAlbums != null || state.hasLoadedAlbums,
      favorites: nextFavorites?.items ?? state.favorites,
      favoritesNextPage: nextFavorites?.nextPage,
      clearFavoritesNextPage:
          nextFavorites != null && nextFavorites.nextPage == null,
      hasLoadedFavorites: nextFavorites != null || state.hasLoadedFavorites,
      people: nextPeople ?? state.people,
      hasLoadedPeople: nextPeople != null || state.hasLoadedPeople,
    );

    if (nextState != state) {
      emit(nextState);
    }
  }

  Future<void> selectTab(LibraryTab tab) async {
    if (_isTabLoaded(tab)) {
      emit(
        state.copyWith(
          selectedTab: tab,
          status: LibraryLoadStatus.success,
          clearError: true,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        selectedTab: tab,
        status: LibraryLoadStatus.loading,
        clearError: true,
      ),
    );

    try {
      switch (tab) {
        case LibraryTab.timeline:
          final timeline = await _mediaRepository.fetchTimelinePage(
            _session,
            year: state.selectedTimelineYear,
          );
          emit(
            state.copyWith(
              selectedTab: tab,
              timeline: timeline.items,
              timelineNextPage: timeline.nextPage,
              clearTimelineNextPage: timeline.nextPage == null,
              hasLoadedTimeline: true,
              status: LibraryLoadStatus.success,
              isLoadingMore: false,
              clearError: true,
            ),
          );
          _ensureRefreshPolling();
        case LibraryTab.albums:
          final albums = await _mediaRepository.fetchAlbums(_session);
          emit(
            state.copyWith(
              selectedTab: tab,
              albums: albums,
              hasLoadedAlbums: true,
              status: LibraryLoadStatus.success,
              isLoadingMore: false,
              clearError: true,
            ),
          );
          _ensureRefreshPolling();
        case LibraryTab.people:
          final people = await _mediaRepository.fetchPeople(_session);
          emit(
            state.copyWith(
              selectedTab: tab,
              people: people,
              hasLoadedPeople: true,
              status: LibraryLoadStatus.success,
              isLoadingMore: false,
              clearError: true,
            ),
          );
          _ensureRefreshPolling();
        case LibraryTab.favorites:
          final favorites = await _mediaRepository.fetchFavoritesPage(_session);
          emit(
            state.copyWith(
              selectedTab: tab,
              favorites: favorites.items,
              favoritesNextPage: favorites.nextPage,
              clearFavoritesNextPage: favorites.nextPage == null,
              hasLoadedFavorites: true,
              status: LibraryLoadStatus.success,
              isLoadingMore: false,
              clearError: true,
            ),
          );
          _ensureRefreshPolling();
      }
    } catch (error) {
      emit(
        state.copyWith(
          selectedTab: tab,
          status: LibraryLoadStatus.failure,
          errorMessage: error is AppException
              ? error.message
              : 'We could not load this section right now.',
        ),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.status != LibraryLoadStatus.success || state.isLoadingMore) {
      return;
    }

    switch (state.selectedTab) {
      case LibraryTab.timeline:
        if (!state.hasMoreTimeline) {
          return;
        }
        await _appendTimelinePage(state.timelineNextPage!);
      case LibraryTab.favorites:
        if (!state.hasMoreFavorites) {
          return;
        }
        await _appendFavoritesPage(state.favoritesNextPage!);
      case LibraryTab.people:
        return;
      case LibraryTab.albums:
        return;
    }
  }

  Future<void> selectTimelineYear(int year) async {
    if (state.selectedTimelineYear == year &&
        state.selectedTab == LibraryTab.timeline &&
        state.hasLoadedTimeline) {
      return;
    }

    emit(
      state.copyWith(
        selectedTimelineYear: year,
        selectedTab: LibraryTab.timeline,
        status: LibraryLoadStatus.loading,
        clearError: true,
      ),
    );

    try {
      final timeline = await _mediaRepository.fetchTimelinePage(
        _session,
        year: year,
      );
      emit(
        state.copyWith(
          selectedTimelineYear: year,
          selectedTab: LibraryTab.timeline,
          timeline: timeline.items,
          timelineNextPage: timeline.nextPage,
          clearTimelineNextPage: timeline.nextPage == null,
          hasLoadedTimeline: true,
          status: LibraryLoadStatus.success,
          isLoadingMore: false,
          clearError: true,
        ),
      );
      _ensureRefreshPolling();
    } catch (error) {
      emit(
        state.copyWith(
          selectedTimelineYear: year,
          selectedTab: LibraryTab.timeline,
          status: LibraryLoadStatus.failure,
          errorMessage: error is AppException
              ? error.message
              : 'We could not load this year right now.',
        ),
      );
    }
  }

  Future<void> _appendTimelinePage(String page) async {
    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final response = await _mediaRepository.fetchTimelinePage(
        _session,
        page: page,
        year: state.selectedTimelineYear,
      );
      emit(
        state.copyWith(
          timeline: [
            ...state.timeline,
            ..._dedupeAssets(state.timeline, response),
          ],
          timelineNextPage: response.nextPage,
          clearTimelineNextPage: response.nextPage == null,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: error is AppException
              ? error.message
              : 'We could not load more timeline photos right now.',
        ),
      );
    }
  }

  Future<void> _appendFavoritesPage(String page) async {
    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final response = await _mediaRepository.fetchFavoritesPage(
        _session,
        page: page,
      );
      emit(
        state.copyWith(
          favorites: [
            ...state.favorites,
            ..._dedupeAssets(state.favorites, response),
          ],
          favoritesNextPage: response.nextPage,
          clearFavoritesNextPage: response.nextPage == null,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          errorMessage: error is AppException
              ? error.message
              : 'We could not load more favorite photos right now.',
        ),
      );
    }
  }

  List<dynamic> _dedupeAssets(
    List<dynamic> existing,
    MediaPage<dynamic> response,
  ) {
    final existingIds = existing.map((item) => item.id as String).toSet();
    return response.items
        .where((item) => !existingIds.contains(item.id))
        .toList(growable: false);
  }

  bool _isTabLoaded(LibraryTab tab) {
    return switch (tab) {
      LibraryTab.timeline => state.hasLoadedTimeline,
      LibraryTab.albums => state.hasLoadedAlbums,
      LibraryTab.people => state.hasLoadedPeople,
      LibraryTab.favorites => state.hasLoadedFavorites,
    };
  }

  void _ensureRefreshPolling() {
    _refreshTimer ??= Timer.periodic(_refreshInterval, (_) {
      unawaited(refreshContent());
    });
  }

  Future<List<AlbumSummary>?> _safeFetchAlbums() async {
    try {
      return await _mediaRepository.fetchAlbums(_session);
    } catch (_) {
      return null;
    }
  }

  Future<MediaPage<AssetSummary>?> _safeFetchFavorites() async {
    try {
      return await _mediaRepository.fetchFavoritesPage(_session);
    } catch (_) {
      return null;
    }
  }

  Future<List<PersonSummary>?> _safeFetchPeople() async {
    try {
      return await _mediaRepository.fetchPeople(_session);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshContent() async {
    if (_isRefreshing ||
        state.status != LibraryLoadStatus.success ||
        state.isLoadingMore) {
      return;
    }

    _isRefreshing = true;
    try {
      final timelineFuture = _mediaRepository.fetchTimelinePage(
        _session,
        year: state.selectedTimelineYear,
      );
      final favoritesFuture = _mediaRepository.fetchFavoritesPage(_session);
      final albumsFuture = _mediaRepository.fetchAlbums(_session);
      final timeline = await timelineFuture;
      final favorites = await favoritesFuture;
      final albums = await albumsFuture;

      final refreshedTimeline = _mergeRefreshedAssets(
        existing: state.timeline,
        refreshedFirstPage: timeline.items,
      );
      final refreshedFavorites = _mergeRefreshedAssets(
        existing: state.favorites,
        refreshedFirstPage: favorites.items,
      );

      final nextState = state.copyWith(
        timeline: refreshedTimeline,
        timelineNextPage: timeline.nextPage,
        clearTimelineNextPage: timeline.nextPage == null,
        favorites: refreshedFavorites,
        favoritesNextPage: favorites.nextPage,
        clearFavoritesNextPage: favorites.nextPage == null,
        albums: albums,
        hasLoadedTimeline: true,
        hasLoadedFavorites: true,
        hasLoadedAlbums: true,
        status: LibraryLoadStatus.success,
        clearError: true,
      );

      if (nextState != state) {
        emit(nextState);
      }
    } catch (_) {
      // Keep the current surface stable on background refresh failures.
    } finally {
      _isRefreshing = false;
    }
  }

  List<AssetSummary> _mergeRefreshedAssets({
    required List<AssetSummary> existing,
    required List<AssetSummary> refreshedFirstPage,
  }) {
    if (existing.isEmpty) {
      return refreshedFirstPage;
    }

    if (listEquals(existing, refreshedFirstPage)) {
      return existing;
    }

    final refreshedIds = refreshedFirstPage.map((item) => item.id).toSet();
    final trailingItems = existing
        .where((item) => !refreshedIds.contains(item.id))
        .toList(growable: false);
    return List<AssetSummary>.unmodifiable([
      ...refreshedFirstPage,
      ...trailingItems,
    ]);
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
