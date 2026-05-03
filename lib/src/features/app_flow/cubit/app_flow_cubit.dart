import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_flow_state.dart';

class AppFlowCubit extends Cubit<AppFlowState> {
  AppFlowCubit() : super(const AppFlowState.bootstrap());

  Future<void> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    emit(const AppFlowState.onboarding());
  }

  void completeSignIn(AppSession session) {
    emit(AppFlowState.home(session));
  }

  void signOut() {
    emit(const AppFlowState.onboarding());
  }
}
