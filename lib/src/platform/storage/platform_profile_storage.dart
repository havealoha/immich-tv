import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import '../../core/models/saved_profile.dart';
import '../../core/models/saved_profile_secret.dart';
import 'profile_storage.dart';

class PlatformProfileStorage implements ProfileStorage {
  PlatformProfileStorage({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _profilesKey = 'immichtv.profiles';
  static const _secretKeyPrefix = 'immichtv.profile.secret.';

  final FlutterSecureStorage _secureStorage;

  @override
  Future<List<SavedProfile>> readProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfiles = prefs.getString(_profilesKey);
    if (rawProfiles == null || rawProfiles.isEmpty) {
      return const <SavedProfile>[];
    }

    final decoded = jsonDecode(rawProfiles) as List<dynamic>;
    final profiles = decoded
        .cast<Map<String, dynamic>>()
        .map(SavedProfile.fromJson)
        .toList(growable: false);
    profiles.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return profiles;
  }

  @override
  Future<void> saveProfile(SavedProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    final profiles = (await readProfiles()).toList(growable: true);
    final index = profiles.indexWhere((item) => item.id == profile.id);

    if (index >= 0) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }

    profiles.sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    await prefs.setString(
      _profilesKey,
      jsonEncode(profiles.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  @override
  Future<void> saveProfileSecret({
    required String profileId,
    required SavedProfileSecret secret,
  }) async {
    try {
      await _secureStorage.write(
        key: _secretKey(profileId),
        value: jsonEncode(secret.toJson()),
      );
    } catch (error) {
      throw AppException(
        'This device could not securely store profile credentials.',
        code: 'secure_storage_unavailable',
        cause: error,
      );
    }
  }

  @override
  Future<SavedProfileSecret?> readProfileSecret(String profileId) async {
    try {
      final rawSecret = await _secureStorage.read(key: _secretKey(profileId));
      if (rawSecret == null || rawSecret.isEmpty) {
        return null;
      }

      return SavedProfileSecret.fromJson(
        jsonDecode(rawSecret) as Map<String, dynamic>,
      );
    } catch (error) {
      throw AppException(
        'This device could not securely access saved profile credentials.',
        code: 'secure_storage_unavailable',
        cause: error,
      );
    }
  }

  String _secretKey(String profileId) => '$_secretKeyPrefix$profileId';
}
