import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pushfire_sdk/src/api/pushfire_api_client.dart';
import 'package:pushfire_sdk/src/config/pushfire_config.dart';
import 'package:pushfire_sdk/src/exceptions/pushfire_exceptions.dart';

void main() {
  const config = PushFireConfig(
    apiKey: 'test-key',
    baseUrl: 'https://api.pushfire.app/functions/v1/',
  );

  group('PushFireApiClient success responses', () {
    test('2xx with JSON body returns decoded map', () async {
      final mock =
          MockClient((req) async => http.Response('{"id":"sub_1"}', 200));
      final client = PushFireApiClient(config, httpClient: mock);
      final result = await client.post('login-subscriber', {'data': {}});
      expect(result['id'], 'sub_1');
    });

    test('2xx with empty body returns success map', () async {
      final mock = MockClient((req) async => http.Response('', 200));
      final client = PushFireApiClient(config, httpClient: mock);
      final result = await client.post('logout-subscriber', {'data': {}});
      expect(result['success'], true);
    });
  });

  group('PushFireApiClient error responses', () {
    test('4xx with JSON error preserves status, code, message, body', () async {
      final mock = MockClient((req) async => http.Response(
            '{"message":"Missing authorization header","code":"missing_auth"}',
            401,
          ));
      final client = PushFireApiClient(config, httpClient: mock);

      await expectLater(
        client.patch('update-subscriber', {'data': {}}),
        throwsA(isA<PushFireApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)
            .having((e) => e.code, 'code', 'missing_auth')
            .having((e) => e.message, 'message', 'Missing authorization header')
            .having((e) => e.responseBody, 'responseBody',
                contains('Missing authorization header'))),
      );
    });

    test('error is NOT re-wrapped as "Unexpected error"', () async {
      final mock =
          MockClient((req) async => http.Response('{"message":"Nope"}', 403));
      final client = PushFireApiClient(config, httpClient: mock);

      await expectLater(
        client.post('x', {}),
        throwsA(isA<PushFireApiException>()
            .having((e) => e.message, 'message', 'Nope')
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('5xx sets the status code', () async {
      final mock =
          MockClient((req) async => http.Response('{"message":"boom"}', 500));
      final client = PushFireApiClient(config, httpClient: mock);
      await expectLater(
        client.post('x', {}),
        throwsA(isA<PushFireApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', 'boom')
            .having((e) => e.code, 'code', isNull)),
      );
    });

    test('non-JSON error body is surfaced raw', () async {
      final mock = MockClient(
          (req) async => http.Response('<html>502 Bad Gateway</html>', 502));
      final client = PushFireApiClient(config, httpClient: mock);
      await expectLater(
        client.post('x', {}),
        throwsA(isA<PushFireApiException>()
            .having((e) => e.statusCode, 'statusCode', 502)
            .having((e) => e.message, 'message', '<html>502 Bad Gateway</html>')
            .having((e) => e.responseBody, 'responseBody',
                contains('<html>502 Bad Gateway</html>'))),
      );
    });

    test('nested errors[] array surfaces the validation message', () async {
      final mock = MockClient((req) async => http.Response(
            '{"errors":[{"path":"data.phone","message":"Phone is required"}]}',
            400,
          ));
      final client = PushFireApiClient(config, httpClient: mock);
      await expectLater(
        client.patch('update-subscriber', {'data': {}}),
        throwsA(isA<PushFireApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'Phone is required')),
      );
    });

    test('multiple errors[] messages are joined', () async {
      final mock = MockClient((req) async => http.Response(
            '{"errors":[{"message":"Phone is required"},'
            '{"message":"Email is invalid"}]}',
            400,
          ));
      final client = PushFireApiClient(config, httpClient: mock);
      await expectLater(
        client.post('x', {}),
        throwsA(isA<PushFireApiException>().having((e) => e.message, 'message',
            'Phone is required; Email is invalid')),
      );
    });

    test('unknown JSON shape falls back to the whole body', () async {
      final mock = MockClient((req) async => http.Response(
            '{"unexpected":"shape","detail":42}',
            422,
          ));
      final client = PushFireApiClient(config, httpClient: mock);
      await expectLater(
        client.post('x', {}),
        throwsA(isA<PushFireApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having((e) => e.message, 'message',
                '{"unexpected":"shape","detail":42}')),
      );
    });

    test('empty error body falls back to a status message', () async {
      final mock = MockClient((req) async => http.Response('', 500));
      final client = PushFireApiClient(config, httpClient: mock);
      await expectLater(
        client.post('x', {}),
        throwsA(isA<PushFireApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message',
                'API request failed with status 500')),
      );
    });
  });

  group('PushFireApiClient transport errors', () {
    test('SocketException becomes PushFireNetworkException', () async {
      final mock =
          MockClient((req) async => throw const SocketException('no route'));
      final client = PushFireApiClient(config, httpClient: mock);
      await expectLater(
        client.post('x', {}),
        throwsA(isA<PushFireNetworkException>()
            .having((e) => e.message, 'message', contains('Network error'))),
      );
    });

    test('TimeoutException becomes PushFireNetworkException', () async {
      final mock = MockClient((req) async => throw TimeoutException('slow'));
      final client = PushFireApiClient(config, httpClient: mock);
      await expectLater(
        client.post('x', {}),
        throwsA(isA<PushFireNetworkException>()
            .having((e) => e.message, 'message', contains('timed out'))
            .having((e) => e.originalError, 'originalError',
                isA<TimeoutException>())),
      );
    });

    test('timeout message includes the configured seconds', () async {
      final mock = MockClient((req) async => throw TimeoutException('slow'));
      final client = PushFireApiClient(
        const PushFireConfig(
            apiKey: 'k',
            baseUrl: 'https://api.pushfire.app/functions/v1/',
            timeoutSeconds: 15),
        httpClient: mock,
      );
      await expectLater(
        client.post('x', {}),
        throwsA(isA<PushFireNetworkException>()
            .having((e) => e.message, 'message', contains('15s'))),
      );
    });
  });
}
