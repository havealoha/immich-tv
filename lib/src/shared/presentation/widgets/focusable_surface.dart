import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_durations.dart';
import '../app_focus_decoration.dart';
import '../app_radii.dart';
import 'tv_focusable.dart';

class FocusableSurface extends StatefulWidget {
  const FocusableSurface({
    super.key,
    required this.child,
    this.onPressed,
    this.autofocus = false,
    this.width,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = AppRadii.lg,
    this.backgroundColor = AppColors.backgroundElevated,
    this.borderColor = AppColors.border,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool autofocus;
  final double? width;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;

  @override
  State<FocusableSurface> createState() => _FocusableSurfaceState();
}

class _FocusableSurfaceState extends State<FocusableSurface> {
  @override
  Widget build(BuildContext context) {
    final interactive = widget.onPressed != null;
    return TvFocusable(
      autofocus: widget.autofocus,
      enabled: interactive,
      onPressed: widget.onPressed,
      builder: (_, state) {
        final activeBackgroundColor =
            Color.lerp(widget.backgroundColor, Colors.white, 0.04) ??
            widget.backgroundColor;

        return AnimatedContainer(
          duration: AppDurations.normal,
          curve: Curves.easeOutCubic,
          width: widget.width,
          padding: widget.padding,
          decoration: AppFocusDecoration.surface(
            isFocused: state.isFocused,
            isActive: state.isActive,
            backgroundColor: widget.backgroundColor,
            activeBackgroundColor: activeBackgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: widget.child,
        );
      },
    );
  }
}
