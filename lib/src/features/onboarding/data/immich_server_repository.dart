import 'package:dio/dio.dart';

import '../../../core/config/demo_mode.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/server_config.dart';
import '../../../core/models/server_validation_result.dart';
import '../../../core/repositories/server_repository.dart';
import '../../../core/services/server_url_normalizer.dart';

class ImmichServerRepository implements ServerRepository {
  ImmichServerRepository({
    required Dio dio,
    required ServerUrlNormalizer normalizer,
  }) : _dio = dio,
       _normalizer = normalizer;

  final Dio _dio;
  final ServerUrlNormalizer _normalizer;

  @override
  Future<ServerValidationResult> validateServer(String rawInput) async {
    var config = _normalizer.normalize(rawInput);
    if (DemoMode.matchesServerUrl(config.serverUrl)) {
      return ServerValidationResult(
        serverConfig: config,
        pingPath: 'demo/ping',
      );
    }
    config = await _discoverApiEndpoint(config);

    final pingPath = await _pingCompatibleEndpoint(config);
    return ServerValidationResult(serverConfig: config, pingPath: pingPath);
  }

  Future<ServerConfig> _discoverApiEndpoint(ServerConfig config) async {
    final wellKnownUrl = config.serverEndpoint('.well-known/immich');

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        wellKnownUrl.toString(),
      );
      final body = response.data;
      final api = body?['api'];
      final endpoint = api is Map<String, dynamic>
          ? api['endpoint'] as String?
          : null;

      if (endpoint == null || endpoint.trim().isEmpty) {
        return config;
      }

      final resolvedApiUrl = config.serverUrl.resolve(endpoint);
      return config.copyWith(apiUrl: _stripTrailingSlash(resolvedApiUrl));
    } on DioException {
      return config;
    }
  }

  Future<String> _pingCompatibleEndpoint(ServerConfig config) async {
    final candidates = ['server/ping', 'server-info/ping'];

    for (final candidate in candidates) {
      try {
        await _dio.get<dynamic>(config.apiEndpoint(candidate).toString());
        return candidate;
      } on DioException catch (error) {
        if (error.response?.statusCode == 404) {
          continue;
        }

        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          throw const AppException(
            'We could not reach that server. Check the URL and make sure Immich is available.',
            code: 'server_unreachable',
          );
        }

        throw const AppException(
          'That server responded, but it does not look like a compatible Immich instance yet.',
          code: 'server_validation_failed',
        );
      }
    }

    throw const AppException(
      'We reached the host, but could not find a supported Immich API endpoint.',
      code: 'immich_api_not_found',
    );
  }

  Uri _stripTrailingSlash(Uri uri) {
    final normalizedPath = uri.path.replaceFirst(RegExp(r'/+$'), '');
    return uri.replace(path: normalizedPath.isEmpty ? '' : normalizedPath);
  }
}
