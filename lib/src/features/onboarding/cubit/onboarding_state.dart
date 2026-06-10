import 'package:equatable/equatable.dart';

import '../../../core/models/authenticated_session.dart';
import '../../../core/models/immich_auth_method.dart';
import '../../../core/models/server_config.dart';

enum OnboardingStep { server, authMethod, credentials, pin }

enum OnboardingStatus { idle, validatingServer, signingIn, savingProfile }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.server,
    this.status = OnboardingStatus.idle,
    this.serverConfig,
    this.pendingSession,
    this.errorMessage,
    this.authMethod = ImmichAuthMethod.password,
  });

  final OnboardingStep step;
  final OnboardingStatus status;
  final ServerConfig? serverConfig;
  final AuthenticatedSession? pendingSession;
  final String? errorMessage;
  final ImmichAuthMethod authMethod;

  bool get isBusy => status != OnboardingStatus.idle;
  bool get hasValidatedServer => serverConfig != null;
  bool get hasPendingSession => pendingSession != null;

  OnboardingState copyWith({
    OnboardingStep? step,
    OnboardingStatus? status,
    ServerConfig? serverConfig,
    AuthenticatedSession? pendingSession,
    String? errorMessage,
    ImmichAuthMethod? authMethod,
    bool clearServerConfig = false,
    bool clearPendingSession = false,
    bool clearError = false,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      status: status ?? this.status,
      serverConfig: clearServerConfig
          ? null
          : (serverConfig ?? this.serverConfig),
      pendingSession: clearPendingSession
          ? null
          : (pendingSession ?? this.pendingSession),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      authMethod: authMethod ?? this.authMethod,
    );
  }

  @override
  List<Object?> get props => [
    step,
    status,
    serverConfig,
    pendingSession,
    errorMessage,
    authMethod,
  ];
}
