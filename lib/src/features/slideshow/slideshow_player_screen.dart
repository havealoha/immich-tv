import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/asset_summary.dart';
import '../../core/models/immich_auth_method.dart';
import '../../shared/presentation/app_colors.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/authenticated_asset_image.dart';
import '../../shared/presentation/widgets/loading_skeleton.dart';
import '../../shared/presentation/widgets/tv_focusable.dart';

class SlideshowPlayerScreen extends StatefulWidget {
  const SlideshowPlayerScreen({
    super.key,
    required this.assets,
    required this.accessToken,
    this.authMethod = ImmichAuthMethod.password,
    required this.initialDurationSeconds,
    this.initialIndex = 0,
    this.shuffle = false,
  });

  final List<AssetSummary> assets;
  final String accessToken;
  final ImmichAuthMethod authMethod;
  final int initialDurationSeconds;
  final int initialIndex;
  final bool shuffle;

  static Future<void> show(
    BuildContext context, {
    required List<AssetSummary> assets,
    required String accessToken,
    ImmichAuthMethod authMethod = ImmichAuthMethod.password,
    required int initialDurationSeconds,
    int initialIndex = 0,
    bool shuffle = false,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            SlideshowPlayerScreen(
              assets: assets,
              accessToken: accessToken,
              authMethod: authMethod,
              initialDurationSeconds: initialDurationSeconds,
              initialIndex: initialIndex,
              shuffle: shuffle,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  State<SlideshowPlayerScreen> createState() => _SlideshowPlayerScreenState();
}

class _SlideshowPlayerScreenState extends State<SlideshowPlayerScreen> {
  late final List<AssetSummary> _assets;
  late int _durationSeconds;
  Timer? _advanceTimer;
  int _currentIndex = 0;
  bool _isPlaying = true;
  late final FocusNode _slideshowFocusNode;
  late final FocusNode _playPauseButtonFocusNode;
  late final FocusNode _closeButtonFocusNode;

  @override
  void initState() {
    super.initState();
    _assets = List<AssetSummary>.from(widget.assets);
    if (widget.shuffle) {
      _assets.shuffle(Random(17));
    }
    _durationSeconds = widget.initialDurationSeconds;
    _currentIndex = _resolveInitialIndex(widget.initialIndex);
    _slideshowFocusNode = FocusNode(debugLabel: 'slideshow-surface');
    _playPauseButtonFocusNode = FocusNode(debugLabel: 'slideshow-play');
    _closeButtonFocusNode = FocusNode(debugLabel: 'slideshow-close');
    _scheduleAdvance();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _slideshowFocusNode.dispose();
    _playPauseButtonFocusNode.dispose();
    _closeButtonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = _assets[_currentIndex];

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviousIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextIntent(),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            _FocusSlideshowActionsIntent(),
        SingleActivator(LogicalKeyboardKey.arrowUp):
            _FocusSlideshowSurfaceIntent(),
        SingleActivator(LogicalKeyboardKey.space): _TogglePlaybackIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PreviousIntent: CallbackAction<_PreviousIntent>(
            onInvoke: (_) => _handlePrevious(),
          ),
          _NextIntent: CallbackAction<_NextIntent>(
            onInvoke: (_) => _handleNext(),
          ),
          _FocusSlideshowActionsIntent:
              CallbackAction<_FocusSlideshowActionsIntent>(
                onInvoke: (_) => _focusActionButtons(),
              ),
          _FocusSlideshowSurfaceIntent:
              CallbackAction<_FocusSlideshowSurfaceIntent>(
                onInvoke: (_) => _focusSlideshowSurface(),
              ),
          _TogglePlaybackIntent: CallbackAction<_TogglePlaybackIntent>(
            onInvoke: (_) => _togglePlayback(),
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => Navigator.of(context).maybePop(),
          ),
        },
        child: Focus(
          focusNode: _slideshowFocusNode,
          autofocus: true,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                        vertical: AppSpacing.xl,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 420),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey(asset.id),
                          child: AuthenticatedAssetImage(
                            imageUrls: asset.displayUrls,
                            accessToken: widget.accessToken,
                            authMethod: widget.authMethod,
                            requiresAuth: asset.requiresAuth,
                            fit: BoxFit.contain,
                            heroTag: 'slideshow-${asset.id}',
                            placeholderIcon: Icons.photo_outlined,
                            filterQuality: FilterQuality.medium,
                            loadingPlaceholder:
                                const _SlideshowLoadingPlaceholder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 48,
                  left: 0,
                  right: 0,
                  child: Align(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          _formatDate(asset.createdAt),
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
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: 48,
                  child: Align(
                    child: SafeArea(
                      top: false,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SlideshowActionButton(
                            width: 124,
                            icon: _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            label: _isPlaying ? 'Pause' : 'Play',
                            focusNode: _playPauseButtonFocusNode,
                            onPressed: _togglePlayback,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _SlideshowActionButton(
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Object? _handlePrevious() {
    if (_closeButtonFocusNode.hasFocus) {
      _playPauseButtonFocusNode.requestFocus();
      return null;
    }

    if (_playPauseButtonFocusNode.hasFocus) {
      return null;
    }

    _moveTo(_currentIndex - 1);
    return null;
  }

  Object? _handleNext() {
    if (_playPauseButtonFocusNode.hasFocus) {
      _closeButtonFocusNode.requestFocus();
      return null;
    }

    if (_closeButtonFocusNode.hasFocus) {
      return null;
    }

    _moveTo(_currentIndex + 1);
    return null;
  }

  Object? _focusActionButtons() {
    if (_playPauseButtonFocusNode.hasFocus || _closeButtonFocusNode.hasFocus) {
      return null;
    }

    _playPauseButtonFocusNode.requestFocus();
    return null;
  }

  Object? _focusSlideshowSurface() {
    if (_playPauseButtonFocusNode.hasFocus || _closeButtonFocusNode.hasFocus) {
      _slideshowFocusNode.requestFocus();
    }
    return null;
  }

  void _moveTo(int index) {
    if (_assets.isEmpty) {
      return;
    }

    final boundedIndex =
        (index % _assets.length + _assets.length) % _assets.length;
    setState(() {
      _currentIndex = boundedIndex;
    });
    _scheduleAdvance();
  }

  void _togglePlayback() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _scheduleAdvance();
    } else {
      _advanceTimer?.cancel();
    }
  }

  void _scheduleAdvance() {
    _advanceTimer?.cancel();
    if (!_isPlaying || _assets.length < 2) {
      return;
    }

    _advanceTimer = Timer(Duration(seconds: _durationSeconds), () {
      if (!mounted) {
        return;
      }
      _moveTo(_currentIndex + 1);
    });
  }

  int _resolveInitialIndex(int index) {
    if (_assets.isEmpty) {
      return 0;
    }

    if (index < 0) {
      return 0;
    }

    if (index >= _assets.length) {
      return _assets.length - 1;
    }

    return index;
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _SlideshowLoadingPlaceholder extends StatelessWidget {
  const _SlideshowLoadingPlaceholder();

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

class _SlideshowActionButton extends StatefulWidget {
  const _SlideshowActionButton({
    required this.width,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.focusNode,
  });

  final double width;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final FocusNode? focusNode;

  @override
  State<_SlideshowActionButton> createState() => _SlideshowActionButtonState();
}

class _SlideshowActionButtonState extends State<_SlideshowActionButton> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: widget.width,
      child: TvFocusable(
        focusNode: widget.focusNode,
        onPressed: widget.onPressed,
        builder: (context, focusState) {
          final isFocused = focusState.isFocused;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isFocused
                  ? AppColors.focus.withValues(alpha: 0.24)
                  : Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: isFocused
                    ? AppColors.focus
                    : Colors.white.withValues(alpha: 0.14),
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
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, size: 18, color: Colors.white),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    widget.label,
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

class _TogglePlaybackIntent extends Intent {
  const _TogglePlaybackIntent();
}

class _FocusSlideshowActionsIntent extends Intent {
  const _FocusSlideshowActionsIntent();
}

class _FocusSlideshowSurfaceIntent extends Intent {
  const _FocusSlideshowSurfaceIntent();
}
