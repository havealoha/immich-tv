import 'package:flutter/material.dart';

import '../../../shared/presentation/app_colors.dart';

class ProfilePickerHeader extends StatelessWidget {
  const ProfilePickerHeader({
    super.key,
    required this.theme,
    required this.isTvLayout,
  });

  final ThemeData theme;
  final bool isTvLayout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Immich TV',
          textAlign: TextAlign.center,
          style:
              (isTvLayout
                      ? theme.textTheme.displayMedium
                      : theme.textTheme.displaySmall)
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1),
        ),
        const SizedBox(height: 12),
        Text(
          'Choose a profile to unlock your library, or add a new one for this TV.',
          textAlign: TextAlign.center,
          style:
              (isTvLayout
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.titleMedium)
                  ?.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }
}
