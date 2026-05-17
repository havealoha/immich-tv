import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:immichtv/src/core/config/demo_mode.dart';
import 'package:immichtv/src/core/models/saved_profile.dart';
import 'package:immichtv/src/core/models/saved_profile_secret.dart';
import 'package:immichtv/src/core/models/server_config.dart';
import 'package:immichtv/src/platform/storage/profile_storage.dart';
import 'package:immichtv/src/features/auth/data/immich_auth_repository.dart';

void main() {
  test('saved demo profiles unlock through mock auth without remote login', () async {
    final profileStorage = _InMemoryProfileStorage(
      profiles: [
        SavedProfile(
          id: 'demo-profile',
          name: 'Demo User',
          email: DemoMode.email,
          serverConfig: ServerConfig(
            rawInput: DemoMode.serverUrl,
            serverUrl: Uri.parse(DemoMode.serverUrl),
            apiUrl: Uri.parse('${DemoMode.serverUrl}/api'),
          ),
          lastUsedAt: DateTime(2026),
        ),
      ],
      secrets: const {
        'demo-profile': SavedProfileSecret(
          password: DemoMode.password,
          pin: '1234',
        ),
      },
    );
    final dio = Dio()..httpClientAdapter = _ThrowingHttpClientAdapter();
    final repository = ImmichAuthRepository(
      dio: dio,
      profileStorage: profileStorage,
    );

    final session = await repository.signInWithSavedProfile(
      profileId: 'demo-profile',
      pin: '1234',
    );

    expect(session.user.email, DemoMode.email);
    expect(session.serverConfig.serverUrl.toString(), DemoMode.serverUrl);
    expect(session.accessToken, startsWith('mock-token-'));
  });

  test('saved real profiles still use remote login', () async {
    final serverConfig = ServerConfig(
      rawInput: 'https://photos.example.com',
      serverUrl: Uri.parse('https://photos.example.com'),
      apiUrl: Uri.parse('https://photos.example.com/api'),
    );
    final profileStorage = _InMemoryProfileStorage(
      profiles: [
        SavedProfile(
          id: 'real-profile',
          name: 'Family Room',
          email: 'family@example.com',
          serverConfig: serverConfig,
          lastUsedAt: DateTime(2026),
        ),
      ],
      secrets: const {
        'real-profile': SavedProfileSecret(
          password: 'secret-password',
          pin: '1234',
        ),
      },
    );
    final dio = Dio()
      ..httpClientAdapter = _RecordingHttpClientAdapter(
        responses: {
          'POST https://photos.example.com/api/auth/login': ResponseBody.fromString(
            jsonEncode({'accessToken': 'remote-token'}),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          ),
          'GET https://photos.example.com/api/users/me': ResponseBody.fromString(
            jsonEncode({
              'id': 'remote-user',
              'email': 'family@example.com',
              'name': 'Family Room',
            }),
            200,
            headers: {
              Headers.contentTypeHeader: ['application/json'],
            },
          ),
        },
      );
    final repository = ImmichAuthRepository(
      dio: dio,
      profileStorage: profileStorage,
    );

    final session = await repository.signInWithSavedProfile(
      profileId: 'real-profile',
      pin: '1234',
    );

    expect(session.accessToken, 'remote-token');
    expect(session.user.email, 'family@example.com');
    expect(
      (dio.httpClientAdapter as _RecordingHttpClientAdapter).requests,
      containsAll(<String>[
        'POST https://photos.example.com/api/auth/login',
        'GET https://photos.example.com/api/users/me',
      ]),
    );
  });
}

class _InMemoryProfileStorage implements ProfileStorage {
  _InMemoryProfileStorage({
    required List<SavedProfile> profiles,
    required Map<String, SavedProfileSecret> secrets,
  }) : _profiles = List<SavedProfile>.from(profiles),
       _secrets = Map<String, SavedProfileSecret>.from(secrets);

  final List<SavedProfile> _profiles;
  final Map<String, SavedProfileSecret> _secrets;

  @override
  Future<List<SavedProfile>> readProfiles() async => List<SavedProfile>.from(_profiles);

  @override
  Future<SavedProfileSecret?> readProfileSecret(String profileId) async => _secrets[profileId];

  @override
  Future<void> saveProfile(SavedProfile profile) async {
    final index = _profiles.indexWhere((item) => item.id == profile.id);
    if (index >= 0) {
      _profiles[index] = profile;
      return;
    }
    _profiles.add(profile);
  }

  @override
  Future<void> saveProfileSecret({
    required String profileId,
    required SavedProfileSecret secret,
  }) async {
    _secrets[profileId] = secret;
  }
}

class _ThrowingHttpClientAdapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw StateError('Unexpected network request: ${options.method} ${options.uri}');
  }
}

class _RecordingHttpClientAdapter implements HttpClientAdapter {
  _RecordingHttpClientAdapter({required this.responses});

  final Map<String, ResponseBody> responses;
  final List<String> requests = <String>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.uri}';
    requests.add(key);
    final response = responses[key];
    if (response == null) {
      throw StateError('No stubbed response for $key');
    }
    return response;
  }
}
