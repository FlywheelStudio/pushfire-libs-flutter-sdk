import 'dart:io';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/pushfire_api_client.dart';
import '../config/pushfire_config.dart';
import '../exceptions/pushfire_exceptions.dart';
import '../models/device.dart';
import '../models/notification_status.dart';
import '../models/set_notification_result.dart';
import '../utils/logger.dart';

/// Service for managing device registration and updates
class DeviceService {
  final PushFireApiClient _apiClient;
  final PushFireConfig _config;
  static const String _deviceIdKey = 'pushfire_device_id';
  static const String _fcmTokenKey = 'pushfire_fcm_token';
  static const String _lastPermissionStatusKey =
      'pushfire_last_permission_status';
  static const String _notificationPreferenceKey =
      'pushfire_notification_preference';

  @visibleForTesting
  final Future<bool> Function()? isPushNotificationEnabledOverride;
  @visibleForTesting
  final Future<Map<String, String>> Function()? getDeviceInfoOverride;
  @visibleForTesting
  final Future<String?> Function()? getFcmTokenOverride;

  DeviceService(this._apiClient, this._config, {
    this.isPushNotificationEnabledOverride,
    this.getDeviceInfoOverride,
    this.getFcmTokenOverride,
  });

  /// Register or update device automatically
  Future<Device> registerDevice() async {
    try {
      PushFireLogger.info('Starting device registration');

      // Get FCM token
      final fcmToken = await _getFcmToken();
      if (fcmToken == null) {
        throw const PushFireDeviceException('Failed to get FCM token');
      }

      // Get device information
      final deviceInfo = await _getDeviceInfo();

      // Compute effective notification state from OS permission and saved preference
      final osPermission = await _isPushNotificationEnabled();
      final savedPreference = await _getSavedNotificationPreference();
      final effectiveEnabled = osPermission && (savedPreference ?? true);

      // Create device object
      final device = Device(
        fcmToken: fcmToken,
        os: deviceInfo['os']!,
        osVersion: deviceInfo['osVersion']!,
        language: deviceInfo['language']!,
        manufacturer: deviceInfo['manufacturer']!,
        model: deviceInfo['model']!,
        appVersion: deviceInfo['appVersion']!,
        pushNotificationEnabled: effectiveEnabled,
      );

      PushFireLogger.logDeviceInfo(device.toJson());

      // Check if device is already registered
      final prefs = await SharedPreferences.getInstance();
      final existingDeviceId = prefs.getString(_deviceIdKey);
      final lastFcmToken = prefs.getString(_fcmTokenKey);
      final lastPermissionStatus = await _getLastPermissionStatus();

      Device registeredDevice;

      if (existingDeviceId != null && lastFcmToken == fcmToken) {
        // Device already registered with same FCM token
        // Check if permission status changed - if so, update device
        if (lastPermissionStatus != null &&
            lastPermissionStatus != device.pushNotificationEnabled) {
          PushFireLogger.info(
              'Device permission status changed - updating device with ID: $existingDeviceId');
          registeredDevice =
              await _updateDevice(device.copyWith(id: existingDeviceId));
        } else {
          PushFireLogger.info(
              'Device already registered with ID: $existingDeviceId');
          registeredDevice = device.copyWith(id: existingDeviceId);
        }
      } else if (existingDeviceId != null) {
        // Device registered but FCM token changed - update
        PushFireLogger.info('Updating device with new FCM token');
        registeredDevice =
            await _updateDevice(device.copyWith(id: existingDeviceId));
      } else {
        // New device registration
        PushFireLogger.info('Registering new device');
        registeredDevice = await _registerNewDevice(device);
        // Save default notification preference on first registration
        await _saveNotificationPreference(true);
      }

      // Save device info
      await prefs.setString(_deviceIdKey, registeredDevice.id!);
      await prefs.setString(_fcmTokenKey, fcmToken);

      // Save current OS permission status (raw, not effective value)
      await _savePermissionStatus(osPermission);

      PushFireLogger.info(
          'Device registration completed: ${registeredDevice.id}');
      return registeredDevice;
    } catch (e) {
      PushFireLogger.error('Device registration failed', e);
      if (e is PushFireException) {
        rethrow;
      }
      throw PushFireDeviceException('Device registration failed: $e',
          originalError: e);
    }
  }

  /// Register a new device
  Future<Device> _registerNewDevice(Device device) async {
    try {
      final deviceData = {'data': device.toJson()};
      final response = await _apiClient.post('register-device', deviceData);

      // Extract device ID from response
      String? deviceId;
      if (response.containsKey('id')) {
        deviceId = response['id'] as String;
      } else if (response.containsKey('deviceId')) {
        deviceId = response['deviceId'] as String;
      } else if (response.containsKey('data') && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        deviceId = data['id'] as String? ?? data['deviceId'] as String?;
      }

      if (deviceId == null) {
        throw const PushFireDeviceException(
            'Device registration succeeded but no device ID returned');
      }

      return device.copyWith(id: deviceId);
    } catch (e) {
      if (e is PushFireException) {
        rethrow;
      }
      throw PushFireDeviceException('Failed to register device: $e',
          originalError: e);
    }
  }

  /// Update existing device
  Future<Device> _updateDevice(Device device) async {
    try {
      final deviceData = {'data': device.toJson()};
      await _apiClient.patch('update-device', deviceData);
      return device;
    } catch (e) {
      if (e is PushFireException) {
        rethrow;
      }
      throw PushFireDeviceException('Failed to update device: $e',
          originalError: e);
    }
  }

  /// Get FCM token
  Future<String?> _getFcmToken() async {
    if (getFcmTokenOverride != null) {
      return getFcmTokenOverride!();
    }
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission if enabled in config
      if (_config.requestNotificationPermission) {
        // For Android 13+ (API 33+), use permission_handler for accurate checking
        if (Platform.isAndroid) {
          final isAndroid13Plus = await _isAndroid13OrHigher();
          if (isAndroid13Plus) {
            final permissionStatus = await Permission.notification.status;
            PushFireLogger.info(
                'Android 13+ notification permission status: $permissionStatus');

            // Request permission if not granted
            if (!permissionStatus.isGranted) {
              PushFireLogger.info(
                  'Requesting notification permission on Android 13+');
              final result = await Permission.notification.request();
              PushFireLogger.info(
                  'Android 13+ permission request result: $result');

              if (result.isGranted) {
                PushFireLogger.info(
                    'Notification permission granted on Android 13+');
              } else if (result.isPermanentlyDenied) {
                PushFireLogger.warning(
                    'Notification permission permanently denied on Android 13+');
              } else {
                PushFireLogger.warning(
                    'Notification permission denied on Android 13+');
              }
            } else {
              PushFireLogger.info(
                  'Notification permission already granted on Android 13+');
            }
          } else {
            // For older Android versions, use Firebase Messaging
            await _requestPermissionWithFirebaseMessaging(messaging);
          }
        } else {
          // For iOS, use Firebase Messaging
          await _requestPermissionWithFirebaseMessaging(messaging);
        }
      } else {
        PushFireLogger.info(
            'Automatic permission request disabled in configuration');
      }

      // Get token regardless of permission status (for manual permission grants)
      final token = await messaging.getToken();
      if (token != null) {
        PushFireLogger.logFcmToken(token);
      }

      return token;
    } catch (e) {
      PushFireLogger.error('Failed to get FCM token', e);
      return null;
    }
  }

  /// Request permission using Firebase Messaging (for iOS and older Android)
  Future<void> _requestPermissionWithFirebaseMessaging(
      FirebaseMessaging messaging) async {
    try {
      var settings = await messaging.getNotificationSettings();

      final shouldRequest =
          settings.authorizationStatus == AuthorizationStatus.notDetermined;

      if (shouldRequest) {
        PushFireLogger.info(
            'Requesting notification permission via Firebase Messaging (status: ${settings.authorizationStatus})');

        settings = await _requestPermissionWithPlatformSettings(messaging);
        _logPermissionResult(settings.authorizationStatus);
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        PushFireLogger.info('Notification permission already granted');
      } else {
        PushFireLogger.info(
            'Notification permission status: ${settings.authorizationStatus} - not requesting');
      }
    } catch (e) {
      PushFireLogger.error(
          'Failed to request permission via Firebase Messaging', e);
    }
  }

  /// Check if push notifications are enabled
  Future<bool> _isPushNotificationEnabled() async {
    if (isPushNotificationEnabledOverride != null) {
      return isPushNotificationEnabledOverride!();
    }
    try {
      // For Android 13+ (API 33+), use permission_handler for accurate status
      if (Platform.isAndroid) {
        final isAndroid13Plus = await _isAndroid13OrHigher();
        if (isAndroid13Plus) {
          final status = await Permission.notification.status;
          PushFireLogger.info(
              'Android 13+ notification permission status: $status');
          return status.isGranted;
        }
      }

      // For iOS and older Android versions, use Firebase Messaging
      // Both 'authorized' and 'provisional' are considered enabled
      // (provisional is iOS-specific and allows quiet notifications)
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      PushFireLogger.warning('Failed to check push notification status', e);
      return false;
    }
  }

  /// Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
    if (getDeviceInfoOverride != null) {
      return getDeviceInfoOverride!();
    }
    final deviceInfoPlugin = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return {
        'os': 'android',
        'osVersion': androidInfo.version.release,
        'language': Platform.localeName,
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'appVersion': packageInfo.version,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfoPlugin.iosInfo;
      return {
        'os': 'ios',
        'osVersion': iosInfo.systemVersion,
        'language': Platform.localeName,
        'manufacturer': 'Apple',
        'model': iosInfo.model,
        'appVersion': packageInfo.version,
      };
    } else {
      throw const PushFireDeviceException('Unsupported platform');
    }
  }

  /// Check if Android version requires runtime permission (API 33+)
  Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;
      return androidInfo.version.sdkInt >= 33;
    } catch (e) {
      PushFireLogger.warning('Failed to check Android version', e);
      return false;
    }
  }

  /// Manually request notification permissions
  /// Returns true if permission was granted, false otherwise
  Future<bool> requestNotificationPermission() async {
    try {
      PushFireLogger.info('Manually requesting notification permission');

      bool isGranted = false;

      // For Android 13+ (API 33+), use permission_handler
      if (Platform.isAndroid) {
        final isAndroid13Plus = await _isAndroid13OrHigher();
        if (isAndroid13Plus) {
          PushFireLogger.info(
              'Requesting notification permission on Android 13+ using permission_handler');
          final status = await Permission.notification.request();
          isGranted = status.isGranted;

          PushFireLogger.info(
              'Android 13+ permission request result: $status (granted: $isGranted)');

          if (status.isPermanentlyDenied) {
            PushFireLogger.warning(
                'Notification permission permanently denied - user needs to enable in settings');
          }
        } else {
          // For older Android versions, use Firebase Messaging
          final messaging = FirebaseMessaging.instance;
          final settings =
              await _requestPermissionWithPlatformSettings(messaging);
          _logPermissionResult(settings.authorizationStatus);
          isGranted = settings.authorizationStatus ==
                  AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;
        }
      } else {
        // For iOS, use Firebase Messaging
        final messaging = FirebaseMessaging.instance;
        final settings =
            await _requestPermissionWithPlatformSettings(messaging);
        _logPermissionResult(settings.authorizationStatus);
        isGranted =
            settings.authorizationStatus == AuthorizationStatus.authorized ||
                settings.authorizationStatus == AuthorizationStatus.provisional;
      }

      if (isGranted) {
        PushFireLogger.info(
            'Manual notification permission granted - re-registering device');
        // Re-register device to update permission status
        await registerDevice();
      }

      return isGranted;
    } catch (e) {
      PushFireLogger.error(
          'Failed to request notification permission manually', e);
      throw PushFireDeviceException(
          'Failed to request notification permission: $e',
          originalError: e);
    }
  }

  /// Set the notification preference for this device.
  ///
  /// - If [enabled] is true and OS permission is denied, returns
  ///   [SetNotificationResult.systemPermissionDenied] without making a server call.
  /// - If [enabled] is false, always saves and PATCHes the server.
  /// - Short-circuits if the preference already matches (except when enabling
  ///   with OS permission denied — always returns systemPermissionDenied).
  ///
  /// Throws [PushFireDeviceException] if no device is registered.
  Future<SetNotificationResult> setNotificationEnabled(bool enabled) async {
    try {
      PushFireLogger.info('Setting notification enabled: $enabled');

      // Check OS permission first when enabling
      if (enabled) {
        final osPermission = await _isPushNotificationEnabled();
        if (!osPermission) {
          PushFireLogger.warning(
              'Cannot enable notifications - OS permission is denied');
          return SetNotificationResult.systemPermissionDenied;
        }
      }

      // Short-circuit if preference already matches
      final currentPreference = await _getSavedNotificationPreference();
      if (currentPreference == enabled) {
        PushFireLogger.info(
            'Notification preference already set to $enabled - no change needed');
        return SetNotificationResult.success;
      }

      // Get device ID — required for PATCH
      final deviceId = await getDeviceId();
      if (deviceId == null) {
        throw const PushFireDeviceException(
            'Cannot set notification preference - no device registered');
      }

      // Save preference locally first
      await _saveNotificationPreference(enabled);

      // PATCH server
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString(_fcmTokenKey);
      if (fcmToken == null) {
        throw const PushFireDeviceException(
            'Cannot set notification preference - no FCM token available');
      }

      final deviceInfo = await _getDeviceInfo();
      final device = Device(
        id: deviceId,
        fcmToken: fcmToken,
        os: deviceInfo['os']!,
        osVersion: deviceInfo['osVersion']!,
        language: deviceInfo['language']!,
        manufacturer: deviceInfo['manufacturer']!,
        model: deviceInfo['model']!,
        appVersion: deviceInfo['appVersion']!,
        pushNotificationEnabled: enabled,
      );

      await _updateDevice(device);

      PushFireLogger.info('Notification preference updated to $enabled');
      return SetNotificationResult.success;
    } catch (e) {
      PushFireLogger.error('Failed to set notification enabled', e);
      if (e is PushFireException) {
        rethrow;
      }
      throw PushFireDeviceException(
          'Failed to set notification preference: $e',
          originalError: e);
    }
  }

  /// Get the current notification status.
  ///
  /// Returns OS-level permission and the PushFire preference.
  /// Does not require a registered device — reads OS permission directly
  /// and saved preference from SharedPreferences.
  Future<NotificationStatus> getNotificationStatus() async {
    try {
      final osPermission = await _isPushNotificationEnabled();
      final savedPreference = await _getSavedNotificationPreference();
      return NotificationStatus(
        isPermissionGranted: osPermission,
        isEnabled: savedPreference ?? true,
      );
    } catch (e) {
      PushFireLogger.error('Failed to get notification status', e);
      if (e is PushFireException) rethrow;
      throw PushFireDeviceException('Failed to get notification status: $e',
          originalError: e);
    }
  }

  /// Get stored device ID
  Future<String?> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceIdKey);
  }

  /// Clear device data from local storage
  Future<void> clearDeviceData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
    await prefs.remove(_fcmTokenKey);
    await prefs.remove(_lastPermissionStatusKey);
    await prefs.remove(_notificationPreferenceKey);
    PushFireLogger.info('Device data cleared');
  }

  /// Check for permission status changes and handle based on saved preference.
  ///
  /// - OS revoked: always PATCH server false
  /// - OS re-granted + saved preference true: PATCH server true (restore)
  /// - OS re-granted + saved preference false: do nothing (dev opted out)
  /// - No change: do nothing
  ///
  /// Returns the registered Device if server was updated, null otherwise.
  Future<Device?> checkAndHandlePermissionStatusChange() async {
    try {
      final currentOsPermission = await _isPushNotificationEnabled();
      final lastOsPermission = await _getLastPermissionStatus();

      // If we don't have a last status, save current and return
      if (lastOsPermission == null) {
        await _savePermissionStatus(currentOsPermission);
        return null;
      }

      // No change in OS permission — do nothing
      if (lastOsPermission == currentOsPermission) {
        return null;
      }

      // OS permission changed — save the new OS status
      await _savePermissionStatus(currentOsPermission);

      if (!currentOsPermission) {
        // OS permission was revoked — always PATCH server false
        PushFireLogger.info(
            'OS notification permission revoked - updating server to disabled');
        final device = await registerDevice();
        return device;
      } else {
        // OS permission was re-granted — check saved preference
        final savedPreference = await _getSavedNotificationPreference();
        if (savedPreference ?? true) {
          PushFireLogger.info(
              'OS notification permission re-granted and preference is enabled - restoring');
          final device = await registerDevice();
          return device;
        } else {
          PushFireLogger.info(
              'OS notification permission re-granted but preference is disabled - not restoring');
          return null;
        }
      }
    } catch (e) {
      PushFireLogger.error('Failed to check permission status change', e);
      return null;
    }
  }

  /// Get last known permission status
  Future<bool?> _getLastPermissionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_lastPermissionStatusKey);
    } catch (e) {
      PushFireLogger.warning('Failed to get last permission status', e);
      return null;
    }
  }

  /// Save current permission status
  Future<void> _savePermissionStatus(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_lastPermissionStatusKey, enabled);
    } catch (e) {
      PushFireLogger.warning('Failed to save permission status', e);
    }
  }

  /// Get saved notification preference (developer-set value)
  Future<bool?> _getSavedNotificationPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationPreferenceKey);
    } catch (e) {
      PushFireLogger.warning('Failed to get saved notification preference', e);
      return null;
    }
  }

  /// Save notification preference
  Future<void> _saveNotificationPreference(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationPreferenceKey, enabled);
    } catch (e) {
      PushFireLogger.warning('Failed to save notification preference', e);
    }
  }

  /// Request permission with platform-specific settings
  Future<NotificationSettings> _requestPermissionWithPlatformSettings(
      FirebaseMessaging messaging) async {
    if (Platform.isIOS) {
      // iOS-specific settings with comprehensive permissions
      return await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } else if (Platform.isAndroid) {
      // For Android 13+ (API 33+), we need to ensure the permission dialog appears
      // Firebase Messaging's requestPermission should handle this, but we log for debugging
      final isAndroid13Plus = await _isAndroid13OrHigher();
      if (isAndroid13Plus) {
        PushFireLogger.info(
            'Requesting notification permission on Android 13+ (API 33+)');
      }

      // Android-specific settings (simpler as most are handled by system)
      // Note: For Android 13+, POST_NOTIFICATIONS permission must be declared in AndroidManifest.xml
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (isAndroid13Plus) {
        PushFireLogger.info(
            'Android 13+ permission request completed with status: ${settings.authorizationStatus}');

        // If still denied after request, log a helpful message
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          PushFireLogger.warning(
              'Notification permission denied on Android 13+. '
              'Ensure POST_NOTIFICATIONS permission is declared in AndroidManifest.xml');
        }
      }

      return settings;
    } else {
      // Default fallback for other platforms
      return await messaging.requestPermission();
    }
  }

  /// Log permission request result with appropriate context
  void _logPermissionResult(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        PushFireLogger.info(
            'Notification permission granted - app can receive notifications');
        break;
      case AuthorizationStatus.denied:
        PushFireLogger.warning(
            'Notification permission denied - notifications will not be delivered');
        break;
      case AuthorizationStatus.provisional:
        PushFireLogger.info(
            'Provisional notification permission granted - quiet notifications enabled');
        break;
      case AuthorizationStatus.notDetermined:
        PushFireLogger.info('Notification permission not determined');
        break;
    }
  }
}
