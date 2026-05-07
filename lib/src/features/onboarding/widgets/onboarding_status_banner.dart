import 'package:flutter/material.dart';

import '../../../shared/presentation/app_colors.dart';

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
    return Container(
      padding: EdgeInsets.symmetric(vertical: padding * 0.75),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            height: ((isTvLayout ? 28.0 : 24.0) * typographyScale).clamp(
              20.0,
              32.0,
            ),
            margin: EdgeInsets.only(
              top: 2,
              right: (12.0 * typographyScale).clamp(10.0, 18.0),
            ),
            color: color,
          ),
          Icon(
            icon,
            color: color,
            size: ((isTvLayout ? 28.0 : 24.0) * typographyScale).clamp(
              20.0,
              32.0,
            ),
          ),
          SizedBox(width: (10.0 * typographyScale).clamp(8.0, 14.0)),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: (16.0 * typographyScale).clamp(14.0, 20.0),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
