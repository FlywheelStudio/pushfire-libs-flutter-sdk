import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pushfire_sdk/src/api/pushfire_api_client.dart';
import 'package:pushfire_sdk/src/config/pushfire_config.dart';
import 'package:pushfire_sdk/src/services/device_service.dart';

/// Reproduction for the permission-change sync bug.
///
/// Symptom (reported on a Samsung device that does NOT kill the app when the
/// user toggles the notification permission in system settings): after the
/// permission changes and the app is brought back to the foreground, PushFire
/// still shows the old value. On a Pixel/emulator the OS kills the app on the
/// permission change, so the working cold-start path runs instead and it looks
/// fine — hence the intermittency.
///
/// These two tests isolate the difference: the SAME permission change is pushed
/// through the resume path vs the cold-start path.
class RecordingApiClient extends PushFireApiClient {
  final List<Map<String, dynamic>> postCalls = [];
  final List<Map<String, dynamic>> patchCalls = [];

  RecordingApiClient()
      : super(const PushFireConfig(apiKey: 'test', baseUrl: 'http://test/'));

  @override
  Future<Map<String, dynamic>> post(
      String endpoint, Map<String, dynamic> data) async {
    postCalls.add({'endpoint': endpoint, 'data': data});
    return {'id': 'device-1'};
  }

  @override
  Future<Map<String, dynamic>> patch(
      String endpoint, Map<String, dynamic> data) async {
    patchCalls.add({'endpoint': endpoint, 'data': data});
    return {'success': true};
  }
}

class PlatformState {
  bool osPermission;
  PlatformState(this.osPermission);
}

const _deviceInfo = {
  'os': 'android',
  'osVersion': '16',
  'language': 'en',
  'manufacturer': 'samsung',
  'model': 'SM-A546E',
  'appVersion': '1.0.0',
};

DeviceService buildService(RecordingApiClient api, PlatformState state) {
  return DeviceService(
    api,
    const PushFireConfig(apiKey: 'test', baseUrl: 'http://test/'),
    isPushNotificationEnabledOverride: () async => state.osPermission,
    getDeviceInfoOverride: () async => _deviceInfo,
    getFcmTokenOverride: () async => 'fcm-token-1',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('CONTROL (cold-start path): OS revoke while app dead -> PATCH false',
      () async {
    final api = RecordingApiClient();
    final state = PlatformState(true); // permission granted at first launch
    final service = buildService(api, state);

    // First launch: registers with enabled = true.
    await service.registerDevice();
    api.postCalls.clear();
    api.patchCalls.clear();

    // Permission revoked while the app was terminated; app relaunches and
    // auto-register runs registerDevice() directly (the init/cold-start path).
    state.osPermission = false;
    await service.registerDevice();

    // Cold-start path correctly syncs the server to disabled.
    expect(api.patchCalls, hasLength(1));
    expect(api.patchCalls.first['endpoint'], 'update-device');
    expect(
      api.patchCalls.first['data']['data']['pushNotificationEnabled'],
      false,
    );
  });

  test(
      'BUG (resume path): OS revoke while app alive -> server should be PATCHed '
      'false but is NOT', () async {
    final api = RecordingApiClient();
    final state = PlatformState(true); // permission granted at first launch
    final service = buildService(api, state);

    // First launch: registers with enabled = true.
    await service.registerDevice();
    api.postCalls.clear();
    api.patchCalls.clear();

    // User toggles the permission OFF in system settings. On a device that does
    // not kill the app, the app is merely resumed, so the SDK reconciles via
    // checkAndHandlePermissionStatusChange() (the same entry point used by the
    // lifecycle observer and syncNotificationPermission()).
    state.osPermission = false;
    await service.checkAndHandlePermissionStatusChange();

    // EXPECTED: the server is told the device is now disabled.
    // ACTUAL (bug): no PATCH is sent, so PushFire keeps showing enabled.
    expect(
      api.patchCalls,
      hasLength(1),
      reason: 'resume path should PATCH update-device with the new value',
    );
    expect(
      api.patchCalls.first['data']['data']['pushNotificationEnabled'],
      false,
    );
  });
}
