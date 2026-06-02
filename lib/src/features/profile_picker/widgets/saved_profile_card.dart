import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/authenticated_session.dart';
import '../../../core/models/saved_profile.dart';
import '../../../shared/presentation/app_colors.dart';
import '../../../shared/presentation/app_durations.dart';
import '../../../shared/presentation/app_focus_decoration.dart';
import '../../../shared/presentation/app_scale.dart';
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
    final scale = AppScale.of(context);
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

        await context.read<AppFlowCubit>().completeSignIn(session);
      },
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
                    child: CircleAvatar(
                      radius: scale.sizeOf(
                        isTvLayout ? 52 : 42,
                        min: 40,
                        max: 50,
                      ),
                      backgroundColor: avatarColor,
                      foregroundColor: Colors.white,
                      child: Text(
                        profile.initials,
                        style:
                            (isTvLayout
                                    ? theme.textTheme.headlineMedium
                                    : theme.textTheme.headlineSmall)
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: scale.text(
                                    isTvLayout ? 30 : 24,
                                    min: 22,
                                    max: 28,
                                  ),
                                ),
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
                  profile.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        );
      },
    );
  }
}
