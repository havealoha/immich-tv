part of 'asset_viewer_screen.dart';

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
            loadingPlaceholder: const _ViewerPhotoLoadingPlaceholder(),
          ),
        ),
      ),
    );
  }
}

class _ViewerPhotoLoadingPlaceholder extends StatelessWidget {
  const _ViewerPhotoLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_outlined,
              color: Colors.white.withValues(alpha: 0.92),
              size: 44,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading photo',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const LoadingSkeleton(
              width: 136,
              height: 8,
              borderRadius: 999,
              baseColor: Color(0xFF111111),
              highlightColor: Color(0xFF262626),
            ),
          ],
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
      return const _VideoLoadingPlaceholder();
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _VideoLoadingPlaceholder();
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

class _VideoLoadingPlaceholder extends StatelessWidget {
  const _VideoLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_outlined,
              color: Colors.white.withValues(alpha: 0.92),
              size: 44,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading video',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const LoadingSkeleton(
              width: 148,
              height: 8,
              borderRadius: 999,
              baseColor: Color(0xFF111111),
              highlightColor: Color(0xFF262626),
            ),
          ],
        ),
      ),
    );
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

String _formatDate(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
