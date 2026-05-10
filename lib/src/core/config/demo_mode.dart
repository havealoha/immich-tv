class DemoMode {
  const DemoMode._();

  static const String serverUrl = 'https://demo.immichtv.local';
  static const String email = 'demo@immich.tv';
  static const String password = 'demo1234';

  static bool matchesRawInput(String rawInput) {
    return rawInput.trim().toLowerCase() == serverUrl;
  }

  static bool matchesServerUrl(Uri serverUri) {
    return _normalizeUrl(serverUri.toString()) == serverUrl;
  }

  static bool matchesCredentials({
    required String email,
    required String password,
  }) {
    return email.trim().toLowerCase() == DemoMode.email && password == DemoMode.password;
  }

  static String _normalizeUrl(String value) {
    return value.trim().toLowerCase().replaceFirst(RegExp(r'/+$'), '');
  }
}
