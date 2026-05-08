import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/media_page.dart';
import '../../../core/repositories/media_repository.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._mediaRepository, this._session)
    : super(LibraryState(selectedTimelineYear: DateTime.now().year));

  final MediaRepository _mediaRepository;
  final AuthenticatedSession _session;

  Future<void> loadInitial() async {
    emit(state.copyWith(status: LibraryLoadStatus.loading, clearError: true));

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

      emit(
        state.copyWith(
          status: LibraryLoadStatus.success,
          timeline: timeline.items,
          timelineNextPage: timeline.nextPage,
          clearTimelineNextPage: timeline.nextPage == null,
          favorites: favorites.items,
          favoritesNextPage: favorites.nextPage,
          clearFavoritesNextPage: favorites.nextPage == null,
          albums: albums,
          hasLoadedTimeline: true,
          hasLoadedFavorites: true,
          hasLoadedAlbums: true,
          isLoadingMore: false,
          clearError: true,
        ),
      );
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
      LibraryTab.favorites => state.hasLoadedFavorites,
    };
  }
}
