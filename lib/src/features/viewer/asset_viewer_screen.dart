import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../core/models/asset_summary.dart';
import '../../core/network/immich_headers.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/authenticated_asset_image.dart';
import 'cubit/asset_viewer_cubit.dart';

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
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialIndex = context.read<AssetViewerCubit>().state.currentIndex;
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssetViewerCubit, AssetViewerState>(
      builder: (context, state) {
        return Shortcuts(
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviousIntent(),
            SingleActivator(LogicalKeyboardKey.arrowRight): _NextIntent(),
            SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _PreviousIntent: CallbackAction<_PreviousIntent>(
                onInvoke: (_) => _moveTo(state.currentIndex - 1),
              ),
              _NextIntent: CallbackAction<_NextIntent>(
                onInvoke: (_) => _moveTo(state.currentIndex + 1),
              ),
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => Navigator.of(context).maybePop(),
              ),
            },
            child: Focus(
              autofocus: true,
              child: Scaffold(
                backgroundColor: Colors.black,

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
                        child: SizedBox(
                          width: 108,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.12,
                              ),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadii.pill,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Close'),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
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

  void _moveTo(int index) {
    final cubit = context.read<AssetViewerCubit>();
    if (index < 0 || index >= cubit.state.assets.length) {
      return;
    }

    cubit.jumpTo(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }
}

class _ViewerPage extends StatelessWidget {
  const _ViewerPage({required this.asset, required this.accessToken});

  final AssetSummary asset;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    if (asset.isVideo) {
      return _ViewerVideoPlayer(asset: asset, accessToken: accessToken);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.xl,
        ),
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: AuthenticatedAssetImage(
            imageUrls: asset.displayUrls,
            accessToken: accessToken,
            requiresAuth: asset.requiresAuth,
            fit: BoxFit.contain,
            heroTag: 'asset-${asset.id}',
            placeholderIcon: Icons.photo_outlined,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

class _ViewerVideoPlayer extends StatefulWidget {
  const _ViewerVideoPlayer({required this.asset, required this.accessToken});

  final AssetSummary asset;
  final String accessToken;

  @override
  State<_ViewerVideoPlayer> createState() => _ViewerVideoPlayerState();
}

class _ViewerVideoPlayerState extends State<_ViewerVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _showChrome = true;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant _ViewerVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id ||
        oldWidget.accessToken != widget.accessToken) {
      _disposeController();
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || _initializeFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !controller.value.isInitialized) {
          return const _VideoPlayerError();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0
                    ? 16 / 9
                    : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showChrome = !_showChrome),
                child: const SizedBox.expand(),
              ),
            ),
            AnimatedOpacity(
              opacity: _showChrome || !controller.value.isPlaying ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: !_showChrome && controller.value.isPlaying,
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.32),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _togglePlayback,
                      iconSize: 56,
                      color: Colors.white,
                      icon: Icon(
                        controller.value.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: AppSpacing.xl,
              child: AnimatedOpacity(
                opacity: _showChrome || !controller.value.isPlaying ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    child: VideoProgressIndicator(
                      controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Colors.white,
                        bufferedColor: Colors.white.withValues(alpha: 0.35),
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _initializePlayer() async {
    final playableUrl = _resolvePlayableVideoUrl();
    if (playableUrl.isEmpty) {
      return;
    }

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(playableUrl),
      httpHeaders: widget.asset.requiresAuth
          ? ImmichHeaders.mediaSessionToken(widget.accessToken)
          : const <String, String>{},
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );

    setState(() {
      _controller = controller;
      _initializeFuture = controller.initialize().then((_) async {
        await controller.setLooping(true);
        await controller.play();
      });
    });
  }

  String _resolvePlayableVideoUrl() {
    for (final url in widget.asset.displayUrls) {
      final trimmed = url.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      final uri = Uri.tryParse(trimmed);
      final path = uri?.path.toLowerCase() ?? trimmed.toLowerCase();
      if (path.contains('/video/playback') ||
          path.endsWith('.mp4') ||
          path.endsWith('.webm') ||
          path.endsWith('.m3u8') ||
          path.endsWith('.mov')) {
        return trimmed;
      }
    }

    return widget.asset.displayUrls.firstWhere(
      (url) => url.trim().isNotEmpty,
      orElse: () => '',
    );
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    _initializeFuture = null;
    if (controller != null) {
      await controller.dispose();
    }
  }
}

class _VideoPlayerError extends StatelessWidget {
  const _VideoPlayerError();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_display_outlined, size: 40, color: Colors.white),
            SizedBox(height: AppSpacing.md),
            Text(
              'This video could not be played',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Try another asset or reconnect to the server and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewerArrow extends StatelessWidget {
  const _ViewerArrow({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: IconButton.filledTonal(
        onPressed: enabled ? onPressed : null,
        iconSize: 36,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xB30C151A),
          disabledBackgroundColor: const Color(0x400C151A),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white54,
          minimumSize: const Size(64, 64),
          fixedSize: const Size(64, 64),
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        icon: Icon(icon),
      ),
    );
  }
}

class _PreviousIntent extends Intent {
  const _PreviousIntent();
}

class _NextIntent extends Intent {
  const _NextIntent();
}

String _formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
