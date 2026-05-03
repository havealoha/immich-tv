import 'package:dio/dio.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/models/authenticated_session.dart';
import '../../../core/models/server_config.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/network/immich_headers.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../platform/storage/session_storage.dart';

class ImmichAuthRepository implements AuthRepository {
  ImmichAuthRepository({
    required Dio dio,
    required SessionStorage sessionStorage,
  }) : _dio = dio,
       _sessionStorage = sessionStorage;

  final Dio _dio;
  final SessionStorage _sessionStorage;

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

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        serverConfig.apiUrl.resolve('auth/login').toString(),
        data: {'email': trimmedEmail, 'password': password},
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
        serverConfig.apiUrl.resolve('users/me').toString(),
        options: Options(headers: ImmichHeaders.sessionToken(token)),
      );

      final user = UserProfile.fromJson(
        profileResponse.data ?? const <String, dynamic>{},
      );
      final session = AuthenticatedSession(
        serverConfig: serverConfig,
        accessToken: token,
        user: user,
      );

      await _sessionStorage.saveSession(session);
      return session;
    } on DioException catch (error) {
      throw _mapSignInError(error);
    }
  }

  @override
  Future<AuthenticatedSession?> restoreSession() async {
    final stored = await _sessionStorage.readSession();
    if (stored == null) {
      return null;
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        stored.serverConfig.apiUrl.resolve('users/me').toString(),
        options: Options(
          headers: ImmichHeaders.sessionToken(stored.accessToken),
        ),
      );

      final user = UserProfile.fromJson(
        response.data ?? const <String, dynamic>{},
      );
      final refreshed = AuthenticatedSession(
        serverConfig: stored.serverConfig,
        accessToken: stored.accessToken,
        user: user,
      );
      await _sessionStorage.saveSession(refreshed);
      return refreshed;
    } on DioException {
      await _sessionStorage.clearSession();
      return null;
    }
  }

  @override
  Future<void> signOut() => _sessionStorage.clearSession();

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
}
