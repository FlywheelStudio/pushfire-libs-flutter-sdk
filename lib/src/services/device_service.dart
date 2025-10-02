import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/pushfire_api_client.dart';
import '../config/pushfire_config.dart';
import '../exceptions/pushfire_exceptions.dart';
import '../models/device.dart';
import '../utils/logger.dart';

/// Service for managing device registration and updates
class DeviceService {
  final PushFireApiClient _apiClient;
  final PushFireConfig _config;
  static const String _deviceIdKey = 'pushfire_device_id';
  static const String _fcmTokenKey = 'pushfire_fcm_token';

  DeviceService(this._apiClient, this._config);

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

      // Create device object
      final device = Device(
        fcmToken: fcmToken,
        os: deviceInfo['os']!,
        osVersion: deviceInfo['osVersion']!,
        language: deviceInfo['language']!,
        manufacturer: deviceInfo['manufacturer']!,
        model: deviceInfo['model']!,
        appVersion: deviceInfo['appVersion']!,
        pushNotificationEnabled: await _isPushNotificationEnabled(),
      );

      PushFireLogger.logDeviceInfo(device.toJson());

      // Check if device is already registered
      final prefs = await SharedPreferences.getInstance();
      final existingDeviceId = prefs.getString(_deviceIdKey);
      final lastFcmToken = prefs.getString(_fcmTokenKey);

      Device registeredDevice;

      if (existingDeviceId != null && lastFcmToken == fcmToken) {
        // Device already registered with same FCM token
        PushFireLogger.info(
            'Device already registered with ID: $existingDeviceId');
        registeredDevice = device.copyWith(id: existingDeviceId);
      } else if (existingDeviceId != null) {
        // Device registered but FCM token changed - update
        PushFireLogger.info('Updating device with new FCM token');
        registeredDevice =
            await _updateDevice(device.copyWith(id: existingDeviceId));
      } else {
        // New device registration
        PushFireLogger.info('Registering new device');
        registeredDevice = await _registerNewDevice(device);
      }

      // Save device info
      await prefs.setString(_deviceIdKey, registeredDevice.id!);
      await prefs.setString(_fcmTokenKey, fcmToken);

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
    try {
      final messaging = FirebaseMessaging.instance;

      // Check current permission status
      var settings = await messaging.getNotificationSettings();
      
      // Request permission if enabled in config and not already authorized
      if (_config.requestNotificationPermission && 
          settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        PushFireLogger.info('Requesting notification permission as configured');
        
        // Platform-specific permission request with appropriate settings
        settings = await _requestPermissionWithPlatformSettings(messaging);
        
        _logPermissionResult(settings.authorizationStatus);
      } else if (!_config.requestNotificationPermission) {
        PushFireLogger.info('Automatic permission request disabled in configuration');
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

  /// Check if push notifications are enabled
  Future<bool> _isPushNotificationEnabled() async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      PushFireLogger.warning('Failed to check push notification status', e);
      return false;
    }
  }

  /// Get device information
  Future<Map<String, String>> _getDeviceInfo() async {
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

  /// Manually request notification permissions
  /// Returns true if permission was granted, false otherwise
  Future<bool> requestNotificationPermission() async {
    try {
      PushFireLogger.info('Manually requesting notification permission');
      final messaging = FirebaseMessaging.instance;
      
      // Use platform-specific permission request
      final settings = await _requestPermissionWithPlatformSettings(messaging);
      
      _logPermissionResult(settings.authorizationStatus);
      
      final isGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
                       settings.authorizationStatus == AuthorizationStatus.provisional;
      
      if (isGranted) {
        PushFireLogger.info('Manual notification permission granted - re-registering device');
        // Re-register device to update permission status
        await registerDevice();
      }
      
      return isGranted;
    } catch (e) {
      PushFireLogger.error('Failed to request notification permission manually', e);
      throw PushFireDeviceException('Failed to request notification permission: $e',
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
    PushFireLogger.info('Device data cleared');
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
      // Android-specific settings (simpler as most are handled by system)
      return await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
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
