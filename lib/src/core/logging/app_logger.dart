import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// A singleton class for structured logging with file, method, and line tracking.
class AppLogger {
  AppLogger._internal();

  static final AppLogger instance = AppLogger._internal();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 90,
      colors: false,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.none,
      noBoxingByDefault: false,
    ),
  );

  void debug(dynamic message) {
    if (kDebugMode) {
      _logger.d(_formatMessage(message.toString()));
    }
  }

  void info(dynamic message) {
    _logger.i(_formatMessage(message.toString()));
  }

  void warning(dynamic message) {
    final formattedMessage = _formatMessage(message.toString());
    _logger.w(formattedMessage);
  }

  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final formattedMessage = _formatMessage(message.toString());
    _logger.e(formattedMessage, error: error, stackTrace: stackTrace);
  }

  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    final formattedMessage = _formatMessage(message.toString());
    _logger.f(formattedMessage, error: error, stackTrace: stackTrace);
  }

  String _formatMessage(String message) {
    final logDetails = _getLogOrigin();
    return '${DateTime.now()} | ${_getDebugMethodName().toUpperCase()} | '
        '${logDetails["file"]}:${logDetails["line"]} | ${logDetails["method"]} \n'
        '${_sanitizeMessage(message)}';
  }

  Map<String, String> _getLogOrigin() {
    try {
      final stackTrace = StackTrace.current.toString().split('\n')[3];
      final regex = RegExp(r'^(.*) \((.*):(\d+):\d+\)$');
      final match = regex.firstMatch(stackTrace);
      if (match != null) {
        return {
          'method':
              match
                  .group(1)
                  ?.substring(
                    match.group(1)?.lastIndexOf(' ') ?? 0,
                    match.group(1)?.length ?? 0,
                  )
                  .trim() ??
              'UnknownMethod',
          'file': match.group(2)?.split('/').last ?? 'UnknownFile',
          'line': match.group(3) ?? '0',
        };
      }
    } catch (_) {
      return {'method': 'Unknown', 'file': 'Unknown', 'line': '0'};
    }
    return {'method': 'Unknown', 'file': 'Unknown', 'line': '0'};
  }

  String _getDebugMethodName() {
    try {
      final stackTrace = StackTrace.current.toString().split('\n')[2];
      final regex = RegExp(r'#\d+\s+(\S+)\s');
      final match = regex.firstMatch(stackTrace);
      if (match != null) {
        return match.group(1) ?? 'UnknownMethod';
      }
    } catch (_) {
      return 'UnknownMethod';
    }
    return 'UnknownMethod';
  }

  String _sanitizeMessage(String message) {
    return message.replaceAll(
      RegExp(r'(password|token|apikey|secret|key):\s*\S+'),
      '****',
    );
  }
}

final logger = AppLogger.instance;

final dioLogger = PrettyDioLogger(
  requestHeader: true,
  requestBody: true,
  responseBody: true,
  responseHeader: true,
  compact: true,
);
