class ImmichHeaders {
  const ImmichHeaders._();

  static Map<String, String> sessionToken(String token) {
    return {'X-Immich-Session-Token': token, 'Accept': 'application/json'};
  }
}
