import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_radii.dart';
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

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.all(isTvLayout ? 28 : 22),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF122633) : const Color(0xCC0F1D26),
            borderRadius: BorderRadius.circular(AppRadii.xl),
            border: Border.all(
              color: focusState.isFocused ? AppColors.focus : AppColors.border,
              width: focusState.isFocused ? 2.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isTvLayout ? 88 : 72,
                height: isTvLayout ? 88 : 72,
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
              SizedBox(height: isTvLayout ? 24 : 18),
              Text(
                'Add profile',
                style:
                    (isTvLayout
                            ? theme.textTheme.headlineSmall
                            : theme.textTheme.titleLarge)
                        ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Connect another Immich account and save it behind a 4-digit PIN.',
                style:
                    (isTvLayout
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const Spacer(),
              Text(
                'Open setup',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.focus,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
