import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../app_radii.dart';
import '../app_spacing.dart';

class ShortcutHint extends StatelessWidget {
  const ShortcutHint({
    super.key,
    required this.label,
    this.size = ShortcutHintSize.medium,
  });

  final String label;
  final ShortcutHintSize size;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = size == ShortcutHintSize.large
        ? AppSpacing.md
        : AppSpacing.sm;
    final verticalPadding = size == ShortcutHintSize.large
        ? AppSpacing.sm
        : AppSpacing.xs;
    final textStyle = size == ShortcutHintSize.large
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.labelMedium;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: textStyle?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

enum ShortcutHintSize { medium, large }
