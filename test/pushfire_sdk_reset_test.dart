import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pushfire_sdk/src/api/pushfire_api_client.dart';
import 'package:pushfire_sdk/src/config/pushfire_config.dart';
import 'package:pushfire_sdk/src/exceptions/pushfire_exceptions.dart';
import 'package:pushfire_sdk/src/pushfire_sdk_impl.dart';
import 'package:pushfire_sdk/src/services/device_service.dart';
import 'package:pushfire_sdk/src/services/subscriber_service.dart';

class FakeApiClient extends PushFireApiClient {
  final List<String> postEndpoints = [];
  Object? postError;

  FakeApiClient()
      : super(const PushFireConfig(apiKey: 'k', baseUrl: 'http://test/'));

  @override
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    postEndpoints.add(endpoint);
    if (postError != null) throw postError!;
    return {'success': true};
  }
}

const _subscriberIdKey = 'pushfire_subscriber_id';
const _subscriberDataKey = 'pushfire_subscriber_data';
const _deviceIdKey = 'pushfire_device_id';
const _fcmTokenKey = 'pushfire_fcm_token';
const _lastPermissionStatusKey = 'pushfire_last_permission_status';
const _notificationPreferenceKey = 'pushfire_notification_preference';

/// Everything reset() promises to erase.
const _allKeys = [
  _subscriberIdKey,
  _subscriberDataKey,
  _deviceIdKey,
  _fcmTokenKey,
  _lastPermissionStatusKey,
  _notificationPreferenceKey,
];

Map<String, Object> _seed({required Map<String, dynamic> subscriberBlob}) => {
      _subscriberDataKey: json.encode(subscriberBlob),
      if (subscriberBlob['id'] != null)
        _subscriberIdKey: subscriberBlob['id'] as String,
      _deviceIdKey: 'dev-abc',
      _fcmTokenKey: 'fcm-token',
      _lastPermissionStatusKey: true,
      _notificationPreferenceKey: false,
    };

/// A fully populated subscriber, as stored after a successful login.
const _loggedIn = {
  'id': 'sub-123',
  'deviceId': 'dev-abc',
  'externalId': 'user-1',
  'name': 'Ada Lovelace',
  'email': 'ada@example.com',
  'phone': '+15551234567',
};

Future<void> _expectEverythingCleared() async {
  final prefs = await SharedPreferences.getInstance();
  for (final key in _allKeys) {
    expect(prefs.get(key), isNull, reason: '$key survived the reset');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeApiClient api;
  late DeviceService deviceService;
  late SubscriberService subscriberService;

  void wire() {
    api = FakeApiClient();
    deviceService = DeviceService(
      api,
      const PushFireConfig(apiKey: 'k', baseUrl: 'http://test/'),
    );
    subscriberService = SubscriberService(api, deviceService);
  }

  Future<void> reset() => PushFireSDKImpl.clearAllLocalState(
        subscriberService: subscriberService,
        deviceService: deviceService,
        isSubscriberLoggedIn: subscriberService.isSubscriberLoggedIn,
        logoutSubscriber: subscriberService.logoutSubscriber,
      );

  group('reset clears all local state', () {
    test('logs out and clears everything on the happy path', () async {
      SharedPreferences.setMockInitialValues(_seed(subscriberBlob: _loggedIn));
      wire();

      await reset();

      expect(api.postEndpoints, ['logout-subscriber']);
      await _expectEverythingCleared();
    });

    test('clears a stored subscriber whose id is null', () async {
      // A blob with no id does not count as logged in, so the gated logout
      // skips it entirely — and on a shared device the next user's session
      // would start holding the previous user's name, email and phone.
      SharedPreferences.setMockInitialValues(_seed(subscriberBlob: {
        'deviceId': 'dev-abc',
        'externalId': 'user-1',
        'name': 'Ada Lovelace',
        'email': 'ada@example.com',
        'phone': '+15551234567',
      }));
      wire();

      expect(await subscriberService.isSubscriberLoggedIn(), isFalse);

      await reset();

      expect(api.postEndpoints, isEmpty, reason: 'nothing to log out');
      await _expectEverythingCleared();
    });

    test('clears device data when the logout request fails', () async {
      // logoutSubscriber clears locally and then rethrows. Letting that escape
      // skipped clearDeviceData, so the device id, FCM token and permission
      // state survived a reset that reported failure.
      SharedPreferences.setMockInitialValues(_seed(subscriberBlob: _loggedIn));
      wire();
      api.postError = const PushFireApiException('boom', statusCode: 500);

      await reset();

      expect(api.postEndpoints, ['logout-subscriber']);
      await _expectEverythingCleared();
    });

    test('does not rethrow a failed logout', () async {
      SharedPreferences.setMockInitialValues(_seed(subscriberBlob: _loggedIn));
      wire();
      api.postError = const PushFireNetworkException('offline');

      await expectLater(reset(), completes);
    });

    test('clears device data when the logout throws something unexpected',
        () async {
      SharedPreferences.setMockInitialValues(_seed(subscriberBlob: _loggedIn));
      wire();
      api.postError = StateError('not a PushFireException');

      await reset();

      await _expectEverythingCleared();
    });

    test('is a no-op on an already clean install', () async {
      SharedPreferences.setMockInitialValues({});
      wire();

      await reset();

      expect(api.postEndpoints, isEmpty);
      await _expectEverythingCleared();
    });
  });
}
