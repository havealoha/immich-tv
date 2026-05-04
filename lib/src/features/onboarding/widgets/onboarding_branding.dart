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
    final isTvLayout = MediaQuery.sizeOf(context).width >= AppBreakpoints.tv;
    final serverValidated = state.hasValidatedServer;

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
        SizedBox(height: isTvLayout ? 18 : 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTvLayout ? 960 : 760),
          child: Text(
            serverValidated
                ? 'Your server is ready. Enter your Immich account email and password to continue.'
                : 'Enter your Immich Server URL to connect this TV and continue to sign in.',
            textAlign: TextAlign.center,
            style:
                (isTvLayout
                        ? theme.textTheme.headlineSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      ],
    );
  }
}
