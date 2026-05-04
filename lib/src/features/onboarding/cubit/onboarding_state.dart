import 'package:equatable/equatable.dart';

import '../../../core/models/authenticated_session.dart';
import '../../../core/models/server_config.dart';

enum OnboardingStep { server, credentials, pin }

enum OnboardingStatus { idle, validatingServer, signingIn, savingProfile }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.server,
    this.status = OnboardingStatus.idle,
    this.serverConfig,
    this.pendingSession,
    this.errorMessage,
  });

  final OnboardingStep step;
  final OnboardingStatus status;
  final ServerConfig? serverConfig;
  final AuthenticatedSession? pendingSession;
  final String? errorMessage;

  bool get isBusy => status != OnboardingStatus.idle;
  bool get hasValidatedServer => serverConfig != null;
  bool get hasPendingSession => pendingSession != null;

  OnboardingState copyWith({
    OnboardingStep? step,
    OnboardingStatus? status,
    ServerConfig? serverConfig,
    AuthenticatedSession? pendingSession,
    String? errorMessage,
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
    );
  }

  @override
  List<Object?> get props => [
    step,
    status,
    serverConfig,
    pendingSession,
    errorMessage,
  ];
}
