import 'package:flutter_test/flutter_test.dart';
import 'package:immichtv/src/core/models/authenticated_session.dart';
import 'package:immichtv/src/core/models/saved_profile.dart';
import 'package:immichtv/src/core/models/server_config.dart';
import 'package:immichtv/src/core/models/user_profile.dart';
import 'package:immichtv/src/core/repositories/auth_repository.dart';
import 'package:immichtv/src/features/app_flow/cubit/app_flow_cubit.dart';
import 'package:immichtv/src/features/app_flow/cubit/app_flow_state.dart';

void main() {
  test(
    'completeSignIn refreshes saved profiles so newly added users appear in the switcher',
    () async {
      final primaryProfile = _savedProfile(
        id: 'profile-1',
        email: 'livingroom@example.com',
        name: 'Living Room',
      );
      final addedProfile = _savedProfile(
        id: 'profile-2',
        email: 'guest@example.com',
        name: 'Guest',
      );
      final repository = _FakeAuthRepository(savedProfiles: [primaryProfile]);
      final cubit = AppFlowCubit(repository);
      addTearDown(cubit.close);

      await cubit.initialize();
      expect(cubit.state.stage, AppStage.profilePicker);
      expect(cubit.state.profiles, [primaryProfile]);

      cubit.showOnboarding();
      repository.savedProfiles = [primaryProfile, addedProfile];

      await cubit.completeSignIn(
        _session(email: addedProfile.email, name: addedProfile.name),
      );

      expect(cubit.state.stage, AppStage.home);
      expect(cubit.state.profiles, [primaryProfile, addedProfile]);
    },
  );
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({required this.savedProfiles});

  List<SavedProfile> savedProfiles;

  @override
  Future<List<SavedProfile>> getSavedProfiles() async =>
      List<SavedProfile>.from(savedProfiles);

  @override
  Future<void> saveProfile({
    required AuthenticatedSession session,
    String? password,
    String? apiKey,
    required String pin,
  }) async {}

  @override
  Future<AuthenticatedSession> signIn({
    required ServerConfig serverConfig,
    required String email,
    required String password,
  }) async => _session(email: email, name: email);

  @override
  Future<AuthenticatedSession> signInWithApiKey({
    required ServerConfig serverConfig,
    required String apiKey,
  }) async => _session(email: 'apikey@example.com', name: 'API Key');

  @override
  Future<AuthenticatedSession> signInWithSavedProfile({
    required String profileId,
    required String pin,
  }) async => _session(email: 'saved@example.com', name: 'Saved');

  @override
  Future<void> signOut() async {}
}

AuthenticatedSession _session({required String email, required String name}) {
  final serverConfig = ServerConfig(
    rawInput: 'https://photos.example.com',
    serverUrl: Uri.parse('https://photos.example.com'),
    apiUrl: Uri.parse('https://photos.example.com/api'),
  );
  return AuthenticatedSession(
    serverConfig: serverConfig,
    accessToken: 'token',
    user: UserProfile(id: email, email: email, name: name),
  );
}

SavedProfile _savedProfile({
  required String id,
  required String email,
  required String name,
}) {
  final session = _session(email: email, name: name);
  return SavedProfile(
    id: id,
    name: name,
    email: email,
    serverConfig: session.serverConfig,
    lastUsedAt: DateTime(2026, 5, 17),
  );
}
