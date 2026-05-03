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

  Uri serverEndpoint(String path) => _appendPath(serverUrl, path);

  Uri apiEndpoint(String path) => _appendPath(apiUrl, path);

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

  Uri _appendPath(Uri base, String path) {
    final baseSegments = base.pathSegments.where(
      (segment) => segment.isNotEmpty,
    );
    final nextSegments = path.split('/').where((segment) => segment.isNotEmpty);

    return base.replace(
      pathSegments: [...baseSegments, ...nextSegments],
      query: null,
      fragment: null,
    );
  }

  @override
  List<Object?> get props => [rawInput, serverUrl, apiUrl];
}
