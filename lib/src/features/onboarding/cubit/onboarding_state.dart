import 'package:equatable/equatable.dart';

enum OnboardingStep { server, credentials }

enum OnboardingStatus { idle, validatingServer, signingIn }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.server,
    this.status = OnboardingStatus.idle,
  });

  final OnboardingStep step;
  final OnboardingStatus status;

  bool get isBusy => status != OnboardingStatus.idle;

  OnboardingState copyWith({OnboardingStep? step, OnboardingStatus? status}) {
    return OnboardingState(
      step: step ?? this.step,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [step, status];
}
