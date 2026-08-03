import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show visibleForTesting;
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

  /// Keys whose values must never reach a log line: the FCM token, which is a
  /// send capability, and subscriber PII.
  ///
  /// Both casings are listed because the SDK sends camelCase but the server may
  /// echo snake_case back.
  static const Set<String> _sensitiveKeys = {
    'fcmToken',
    'fcm_token',
    'name',
    'email',
    'phone',
    'metadata',
    // Tag values routinely hold an email, plan or region.
    'value',
  };

  static const String _redacted = '<redacted>';

  /// Copy [body] with every credential and PII value replaced.
  ///
  /// The shape survives — which keys were sent, and a masked token that can
  /// still be correlated with the server — so the log stays useful for
  /// debugging without carrying the values themselves into device logs, which
  /// other tooling and crash collectors read.
  static Map<String, dynamic> redact(Map<String, dynamic> body) {
    final result = <String, dynamic>{};
    body.forEach((key, value) {
      result[key] = _sensitiveKeys.contains(key)
          ? _maskSensitive(key, value)
          : _redactNested(value);
    });
    return result;
  }

  static Object? _maskSensitive(String key, Object? value) {
    if (value == null) return null;
    if (value is String && (key == 'fcmToken' || key == 'fcm_token')) {
      return maskToken(value);
    }
    return _redacted;
  }

  static Object? _redactNested(Object? value) {
    if (value is Map) {
      return redact(value.map((k, v) => MapEntry(k.toString(), v)));
    }
    if (value is List) {
      return value.map(_redactNested).toList();
    }
    return value;
  }

  /// Mask a token, keeping enough of each end to correlate it with the server.
  @visibleForTesting
  static String maskToken(String token) {
    return token.length > 20
        ? '${token.substring(0, 10)}...${token.substring(token.length - 10)}'
        : token;
  }

  /// Redact a raw JSON response body.
  ///
  /// Anything that is not a JSON object — an HTML gateway page, a plain string
  /// — is returned unchanged: it carries no field the SDK sent.
  @visibleForTesting
  static String redactBody(String body) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        return json.encode(redact(decoded));
      }
    } catch (_) {
      // Not JSON; fall through.
    }
    return body;
  }

  /// Log API request
  static void logApiRequest(
      String method, String url, Map<String, dynamic>? body) {
    if (_enableLogging) {
      final message = 'API Request: $method $url';
      if (body != null) {
        debug('$message\nBody: ${redact(body)}');
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
        // Responses echo back what was sent: register-device returns the device
        // row, login-subscriber the subscriber row.
        debug('$message\nResponse: ${redactBody(body)}');
      } else {
        debug(message);
      }
    }
  }

  /// Build the API error log line. Extracted as a pure function for testing.
  @visibleForTesting
  static String formatApiError(
    String method,
    String endpoint,
    int statusCode,
    String? code,
    String message,
  ) {
    final buffer =
        StringBuffer('API error: $method $endpoint -> HTTP $statusCode');
    if (code != null) buffer.write(' code=$code');
    buffer.write(' msg="$message"');
    return buffer.toString();
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
      error(formatApiError(method, endpoint, statusCode, code, message));
    }
  }

  /// Log device information
  ///
  /// The map is a `Device.toJson()`, which carries the full FCM token.
  static void logDeviceInfo(Map<String, dynamic> deviceInfo) {
    if (_enableLogging) {
      info('Device Info: ${redact(deviceInfo)}');
    }
  }

  /// Log FCM token
  static void logFcmToken(String token) {
    if (_enableLogging) {
      info('FCM Token: ${maskToken(token)}');
    }
  }

  /// Check if logging is enabled
  static bool get isLoggingEnabled => _enableLogging;
}
