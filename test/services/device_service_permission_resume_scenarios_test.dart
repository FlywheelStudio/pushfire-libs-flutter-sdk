import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pushfire_sdk/src/api/pushfire_api_client.dart';
import 'package:pushfire_sdk/src/config/pushfire_config.dart';
import 'package:pushfire_sdk/src/services/device_service.dart';

/// End-to-end-ish coverage of the exact scenarios reported on a Samsung device
/// (SM-A546E) that does NOT kill the app when the notification permission is
/// toggled in system settings, so the SDK reconciles via the resume path
/// (checkAndHandlePermissionStatusChange), not a cold start.
///
/// Each test asserts what the server (PushFire) should end up being told.
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

/// The value of pushNotificationEnabled in the most recent PATCH, or null if
/// no PATCH was sent.
bool? lastPatchedEnabled(RecordingApiClient api) {
  if (api.patchCalls.isEmpty) return null;
  return api.patchCalls.last['data']['data']['pushNotificationEnabled']
      as bool?;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'Case 1 — granted, then REVOKED in settings, app resumed -> server denied',
      () async {
    final api = RecordingApiClient();
    final state = PlatformState(true);
    final service = buildService(api, state);

    await service.registerDevice(); // first launch: enabled
    api.patchCalls.clear();

    // User turns notifications OFF in settings; app is resumed (not killed).
    state.osPermission = false;
    await service.checkAndHandlePermissionStatusChange();

    expect(api.patchCalls, hasLength(1));
    expect(lastPatchedEnabled(api), false);
  });

  test('Case 2 — denied, then RE-GRANTED in settings, app resumed -> restored',
      () async {
    final api = RecordingApiClient();
    final state = PlatformState(true);
    final service = buildService(api, state);

    await service.registerDevice(); // enabled
    state.osPermission = false; // revoke
    await service.checkAndHandlePermissionStatusChange();
    api.patchCalls.clear();

    // User turns notifications back ON; app resumed.
    state.osPermission = true;
    await service.checkAndHandlePermissionStatusChange();

    // This is the case that used to stay "denied" in PushFire.
    expect(api.patchCalls, hasLength(1));
    expect(lastPatchedEnabled(api), true);
  });

  test(
      'Case 3 — developer disabled via setNotificationEnabled(false): OS '
      're-grant does NOT restore', () async {
    final api = RecordingApiClient();
    final state = PlatformState(true);
    final service = buildService(api, state);

    await service.registerDevice(); // enabled
    await service.setNotificationEnabled(false); // developer opt-out
    api.patchCalls.clear();

    // OS toggled off then back on while the app is alive.
    state.osPermission = false;
    await service.checkAndHandlePermissionStatusChange();
    state.osPermission = true;
    await service.checkAndHandlePermissionStatusChange();

    // Server must never be flipped back to enabled against the opt-out.
    final anyEnabledPatch = api.patchCalls
        .any((c) => c['data']['data']['pushNotificationEnabled'] == true);
    expect(anyEnabledPatch, isFalse,
        reason: 'developer opt-out must survive an OS re-grant');
  });

  test('Case 4 — app resumed with NO permission change -> no server call',
      () async {
    final api = RecordingApiClient();
    final state = PlatformState(true);
    final service = buildService(api, state);

    await service.registerDevice(); // enabled
    api.patchCalls.clear();
    api.postCalls.clear();

    // Resume, permission unchanged.
    await service.checkAndHandlePermissionStatusChange();

    expect(api.patchCalls, isEmpty);
    expect(api.postCalls, isEmpty);
  });

  test('Case 5 — resuming again after a synced revoke -> no duplicate PATCH',
      () async {
    final api = RecordingApiClient();
    final state = PlatformState(true);
    final service = buildService(api, state);

    await service.registerDevice(); // enabled
    state.osPermission = false;
    await service.checkAndHandlePermissionStatusChange(); // syncs -> denied
    api.patchCalls.clear();

    // App resumed a second time, still denied, nothing changed.
    await service.checkAndHandlePermissionStatusChange();

    expect(api.patchCalls, isEmpty);
  });
}
