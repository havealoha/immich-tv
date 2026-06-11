import 'dart:convert';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/immich_auth_method.dart';
import '../../../core/models/saved_profile.dart';
import '../../../core/models/saved_profile_secret.dart';
import '../../../core/models/server_config.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../platform/storage/profile_storage.dart';

class MockAuthRepository implements AuthRepository {
  MockAuthRepository({required ProfileStorage profileStorage})
    : _profileStorage = profileStorage;

  final ProfileStorage _profileStorage;

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

    return AuthenticatedSession(
      serverConfig: serverConfig,
      accessToken: 'mock-token-${trimmedEmail.hashCode}',
      user: UserProfile(
        id: 'mock-user-${trimmedEmail.toLowerCase()}',
        email: trimmedEmail,
        name: _displayNameFromEmail(trimmedEmail),
      ),
      authMethod: ImmichAuthMethod.password,
    );
  }

  @override
  Future<AuthenticatedSession> signInWithApiKey({
    required ServerConfig serverConfig,
    required String apiKey,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 360));

    final trimmedApiKey = apiKey.trim();
    if (trimmedApiKey.isEmpty) {
      throw const AppException(
        'Enter an API key to continue in demo mode.',
        code: 'mock_missing_api_key',
      );
    }

    return AuthenticatedSession(
      serverConfig: serverConfig,
      accessToken: trimmedApiKey,
      user: const UserProfile(
        id: 'mock-api-user',
        email: 'apikey@demo.immich',
        name: 'API Key User',
      ),
      authMethod: ImmichAuthMethod.apiKey,
    );
  }

  @override
  Future<List<SavedProfile>> getSavedProfiles() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return _profileStorage.readProfiles();
  }

  @override
  Future<void> saveProfile({
    required AuthenticatedSession session,
    String? password,
    String? apiKey,
    required String pin,
  }) async {
    _validatePin(pin);
    final profile = _savedProfileFromSession(session);
    await _profileStorage.saveProfile(profile);
    await _profileStorage.saveProfileSecret(
      profileId: profile.id,
      secret: SavedProfileSecret(password: password, apiKey: apiKey, pin: pin),
    );
  }

  @override
  Future<AuthenticatedSession> signInWithSavedProfile({
    required String profileId,
    required String pin,
  }) async {
    _validatePin(pin);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final profiles = await _profileStorage.readProfiles();
    SavedProfile? profile;
    for (final item in profiles) {
      if (item.id == profileId) {
        profile = item;
        break;
      }
    }

    if (profile == null) {
      throw const AppException(
        'That profile is no longer available on this device.',
        code: 'profile_not_found',
      );
    }

    final secret = await _profileStorage.readProfileSecret(profileId);
    if (secret == null) {
      throw const AppException(
        'Saved credentials for that profile are unavailable.',
        code: 'profile_secret_missing',
      );
    }

    if (secret.pin != pin) {
      throw const AppException(
        'That PIN did not match this profile.',
        code: 'invalid_pin',
      );
    }

    final session = switch (profile.authMethod) {
      ImmichAuthMethod.password => await signIn(
        serverConfig: profile.serverConfig,
        email: profile.email,
        password: secret.password ?? '',
      ),
      ImmichAuthMethod.apiKey => await signInWithApiKey(
        serverConfig: profile.serverConfig,
        apiKey: secret.apiKey ?? '',
      ),
    };
    await _profileStorage.saveProfile(_savedProfileFromSession(session));
    return session;
  }

  @override
  Future<void> signOut() async {}

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

  SavedProfile _savedProfileFromSession(AuthenticatedSession session) {
    return SavedProfile(
      id: base64Url.encode(
        utf8.encode(
          '${session.serverConfig.serverUrl}::${session.user.id.toLowerCase()}',
        ),
      ),
      name: session.user.name,
      email: session.user.email,
      serverConfig: session.serverConfig,
      lastUsedAt: DateTime.now(),
      authMethod: session.authMethod,
    );
  }

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw const AppException(
        'Enter a 4-digit PIN to save or unlock a profile.',
        code: 'invalid_pin_format',
      );
    }
  }
}
