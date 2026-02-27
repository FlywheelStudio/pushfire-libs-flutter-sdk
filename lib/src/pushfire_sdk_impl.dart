import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import 'api/pushfire_api_client.dart';
import 'config/pushfire_config.dart';
import 'exceptions/pushfire_exceptions.dart';
import 'models/device.dart';
import 'models/subscriber.dart';
import 'models/subscriber_tag.dart';
import 'models/workflow_execution.dart';
import 'services/device_service.dart';
import 'services/subscriber_service.dart';
import 'services/tag_service.dart';
import 'services/workflow_service.dart';
import 'utils/logger.dart';

/// Main implementation of the PushFire SDK
class PushFireSDKImpl with WidgetsBindingObserver {
  static PushFireSDKImpl? _instance;
  static bool _isInitialized = false;

  late final PushFireConfig _config;
  late final PushFireApiClient _apiClient;
  late final DeviceService _deviceService;
  late final SubscriberService _subscriberService;
  late final TagService _tagService;
  late final WorkflowService _workflowService;

  Device? _currentDevice;
  Subscriber? _currentSubscriber;

  // Stream controllers for events
  final _deviceRegisteredController = StreamController<Device>.broadcast();
  final _subscriberLoggedInController =
      StreamController<Subscriber>.broadcast();
  final _subscriberLoggedOutController = StreamController<void>.broadcast();
  final _fcmTokenRefreshController = StreamController<String>.broadcast();

  // Stream subscriptions that need to be cancelled on dispose
  StreamSubscription<String>? _fcmTokenRefreshSubscription;
  StreamSubscription<sp.AuthState>? _supabaseAuthSubscription;
  StreamSubscription<User?>? _firebaseAuthSubscription;

  // Flag to prevent overlapping permission checks
  bool _isCheckingPermission = false;

  PushFireSDKImpl._();

  /// Get the singleton instance
  static PushFireSDKImpl get instance {
    if (!_isInitialized) {
      throw const PushFireNotInitializedException();
    }
    return _instance!;
  }

  /// Initialize the SDK
  static Future<void> initialize(PushFireConfig config) async {
    if (kIsWeb) {
      debugPrint(
        'PushFire SDK: Web is not supported. '
        'The SDK requires native platform features (FCM, device info, permissions) '
        'that are not available in web browsers. '
        'All SDK calls will be silently ignored.',
      );
      return;
    }

    if (_isInitialized) {
      PushFireLogger.warning('PushFire SDK already initialized');
      return;
    }

    try {
      PushFireLogger.initialize(enableLogging: config.enableLogging);
      PushFireLogger.info('Initializing PushFire SDK');

      _instance = PushFireSDKImpl._();
      await _instance!._initialize(config);

      _isInitialized = true;
      PushFireLogger.info('PushFire SDK initialized successfully');
    } catch (e) {
      PushFireLogger.error('Failed to initialize PushFire SDK', e);
      _instance = null;
      rethrow;
    }
  }

  /// Internal initialization
  Future<void> _initialize(PushFireConfig config) async {
    _config = config;

    // Validate configuration
    if (config.apiKey.isEmpty) {
      throw const PushFireConfigurationException('API key is required');
    }

    if (config.baseUrl.isEmpty) {
      throw const PushFireConfigurationException('Base URL is required');
    }

    // Initialize Firebase if not already initialized
    try {
      await Firebase.initializeApp();
      PushFireLogger.info('Firebase initialized successfully');
    } catch (e) {
      // Firebase might already be initialized, which is fine
      PushFireLogger.info(
          'Firebase already initialized or initialization failed: $e');
    }

    // Initialize services
    _apiClient = PushFireApiClient(config);
    _deviceService = DeviceService(_apiClient, config);
    _subscriberService = SubscriberService(_apiClient, _deviceService);
    _tagService = TagService(_apiClient, _subscriberService);
    _workflowService = WorkflowService(_apiClient);

    // Auto-register device
    await _autoRegisterDevice();

    // Set up FCM token refresh listener
    _setupFcmTokenRefreshListener();

    // Set up app lifecycle observer for permission status monitoring
    _setupAppLifecycleObserver();

    // listen for auth events if using any auth provider
    switch (config.authProvider) {
      case AuthProvider.supabase:
        PushFireLogger.info('Listening for auth state changes');
        // Listen for auth state changes
        _supabaseAuthSubscription =
            sp.Supabase.instance.client.auth.onAuthStateChange
                .listen((data) async {
          final event = data.event;
          final session = data.session;
          // Handle auth state changes if needed
          if ((event == sp.AuthChangeEvent.signedIn ||
                  event == sp.AuthChangeEvent.initialSession ||
                  event == sp.AuthChangeEvent.userUpdated) &&
              session != null) {
            final user = session.user;

            // Skip if already logged in as this user
            final current =
                await _subscriberService.getCurrentSubscriber();
            if (current != null && current.externalId == user.id) {
              PushFireLogger.info(
                  'Subscriber already logged in as ${user.id}, skipping auto-login');
              return;
            }

            final email =
                user.email == null || user.email == '' ? null : user.email;
            final phone =
                user.phone == null || user.phone == '' ? null : user.phone;
            final name = user.userMetadata?['full_name'] == null ||
                    user.userMetadata?['full_name'] == ''
                ? null
                : user.userMetadata?['full_name'];
            loginSubscriber(
                externalId: user.id,
                email: email,
                phone: phone,
                name: name);
          } else if (event == sp.AuthChangeEvent.signedOut) {
            logoutSubscriber();
          }
        });
        break;
      case AuthProvider.firebase:
        PushFireLogger.info('Listening for auth state changes');
        _firebaseAuthSubscription =
            FirebaseAuth.instance.authStateChanges().listen((User? user) async {
          if (user != null) {
            PushFireLogger.info('User signed in: ${user.uid}');

            // Skip if already logged in as this user
            final current =
                await _subscriberService.getCurrentSubscriber();
            if (current != null && current.externalId == user.uid) {
              PushFireLogger.info(
                  'Subscriber already logged in as ${user.uid}, skipping auto-login');
              return;
            }

            final name = user.displayName == null || user.displayName == ''
                ? null
                : user.displayName;
            final email =
                user.email == null || user.email == '' ? null : user.email;
            final phone = user.phoneNumber == null || user.phoneNumber == ''
                ? null
                : user.phoneNumber;
            loginSubscriber(
                externalId: user.uid,
                email: email,
                name: name,
                phone: phone);
          } else {
            PushFireLogger.info('User signed out');
            logoutSubscriber();
          }
        });
        break;
      default:
        break;
    }

    PushFireLogger.info('SDK services initialized');
  }

  /// Auto-register device on initialization
  Future<void> _autoRegisterDevice() async {
    try {
      PushFireLogger.info('Auto-registering device');
      _currentDevice = await _deviceService.registerDevice();
      _deviceRegisteredController.add(_currentDevice!);
      PushFireLogger.info('Device auto-registration completed');
    } catch (e) {
      PushFireLogger.error('Device auto-registration failed', e);
      // Don't throw here - allow SDK to continue working
    }
  }

  /// Set up FCM token refresh listener
  void _setupFcmTokenRefreshListener() {
    _fcmTokenRefreshSubscription =
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        PushFireLogger.info('FCM token refreshed');
        PushFireLogger.logFcmToken(newToken);

        // Check for permission status changes before re-registering
        await _deviceService.checkAndHandlePermissionStatusChange();

        // Re-register device with new token
        _currentDevice = await _deviceService.registerDevice();
        _deviceRegisteredController.add(_currentDevice!);
        _fcmTokenRefreshController.add(newToken);

        PushFireLogger.info('Device updated with new FCM token');
      } catch (e) {
        PushFireLogger.error('Failed to update device with new FCM token', e);
      }
    });
  }

  /// Set up app lifecycle observer to detect permission changes
  void _setupAppLifecycleObserver() {
    try {
      WidgetsBinding.instance.addObserver(this);
      PushFireLogger.info(
          'App lifecycle observer set up for permission monitoring');
    } catch (e) {
      // If WidgetsBinding is not available (e.g., in tests), continue without it
      PushFireLogger.warning('Could not set up app lifecycle observer: $e');
    }
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check for permission status changes when app comes to foreground
      // Use unawaited since this is a synchronous callback, but guard against overlapping calls
      unawaited(_checkPermissionStatusOnResume());
    }
  }

  /// Check permission status when app resumes
  /// This method is safe to call multiple times - it guards against overlapping executions
  Future<void> _checkPermissionStatusOnResume() async {
    // Prevent overlapping calls - if a check is already in progress, skip this one
    if (_isCheckingPermission) {
      PushFireLogger.info(
          'Permission check already in progress - skipping duplicate call');
      return;
    }

    _isCheckingPermission = true;
    try {
      PushFireLogger.info(
          'App resumed - checking notification permission status');
      final updatedDevice =
          await _deviceService.checkAndHandlePermissionStatusChange();

      if (updatedDevice != null) {
        // Device was already re-registered by checkAndHandlePermissionStatusChange
        // Just update the current device reference and emit event
        _currentDevice = updatedDevice;
        _deviceRegisteredController.add(updatedDevice);
        PushFireLogger.info('Device updated after permission status change');
      }
    } catch (e) {
      PushFireLogger.error(
          'Failed to check permission status on app resume', e);
    } finally {
      _isCheckingPermission = false;
    }
  }

  /// Login subscriber
  Future<Subscriber> loginSubscriber({
    required String externalId,
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    try {
      _currentSubscriber = await _subscriberService.loginSubscriber(
        externalId: externalId,
        name: name,
        email: email,
        phone: phone,
        metadata: metadata,
      );

      _subscriberLoggedInController.add(_currentSubscriber!);
      return _currentSubscriber!;
    } catch (e) {
      PushFireLogger.error('Subscriber login failed', e);
      rethrow;
    }
  }

  /// Update subscriber
  Future<Subscriber> updateSubscriber({
    String? name,
    String? email,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    _ensureInitialized();

    final currentSubscriber = await _subscriberService.getCurrentSubscriber();
    if (currentSubscriber?.id == null) {
      throw const PushFireSubscriberException('No subscriber logged in');
    }

    try {
      // Always use current subscriber's externalId (backend doesn't allow updates)
      await _subscriberService.updateSubscriber(
        subscriberId: currentSubscriber!.id!,
        externalId: currentSubscriber.externalId,
        name: name,
        email: email,
        phone: phone,
        metadata: metadata,
      );

      // Update the local subscriber state (externalId remains unchanged)
      _currentSubscriber = currentSubscriber.copyWith(
        name: name,
        email: email,
        phone: phone,
        metadata: metadata,
      );

      // Store updated subscriber data
      await _subscriberService.storeSubscriberData(_currentSubscriber!);

      return _currentSubscriber!;
    } catch (e) {
      PushFireLogger.error('Subscriber update failed', e);
      rethrow;
    }
  }

  /// Logout subscriber
  Future<void> logoutSubscriber() async {
    _ensureInitialized();

    try {
      await _subscriberService.logoutSubscriber();
      _currentSubscriber = null;
      _subscriberLoggedOutController.add(null);
    } catch (e) {
      PushFireLogger.error('Subscriber logout failed', e);
      rethrow;
    }
  }

  /// Add tag to current subscriber
  Future<SubscriberTag> addTag(String tagId, String value) async {
    _ensureInitialized();
    return await _tagService.addTag(tagId, value);
  }

  /// Update tag for current subscriber
  Future<SubscriberTag> updateTag(String tagId, String value) async {
    _ensureInitialized();
    return await _tagService.updateTag(tagId, value);
  }

  /// Remove tag from current subscriber
  Future<void> removeTag(String tagId) async {
    _ensureInitialized();
    return await _tagService.removeTag(tagId);
  }

  /// Add multiple tags
  Future<List<SubscriberTag>> addTags(Map<String, String> tags) async {
    _ensureInitialized();
    return await _tagService.addTags(tags);
  }

  /// Update multiple tags
  Future<List<SubscriberTag>> updateTags(Map<String, String> tags) async {
    _ensureInitialized();
    return await _tagService.updateTags(tags);
  }

  /// Remove multiple tags
  Future<void> removeTags(List<String> tagIds) async {
    _ensureInitialized();
    return await _tagService.removeTags(tagIds);
  }

  // Workflow execution methods

  /// Create a workflow execution
  Future<Map<String, dynamic>> createWorkflowExecution(
    WorkflowExecutionRequest request,
  ) async {
    _ensureInitialized();
    return await _workflowService.createWorkflowExecution(request);
  }

  /// Create an immediate workflow execution for subscribers
  Future<Map<String, dynamic>> createImmediateWorkflowForSubscribers({
    required String workflowId,
    required List<String> subscriberIds,
  }) async {
    _ensureInitialized();
    return await _workflowService.createImmediateWorkflowForSubscribers(
      workflowId: workflowId,
      subscriberIds: subscriberIds,
    );
  }

  /// Create an immediate workflow execution for segments
  Future<Map<String, dynamic>> createImmediateWorkflowForSegments({
    required String workflowId,
    required List<String> segmentIds,
  }) async {
    _ensureInitialized();
    return await _workflowService.createImmediateWorkflowForSegments(
      workflowId: workflowId,
      segmentIds: segmentIds,
    );
  }

  /// Create a scheduled workflow execution for subscribers
  Future<Map<String, dynamic>> createScheduledWorkflowForSubscribers({
    required String workflowId,
    required List<String> subscriberIds,
    required DateTime scheduledFor,
  }) async {
    _ensureInitialized();
    return await _workflowService.createScheduledWorkflowForSubscribers(
      workflowId: workflowId,
      subscriberIds: subscriberIds,
      scheduledFor: scheduledFor,
    );
  }

  /// Create a scheduled workflow execution for segments
  Future<Map<String, dynamic>> createScheduledWorkflowForSegments({
    required String workflowId,
    required List<String> segmentIds,
    required DateTime scheduledFor,
  }) async {
    _ensureInitialized();
    return await _workflowService.createScheduledWorkflowForSegments(
      workflowId: workflowId,
      segmentIds: segmentIds,
      scheduledFor: scheduledFor,
    );
  }

  /// Get current device
  Device? get currentDevice => _currentDevice;

  /// Get current subscriber
  Future<Subscriber?> getCurrentSubscriber() async {
    _ensureInitialized();
    _currentSubscriber ??= await _subscriberService.getCurrentSubscriber();
    return _currentSubscriber;
  }

  /// Check if subscriber is logged in
  Future<bool> isSubscriberLoggedIn() async {
    _ensureInitialized();
    return await _subscriberService.isSubscriberLoggedIn();
  }

  /// Get device ID
  Future<String?> getDeviceId() async {
    _ensureInitialized();
    return await _deviceService.getDeviceId();
  }

  /// Get subscriber ID
  Future<String?> getSubscriberId() async {
    _ensureInitialized();
    return await _subscriberService.getSubscriberId();
  }

  /// Get SDK configuration
  PushFireConfig get config {
    _ensureInitialized();
    return _config;
  }

  /// Manually request notification permissions
  Future<bool> requestNotificationPermission() async {
    _ensureInitialized();
    return await _deviceService.requestNotificationPermission();
  }

  /// Check if SDK is initialized
  static bool get isInitialized => _isInitialized;

  // Event streams

  /// Stream of device registration events
  Stream<Device> get onDeviceRegistered => _deviceRegisteredController.stream;

  /// Stream of subscriber login events
  Stream<Subscriber> get onSubscriberLoggedIn =>
      _subscriberLoggedInController.stream;

  /// Stream of subscriber logout events
  Stream<void> get onSubscriberLoggedOut =>
      _subscriberLoggedOutController.stream;

  /// Stream of FCM token refresh events
  Stream<String> get onFcmTokenRefresh => _fcmTokenRefreshController.stream;

  /// Clear all data and reset SDK
  Future<void> reset() async {
    _ensureInitialized();

    try {
      PushFireLogger.info('Resetting SDK');

      // Logout subscriber if logged in
      if (await isSubscriberLoggedIn()) {
        await logoutSubscriber();
      }

      // Clear device data
      await _deviceService.clearDeviceData();

      // Reset current state
      _currentDevice = null;
      _currentSubscriber = null;

      PushFireLogger.info('SDK reset completed');
    } catch (e) {
      PushFireLogger.error('SDK reset failed', e);
      rethrow;
    }
  }

  /// Dispose SDK resources
  void dispose() {
    if (!_isInitialized) return;

    PushFireLogger.info('Disposing SDK');

    // Remove app lifecycle observer
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (e) {
      // Ignore if observer wasn't added or WidgetsBinding is not available
    }

    // Reset flags
    _isCheckingPermission = false;

    // Cancel stream subscriptions to prevent memory leaks
    _fcmTokenRefreshSubscription?.cancel();
    _fcmTokenRefreshSubscription = null;
    _supabaseAuthSubscription?.cancel();
    _supabaseAuthSubscription = null;
    _firebaseAuthSubscription?.cancel();
    _firebaseAuthSubscription = null;

    _apiClient.dispose();
    _deviceRegisteredController.close();
    _subscriberLoggedInController.close();
    _subscriberLoggedOutController.close();
    _fcmTokenRefreshController.close();

    _instance = null;
    _isInitialized = false;

    PushFireLogger.info('SDK disposed');
  }

  /// Ensure SDK is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      throw const PushFireNotInitializedException();
    }
  }
}
