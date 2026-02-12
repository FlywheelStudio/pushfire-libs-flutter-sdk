import 'package:flutter_test/flutter_test.dart';
import 'package:pushfire_sdk/pushfire_sdk.dart';

void main() {
  group('PushFireApiException', () {
    test('creates with message only', () {
      const exception = PushFireApiException('API request failed');
      expect(exception.message, 'API request failed');
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
      expect(exception.statusCode, isNull);
      expect(exception.responseBody, isNull);
    });

    test('creates with all parameters', () {
      final originalErr = Exception('underlying');
      final exception = PushFireApiException(
        'Bad request',
        code: 'BAD_REQUEST',
        originalError: originalErr,
        statusCode: 400,
        responseBody: '{"error": "bad request"}',
      );
      expect(exception.message, 'Bad request');
      expect(exception.code, 'BAD_REQUEST');
      expect(exception.originalError, originalErr);
      expect(exception.statusCode, 400);
      expect(exception.responseBody, '{"error": "bad request"}');
    });

    test('is a PushFireException', () {
      const exception = PushFireApiException('test');
      expect(exception, isA<PushFireException>());
    });

    test('implements Exception', () {
      const exception = PushFireApiException('test');
      expect(exception, isA<Exception>());
    });

    group('toString', () {
      test('with message only', () {
        const exception = PushFireApiException('Something went wrong');
        expect(exception.toString(), 'PushFireApiException: Something went wrong');
      });

      test('with code only', () {
        const exception = PushFireApiException(
          'Forbidden',
          code: 'FORBIDDEN',
        );
        expect(
          exception.toString(),
          'PushFireApiException(FORBIDDEN): Forbidden',
        );
      });

      test('with statusCode only', () {
        const exception = PushFireApiException(
          'Not Found',
          statusCode: 404,
        );
        expect(
          exception.toString(),
          'PushFireApiException [HTTP 404]: Not Found',
        );
      });

      test('with both code and statusCode', () {
        const exception = PushFireApiException(
          'Unauthorized',
          code: 'AUTH_ERROR',
          statusCode: 401,
        );
        expect(
          exception.toString(),
          'PushFireApiException(AUTH_ERROR) [HTTP 401]: Unauthorized',
        );
      });

      test('with all parameters', () {
        const exception = PushFireApiException(
          'Server error',
          code: 'INTERNAL',
          statusCode: 500,
          responseBody: 'error body',
        );
        // responseBody is not included in toString
        expect(
          exception.toString(),
          'PushFireApiException(INTERNAL) [HTTP 500]: Server error',
        );
      });
    });
  });

  group('PushFireNotInitializedException', () {
    test('creates with no parameters', () {
      const exception = PushFireNotInitializedException();
      expect(
        exception.message,
        'PushFire SDK is not initialized. Call PushFireSDK.initialize() first.',
      );
    });

    test('has null code', () {
      const exception = PushFireNotInitializedException();
      expect(exception.code, isNull);
    });

    test('has null originalError', () {
      const exception = PushFireNotInitializedException();
      expect(exception.originalError, isNull);
    });

    test('is a PushFireException', () {
      const exception = PushFireNotInitializedException();
      expect(exception, isA<PushFireException>());
    });

    test('implements Exception', () {
      const exception = PushFireNotInitializedException();
      expect(exception, isA<Exception>());
    });

    test('toString without code outputs base format', () {
      const exception = PushFireNotInitializedException();
      expect(
        exception.toString(),
        'PushFireException: '
        'PushFire SDK is not initialized. Call PushFireSDK.initialize() first.',
      );
    });
  });

  group('PushFireConfigurationException', () {
    test('creates with message only', () {
      const exception = PushFireConfigurationException('Invalid config');
      expect(exception.message, 'Invalid config');
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
    });

    test('creates with all parameters', () {
      final originalErr = FormatException('bad format');
      final exception = PushFireConfigurationException(
        'Config error',
        code: 'INVALID_CONFIG',
        originalError: originalErr,
      );
      expect(exception.message, 'Config error');
      expect(exception.code, 'INVALID_CONFIG');
      expect(exception.originalError, originalErr);
    });

    test('is a PushFireException', () {
      const exception = PushFireConfigurationException('test');
      expect(exception, isA<PushFireException>());
    });

    test('implements Exception', () {
      const exception = PushFireConfigurationException('test');
      expect(exception, isA<Exception>());
    });

    test('toString without code', () {
      const exception = PushFireConfigurationException('Missing API key');
      expect(
        exception.toString(),
        'PushFireException: Missing API key',
      );
    });

    test('toString with code', () {
      const exception = PushFireConfigurationException(
        'Missing API key',
        code: 'MISSING_KEY',
      );
      expect(
        exception.toString(),
        'PushFireException(MISSING_KEY): Missing API key',
      );
    });
  });

  group('PushFireDeviceException', () {
    test('creates with message only', () {
      const exception = PushFireDeviceException('Device registration failed');
      expect(exception.message, 'Device registration failed');
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
    });

    test('creates with all parameters', () {
      final originalErr = StateError('no token');
      final exception = PushFireDeviceException(
        'FCM token error',
        code: 'FCM_ERROR',
        originalError: originalErr,
      );
      expect(exception.message, 'FCM token error');
      expect(exception.code, 'FCM_ERROR');
      expect(exception.originalError, originalErr);
    });

    test('is a PushFireException', () {
      const exception = PushFireDeviceException('test');
      expect(exception, isA<PushFireException>());
    });

    test('implements Exception', () {
      const exception = PushFireDeviceException('test');
      expect(exception, isA<Exception>());
    });

    test('toString without code', () {
      const exception = PushFireDeviceException('Device error');
      expect(exception.toString(), 'PushFireException: Device error');
    });

    test('toString with code', () {
      const exception = PushFireDeviceException(
        'Device error',
        code: 'DEV_ERR',
      );
      expect(
        exception.toString(),
        'PushFireException(DEV_ERR): Device error',
      );
    });
  });

  group('PushFireSubscriberException', () {
    test('creates with message only', () {
      const exception = PushFireSubscriberException('Subscriber not found');
      expect(exception.message, 'Subscriber not found');
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
    });

    test('creates with all parameters', () {
      final originalErr = ArgumentError('invalid id');
      final exception = PushFireSubscriberException(
        'Login failed',
        code: 'LOGIN_FAIL',
        originalError: originalErr,
      );
      expect(exception.message, 'Login failed');
      expect(exception.code, 'LOGIN_FAIL');
      expect(exception.originalError, originalErr);
    });

    test('is a PushFireException', () {
      const exception = PushFireSubscriberException('test');
      expect(exception, isA<PushFireException>());
    });

    test('implements Exception', () {
      const exception = PushFireSubscriberException('test');
      expect(exception, isA<Exception>());
    });

    test('toString without code', () {
      const exception = PushFireSubscriberException('Subscriber error');
      expect(exception.toString(), 'PushFireException: Subscriber error');
    });

    test('toString with code', () {
      const exception = PushFireSubscriberException(
        'Subscriber error',
        code: 'SUB_ERR',
      );
      expect(
        exception.toString(),
        'PushFireException(SUB_ERR): Subscriber error',
      );
    });
  });

  group('PushFireTagException', () {
    test('creates with message only', () {
      const exception = PushFireTagException('Tag not found');
      expect(exception.message, 'Tag not found');
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
    });

    test('creates with all parameters', () {
      final originalErr = UnsupportedError('unsupported');
      final exception = PushFireTagException(
        'Tag creation failed',
        code: 'TAG_CREATE',
        originalError: originalErr,
      );
      expect(exception.message, 'Tag creation failed');
      expect(exception.code, 'TAG_CREATE');
      expect(exception.originalError, originalErr);
    });

    test('is a PushFireException', () {
      const exception = PushFireTagException('test');
      expect(exception, isA<PushFireException>());
    });

    test('implements Exception', () {
      const exception = PushFireTagException('test');
      expect(exception, isA<Exception>());
    });

    test('toString without code', () {
      const exception = PushFireTagException('Tag error');
      expect(exception.toString(), 'PushFireException: Tag error');
    });

    test('toString with code', () {
      const exception = PushFireTagException(
        'Tag error',
        code: 'TAG_ERR',
      );
      expect(
        exception.toString(),
        'PushFireException(TAG_ERR): Tag error',
      );
    });
  });

  group('PushFireNetworkException', () {
    test('creates with message only', () {
      const exception = PushFireNetworkException('Connection timeout');
      expect(exception.message, 'Connection timeout');
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
    });

    test('creates with all parameters', () {
      final originalErr = Exception('socket closed');
      final exception = PushFireNetworkException(
        'No internet',
        code: 'NO_INTERNET',
        originalError: originalErr,
      );
      expect(exception.message, 'No internet');
      expect(exception.code, 'NO_INTERNET');
      expect(exception.originalError, originalErr);
    });

    test('is a PushFireException', () {
      const exception = PushFireNetworkException('test');
      expect(exception, isA<PushFireException>());
    });

    test('implements Exception', () {
      const exception = PushFireNetworkException('test');
      expect(exception, isA<Exception>());
    });

    test('toString without code', () {
      const exception = PushFireNetworkException('Network error');
      expect(exception.toString(), 'PushFireException: Network error');
    });

    test('toString with code', () {
      const exception = PushFireNetworkException(
        'Network error',
        code: 'NET_ERR',
      );
      expect(
        exception.toString(),
        'PushFireException(NET_ERR): Network error',
      );
    });
  });

  group('originalError storage', () {
    test('stores a String as originalError', () {
      const exception = PushFireConfigurationException(
        'error',
        originalError: 'string error',
      );
      expect(exception.originalError, 'string error');
      expect(exception.originalError, isA<String>());
    });

    test('stores an int as originalError', () {
      const exception = PushFireDeviceException(
        'error',
        originalError: 42,
      );
      expect(exception.originalError, 42);
    });

    test('stores an Exception as originalError', () {
      final inner = FormatException('bad');
      final exception = PushFireSubscriberException(
        'error',
        originalError: inner,
      );
      expect(exception.originalError, isA<FormatException>());
      expect(exception.originalError, same(inner));
    });

    test('stores an Error as originalError', () {
      final inner = StateError('bad state');
      final exception = PushFireTagException(
        'error',
        originalError: inner,
      );
      expect(exception.originalError, isA<StateError>());
      expect(exception.originalError, same(inner));
    });

    test('stores null originalError by default', () {
      const exception = PushFireNetworkException('error');
      expect(exception.originalError, isNull);
    });
  });

  group('inheritance hierarchy', () {
    test('PushFireApiException is a PushFireException', () {
      const e = PushFireApiException('test');
      expect(e, isA<PushFireException>());
    });

    test('PushFireNotInitializedException is a PushFireException', () {
      const e = PushFireNotInitializedException();
      expect(e, isA<PushFireException>());
    });

    test('PushFireConfigurationException is a PushFireException', () {
      const e = PushFireConfigurationException('test');
      expect(e, isA<PushFireException>());
    });

    test('PushFireDeviceException is a PushFireException', () {
      const e = PushFireDeviceException('test');
      expect(e, isA<PushFireException>());
    });

    test('PushFireSubscriberException is a PushFireException', () {
      const e = PushFireSubscriberException('test');
      expect(e, isA<PushFireException>());
    });

    test('PushFireTagException is a PushFireException', () {
      const e = PushFireTagException('test');
      expect(e, isA<PushFireException>());
    });

    test('PushFireNetworkException is a PushFireException', () {
      const e = PushFireNetworkException('test');
      expect(e, isA<PushFireException>());
    });

    test('all exception types implement Exception interface', () {
      final exceptions = <PushFireException>[
        const PushFireApiException('a'),
        const PushFireNotInitializedException(),
        const PushFireConfigurationException('c'),
        const PushFireDeviceException('d'),
        const PushFireSubscriberException('e'),
        const PushFireTagException('f'),
        const PushFireNetworkException('g'),
      ];
      for (final e in exceptions) {
        expect(e, isA<Exception>(),
            reason: '${e.runtimeType} should implement Exception');
      }
    });
  });

  group('edge cases', () {
    test('empty message is allowed', () {
      const exception = PushFireConfigurationException('');
      expect(exception.message, '');
      expect(exception.toString(), 'PushFireException: ');
    });

    test('empty code is treated as non-null', () {
      const exception = PushFireDeviceException('msg', code: '');
      expect(exception.code, '');
      expect(exception.toString(), 'PushFireException(): msg');
    });

    test('PushFireApiException with statusCode 0', () {
      const exception = PushFireApiException('msg', statusCode: 0);
      expect(exception.toString(), 'PushFireApiException [HTTP 0]: msg');
    });

    test('PushFireApiException with empty responseBody', () {
      const exception = PushFireApiException(
        'msg',
        responseBody: '',
      );
      expect(exception.responseBody, '');
    });
  });
}
