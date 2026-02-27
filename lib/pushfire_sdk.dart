library pushfire_sdk;

// Export public API
export 'src/config/pushfire_config.dart';
export 'src/models/device.dart';
export 'src/models/subscriber.dart';
export 'src/models/subscriber_tag.dart';
export 'src/models/workflow_execution.dart';
export 'src/exceptions/pushfire_exceptions.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'src/pushfire_sdk_impl.dart';
import 'src/config/pushfire_config.dart';
import 'src/models/device.dart';
import 'src/models/subscriber.dart';
import 'src/models/subscriber_tag.dart';
import 'src/models/workflow_execution.dart';

/// Main PushFire SDK class
///
/// This is the primary interface for interacting with the PushFire service.
/// Initialize the SDK once at app startup and use the singleton instance
/// for all subsequent operations.
///
/// **Web platform:** The SDK does not support web. All methods will silently
/// no-op and return safe defaults when running in a browser.
///
/// Example usage:
/// ```dart
/// // Initialize SDK
/// await PushFireSDK.initialize(
///   PushFireConfig(
///     apiKey: 'your-api-key',
///     enableLogging: true,
///   ),
/// );
///
/// // Login subscriber
/// await PushFireSDK.instance.loginSubscriber(
///   externalId: '12345',
///   name: 'John Doe',
///   email: 'john@example.com',
/// );
///
/// // Add tags
/// await PushFireSDK.instance.addTag('user_type', 'premium');
/// ```
class PushFireSDK {
  PushFireSDK._();

  /// Initialize the PushFire SDK
  ///
  /// This must be called once before using any other SDK methods.
  /// Typically called in your app's main() function or during app initialization.
  ///
  /// On web, this logs a warning and does nothing.
  ///
  /// [config] - Configuration for the SDK including API key and settings
  ///
  /// Throws [PushFireConfigurationException] if configuration is invalid
  /// Throws [PushFireDeviceException] if device registration fails
  static Future<void> initialize(PushFireConfig config) async {
    await PushFireSDKImpl.initialize(config);
  }

  /// Get the singleton SDK instance
  ///
  /// Throws [PushFireNotInitializedException] if SDK is not initialized
  static PushFireSDK get instance {
    return PushFireSDK._();
  }

  /// Check if the SDK is initialized
  ///
  /// Always returns false on web since the SDK does not support web.
  static bool get isInitialized => !kIsWeb && PushFireSDKImpl.isInitialized;

  // Subscriber methods

  /// Login or register a subscriber
  ///
  /// Returns null on web.
  Future<Subscriber?> loginSubscriber({
    required String externalId,
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    if (kIsWeb) return null;
    return await PushFireSDKImpl.instance.loginSubscriber(
      externalId: externalId,
      name: name,
      email: email,
      phone: phone,
      metadata: metadata,
    );
  }

  /// Update current subscriber information
  ///
  /// Returns null on web.
  Future<Subscriber?> updateSubscriber({
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    if (kIsWeb) return null;
    return await PushFireSDKImpl.instance.updateSubscriber(
      name: name,
      email: email,
      phone: phone,
      metadata: metadata,
    );
  }

  /// Logout current subscriber
  ///
  /// Does nothing on web.
  Future<void> logoutSubscriber() async {
    if (kIsWeb) return;
    await PushFireSDKImpl.instance.logoutSubscriber();
  }

  /// Get current subscriber
  ///
  /// Returns null on web.
  Future<Subscriber?> getCurrentSubscriber() async {
    if (kIsWeb) return null;
    return await PushFireSDKImpl.instance.getCurrentSubscriber();
  }

  /// Check if a subscriber is currently logged in
  ///
  /// Returns false on web.
  Future<bool> isSubscriberLoggedIn() async {
    if (kIsWeb) return false;
    return await PushFireSDKImpl.instance.isSubscriberLoggedIn();
  }

  // Tag methods

  /// Add a tag to the current subscriber
  ///
  /// Returns null on web.
  Future<SubscriberTag?> addTag(String tagId, String value) async {
    if (kIsWeb) return null;
    return await PushFireSDKImpl.instance.addTag(tagId, value);
  }

  /// Update a tag value for the current subscriber
  ///
  /// Returns null on web.
  Future<SubscriberTag?> updateTag(String tagId, String value) async {
    if (kIsWeb) return null;
    return await PushFireSDKImpl.instance.updateTag(tagId, value);
  }

  /// Remove a tag from the current subscriber
  ///
  /// Does nothing on web.
  Future<void> removeTag(String tagId) async {
    if (kIsWeb) return;
    await PushFireSDKImpl.instance.removeTag(tagId);
  }

  /// Add multiple tags at once
  ///
  /// Returns empty list on web.
  Future<List<SubscriberTag>> addTags(Map<String, String> tags) async {
    if (kIsWeb) return [];
    return await PushFireSDKImpl.instance.addTags(tags);
  }

  /// Update multiple tags at once
  ///
  /// Returns empty list on web.
  Future<List<SubscriberTag>> updateTags(Map<String, String> tags) async {
    if (kIsWeb) return [];
    return await PushFireSDKImpl.instance.updateTags(tags);
  }

  /// Remove multiple tags at once
  ///
  /// Does nothing on web.
  Future<void> removeTags(List<String> tagIds) async {
    if (kIsWeb) return;
    await PushFireSDKImpl.instance.removeTags(tagIds);
  }

  // Workflow execution methods

  /// Create a workflow execution
  ///
  /// Returns empty map on web.
  Future<Map<String, dynamic>> createWorkflowExecution(
    WorkflowExecutionRequest request,
  ) async {
    if (kIsWeb) return {};
    return await PushFireSDKImpl.instance.createWorkflowExecution(request);
  }

  /// Create an immediate workflow execution for subscribers
  ///
  /// Returns empty map on web.
  Future<Map<String, dynamic>> createImmediateWorkflowForSubscribers({
    required String workflowId,
    required List<String> subscriberIds,
  }) async {
    if (kIsWeb) return {};
    return await PushFireSDKImpl.instance.createImmediateWorkflowForSubscribers(
      workflowId: workflowId,
      subscriberIds: subscriberIds,
    );
  }

  /// Create an immediate workflow execution for segments
  ///
  /// Returns empty map on web.
  Future<Map<String, dynamic>> createImmediateWorkflowForSegments({
    required String workflowId,
    required List<String> segmentIds,
  }) async {
    if (kIsWeb) return {};
    return await PushFireSDKImpl.instance.createImmediateWorkflowForSegments(
      workflowId: workflowId,
      segmentIds: segmentIds,
    );
  }

  /// Create a scheduled workflow execution for subscribers
  ///
  /// Returns empty map on web.
  Future<Map<String, dynamic>> createScheduledWorkflowForSubscribers({
    required String workflowId,
    required List<String> subscriberIds,
    required DateTime scheduledFor,
  }) async {
    if (kIsWeb) return {};
    return await PushFireSDKImpl.instance.createScheduledWorkflowForSubscribers(
      workflowId: workflowId,
      subscriberIds: subscriberIds,
      scheduledFor: scheduledFor,
    );
  }

  /// Create a scheduled workflow execution for segments
  ///
  /// Returns empty map on web.
  Future<Map<String, dynamic>> createScheduledWorkflowForSegments({
    required String workflowId,
    required List<String> segmentIds,
    required DateTime scheduledFor,
  }) async {
    if (kIsWeb) return {};
    return await PushFireSDKImpl.instance.createScheduledWorkflowForSegments(
      workflowId: workflowId,
      segmentIds: segmentIds,
      scheduledFor: scheduledFor,
    );
  }

  // Device and utility methods

  /// Get current device information
  ///
  /// Returns null on web.
  Device? get currentDevice {
    if (kIsWeb) return null;
    return PushFireSDKImpl.instance.currentDevice;
  }

  /// Get current device ID
  ///
  /// Returns null on web.
  Future<String?> getDeviceId() async {
    if (kIsWeb) return null;
    return await PushFireSDKImpl.instance.getDeviceId();
  }

  /// Get current subscriber ID
  ///
  /// Returns null on web.
  Future<String?> getSubscriberId() async {
    if (kIsWeb) return null;
    return await PushFireSDKImpl.instance.getSubscriberId();
  }

  /// Get SDK configuration
  ///
  /// Returns null on web.
  PushFireConfig? get config {
    if (kIsWeb) return null;
    return PushFireSDKImpl.instance.config;
  }

  /// Manually request notification permissions
  ///
  /// Returns false on web.
  Future<bool> requestNotificationPermission() async {
    if (kIsWeb) return false;
    return await PushFireSDKImpl.instance.requestNotificationPermission();
  }

  // Event streams

  /// Stream of device registration events
  ///
  /// Returns empty stream on web.
  Stream<Device> get onDeviceRegistered {
    if (kIsWeb) return const Stream.empty();
    return PushFireSDKImpl.instance.onDeviceRegistered;
  }

  /// Stream of subscriber login events
  ///
  /// Returns empty stream on web.
  Stream<Subscriber> get onSubscriberLoggedIn {
    if (kIsWeb) return const Stream.empty();
    return PushFireSDKImpl.instance.onSubscriberLoggedIn;
  }

  /// Stream of subscriber logout events
  ///
  /// Returns empty stream on web.
  Stream<void> get onSubscriberLoggedOut {
    if (kIsWeb) return const Stream.empty();
    return PushFireSDKImpl.instance.onSubscriberLoggedOut;
  }

  /// Stream of FCM token refresh events
  ///
  /// Returns empty stream on web.
  Stream<String> get onFcmTokenRefresh {
    if (kIsWeb) return const Stream.empty();
    return PushFireSDKImpl.instance.onFcmTokenRefresh;
  }

  // Advanced methods

  /// Reset SDK and clear all data
  ///
  /// Does nothing on web.
  Future<void> reset() async {
    if (kIsWeb) return;
    await PushFireSDKImpl.instance.reset();
  }

  /// Dispose SDK resources
  ///
  /// Does nothing on web.
  static void dispose() {
    if (kIsWeb) return;
    if (PushFireSDKImpl.isInitialized) {
      PushFireSDKImpl.instance.dispose();
    }
  }
}
