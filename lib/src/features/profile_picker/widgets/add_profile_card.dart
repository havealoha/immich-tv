import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_durations.dart';
import '../../../shared/presentation/app_focus_decoration.dart';
import '../../../shared/presentation/app_radii.dart';
import '../../../shared/presentation/app_scale.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../../../shared/presentation/widgets/tv_focusable.dart';
import '../../app_flow/cubit/app_flow_cubit.dart';

class AddProfileCard extends StatelessWidget {
  const AddProfileCard({super.key, required this.isTvLayout});

  final bool isTvLayout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = AppScale.of(context);

    return TvFocusable(
      onPressed: () => context.read<AppFlowCubit>().showOnboarding(),
      builder: (context, focusState) {
        final isFocused = focusState.isFocused;
        final isActive = focusState.isActive;

        return AnimatedScale(
          duration: AppDurations.normal,
          scale: isActive ? 1.02 : 1,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: scale.space(isTvLayout ? 12 : 8, min: 8, max: 12),
              vertical: scale.space(isTvLayout ? 10 : 8, min: 8, max: 10),
            ),
            child: AnimatedContainer(
              duration: AppDurations.normal,
              padding: EdgeInsets.symmetric(
                horizontal: scale.space(isTvLayout ? 18 : 16, min: 14, max: 20),
                vertical: scale.space(isTvLayout ? 20 : 16, min: 14, max: 20),
              ),
              decoration: AppFocusDecoration.surface(
                isFocused: isFocused,
                isActive: isActive,
                backgroundColor: const Color(0xFF0D1A21),
                activeBackgroundColor: const Color(0xFF13212A),
                borderRadius: BorderRadius.circular(
                  scale.radius(AppRadii.lg, min: 18, max: 24),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: AnimatedContainer(
                      duration: AppDurations.normal,
                      padding: EdgeInsets.all(
                        scale.space(isTvLayout ? 6 : 4, min: 4, max: 6),
                      ),
                      decoration: AppFocusDecoration.circle(
                        isFocused: isFocused,
                        isActive: isActive,
                        backgroundColor: Colors.transparent,
                      ),
                      child: Container(
                        width: scale.sizeOf(
                          isTvLayout ? 104 : 84,
                          min: 80,
                          max: 96,
                        ),
                        height: scale.sizeOf(
                          isTvLayout ? 104 : 84,
                          min: 80,
                          max: 96,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: scale.sizeOf(
                            isTvLayout ? 42 : 34,
                            min: 30,
                            max: 38,
                          ),
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: scale.space(
                      isTvLayout ? 18 : 14,
                      min: 12,
                      max: 18,
                    ),
                  ),
                  Text(
                    'Add profile',
                    textAlign: TextAlign.center,
                    style:
                        (isTvLayout
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.titleLarge)
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: scale.text(
                                isTvLayout ? 26 : 22,
                                min: 18,
                                max: 24,
                              ),
                            ),
                  ),
                  SizedBox(height: scale.space(AppSpacing.xs, min: 8, max: 8)),
                  Text(
                    'New account',
                    textAlign: TextAlign.center,
                    style:
                        (isTvLayout
                                ? theme.textTheme.titleSmall
                                : theme.textTheme.bodySmall)
                            ?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                              fontSize: scale.text(
                                isTvLayout ? 15 : 13,
                                min: 12,
                                max: 15,
                              ),
                            ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
