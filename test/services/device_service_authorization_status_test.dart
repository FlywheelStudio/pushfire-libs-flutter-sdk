import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:pushfire_sdk/src/services/device_service.dart';
import 'package:pushfire_sdk/src/utils/logger.dart';

/// Covers every AuthorizationStatus the resolved firebase_messaging defines,
/// so the test also checks deniedPermanently when the version has it.
void main() {
  const granted = {
    AuthorizationStatus.authorized,
    AuthorizationStatus.provisional,
  };

  group('DeviceService.isDenied', () {
    test('is true only for denied statuses', () {
      for (final status in AuthorizationStatus.values) {
        final expected = !granted.contains(status) &&
            status != AuthorizationStatus.notDetermined;
        expect(DeviceService.isDenied(status), expected, reason: '$status');
      }
    });

    test('includes denied', () {
      expect(DeviceService.isDenied(AuthorizationStatus.denied), isTrue);
    });

    test('includes deniedPermanently when firebase_messaging defines it', () {
      final permanent = AuthorizationStatus.values
          .where((s) => s.name == 'deniedPermanently');
      for (final status in permanent) {
        expect(DeviceService.isDenied(status), isTrue);
      }
    });
  });

  group('DeviceService.logPermissionResult', () {
    late List<LogRecord> records;

    setUp(() {
      PushFireLogger.initialize(enableLogging: true);
      records = [];
      Logger.root.onRecord.listen(records.add);
    });

    test('logs every status, warning only for denied ones', () {
      for (final status in AuthorizationStatus.values) {
        records.clear();
        DeviceService.logPermissionResult(status);

        expect(records, hasLength(1), reason: '$status');
        final record = records.single;
        if (DeviceService.isDenied(status)) {
          expect(record.level, Level.WARNING, reason: '$status');
          expect(record.message, contains('denied'), reason: '$status');
          expect(record.message, contains('$status'), reason: '$status');
        } else {
          expect(record.level, lessThan(Level.WARNING), reason: '$status');
        }
      }
    });

    test('granted statuses are not described as denied', () {
      for (final status in granted) {
        records.clear();
        DeviceService.logPermissionResult(status);
        expect(records.single.message, isNot(contains('denied')),
            reason: '$status');
      }
    });
  });
}
