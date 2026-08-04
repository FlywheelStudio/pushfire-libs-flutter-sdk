import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:pushfire_sdk/src/models/device.dart';
import 'package:pushfire_sdk/src/utils/logger.dart';

/// A realistic FCM token: long, high-entropy, and a send capability on its own.
const _fcmToken = 'fMEGD8pQR0-abcdefghijklmnopqrstuvwxyz0123456789:APA91bHqXwPl'
    'ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ_final_ten';

void main() {
  group('PushFireLogger.maskToken', () {
    test('keeps only the first and last ten characters', () {
      expect(
        PushFireLogger.maskToken(_fcmToken),
        '${_fcmToken.substring(0, 10)}...'
        '${_fcmToken.substring(_fcmToken.length - 10)}',
      );
    });

    test('leaves the middle out entirely', () {
      final masked = PushFireLogger.maskToken(_fcmToken);
      expect(masked.contains('APA91bHqXwPl'), isFalse);
      expect(masked.length, lessThan(_fcmToken.length));
    });
  });

  group('PushFireLogger.redact', () {
    test('masks the FCM token in a device payload', () {
      const device = Device(
        id: 'dev-1',
        fcmToken: _fcmToken,
        os: 'ios',
        osVersion: '17.0',
        language: 'en',
        manufacturer: 'Apple',
        model: 'iPhone',
        appVersion: '1.0.0',
        pushNotificationEnabled: true,
      );

      final redacted = PushFireLogger.redact(device.toJson());

      expect(redacted['fcmToken'], PushFireLogger.maskToken(_fcmToken));
      expect('$redacted'.contains(_fcmToken), isFalse);
      // Everything a device log is actually read for survives.
      expect(redacted['id'], 'dev-1');
      expect(redacted['os'], 'ios');
      expect(redacted['pushNotificationEnabled'], true);
    });

    test('redacts subscriber PII but keeps externalId and the shape', () {
      final body = {
        'data': {
          'deviceId': 'dev-1',
          'externalId': 'user-42',
          'name': 'Ada Lovelace',
          'email': 'ada@example.com',
          'phone': '+15551234567',
          'metadata': {'plan': 'premium', 'ssn': '000-00-0000'},
        },
      };

      final redacted = PushFireLogger.redact(body);
      final data = redacted['data'] as Map<String, dynamic>;

      expect(data['name'], '<redacted>');
      expect(data['email'], '<redacted>');
      expect(data['phone'], '<redacted>');
      // The whole metadata map goes, not just its known keys — the SDK does not
      // control what an integrator puts in there.
      expect(data['metadata'], '<redacted>');

      // Identifiers stay: they are what a support ticket is traced by.
      expect(data['externalId'], 'user-42');
      expect(data['deviceId'], 'dev-1');

      final rendered = '$redacted';
      for (final secret in [
        'Ada Lovelace',
        'ada@example.com',
        '+15551234567',
        'premium',
        '000-00-0000',
      ]) {
        expect(rendered.contains(secret), isFalse, reason: 'leaked $secret');
      }
    });

    test('redacts a tag value', () {
      final redacted = PushFireLogger.redact({
        'data': {
          'tagId': 'user_email',
          'subscriberId': 'sub-1',
          'value': 'ada@example.com',
        },
      });

      final data = redacted['data'] as Map<String, dynamic>;
      expect(data['value'], '<redacted>');
      expect(data['tagId'], 'user_email');
    });

    test('leaves a null value null rather than claiming it was redacted', () {
      final redacted = PushFireLogger.redact({'email': null, 'os': 'ios'});
      expect(redacted['email'], isNull);
    });

    test('does not mutate the caller\'s map', () {
      final body = {'fcmToken': _fcmToken};
      PushFireLogger.redact(body);
      expect(body['fcmToken'], _fcmToken);
    });

    test('reaches into lists of maps', () {
      final redacted = PushFireLogger.redact({
        'subscribers': [
          {'externalId': 'a', 'email': 'a@example.com'},
          {'externalId': 'b', 'email': 'b@example.com'},
        ],
      });

      final list = redacted['subscribers'] as List;
      expect((list[0] as Map)['email'], '<redacted>');
      expect((list[1] as Map)['email'], '<redacted>');
      expect((list[0] as Map)['externalId'], 'a');
    });
  });

  group('PushFireLogger.redactBody', () {
    test('redacts a JSON response that echoes the device row', () {
      final redacted = PushFireLogger.redactBody(
        '{"id":"dev-1","fcm_token":"$_fcmToken","os":"ios"}',
      );

      expect(redacted.contains(_fcmToken), isFalse);
      expect(redacted.contains('dev-1'), isTrue);
    });

    test('redacts snake_case PII the server sends back', () {
      final redacted = PushFireLogger.redactBody(
        '{"id":"sub-1","email":"ada@example.com","name":"Ada"}',
      );

      expect(redacted.contains('ada@example.com'), isFalse);
      expect(redacted.contains('sub-1'), isTrue);
    });

    test('passes through a body that is not a JSON object', () {
      // An HTML gateway page carries nothing the SDK sent, and mangling it
      // would cost the only clue about what the proxy returned.
      const html = '<html><body>502 Bad Gateway</body></html>';
      expect(PushFireLogger.redactBody(html), html);
    });
  });

  group('emitted log records', () {
    late List<String> records;

    setUp(() {
      PushFireLogger.initialize(enableLogging: true);
      records = [];
      Logger.root.onRecord.listen((r) => records.add(r.message));
    });

    test('logDeviceInfo never writes the token', () async {
      const device = Device(
        fcmToken: _fcmToken,
        os: 'ios',
        osVersion: '17.0',
        language: 'en',
        manufacturer: 'Apple',
        model: 'iPhone',
        appVersion: '1.0.0',
        pushNotificationEnabled: true,
      );

      PushFireLogger.logDeviceInfo(device.toJson());
      await Future<void>.delayed(Duration.zero);

      expect(records, isNotEmpty);
      expect(records.join('\n').contains(_fcmToken), isFalse);
    });

    test('logApiRequest never writes PII from the body', () async {
      PushFireLogger.logApiRequest('POST', 'http://test/login-subscriber', {
        'data': {
          'externalId': 'user-42',
          'email': 'ada@example.com',
          'phone': '+15551234567',
        },
      });
      await Future<void>.delayed(Duration.zero);

      final logged = records.join('\n');
      expect(logged.contains('ada@example.com'), isFalse);
      expect(logged.contains('+15551234567'), isFalse);
      expect(logged.contains('login-subscriber'), isTrue);
    });

    test('logApiResponse never writes a token echoed by the server', () async {
      PushFireLogger.logApiResponse('POST', 'http://test/register-device', 200,
          '{"id":"dev-1","fcmToken":"$_fcmToken"}');
      await Future<void>.delayed(Duration.zero);

      expect(records.join('\n').contains(_fcmToken), isFalse);
    });
  });
}
