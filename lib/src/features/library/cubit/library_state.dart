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
    this.errorMessage,
  });

  final LibraryTab selectedTab;
  final LibraryLoadStatus status;
  final List<AssetSummary> timeline;
  final List<AlbumSummary> albums;
  final List<AssetSummary> favorites;
  final String? errorMessage;

  bool get isLoading => status == LibraryLoadStatus.loading;

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
    String? errorMessage,
    bool clearError = false,
  }) {
    return LibraryState(
      selectedTab: selectedTab ?? this.selectedTab,
      status: status ?? this.status,
      timeline: timeline ?? this.timeline,
      albums: albums ?? this.albums,
      favorites: favorites ?? this.favorites,
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
    errorMessage,
  ];
}
