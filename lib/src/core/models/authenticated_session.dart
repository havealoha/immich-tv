import 'package:equatable/equatable.dart';

import 'immich_auth_method.dart';
import 'server_config.dart';
import 'user_profile.dart';

class AuthenticatedSession extends Equatable {
  const AuthenticatedSession({
    required this.serverConfig,
    required this.accessToken,
    required this.user,
    this.authMethod = ImmichAuthMethod.password,
  });

  final ServerConfig serverConfig;
  final String accessToken;
  final UserProfile user;
  final ImmichAuthMethod authMethod;

  Map<String, dynamic> toJson() {
    return {
      'serverConfig': serverConfig.toJson(),
      'accessToken': accessToken,
      'user': user.toJson(),
      'authMethod': authMethod.storageValue,
    };
  }

  factory AuthenticatedSession.fromJson(Map<String, dynamic> json) {
    return AuthenticatedSession(
      serverConfig: ServerConfig.fromJson(
        json['serverConfig'] as Map<String, dynamic>,
      ),
      accessToken: json['accessToken'] as String,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      authMethod: ImmichAuthMethod.fromStorageValue(
        json['authMethod'] as String?,
      ),
    );
  }

  @override
  List<Object?> get props => [serverConfig, accessToken, user, authMethod];
}
