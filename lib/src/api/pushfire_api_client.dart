import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/pushfire_config.dart';
import '../exceptions/pushfire_exceptions.dart';
import '../utils/logger.dart';

/// HTTP client for PushFire API
class PushFireApiClient {
  final PushFireConfig _config;
  late final http.Client _httpClient;

  PushFireApiClient(this._config, {http.Client? httpClient}) {
    _httpClient = httpClient ?? http.Client();
  }

  /// Get common headers for API requests
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ${_config.apiKey}',
      };

  /// Make a POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return _makeRequest('POST', endpoint, data);
  }

  /// Make a PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return _makeRequest('PATCH', endpoint, data);
  }

  /// Make a DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    return _makeRequest('DELETE', endpoint, data);
  }

  /// Make an HTTP request
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final url = Uri.parse('${_config.baseUrl}$endpoint');
    final body = json.encode(data);

    PushFireLogger.logApiRequest(method, url.toString(), data);

    try {
      late http.Response response;

      switch (method) {
        case 'POST':
          response = await _httpClient
              .post(url, headers: _headers, body: body)
              .timeout(Duration(seconds: _config.timeoutSeconds));
          break;
        case 'PATCH':
          response = await _httpClient
              .patch(url, headers: _headers, body: body)
              .timeout(Duration(seconds: _config.timeoutSeconds));
          break;
        case 'DELETE':
          response = await _httpClient
              .delete(url, headers: _headers, body: body)
              .timeout(Duration(seconds: _config.timeoutSeconds));
          break;
        default:
          throw PushFireApiException('Unsupported HTTP method: $method');
      }

      PushFireLogger.logApiResponse(
        method,
        url.toString(),
        response.statusCode,
        response.body,
      );

      return _handleResponse(method, endpoint, response);
    } on PushFireException {
      rethrow;
    } on TimeoutException catch (e) {
      final message =
          'Request to $method $endpoint timed out after ${_config.timeoutSeconds}s';
      PushFireLogger.error(message, e);
      throw PushFireNetworkException(message, originalError: e);
    } on SocketException catch (e) {
      PushFireLogger.error(
          'Network error during $method $endpoint: ${e.message}', e);
      throw PushFireNetworkException(
        'Network error: ${e.message}',
        originalError: e,
      );
    } on HttpException catch (e) {
      PushFireLogger.error(
          'HTTP error during $method $endpoint: ${e.message}', e);
      throw PushFireNetworkException(
        'HTTP error: ${e.message}',
        originalError: e,
      );
    } catch (e) {
      PushFireLogger.error('Unexpected error during $method $endpoint', e);
      throw PushFireApiException(
        'Unexpected error: $e',
        originalError: e,
      );
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(
    String method,
    String endpoint,
    http.Response response,
  ) {
    final statusCode = response.statusCode;
    final body = response.body;

    // Success status codes
    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) {
        return {'success': true};
      }

      try {
        final decoded = json.decode(body) as Map<String, dynamic>;
        return decoded;
      } catch (e) {
        PushFireLogger.warning('Failed to decode response body: $body', e);
        return {'success': true, 'raw_response': body};
      }
    }

    // Error status codes
    String errorMessage;
    String? errorCode;

    try {
      final decoded = json.decode(body);
      if (decoded is Map<String, dynamic>) {
        // Try the known shapes, then fall back to the whole body so the caller
        // always sees the server's actual response, not a generic string.
        errorMessage = decoded['message'] as String? ??
            decoded['error'] as String? ??
            _extractErrorsList(decoded['errors']) ??
            body.trim();
        errorCode = decoded['code'] as String?;
      } else {
        // Valid JSON but not an object (array, string, number) — show it raw.
        errorMessage = body.trim();
      }
    } catch (_) {
      // Body is not JSON (e.g. an HTML gateway page) — show it raw.
      errorMessage = body.trim();
    }

    // Last resort when the response body is empty/blank.
    if (errorMessage.isEmpty) {
      errorMessage = 'API request failed with status $statusCode';
    }

    PushFireLogger.logApiError(
        method, endpoint, statusCode, errorCode, errorMessage);

    throw PushFireApiException(
      errorMessage,
      code: errorCode,
      statusCode: statusCode,
      responseBody: body,
    );
  }

  /// Extract and join messages from a validation-style `errors` array, e.g.
  /// `{"errors":[{"path":"data.phone","message":"Phone is required"}]}`.
  /// Returns null when [errors] is not a non-empty list carrying messages.
  static String? _extractErrorsList(dynamic errors) {
    if (errors is! List || errors.isEmpty) return null;
    final messages = errors
        .whereType<Map>()
        .map((e) => e['message'])
        .whereType<String>()
        .where((m) => m.isNotEmpty)
        .toList();
    return messages.isEmpty ? null : messages.join('; ');
  }

  /// Dispose the HTTP client
  void dispose() {
    _httpClient.close();
  }
}
