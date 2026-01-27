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

  const PushFireConfig({
    required this.apiKey,
    this.baseUrl = 'https://jojnoebcqoqjlshwzmjm.supabase.co/functions/v1/',
    this.enableLogging = false,
    this.timeoutSeconds = 30,
    this.authProvider = AuthProvider.none,
    this.requestNotificationPermission = true,
  });

  /// Create a copy of this config with updated values
  PushFireConfig copyWith({
    String? apiKey,
    String? baseUrl,
    bool? enableLogging,
    int? timeoutSeconds,
    AuthProvider? authProvider,
    bool? requestNotificationPermission,
  }) {
    return PushFireConfig(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      enableLogging: enableLogging ?? this.enableLogging,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      authProvider: authProvider ?? this.authProvider,
      requestNotificationPermission:
          requestNotificationPermission ?? this.requestNotificationPermission,
    );
  }

  @override
  String toString() {
    return 'PushFireConfig(baseUrl: $baseUrl, enableLogging: $enableLogging, timeoutSeconds: $timeoutSeconds)';
  }
}

enum AuthProvider { supabase, firebase, none }
