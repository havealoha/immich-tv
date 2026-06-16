import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../../../core/config/demo_mode.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/models/server_config.dart';
import '../../../core/models/server_validation_result.dart';
import '../../../core/repositories/server_repository.dart';
import '../../../core/services/certificate_trust_service.dart';
import '../../../core/services/server_url_normalizer.dart';

class ImmichServerRepository implements ServerRepository {
  ImmichServerRepository({
    required Dio dio,
    required ServerUrlNormalizer normalizer,
    CertificateTrustService? trustService,
  })  : _dio = dio,
        _normalizer = normalizer,
        _trustService = trustService ?? CertificateTrustService();

  final Dio _dio;
  final ServerUrlNormalizer _normalizer;
  final CertificateTrustService _trustService;

  @override
  Future<ServerValidationResult> validateServer(String rawInput) async {
    var config = _normalizer.normalize(rawInput);
    if (DemoMode.matchesRawInput(rawInput)) {
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
      final endpoint = api is Map<String, dynamic> ? api['endpoint'] as String? : null;

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
    final host = config.serverUrl.host;

    for (final candidate in candidates) {
      try {
        await _dio.get<dynamic>(config.apiEndpoint(candidate).toString());
        return candidate;
      } on DioException catch (error) {
        if (_isCertificateError(error)) {
          final cert = await _fetchServerCertificate(config.serverUrl);
          if (cert != null) {
            final isAlreadyTrusted = await _trustService.isCertificateTrusted(host, cert);
            if (isAlreadyTrusted) {
              throw AppException('Certificate trusted but connection still failing', code: 'cert_error');
            }

            throw AppException(
              'This server uses an untrusted certificate.',
              code: 'cert_untrusted',
              details: {
                'host': host,
                'certificate': cert,
              },
            );
          }
          throw const AppException('Could not retrieve server certificate.', code: 'cert_untrusted');
        }

        if (error.response?.statusCode == 404) continue;

        if (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout) {
          throw AppException(
            _unreachableMessage(config.serverUrl),
            code: 'server_unreachable',
          );
        }

        throw const AppException(
          'That server responded, but it does not look like a compatible Immich instance.',
          code: 'server_validation_failed',
        );
      }
    }

    throw const AppException(
      'We reached the host, but could not find a supported Immich API endpoint.',
      code: 'immich_api_not_found',
    );
  }

  bool _isCertificateError(DioException error) {
    final e = error.error;
    return e is HandshakeException ||
        e is CertificateException ||
        (e is SocketException && e.message.contains('CERTIFICATE_VERIFY_FAILED')) ||
        error.message?.contains('CERTIFICATE_VERIFY_FAILED') == true;
  }

  Future<X509Certificate?> _fetchServerCertificate(Uri serverUrl) async {
    try {
      final client = HttpClient();
      X509Certificate? serverCert;

      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        serverCert = cert;
        return true;
      };

      final request = await client.getUrl(serverUrl);
      final response = await request.close();
      await response.drain();
      client.close();
      return serverCert;
    } catch (e) {
      debugPrint('Failed to fetch certificate: $e');
      return null;
    }
  }

  String _stripTrailingSlash(Uri uri) {
    final str = uri.toString();
    return str.endsWith('/') ? str.substring(0, str.length - 1) : str;
  }

  String _unreachableMessage(Uri serverUrl) {
    return 'Could not reach ${serverUrl.host}. Check your network and server address.';
  }
}
