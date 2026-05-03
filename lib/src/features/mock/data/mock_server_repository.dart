import '../../../core/errors/app_exception.dart';
import '../../../core/models/server_validation_result.dart';
import '../../../core/repositories/server_repository.dart';
import '../../../core/services/server_url_normalizer.dart';

class MockServerRepository implements ServerRepository {
  MockServerRepository({required ServerUrlNormalizer normalizer})
    : _normalizer = normalizer;

  final ServerUrlNormalizer _normalizer;

  @override
  Future<ServerValidationResult> validateServer(String rawInput) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));

    if (rawInput.trim().isEmpty) {
      throw const AppException(
        'Enter a demo server URL to continue.',
        code: 'mock_server_empty',
      );
    }

    final config = _normalizer.normalize(rawInput);
    return ServerValidationResult(
      serverConfig: config,
      pingPath: 'server/ping',
    );
  }
}
