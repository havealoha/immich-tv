part of 'asset_viewer_screen.dart';

class _SlideshowConfigDialog extends StatefulWidget {
  const _SlideshowConfigDialog({
    required this.durationOptions,
    required this.photoCount,
    required this.currentAssetIsVideo,
    required this.totalAssetCount,
  });

  final List<int> durationOptions;
  final int photoCount;
  final bool currentAssetIsVideo;
  final int totalAssetCount;

  @override
  State<_SlideshowConfigDialog> createState() => _SlideshowConfigDialogState();
}

class _SlideshowConfigDialogState extends State<_SlideshowConfigDialog> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: const Color(0xFF0D1A21),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        side: const BorderSide(color: Color(0xFF22353F)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: FocusTraversalGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Start slideshow',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Cancel',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.06),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.currentAssetIsVideo
                      ? 'Videos are skipped in slideshow mode. Playback will begin from the first photo in this set.'
                      : 'Choose how long each photo stays on screen. Selecting an interval starts playback immediately.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Interval',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: widget.durationOptions.map((seconds) {
                    return _SlideshowDurationOption(
                      seconds: seconds,
                      isSelected: false,
                      autofocus: seconds == widget.durationOptions.first,
                      onPressed: () => Navigator.of(context).pop(seconds),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChromeVisibility extends StatelessWidget {
  const _ChromeVisibility({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(
        ignoring: !visible,
        child: child,
      ),
    );
  }
}

class _ViewerIconActionButton extends StatefulWidget {
  const _ViewerIconActionButton({
    required this.icon,
    required this.onPressed,
    this.enabled = true,
    this.focusNode,
    this.onFocusChange,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool enabled;
  final FocusNode? focusNode;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<_ViewerIconActionButton> createState() => _ViewerIconActionButtonState();
}

class _ViewerIconActionButtonState extends State<_ViewerIconActionButton> {
  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      onPressed: widget.enabled ? widget.onPressed : () {},
      onFocusChange: widget.onFocusChange,
      builder: (context, focusState) {
        final isFocused = focusState.isFocused;
        final isEnabled = focusState.enabled;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: !isEnabled
                ? Colors.black.withValues(alpha: 0.08)
                : isFocused
                ? AppColors.focus.withValues(alpha: 0.24)
                : Colors.black.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: isFocused
                  ? AppColors.focus
                  : Colors.white.withValues(alpha: isEnabled ? 0.14 : 0.06),
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
          child: Icon(
            widget.icon,
            size: 18,
            color: isEnabled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.36),
          ),
        );
      },
    );
  }
}

class _ViewerWallpaperClock extends StatelessWidget {
  const _ViewerWallpaperClock({required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatWallpaperTime(now),
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatWallpaperDate(now),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.84),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatWallpaperTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _formatWallpaperDate(DateTime value) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${weekdays[value.weekday - 1]} ${value.day} ${months[value.month - 1]}';
}

class _SlideshowDurationOption extends StatefulWidget {
  const _SlideshowDurationOption({
    required this.seconds,
    required this.isSelected,
    required this.onPressed,
    this.autofocus = false,
  });

  final int seconds;
  final bool isSelected;
  final bool autofocus;
  final VoidCallback onPressed;

  @override
  State<_SlideshowDurationOption> createState() =>
      _SlideshowDurationOptionState();
}

class _SlideshowDurationOptionState extends State<_SlideshowDurationOption> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 112,
      child: TvFocusable(
        autofocus: widget.autofocus,
        onPressed: widget.onPressed,
        builder: (context, focusState) {
          final isFocused = focusState.isFocused;
          final isSelected = widget.isSelected;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.focus.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(
                color: isFocused || isSelected
                    ? AppColors.focus
                    : Colors.white.withValues(alpha: 0.1),
                width: isFocused ? 2.4 : (isSelected ? 1.8 : 1),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.seconds}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'seconds',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
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
        iconSize: 28,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xB30C151A),
          disabledBackgroundColor: const Color(0x400C151A),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white54,
          minimumSize: const Size(48, 48),
          fixedSize: const Size(48, 48),
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

class _FocusActionsIntent extends Intent {
  const _FocusActionsIntent();
}

class _FocusViewerIntent extends Intent {
  const _FocusViewerIntent();
}
