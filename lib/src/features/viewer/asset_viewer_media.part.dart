part of 'asset_viewer_screen.dart';

class _ScrubberFocusMoveIntent extends Intent {
  const _ScrubberFocusMoveIntent(this.offset);

  final int offset;
}

class _ViewerPage extends StatelessWidget {
  const _ViewerPage({
    required this.asset,
    required this.accessToken,
    required this.fitMode,
    this.onRegisterVideoScrubberHandle,
    this.onVideoScrubberModeChanged,
  });

  final AssetSummary asset;
  final String accessToken;
  final ViewerImageFitMode fitMode;
  final ValueChanged<_ViewerVideoScrubberHandle?>?
  onRegisterVideoScrubberHandle;
  final ValueChanged<bool>? onVideoScrubberModeChanged;

  @override
  Widget build(BuildContext context) {
    if (asset.isVideo) {
      return _ViewerVideoPlayer(
        asset: asset,
        accessToken: accessToken,
        onRegisterScrubberHandle: onRegisterVideoScrubberHandle,
        onScrubModeChanged: onVideoScrubberModeChanged,
      );
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
              loadingOverlay: const _ViewerMediaLoadingOverlay(),
            ),
          ),
        );
      },
    );
  }
}

class _ViewerMediaLoadingOverlay extends StatelessWidget {
  const _ViewerMediaLoadingOverlay({this.progress});
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 44,
        height: 44,
        child: CircularProgressIndicator(
          value: progress,
          strokeWidth: 3.5,
          backgroundColor: Colors.white.withValues(alpha: 0.18),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}

class _ViewerVideoPlayer extends StatefulWidget {
  const _ViewerVideoPlayer({
    required this.asset,
    required this.accessToken,
    this.onRegisterScrubberHandle,
    this.onScrubModeChanged,
  });

  final AssetSummary asset;
  final String accessToken;
  final ValueChanged<_ViewerVideoScrubberHandle?>? onRegisterScrubberHandle;
  final ValueChanged<bool>? onScrubModeChanged;

  @override
  State<_ViewerVideoPlayer> createState() => _ViewerVideoPlayerState();
}

class _ViewerVideoPlayerState extends State<_ViewerVideoPlayer> {
  static const _chromeAutoHideDelay = Duration(seconds: 2);
  static const _scrubDurations = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 10),
    Duration(seconds: 20),
  ];

  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  double? _webLoadProgress;
  final FocusNode _focusNode = FocusNode(debugLabel: 'viewer-video-player');
  final List<FocusNode> _scrubFocusNodes = _scrubDurations
      .expand(
        (duration) => [
          FocusNode(debugLabel: 'viewer-video-back-${duration.inSeconds}'),
          FocusNode(debugLabel: 'viewer-video-forward-${duration.inSeconds}'),
        ],
      )
      .toList(growable: false);
  final FocusNode _closeScrubberFocusNode = FocusNode(
    debugLabel: 'viewer-video-close-scrubber',
  );
  bool _showChrome = true;
  bool _isScrubModeActive = false;
  bool _isLooping = true;
  bool? _wasPlaying;
  Timer? _chromeHideTimer;

  @override
  void initState() {
    super.initState();
    _registerScrubberHandle();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(covariant _ViewerVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onRegisterScrubberHandle != widget.onRegisterScrubberHandle) {
      _registerScrubberHandle();
    }
    if (oldWidget.onScrubModeChanged != widget.onScrubModeChanged) {
      widget.onScrubModeChanged?.call(_isScrubModeActive);
    }
    if (oldWidget.asset.id != widget.asset.id ||
        oldWidget.accessToken != widget.accessToken) {
      _isScrubModeActive = false;
      _disposeController();
      _registerScrubberHandle();
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _chromeHideTimer?.cancel();
    widget.onRegisterScrubberHandle?.call(null);
    widget.onScrubModeChanged?.call(false);
    _focusNode.dispose();
    for (final focusNode in _scrubFocusNodes) {
      focusNode.dispose();
    }
    _closeScrubberFocusNode.dispose();
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
            scrubFocusNodes: _scrubFocusNodes,
            closeScrubberFocusNode: _closeScrubberFocusNode,
            showChrome: _showChrome,
            isScrubModeActive: _isScrubModeActive,
            onSurfaceTap: _handleSurfaceTap,
            onTogglePlayback: _togglePlayback,
            onSeekRelative: _seekRelative,
            onExitScrubMode: _exitScrubMode,
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
        _isLooping = true;
        await controller.setLooping(_isLooping);
        if (!kIsWeb) {
          await controller.play();
        }
        _registerScrubberHandle();
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
    _isLooping = true;
    await controller.setLooping(_isLooping);
    _registerScrubberHandle();
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

    if (_isScrubModeActive) {
      _exitScrubMode();
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
    _registerScrubberHandle();

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
    if (controller == null ||
        !controller.value.isPlaying ||
        _isScrubModeActive) {
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

  void _registerScrubberHandle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      widget.onRegisterScrubberHandle?.call(
        _ViewerVideoScrubberHandle(
          togglePlayback: _togglePlayback,
          activate: _activateScrubMode,
          reset: _resetPlayback,
          toggleLooping: _toggleLooping,
          isAvailable: () => _controller?.value.isInitialized ?? false,
          isPlaying: () => _controller?.value.isPlaying ?? false,
          isScrubModeActive: () => _isScrubModeActive,
          isLooping: () => _isLooping,
        ),
      );
    });
  }

  void _activateScrubMode() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    _chromeHideTimer?.cancel();
    if (mounted) {
      setState(() {
        _showChrome = true;
        _isScrubModeActive = true;
      });
    }
    widget.onScrubModeChanged?.call(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrubFocusNodes.first.requestFocus();
    });
  }

  void _exitScrubMode() {
    if (!_isScrubModeActive || !mounted) {
      return;
    }
    setState(() {
      _isScrubModeActive = false;
      _showChrome = true;
    });
    widget.onScrubModeChanged?.call(false);
    _scheduleChromeAutoHide(forceShow: true);
  }

  Future<void> _seekRelative(Duration delta) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final duration = controller.value.duration;
    final position = controller.value.position;
    var nextPosition = position + delta;
    if (nextPosition < Duration.zero) {
      nextPosition = Duration.zero;
    }
    if (nextPosition > duration) {
      nextPosition = duration;
    }
    await controller.seekTo(nextPosition);
    if (mounted) {
      setState(() {
        _showChrome = true;
      });
    }
  }

  Future<void> _resetPlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    await controller.seekTo(Duration.zero);
    if (mounted) {
      setState(() {
        _showChrome = true;
      });
    }
  }

  Future<void> _toggleLooping() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final nextLooping = !_isLooping;
    await controller.setLooping(nextLooping);
    if (!mounted) {
      return;
    }
    setState(() {
      _isLooping = nextLooping;
      _showChrome = true;
    });
    _registerScrubberHandle();
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
          child: _ViewerMediaLoadingOverlay(progress: progress),
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
    required this.scrubFocusNodes,
    required this.closeScrubberFocusNode,
    required this.showChrome,
    required this.isScrubModeActive,
    required this.onSurfaceTap,
    required this.onTogglePlayback,
    required this.onSeekRelative,
    required this.onExitScrubMode,
  });

  final VideoPlayerController controller;
  final FocusNode focusNode;
  final List<FocusNode> scrubFocusNodes;
  final FocusNode closeScrubberFocusNode;
  final bool showChrome;
  final bool isScrubModeActive;
  final VoidCallback onSurfaceTap;
  final VoidCallback onTogglePlayback;
  final ValueChanged<Duration> onSeekRelative;
  final VoidCallback onExitScrubMode;

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
            top: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: isScrubModeActive ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: IgnorePointer(
                ignoring: !isScrubModeActive,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: Colors.black.withValues(alpha: 0.58)),
                    _ViewerVideoScrubberPanel(
                      controller: controller,
                      scrubFocusNodes: scrubFocusNodes,
                      closeFocusNode: closeScrubberFocusNode,
                      onSeekRelative: onSeekRelative,
                      onClose: onExitScrubMode,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerVideoScrubberPanel extends StatelessWidget {
  const _ViewerVideoScrubberPanel({
    required this.controller,
    required this.scrubFocusNodes,
    required this.closeFocusNode,
    required this.onSeekRelative,
    required this.onClose,
  });

  final VideoPlayerController controller;
  final List<FocusNode> scrubFocusNodes;
  final FocusNode closeFocusNode;
  final ValueChanged<Duration> onSeekRelative;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final orderedFocusNodes = <FocusNode>[
      scrubFocusNodes[4],
      scrubFocusNodes[2],
      scrubFocusNodes[0],
      closeFocusNode,
      scrubFocusNodes[1],
      scrubFocusNodes[3],
      scrubFocusNodes[5],
    ];

    return Center(
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          final theme = Theme.of(context);
          final duration = value.duration;
          final position = value.position;
          final clampedPosition = position > duration ? duration : position;

          return Shortcuts(
            shortcuts: const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.arrowLeft):
                  _ScrubberFocusMoveIntent(-1),
              SingleActivator(LogicalKeyboardKey.arrowRight):
                  _ScrubberFocusMoveIntent(1),
              SingleActivator(LogicalKeyboardKey.arrowUp): DoNothingIntent(),
              SingleActivator(LogicalKeyboardKey.arrowDown): DoNothingIntent(),
            },
            child: Actions(
              actions: <Type, Action<Intent>>{
                _ScrubberFocusMoveIntent:
                    CallbackAction<_ScrubberFocusMoveIntent>(
                      onInvoke: (intent) {
                        final currentIndex = orderedFocusNodes.indexWhere(
                          (node) => node.hasFocus,
                        );
                        final safeIndex = currentIndex < 0 ? 0 : currentIndex;
                        final nextIndex = (safeIndex + intent.offset).clamp(
                          0,
                          orderedFocusNodes.length - 1,
                        );
                        orderedFocusNodes[nextIndex].requestFocus();
                        return null;
                      },
                    ),
              },
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.video_settings_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Video scrubber',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${_formatVideoPosition(clampedPosition)} / ${_formatVideoPosition(duration)}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Choose a jump size and press OK.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            _ViewerVideoScrubActionButton(
                              focusNode: scrubFocusNodes[4],
                              label: '-20s',
                              onPressed: () => onSeekRelative(
                                -_ViewerVideoPlayerState._scrubDurations[2],
                              ),
                            ),
                            _ViewerVideoScrubActionButton(
                              focusNode: scrubFocusNodes[2],
                              label: '-10s',
                              onPressed: () => onSeekRelative(
                                -_ViewerVideoPlayerState._scrubDurations[1],
                              ),
                            ),
                            _ViewerVideoScrubActionButton(
                              focusNode: scrubFocusNodes[0],
                              label: '-5s',
                              onPressed: () => onSeekRelative(
                                -_ViewerVideoPlayerState._scrubDurations[0],
                              ),
                            ),
                            _ViewerVideoScrubActionButton(
                              focusNode: closeFocusNode,
                              icon: Icons.close_rounded,
                              semanticsLabel: 'Close',
                              onPressed: onClose,
                            ),
                            _ViewerVideoScrubActionButton(
                              focusNode: scrubFocusNodes[1],
                              label: '+5s',
                              onPressed: () => onSeekRelative(
                                _ViewerVideoPlayerState._scrubDurations[0],
                              ),
                            ),
                            _ViewerVideoScrubActionButton(
                              focusNode: scrubFocusNodes[3],
                              label: '+10s',
                              onPressed: () => onSeekRelative(
                                _ViewerVideoPlayerState._scrubDurations[1],
                              ),
                            ),
                            _ViewerVideoScrubActionButton(
                              focusNode: scrubFocusNodes[5],
                              label: '+20s',
                              onPressed: () => onSeekRelative(
                                _ViewerVideoPlayerState._scrubDurations[2],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ViewerVideoScrubActionButton extends StatefulWidget {
  const _ViewerVideoScrubActionButton({
    required this.focusNode,
    required this.onPressed,
    this.label,
    this.icon,
    this.semanticsLabel,
  });

  final FocusNode focusNode;
  final String? label;
  final VoidCallback onPressed;
  final IconData? icon;
  final String? semanticsLabel;

  @override
  State<_ViewerVideoScrubActionButton> createState() =>
      _ViewerVideoScrubActionButtonState();
}

class _ViewerVideoScrubActionButtonState
    extends State<_ViewerVideoScrubActionButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TvFocusable(
      focusNode: widget.focusNode,
      onPressed: widget.onPressed,
      builder: (context, focusState) {
        final isFocused = focusState.isFocused;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isFocused
                ? AppColors.focus.withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isFocused
                  ? AppColors.focus
                  : Colors.white.withValues(alpha: 0.12),
              width: isFocused ? 2.4 : 1.2,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.focusGlow,
                      blurRadius: 22,
                      spreadRadius: 2,
                    ),
                  ]
                : const [],
          ),
          child: Semantics(
            button: true,
            label: widget.semanticsLabel ?? widget.label,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: Colors.white, size: 18),
                  if (widget.label != null)
                    const SizedBox(width: AppSpacing.xs),
                ],
                if (widget.label != null)
                  Text(
                    widget.label!,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _formatVideoPosition(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
