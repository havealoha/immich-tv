import 'package:equatable/equatable.dart';

import '../../../core/models/authenticated_session.dart';
import '../../../core/models/immich_auth_method.dart';
import '../../../core/models/server_config.dart';

enum OnboardingStep { server, authMethod, credentials, pin }

enum OnboardingStatus { idle, validatingServer, signingIn, savingProfile }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.serverUrl,
    this.status = OnboardingStatus.idle,
    this.serverConfig,
    this.email,
    this.password,
    this.errorMessage,
    this.pendingCertificate,   // ← NEW
  });

  final OnboardingStep step;
  final OnboardingStatus status;
  final ServerConfig? serverConfig;
  final String? email;
  final String? password;
  final String? errorMessage;
  final X509Certificate? pendingCertificate;   // ← NEW

  OnboardingState copyWith({
    OnboardingStep? step,
    OnboardingStatus? status,
    ServerConfig? serverConfig,
    String? email,
    String? password,
    String? errorMessage,
    bool clearError = false,
    X509Certificate? pendingCertificate,   // ← NEW
  }) {
    return OnboardingState(
      step: step ?? this.step,
      status: status ?? this.status,
      serverConfig: serverConfig ?? this.serverConfig,
      email: email ?? this.email,
      password: password ?? this.password,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingCertificate: pendingCertificate ?? this.pendingCertificate,
    );
  }

  @override
  List<Object?> get props => [
        step,
        status,
        serverConfig,
        email,
        password,
        errorMessage,
        pendingCertificate,
      ];
}
