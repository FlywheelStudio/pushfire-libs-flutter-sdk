# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.5]

### Added
- **GitHub Actions Workflows**: Automated CI/CD pipeline for testing and publishing
  - CI workflow for continuous integration on pushes and PRs
  - Release workflow that automatically publishes to pub.dev when tags are pushed
  - Automatic version management from git tags
  - GitHub Releases creation with release notes

### Technical Implementation
- **Workflow Automation**: 
  - Automated testing, analysis, and dry-run verification
  - OIDC-based authentication for pub.dev publishing
  - Version extraction and file updates from git tags
  - GitHub Releases with installation instructions

## [0.1.4]

### Fixed
- **Memory Leaks**: Fixed stream subscription memory leaks by properly storing and cancelling all subscriptions
  - FCM token refresh listener now properly cancelled on dispose
  - Firebase auth state listener now properly cancelled on dispose
  - Supabase auth state listener now properly cancelled on dispose
- **Race Conditions**: Fixed race condition in app lifecycle permission checking
  - Added guard flag to prevent overlapping permission checks
  - Proper async handling with `unawaited()` for fire-and-forget futures
- **Double Registration**: Fixed redundant device registration when permission status changes
  - `checkAndHandlePermissionStatusChange()` now returns the registered Device directly
  - Eliminates unnecessary API calls when permission changes are detected
- **Permission Status Inconsistency**: Fixed inconsistency between permission checking and requesting
  - `_isPushNotificationEnabled()` now correctly recognizes both `authorized` and `provisional` status
  - Ensures iOS provisional permission is properly registered as enabled
- **Dependency Conflicts**: Fixed `permission_handler` version constraint to support both 11.x and 12.x
  - Updated constraint from `^11.3.1` to `>=11.3.1 <13.0.0`
  - Resolves conflicts with packages requiring `permission_handler` 12.x

### Enhanced
- **Android 13+ Permission Handling**: Improved Android 13+ (API 33+) notification permission support
  - Added `permission_handler` package for accurate permission status checking
  - Proper handling of `POST_NOTIFICATIONS` runtime permission
  - Better detection of permission status on first launch
- **Automatic Permission Detection**: Added automatic detection of permission status changes
  - Monitors app lifecycle to detect when permissions are enabled after being denied
  - Automatically re-registers device when permission status changes from denied to authorized
  - Checks permission status on app resume and FCM token refresh
- **Permission Status Tracking**: Added persistent tracking of permission status
  - Stores last known permission status in SharedPreferences
  - Detects changes from denied to authorized state
  - Automatically updates device registration when permissions are enabled

### Technical Improvements
- **Resource Management**: Proper cleanup of all stream subscriptions and observers
- **Error Handling**: Improved error handling in permission checking flows
- **Code Quality**: Fixed analyzer warnings and followed Dart best practices
- **Platform Support**: Enhanced Android 13+ support with dedicated permission handling

## [0.1.3]

### Added
- **Notification Permission Control**: Flexible notification permission handling for better user experience
  - `requestNotificationPermission` parameter in `PushFireConfig` to control automatic permission requests
  - `requestNotificationPermission()` method for manual permission requests at appropriate times
  - Platform-specific permission handling for iOS, Android, and Web

### Enhanced
- **Permission Management**:
  - Automatic permission request during SDK initialization (default behavior)
  - Option to disable automatic requests for custom UX flows
  - Manual permission request method with boolean return value
  - Automatic device re-registration when permissions are granted manually

- **Platform-Specific Behavior**:
  - iOS: Proper Firebase Messaging permission settings for alerts, badges, and sounds
  - Android: Runtime permission handling for Android 13+ (API level 33+)
  - Web: Browser notification permission requests through Firebase Messaging

- **Developer Experience**:
  - Comprehensive logging for permission request outcomes
  - Graceful handling of permission denial scenarios
  - Device registration continues even without notification permissions
  - Support for manual permission grants through device settings

### Technical Implementation
- **Configuration Options**: Added `requestNotificationPermission` to `PushFireConfig` class
- **Service Enhancement**: Updated `DeviceService` to handle conditional permission requests
- **SDK Interface**: Added public `requestNotificationPermission()` method to main SDK interface
- **Error Handling**: Robust permission status checking and logging

### Documentation
- **README Updates**: Complete notification permission configuration guide
- **Code Examples**: Detailed examples for automatic and manual permission strategies
- **Best Practices**: Guidelines for optimal permission request timing and user experience

## [0.1.2]

### Added
- **Configuration Options**: Enhanced SDK configuration with additional parameters
  - `timeoutSeconds` parameter for API request timeout configuration
  - `enableLogging` parameter for debug logging control

## [0.1.1]

### Added
- **Authentication Provider Integration**: Automatic subscriber management through authentication providers
  - `AuthProvider` enum with support for `firebase`, `supabase`, and `none` options
  - `authProvider` parameter in `PushFireConfig` for configuring authentication integration
  - Automatic subscriber login/logout based on authentication state changes

### Enhanced
- **Firebase Authentication Integration**:
  - Automatic listening for `authStateChanges()` from `FirebaseAuth.instance`
  - Auto-login with user UID as external ID, plus email, display name, and phone number
  - Auto-logout when user signs out of Firebase Authentication

- **Supabase Authentication Integration**:
  - Automatic listening for `onAuthStateChange` events from Supabase client
  - Auto-login with user ID as external ID, plus email, full_name metadata, and phone number
  - Auto-logout when user signs out of Supabase Authentication

- **Configuration Options**:
  - Added `authProvider` parameter to `PushFireConfig` class
  - Defaults to `AuthProvider.none` for manual subscriber management
  - Comprehensive documentation for all authentication provider options

### Technical Implementation
- **Service Integration**: Authentication state listeners integrated into `PushFireSDKImpl`
- **Dependency Management**: Support for both `firebase_auth` and `supabase_flutter` packages
- **Error Handling**: Graceful handling of authentication state changes and edge cases
- **Logging**: Comprehensive logging for authentication events and state changes

### Documentation
- **README Updates**: Complete authentication provider configuration guide
- **Code Examples**: Detailed examples for Firebase, Supabase, and manual configurations
- **Configuration Reference**: Updated configuration options table with `authProvider` parameter

## [0.1.0] 

### Added
- **Workflow Execution API**: Complete workflow execution system with support for immediate and scheduled workflows
  - `createWorkflowExecution()` - Advanced method for custom workflow execution requests
  - `createImmediateWorkflowForSubscribers()` - Execute workflows immediately for specific subscribers
  - `createImmediateWorkflowForSegments()` - Execute workflows immediately for specific segments
  - `createScheduledWorkflowForSubscribers()` - Schedule workflows for future execution targeting subscribers
  - `createScheduledWorkflowForSegments()` - Schedule workflows for future execution targeting segments

- **New Data Models**:
  - `WorkflowExecutionRequest` - Main request model with validation and JSON serialization
  - `WorkflowTarget` - Target configuration supporting subscribers and segments
  - `WorkflowExecutionType` - Enum for immediate vs scheduled execution types
  - `WorkflowTargetType` - Enum for subscriber vs segment targeting

- **Technical Implementation**:
  - New `WorkflowService` class for API integration and request handling
  - Comprehensive input validation including UUID format verification
  - Proper error handling with `PushFireApiException` integration
  - Full logging support for debugging and monitoring

- **Developer Experience**:
  - Updated example application with complete workflow execution demo UI
  - Comprehensive documentation with code examples for all workflow methods
  - Type-safe API with proper Dart null safety support

## 0.0.9

* Downgraded `package_info_plus` dependency to `^8.3.0` to resolve compatibility issues.


## 0.0.8

* Downgraded `firebase_messaging` dependency from `^15.2.8` to `^15.1.0` to resolve compatibility issues with `firebase_core_platform_interface` 5.4.0.

## 0.0.7

* Updated `firebase_messaging` dependency from `^14.7.9` to `^15.2.8` to resolve compatibility issues with `firebase_core` 3.x.

## 0.0.6

### Changed
- Downgraded `firebase_messaging` dependency from `^15.2.9` to `^14.7.9` to resolve `firebase_core_platform_interface` version conflicts

## 0.0.5 - 2025-06-19

### Changed
- Updated `firebase_core` dependency constraint from `^3.15.1` to `'>=3.14.0 <4.0.0'` to resolve version conflicts

## [0.0.4] - 2025-06-19

### Changed
- Updated device_info_plus dependency constraint from ^9.1.1 to '>=9.1.1 <12.0.0' to resolve version conflicts

## [0.0.2] - 2025-06-19
### Changed
- bump firebase_core to 3.8.0


## [0.0.2] - 2025-06-19

### Changed
- Version bump to 0.0.2

## [0.0.1] - 2025-06-10

### Added
- Initial release of PushFire Flutter SDK
- Basic subscriber management functionality
- Device registration with FCM integration
- Tag management capabilities
- Core API client implementation
- Automatic device registration with FCM integration
- Subscriber management (login, update, logout)
- Tag management (add, update, remove single and multiple tags)
- Configurable SDK with custom API endpoints and settings
- Comprehensive error handling with specific exception types
- Event streams for real-time updates
- Built-in logging system for debugging
- Cross-platform support (iOS and Android)
- Complete API coverage for PushFire service

### Features
- **Device Management**
  - Automatic device registration on SDK initialization
  - FCM token management and refresh handling
  - Device information collection (OS, version, manufacturer, etc.)
  - Persistent device storage

- **Subscriber Management**
  - Login/register subscribers with external ID
  - Update subscriber information (name, email, phone)
  - Logout functionality with data cleanup
  - Persistent subscriber storage

- **Tag Management**
  - Add individual tags to subscribers
  - Update existing tag values
  - Remove tags from subscribers
  - Batch operations for multiple tags
  - Error handling for partial failures

- **Configuration**
  - Customizable API base URL
  - API key authentication
  - Configurable request timeouts
  - Debug logging toggle

- **Error Handling**
  - Specific exception types for different error scenarios
  - Network error handling
  - API error handling with status codes
  - Configuration validation

- **Event Streams**
  - Device registration events
  - Subscriber login/logout events
  - FCM token refresh events
  - Real-time status updates

- **Developer Experience**
  - Comprehensive documentation
  - Example application
  - TypeScript-style documentation
  - Best practices guide
  - Troubleshooting guide

### Dependencies
- `flutter`: SDK integration
- `firebase_messaging`: FCM token management
- `http`: API communication
- `device_info_plus`: Device information collection
- `package_info_plus`: App version information
- `shared_preferences`: Local data persistence
- `logging`: Debug logging system

### Platform Support
- iOS 11.0+
- Android API level 21+
- Flutter 3.0.0+
- Dart 3.0.0+

### API Endpoints Covered
- `POST /devices` - Register device
- `PATCH /devices/{id}` - Update device
- `POST /subscribers/login` - Login subscriber
- `PATCH /subscribers/{id}` - Update subscriber
- `POST /subscribers/logout` - Logout subscriber
- `POST /subscribers/tags` - Add subscriber tag
- `PATCH /subscribers/tags` - Update subscriber tag
- `DELETE /subscribers/tags` - Remove subscriber tag

### Security
- API key authentication for all requests
- Secure storage of sensitive data
- No hardcoded credentials
- HTTPS-only communication

### Performance
- Efficient API request batching
- Minimal memory footprint
- Optimized for mobile devices
- Background processing support

[1.0.0]: https://github.com/pushfire/flutter-sdk/releases/tag/v1.0.0
