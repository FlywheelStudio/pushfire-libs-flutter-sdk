import 'package:flutter_test/flutter_test.dart';
import 'package:pushfire_sdk/pushfire_sdk.dart';

void main() {
  group('AuthProvider', () {
    test('has exactly three values', () {
      expect(AuthProvider.values.length, 3);
    });

    test('contains supabase', () {
      expect(AuthProvider.values, contains(AuthProvider.supabase));
    });

    test('contains firebase', () {
      expect(AuthProvider.values, contains(AuthProvider.firebase));
    });

    test('contains none', () {
      expect(AuthProvider.values, contains(AuthProvider.none));
    });

    test('values are in expected order', () {
      expect(AuthProvider.values[0], AuthProvider.supabase);
      expect(AuthProvider.values[1], AuthProvider.firebase);
      expect(AuthProvider.values[2], AuthProvider.none);
    });

    test('name returns correct string for each value', () {
      expect(AuthProvider.supabase.name, 'supabase');
      expect(AuthProvider.firebase.name, 'firebase');
      expect(AuthProvider.none.name, 'none');
    });
  });

  group('PushFireConfig', () {
    group('construction with only apiKey', () {
      late PushFireConfig config;

      setUp(() {
        config = const PushFireConfig(apiKey: 'test-api-key');
      });

      test('stores the provided apiKey', () {
        expect(config.apiKey, 'test-api-key');
      });

      test('baseUrl defaults to the expected Supabase URL', () {
        expect(
          config.baseUrl,
          'https://jojnoebcqoqjlshwzmjm.supabase.co/functions/v1/',
        );
      });

      test('enableLogging defaults to false', () {
        expect(config.enableLogging, false);
      });

      test('timeoutSeconds defaults to 30', () {
        expect(config.timeoutSeconds, 30);
      });

      test('authProvider defaults to AuthProvider.none', () {
        expect(config.authProvider, AuthProvider.none);
      });

      test('requestNotificationPermission defaults to true', () {
        expect(config.requestNotificationPermission, true);
      });
    });

    group('construction with all parameters', () {
      late PushFireConfig config;

      setUp(() {
        config = const PushFireConfig(
          apiKey: 'my-custom-key',
          baseUrl: 'https://custom.api.example.com/',
          enableLogging: true,
          timeoutSeconds: 60,
          authProvider: AuthProvider.supabase,
          requestNotificationPermission: false,
        );
      });

      test('stores apiKey', () {
        expect(config.apiKey, 'my-custom-key');
      });

      test('stores custom baseUrl', () {
        expect(config.baseUrl, 'https://custom.api.example.com/');
      });

      test('stores enableLogging as true', () {
        expect(config.enableLogging, true);
      });

      test('stores custom timeoutSeconds', () {
        expect(config.timeoutSeconds, 60);
      });

      test('stores authProvider as supabase', () {
        expect(config.authProvider, AuthProvider.supabase);
      });

      test('stores requestNotificationPermission as false', () {
        expect(config.requestNotificationPermission, false);
      });
    });

    group('construction with firebase authProvider', () {
      test('stores authProvider as firebase', () {
        const config = PushFireConfig(
          apiKey: 'key',
          authProvider: AuthProvider.firebase,
        );
        expect(config.authProvider, AuthProvider.firebase);
      });
    });

    group('const constructor', () {
      test('can be used as a const value', () {
        const config1 = PushFireConfig(apiKey: 'same-key');
        const config2 = PushFireConfig(apiKey: 'same-key');
        // Both are const with identical arguments, so they are identical.
        expect(identical(config1, config2), true);
      });
    });

    group('copyWith', () {
      late PushFireConfig original;

      setUp(() {
        original = const PushFireConfig(
          apiKey: 'original-key',
          baseUrl: 'https://original.example.com/',
          enableLogging: false,
          timeoutSeconds: 30,
          authProvider: AuthProvider.none,
          requestNotificationPermission: true,
        );
      });

      test('returns a new instance with no changes when no arguments given',
          () {
        final copy = original.copyWith();
        expect(copy.apiKey, original.apiKey);
        expect(copy.baseUrl, original.baseUrl);
        expect(copy.enableLogging, original.enableLogging);
        expect(copy.timeoutSeconds, original.timeoutSeconds);
        expect(copy.authProvider, original.authProvider);
        expect(
          copy.requestNotificationPermission,
          original.requestNotificationPermission,
        );
      });

      test('copies with updated apiKey', () {
        final copy = original.copyWith(apiKey: 'new-key');
        expect(copy.apiKey, 'new-key');
        expect(copy.baseUrl, original.baseUrl);
        expect(copy.enableLogging, original.enableLogging);
        expect(copy.timeoutSeconds, original.timeoutSeconds);
        expect(copy.authProvider, original.authProvider);
        expect(
          copy.requestNotificationPermission,
          original.requestNotificationPermission,
        );
      });

      test('copies with updated baseUrl', () {
        final copy = original.copyWith(baseUrl: 'https://new.example.com/');
        expect(copy.apiKey, original.apiKey);
        expect(copy.baseUrl, 'https://new.example.com/');
      });

      test('copies with updated enableLogging', () {
        final copy = original.copyWith(enableLogging: true);
        expect(copy.enableLogging, true);
        expect(copy.apiKey, original.apiKey);
      });

      test('copies with updated timeoutSeconds', () {
        final copy = original.copyWith(timeoutSeconds: 120);
        expect(copy.timeoutSeconds, 120);
        expect(copy.apiKey, original.apiKey);
      });

      test('copies with updated authProvider', () {
        final copy = original.copyWith(authProvider: AuthProvider.firebase);
        expect(copy.authProvider, AuthProvider.firebase);
        expect(copy.apiKey, original.apiKey);
      });

      test('copies with updated requestNotificationPermission', () {
        final copy = original.copyWith(requestNotificationPermission: false);
        expect(copy.requestNotificationPermission, false);
        expect(copy.apiKey, original.apiKey);
      });

      test('copies with multiple parameters updated at once', () {
        final copy = original.copyWith(
          apiKey: 'multi-key',
          enableLogging: true,
          timeoutSeconds: 90,
          authProvider: AuthProvider.supabase,
        );
        expect(copy.apiKey, 'multi-key');
        expect(copy.enableLogging, true);
        expect(copy.timeoutSeconds, 90);
        expect(copy.authProvider, AuthProvider.supabase);
        // Unchanged fields
        expect(copy.baseUrl, original.baseUrl);
        expect(
          copy.requestNotificationPermission,
          original.requestNotificationPermission,
        );
      });

      test('copies with all parameters updated', () {
        final copy = original.copyWith(
          apiKey: 'all-new-key',
          baseUrl: 'https://all-new.example.com/',
          enableLogging: true,
          timeoutSeconds: 5,
          authProvider: AuthProvider.firebase,
          requestNotificationPermission: false,
        );
        expect(copy.apiKey, 'all-new-key');
        expect(copy.baseUrl, 'https://all-new.example.com/');
        expect(copy.enableLogging, true);
        expect(copy.timeoutSeconds, 5);
        expect(copy.authProvider, AuthProvider.firebase);
        expect(copy.requestNotificationPermission, false);
      });

      test('does not mutate the original instance', () {
        original.copyWith(
          apiKey: 'changed-key',
          baseUrl: 'https://changed.example.com/',
          enableLogging: true,
          timeoutSeconds: 999,
          authProvider: AuthProvider.supabase,
          requestNotificationPermission: false,
        );
        expect(original.apiKey, 'original-key');
        expect(original.baseUrl, 'https://original.example.com/');
        expect(original.enableLogging, false);
        expect(original.timeoutSeconds, 30);
        expect(original.authProvider, AuthProvider.none);
        expect(original.requestNotificationPermission, true);
      });
    });

    group('toString', () {
      test('includes baseUrl, enableLogging, and timeoutSeconds', () {
        const config = PushFireConfig(apiKey: 'some-key');
        final result = config.toString();
        expect(
          result,
          'PushFireConfig(baseUrl: '
          'https://jojnoebcqoqjlshwzmjm.supabase.co/functions/v1/, '
          'enableLogging: false, timeoutSeconds: 30)',
        );
      });

      test('reflects custom values', () {
        const config = PushFireConfig(
          apiKey: 'some-key',
          baseUrl: 'https://custom.com/',
          enableLogging: true,
          timeoutSeconds: 45,
        );
        final result = config.toString();
        expect(
          result,
          'PushFireConfig(baseUrl: https://custom.com/, '
          'enableLogging: true, timeoutSeconds: 45)',
        );
      });

      test('does not contain apiKey for security', () {
        const config = PushFireConfig(apiKey: 'super-secret-key-12345');
        final result = config.toString();
        expect(result.contains('super-secret-key-12345'), false);
      });

      test('does not contain authProvider', () {
        const config = PushFireConfig(
          apiKey: 'key',
          authProvider: AuthProvider.supabase,
        );
        final result = config.toString();
        // toString only includes baseUrl, enableLogging, and timeoutSeconds
        expect(result.contains('authProvider'), false);
      });

      test('does not contain requestNotificationPermission', () {
        const config = PushFireConfig(apiKey: 'key');
        final result = config.toString();
        expect(result.contains('requestNotificationPermission'), false);
      });
    });
  });
}
