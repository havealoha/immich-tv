import '../../core/models/saved_profile.dart';
import '../../core/models/saved_profile_secret.dart';
import 'profile_storage.dart';
import 'platform_profile_storage_io.dart'
    if (dart.library.js_interop) 'platform_profile_storage_web.dart' as impl;

class PlatformProfileStorage implements ProfileStorage {
  PlatformProfileStorage() : _delegate = impl.createPlatformProfileStorage();

  final ProfileStorage _delegate;

  @override
  Future<List<SavedProfile>> readProfiles() => _delegate.readProfiles();

  @override
  Future<void> saveProfile(SavedProfile profile) =>
      _delegate.saveProfile(profile);

  @override
  Future<void> saveProfileSecret({
    required String profileId,
    required SavedProfileSecret secret,
  }) => _delegate.saveProfileSecret(profileId: profileId, secret: secret);

  @override
  Future<SavedProfileSecret?> readProfileSecret(String profileId) =>
      _delegate.readProfileSecret(profileId);
}
