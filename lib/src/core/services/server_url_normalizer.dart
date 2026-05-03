import '../errors/app_exception.dart';
import '../models/server_config.dart';

class ServerUrlNormalizer {
  const ServerUrlNormalizer();

  ServerConfig normalize(String rawInput) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      throw const AppException(
        'Enter the URL of your Immich server to continue.',
        code: 'empty_server_url',
      );
    }

    final withScheme = trimmed.contains('://') ? trimmed : 'http://$trimmed';
    final parsed = Uri.tryParse(withScheme);
    if (parsed == null || parsed.host.isEmpty) {
      throw const AppException(
        'That server URL does not look valid yet.',
        code: 'invalid_server_url',
      );
    }

    final sanitizedPath = _sanitizePath(parsed.path);
    final normalized = parsed.replace(
      path: sanitizedPath,
      query: null,
      fragment: null,
    );

    if (_isApiPath(normalized.pathSegments)) {
      final serverSegments = normalized.pathSegments.take(
        normalized.pathSegments.length - 1,
      );
      return ServerConfig(
        rawInput: rawInput,
        serverUrl: normalized.replace(pathSegments: serverSegments),
        apiUrl: normalized,
      );
    }

    final serverUrl = normalized;
    final apiSegments = [
      ...serverUrl.pathSegments.where((segment) => segment.isNotEmpty),
      'api',
    ];

    return ServerConfig(
      rawInput: rawInput,
      serverUrl: serverUrl,
      apiUrl: serverUrl.replace(pathSegments: apiSegments),
    );
  }

  String _sanitizePath(String path) {
    if (path.isEmpty || path == '/') {
      return '';
    }

    final trimmed = path.replaceFirst(RegExp(r'/+$'), '');
    return trimmed.isEmpty ? '' : trimmed;
  }

  bool _isApiPath(List<String> pathSegments) {
    return pathSegments.isNotEmpty && pathSegments.last == 'api';
  }
}
