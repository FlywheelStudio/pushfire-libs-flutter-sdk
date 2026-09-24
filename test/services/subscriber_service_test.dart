import 'dart:convert';
import 'dart:io';

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
  Map<String, dynamic>? lastPostData;
  Map<String, dynamic>? lastPatchData;

  FakeApiClient()
      : super(const PushFireConfig(apiKey: 'k', baseUrl: 'http://test/'));

  void throwOnPost(Object error) => _postError = error;
  void returnOnPost(Map<String, dynamic> response) => _postResponse = response;

  @override
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    if (_postError != null) throw _postError!;
    lastPostData = data;
    return _postResponse;
  }

  @override
  Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> data) async {
    lastPatchData = data;
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

  group('Subscriber timezone API payload', () {
    late FakeApiClient fakeApi;
    late SubscriberService service;

    setUp(() {
      _seedPrefs();
      fakeApi = FakeApiClient()..returnOnPost({'subscriberId': 'sub-123'});
      service = SubscriberService(
        fakeApi,
        DeviceService(fakeApi, const PushFireConfig(apiKey: 'k')),
      );
    });

    test('login sends an IANA timezone and stores it', () async {
      final subscriber = await service.loginSubscriber(
        externalId: 'user-1',
        timezone: 'America/New_York',
      );

      expect(fakeApi.lastPostData?['data']['timezone'], 'America/New_York');
      expect(subscriber.timezone, 'America/New_York');
      expect(
          (await service.getCurrentSubscriber())?.timezone, 'America/New_York');
    });

    test('update sends timezone and can clear it with an empty string',
        () async {
      await service.updateSubscriber(
        subscriberId: 'sub-123',
        externalId: 'user-1',
        timezone: 'Europe/London',
      );
      expect(fakeApi.lastPatchData?['data']['timezone'], 'Europe/London');

      await service.updateSubscriber(
        subscriberId: 'sub-123',
        externalId: 'user-1',
        timezone: '',
      );
      expect(fakeApi.lastPatchData?['data']['timezone'], '');
    });

    test('omits timezone when caller does not supply one', () async {
      await service.loginSubscriber(externalId: 'user-1');
      expect(fakeApi.lastPostData?['data'], isNot(contains('timezone')));

      await service.updateSubscriber(
        subscriberId: 'sub-123',
        externalId: 'user-1',
      );
      expect(fakeApi.lastPatchData?['data'], isNot(contains('timezone')));
    });
  });

  test('subscriber timezone travels over the real HTTP client', () async {
    _seedPrefs();
    // flutter_test normally replaces HttpClient with an empty HTTP 400 stub.
    final previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = null;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <Map<String, dynamic>>[];
    final listener = server.listen((request) async {
      requests.add({
        'method': request.method,
        'path': request.uri.path,
        'body': jsonDecode(await utf8.decoder.bind(request).join()),
      });
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'subscriberId': 'sub-123'}));
      await request.response.close();
    });

    try {
      final api = PushFireApiClient(PushFireConfig(
        apiKey: 'test-key',
        baseUrl: 'http://127.0.0.1:${server.port}/',
      ));
      final service = SubscriberService(
        api,
        DeviceService(api, const PushFireConfig(apiKey: 'test-key')),
      );

      await service.loginSubscriber(
        externalId: 'user-1',
        timezone: 'Africa/Tripoli',
      );
      await service.updateSubscriber(
        subscriberId: 'sub-123',
        externalId: 'user-1',
        timezone: '',
      );

      expect(requests, [
        {
          'method': 'POST',
          'path': '/login-subscriber',
          'body': {
            'data': {
              'deviceId': 'dev-abc',
              'externalId': 'user-1',
              'timezone': 'Africa/Tripoli',
            },
          },
        },
        {
          'method': 'PATCH',
          'path': '/update-subscriber',
          'body': {
            'data': {
              'id': 'sub-123',
              'externalId': 'user-1',
              'timezone': '',
            },
          },
        },
      ]);
    } finally {
      await listener.cancel();
      await server.close(force: true);
      HttpOverrides.global = previousHttpOverrides;
    }
  });

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

    test('clears local data when the API throws a PushFireApiException',
        () async {
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
          reason:
              'subscriber-data key should be cleared after unexpected error');
    });
  });
}
