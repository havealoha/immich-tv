import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TvFocusableState {
  const TvFocusableState({
    required this.isFocused,
    required this.isHovered,
    required this.enabled,
  });

  final bool isFocused;
  final bool isHovered;
  final bool enabled;

  bool get isActive => enabled && (isFocused || isHovered);
}

class TvFocusable extends StatefulWidget {
  const TvFocusable({
    super.key,
    required this.builder,
    this.onPressed,
    this.autofocus = false,
    this.enabled = true,
    this.mouseCursor = SystemMouseCursors.click,
    this.onFocusChange,
    this.focusNode,
  });

  final Widget Function(BuildContext context, TvFocusableState state) builder;
  final VoidCallback? onPressed;
  final bool autofocus;
  final bool enabled;
  final MouseCursor mouseCursor;
  final ValueChanged<bool>? onFocusChange;
  final FocusNode? focusNode;

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  bool _isFocused = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.enabled && widget.onPressed != null;
    final focusState = TvFocusableState(
      isFocused: _isFocused,
      isHovered: _isHovered,
      enabled: interactive,
    );

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      enabled: interactive,
      mouseCursor: interactive ? widget.mouseCursor : MouseCursor.defer,
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        const SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: interactive
          ? <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.onPressed?.call();
                  return null;
                },
              ),
              ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
                onInvoke: (_) {
                  widget.onPressed?.call();
                  return null;
                },
              ),
            }
          : const <Type, Action<Intent>>{},
      onShowFocusHighlight: (value) {
        if (_isFocused == value) {
          return;
        }
        setState(() => _isFocused = value);
        widget.onFocusChange?.call(value);
        if (value) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }
            Scrollable.ensureVisible(
              context,
              alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
            );
          });
        }
      },
      onShowHoverHighlight: (value) {
        if (_isHovered != value) {
          setState(() => _isHovered = value);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: interactive ? widget.onPressed : null,
        child: widget.builder(context, focusState),
      ),
    );
  }
}
