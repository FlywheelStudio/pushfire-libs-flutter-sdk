import 'dart:developer' as developer;
import 'package:logging/logging.dart';

/// Centralized logging utility for PushFire SDK
class PushFireLogger {
  static final Logger _logger = Logger('PushFireSDK');
  static bool _isInitialized = false;
  static bool _enableLogging = false;

  /// Initialize the logger
  static void initialize({bool enableLogging = false}) {
    if (_isInitialized) return;

    _enableLogging = enableLogging;

    if (enableLogging) {
      Logger.root.level = Level.ALL;
      Logger.root.onRecord.listen((record) {
        developer.log(
          record.message,
          time: record.time,
          level: record.level.value,
          name: record.loggerName,
          error: record.error,
          stackTrace: record.stackTrace,
        );
      });
    }

    _isInitialized = true;
  }

  /// Log debug message
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (_enableLogging) {
      _logger.fine(message, error, stackTrace);
    }
  }

  /// Log info message
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (_enableLogging) {
      _logger.info(message, error, stackTrace);
    }
  }

  /// Log warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (_enableLogging) {
      _logger.warning(message, error, stackTrace);
    }
  }

  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (_enableLogging) {
      _logger.severe(message, error, stackTrace);
    }
  }

  /// Log API request
  static void logApiRequest(
      String method, String url, Map<String, dynamic>? body) {
    if (_enableLogging) {
      final message = 'API Request: $method $url';
      if (body != null) {
        debug('$message\nBody: $body');
      } else {
        debug(message);
      }
    }
  }

  /// Log API response
  static void logApiResponse(
      String method, String url, int statusCode, String? body) {
    if (_enableLogging) {
      final message = 'API Response: $method $url - Status: $statusCode';
      if (body != null && body.isNotEmpty) {
        debug('$message\nResponse: $body');
      } else {
        debug(message);
      }
    }
  }

  /// Log an API error response as a single, clear error line
  static void logApiError(
    String method,
    String endpoint,
    int statusCode,
    String? code,
    String message,
  ) {
    if (_enableLogging) {
      final buffer =
          StringBuffer('API error: $method $endpoint -> HTTP $statusCode');
      if (code != null) buffer.write(' code=$code');
      buffer.write(' msg="$message"');
      error(buffer.toString());
    }
  }

  /// Log device information
  static void logDeviceInfo(Map<String, dynamic> deviceInfo) {
    if (_enableLogging) {
      info('Device Info: $deviceInfo');
    }
  }

  /// Log FCM token
  static void logFcmToken(String token) {
    if (_enableLogging) {
      // Only log first and last 10 characters for security
      final maskedToken = token.length > 20
          ? '${token.substring(0, 10)}...${token.substring(token.length - 10)}'
          : token;
      info('FCM Token: $maskedToken');
    }
  }

  /// Check if logging is enabled
  static bool get isLoggingEnabled => _enableLogging;
}
