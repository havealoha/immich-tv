import '../models/authenticated_session.dart';
import '../models/saved_profile.dart';
import '../models/server_config.dart';

abstract class AuthRepository {
  Future<AuthenticatedSession> signIn({
    required ServerConfig serverConfig,
    required String email,
    required String password,
  });

  Future<List<SavedProfile>> getSavedProfiles();

  Future<void> saveProfile({
    required AuthenticatedSession session,
    required String password,
    required String pin,
  });

  Future<AuthenticatedSession> signInWithSavedProfile({
    required String profileId,
    required String pin,
  });

  Future<void> signOut();
}
