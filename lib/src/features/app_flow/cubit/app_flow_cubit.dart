import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/authenticated_session.dart';
import '../../../core/repositories/auth_repository.dart';
import 'app_flow_state.dart';

class AppFlowCubit extends Cubit<AppFlowState> {
  static const _minimumBootstrapDuration = Duration(milliseconds: 1500);

  AppFlowCubit(this._authRepository) : super(const AppFlowState.bootstrap());

  final AuthRepository _authRepository;

  Future<void> initialize() async {
    final startedAt = DateTime.now();
    final profiles = await _authRepository.getSavedProfiles();
    final elapsed = DateTime.now().difference(startedAt);
    final remainingDelay = _minimumBootstrapDuration - elapsed;
    if (!remainingDelay.isNegative) {
      await Future<void>.delayed(remainingDelay);
    }
    if (profiles.isEmpty) {
      emit(const AppFlowState.onboarding());
      return;
    }

    emit(AppFlowState.profilePicker(profiles));
  }

  void completeSignIn(AuthenticatedSession session) {
    emit(AppFlowState.home(session, profiles: state.profiles));
  }

  void showOnboarding() {
    emit(AppFlowState.onboarding(profiles: state.profiles));
  }

  void showProfilePicker() {
    emit(AppFlowState.profilePicker(state.profiles));
  }

  Future<void> refreshProfiles() async {
    final profiles = await _authRepository.getSavedProfiles();
    if (profiles.isEmpty) {
      emit(const AppFlowState.onboarding());
      return;
    }

    emit(AppFlowState.profilePicker(profiles));
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    await refreshProfiles();
  }
}
