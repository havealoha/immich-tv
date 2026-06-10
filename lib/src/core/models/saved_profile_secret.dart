class SavedProfileSecret {
  const SavedProfileSecret({this.password, this.apiKey, required this.pin});

  final String? password;
  final String? apiKey;
  final String pin;

  Map<String, dynamic> toJson() {
    return {'password': password, 'apiKey': apiKey, 'pin': pin};
  }

  factory SavedProfileSecret.fromJson(Map<String, dynamic> json) {
    return SavedProfileSecret(
      password: json['password'] as String?,
      apiKey: json['apiKey'] as String?,
      pin: json['pin'] as String,
    );
  }
}
