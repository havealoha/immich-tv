import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

import '../logging/app_logger.dart';

typedef BadCertificateCallback = bool Function(X509Certificate cert, String host, int port);

class ImmichDioFactory {
  const ImmichDioFactory._();

  static Dio create({BadCertificateCallback? badCertificateCallback}) {
    const connectTimeout = Duration(seconds: 12);
    const receiveTimeout = Duration(seconds: 12);

    final dio = Dio(
      BaseOptions(
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: kIsWeb ? null : connectTimeout,
      ),
    );

    if (!kIsWeb) {
      (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        if (badCertificateCallback != null) {
          client.badCertificateCallback = badCertificateCallback;
        }
        return client;
      };
    }

    if (kDebugMode) {
      dio.interceptors.add(dioLogger);
    }

    return dio;
  }
}
