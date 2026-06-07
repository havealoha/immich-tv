import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../logging/app_logger.dart';

class ImmichDioFactory {
  const ImmichDioFactory._();

  static Dio create() {
    const connectTimeout = Duration(seconds: 12);
    const receiveTimeout = Duration(seconds: 12);

    final dio = Dio(
      BaseOptions(
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        // Dio's web adapter logs noisy warnings for GET requests when a
        // non-zero send timeout is configured globally.
        sendTimeout: kIsWeb ? null : connectTimeout,
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(dioLogger);
    }

    return dio;
  }
}
