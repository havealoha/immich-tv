import 'package:flutter/material.dart';

import 'features/bootstrap/bootstrap_flow.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_flow.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppStage _stage = AppStage.bootstrap;
  AppSession? _session;

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      AppStage.bootstrap => BootstrapFlow(
        onReady: (restoredSession) {
          setState(() {
            _session = restoredSession;
            _stage = restoredSession == null
                ? AppStage.onboarding
                : AppStage.home;
          });
        },
      ),
      AppStage.onboarding => OnboardingFlow(
        onAuthenticated: (session) {
          setState(() {
            _session = session;
            _stage = AppStage.home;
          });
        },
      ),
      AppStage.home => HomeScreen(
        session: _session!,
        onSignOut: () {
          setState(() {
            _session = null;
            _stage = AppStage.onboarding;
          });
        },
      ),
    };
  }
}

enum AppStage { bootstrap, onboarding, home }

class AppSession {
  const AppSession({
    required this.serverUrl,
    required this.userEmail,
    required this.displayName,
  });

  final String serverUrl;
  final String userEmail;
  final String displayName;
}
