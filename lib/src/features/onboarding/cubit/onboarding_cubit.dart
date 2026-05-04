import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/server_repository.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required AuthRepository authRepository,
    required ServerRepository serverRepository,
  }) : _authRepository = authRepository,
       _serverRepository = serverRepository,
       super(const OnboardingState());

  final AuthRepository _authRepository;
  final ServerRepository _serverRepository;

  Future<void> validateServer(String rawUrl) async {
    emit(
      state.copyWith(
        status: OnboardingStatus.validatingServer,
        clearError: true,
      ),
    );

    try {
      final result = await _serverRepository.validateServer(rawUrl);
      emit(
        state.copyWith(
          step: OnboardingStep.credentials,
          status: OnboardingStatus.idle,
          serverConfig: result.serverConfig,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: OnboardingStatus.idle,
          errorMessage: error is AppException
              ? error.message
              : 'We could not validate that server right now.',
        ),
      );
    }
  }

  Future<AuthenticatedSession?> signIn({
    required String email,
    required String password,
  }) async {
    final serverConfig = state.serverConfig;
    if (serverConfig == null) {
      emit(
        state.copyWith(errorMessage: 'Validate your server before signing in.'),
      );
      return null;
    }

    emit(state.copyWith(status: OnboardingStatus.signingIn, clearError: true));

    try {
      final session = await _authRepository.signIn(
        serverConfig: serverConfig,
        email: email,
        password: password,
      );
      emit(state.copyWith(status: OnboardingStatus.idle, clearError: true));
      return session;
    } catch (error) {
      emit(
        state.copyWith(
          status: OnboardingStatus.idle,
          errorMessage: error is AppException
              ? error.message
              : 'We could not complete sign-in right now.',
        ),
      );
      return null;
    }
  }

  void returnToServerStep() {
    emit(
      state.copyWith(
        step: OnboardingStep.server,
        status: OnboardingStatus.idle,
        clearError: true,
      ),
    );
  }
}
