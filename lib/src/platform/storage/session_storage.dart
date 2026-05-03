import '../../core/models/authenticated_session.dart';

abstract class SessionStorage {
  Future<void> saveSession(AuthenticatedSession session);

  Future<AuthenticatedSession?> readSession();

  Future<void> clearSession();
}
