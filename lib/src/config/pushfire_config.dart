/// Configuration class for PushFire SDK
class PushFireConfig {
  /// API key for authentication
  final String apiKey;

  /// Base URL for the PushFire API
  final String baseUrl;

  /// Enable debug logging
  final bool enableLogging;

  /// Timeout for HTTP requests in seconds
  final int timeoutSeconds;

  /// Authentication provider for automatic subscriber management
  final AuthProvider authProvider;

  /// Automatically request notification permission during SDK initialization
  final bool requestNotificationPermission;

  /// iOS only. When [requestNotificationPermission] is false, still trigger
  /// remote-notification registration so an APNS token (and therefore an FCM
  /// token) can be obtained without showing the interruptive permission
  /// dialog.
  ///
  /// This works by requesting *provisional* authorization: the OS calls
  /// `registerForRemoteNotifications` and delivers notifications quietly to
  /// Notification Center without a prompt. Note that provisional authorization
  /// is not the same as "no authorization" — the user can later be asked to
  /// keep or turn off notifications. For a truly authorization-free
  /// registration, call `application.registerForRemoteNotifications()` from
  /// your AppDelegate instead and leave this false.
  ///
  /// No effect on Android or when [requestNotificationPermission] is true.
  final bool iosRegisterWithoutPrompt;

  /// Optional override for how the FCM token is obtained.
  ///
  /// When supplied, the SDK calls this instead of its built-in
  /// FirebaseMessaging logic. Useful as an escape hatch on iOS to plug in an
  /// APNS-aware token fetcher, or in tests. Return null to indicate no token
  /// is available yet (device registration is skipped and retried via
  /// onTokenRefresh).
  final Future<String?> Function()? getFcmTokenOverride;

  const PushFireConfig({
    required this.apiKey,
    this.baseUrl = 'https://api.pushfire.app/functions/v1/',
    this.enableLogging = false,
    this.timeoutSeconds = 30,
    this.authProvider = AuthProvider.none,
    this.requestNotificationPermission = true,
    this.iosRegisterWithoutPrompt = false,
    this.getFcmTokenOverride,
  });

  /// Create a copy of this config with updated values
  PushFireConfig copyWith({
    String? apiKey,
    String? baseUrl,
    bool? enableLogging,
    int? timeoutSeconds,
    AuthProvider? authProvider,
    bool? requestNotificationPermission,
    bool? iosRegisterWithoutPrompt,
    Future<String?> Function()? getFcmTokenOverride,
  }) {
    return PushFireConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      enableLogging: enableLogging ?? this.enableLogging,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      authProvider: authProvider ?? this.authProvider,
      requestNotificationPermission:
          requestNotificationPermission ?? this.requestNotificationPermission,
      iosRegisterWithoutPrompt:
          iosRegisterWithoutPrompt ?? this.iosRegisterWithoutPrompt,
      getFcmTokenOverride: getFcmTokenOverride ?? this.getFcmTokenOverride,
    );
  }

  @override
  String toString() {
    return 'PushFireConfig(baseUrl: $baseUrl, enableLogging: $enableLogging, timeoutSeconds: $timeoutSeconds)';
  }
}

enum AuthProvider { supabase, firebase, none }
