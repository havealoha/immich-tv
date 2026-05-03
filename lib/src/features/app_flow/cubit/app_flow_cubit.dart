import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/authenticated_session.dart';
import '../../../core/repositories/auth_repository.dart';
import 'app_flow_state.dart';

class AppFlowCubit extends Cubit<AppFlowState> {
  AppFlowCubit(this._authRepository) : super(const AppFlowState.bootstrap());

  final AuthRepository _authRepository;

  Future<void> initialize() async {
    final restoredSession = await _authRepository.restoreSession();
    if (restoredSession == null) {
      emit(const AppFlowState.onboarding());
      return;
    }

    emit(AppFlowState.home(restoredSession));
  }

  void completeSignIn(AuthenticatedSession session) {
    emit(AppFlowState.home(session));
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    emit(const AppFlowState.onboarding());
  }
}
