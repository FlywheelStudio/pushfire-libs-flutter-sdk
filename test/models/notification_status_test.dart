import 'package:flutter_test/flutter_test.dart';
import 'package:pushfire_sdk/src/models/notification_status.dart';

void main() {
  group('NotificationStatus', () {
    group('constructor', () {
      test('creates instance with all fields', () {
        const status = NotificationStatus(
          isPermissionGranted: true,
          isEnabled: false,
        );
        expect(status.isPermissionGranted, true);
        expect(status.isEnabled, false);
      });

      test('can be declared as const', () {
        const a = NotificationStatus(
          isPermissionGranted: true,
          isEnabled: true,
        );
        const b = NotificationStatus(
          isPermissionGranted: true,
          isEnabled: true,
        );
        expect(identical(a, b), isTrue);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        const a = NotificationStatus(
          isPermissionGranted: true,
          isEnabled: true,
        );
        const b = NotificationStatus(
          isPermissionGranted: true,
          isEnabled: true,
        );
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different isPermissionGranted are not equal', () {
        const a = NotificationStatus(
          isPermissionGranted: true,
          isEnabled: true,
        );
        const b = NotificationStatus(
          isPermissionGranted: false,
          isEnabled: true,
        );
        expect(a, isNot(b));
      });

      test('different isEnabled are not equal', () {
        const a = NotificationStatus(
          isPermissionGranted: true,
          isEnabled: true,
        );
        const b = NotificationStatus(
          isPermissionGranted: true,
          isEnabled: false,
        );
        expect(a, isNot(b));
      });
    });

    group('toString', () {
      test('includes both fields', () {
        const status = NotificationStatus(
          isPermissionGranted: true,
          isEnabled: false,
        );
        final str = status.toString();
        expect(str, contains('isPermissionGranted: true'));
        expect(str, contains('isEnabled: false'));
      });
    });
  });
}
