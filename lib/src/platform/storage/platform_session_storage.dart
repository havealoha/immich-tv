import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/authenticated_session.dart';
import 'session_storage.dart';

class PlatformSessionStorage implements SessionStorage {
  PlatformSessionStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _sessionMetadataKey = 'immichtv.session.metadata';
  static const _sessionTokenKey = 'immichtv.session.token';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> saveSession(AuthenticatedSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionMetadataKey,
      jsonEncode({
        'serverConfig': session.serverConfig.toJson(),
        'user': session.user.toJson(),
      }),
    );

    try {
      await _secureStorage.write(
        key: _sessionTokenKey,
        value: session.accessToken,
      );
      await prefs.remove(_sessionTokenKey);
    } catch (_) {
      await prefs.setString(_sessionTokenKey, session.accessToken);
    }
  }

  @override
  Future<AuthenticatedSession?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    final metadata = prefs.getString(_sessionMetadataKey);
    if (metadata == null) {
      return null;
    }

    String? token;
    try {
      token = await _secureStorage.read(key: _sessionTokenKey);
    } catch (_) {
      token = null;
    }
    token ??= prefs.getString(_sessionTokenKey);

    if (token == null || token.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(metadata) as Map<String, dynamic>;
    return AuthenticatedSession.fromJson({
      'serverConfig': decoded['serverConfig'],
      'user': decoded['user'],
      'accessToken': token,
    });
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionMetadataKey);
    await prefs.remove(_sessionTokenKey);

    try {
      await _secureStorage.delete(key: _sessionTokenKey);
    } catch (_) {
      // Fall back to shared preferences only.
    }
  }
}
