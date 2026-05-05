import 'package:equatable/equatable.dart';

import '../../../core/models/authenticated_session.dart';
import '../../../core/models/saved_profile.dart';

enum AppStage { bootstrap, profilePicker, onboarding, home }

class AppFlowState extends Equatable {
  const AppFlowState({
    required this.stage,
    this.session,
    this.profiles = const <SavedProfile>[],
  });

  const AppFlowState.bootstrap() : this(stage: AppStage.bootstrap);

  const AppFlowState.profilePicker(List<SavedProfile> profiles)
    : this(stage: AppStage.profilePicker, profiles: profiles);

  const AppFlowState.onboarding({List<SavedProfile> profiles = const []})
    : this(stage: AppStage.onboarding, profiles: profiles);

  const AppFlowState.home(
    AuthenticatedSession session, {
    List<SavedProfile> profiles = const [],
  }) : this(stage: AppStage.home, session: session, profiles: profiles);

  final AppStage stage;
  final AuthenticatedSession? session;
  final List<SavedProfile> profiles;

  @override
  List<Object?> get props => [stage, session, profiles];
}
