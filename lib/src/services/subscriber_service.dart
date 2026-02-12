import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../api/pushfire_api_client.dart';
import '../exceptions/pushfire_exceptions.dart';
import '../models/subscriber.dart';
import '../utils/logger.dart';
import 'device_service.dart';

/// Service for managing subscriber operations
class SubscriberService {
  final PushFireApiClient _apiClient;
  final DeviceService _deviceService;
  static const String _subscriberIdKey = 'pushfire_subscriber_id';
  static const String _subscriberDataKey = 'pushfire_subscriber_data';

  SubscriberService(this._apiClient, this._deviceService);

  /// Login or register a subscriber
  Future<Subscriber> loginSubscriber({
    required String externalId,
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      PushFireLogger.info('Starting subscriber login: $externalId');

      // Get device ID
      final deviceId = await _deviceService.getDeviceId();
      if (deviceId == null) {
        throw const PushFireSubscriberException(
          'Device not registered. Call registerDevice() first.',
        );
      }

      // Create subscriber data
      final subscriberData = {
        'data': {
          'deviceId': deviceId,
          'externalId': externalId,
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (metadata != null) 'metadata': metadata,
        },
      };

      PushFireLogger.info('Logging in subscriber with data: $subscriberData');

      // Make API call
      final response =
          await _apiClient.post('login-subscriber', subscriberData);

      // Extract subscriber ID from response
      String? subscriberId;
      if (response.containsKey('id')) {
        subscriberId = response['id'] as String;
      } else if (response.containsKey('subscriberId')) {
        subscriberId = response['subscriberId'] as String;
      } else if (response.containsKey('data') && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        subscriberId = data['id'] as String? ?? data['subscriberId'] as String?;
      }

      if (subscriberId == null) {
        throw const PushFireSubscriberException(
          'Subscriber login succeeded but no subscriber ID returned',
        );
      }

      // Create subscriber object
      final subscriber = Subscriber(
        id: subscriberId,
        deviceId: deviceId,
        externalId: externalId,
        name: name,
        email: email,
        phone: phone,
        metadata: metadata,
      );

      // Store subscriber data
      await storeSubscriberData(subscriber);

      PushFireLogger.info('Subscriber login completed: $subscriberId');
      return subscriber;
    } catch (e) {
      PushFireLogger.error('Subscriber login failed', e);
      if (e is PushFireException) {
        rethrow;
      }
      throw PushFireSubscriberException(
        'Subscriber login failed: $e',
        originalError: e,
      );
    }
  }

  /// Update subscriber information
  Future<void> updateSubscriber({
    required String subscriberId,
    required String externalId,
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      PushFireLogger.info('Updating subscriber: $subscriberId');

      // Create update data
      final updateData = {
        'data': {
          'id': subscriberId,
          'externalId': externalId,
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (metadata != null) 'metadata': metadata,
        },
      };

      // Make API call
      await _apiClient.patch('update-subscriber', updateData);

      PushFireLogger.info('Subscriber updated successfully');
    } catch (e) {
      PushFireLogger.error('Subscriber update failed', e);
      if (e is PushFireException) {
        rethrow;
      }
      throw PushFireSubscriberException(
        'Subscriber update failed: $e',
        originalError: e,
      );
    }
  }

  /// Logout current subscriber
  Future<void> logoutSubscriber() async {
    try {
      PushFireLogger.info('Starting subscriber logout');

      // Get current subscriber and device
      final subscriber = await getCurrentSubscriber();
      final deviceId = await _deviceService.getDeviceId();

      if (subscriber?.id == null || deviceId == null) {
        PushFireLogger.warning('No subscriber or device found for logout');
        await _clearSubscriberData();
        return;
      }

      // Make API call
      final logoutData = {
        'data': {
          'deviceId': deviceId,
          'subscriberId': subscriber!.id!,
        },
      };

      await _apiClient.post('logout-subscriber', logoutData);

      // Clear local data
      await _clearSubscriberData();

      PushFireLogger.info('Subscriber logout completed');
    } catch (e) {
      PushFireLogger.error('Subscriber logout failed', e);
      // Clear local data even if API call fails
      await _clearSubscriberData();

      if (e is PushFireException) {
        rethrow;
      }
      throw PushFireSubscriberException(
        'Subscriber logout failed: $e',
        originalError: e,
      );
    }
  }

  /// Get current subscriber from local storage
  Future<Subscriber?> getCurrentSubscriber() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subscriberJson = prefs.getString(_subscriberDataKey);

      if (subscriberJson == null) {
        return null;
      }

      final data = json.decode(subscriberJson) as Map<String, dynamic>;

      return Subscriber.fromJson(data);
    } catch (e) {
      PushFireLogger.warning('Failed to get current subscriber', e);
      return null;
    }
  }

  /// Check if subscriber is logged in
  Future<bool> isSubscriberLoggedIn() async {
    final subscriber = await getCurrentSubscriber();
    return subscriber?.id != null;
  }

  /// Store subscriber data locally
  Future<void> storeSubscriberData(Subscriber subscriber) async {
    final prefs = await SharedPreferences.getInstance();

    if (subscriber.id != null) {
      await prefs.setString(_subscriberIdKey, subscriber.id!);
    }

    // Store as JSON
    await prefs.setString(_subscriberDataKey, json.encode(subscriber.toJson()));
  }

  /// Clear subscriber data from local storage
  Future<void> _clearSubscriberData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_subscriberIdKey);
    await prefs.remove(_subscriberDataKey);
    PushFireLogger.info('Subscriber data cleared');
  }

  /// Get stored subscriber ID
  Future<String?> getSubscriberId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_subscriberIdKey);
  }
}
