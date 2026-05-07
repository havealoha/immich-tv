import 'package:flutter/material.dart';

import '../../../shared/presentation/app_breakpoints.dart';

class OnboardingShell extends StatelessWidget {
  const OnboardingShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1A4E58), Color(0xFF08131A)],
            center: Alignment.topLeft,
            radius: 1.4,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewportConstraints) {
              final viewportWidth = viewportConstraints.maxWidth;
              final isTvLayout = viewportWidth >= AppBreakpoints.tv;
              final horizontalPadding = isTvLayout
                  ? 40.0
                  : viewportWidth < AppBreakpoints.tablet
                  ? 24.0
                  : 32.0;
              final panelWidthFactor = isTvLayout
                  ? 0.42
                  : viewportWidth < AppBreakpoints.tablet
                  ? 0.94
                  : 0.62;
              final panelMaxWidth = (viewportWidth * panelWidthFactor).clamp(
                360.0,
                760.0,
              );
              final panelPadding = (viewportWidth * (isTvLayout ? 0.018 : 0.03))
                  .clamp(24.0, 36.0);

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isTvLayout ? 20 : 24,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: panelMaxWidth),
                          child: Padding(
                            padding: EdgeInsets.all(panelPadding),
                            child: SingleChildScrollView(child: child),
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
