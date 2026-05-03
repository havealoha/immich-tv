import 'package:equatable/equatable.dart';

import 'server_config.dart';

class ServerValidationResult extends Equatable {
  const ServerValidationResult({
    required this.serverConfig,
    required this.pingPath,
  });

  final ServerConfig serverConfig;
  final String pingPath;

  @override
  List<Object?> get props => [serverConfig, pingPath];
}
