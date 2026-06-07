import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/asset_summary.dart';
import '../../core/network/immich_headers.dart';
import '../../platform/auth/browser_session_bridge.dart';
import '../../core/repositories/asset_image_repository.dart';
import '../../platform/media/web_authenticated_video_cache.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/authenticated_asset_image.dart';
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
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          final scaleAnimation = Tween<double>(
            begin: 0.985,
            end: 1,
          ).animate(curvedAnimation);
          return FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(scale: scaleAnimation, child: child),
          );
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

class _ViewerVideoScrubberHandle {
  const _ViewerVideoScrubberHandle({
    required this.togglePlayback,
    required this.activate,
    required this.reset,
    required this.toggleLooping,
    required this.isAvailable,
    required this.isPlaying,
    required this.isScrubModeActive,
    required this.isLooping,
  });

  final VoidCallback togglePlayback;
  final VoidCallback activate;
  final VoidCallback reset;
  final VoidCallback toggleLooping;
  final bool Function() isAvailable;
  final bool Function() isPlaying;
  final bool Function() isScrubModeActive;
  final bool Function() isLooping;
}

class _AssetViewerViewState extends State<_AssetViewerView> {
  static const _chromeHideDelay = Duration(milliseconds: 1500);
  static const _wallpaperClockDebugDelay = Duration(seconds: 10);
  static const _wallpaperClockReleaseDelay = Duration(minutes: 2);
  static const _slideshowDurationOptions = <int>[5, 8, 12];
  late final PageController _pageController;
  late final FocusNode _viewerFocusNode;
  late final FocusNode _slideshowButtonFocusNode;
  late final FocusNode _videoPlayPauseButtonFocusNode;
  late final FocusNode _videoScrubberButtonFocusNode;
  late final FocusNode _videoResetButtonFocusNode;
  late final FocusNode _videoLoopButtonFocusNode;
  late final FocusNode _imageFitButtonFocusNode;
  late final FocusNode _wallpaperButtonFocusNode;
  late final FocusNode _closeButtonFocusNode;
  Timer? _chromeHideTimer;
  Timer? _wallpaperClockTimer;
  Timer? _wallpaperClockTicker;
  bool _showChrome = true;
  bool _showWallpaperClock = false;
  bool _wallpaperModeActive = false;
  DateTime _wallpaperClockNow = DateTime.now();
  DateTime? _wallpaperModeActivatedAt;
  _ViewerVideoScrubberHandle? _activeVideoScrubberHandle;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<AssetViewerCubit>().state.currentIndex;
    _pageController = PageController(initialPage: initialIndex);
    _viewerFocusNode = FocusNode(debugLabel: 'viewer-surface');
    _slideshowButtonFocusNode = FocusNode(debugLabel: 'viewer-slideshow');
    _videoPlayPauseButtonFocusNode = FocusNode(
      debugLabel: 'viewer-video-play-pause',
    );
    _videoScrubberButtonFocusNode = FocusNode(
      debugLabel: 'viewer-video-scrubber',
    );
    _videoResetButtonFocusNode = FocusNode(debugLabel: 'viewer-video-reset');
    _videoLoopButtonFocusNode = FocusNode(debugLabel: 'viewer-video-loop');
    _imageFitButtonFocusNode = FocusNode(debugLabel: 'viewer-image-fit');
    _wallpaperButtonFocusNode = FocusNode(debugLabel: 'viewer-wallpaper');
    _closeButtonFocusNode = FocusNode(debugLabel: 'viewer-close');
    _viewerFocusNode.addListener(_handleFocusChange);
    _slideshowButtonFocusNode.addListener(_handleFocusChange);
    _videoPlayPauseButtonFocusNode.addListener(_handleFocusChange);
    _videoScrubberButtonFocusNode.addListener(_handleFocusChange);
    _videoResetButtonFocusNode.addListener(_handleFocusChange);
    _videoLoopButtonFocusNode.addListener(_handleFocusChange);
    _imageFitButtonFocusNode.addListener(_handleFocusChange);
    _wallpaperButtonFocusNode.addListener(_handleFocusChange);
    _closeButtonFocusNode.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _registerInteraction();
      _prefetchNearbyViewerImages(context.read<AssetViewerCubit>().state);
    });
  }

  @override
  void dispose() {
    _chromeHideTimer?.cancel();
    _wallpaperClockTimer?.cancel();
    _wallpaperClockTicker?.cancel();
    _viewerFocusNode.removeListener(_handleFocusChange);
    _slideshowButtonFocusNode.removeListener(_handleFocusChange);
    _videoPlayPauseButtonFocusNode.removeListener(_handleFocusChange);
    _videoScrubberButtonFocusNode.removeListener(_handleFocusChange);
    _videoResetButtonFocusNode.removeListener(_handleFocusChange);
    _videoLoopButtonFocusNode.removeListener(_handleFocusChange);
    _imageFitButtonFocusNode.removeListener(_handleFocusChange);
    _wallpaperButtonFocusNode.removeListener(_handleFocusChange);
    _closeButtonFocusNode.removeListener(_handleFocusChange);
    _pageController.dispose();
    _viewerFocusNode.dispose();
    _slideshowButtonFocusNode.dispose();
    _videoPlayPauseButtonFocusNode.dispose();
    _videoScrubberButtonFocusNode.dispose();
    _videoResetButtonFocusNode.dispose();
    _videoLoopButtonFocusNode.dispose();
    _imageFitButtonFocusNode.dispose();
    _wallpaperButtonFocusNode.dispose();
    _closeButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetViewerCubit, AssetViewerState>(
      builder: (context, state) {
        final slideshowEnabled = state.assets.any((asset) => !asset.isVideo);
        final currentAssetIsVideo = state.currentAsset.isVideo;
        final scrubberEnabled = currentAssetIsVideo;
        final activeVideoHandle = _activeVideoScrubberHandle;
        final isVideoPlaying = activeVideoHandle?.isPlaying() ?? false;
        final loopEnabled = activeVideoHandle?.isLooping() ?? true;
        final imageFitEnabled = !state.currentAsset.isVideo;
        final wallpaperEnabled = !state.currentAsset.isVideo;
        final showWallpaperOverlay =
            _wallpaperModeActive && !state.currentAsset.isVideo;

        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviousIntent(),
            SingleActivator(LogicalKeyboardKey.arrowRight): _NextIntent(),
            SingleActivator(LogicalKeyboardKey.arrowDown):
                _FocusActionsIntent(),
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
                onInvoke: (_) {
                  _registerInteraction();
                  return Navigator.of(context).maybePop();
                },
              ),
            },
            child: Focus(
              focusNode: _viewerFocusNode,
              autofocus: true,
              onKeyEvent: (_, event) {
                _registerInteraction();
                return KeyEventResult.ignored;
              },
              child: Scaffold(
                backgroundColor: AppColors.background,
                body: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) => _registerInteraction(),
                  onPointerMove: (_) => _registerInteraction(),
                  onPointerSignal: (_) => _registerInteraction(),
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: state.assets.length,
                        onPageChanged: (index) {
                          _registerInteraction();
                          context.read<AssetViewerCubit>().jumpTo(index);
                          _scheduleWallpaperClock();
                        },
                        itemBuilder: (context, index) {
                          final asset = state.assets[index];
                          return _ViewerPage(
                            asset: asset,
                            accessToken: widget.accessToken,
                            fitMode: state.imageFitMode,
                            onRegisterVideoScrubberHandle:
                                index == state.currentIndex
                                ? _registerVideoScrubberHandle
                                : null,
                            onVideoScrubberModeChanged:
                                index == state.currentIndex
                                ? _handleVideoScrubberModeChanged
                                : null,
                          );
                        },
                      ),
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedOpacity(
                            opacity: showWallpaperOverlay ? 1 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: const ColoredBox(color: Color(0x4D000000)),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: AppSpacing.md,
                        child: _ChromeVisibility(
                          visible: _showChrome,
                          child: _ViewerArrow(
                            icon: Icons.chevron_left,
                            enabled: state.hasPrevious,
                            onPressed: () {
                              _registerInteraction();
                              _moveTo(state.currentIndex - 1);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: AppSpacing.md,
                        child: _ChromeVisibility(
                          visible: _showChrome,
                          child: _ViewerArrow(
                            icon: Icons.chevron_right,
                            enabled: state.hasNext,
                            onPressed: () {
                              _registerInteraction();
                              _moveTo(state.currentIndex + 1);
                            },
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 0,
                        left: 0,
                        child: _ChromeVisibility(
                          visible: _showChrome,
                          child: Align(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (currentAssetIsVideo)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _ViewerIconActionButton(
                                        icon: isVideoPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        enabled: scrubberEnabled,
                                        focusNode:
                                            _videoPlayPauseButtonFocusNode,
                                        onFocusChange: (_) =>
                                            _registerInteraction(),
                                        onPressed: () {
                                          _registerInteraction();
                                          _activeVideoScrubberHandle
                                              ?.togglePlayback();
                                        },
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      _ViewerIconActionButton(
                                        icon: Icons.video_settings_rounded,
                                        enabled: scrubberEnabled,
                                        focusNode:
                                            _videoScrubberButtonFocusNode,
                                        onFocusChange: (_) =>
                                            _registerInteraction(),
                                        onPressed: () {
                                          _registerInteraction();
                                          _activeVideoScrubberHandle
                                              ?.activate();
                                        },
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      _ViewerIconActionButton(
                                        icon: Icons.restart_alt_rounded,
                                        enabled: scrubberEnabled,
                                        focusNode: _videoResetButtonFocusNode,
                                        onFocusChange: (_) =>
                                            _registerInteraction(),
                                        onPressed: () {
                                          _registerInteraction();
                                          _activeVideoScrubberHandle?.reset();
                                        },
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      _ViewerIconActionButton(
                                        icon: loopEnabled
                                            ? Icons.repeat_one_rounded
                                            : Icons.repeat_rounded,
                                        enabled: scrubberEnabled,
                                        focusNode: _videoLoopButtonFocusNode,
                                        onFocusChange: (_) =>
                                            _registerInteraction(),
                                        onPressed: () {
                                          _registerInteraction();
                                          _activeVideoScrubberHandle
                                              ?.toggleLooping();
                                        },
                                      ),
                                    ],
                                  )
                                else
                                  _ViewerIconActionButton(
                                    icon: Icons.slideshow_rounded,
                                    enabled: slideshowEnabled,
                                    focusNode: _slideshowButtonFocusNode,
                                    onFocusChange: (_) =>
                                        _registerInteraction(),
                                    onPressed: () {
                                      _registerInteraction();
                                      _startSlideshow(state);
                                    },
                                  ),
                                if (imageFitEnabled) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  _ViewerIconActionButton(
                                    icon: _imageFitIcon(state.imageFitMode),
                                    focusNode: _imageFitButtonFocusNode,
                                    onFocusChange: (_) =>
                                        _registerInteraction(),
                                    onPressed: () {
                                      _registerInteraction();
                                      context
                                          .read<AssetViewerCubit>()
                                          .toggleImageFitMode();
                                    },
                                  ),
                                ],
                                if (wallpaperEnabled) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  _ViewerIconActionButton(
                                    icon: Icons.wallpaper_rounded,
                                    focusNode: _wallpaperButtonFocusNode,
                                    onFocusChange: (_) =>
                                        _registerInteraction(),
                                    onPressed: () {
                                      _activateWallpaperMode();
                                    },
                                  ),
                                ],
                                const SizedBox(width: AppSpacing.sm),
                                _ViewerIconActionButton(
                                  icon: Icons.close_rounded,
                                  focusNode: _closeButtonFocusNode,
                                  onFocusChange: (_) => _registerInteraction(),
                                  onPressed: () {
                                    _registerInteraction();
                                    Navigator.of(context).maybePop();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: _ChromeVisibility(
                          visible: _showWallpaperClock,
                          child: _ViewerWallpaperClock(now: _wallpaperClockNow),
                        ),
                      ),
                    ],
                  ),
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
    _registerInteraction();
    if (_activeVideoScrubberHandle?.isScrubModeActive() ?? false) {
      return null;
    }

    if (_closeButtonFocusNode.hasFocus) {
      if (state.currentAsset.isVideo &&
          _videoLoopButtonFocusNode.canRequestFocus) {
        _videoLoopButtonFocusNode.requestFocus();
      } else if (_wallpaperButtonFocusNode.canRequestFocus &&
          !state.currentAsset.isVideo) {
        _wallpaperButtonFocusNode.requestFocus();
      } else if (_imageFitButtonFocusNode.canRequestFocus &&
          !state.currentAsset.isVideo) {
        _imageFitButtonFocusNode.requestFocus();
      } else if (state.currentAsset.isVideo) {
        _videoPlayPauseButtonFocusNode.requestFocus();
      } else {
        _slideshowButtonFocusNode.requestFocus();
      }
      return null;
    }

    if (_wallpaperButtonFocusNode.hasFocus) {
      if (_imageFitButtonFocusNode.canRequestFocus &&
          !state.currentAsset.isVideo) {
        _imageFitButtonFocusNode.requestFocus();
      } else {
        _slideshowButtonFocusNode.requestFocus();
      }
      return null;
    }

    if (_imageFitButtonFocusNode.hasFocus) {
      _slideshowButtonFocusNode.requestFocus();
      return null;
    }

    if (_videoPlayPauseButtonFocusNode.hasFocus) {
      return null;
    }

    if (_videoScrubberButtonFocusNode.hasFocus) {
      _videoPlayPauseButtonFocusNode.requestFocus();
      return null;
    }

    if (_videoResetButtonFocusNode.hasFocus) {
      _videoScrubberButtonFocusNode.requestFocus();
      return null;
    }

    if (_videoLoopButtonFocusNode.hasFocus) {
      _videoResetButtonFocusNode.requestFocus();
      return null;
    }

    if (_slideshowButtonFocusNode.hasFocus) {
      return null;
    }

    _moveTo(state.currentIndex - 1);
    return null;
  }

  Object? _handleNext(AssetViewerState state, bool slideshowEnabled) {
    _registerInteraction();
    if (_activeVideoScrubberHandle?.isScrubModeActive() ?? false) {
      return null;
    }

    if (_slideshowButtonFocusNode.hasFocus) {
      if (_imageFitButtonFocusNode.canRequestFocus &&
          !state.currentAsset.isVideo) {
        _imageFitButtonFocusNode.requestFocus();
      } else if (!state.currentAsset.isVideo) {
        _wallpaperButtonFocusNode.requestFocus();
      } else {
        _closeButtonFocusNode.requestFocus();
      }
      return null;
    }

    if (_videoPlayPauseButtonFocusNode.hasFocus) {
      _videoScrubberButtonFocusNode.requestFocus();
      return null;
    }

    if (_videoScrubberButtonFocusNode.hasFocus) {
      _videoResetButtonFocusNode.requestFocus();
      return null;
    }

    if (_videoResetButtonFocusNode.hasFocus) {
      _videoLoopButtonFocusNode.requestFocus();
      return null;
    }

    if (_videoLoopButtonFocusNode.hasFocus) {
      _closeButtonFocusNode.requestFocus();
      return null;
    }

    if (_imageFitButtonFocusNode.hasFocus) {
      if (!state.currentAsset.isVideo) {
        _wallpaperButtonFocusNode.requestFocus();
      } else {
        _closeButtonFocusNode.requestFocus();
      }
      return null;
    }

    if (_wallpaperButtonFocusNode.hasFocus) {
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
    _registerInteraction();
    if (_activeVideoScrubberHandle?.isScrubModeActive() ?? false) {
      return null;
    }

    if (_slideshowButtonFocusNode.hasFocus ||
        _videoPlayPauseButtonFocusNode.hasFocus ||
        _videoScrubberButtonFocusNode.hasFocus ||
        _videoResetButtonFocusNode.hasFocus ||
        _videoLoopButtonFocusNode.hasFocus ||
        _imageFitButtonFocusNode.hasFocus ||
        _wallpaperButtonFocusNode.hasFocus ||
        _closeButtonFocusNode.hasFocus) {
      return null;
    }

    if (context.read<AssetViewerCubit>().state.currentAsset.isVideo) {
      _videoPlayPauseButtonFocusNode.requestFocus();
    } else if (slideshowEnabled) {
      _slideshowButtonFocusNode.requestFocus();
    } else {
      _closeButtonFocusNode.requestFocus();
    }
    return null;
  }

  Object? _focusViewerSurface() {
    _registerInteraction();
    if (_activeVideoScrubberHandle?.isScrubModeActive() ?? false) {
      return null;
    }

    if (_slideshowButtonFocusNode.hasFocus ||
        _videoPlayPauseButtonFocusNode.hasFocus ||
        _videoScrubberButtonFocusNode.hasFocus ||
        _videoResetButtonFocusNode.hasFocus ||
        _videoLoopButtonFocusNode.hasFocus ||
        _imageFitButtonFocusNode.hasFocus ||
        _wallpaperButtonFocusNode.hasFocus ||
        _closeButtonFocusNode.hasFocus) {
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
    _scheduleWallpaperClock();
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

  bool get _hasAnyActionFocus =>
      _slideshowButtonFocusNode.hasFocus ||
      _videoPlayPauseButtonFocusNode.hasFocus ||
      _videoScrubberButtonFocusNode.hasFocus ||
      _videoResetButtonFocusNode.hasFocus ||
      _videoLoopButtonFocusNode.hasFocus ||
      _imageFitButtonFocusNode.hasFocus ||
      _wallpaperButtonFocusNode.hasFocus ||
      _closeButtonFocusNode.hasFocus;

  void _registerVideoScrubberHandle(_ViewerVideoScrubberHandle? handle) {
    if (!mounted) {
      return;
    }
    if (identical(_activeVideoScrubberHandle, handle)) {
      return;
    }
    setState(() {
      _activeVideoScrubberHandle = handle;
    });
  }

  void _handleVideoScrubberModeChanged(bool isActive) {
    if (!mounted || isActive) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !context.read<AssetViewerCubit>().state.currentAsset.isVideo) {
        return;
      }
      _videoScrubberButtonFocusNode.requestFocus();
    });
  }

  void _handleFocusChange() {
    if (!mounted) {
      return;
    }

    if (_viewerFocusNode.hasFocus) {
      _registerInteraction();
      return;
    }

    if (_hasAnyActionFocus) {
      _chromeHideTimer?.cancel();
      if (!_showChrome) {
        setState(() => _showChrome = true);
      }
    }
  }

  void _registerInteraction() {
    if (!mounted) {
      return;
    }

    if (_shouldIgnoreWallpaperExitForCurrentInteraction()) {
      return;
    }

    _hideWallpaperClock();
    _chromeHideTimer?.cancel();
    if (!_showChrome) {
      setState(() => _showChrome = true);
    }

    if (!_viewerFocusNode.hasFocus || _hasAnyActionFocus) {
      return;
    }

    _chromeHideTimer = Timer(_chromeHideDelay, () {
      if (!mounted || !_viewerFocusNode.hasFocus || _hasAnyActionFocus) {
        return;
      }
      setState(() => _showChrome = false);
    });

    _scheduleWallpaperClock();
  }

  Duration get _wallpaperClockDelay =>
      kDebugMode ? _wallpaperClockDebugDelay : _wallpaperClockReleaseDelay;

  bool get _currentAssetSupportsWallpaperClock =>
      !context.read<AssetViewerCubit>().state.currentAsset.isVideo;

  void _hideWallpaperClock() {
    _wallpaperClockTimer?.cancel();
    _wallpaperClockTicker?.cancel();
    _wallpaperModeActive = false;
    _wallpaperModeActivatedAt = null;
    if (_showWallpaperClock) {
      setState(() => _showWallpaperClock = false);
    }
  }

  void _scheduleWallpaperClock() {
    _wallpaperClockTimer?.cancel();
    _wallpaperClockTicker?.cancel();
    if (!_currentAssetSupportsWallpaperClock) {
      if (_showWallpaperClock) {
        setState(() => _showWallpaperClock = false);
      }
      return;
    }

    _wallpaperClockTimer = Timer(_wallpaperClockDelay, () {
      if (!mounted ||
          !_currentAssetSupportsWallpaperClock ||
          _wallpaperModeActive) {
        return;
      }

      setState(() {
        _showWallpaperClock = true;
        _wallpaperClockNow = DateTime.now();
      });

      _wallpaperClockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted ||
            !_showWallpaperClock ||
            !_currentAssetSupportsWallpaperClock) {
          return;
        }
        setState(() => _wallpaperClockNow = DateTime.now());
      });
    });
  }

  void _activateWallpaperMode() {
    if (!_currentAssetSupportsWallpaperClock) {
      return;
    }

    _wallpaperClockTimer?.cancel();
    _wallpaperClockTicker?.cancel();
    setState(() {
      _wallpaperModeActive = true;
      _wallpaperModeActivatedAt = DateTime.now();
      _showWallpaperClock = true;
      _showChrome = false;
      _wallpaperClockNow = DateTime.now();
    });
    _viewerFocusNode.requestFocus();
    _wallpaperClockTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted ||
          !_showWallpaperClock ||
          !_currentAssetSupportsWallpaperClock) {
        return;
      }
      setState(() => _wallpaperClockNow = DateTime.now());
    });
  }

  bool _shouldIgnoreWallpaperExitForCurrentInteraction() {
    if (!_wallpaperModeActive) {
      return false;
    }

    final activatedAt = _wallpaperModeActivatedAt;
    if (activatedAt == null) {
      return false;
    }

    return DateTime.now().difference(activatedAt) <
        const Duration(milliseconds: 250);
  }

  IconData _imageFitIcon(ViewerImageFitMode mode) {
    return switch (mode) {
      ViewerImageFitMode.contain => Icons.fit_screen_rounded,
      ViewerImageFitMode.fitWidth => Icons.width_full_rounded,
    };
  }
}
