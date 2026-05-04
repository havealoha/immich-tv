import 'package:flutter/material.dart';

import '../../core/models/saved_profile.dart';
import '../../shared/presentation/app_breakpoints.dart';
import 'widgets/add_profile_card.dart';
import 'widgets/profile_picker_header.dart';
import 'widgets/saved_profile_card.dart';

class ProfilePickerScreen extends StatelessWidget {
  const ProfilePickerScreen({super.key, required this.profiles});

  final List<SavedProfile> profiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              final isTvLayout = constraints.maxWidth >= AppBreakpoints.tv;
              final horizontalPadding = isTvLayout ? 56.0 : 28.0;
              final tileWidth = isTvLayout ? 280.0 : 220.0;
              final maxColumns = isTvLayout ? 5 : 3;
              final crossAxisCount = (constraints.maxWidth / tileWidth)
                  .floor()
                  .clamp(2, maxColumns);

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  isTvLayout ? 36 : 28,
                  horizontalPadding,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfilePickerHeader(theme: theme, isTvLayout: isTvLayout),
                    SizedBox(height: isTvLayout ? 36 : 28),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth:
                                (crossAxisCount * tileWidth) +
                                ((crossAxisCount - 1) * (isTvLayout ? 24 : 18)),
                          ),
                          child: GridView.builder(
                            shrinkWrap: true,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  mainAxisSpacing: isTvLayout ? 24 : 18,
                                  crossAxisSpacing: isTvLayout ? 24 : 18,
                                  childAspectRatio: isTvLayout ? 0.9 : 0.84,
                                ),
                            itemCount: profiles.length + 1,
                            itemBuilder: (context, index) {
                              if (index == profiles.length) {
                                return AddProfileCard(isTvLayout: isTvLayout);
                              }

                              return SavedProfileCard(
                                profile: profiles[index],
                                autofocus: index == 0,
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
