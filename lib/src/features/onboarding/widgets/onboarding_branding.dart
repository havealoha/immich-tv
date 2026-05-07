import 'package:flutter/material.dart';

import '../../../shared/presentation/app_breakpoints.dart';
import '../../../shared/presentation/app_colors.dart';
import '../cubit/onboarding_state.dart';

class OnboardingBranding extends StatelessWidget {
  const OnboardingBranding({
    super.key,
    required this.theme,
    required this.state,
  });

  final ThemeData theme;
  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final viewportSize = MediaQuery.sizeOf(context);
    final isTvLayout = viewportSize.width >= AppBreakpoints.tv;
    final widthScale = (viewportSize.width / 1440).clamp(0.72, 1.28);
    final heightScale = (viewportSize.height / 900).clamp(0.9, 1.18);
    final typographyScale = ((widthScale * 0.7) + (heightScale * 0.3)).clamp(
      0.82,
      1.22,
    );
    final description = switch (state.step) {
      OnboardingStep.server =>
        'Enter your Immich Server URL to connect this TV and continue to sign in.',
      OnboardingStep.credentials =>
        'Your server is ready. Enter your Immich account email and password to continue.',
      OnboardingStep.pin =>
        'Set a 4-digit PIN so this profile can be reopened quickly on future launches.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Immich TV',
          textAlign: TextAlign.center,
          style:
              (isTvLayout
                      ? theme.textTheme.headlineLarge
                      : theme.textTheme.displaySmall)
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                    fontSize: ((isTvLayout ? 48.0 : 40.0) * typographyScale)
                        .clamp(32.0, 58.0),
                  ),
        ),
        SizedBox(height: (12.0 * heightScale).clamp(10.0, 18.0)),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: (viewportSize.width * (isTvLayout ? 0.5 : 0.78)).clamp(
              320.0,
              780.0,
            ),
          ),
          child: Text(
            description,
            textAlign: TextAlign.center,
            style:
                (isTvLayout
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.titleMedium)
                    ?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                      fontSize: (20.0 * typographyScale).clamp(16.0, 28.0),
                    ),
          ),
        ),
      ],
    );
  }
}
