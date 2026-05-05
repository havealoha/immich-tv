import 'package:equatable/equatable.dart';

import 'server_config.dart';

class SavedProfile extends Equatable {
  const SavedProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.serverConfig,
    required this.lastUsedAt,
  });

  final String id;
  final String name;
  final String email;
  final ServerConfig serverConfig;
  final DateTime lastUsedAt;

  String get initials {
    final source = name.trim().isEmpty ? email : name;
    final letters = source
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .take(2)
        .map((segment) => segment.substring(0, 1).toUpperCase())
        .join();
    return letters.isEmpty ? 'U' : letters;
  }

  SavedProfile copyWith({
    String? id,
    String? name,
    String? email,
    ServerConfig? serverConfig,
    DateTime? lastUsedAt,
  }) {
    return SavedProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      serverConfig: serverConfig ?? this.serverConfig,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'serverConfig': serverConfig.toJson(),
      'lastUsedAt': lastUsedAt.toIso8601String(),
    };
  }

  factory SavedProfile.fromJson(Map<String, dynamic> json) {
    return SavedProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      serverConfig: ServerConfig.fromJson(
        json['serverConfig'] as Map<String, dynamic>,
      ),
      lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, name, email, serverConfig, lastUsedAt];
}
