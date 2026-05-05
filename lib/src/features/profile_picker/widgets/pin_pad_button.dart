import 'package:flutter/material.dart';

import '../../../shared/presentation/app_colors.dart';
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
        final isActive = focusState.isActive;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF17303E) : const Color(0xFF10202A),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: focusState.isFocused ? AppColors.focus : AppColors.border,
              width: focusState.isFocused ? 2 : 1,
            ),
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
