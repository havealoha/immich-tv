import '../models/authenticated_session.dart';
import '../models/server_config.dart';

abstract class AuthRepository {
  Future<AuthenticatedSession> signIn({
    required ServerConfig serverConfig,
    required String email,
    required String password,
  });

  Future<AuthenticatedSession?> restoreSession();

  Future<void> signOut();
}
