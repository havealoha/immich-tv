import 'package:equatable/equatable.dart';

import '../../../core/models/album_summary.dart';
import '../../../core/models/asset_summary.dart';
import '../../../core/models/person_summary.dart';

enum LibraryTab { timeline, albums, people, favorites }

enum LibraryLoadStatus { idle, loading, success, failure }

class LibraryState extends Equatable {
  const LibraryState({
    this.selectedTab = LibraryTab.timeline,
    this.selectedTimelineYear = 0,
    this.status = LibraryLoadStatus.idle,
    this.timeline = const [],
    this.albums = const [],
    this.people = const [],
    this.favorites = const [],
    this.hasLoadedTimeline = false,
    this.hasLoadedAlbums = false,
    this.hasLoadedPeople = false,
    this.hasLoadedFavorites = false,
    this.timelineNextPage,
    this.favoritesNextPage,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final LibraryTab selectedTab;
  final int selectedTimelineYear;
  final LibraryLoadStatus status;
  final List<AssetSummary> timeline;
  final List<AlbumSummary> albums;
  final List<PersonSummary> people;
  final List<AssetSummary> favorites;
  final bool hasLoadedTimeline;
  final bool hasLoadedAlbums;
  final bool hasLoadedPeople;
  final bool hasLoadedFavorites;
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
      LibraryTab.people => false,
      LibraryTab.favorites => hasMoreFavorites,
      LibraryTab.albums => false,
    };
  }

  List<Object> get activeItems {
    return switch (selectedTab) {
      LibraryTab.timeline => timeline,
      LibraryTab.albums => albums,
      LibraryTab.people => people,
      LibraryTab.favorites => favorites,
    };
  }

  LibraryState copyWith({
    LibraryTab? selectedTab,
    int? selectedTimelineYear,
    LibraryLoadStatus? status,
    List<AssetSummary>? timeline,
    List<AlbumSummary>? albums,
    List<PersonSummary>? people,
    List<AssetSummary>? favorites,
    bool? hasLoadedTimeline,
    bool? hasLoadedAlbums,
    bool? hasLoadedPeople,
    bool? hasLoadedFavorites,
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
      selectedTimelineYear: selectedTimelineYear ?? this.selectedTimelineYear,
      status: status ?? this.status,
      timeline: timeline ?? this.timeline,
      albums: albums ?? this.albums,
      people: people ?? this.people,
      favorites: favorites ?? this.favorites,
      hasLoadedTimeline: hasLoadedTimeline ?? this.hasLoadedTimeline,
      hasLoadedAlbums: hasLoadedAlbums ?? this.hasLoadedAlbums,
      hasLoadedPeople: hasLoadedPeople ?? this.hasLoadedPeople,
      hasLoadedFavorites: hasLoadedFavorites ?? this.hasLoadedFavorites,
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
    selectedTimelineYear,
    status,
    timeline,
    albums,
    people,
    favorites,
    hasLoadedTimeline,
    hasLoadedAlbums,
    hasLoadedPeople,
    hasLoadedFavorites,
    timelineNextPage,
    favoritesNextPage,
    isLoadingMore,
    errorMessage,
  ];
}
