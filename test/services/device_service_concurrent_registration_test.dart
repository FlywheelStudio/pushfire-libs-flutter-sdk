import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pushfire_sdk/src/api/pushfire_api_client.dart';
import 'package:pushfire_sdk/src/config/pushfire_config.dart';
import 'package:pushfire_sdk/src/exceptions/pushfire_exceptions.dart';
import 'package:pushfire_sdk/src/services/device_service.dart';

/// API client that records calls and can hold a POST open, so two callers are
/// genuinely in flight at the same time.
class SlowFakeApiClient extends PushFireApiClient {
  final List<String> postEndpoints = [];
  final List<String> patchEndpoints = [];
  Duration postDelay = const Duration(milliseconds: 20);
  int _nextDeviceId = 1;

  SlowFakeApiClient()
      : super(const PushFireConfig(apiKey: 'test', baseUrl: 'http://test/'));

  @override
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    postEndpoints.add(endpoint);
    await Future<void>.delayed(postDelay);
    // A distinct id per call, so a second registration is visible in the
    // returned device rather than hidden behind a shared constant.
    return {'id': 'device-${_nextDeviceId++}'};
  }

  @override
  Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> data) async {
    patchEndpoints.add(endpoint);
    await Future<void>.delayed(postDelay);
    return {'success': true};
  }
}

const _deviceInfo = {
  'os': 'ios',
  'osVersion': '17.0',
  'language': 'en',
  'manufacturer': 'Apple',
  'model': 'iPhone',
  'appVersion': '1.0.0',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('registerDevice is single-flight', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('two concurrent callers create one device row', () async {
      final api = SlowFakeApiClient();
      final service = DeviceService(
        api,
        const PushFireConfig(apiKey: 'test', baseUrl: 'http://test/'),
        isPushNotificationEnabledOverride: () async => true,
        getDeviceInfoOverride: () async => _deviceInfo,
        getFcmTokenOverride: () async => 'fcm-token',
      );

      // Both enter before either writes the device id. Without the guard both
      // read no stored id, both POST, and the first row is orphaned server-side
      // while still holding this FCM token.
      final results = await Future.wait([
        service.registerDevice(),
        service.registerDevice(),
      ]);

      expect(api.postEndpoints, ['register-device']);
      expect(results[0].id, results[1].id);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pushfire_device_id'), results[0].id);
    });

    test('five concurrent callers still create one device row', () async {
      final api = SlowFakeApiClient();
      final service = DeviceService(
        api,
        const PushFireConfig(apiKey: 'test', baseUrl: 'http://test/'),
        isPushNotificationEnabledOverride: () async => true,
        getDeviceInfoOverride: () async => _deviceInfo,
        getFcmTokenOverride: () async => 'fcm-token',
      );

      final results = await Future.wait(
        List.generate(5, (_) => service.registerDevice()),
      );

      expect(api.postEndpoints.length, 1);
      expect(results.map((d) => d.id).toSet(), {results.first.id});
    });

    test('a later registration is not blocked by an earlier finished one',
        () async {
      final api = SlowFakeApiClient();
      var token = 'token-1';
      final service = DeviceService(
        api,
        const PushFireConfig(apiKey: 'test', baseUrl: 'http://test/'),
        isPushNotificationEnabledOverride: () async => true,
        getDeviceInfoOverride: () async => _deviceInfo,
        getFcmTokenOverride: () async => token,
      );

      await service.registerDevice();
      // The token rotated, so the second call must reach the server — the guard
      // coalesces concurrent callers, it does not cache the result.
      token = 'token-2';
      await service.registerDevice();

      expect(api.postEndpoints, ['register-device']);
      expect(api.patchEndpoints, ['update-device']);
    });

    test('a failed registration releases the guard', () async {
      final api = SlowFakeApiClient();
      String? token;
      final service = DeviceService(
        api,
        const PushFireConfig(apiKey: 'test', baseUrl: 'http://test/'),
        isPushNotificationEnabledOverride: () async => true,
        getDeviceInfoOverride: () async => _deviceInfo,
        getFcmTokenOverride: () async => token,
      );

      // No FCM token yet — registration fails, as it does on a cold iOS start
      // before APNS answers.
      await expectLater(
        service.registerDevice(),
        throwsA(isA<PushFireDeviceException>()),
      );

      // The token arrives via onTokenRefresh. A wedged guard would hand this
      // caller the earlier failure forever.
      token = 'fcm-token';
      final device = await service.registerDevice();

      expect(device.id, isNotNull);
      expect(api.postEndpoints, ['register-device']);
    });

    test('concurrent callers all see the failure', () async {
      final api = SlowFakeApiClient();
      final service = DeviceService(
        api,
        const PushFireConfig(apiKey: 'test', baseUrl: 'http://test/'),
        isPushNotificationEnabledOverride: () async => true,
        getDeviceInfoOverride: () async => _deviceInfo,
        getFcmTokenOverride: () async => null,
      );

      final first = service.registerDevice();
      final second = service.registerDevice();

      await expectLater(first, throwsA(isA<PushFireDeviceException>()));
      await expectLater(second, throwsA(isA<PushFireDeviceException>()));
    });
  });
}
