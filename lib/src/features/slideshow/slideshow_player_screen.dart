import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/models/asset_summary.dart';
import '../../shared/presentation/app_radii.dart';
import '../../shared/presentation/app_spacing.dart';
import '../../shared/presentation/widgets/authenticated_asset_image.dart';

class SlideshowPlayerScreen extends StatefulWidget {
  const SlideshowPlayerScreen({
    super.key,
    required this.assets,
    required this.accessToken,
    required this.initialDurationSeconds,
    this.shuffle = false,
  });

  final List<AssetSummary> assets;
  final String accessToken;
  final int initialDurationSeconds;
  final bool shuffle;

  static Future<void> show(
    BuildContext context, {
    required List<AssetSummary> assets,
    required String accessToken,
    required int initialDurationSeconds,
    bool shuffle = false,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            SlideshowPlayerScreen(
              assets: assets,
              accessToken: accessToken,
              initialDurationSeconds: initialDurationSeconds,
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
  static const _durationOptions = <int>[3, 5, 8, 12];

  late final List<AssetSummary> _assets;
  late int _durationSeconds;
  Timer? _advanceTimer;
  int _currentIndex = 0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _assets = List<AssetSummary>.from(widget.assets);
    if (widget.shuffle) {
      _assets.shuffle(Random(17));
    }
    _durationSeconds = widget.initialDurationSeconds;
    _scheduleAdvance();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asset = _assets[_currentIndex];

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowLeft): _PreviousIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight): _NextIntent(),
        SingleActivator(LogicalKeyboardKey.space): _TogglePlaybackIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _PreviousIntent: CallbackAction<_PreviousIntent>(
            onInvoke: (_) => _moveTo(_currentIndex - 1),
          ),
          _NextIntent: CallbackAction<_NextIntent>(
            onInvoke: (_) => _moveTo(_currentIndex + 1),
          ),
          _TogglePlaybackIntent: CallbackAction<_TogglePlaybackIntent>(
            onInvoke: (_) => _togglePlayback(),
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
                            requiresAuth: asset.requiresAuth,
                            fit: BoxFit.contain,
                            heroTag: 'slideshow-${asset.id}',
                            placeholderIcon: Icons.photo_outlined,
                            filterQuality: FilterQuality.medium,
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
                  top: 48,
                  right: AppSpacing.lg,
                  child: _FloatingControlButton(
                    icon: Icons.close_rounded,
                    label: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  left: AppSpacing.xl,
                  right: AppSpacing.xl,
                  bottom: AppSpacing.xl,
                  child: SafeArea(
                    top: false,
                    child: _SlideshowTransportBar(
                      currentIndex: _currentIndex,
                      totalAssets: _assets.length,
                      isPlaying: _isPlaying,
                      durationSeconds: _durationSeconds,
                      durationOptions: _durationOptions,
                      onPrevious: () => _moveTo(_currentIndex - 1),
                      onNext: () => _moveTo(_currentIndex + 1),
                      onTogglePlayback: _togglePlayback,
                      onDurationSelected: _setDuration,
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

  void _setDuration(int seconds) {
    setState(() {
      _durationSeconds = seconds;
    });
    _scheduleAdvance();
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

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}

class _SlideshowTransportBar extends StatelessWidget {
  const _SlideshowTransportBar({
    required this.currentIndex,
    required this.totalAssets,
    required this.isPlaying,
    required this.durationSeconds,
    required this.durationOptions,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlayback,
    required this.onDurationSelected,
  });

  final int currentIndex;
  final int totalAssets;
  final bool isPlaying;
  final int durationSeconds;
  final List<int> durationOptions;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlayback;
  final ValueChanged<int> onDurationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Photo ${currentIndex + 1} of $totalAssets',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FloatingIconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Previous photo',
                  onPressed: onPrevious,
                ),
                const SizedBox(width: AppSpacing.sm),
                _FloatingControlButton(
                  icon: isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  label: isPlaying ? 'Pause' : 'Play',
                  onPressed: onTogglePlayback,
                ),
                const SizedBox(width: AppSpacing.sm),
                _FloatingIconButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Next photo',
                  onPressed: onNext,
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: durationOptions
                  .map((seconds) {
                    final selected = seconds == durationSeconds;
                    return ChoiceChip(
                      label: Text('${seconds}s'),
                      selected: selected,
                      onSelected: (_) => onDurationSelected(seconds),
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedColor: Colors.white.withValues(alpha: 0.18),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      side: BorderSide(
                        color: selected
                            ? Colors.white.withValues(alpha: 0.32)
                            : Colors.transparent,
                      ),
                      showCheckmark: false,
                    );
                  })
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingControlButton extends StatelessWidget {
  const _FloatingControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 116,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.18),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.18),
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
      ),
      icon: Icon(icon),
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
