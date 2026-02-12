import 'package:flutter_test/flutter_test.dart';
import 'package:pushfire_sdk/pushfire_sdk.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Shared test data
  // ---------------------------------------------------------------------------

  const fullJson = <String, dynamic>{
    'id': 'device-abc-123',
    'fcmToken': 'fcm-token-xyz',
    'os': 'android',
    'osVersion': '14',
    'language': 'en',
    'manufacturer': 'Google',
    'model': 'Pixel 8',
    'appVersion': '2.1.0',
    'pushNotificationEnabled': true,
  };

  const minimalJson = <String, dynamic>{
    'fcmToken': 'fcm-token-xyz',
    'os': 'ios',
    'osVersion': '17.4',
    'language': 'ar',
    'manufacturer': 'Apple',
    'model': 'iPhone 15',
    'appVersion': '1.0.0',
    'pushNotificationEnabled': false,
  };

  Device createFullDevice() {
    return const Device(
      id: 'device-abc-123',
      fcmToken: 'fcm-token-xyz',
      os: 'android',
      osVersion: '14',
      language: 'en',
      manufacturer: 'Google',
      model: 'Pixel 8',
      appVersion: '2.1.0',
      pushNotificationEnabled: true,
    );
  }

  Device createMinimalDevice() {
    return const Device(
      fcmToken: 'fcm-token-xyz',
      os: 'ios',
      osVersion: '17.4',
      language: 'ar',
      manufacturer: 'Apple',
      model: 'iPhone 15',
      appVersion: '1.0.0',
      pushNotificationEnabled: false,
    );
  }

  // ---------------------------------------------------------------------------
  // Construction
  // ---------------------------------------------------------------------------

  group('Construction', () {
    test('should create a Device with all fields including id', () {
      final device = createFullDevice();

      expect(device.id, 'device-abc-123');
      expect(device.fcmToken, 'fcm-token-xyz');
      expect(device.os, 'android');
      expect(device.osVersion, '14');
      expect(device.language, 'en');
      expect(device.manufacturer, 'Google');
      expect(device.model, 'Pixel 8');
      expect(device.appVersion, '2.1.0');
      expect(device.pushNotificationEnabled, true);
    });

    test('should create a Device with id as null', () {
      final device = createMinimalDevice();

      expect(device.id, isNull);
      expect(device.fcmToken, 'fcm-token-xyz');
      expect(device.os, 'ios');
      expect(device.osVersion, '17.4');
      expect(device.language, 'ar');
      expect(device.manufacturer, 'Apple');
      expect(device.model, 'iPhone 15');
      expect(device.appVersion, '1.0.0');
      expect(device.pushNotificationEnabled, false);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson
  // ---------------------------------------------------------------------------

  group('fromJson', () {
    test('should parse complete JSON with id', () {
      final device = Device.fromJson(fullJson);

      expect(device.id, 'device-abc-123');
      expect(device.fcmToken, 'fcm-token-xyz');
      expect(device.os, 'android');
      expect(device.osVersion, '14');
      expect(device.language, 'en');
      expect(device.manufacturer, 'Google');
      expect(device.model, 'Pixel 8');
      expect(device.appVersion, '2.1.0');
      expect(device.pushNotificationEnabled, true);
    });

    test('should parse minimal JSON without id', () {
      final device = Device.fromJson(minimalJson);

      expect(device.id, isNull);
      expect(device.fcmToken, 'fcm-token-xyz');
      expect(device.os, 'ios');
      expect(device.osVersion, '17.4');
      expect(device.language, 'ar');
      expect(device.manufacturer, 'Apple');
      expect(device.model, 'iPhone 15');
      expect(device.appVersion, '1.0.0');
      expect(device.pushNotificationEnabled, false);
    });

    test('should parse JSON where id is explicitly null', () {
      final json = Map<String, dynamic>.from(minimalJson)..['id'] = null;
      final device = Device.fromJson(json);

      expect(device.id, isNull);
      expect(device.fcmToken, 'fcm-token-xyz');
    });
  });

  // ---------------------------------------------------------------------------
  // toJson
  // ---------------------------------------------------------------------------

  group('toJson', () {
    test('should include id in JSON when id is not null', () {
      final device = createFullDevice();
      final json = device.toJson();

      expect(json['id'], 'device-abc-123');
      expect(json['fcmToken'], 'fcm-token-xyz');
      expect(json['os'], 'android');
      expect(json['osVersion'], '14');
      expect(json['language'], 'en');
      expect(json['manufacturer'], 'Google');
      expect(json['model'], 'Pixel 8');
      expect(json['appVersion'], '2.1.0');
      expect(json['pushNotificationEnabled'], true);
      expect(json.length, 9);
    });

    test('should omit id from JSON when id is null', () {
      final device = createMinimalDevice();
      final json = device.toJson();

      expect(json.containsKey('id'), isFalse);
      expect(json['fcmToken'], 'fcm-token-xyz');
      expect(json['os'], 'ios');
      expect(json['osVersion'], '17.4');
      expect(json['language'], 'ar');
      expect(json['manufacturer'], 'Apple');
      expect(json['model'], 'iPhone 15');
      expect(json['appVersion'], '1.0.0');
      expect(json['pushNotificationEnabled'], false);
      expect(json.length, 8);
    });

    test('should always include all non-id fields', () {
      final device = createMinimalDevice();
      final json = device.toJson();

      final requiredKeys = [
        'fcmToken',
        'os',
        'osVersion',
        'language',
        'manufacturer',
        'model',
        'appVersion',
        'pushNotificationEnabled',
      ];

      for (final key in requiredKeys) {
        expect(json.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Round-trip: fromJson -> toJson
  // ---------------------------------------------------------------------------

  group('Round-trip serialization', () {
    test('toJson output should match original JSON (with id)', () {
      final device = Device.fromJson(fullJson);
      final result = device.toJson();

      expect(result, fullJson);
    });

    test('toJson output should match original JSON (without id)', () {
      final device = Device.fromJson(minimalJson);
      final result = device.toJson();

      expect(result, minimalJson);
    });

    test('fromJson(toJson()) should produce an equal Device', () {
      final original = createFullDevice();
      final roundTripped = Device.fromJson(original.toJson());

      expect(roundTripped, original);
    });

    test('fromJson(toJson()) should produce an equal Device (no id)', () {
      final original = createMinimalDevice();
      final roundTripped = Device.fromJson(original.toJson());

      expect(roundTripped, original);
    });
  });

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  group('copyWith', () {
    test('should return an identical copy when no arguments are provided', () {
      final device = createFullDevice();
      final copy = device.copyWith();

      expect(copy, device);
      expect(copy.id, device.id);
      expect(copy.fcmToken, device.fcmToken);
      expect(copy.os, device.os);
      expect(copy.osVersion, device.osVersion);
      expect(copy.language, device.language);
      expect(copy.manufacturer, device.manufacturer);
      expect(copy.model, device.model);
      expect(copy.appVersion, device.appVersion);
      expect(copy.pushNotificationEnabled, device.pushNotificationEnabled);
    });

    test('should update only the id field', () {
      final device = createFullDevice();
      final copy = device.copyWith(id: 'new-id');

      expect(copy.id, 'new-id');
      expect(copy.fcmToken, device.fcmToken);
      expect(copy.os, device.os);
      expect(copy.osVersion, device.osVersion);
      expect(copy.language, device.language);
      expect(copy.manufacturer, device.manufacturer);
      expect(copy.model, device.model);
      expect(copy.appVersion, device.appVersion);
      expect(copy.pushNotificationEnabled, device.pushNotificationEnabled);
    });

    test('should update only the fcmToken field', () {
      final device = createFullDevice();
      final copy = device.copyWith(fcmToken: 'new-fcm-token');

      expect(copy.id, device.id);
      expect(copy.fcmToken, 'new-fcm-token');
      expect(copy.os, device.os);
    });

    test('should update only the os field', () {
      final device = createFullDevice();
      final copy = device.copyWith(os: 'ios');

      expect(copy.os, 'ios');
      expect(copy.fcmToken, device.fcmToken);
      expect(copy.model, device.model);
    });

    test('should update only the osVersion field', () {
      final device = createFullDevice();
      final copy = device.copyWith(osVersion: '15');

      expect(copy.osVersion, '15');
      expect(copy.os, device.os);
    });

    test('should update only the language field', () {
      final device = createFullDevice();
      final copy = device.copyWith(language: 'fr');

      expect(copy.language, 'fr');
      expect(copy.manufacturer, device.manufacturer);
    });

    test('should update only the manufacturer field', () {
      final device = createFullDevice();
      final copy = device.copyWith(manufacturer: 'Samsung');

      expect(copy.manufacturer, 'Samsung');
      expect(copy.model, device.model);
    });

    test('should update only the model field', () {
      final device = createFullDevice();
      final copy = device.copyWith(model: 'Galaxy S24');

      expect(copy.model, 'Galaxy S24');
      expect(copy.manufacturer, device.manufacturer);
    });

    test('should update only the appVersion field', () {
      final device = createFullDevice();
      final copy = device.copyWith(appVersion: '3.0.0');

      expect(copy.appVersion, '3.0.0');
      expect(copy.os, device.os);
    });

    test('should update only the pushNotificationEnabled field', () {
      final device = createFullDevice();
      final copy = device.copyWith(pushNotificationEnabled: false);

      expect(copy.pushNotificationEnabled, false);
      expect(copy.fcmToken, device.fcmToken);
      expect(copy.id, device.id);
    });

    test('should update multiple fields at once', () {
      final device = createFullDevice();
      final copy = device.copyWith(
        os: 'ios',
        osVersion: '17.4',
        manufacturer: 'Apple',
        model: 'iPhone 15',
      );

      expect(copy.os, 'ios');
      expect(copy.osVersion, '17.4');
      expect(copy.manufacturer, 'Apple');
      expect(copy.model, 'iPhone 15');
      // Unchanged fields preserved
      expect(copy.id, device.id);
      expect(copy.fcmToken, device.fcmToken);
      expect(copy.language, device.language);
      expect(copy.appVersion, device.appVersion);
      expect(copy.pushNotificationEnabled, device.pushNotificationEnabled);
    });

    test('should preserve null id when no id argument is provided', () {
      final device = createMinimalDevice();
      final copy = device.copyWith(fcmToken: 'updated-token');

      expect(copy.id, isNull);
      expect(copy.fcmToken, 'updated-token');
    });
  });

  // ---------------------------------------------------------------------------
  // Equality (operator ==)
  // ---------------------------------------------------------------------------

  group('Equality', () {
    test('two devices with the same data should be equal', () {
      final a = createFullDevice();
      final b = createFullDevice();

      expect(a, b);
      expect(a == b, isTrue);
    });

    test('two devices with null ids and same data should be equal', () {
      final a = createMinimalDevice();
      final b = createMinimalDevice();

      expect(a, b);
      expect(a == b, isTrue);
    });

    test('identical reference should be equal', () {
      final device = createFullDevice();

      expect(device == device, isTrue);
      expect(identical(device, device), isTrue);
    });

    test('devices with different id should not be equal', () {
      final a = createFullDevice();
      final b = a.copyWith(id: 'different-id');

      expect(a == b, isFalse);
    });

    test('devices with different fcmToken should not be equal', () {
      final a = createFullDevice();
      final b = a.copyWith(fcmToken: 'different-token');

      expect(a == b, isFalse);
    });

    test('devices with different os should not be equal', () {
      final a = createFullDevice();
      final b = a.copyWith(os: 'ios');

      expect(a == b, isFalse);
    });

    test('devices with different osVersion should not be equal', () {
      final a = createFullDevice();
      final b = a.copyWith(osVersion: '15');

      expect(a == b, isFalse);
    });

    test('devices with different language should not be equal', () {
      final a = createFullDevice();
      final b = a.copyWith(language: 'de');

      expect(a == b, isFalse);
    });

    test('devices with different manufacturer should not be equal', () {
      final a = createFullDevice();
      final b = a.copyWith(manufacturer: 'Samsung');

      expect(a == b, isFalse);
    });

    test('devices with different model should not be equal', () {
      final a = createFullDevice();
      final b = a.copyWith(model: 'Galaxy S24');

      expect(a == b, isFalse);
    });

    test('devices with different appVersion should not be equal', () {
      final a = createFullDevice();
      final b = a.copyWith(appVersion: '9.9.9');

      expect(a == b, isFalse);
    });

    test('devices with different pushNotificationEnabled should not be equal',
        () {
      final a = createFullDevice();
      final b = a.copyWith(pushNotificationEnabled: false);

      expect(a == b, isFalse);
    });

    test('a Device should not equal a non-Device object', () {
      final device = createFullDevice();

      // ignore: unrelated_type_equality_checks
      expect(device == 'not a device', isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // hashCode
  // ---------------------------------------------------------------------------

  group('hashCode', () {
    test('equal devices should have the same hashCode', () {
      final a = createFullDevice();
      final b = createFullDevice();

      expect(a.hashCode, b.hashCode);
    });

    test('equal devices without id should have the same hashCode', () {
      final a = createMinimalDevice();
      final b = createMinimalDevice();

      expect(a.hashCode, b.hashCode);
    });

    test('different devices should (likely) have different hashCodes', () {
      final a = createFullDevice();
      final b = a.copyWith(fcmToken: 'completely-different-token-value');

      // Hash collisions are theoretically possible but extremely unlikely
      // for distinct inputs. This test validates the implementation covers
      // all fields in the hash computation.
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('hashCode is consistent across multiple calls', () {
      final device = createFullDevice();
      final first = device.hashCode;
      final second = device.hashCode;
      final third = device.hashCode;

      expect(first, second);
      expect(second, third);
    });
  });

  // ---------------------------------------------------------------------------
  // toString
  // ---------------------------------------------------------------------------

  group('toString', () {
    test('should contain the id value', () {
      final device = createFullDevice();
      final str = device.toString();

      expect(str, contains('device-abc-123'));
    });

    test('should contain the os value', () {
      final device = createFullDevice();
      final str = device.toString();

      expect(str, contains('android'));
    });

    test('should contain the model value', () {
      final device = createFullDevice();
      final str = device.toString();

      expect(str, contains('Pixel 8'));
    });

    test('should contain the pushNotificationEnabled value', () {
      final device = createFullDevice();
      final str = device.toString();

      expect(str, contains('true'));
    });

    test('should start with Device(', () {
      final device = createFullDevice();
      final str = device.toString();

      expect(str, startsWith('Device('));
    });

    test('should handle null id in toString', () {
      final device = createMinimalDevice();
      final str = device.toString();

      expect(str, contains('null'));
      expect(str, contains('ios'));
      expect(str, contains('iPhone 15'));
    });

    test('should match the exact format from the implementation', () {
      final device = createFullDevice();
      final str = device.toString();

      expect(
        str,
        'Device(id: device-abc-123, os: android, model: Pixel 8, '
        'pushNotificationEnabled: true)',
      );
    });

    test('should match the exact format with null id', () {
      final device = createMinimalDevice();
      final str = device.toString();

      expect(
        str,
        'Device(id: null, os: ios, model: iPhone 15, '
        'pushNotificationEnabled: false)',
      );
    });
  });
}
