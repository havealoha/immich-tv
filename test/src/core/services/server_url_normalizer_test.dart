import 'package:flutter_test/flutter_test.dart';
import 'package:immichtv/src/core/services/server_url_normalizer.dart';

void main() {
  const normalizer = ServerUrlNormalizer();

  test('adds a default scheme and api path', () {
    final config = normalizer.normalize('photos.example.com');

    expect(config.serverUrl.toString(), 'http://photos.example.com');
    expect(config.apiUrl.toString(), 'http://photos.example.com/api');
  });

  test('keeps an explicit api endpoint when provided', () {
    final config = normalizer.normalize('https://photos.example.com/api/');

    expect(config.serverUrl.toString(), 'https://photos.example.com');
    expect(config.apiUrl.toString(), 'https://photos.example.com/api');
  });

  test('preserves subpaths for reverse proxy installations', () {
    final config = normalizer.normalize('https://example.com/immich');

    expect(config.serverUrl.toString(), 'https://example.com/immich');
    expect(config.apiUrl.toString(), 'https://example.com/immich/api');
  });
}
