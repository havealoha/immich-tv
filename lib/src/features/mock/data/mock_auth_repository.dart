import '../../../core/errors/app_exception.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/server_config.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../platform/storage/session_storage.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({required SessionStorage sessionStorage})
    : _sessionStorage = sessionStorage;

  final SessionStorage _sessionStorage;

  @override
  Future<AuthenticatedSession> signIn({
    required ServerConfig serverConfig,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 540));

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const AppException(
        'Enter both email and password to continue in demo mode.',
        code: 'mock_missing_credentials',
      );
    }

    final session = AuthenticatedSession(
      serverConfig: serverConfig,
      accessToken: 'mock-token-${trimmedEmail.hashCode}',
      user: UserProfile(
        id: 'mock-user',
        email: trimmedEmail,
        name: _displayNameFromEmail(trimmedEmail),
      ),
    );

    await _sessionStorage.saveSession(session);
    return session;
  }

  @override
  Future<AuthenticatedSession?> restoreSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return _sessionStorage.readSession();
  }

  @override
  Future<void> signOut() => _sessionStorage.clearSession();

  String _displayNameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'Living Room';
    }

    return localPart
        .split(RegExp(r'[._-]+'))
        .where((segment) => segment.isNotEmpty)
        .map((segment) => '${segment[0].toUpperCase()}${segment.substring(1)}')
        .join(' ');
  }
}
