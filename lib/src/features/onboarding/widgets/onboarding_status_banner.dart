import 'package:flutter/material.dart';

import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_scale.dart';

class OnboardingStatusBanner extends StatelessWidget {
  const OnboardingStatusBanner({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
    required this.padding,
    required this.isTvLayout,
    required this.typographyScale,
  });

  final IconData icon;
  final Color color;
  final String message;
  final double padding;
  final bool isTvLayout;
  final double typographyScale;

  @override
  Widget build(BuildContext context) {
    final scale = AppScale.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: padding * 0.75),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: scale.sizeOf(isTvLayout ? 28 : 24, min: 20, max: 28),
            margin: EdgeInsets.only(
              top: 2,
              right: scale.space(12, min: 10, max: 14),
            ),
            color: color,
          ),
          Icon(
            icon,
            color: color,
            size: scale.sizeOf(isTvLayout ? 28 : 24, min: 20, max: 28),
          ),
          SizedBox(width: scale.space(10, min: 8, max: 12)),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: scale.text(16, min: 14, max: 17),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
