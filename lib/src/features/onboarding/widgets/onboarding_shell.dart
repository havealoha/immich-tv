import 'package:flutter/material.dart';

import '../../../shared/presentation/app_breakpoints.dart';

class OnboardingShell extends StatelessWidget {
  const OnboardingShell({
    super.key,
    required this.branding,
    required this.child,
  });

  final Widget branding;
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
              final isTvLayout =
                  viewportConstraints.maxWidth >= AppBreakpoints.tv;
              final horizontalPadding = isTvLayout
                  ? 56.0
                  : viewportConstraints.maxWidth < AppBreakpoints.tablet
                  ? 24.0
                  : 32.0;
              final cardMaxWidth = isTvLayout ? 760.0 : 560.0;
              final cardPadding = isTvLayout ? 40.0 : 32.0;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24,
                ),
                child: Column(
                  children: [
                    branding,
                    SizedBox(height: isTvLayout ? 48 : 32),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: cardMaxWidth),
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.all(cardPadding),
                              child: SingleChildScrollView(child: child),
                            ),
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
