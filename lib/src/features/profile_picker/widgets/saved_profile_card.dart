import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/authenticated_session.dart';
import '../../../core/models/saved_profile.dart';
import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_radii.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../../../shared/presentation/widgets/tv_focusable.dart';
import '../../app_flow/cubit/app_flow_cubit.dart';
import 'pin_unlock_dialog.dart';
import 'profile_avatar_color.dart';

class SavedProfileCard extends StatelessWidget {
  const SavedProfileCard({
    super.key,
    required this.profile,
    required this.autofocus,
    required this.isTvLayout,
  });

  final SavedProfile profile;
  final bool autofocus;
  final bool isTvLayout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarColor = profileAvatarColor(profile);

    return TvFocusable(
      autofocus: autofocus,
      onPressed: () async {
        final session = await showDialog<AuthenticatedSession>(
          context: context,
          barrierDismissible: true,
          builder: (_) => PinUnlockDialog(profile: profile),
        );

        if (!context.mounted || session == null) {
          return;
        }

        context.read<AppFlowCubit>().completeSignIn(session);
      },
      builder: (context, focusState) {
        final isActive = focusState.isActive;

        return AnimatedScale(
          duration: const Duration(milliseconds: 180),
          scale: isActive ? 1.02 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.all(isTvLayout ? 28 : 22),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF13212A) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(
                color: focusState.isFocused
                    ? AppColors.focus
                    : AppColors.border,
                width: focusState.isFocused ? 2.4 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.focus.withValues(alpha: 0.16),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isTvLayout ? 44 : 36,
                  backgroundColor: avatarColor,
                  foregroundColor: Colors.white,
                  child: Text(
                    profile.initials,
                    style:
                        (isTvLayout
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.titleLarge)
                            ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(height: isTvLayout ? 24 : 18),
                Text(
                  profile.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (isTvLayout
                              ? theme.textTheme.headlineSmall
                              : theme.textTheme.titleLarge)
                          ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  profile.email,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      (isTvLayout
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.bodyMedium)
                          ?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                ),
                const Spacer(),
                Text(
                  profile.serverConfig.serverUrl.host,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: isActive ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Unlock with PIN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            (isTvLayout
                                    ? theme.textTheme.titleMedium
                                    : theme.textTheme.bodyLarge)
                                ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
