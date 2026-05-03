import 'package:equatable/equatable.dart';

class AppSession extends Equatable {
  const AppSession({
    required this.serverUrl,
    required this.userEmail,
    required this.displayName,
  });

  final String serverUrl;
  final String userEmail;
  final String displayName;

  @override
  List<Object?> get props => [serverUrl, userEmail, displayName];
}

enum AppStage { bootstrap, onboarding, home }

class AppFlowState extends Equatable {
  const AppFlowState({required this.stage, this.session});

  const AppFlowState.bootstrap() : this(stage: AppStage.bootstrap);

  const AppFlowState.onboarding() : this(stage: AppStage.onboarding);

  const AppFlowState.home(AppSession session)
    : this(stage: AppStage.home, session: session);

  final AppStage stage;
  final AppSession? session;

  @override
  List<Object?> get props => [stage, session];
}
