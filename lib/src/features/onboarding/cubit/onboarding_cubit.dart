import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app_flow/cubit/app_flow_state.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState());

  Future<void> validateServer() async {
    emit(state.copyWith(status: OnboardingStatus.validatingServer));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    emit(
      state.copyWith(
        step: OnboardingStep.credentials,
        status: OnboardingStatus.idle,
      ),
    );
  }

  Future<AppSession> signIn({
    required String serverUrl,
    required String email,
  }) async {
    emit(state.copyWith(status: OnboardingStatus.signingIn));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    emit(state.copyWith(status: OnboardingStatus.idle));

    return AppSession(
      serverUrl: serverUrl,
      userEmail: email,
      displayName: 'Living Room',
    );
  }
}
