import 'package:equatable/equatable.dart';

import '../../../core/models/server_config.dart';

enum OnboardingStep { server, credentials }

enum OnboardingStatus { idle, validatingServer, signingIn }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.server,
    this.status = OnboardingStatus.idle,
    this.serverConfig,
    this.errorMessage,
  });

  final OnboardingStep step;
  final OnboardingStatus status;
  final ServerConfig? serverConfig;
  final String? errorMessage;

  bool get isBusy => status != OnboardingStatus.idle;
  bool get hasValidatedServer => serverConfig != null;

  OnboardingState copyWith({
    OnboardingStep? step,
    OnboardingStatus? status,
    ServerConfig? serverConfig,
    String? errorMessage,
    bool clearServerConfig = false,
    bool clearError = false,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      status: status ?? this.status,
      serverConfig: clearServerConfig
          ? null
          : (serverConfig ?? this.serverConfig),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [step, status, serverConfig, errorMessage];
}
