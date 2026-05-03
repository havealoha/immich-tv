import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/media_page.dart';
import '../../../core/repositories/media_repository.dart';
import 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit(this._mediaRepository, this._session)
    : super(const LibraryState());

  final MediaRepository _mediaRepository;
  final AuthenticatedSession _session;

  Future<void> loadInitial() => selectTab(state.selectedTab);

  Future<void> selectTab(LibraryTab tab) async {
    emit(
      state.copyWith(
        selectedTab: tab,
        status: LibraryLoadStatus.loading,
        clearError: true,
      ),
    );

    if (tab == LibraryTab.slideshow) {
      emit(
        state.copyWith(
          selectedTab: tab,
          status: LibraryLoadStatus.success,
          clearError: true,
        ),
      );
      return;
    }

    try {
      switch (tab) {
        case LibraryTab.timeline:
          final timeline = await _mediaRepository.fetchTimelinePage(_session);
          emit(
            state.copyWith(
              selectedTab: tab,
              timeline: timeline.items,
              timelineNextPage: timeline.nextPage,
              clearTimelineNextPage: timeline.nextPage == null,
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
              status: LibraryLoadStatus.success,
              isLoadingMore: false,
              clearError: true,
            ),
          );
        case LibraryTab.slideshow:
          break;
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
      case LibraryTab.slideshow:
        return;
    }
  }

  Future<void> _appendTimelinePage(String page) async {
    emit(state.copyWith(isLoadingMore: true, clearError: true));

    try {
      final response = await _mediaRepository.fetchTimelinePage(
        _session,
        page: page,
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
}
