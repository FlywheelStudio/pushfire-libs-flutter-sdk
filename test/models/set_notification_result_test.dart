import 'package:flutter_test/flutter_test.dart';
import 'package:pushfire_sdk/src/models/set_notification_result.dart';

void main() {
  group('SetNotificationResult', () {
    test('has success value', () {
      expect(SetNotificationResult.success, isNotNull);
    });

    test('has systemPermissionDenied value', () {
      expect(SetNotificationResult.systemPermissionDenied, isNotNull);
    });

    test('values are distinct', () {
      expect(SetNotificationResult.success,
          isNot(SetNotificationResult.systemPermissionDenied));
    });

    test('has exactly 2 values', () {
      expect(SetNotificationResult.values.length, 2);
    });
  });
}
