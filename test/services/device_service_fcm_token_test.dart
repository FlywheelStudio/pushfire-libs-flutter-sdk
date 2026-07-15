import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pushfire_sdk/src/api/pushfire_api_client.dart';
import 'package:pushfire_sdk/src/config/pushfire_config.dart';
import 'package:pushfire_sdk/src/exceptions/pushfire_exceptions.dart';
import 'package:pushfire_sdk/src/services/device_service.dart';

/// Fake API client that records calls instead of making HTTP requests.
class FakeApiClient extends PushFireApiClient {
  final List<Map<String, dynamic>> postCalls = [];
  final List<Map<String, dynamic>> patchCalls = [];
  Map<String, dynamic> postResponse = {'id': 'test-device-id'};

  FakeApiClient()
      : super(const PushFireConfig(apiKey: 'test', baseUrl: 'http://test/'));

  @override
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    postCalls.add({'endpoint': endpoint, 'data': data});
    return postResponse;
  }

  @override
  Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> data) async {
    patchCalls.add({'endpoint': endpoint, 'data': data});
    return {'success': true};
  }
}

const _testDeviceInfo = {
  'os': 'ios',
  'osVersion': '17.0',
  'language': 'en',
  'manufacturer': 'Apple',
  'model': 'iPhone',
  'appVersion': '1.0.0',
};

/// Builds a DeviceService that avoids real platform/Firebase calls by stubbing
/// OS permission and device info, but leaves the FCM-token resolution under
/// test. [configOverride] exercises the PushFireConfig.getFcmTokenOverride hook;
/// [constructorOverride] exercises the @visibleForTesting constructor hook.
DeviceService buildService(
  FakeApiClient api, {
  Future<String?> Function()? configOverride,
  Future<String?> Function()? constructorOverride,
}) {
  return DeviceService(
    api,
    PushFireConfig(
      apiKey: 'test',
      baseUrl: 'http://test/',
      getFcmTokenOverride: configOverride,
    ),
    isPushNotificationEnabledOverride: () async => true,
    getDeviceInfoOverride: () async => _testDeviceInfo,
    getFcmTokenOverride: constructorOverride,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FCM token override resolution', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('config.getFcmTokenOverride is used when no constructor override',
        () async {
      final api = FakeApiClient();
      final service = buildService(
        api,
        configOverride: () async => 'config-token',
      );

      final device = await service.registerDevice();

      expect(device.fcmToken, 'config-token');
      expect(api.postCalls, hasLength(1));
      expect(api.postCalls.first['data']['data']['fcmToken'], 'config-token');
    });

    test('constructor override takes precedence over config override',
        () async {
      final api = FakeApiClient();
      final service = buildService(
        api,
        configOverride: () async => 'config-token',
        constructorOverride: () async => 'constructor-token',
      );

      final device = await service.registerDevice();

      expect(device.fcmToken, 'constructor-token');
      expect(
          api.postCalls.first['data']['data']['fcmToken'], 'constructor-token');
    });

    test(
        'registration fails cleanly and skips the server when the override '
        'returns null', () async {
      final api = FakeApiClient();
      final service = buildService(
        api,
        configOverride: () async => null,
      );

      await expectLater(
        service.registerDevice(),
        throwsA(isA<PushFireDeviceException>().having(
          (e) => e.message,
          'message',
          'Failed to get FCM token',
        )),
      );
      // Device must not be registered when there is no token.
      expect(api.postCalls, isEmpty);
      expect(await service.getDeviceId(), isNull);
    });
  });
}
