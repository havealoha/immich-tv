import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/asset_summary.dart';

class AssetViewerState {
  const AssetViewerState({required this.assets, required this.currentIndex});

  final List<AssetSummary> assets;
  final int currentIndex;

  AssetSummary get currentAsset => assets[currentIndex];

  bool get hasPrevious => currentIndex > 0;

  bool get hasNext => currentIndex < assets.length - 1;

  AssetViewerState copyWith({List<AssetSummary>? assets, int? currentIndex}) {
    return AssetViewerState(
      assets: assets ?? this.assets,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class AssetViewerCubit extends Cubit<AssetViewerState> {
  AssetViewerCubit({
    required List<AssetSummary> assets,
    required int initialIndex,
  }) : super(AssetViewerState(assets: assets, currentIndex: initialIndex));

  void jumpTo(int index) {
    if (index < 0 || index >= state.assets.length) {
      return;
    }

    emit(state.copyWith(currentIndex: index));
  }

  void next() => jumpTo(state.currentIndex + 1);

  void previous() => jumpTo(state.currentIndex - 1);
}
