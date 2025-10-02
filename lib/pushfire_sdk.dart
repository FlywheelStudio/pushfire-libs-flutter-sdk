library pushfire_sdk;

// Export public API
export 'src/config/pushfire_config.dart';
export 'src/models/device.dart';
export 'src/models/subscriber.dart';
export 'src/models/subscriber_tag.dart';
export 'src/models/workflow_execution.dart';
export 'src/exceptions/pushfire_exceptions.dart';

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
  static bool get isInitialized => PushFireSDKImpl.isInitialized;

  // Subscriber methods

  /// Login or register a subscriber
  ///
  /// [externalId] - Your system's user identifier
  /// [name] - Optional subscriber name
  /// [email] - Optional subscriber email
  /// [phone] - Optional subscriber phone number
  ///
  /// Returns the logged in [Subscriber]
  /// Throws [PushFireSubscriberException] if login fails
  Future<Subscriber> loginSubscriber({
    required String externalId,
    String? name,
    String? email,
    String? phone,
  }) async {
    return await PushFireSDKImpl.instance.loginSubscriber(
      externalId: externalId,
      name: name,
      email: email,
      phone: phone,
    );
  }

  /// Update current subscriber information
  ///
  /// [name] - Updated name
  /// [email] - Updated email
  /// [phone] - Updated phone number
  ///
  /// Returns the updated [Subscriber]
  /// Throws [PushFireSubscriberException] if update fails or no subscriber is logged in
  Future<Subscriber> updateSubscriber({
    String? name,
    String? email,
    String? phone,
  }) async {
    return await PushFireSDKImpl.instance.updateSubscriber(
      name: name,
      email: email,
      phone: phone,
    );
  }

  /// Logout current subscriber
  ///
  /// Throws [PushFireSubscriberException] if logout fails
  Future<void> logoutSubscriber() async {
    await PushFireSDKImpl.instance.logoutSubscriber();
  }

  /// Get current subscriber
  ///
  /// Returns [Subscriber] if logged in, null otherwise
  Future<Subscriber?> getCurrentSubscriber() async {
    return await PushFireSDKImpl.instance.getCurrentSubscriber();
  }

  /// Check if a subscriber is currently logged in
  Future<bool> isSubscriberLoggedIn() async {
    return await PushFireSDKImpl.instance.isSubscriberLoggedIn();
  }

  // Tag methods

  /// Add a tag to the current subscriber
  ///
  /// [tagId] - Unique identifier for the tag
  /// [value] - Tag value
  ///
  /// Returns the created [SubscriberTag]
  /// Throws [PushFireTagException] if operation fails or no subscriber is logged in
  Future<SubscriberTag> addTag(String tagId, String value) async {
    return await PushFireSDKImpl.instance.addTag(tagId, value);
  }

  /// Update a tag value for the current subscriber
  ///
  /// [tagId] - Tag identifier to update
  /// [value] - New tag value
  ///
  /// Returns the updated [SubscriberTag]
  /// Throws [PushFireTagException] if operation fails or no subscriber is logged in
  Future<SubscriberTag> updateTag(String tagId, String value) async {
    return await PushFireSDKImpl.instance.updateTag(tagId, value);
  }

  /// Remove a tag from the current subscriber
  ///
  /// [tagId] - Tag identifier to remove
  ///
  /// Throws [PushFireTagException] if operation fails or no subscriber is logged in
  Future<void> removeTag(String tagId) async {
    await PushFireSDKImpl.instance.removeTag(tagId);
  }

  /// Add multiple tags at once
  ///
  /// [tags] - Map of tag IDs to values
  ///
  /// Returns list of successfully created [SubscriberTag]s
  /// May partially succeed - check logs for individual failures
  Future<List<SubscriberTag>> addTags(Map<String, String> tags) async {
    return await PushFireSDKImpl.instance.addTags(tags);
  }

  /// Update multiple tags at once
  ///
  /// [tags] - Map of tag IDs to new values
  ///
  /// Returns list of successfully updated [SubscriberTag]s
  /// May partially succeed - check logs for individual failures
  Future<List<SubscriberTag>> updateTags(Map<String, String> tags) async {
    return await PushFireSDKImpl.instance.updateTags(tags);
  }

  /// Remove multiple tags at once
  ///
  /// [tagIds] - List of tag IDs to remove
  ///
  /// May partially succeed - check logs for individual failures
  Future<void> removeTags(List<String> tagIds) async {
    await PushFireSDKImpl.instance.removeTags(tagIds);
  }

  // Workflow execution methods

  /// Create a workflow execution
  ///
  /// [request] - The workflow execution request containing all necessary data
  ///
  /// Returns the API response as a Map
  /// Throws [PushFireApiException] if the request fails
  Future<Map<String, dynamic>> createWorkflowExecution(
    WorkflowExecutionRequest request,
  ) async {
    return await PushFireSDKImpl.instance.createWorkflowExecution(request);
  }

  /// Create an immediate workflow execution for subscribers
  ///
  /// [workflowId] - UUID of the workflow to execute
  /// [subscriberIds] - List of subscriber UUIDs to target
  ///
  /// Returns the API response as a Map
  /// Throws [PushFireApiException] if the request fails
  Future<Map<String, dynamic>> createImmediateWorkflowForSubscribers({
    required String workflowId,
    required List<String> subscriberIds,
  }) async {
    return await PushFireSDKImpl.instance.createImmediateWorkflowForSubscribers(
      workflowId: workflowId,
      subscriberIds: subscriberIds,
    );
  }

  /// Create an immediate workflow execution for segments
  ///
  /// [workflowId] - UUID of the workflow to execute
  /// [segmentIds] - List of segment UUIDs to target
  ///
  /// Returns the API response as a Map
  /// Throws [PushFireApiException] if the request fails
  Future<Map<String, dynamic>> createImmediateWorkflowForSegments({
    required String workflowId,
    required List<String> segmentIds,
  }) async {
    return await PushFireSDKImpl.instance.createImmediateWorkflowForSegments(
      workflowId: workflowId,
      segmentIds: segmentIds,
    );
  }

  /// Create a scheduled workflow execution for subscribers
  ///
  /// [workflowId] - UUID of the workflow to execute
  /// [subscriberIds] - List of subscriber UUIDs to target
  /// [scheduledFor] - DateTime when the workflow should be executed
  ///
  /// Returns the API response as a Map
  /// Throws [PushFireApiException] if the request fails
  Future<Map<String, dynamic>> createScheduledWorkflowForSubscribers({
    required String workflowId,
    required List<String> subscriberIds,
    required DateTime scheduledFor,
  }) async {
    return await PushFireSDKImpl.instance.createScheduledWorkflowForSubscribers(
      workflowId: workflowId,
      subscriberIds: subscriberIds,
      scheduledFor: scheduledFor,
    );
  }

  /// Create a scheduled workflow execution for segments
  ///
  /// [workflowId] - UUID of the workflow to execute
  /// [segmentIds] - List of segment UUIDs to target
  /// [scheduledFor] - DateTime when the workflow should be executed
  ///
  /// Returns the API response as a Map
  /// Throws [PushFireApiException] if the request fails
  Future<Map<String, dynamic>> createScheduledWorkflowForSegments({
    required String workflowId,
    required List<String> segmentIds,
    required DateTime scheduledFor,
  }) async {
    return await PushFireSDKImpl.instance.createScheduledWorkflowForSegments(
      workflowId: workflowId,
      segmentIds: segmentIds,
      scheduledFor: scheduledFor,
    );
  }

  // Device and utility methods

  /// Get current device information
  ///
  /// Returns [Device] if registered, null otherwise
  Device? get currentDevice => PushFireSDKImpl.instance.currentDevice;

  /// Get current device ID
  ///
  /// Returns device ID string if available, null otherwise
  Future<String?> getDeviceId() async {
    return await PushFireSDKImpl.instance.getDeviceId();
  }

  /// Get current subscriber ID
  ///
  /// Returns subscriber ID string if logged in, null otherwise
  Future<String?> getSubscriberId() async {
    return await PushFireSDKImpl.instance.getSubscriberId();
  }

  /// Get SDK configuration
  PushFireConfig get config => PushFireSDKImpl.instance.config;

  /// Manually request notification permissions
  ///
  /// This method allows you to request notification permissions at any time,
  /// regardless of the `requestNotificationPermission` configuration setting.
  /// Useful for implementing custom permission request flows.
  ///
  /// Returns true if permission was granted, false otherwise
  /// Throws [PushFireDeviceException] if the request fails
  Future<bool> requestNotificationPermission() async {
    return await PushFireSDKImpl.instance.requestNotificationPermission();
  }

  // Event streams

  /// Stream of device registration events
  ///
  /// Emits [Device] when device is registered or updated
  Stream<Device> get onDeviceRegistered =>
      PushFireSDKImpl.instance.onDeviceRegistered;

  /// Stream of subscriber login events
  ///
  /// Emits [Subscriber] when subscriber logs in
  Stream<Subscriber> get onSubscriberLoggedIn =>
      PushFireSDKImpl.instance.onSubscriberLoggedIn;

  /// Stream of subscriber logout events
  ///
  /// Emits when subscriber logs out
  Stream<void> get onSubscriberLoggedOut =>
      PushFireSDKImpl.instance.onSubscriberLoggedOut;

  /// Stream of FCM token refresh events
  ///
  /// Emits new FCM token when it's refreshed
  Stream<String> get onFcmTokenRefresh =>
      PushFireSDKImpl.instance.onFcmTokenRefresh;

  // Advanced methods

  /// Reset SDK and clear all data
  ///
  /// This will logout the current subscriber and clear all stored data.
  /// Use with caution as this cannot be undone.
  Future<void> reset() async {
    await PushFireSDKImpl.instance.reset();
  }

  /// Dispose SDK resources
  ///
  /// Call this when your app is shutting down to clean up resources.
  /// After calling this, you'll need to initialize the SDK again to use it.
  static void dispose() {
    if (PushFireSDKImpl.isInitialized) {
      PushFireSDKImpl.instance.dispose();
    }
  }
}
