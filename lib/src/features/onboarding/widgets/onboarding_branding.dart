import 'package:flutter/material.dart';

import '../../../shared/presentation/app_breakpoints.dart';
import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_scale.dart';
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
    final scale = AppScale.of(context);
    final isTvLayout = viewportSize.width >= AppBreakpoints.tv;
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
                    fontSize: scale.text(
                      isTvLayout ? 48 : 40,
                      min: 32,
                      max: 50,
                    ),
                  ),
        ),
        SizedBox(height: scale.space(12, min: 10, max: 16)),
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
                      fontSize: scale.text(20, min: 16, max: 22),
                    ),
          ),
        ),
      ],
    );
  }
}
