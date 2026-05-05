import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../../../shared/presentation/widgets/tv_focusable.dart';
import '../../app_flow/cubit/app_flow_cubit.dart';

class AddProfileCard extends StatelessWidget {
  const AddProfileCard({super.key, required this.isTvLayout});

  final bool isTvLayout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvFocusable(
      onPressed: () => context.read<AppFlowCubit>().showOnboarding(),
      builder: (context, focusState) {
        final isActive = focusState.isActive;

        return AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: isActive ? 1.02 : 1,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTvLayout ? 12 : 8,
              vertical: isTvLayout ? 10 : 8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: EdgeInsets.all(isTvLayout ? 6 : 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: focusState.isFocused
                          ? AppColors.focus
                          : Colors.transparent,
                      width: 2.4,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.focus.withValues(alpha: 0.18),
                              blurRadius: 28,
                              spreadRadius: 2,
                            ),
                          ]
                        : const [],
                  ),
                  child: Container(
                    width: isTvLayout ? 104 : 84,
                    height: isTvLayout ? 104 : 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: isTvLayout ? 42 : 34,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: isTvLayout ? 18 : 14),
                Text(
                  'Add profile',
                  textAlign: TextAlign.center,
                  style:
                      (isTvLayout
                              ? theme.textTheme.headlineSmall
                              : theme.textTheme.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
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
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
