import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

import '../../core/models/server_config.dart';
import '../../core/network/immich_dio_factory.dart';

final Map<String, bool> _originSessionReadiness = <String, bool>{};

final Dio _browserSessionDio = () {
  final dio = ImmichDioFactory.create();
  dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: true);
  return dio;
}();

Future<void> primeBrowserImmichSession({
  required ServerConfig serverConfig,
  required String email,
  required String password,
}) async {
  final originKey = _originKey(serverConfig.serverUrl);
  if (_originSessionReadiness[originKey] == true) {
    return;
  }

  try {
    await _browserSessionDio.post<void>(
      serverConfig.apiEndpoint('auth/login').toString(),
      data: <String, String>{'email': email, 'password': password},
      options: Options(extra: const <String, Object>{'withCredentials': true}),
    );
    _originSessionReadiness[originKey] = true;
  } catch (_) {
    _originSessionReadiness[originKey] = false;
  }
}

bool canUseDirectBrowserMediaPlayback(Uri mediaUri) {
  return _originSessionReadiness[_originKey(mediaUri)] == true;
}

void markDirectBrowserMediaPlaybackFailure(Uri mediaUri) {
  _originSessionReadiness[_originKey(mediaUri)] = false;
}

void resetBrowserImmichSessions() {
  _originSessionReadiness.clear();
}

String _originKey(Uri uri) => '${uri.scheme}://${uri.authority}';
