import 'package:flutter/material.dart';

import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_radii.dart';

class OnboardingStatusBanner extends StatelessWidget {
  const OnboardingStatusBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
    required this.padding,
    required this.isTvLayout,
  });

  final IconData icon;
  final Color color;
  final String message;
  final double padding;
  final bool isTvLayout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.backgroundElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isTvLayout ? 28 : 24),
          SizedBox(width: isTvLayout ? 16 : 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: isTvLayout ? 18 : null,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
