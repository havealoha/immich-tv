enum ImmichAuthMethod {
  password,
  apiKey;

  String get storageValue => switch (this) {
    ImmichAuthMethod.password => 'password',
    ImmichAuthMethod.apiKey => 'apiKey',
  };

  String get displayLabel => switch (this) {
    ImmichAuthMethod.password => 'Email and password',
    ImmichAuthMethod.apiKey => 'API key',
  };

  static ImmichAuthMethod fromStorageValue(String? value) {
    return switch (value) {
      'apiKey' => ImmichAuthMethod.apiKey,
      _ => ImmichAuthMethod.password,
    };
  }
}
