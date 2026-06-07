import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/saved_profile.dart';
import '../../core/models/saved_profile_secret.dart';
import 'profile_storage.dart';

ProfileStorage createPlatformProfileStorage() => _WebProfileStorage();

class _WebProfileStorage implements ProfileStorage {
  static const _profilesKey = 'immichtv.profiles';
  static const _secretKeyPrefix = 'immichtv.profile.secret.';

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_secretKey(profileId), jsonEncode(secret.toJson()));
  }

  @override
  Future<SavedProfileSecret?> readProfileSecret(String profileId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawSecret = prefs.getString(_secretKey(profileId));
    if (rawSecret == null || rawSecret.isEmpty) {
      return null;
    }

    return SavedProfileSecret.fromJson(
      jsonDecode(rawSecret) as Map<String, dynamic>,
    );
  }

  String _secretKey(String profileId) => '$_secretKeyPrefix$profileId';
}
