part of 'asset_viewer_screen.dart';

class _ViewerPage extends StatelessWidget {
  const _ViewerPage({
    required this.asset,
    required this.accessToken,
    required this.fitMode,
  });

  final AssetSummary asset;
  final String accessToken;
  final ViewerImageFitMode fitMode;

  @override
  Widget build(BuildContext context) {
    if (asset.isVideo) {
      return _ViewerVideoPlayer(asset: asset, accessToken: accessToken);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = switch (fitMode) {
          ViewerImageFitMode.contain => BoxFit.contain,
          ViewerImageFitMode.fitWidth => BoxFit.fitWidth,
        };

        return InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: AuthenticatedAssetImage(
              imageUrls: asset.displayUrls,
              placeholderImageUrls: asset.thumbnailUrls,
              placeholderBlurSigma: 16,
              accessToken: accessToken,
              requiresAuth: asset.requiresAuth,
              fit: fit,
              heroTag: 'asset-${asset.id}',
              placeholderIcon: Icons.photo_outlined,
              filterQuality: FilterQuality.medium,
              loadingOverlay: const _ViewerMediaLoadingOverlay(
                icon: Icons.photo_outlined,
                label: 'Loading photo',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ViewerMediaLoadingOverlay extends StatelessWidget {
  const _ViewerMediaLoadingOverlay({
    required this.icon,
    required this.label,
    this.progress,
  });

  final IconData icon;
  final String label;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final determinateProgress = progress;
    final progressLabel = determinateProgress == null
        ? null
        : '${(determinateProgress * 100).round()}% downloaded';

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.46),
          borderRadius: BorderRadius.circular(AppRadii.xl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.92), size: 44),
              const SizedBox(height: AppSpacing.md),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (determinateProgress == null)
                const LoadingSkeleton(
                  width: 148,
                  height: 8,
                  borderRadius: 999,
                  baseColor: Color(0xFF111111),
                  highlightColor: Color(0xFF262626),
                )
              else
                SizedBox(
                  width: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: LinearProgressIndicator(
                      value: determinateProgress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF111111),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              if (progressLabel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  progressLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ],
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
  static const _chromeAutoHideDelay = Duration(seconds: 2);

  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  double? _webLoadProgress;
  final FocusNode _focusNode = FocusNode(debugLabel: 'viewer-video-player');
  bool _showChrome = true;
  bool? _wasPlaying;
  Timer? _chromeHideTimer;

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
    _chromeHideTimer?.cancel();
    _focusNode.dispose();
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || _initializeFuture == null) {
      return _ViewerVideoLoadingSurface(
        asset: widget.asset,
        accessToken: widget.accessToken,
        progress: _webLoadProgress,
      );
    }

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        final Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = _ViewerVideoLoadingSurface(
            key: ValueKey<String>('video-loading-${widget.asset.id}'),
            asset: widget.asset,
            accessToken: widget.accessToken,
            progress: _webLoadProgress,
          );
        } else if (snapshot.hasError || !controller.value.isInitialized) {
          child = const _VideoPlayerError(key: ValueKey<String>('video-error'));
        } else {
          child = _ViewerVideoContent(
            key: ValueKey<String>('video-ready-${widget.asset.id}'),
            controller: controller,
            focusNode: _focusNode,
            showChrome: _showChrome,
            onSurfaceTap: _handleSurfaceTap,
            onTogglePlayback: _togglePlayback,
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: child,
        );
      },
    );
  }

  Future<void> _initializePlayer() async {
    final playableUrl = _resolvePlayableVideoUrl();
    if (playableUrl.isEmpty) {
      return;
    }

    setState(() {
      _webLoadProgress = null;
    });

    if (kIsWeb && widget.asset.requiresAuth) {
      setState(() {
        _initializeFuture = _initializeAuthenticatedWebPlayer(playableUrl);
      });
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
    controller.addListener(_handleControllerUpdate);

    setState(() {
      _controller = controller;
      _initializeFuture = controller.initialize().then((_) async {
        await controller.setLooping(true);
        if (!kIsWeb) {
          await controller.play();
        }
        _scheduleChromeAutoHide(forceShow: true);
      });
    });
  }

  Future<void> _initializeAuthenticatedWebPlayer(String playableUrl) async {
    final playableUri = Uri.parse(playableUrl);
    if (canUseDirectBrowserMediaPlayback(playableUri)) {
      try {
        await _initializeDirectWebPlayer(playableUri);
        return;
      } catch (_) {
        markDirectBrowserMediaPlaybackFailure(playableUri);
        final failedController = _controller;
        _controller = null;
        if (failedController != null) {
          await failedController.dispose();
        }
      }
    }

    await _initializeBlobBackedWebPlayer(playableUrl);
  }

  Future<void> _initializeDirectWebPlayer(Uri playableUri) async {
    final controller = VideoPlayerController.networkUrl(
      playableUri,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: false,
        allowBackgroundPlayback: false,
      ),
    );
    controller.addListener(_handleControllerUpdate);

    _controller = controller;
    await controller.initialize();
    await controller.setLooping(true);
    _scheduleChromeAutoHide(forceShow: true);
  }

  Future<void> _initializeBlobBackedWebPlayer(String playableUrl) async {
    final objectUrl = await WebAuthenticatedVideoCache.instance.getObjectUrl(
      sourceUrl: playableUrl,
      accessToken: widget.accessToken,
      onReceiveProgress: (received, total) {
        if (!mounted) {
          return;
        }

        final progress = total > 0 ? (received / total).clamp(0, 1) : null;
        setState(() {
          _webLoadProgress = progress?.toDouble();
        });
      },
    );
    await _initializeDirectWebPlayer(Uri.parse(objectUrl));
    if (mounted) {
      setState(() {
        _webLoadProgress = 1;
      });
    }
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

    _chromeHideTimer?.cancel();
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      setState(() {
        _showChrome = true;
      });
      _scheduleChromeAutoHide();
    }
  }

  Future<void> _disposeController() async {
    final controller = _controller;
    _controller = null;
    _initializeFuture = null;
    _webLoadProgress = null;
    _wasPlaying = null;
    if (controller != null) {
      controller.removeListener(_handleControllerUpdate);
      await controller.dispose();
    }
  }

  void _handleSurfaceTap() {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    setState(() {
      _showChrome = !_showChrome;
    });

    if (_showChrome) {
      _scheduleChromeAutoHide();
    } else {
      _chromeHideTimer?.cancel();
    }
  }

  void _handleControllerUpdate() {
    final controller = _controller;
    if (controller == null || !mounted) {
      return;
    }

    if (!controller.value.isInitialized) {
      return;
    }

    final isPlaying = controller.value.isPlaying;
    if (_wasPlaying == isPlaying) {
      return;
    }
    _wasPlaying = isPlaying;

    if (!isPlaying) {
      _chromeHideTimer?.cancel();
      if (!_showChrome) {
        setState(() {
          _showChrome = true;
        });
      }
      return;
    }

    _scheduleChromeAutoHide();
  }

  void _scheduleChromeAutoHide({bool forceShow = false}) {
    final controller = _controller;
    if (controller == null || !controller.value.isPlaying) {
      return;
    }

    _chromeHideTimer?.cancel();
    if (forceShow && mounted && !_showChrome) {
      setState(() {
        _showChrome = true;
      });
    }

    _chromeHideTimer = Timer(_chromeAutoHideDelay, () {
      if (!mounted) {
        return;
      }
      final currentController = _controller;
      if (currentController == null || !currentController.value.isPlaying) {
        return;
      }
      setState(() {
        _showChrome = false;
      });
    });
  }
}

class _ViewerVideoLoadingSurface extends StatelessWidget {
  const _ViewerVideoLoadingSurface({
    super.key,
    required this.asset,
    required this.accessToken,
    this.progress,
  });

  final AssetSummary asset;
  final String accessToken;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        AuthenticatedAssetImage(
          imageUrls: asset.thumbnailUrls,
          accessToken: accessToken,
          requiresAuth: asset.requiresAuth,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          placeholderIcon: Icons.videocam_outlined,
          placeholderBlurSigma: 16,
          loadingOverlay: const SizedBox.shrink(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
          ),
          child: _ViewerMediaLoadingOverlay(
            icon: Icons.videocam_outlined,
            label: 'Loading video',
            progress: progress,
          ),
        ),
      ],
    );
  }
}

class _ViewerVideoContent extends StatelessWidget {
  const _ViewerVideoContent({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.showChrome,
    required this.onSurfaceTap,
    required this.onTogglePlayback,
  });

  final VideoPlayerController controller;
  final FocusNode focusNode;
  final bool showChrome;
  final VoidCallback onSurfaceTap;
  final VoidCallback onTogglePlayback;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) {
          return KeyEventResult.ignored;
        }

        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.mediaPlayPause ||
            key == LogicalKeyboardKey.mediaPlay ||
            key == LogicalKeyboardKey.mediaPause ||
            key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.space) {
          onTogglePlayback();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: Stack(
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
              onTap: onSurfaceTap,
              child: const SizedBox.expand(),
            ),
          ),
          AnimatedOpacity(
            opacity: showChrome || !controller.value.isPlaying ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !showChrome && controller.value.isPlaying,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.32),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: onTogglePlayback,
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
              opacity: showChrome || !controller.value.isPlaying ? 1 : 0,
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
      ),
    );
  }
}

class _VideoPlayerError extends StatelessWidget {
  const _VideoPlayerError({super.key});

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
