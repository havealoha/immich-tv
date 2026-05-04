import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/bootstrap/bootstrap_flow.dart';
import 'features/app_flow/cubit/app_flow_cubit.dart';
import 'features/app_flow/cubit/app_flow_state.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'features/profile_picker/profile_picker_screen.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppFlowCubit, AppFlowState>(
      builder: (context, state) {
        return switch (state.stage) {
          AppStage.bootstrap => const BootstrapFlow(),
          AppStage.profilePicker => ProfilePickerScreen(
            profiles: state.profiles,
          ),
          AppStage.onboarding => const OnboardingFlow(),
          AppStage.home => HomeScreen(session: state.session!),
        };
      },
    );
  }
}
