import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pushfire_sdk/src/api/pushfire_api_client.dart';
import 'package:pushfire_sdk/src/config/pushfire_config.dart';
import 'package:pushfire_sdk/src/exceptions/pushfire_exceptions.dart';
import 'package:pushfire_sdk/src/models/subscriber.dart';
import 'package:pushfire_sdk/src/services/device_service.dart';
import 'package:pushfire_sdk/src/services/subscriber_service.dart';

/// Fake API client that allows configuring what post() throws or returns
class FakeApiClient extends PushFireApiClient {
  Object? _postError;
  Map<String, dynamic> _postResponse = {'success': true};

  FakeApiClient()
      : super(const PushFireConfig(apiKey: 'k', baseUrl: 'http://test/'));

  void throwOnPost(Object error) => _postError = error;
  void returnOnPost(Map<String, dynamic> response) => _postResponse = response;

  @override
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    if (_postError != null) throw _postError!;
    return _postResponse;
  }

  @override
  Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> data) async {
    return {'success': true};
  }
}

/// Shared preferences keys (mirrors SubscriberService constants)
const _subscriberIdKey = 'pushfire_subscriber_id';
const _subscriberDataKey = 'pushfire_subscriber_data';
const _deviceIdKey = 'pushfire_device_id';

/// Seed SharedPreferences with a subscriber and a device id
void _seedPrefs() {
  const subscriber = Subscriber(
    id: 'sub-123',
    deviceId: 'dev-abc',
    externalId: 'user-1',
  );
  SharedPreferences.setMockInitialValues({
    _subscriberIdKey: 'sub-123',
    _subscriberDataKey: json.encode(subscriber.toJson()),
    _deviceIdKey: 'dev-abc',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriberService.logoutSubscriber - clears local data on error', () {
    late FakeApiClient fakeApi;
    late SubscriberService service;

    setUp(() {
      fakeApi = FakeApiClient();
      final deviceService = DeviceService(
        fakeApi,
        const PushFireConfig(apiKey: 'k'),
      );
      service = SubscriberService(fakeApi, deviceService);
    });

    test('clears local data when the API throws a PushFireApiException', () async {
      _seedPrefs();

      fakeApi.throwOnPost(
        const PushFireApiException('Unauthorized', statusCode: 401),
      );

      await expectLater(
        service.logoutSubscriber(),
        throwsA(isA<PushFireApiException>()
            .having((e) => e.statusCode, 'statusCode', 401)),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_subscriberIdKey), isNull,
          reason: 'subscriber-id key should be cleared after logout error');
      expect(prefs.getString(_subscriberDataKey), isNull,
          reason: 'subscriber-data key should be cleared after logout error');
    });

    test('clears local data when the API throws an unexpected error', () async {
      _seedPrefs();

      fakeApi.throwOnPost(Exception('network blip'));

      await expectLater(
        service.logoutSubscriber(),
        throwsA(isA<PushFireSubscriberException>()),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(_subscriberIdKey), isNull,
          reason: 'subscriber-id key should be cleared after unexpected error');
      expect(prefs.getString(_subscriberDataKey), isNull,
          reason: 'subscriber-data key should be cleared after unexpected error');
    });
  });
}
