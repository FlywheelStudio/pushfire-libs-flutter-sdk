import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pushfire_sdk/src/api/pushfire_api_client.dart';
import 'package:pushfire_sdk/src/config/pushfire_config.dart';
import 'package:pushfire_sdk/src/models/subscriber.dart';
import 'package:pushfire_sdk/src/services/device_service.dart';
import 'package:pushfire_sdk/src/services/subscriber_service.dart';
import 'package:pushfire_sdk/src/services/tag_service.dart';
import 'package:pushfire_sdk/src/utils/logger.dart';

/// What the services log while doing real work, not what the redaction helper
/// does in isolation.
class FakeApiClient extends PushFireApiClient {
  FakeApiClient()
      : super(const PushFireConfig(apiKey: 'k', baseUrl: 'http://test/'));

  @override
  Future<Map<String, dynamic>> post(
          String endpoint, Map<String, dynamic> data) async =>
      {'id': 'sub-1'};

  @override
  Future<Map<String, dynamic>> patch(
          String endpoint, Map<String, dynamic> data) async =>
      {'success': true};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> records;
  late FakeApiClient api;
  late DeviceService deviceService;
  late SubscriberService subscriberService;
  late TagService tagService;

  setUp(() {
    PushFireLogger.initialize(enableLogging: true);
    records = [];
    Logger.root.onRecord.listen((r) => records.add(r.message));

    api = FakeApiClient();
    deviceService = DeviceService(
      api,
      const PushFireConfig(apiKey: 'k', baseUrl: 'http://test/'),
    );
    subscriberService = SubscriberService(api, deviceService);
    tagService = TagService(api, subscriberService);
  });

  test('loginSubscriber logs the externalId but no PII', () async {
    SharedPreferences.setMockInitialValues({'pushfire_device_id': 'dev-1'});

    await subscriberService.loginSubscriber(
      externalId: 'user-42',
      name: 'Ada Lovelace',
      email: 'ada@example.com',
      phone: '+15551234567',
      metadata: {'plan': 'premium'},
    );
    await Future<void>.delayed(Duration.zero);

    final logged = records.join('\n');
    for (final secret in [
      'Ada Lovelace',
      'ada@example.com',
      '+15551234567',
      'premium',
    ]) {
      expect(logged.contains(secret), isFalse, reason: 'leaked $secret');
    }
    // Still traceable: the identifier a support ticket arrives with.
    expect(logged.contains('user-42'), isTrue);
  });

  test('addTag logs the tag id but not its value', () async {
    SharedPreferences.setMockInitialValues({
      'pushfire_device_id': 'dev-1',
      'pushfire_subscriber_id': 'sub-1',
      'pushfire_subscriber_data': json.encode(const Subscriber(
        id: 'sub-1',
        deviceId: 'dev-1',
        externalId: 'user-42',
      ).toJson()),
    });

    await tagService.addTag('user_email', 'ada@example.com');
    await Future<void>.delayed(Duration.zero);

    final logged = records.join('\n');
    expect(logged.contains('ada@example.com'), isFalse);
    expect(logged.contains('user_email'), isTrue);
  });

  test('updateTag logs the tag id but not its value', () async {
    SharedPreferences.setMockInitialValues({
      'pushfire_device_id': 'dev-1',
      'pushfire_subscriber_id': 'sub-1',
      'pushfire_subscriber_data': json.encode(const Subscriber(
        id: 'sub-1',
        deviceId: 'dev-1',
        externalId: 'user-42',
      ).toJson()),
    });

    await tagService.updateTag('user_region', 'eu-west-1');
    await Future<void>.delayed(Duration.zero);

    final logged = records.join('\n');
    expect(logged.contains('eu-west-1'), isFalse);
    expect(logged.contains('user_region'), isTrue);
  });
}
