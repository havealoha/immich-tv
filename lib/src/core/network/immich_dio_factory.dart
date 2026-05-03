import 'package:dio/dio.dart';

import '../logging/app_logger.dart';

class ImmichDioFactory {
  const ImmichDioFactory._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        sendTimeout: const Duration(seconds: 8),
      ),
    );

    dio.interceptors.add(dioLogger);
    return dio;
  }
}
