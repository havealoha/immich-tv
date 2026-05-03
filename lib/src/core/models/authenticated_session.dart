import 'package:equatable/equatable.dart';

import 'server_config.dart';
import 'user_profile.dart';

class AuthenticatedSession extends Equatable {
  const AuthenticatedSession({
    required this.serverConfig,
    required this.accessToken,
    required this.user,
  });

  final ServerConfig serverConfig;
  final String accessToken;
  final UserProfile user;

  Map<String, dynamic> toJson() {
    return {
      'serverConfig': serverConfig.toJson(),
      'accessToken': accessToken,
      'user': user.toJson(),
    };
  }

  factory AuthenticatedSession.fromJson(Map<String, dynamic> json) {
    return AuthenticatedSession(
      serverConfig: ServerConfig.fromJson(
        json['serverConfig'] as Map<String, dynamic>,
      ),
      accessToken: json['accessToken'] as String,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  @override
  List<Object?> get props => [serverConfig, accessToken, user];
}
