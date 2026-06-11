import '../models/immich_auth_method.dart';
import '../models/authenticated_session.dart';

class ImmichHeaders {
  const ImmichHeaders._();

  static Map<String, String> authHeaders({
    required String token,
    required ImmichAuthMethod authMethod,
    String? accept = 'application/json',
  }) {
    final headers = switch (authMethod) {
      ImmichAuthMethod.password => <String, String>{
        'X-Immich-Session-Token': token,
        'Authorization': 'Bearer $token',
      },
      ImmichAuthMethod.apiKey => <String, String>{'x-api-key': token},
    };
    if (accept == null) {
      return headers;
    }

    headers['Accept'] = accept;
    return headers;
  }

  static Map<String, String> sessionHeaders(
    AuthenticatedSession session, {
    String? accept = 'application/json',
  }) {
    return authHeaders(
      token: session.accessToken,
      authMethod: session.authMethod,
      accept: accept,
    );
  }

  static Map<String, String> mediaHeaders({
    required String token,
    required ImmichAuthMethod authMethod,
  }) {
    return authHeaders(token: token, authMethod: authMethod, accept: null);
  }

  static Map<String, String> mediaSessionHeaders(AuthenticatedSession session) {
    return mediaHeaders(
      token: session.accessToken,
      authMethod: session.authMethod,
    );
  }
}
