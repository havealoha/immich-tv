import '../models/server_validation_result.dart';

abstract class ServerRepository {
  Future<ServerValidationResult> validateServer(String rawInput);
}
