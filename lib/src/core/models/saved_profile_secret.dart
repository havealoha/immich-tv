class SavedProfileSecret {
  const SavedProfileSecret({required this.password, required this.pin});

  final String password;
  final String pin;

  Map<String, dynamic> toJson() {
    return {'password': password, 'pin': pin};
  }

  factory SavedProfileSecret.fromJson(Map<String, dynamic> json) {
    return SavedProfileSecret(
      password: json['password'] as String,
      pin: json['pin'] as String,
    );
  }
}
