class ImmichHeaders {
  const ImmichHeaders._();

  static Map<String, String> sessionToken(
    String token, {
    String? accept = 'application/json',
  }) {
    if (accept == null) {
      return {
        'X-Immich-Session-Token': token,
        'Authorization': 'Bearer $token',
      };
    }

    return {
      'X-Immich-Session-Token': token,
      'Authorization': 'Bearer $token',
      'Accept': accept,
    };
  }

  static Map<String, String> mediaSessionToken(String token) {
    return sessionToken(token, accept: null);
  }
}
