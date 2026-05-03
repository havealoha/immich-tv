import 'package:equatable/equatable.dart';

import '../../../core/models/authenticated_session.dart';

enum AppStage { bootstrap, onboarding, home }

class AppFlowState extends Equatable {
  const AppFlowState({required this.stage, this.session});

  const AppFlowState.bootstrap() : this(stage: AppStage.bootstrap);

  const AppFlowState.onboarding() : this(stage: AppStage.onboarding);

  const AppFlowState.home(AuthenticatedSession session)
    : this(stage: AppStage.home, session: session);

  final AppStage stage;
  final AuthenticatedSession? session;

  @override
  List<Object?> get props => [stage, session];
}
