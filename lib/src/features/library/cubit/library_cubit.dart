import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/authenticated_session.dart';
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
              timeline: timeline,
              status: LibraryLoadStatus.success,
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
              clearError: true,
            ),
          );
        case LibraryTab.favorites:
          final favorites = await _mediaRepository.fetchFavoritesPage(_session);
          emit(
            state.copyWith(
              selectedTab: tab,
              favorites: favorites,
              status: LibraryLoadStatus.success,
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
}
