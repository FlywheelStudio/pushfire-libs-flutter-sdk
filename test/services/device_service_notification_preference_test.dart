import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pushfire_sdk/src/api/pushfire_api_client.dart';
import 'package:pushfire_sdk/src/config/pushfire_config.dart';
import 'package:pushfire_sdk/src/exceptions/pushfire_exceptions.dart';
import 'package:pushfire_sdk/src/models/notification_status.dart';
import 'package:pushfire_sdk/src/models/set_notification_result.dart';
import 'package:pushfire_sdk/src/services/device_service.dart';

/// Fake API client that records calls instead of making HTTP requests
class FakeApiClient extends PushFireApiClient {
  final List<Map<String, dynamic>> postCalls = [];
  final List<Map<String, dynamic>> patchCalls = [];
  Map<String, dynamic> postResponse = {'id': 'test-device-id'};
  Map<String, dynamic> patchResponse = {'success': true};
  bool shouldThrowOnPatch = false;

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
    if (shouldThrowOnPatch) {
      throw const PushFireApiException('Network error', statusCode: 500);
    }
    patchCalls.add({'endpoint': endpoint, 'data': data});
    return patchResponse;
  }
}

/// Mutable platform state for controlling test behavior mid-test
class TestPlatformState {
  bool osPermission;
  TestPlatformState({this.osPermission = true});
}

const _testDeviceInfo = {
  'os': 'ios',
  'osVersion': '17.0',
  'language': 'en',
  'manufacturer': 'Apple',
  'model': 'iPhone',
  'appVersion': '1.0.0',
};

DeviceService createTestService({
  FakeApiClient? apiClient,
  TestPlatformState? platform,
  String? fcmToken = 'test-fcm-token',
}) {
  final api = apiClient ?? FakeApiClient();
  final state = platform ?? TestPlatformState();
  return DeviceService(
    api,
    const PushFireConfig(apiKey: 'test', baseUrl: 'http://test/'),
    isPushNotificationEnabledOverride: () async => state.osPermission,
    getDeviceInfoOverride: () async => _testDeviceInfo,
    getFcmTokenOverride: () async => fcmToken,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('setNotificationEnabled', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns success when disabling notifications', () async {
      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      // Register device first (creates device ID)
      await service.registerDevice();
      apiClient.patchCalls.clear();

      final result = await service.setNotificationEnabled(false);

      expect(result, SetNotificationResult.success);
      expect(apiClient.patchCalls, hasLength(1));
      final patchData = apiClient.patchCalls.first['data']['data'];
      expect(patchData['pushNotificationEnabled'], false);
    });

    test('returns success when re-enabling after disable', () async {
      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      await service.registerDevice();
      await service.setNotificationEnabled(false);
      apiClient.patchCalls.clear();

      final result = await service.setNotificationEnabled(true);

      expect(result, SetNotificationResult.success);
      expect(apiClient.patchCalls, hasLength(1));
      final patchData = apiClient.patchCalls.first['data']['data'];
      expect(patchData['pushNotificationEnabled'], true);
    });

    test('returns systemPermissionDenied when enabling with OS denied',
        () async {
      final platform = TestPlatformState(osPermission: false);
      final apiClient = FakeApiClient();
      final service =
          createTestService(apiClient: apiClient, platform: platform);

      // Register device with OS denied
      await service.registerDevice();
      apiClient.patchCalls.clear();

      final result = await service.setNotificationEnabled(true);

      expect(result, SetNotificationResult.systemPermissionDenied);
      // No server call should be made
      expect(apiClient.patchCalls, isEmpty);
    });

    test('disabling works even when OS permission is denied', () async {
      final platform = TestPlatformState(osPermission: false);
      final apiClient = FakeApiClient();
      final service =
          createTestService(apiClient: apiClient, platform: platform);

      await service.registerDevice();
      apiClient.patchCalls.clear();

      final result = await service.setNotificationEnabled(false);

      expect(result, SetNotificationResult.success);
      expect(apiClient.patchCalls, hasLength(1));
    });

    test('short-circuits when preference already matches', () async {
      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      // Register device — default preference is true
      await service.registerDevice();
      apiClient.patchCalls.clear();

      // Enable when already enabled — should short-circuit
      final result = await service.setNotificationEnabled(true);

      expect(result, SetNotificationResult.success);
      expect(apiClient.patchCalls, isEmpty);
    });

    test('short-circuits disable when already disabled', () async {
      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      await service.registerDevice();
      await service.setNotificationEnabled(false);
      apiClient.patchCalls.clear();

      // Disable again — should short-circuit
      final result = await service.setNotificationEnabled(false);

      expect(result, SetNotificationResult.success);
      expect(apiClient.patchCalls, isEmpty);
    });

    test('throws PushFireDeviceException when no device registered', () async {
      final service = createTestService();
      // Don't register device

      expect(
        () => service.setNotificationEnabled(false),
        throwsA(isA<PushFireDeviceException>()),
      );
    });

    test('saves preference locally even if server call fails', () async {
      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      await service.registerDevice();
      apiClient.shouldThrowOnPatch = true;

      // Should throw but preference should be saved locally
      try {
        await service.setNotificationEnabled(false);
        fail('Expected exception');
      } on PushFireException {
        // Expected
      }

      // Verify preference was saved locally
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pushfire_notification_preference'), false);
    });
  });

  group('getNotificationStatus', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns OS granted + preference true', () async {
      final service = createTestService();
      await service.registerDevice(); // saves default preference true

      final status = await service.getNotificationStatus();

      expect(
          status,
          const NotificationStatus(
              isPermissionGranted: true, isEnabled: true));
    });

    test('returns OS granted + preference false', () async {
      final service = createTestService();
      await service.registerDevice();
      await service.setNotificationEnabled(false);

      final status = await service.getNotificationStatus();

      expect(
          status,
          const NotificationStatus(
              isPermissionGranted: true, isEnabled: false));
    });

    test('returns OS denied + preference true', () async {
      final platform = TestPlatformState(osPermission: false);
      final service = createTestService(platform: platform);
      await service.registerDevice();

      final status = await service.getNotificationStatus();

      expect(
          status,
          const NotificationStatus(
              isPermissionGranted: false, isEnabled: true));
    });

    test('defaults preference to true when no preference saved', () async {
      final service = createTestService();
      // Don't register — no preference saved yet

      final status = await service.getNotificationStatus();

      expect(
          status,
          const NotificationStatus(
              isPermissionGranted: true, isEnabled: true));
    });

    test('works without device registration', () async {
      final service = createTestService();
      // getNotificationStatus should not require a registered device

      final status = await service.getNotificationStatus();

      expect(status.isPermissionGranted, true);
      expect(status.isEnabled, true);
    });
  });

  group('checkAndHandlePermissionStatusChange', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('patches server false when OS permission revoked', () async {
      final platform = TestPlatformState(osPermission: true);
      final apiClient = FakeApiClient();
      final service =
          createTestService(apiClient: apiClient, platform: platform);

      // Register with OS granted
      await service.registerDevice();
      apiClient.patchCalls.clear();
      apiClient.postCalls.clear();

      // Revoke OS permission
      platform.osPermission = false;

      final device = await service.checkAndHandlePermissionStatusChange();

      expect(device, isNotNull);
      expect(device!.pushNotificationEnabled, false);
    });

    test('restores when OS re-granted and preference is true', () async {
      final platform = TestPlatformState(osPermission: true);
      final apiClient = FakeApiClient();
      final service =
          createTestService(apiClient: apiClient, platform: platform);

      // Register with OS granted (preference defaults to true)
      await service.registerDevice();

      // Revoke OS permission
      platform.osPermission = false;
      await service.checkAndHandlePermissionStatusChange();
      apiClient.patchCalls.clear();
      apiClient.postCalls.clear();

      // Re-grant OS permission
      platform.osPermission = true;

      final device = await service.checkAndHandlePermissionStatusChange();

      // Should restore since preference is true
      expect(device, isNotNull);
      expect(device!.pushNotificationEnabled, true);
    });

    test('does NOT restore when OS re-granted but preference is false',
        () async {
      final platform = TestPlatformState(osPermission: true);
      final apiClient = FakeApiClient();
      final service =
          createTestService(apiClient: apiClient, platform: platform);

      // Register, then disable preference
      await service.registerDevice();
      await service.setNotificationEnabled(false);

      // Revoke OS permission
      platform.osPermission = false;
      await service.checkAndHandlePermissionStatusChange();
      apiClient.patchCalls.clear();
      apiClient.postCalls.clear();

      // Re-grant OS permission
      platform.osPermission = true;

      final device = await service.checkAndHandlePermissionStatusChange();

      // Should NOT restore since developer opted out
      expect(device, isNull);
    });

    test('does nothing when no OS permission change', () async {
      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      await service.registerDevice();
      apiClient.patchCalls.clear();
      apiClient.postCalls.clear();

      final device = await service.checkAndHandlePermissionStatusChange();

      expect(device, isNull);
      expect(apiClient.patchCalls, isEmpty);
      expect(apiClient.postCalls, isEmpty);
    });

    test('saves current status and returns null when no previous status',
        () async {
      // Simulate scenario where _lastPermissionStatusKey has no value
      SharedPreferences.setMockInitialValues({
        'pushfire_device_id': 'existing-id',
        'pushfire_fcm_token': 'test-fcm-token',
        // No pushfire_last_permission_status
      });

      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      final device = await service.checkAndHandlePermissionStatusChange();

      expect(device, isNull);

      // Verify it saved the current status
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pushfire_last_permission_status'), true);
    });
  });

  group('registerDevice with preference', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('uses effective value: OS granted + no saved pref = true', () async {
      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      final device = await service.registerDevice();

      expect(device.pushNotificationEnabled, true);
    });

    test('uses effective value: OS denied + no saved pref = false', () async {
      final platform = TestPlatformState(osPermission: false);
      final apiClient = FakeApiClient();
      final service =
          createTestService(apiClient: apiClient, platform: platform);

      final device = await service.registerDevice();

      expect(device.pushNotificationEnabled, false);
    });

    test('uses effective value: OS granted + pref false = false', () async {
      // Pre-set preference to false
      SharedPreferences.setMockInitialValues({
        'pushfire_notification_preference': false,
      });

      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      final device = await service.registerDevice();

      expect(device.pushNotificationEnabled, false);
    });

    test('uses effective value: OS granted + pref true = true', () async {
      SharedPreferences.setMockInitialValues({
        'pushfire_notification_preference': true,
      });

      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      final device = await service.registerDevice();

      expect(device.pushNotificationEnabled, true);
    });

    test('saves raw OS permission, not effective value', () async {
      // Key fix: preference is false, OS is granted
      // effective = true && false = false
      // But saved permission status should be true (raw OS)
      SharedPreferences.setMockInitialValues({
        'pushfire_notification_preference': false,
      });

      final service = createTestService();
      await service.registerDevice();

      final prefs = await SharedPreferences.getInstance();
      // Should save raw OS permission (true), NOT effective value (false)
      expect(prefs.getBool('pushfire_last_permission_status'), true);
    });

    test('saves default preference true on first registration only', () async {
      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      await service.registerDevice();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('pushfire_notification_preference'), true);
    });

    test('does not overwrite existing preference on re-registration', () async {
      // Pre-set preference to false (developer opted out)
      SharedPreferences.setMockInitialValues({
        'pushfire_device_id': 'existing-id',
        'pushfire_fcm_token': 'old-token',
        'pushfire_notification_preference': false,
        'pushfire_last_permission_status': true,
      });

      final apiClient = FakeApiClient();
      final service = createTestService(apiClient: apiClient);

      await service.registerDevice();

      final prefs = await SharedPreferences.getInstance();
      // Should not have overwritten to true
      expect(prefs.getBool('pushfire_notification_preference'), false);
    });
  });

  group('clearDeviceData', () {
    test('clears notification preference key', () async {
      SharedPreferences.setMockInitialValues({
        'pushfire_device_id': 'test-id',
        'pushfire_fcm_token': 'test-token',
        'pushfire_last_permission_status': true,
        'pushfire_notification_preference': false,
      });

      final service = createTestService();
      await service.clearDeviceData();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pushfire_device_id'), isNull);
      expect(prefs.getString('pushfire_fcm_token'), isNull);
      expect(prefs.getBool('pushfire_last_permission_status'), isNull);
      expect(prefs.getBool('pushfire_notification_preference'), isNull);
    });
  });
}
