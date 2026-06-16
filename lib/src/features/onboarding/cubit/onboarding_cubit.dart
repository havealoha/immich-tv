import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/immich_auth_method.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/server_repository.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
OnboardingCubit({
  required AuthRepository authRepository,
  required ServerRepository serverRepository,
  CertificateTrustService? trustService,
}) : 
  _authRepository = authRepository,
  _serverRepository = serverRepository,
  _trustService = trustService ?? CertificateTrustService(),
  super(const OnboardingState());

  final CertificateTrustService _trustService;
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
          step: OnboardingStep.authMethod,
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
      emit(
        state.copyWith(
          step: OnboardingStep.pin,
          status: OnboardingStatus.idle,
          pendingSession: session,
          clearError: true,
        ),
      );
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

  Future<AuthenticatedSession?> signInWithApiKey({
    required String apiKey,
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
      final session = await _authRepository.signInWithApiKey(
        serverConfig: serverConfig,
        apiKey: apiKey,
      );
      emit(
        state.copyWith(
          step: OnboardingStep.pin,
          status: OnboardingStatus.idle,
          pendingSession: session,
          clearError: true,
        ),
      );
      return session;
    } catch (error) {
      emit(
        state.copyWith(
          status: OnboardingStatus.idle,
          errorMessage: error is AppException
              ? error.message
              : 'We could not verify that API key right now.',
        ),
      );
      return null;
    }
  }

  void selectAuthMethod(ImmichAuthMethod authMethod) {
    emit(
      state.copyWith(
        step: OnboardingStep.credentials,
        authMethod: authMethod,
        clearPendingSession: true,
        clearError: true,
      ),
    );
  }

  void returnToAuthMethodStep() {
    emit(
      state.copyWith(
        step: OnboardingStep.authMethod,
        status: OnboardingStatus.idle,
        clearPendingSession: true,
        clearError: true,
      ),
    );
  }

  void returnToServerStep() {
    emit(
      state.copyWith(
        step: OnboardingStep.server,
        status: OnboardingStatus.idle,
        clearPendingSession: true,
        clearError: true,
      ),
    );
  }

  void returnToCredentialsStep() {
    emit(
      state.copyWith(
        step: OnboardingStep.credentials,
        status: OnboardingStatus.idle,
        clearError: true,
      ),
    );
  }
}
