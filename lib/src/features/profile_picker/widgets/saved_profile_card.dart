import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/authenticated_session.dart';
import '../../../core/models/saved_profile.dart';
import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_spacing.dart';
import '../../../shared/presentation/widgets/tv_focusable.dart';
import '../../app_flow/cubit/app_flow_cubit.dart';
import 'pin_unlock_screen.dart';
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
        final session = await Navigator.of(context).push<AuthenticatedSession>(
          MaterialPageRoute(builder: (_) => PinUnlockScreen(profile: profile)),
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
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTvLayout ? 12 : 8,
              vertical: isTvLayout ? 10 : 8,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: AnimatedContainer(
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
                    child: CircleAvatar(
                      radius: isTvLayout ? 52 : 42,
                      backgroundColor: avatarColor,
                      foregroundColor: Colors.white,
                      child: Text(
                        profile.initials,
                        style:
                            (isTvLayout
                                    ? theme.textTheme.headlineMedium
                                    : theme.textTheme.headlineSmall)
                                ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isTvLayout ? 18 : 14),
                Text(
                  profile.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
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
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
