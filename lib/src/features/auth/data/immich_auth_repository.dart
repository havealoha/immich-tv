import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/demo_mode.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/saved_profile.dart';
import '../../../core/models/saved_profile_secret.dart';
import '../../../core/models/server_config.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/immich_headers.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../features/mock/data/mock_auth_repository.dart';
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
      if (!DemoMode.matchesCredentials(email: trimmedEmail, password: password)) {
        throw AppException(
          'Use the demo credentials for ${DemoMode.serverUrl}.',
          code: 'invalid_demo_credentials',
        );
      }
      return MockAuthRepository(
        profileStorage: _profileStorage,
      ).signIn(
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
  Future<List<SavedProfile>> getSavedProfiles() {
    return _profileStorage.readProfiles();
  }

  @override
  Future<void> saveProfile({
    required AuthenticatedSession session,
    required String password,
    required String pin,
  }) async {
    _validatePin(pin);
    if (password.isEmpty) {
      throw const AppException(
        'Enter both email and password to save this profile.',
        code: 'missing_credentials',
      );
    }

    final profile = _savedProfileFromSession(session);
    await _profileStorage.saveProfile(profile);
    await _profileStorage.saveProfileSecret(
      profileId: profile.id,
      secret: SavedProfileSecret(password: password, pin: pin),
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
      final session = await _signInRemote(
        serverConfig: profile.serverConfig,
        email: profile.email,
        password: secret.password,
      );
      await _profileStorage.saveProfile(_savedProfileFromSession(session));
      return session;
    } on DioException catch (error) {
      throw _mapSignInError(error);
    }
  }

  @override
  Future<void> signOut() async {}

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

    final profileResponse = await _dio.get<Map<String, dynamic>>(
      serverConfig.apiEndpoint('users/me').toString(),
      options: Options(headers: ImmichHeaders.sessionToken(token)),
    );

    final user = UserProfile.fromJson(
      profileResponse.data ?? const <String, dynamic>{},
    );

    return AuthenticatedSession(
      serverConfig: serverConfig,
      accessToken: token,
      user: user,
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

  SavedProfile _savedProfileFromSession(AuthenticatedSession session) {
    return SavedProfile(
      id: _profileIdForSession(session),
      name: session.user.name,
      email: session.user.email,
      serverConfig: session.serverConfig,
      lastUsedAt: DateTime.now(),
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
