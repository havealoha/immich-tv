import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/demo_mode.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/immich_auth_method.dart';
import '../../../core/models/saved_profile.dart';
import '../../../core/models/saved_profile_secret.dart';
import '../../../core/models/server_config.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/immich_headers.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../features/mock/data/mock_auth_repository.dart';
import '../../../platform/auth/browser_session_bridge.dart';
import '../../../platform/storage/profile_storage.dart';

class ImmichAuthRepository implements AuthRepository {
  ImmichAuthRepository({
    required Dio dio,
    required ProfileStorage profileStorage,
  }) : _dio = dio,
       _profileStorage = profileStorage;

  final Dio _dio;
  final ProfileStorage _profileStorage;

  @override
  Future<AuthenticatedSession> signIn({
    required ServerConfig serverConfig,
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const AppException(
        'Enter both email and password to sign in.',
        code: 'missing_credentials',
      );
    }

    if (DemoMode.matchesServerUrl(serverConfig.serverUrl)) {
      if (!DemoMode.matchesCredentials(
        email: trimmedEmail,
        password: password,
      )) {
        throw AppException(
          'Use the demo credentials for ${DemoMode.serverUrl}.',
          code: 'invalid_demo_credentials',
        );
      }
      return MockAuthRepository(profileStorage: _profileStorage).signIn(
        serverConfig: serverConfig,
        email: trimmedEmail,
        password: password,
      );
    }

    try {
      return await _signInRemote(
        serverConfig: serverConfig,
        email: trimmedEmail,
        password: password,
      );
    } on DioException catch (error) {
      throw _mapSignInError(error);
    }
  }

  @override
  Future<AuthenticatedSession> signInWithApiKey({
    required ServerConfig serverConfig,
    required String apiKey,
  }) async {
    final trimmedApiKey = apiKey.trim();
    if (trimmedApiKey.isEmpty) {
      throw const AppException(
        'Enter an API key to continue.',
        code: 'missing_api_key',
      );
    }

    if (DemoMode.matchesServerUrl(serverConfig.serverUrl)) {
      return MockAuthRepository(
        profileStorage: _profileStorage,
      ).signInWithApiKey(serverConfig: serverConfig, apiKey: trimmedApiKey);
    }

    try {
      return await _authenticateWithCredential(
        serverConfig: serverConfig,
        credential: trimmedApiKey,
        authMethod: ImmichAuthMethod.apiKey,
      );
    } on DioException catch (error) {
      throw _mapApiKeyError(error);
    }
  }

  @override
  Future<List<SavedProfile>> getSavedProfiles() {
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
    switch (session.authMethod) {
      case ImmichAuthMethod.password:
        if (password == null || password.isEmpty) {
          throw const AppException(
            'Enter both email and password to save this profile.',
            code: 'missing_credentials',
          );
        }
      case ImmichAuthMethod.apiKey:
        if (apiKey == null || apiKey.isEmpty) {
          throw const AppException(
            'Enter an API key to save this profile.',
            code: 'missing_api_key',
          );
        }
    }

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

    if (DemoMode.matchesServerUrl(profile.serverConfig.serverUrl)) {
      return MockAuthRepository(
        profileStorage: _profileStorage,
      ).signInWithSavedProfile(profileId: profileId, pin: pin);
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

    try {
      final session = switch (profile.authMethod) {
        ImmichAuthMethod.password => await _signInRemote(
          serverConfig: profile.serverConfig,
          email: profile.email,
          password: secret.password ?? '',
        ),
        ImmichAuthMethod.apiKey => await _authenticateWithCredential(
          serverConfig: profile.serverConfig,
          credential: secret.apiKey ?? '',
          authMethod: ImmichAuthMethod.apiKey,
        ),
      };
      await _profileStorage.saveProfile(_savedProfileFromSession(session));
      return session;
    } on DioException catch (error) {
      throw profile.authMethod == ImmichAuthMethod.apiKey
          ? _mapApiKeyError(error)
          : _mapSignInError(error);
    }
  }

  @override
  Future<void> signOut() async {
    resetBrowserImmichSessions();
  }

  Future<AuthenticatedSession> _signInRemote({
    required ServerConfig serverConfig,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      serverConfig.apiEndpoint('auth/login').toString(),
      data: {'email': email, 'password': password},
    );

    final payload = response.data ?? const <String, dynamic>{};
    final token = payload['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw const AppException(
        'Immich did not return a session token.',
        code: 'missing_access_token',
      );
    }

    final session = await _authenticateWithCredential(
      serverConfig: serverConfig,
      credential: token,
      authMethod: ImmichAuthMethod.password,
    );

    await primeBrowserImmichSession(
      serverConfig: serverConfig,
      email: email,
      password: password,
    );

    return session;
  }

  Future<AuthenticatedSession> _authenticateWithCredential({
    required ServerConfig serverConfig,
    required String credential,
    required ImmichAuthMethod authMethod,
  }) async {
    final profileResponse = await _dio.get<Map<String, dynamic>>(
      serverConfig.apiEndpoint('users/me').toString(),
      options: Options(
        headers: ImmichHeaders.authHeaders(
          token: credential,
          authMethod: authMethod,
        ),
      ),
    );

    final user = UserProfile.fromJson(
      profileResponse.data ?? const <String, dynamic>{},
    );

    return AuthenticatedSession(
      serverConfig: serverConfig,
      accessToken: credential,
      user: user,
      authMethod: authMethod,
    );
  }

  AppException _mapSignInError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return const AppException(
        'Immich rejected those credentials. Double-check your email and password.',
        code: 'invalid_credentials',
      );
    }

    return AppException(
      'We could not complete the sign-in request right now.',
      code: 'sign_in_failed',
      cause: error,
    );
  }

  AppException _mapApiKeyError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401 || statusCode == 403) {
      return const AppException(
        'Immich rejected that API key. Check that it is still valid and has not been revoked.',
        code: 'invalid_api_key',
      );
    }

    return AppException(
      'We could not verify that API key right now.',
      code: 'api_key_failed',
      cause: error,
    );
  }

  SavedProfile _savedProfileFromSession(AuthenticatedSession session) {
    return SavedProfile(
      id: _profileIdForSession(session),
      name: session.user.name,
      email: session.user.email,
      serverConfig: session.serverConfig,
      lastUsedAt: DateTime.now(),
      authMethod: session.authMethod,
    );
  }

  String _profileIdForSession(AuthenticatedSession session) {
    return base64Url.encode(
      utf8.encode(
        '${session.serverConfig.serverUrl}::${session.user.id.toLowerCase()}',
      ),
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
