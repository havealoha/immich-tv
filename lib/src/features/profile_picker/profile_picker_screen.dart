import 'package:flutter/material.dart';

import '../../core/models/saved_profile.dart';
import '../../shared/presentation/app_breakpoints.dart';
import '../../shared/presentation/app_scale.dart';
import 'widgets/add_profile_card.dart';
import 'widgets/saved_profile_card.dart';

class ProfilePickerScreen extends StatelessWidget {
  const ProfilePickerScreen({super.key, required this.profiles});

  final List<SavedProfile> profiles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1B4A5A), Color(0xFF10232E), Color(0xFF08131A)],
            center: Alignment(-0.25, -0.8),
            radius: 1.3,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = AppScale.of(context);
              final isTvLayout = constraints.maxWidth >= AppBreakpoints.tv;
              final horizontalPadding = scale.space(
                isTvLayout ? 56 : 28,
                min: 24,
                max: 48,
              );
              final tileWidth = scale.sizeOf(
                isTvLayout ? 280 : 220,
                min: 200,
                max: 260,
              );
              final maxColumns = isTvLayout ? 5 : 3;
              final crossAxisCount = (constraints.maxWidth / tileWidth)
                  .floor()
                  .clamp(2, maxColumns);
              final gridSpacing = scale.space(
                isTvLayout ? 24 : 18,
                min: 16,
                max: 22,
              );

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  scale.space(isTvLayout ? 36 : 28, min: 24, max: 32),
                  horizontalPadding,
                  scale.space(28, min: 24, max: 32),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                (crossAxisCount * tileWidth) +
                                ((crossAxisCount - 1) * gridSpacing),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: gridSpacing,
                                  crossAxisSpacing: gridSpacing,
                                  childAspectRatio: isTvLayout ? 0.9 : 0.84,
                                ),
                            itemCount: profiles.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return AddProfileCard(isTvLayout: isTvLayout);
                              }

                              return SavedProfileCard(
                                profile: profiles[index - 1],
                                autofocus: index == 1,
                                isTvLayout: isTvLayout,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
