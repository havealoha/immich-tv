import 'package:flutter/material.dart';

import '../../../shared/presentation/app_durations.dart';
import '../../../shared/presentation/app_focus_decoration.dart';
import '../../../shared/presentation/app_radii.dart';
import '../../../shared/presentation/widgets/tv_focusable.dart';

class PinPadButton extends StatelessWidget {
  const PinPadButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onPressed: onPressed,
      enabled: onPressed != null,
      builder: (context, focusState) {
        final isFocused = focusState.isFocused;
        final isActive = focusState.isActive;
        return AnimatedContainer(
          duration: AppDurations.normal,
          decoration: AppFocusDecoration.surface(
            isFocused: isFocused,
            isActive: isActive,
            backgroundColor: const Color(0xFF10202A),
            activeBackgroundColor: const Color(0xFF17303E),
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      },
    );
  }
}
