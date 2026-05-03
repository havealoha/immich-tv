import 'package:equatable/equatable.dart';

import '../../../core/models/album_summary.dart';
import '../../../core/models/asset_summary.dart';

enum LibraryTab { timeline, albums, favorites, slideshow }

enum LibraryLoadStatus { idle, loading, success, failure }

class LibraryState extends Equatable {
  const LibraryState({
    this.selectedTab = LibraryTab.timeline,
    this.status = LibraryLoadStatus.idle,
    this.timeline = const [],
    this.albums = const [],
    this.favorites = const [],
    this.timelineNextPage,
    this.favoritesNextPage,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final LibraryTab selectedTab;
  final LibraryLoadStatus status;
  final List<AssetSummary> timeline;
  final List<AlbumSummary> albums;
  final List<AssetSummary> favorites;
  final String? timelineNextPage;
  final String? favoritesNextPage;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get isLoading => status == LibraryLoadStatus.loading;

  bool get hasMoreTimeline =>
      timelineNextPage != null && timelineNextPage!.isNotEmpty;

  bool get hasMoreFavorites =>
      favoritesNextPage != null && favoritesNextPage!.isNotEmpty;

  bool get hasMoreForSelectedTab {
    return switch (selectedTab) {
      LibraryTab.timeline => hasMoreTimeline,
      LibraryTab.favorites => hasMoreFavorites,
      LibraryTab.albums || LibraryTab.slideshow => false,
    };
  }

  List<Object> get activeItems {
    return switch (selectedTab) {
      LibraryTab.timeline => timeline,
      LibraryTab.albums => albums,
      LibraryTab.favorites => favorites,
      LibraryTab.slideshow => const [],
    };
  }

  LibraryState copyWith({
    LibraryTab? selectedTab,
    LibraryLoadStatus? status,
    List<AssetSummary>? timeline,
    List<AlbumSummary>? albums,
    List<AssetSummary>? favorites,
    String? timelineNextPage,
    String? favoritesNextPage,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    bool clearTimelineNextPage = false,
    bool clearFavoritesNextPage = false,
  }) {
    return LibraryState(
      selectedTab: selectedTab ?? this.selectedTab,
      status: status ?? this.status,
      timeline: timeline ?? this.timeline,
      albums: albums ?? this.albums,
      favorites: favorites ?? this.favorites,
      timelineNextPage: clearTimelineNextPage
          ? null
          : (timelineNextPage ?? this.timelineNextPage),
      favoritesNextPage: clearFavoritesNextPage
          ? null
          : (favoritesNextPage ?? this.favoritesNextPage),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    selectedTab,
    status,
    timeline,
    albums,
    favorites,
    timelineNextPage,
    favoritesNextPage,
    isLoadingMore,
    errorMessage,
  ];
}
