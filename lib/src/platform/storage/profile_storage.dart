import '../../core/models/saved_profile.dart';
import '../../core/models/saved_profile_secret.dart';

abstract class ProfileStorage {
  Future<List<SavedProfile>> readProfiles();

  Future<void> saveProfile(SavedProfile profile);

  Future<void> saveProfileSecret({
    required String profileId,
    required SavedProfileSecret secret,
  });

  Future<SavedProfileSecret?> readProfileSecret(String profileId);
}
