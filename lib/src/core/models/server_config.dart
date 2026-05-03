import 'package:equatable/equatable.dart';

class ServerConfig extends Equatable {
  const ServerConfig({
    required this.rawInput,
    required this.serverUrl,
    required this.apiUrl,
  });

  final String rawInput;
  final Uri serverUrl;
  final Uri apiUrl;

  ServerConfig copyWith({String? rawInput, Uri? serverUrl, Uri? apiUrl}) {
    return ServerConfig(
      rawInput: rawInput ?? this.rawInput,
      serverUrl: serverUrl ?? this.serverUrl,
      apiUrl: apiUrl ?? this.apiUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rawInput': rawInput,
      'serverUrl': serverUrl.toString(),
      'apiUrl': apiUrl.toString(),
    };
  }

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      rawInput: json['rawInput'] as String,
      serverUrl: Uri.parse(json['serverUrl'] as String),
      apiUrl: Uri.parse(json['apiUrl'] as String),
    );
  }

  @override
  List<Object?> get props => [rawInput, serverUrl, apiUrl];
}
