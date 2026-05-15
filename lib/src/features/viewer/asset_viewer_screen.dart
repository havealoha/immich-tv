import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/asset_summary.dart';
import '../../core/network/immich_headers.dart';
import '../../core/repositories/asset_image_repository.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/authenticated_asset_image.dart';
import '../../shared/presentation/widgets/loading_skeleton.dart';
import '../../shared/presentation/widgets/tv_focusable.dart';
import '../slideshow/slideshow_player_screen.dart';
import 'cubit/asset_viewer_cubit.dart';

part 'asset_viewer_controls.part.dart';
part 'asset_viewer_media.part.dart';

class AssetViewerScreen extends StatelessWidget {
  const AssetViewerScreen({
    super.key,
    required this.assets,
    required this.initialIndex,
    required this.accessToken,
  });

  final List<AssetSummary> assets;
  final int initialIndex;
  final String accessToken;

  static Future<void> show(
    BuildContext context, {
    required List<AssetSummary> assets,
    required int initialIndex,
    required String accessToken,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AssetViewerScreen(
              assets: assets,
              initialIndex: initialIndex,
              accessToken: accessToken,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          AssetViewerCubit(assets: assets, initialIndex: initialIndex),
      child: _AssetViewerView(accessToken: accessToken),
    );
  }
}

class _AssetViewerView extends StatefulWidget {
  const _AssetViewerView({required this.accessToken});

  final String accessToken;

  @override
  State<_AssetViewerView> createState() => _AssetViewerViewState();
}

class _AssetViewerViewState extends State<_AssetViewerView> {
  static const _slideshowDurationOptions = <int>[5, 8, 12];
  late final PageController _pageController;
  late final FocusNode _viewerFocusNode;
  late final FocusNode _slideshowButtonFocusNode;
  late final FocusNode _closeButtonFocusNode;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<AssetViewerCubit>().state.currentIndex;
    _pageController = PageController(initialPage: initialIndex);
    _viewerFocusNode = FocusNode(debugLabel: 'viewer-surface');
    _slideshowButtonFocusNode = FocusNode(debugLabel: 'viewer-slideshow');
    _closeButtonFocusNode = FocusNode(debugLabel: 'viewer-close');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _prefetchNearbyViewerImages(context.read<AssetViewerCubit>().state);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewerFocusNode.dispose();
    _slideshowButtonFocusNode.dispose();
    _closeButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetViewerCubit, AssetViewerState>(
      builder: (context, state) {
        final slideshowEnabled = state.assets.any((asset) => !asset.isVideo);

        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviousIntent(),
            SingleActivator(LogicalKeyboardKey.arrowRight): _NextIntent(),
            SingleActivator(LogicalKeyboardKey.arrowDown): _FocusActionsIntent(),
            SingleActivator(LogicalKeyboardKey.arrowUp): _FocusViewerIntent(),
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _PreviousIntent: CallbackAction<_PreviousIntent>(
                onInvoke: (_) => _handlePrevious(state),
              ),
              _NextIntent: CallbackAction<_NextIntent>(
                onInvoke: (_) => _handleNext(state, slideshowEnabled),
              ),
              _FocusActionsIntent: CallbackAction<_FocusActionsIntent>(
                onInvoke: (_) => _focusActionButtons(slideshowEnabled),
              ),
              _FocusViewerIntent: CallbackAction<_FocusViewerIntent>(
                onInvoke: (_) => _focusViewerSurface(),
              ),
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => Navigator.of(context).maybePop(),
              ),
            },
            child: Focus(
              focusNode: _viewerFocusNode,
              autofocus: true,
              child: Scaffold(
                backgroundColor: AppColors.background,
                body: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: state.assets.length,
                      onPageChanged: context.read<AssetViewerCubit>().jumpTo,
                      itemBuilder: (context, index) {
                        final asset = state.assets[index];
                        return _ViewerPage(
                          asset: asset,
                          accessToken: widget.accessToken,
                        );
                      },
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: AppSpacing.md,
                      child: _ViewerArrow(
                        icon: Icons.chevron_left,
                        enabled: state.hasPrevious,
                        onPressed: () => _moveTo(state.currentIndex - 1),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: AppSpacing.md,
                      child: _ViewerArrow(
                        icon: Icons.chevron_right,
                        enabled: state.hasNext,
                        onPressed: () => _moveTo(state.currentIndex + 1),
                      ),
                    ),
                    Positioned(
                      top: 48,
                      left: 0,
                      right: 0,
                      child: Align(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.sm,
                            ),
                            child: Text(
                              _formatDate(state.currentAsset.createdAt),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 48,
                      right: 0,
                      left: 0,
                      child: Align(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ViewerActionButton(
                              width: 184,
                              icon: Icons.slideshow_rounded,
                              label: 'Slideshow',
                              enabled: slideshowEnabled,
                              focusNode: _slideshowButtonFocusNode,
                              onPressed: () => _startSlideshow(state),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            _ViewerActionButton(
                              width: 124,
                              icon: Icons.close_rounded,
                              label: 'Close',
                              focusNode: _closeButtonFocusNode,
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _startSlideshow(AssetViewerState state) async {
    final slideshowAssets = state.assets
        .where((asset) => !asset.isVideo)
        .toList(growable: false);
    if (slideshowAssets.isEmpty) {
      return;
    }

    final durationSeconds = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _SlideshowConfigDialog(
        durationOptions: _slideshowDurationOptions,
        photoCount: slideshowAssets.length,
        currentAssetIsVideo: state.currentAsset.isVideo,
        totalAssetCount: state.assets.length,
      ),
    );

    if (!mounted || durationSeconds == null) {
      return;
    }

    final initialSlideshowIndex = slideshowAssets.indexWhere(
      (asset) => asset.id == state.currentAsset.id,
    );

    await SlideshowPlayerScreen.show(
      context,
      assets: slideshowAssets,
      accessToken: widget.accessToken,
      initialDurationSeconds: durationSeconds,
      initialIndex: initialSlideshowIndex >= 0 ? initialSlideshowIndex : 0,
    );
  }

  Object? _handlePrevious(AssetViewerState state) {
    if (_closeButtonFocusNode.hasFocus) {
      _slideshowButtonFocusNode.requestFocus();
      return null;
    }

    if (_slideshowButtonFocusNode.hasFocus) {
      return null;
    }

    _moveTo(state.currentIndex - 1);
    return null;
  }

  Object? _handleNext(AssetViewerState state, bool slideshowEnabled) {
    if (_slideshowButtonFocusNode.hasFocus) {
      _closeButtonFocusNode.requestFocus();
      return null;
    }

    if (_closeButtonFocusNode.hasFocus) {
      return null;
    }

    if (!slideshowEnabled && _viewerFocusNode.hasFocus) {
      _closeButtonFocusNode.requestFocus();
      return null;
    }

    _moveTo(state.currentIndex + 1);
    return null;
  }

  Object? _focusActionButtons(bool slideshowEnabled) {
    if (_slideshowButtonFocusNode.hasFocus || _closeButtonFocusNode.hasFocus) {
      return null;
    }

    if (slideshowEnabled) {
      _slideshowButtonFocusNode.requestFocus();
    } else {
      _closeButtonFocusNode.requestFocus();
    }
    return null;
  }

  Object? _focusViewerSurface() {
    if (_slideshowButtonFocusNode.hasFocus || _closeButtonFocusNode.hasFocus) {
      _viewerFocusNode.requestFocus();
    }
    return null;
  }

  void _moveTo(int index) {
    final cubit = context.read<AssetViewerCubit>();
    if (index < 0 || index >= cubit.state.assets.length) {
      return;
    }

    cubit.jumpTo(index);
    _prefetchNearbyViewerImages(cubit.state.copyWith(currentIndex: index));
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _prefetchNearbyViewerImages(AssetViewerState state) {
    final nearby = <List<String>>[];
    for (final offset in const [-1, 1, 2]) {
      final targetIndex = state.currentIndex + offset;
      if (targetIndex < 0 || targetIndex >= state.assets.length) {
        continue;
      }

      final asset = state.assets[targetIndex];
      if (asset.isVideo) {
        continue;
      }
      nearby.add(asset.displayUrls);
    }

    if (nearby.isEmpty) {
      return;
    }

    context.read<AssetImageRepository>().prefetchImages(
      urls: nearby,
      accessToken: widget.accessToken,
    );
  }
}
