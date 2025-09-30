# PushFire Flutter SDK

A Flutter SDK for integrating with the PushFire push notification service. This SDK provides easy-to-use APIs for device registration, subscriber management, and tag operations.

## Features

- 🚀 **Automatic Device Registration**: Seamlessly registers devices with FCM tokens
- 👤 **Subscriber Management**: Login, update, and logout subscribers
- 🏷️ **Tag Management**: Add, update, and remove subscriber tags
- 📱 **Cross-Platform**: Works on both iOS and Android
- 🔧 **Configurable**: Customizable API endpoints and settings
- 📊 **Logging**: Built-in logging for debugging
- 🔄 **Event Streams**: Real-time updates via streams
- 🛡️ **Error Handling**: Comprehensive exception handling

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  pushfire_sdk: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Setup

### 1. Firebase Setup

This SDK uses Firebase Cloud Messaging (FCM) for push notifications. You need to:

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add your Android/iOS app to the project
3. Install FlutterFire CLI and configure Firebase:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. This will generate `firebase_options.dart` file with your Firebase configuration
5. Download and add the configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
6. Follow the [FlutterFire setup guide](https://firebase.flutter.dev/docs/overview) for platform-specific configuration

### 2. Platform Configuration

#### Android

Add the following to your `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.google.firebase:firebase-messaging:23.0.0'
}
```

#### iOS

Enable push notifications in your iOS project:

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your project target
3. Go to "Signing & Capabilities"
4. Add "Push Notifications" capability
5. Add "Background Modes" capability and enable "Background processing" and "Remote notifications"

## Usage

### 1. Initialize the SDK

Initialize the SDK in your app's `main()` function:

```dart
import 'package:pushfire_sdk/pushfire_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize PushFire SDK
  await PushFireSDK.initialize(
    PushFireConfig(
      apiKey: 'your-api-key-here',
      baseUrl: 'https://api.pushfire.com', // Optional: defaults to production
      enableLogging: true, // Optional: enable for debugging
      timeoutSeconds: 30, // Optional: request timeout
      authProvider: AuthProvider.firebase, // Optional: authentication provider
    ),
  );
  
  runApp(MyApp());
}
```

### 2. Authentication Provider Integration

The PushFire SDK supports automatic subscriber management through authentication providers. When configured, the SDK automatically handles subscriber login/logout based on the user's authentication state.

#### Supported Authentication Providers

- **Firebase Authentication** (`AuthProvider.firebase`)
- **Supabase Authentication** (`AuthProvider.supabase`)  
- **None** (`AuthProvider.none`) - Default, manual subscriber management

#### Firebase Authentication Integration

```dart
await PushFireSDK.initialize(
  PushFireConfig(
    apiKey: 'your-api-key-here',
    authProvider: AuthProvider.firebase,
  ),
);
```

When Firebase Authentication is configured:
- The SDK automatically listens for `authStateChanges()` from `FirebaseAuth.instance`
- When a user signs in, the SDK automatically calls `loginSubscriber()` with:
  - `externalId`: User's UID
  - `email`: User's email (if available)
  - `name`: User's display name or 'Guest' if not available
  - `phone`: User's phone number (if available)
- When a user signs out, the SDK automatically calls `logoutSubscriber()`

#### Supabase Authentication Integration

```dart
await PushFireSDK.initialize(
  PushFireConfig(
    apiKey: 'your-api-key-here',
    authProvider: AuthProvider.supabase,
  ),
);
```

When Supabase Authentication is configured:
- The SDK automatically listens for `onAuthStateChange` events from `Supabase.instance.client.auth`
- When a user signs in (`AuthChangeEvent.signedIn`), the SDK automatically calls `loginSubscriber()` with:
  - `externalId`: User's ID
  - `email`: User's email (if available)
  - `name`: User's full_name from metadata or 'Guest' if not available
  - `phone`: User's phone number (if available)
- When a user signs out (`AuthChangeEvent.signedOut`), the SDK automatically calls `logoutSubscriber()`

#### Manual Subscriber Management

```dart
await PushFireSDK.initialize(
  PushFireConfig(
    apiKey: 'your-api-key-here',
    authProvider: AuthProvider.none, // Default
  ),
);
```

When no authentication provider is configured, you must manually manage subscribers using the SDK methods.

### 3. Subscriber Management

#### Login/Register a Subscriber

```dart
try {
  final subscriber = await PushFireSDK.instance.loginSubscriber(
    externalId: 'user123', // Your user ID
    name: 'John Doe',
    email: 'john@example.com',
    phone: '+1234567890',
  );
  
  print('Subscriber logged in: ${subscriber.id}');
} catch (e) {
  print('Login failed: $e');
}
```

#### Update Subscriber

```dart
try {
  final updatedSubscriber = await PushFireSDK.instance.updateSubscriber(
    name: 'John Smith',
    email: 'johnsmith@example.com',
  );
  
  print('Subscriber updated: ${updatedSubscriber.name}');
} catch (e) {
  print('Update failed: $e');
}
```

#### Logout Subscriber

```dart
try {
  await PushFireSDK.instance.logoutSubscriber();
  print('Subscriber logged out');
} catch (e) {
  print('Logout failed: $e');
}
```

#### Check Subscriber Status

```dart
// Check if subscriber is logged in
final isLoggedIn = await PushFireSDK.instance.isSubscriberLoggedIn();

// Get current subscriber
final subscriber = await PushFireSDK.instance.getCurrentSubscriber();
if (subscriber != null) {
  print('Current subscriber: ${subscriber.name}');
}
```

### 3. Tag Management

#### Add Tags

```dart
// Add single tag
try {
  final tag = await PushFireSDK.instance.addTag('user_type', 'premium');
  print('Tag added: ${tag.tagId} = ${tag.value}');
} catch (e) {
  print('Failed to add tag: $e');
}

// Add multiple tags
try {
  final tags = await PushFireSDK.instance.addTags({
    'user_type': 'premium',
    'subscription_plan': 'yearly',
    'region': 'us-west',
  });
  
  print('Added ${tags.length} tags');
} catch (e) {
  print('Failed to add tags: $e');
}
```

#### Update Tags

```dart
// Update single tag
try {
  final tag = await PushFireSDK.instance.updateTag('user_type', 'enterprise');
  print('Tag updated: ${tag.tagId} = ${tag.value}');
} catch (e) {
  print('Failed to update tag: $e');
}

// Update multiple tags
try {
  final tags = await PushFireSDK.instance.updateTags({
    'user_type': 'enterprise',
    'subscription_plan': 'monthly',
  });
  
  print('Updated ${tags.length} tags');
} catch (e) {
  print('Failed to update tags: $e');
}
```

#### Remove Tags

```dart
// Remove single tag
try {
  await PushFireSDK.instance.removeTag('user_type');
  print('Tag removed');
} catch (e) {
  print('Failed to remove tag: $e');
}

// Remove multiple tags
try {
  await PushFireSDK.instance.removeTags(['user_type', 'region']);
  print('Tags removed');
} catch (e) {
  print('Failed to remove tags: $e');
}
```

### 4. Workflow Execution

Execute automated workflows for targeted push notifications:

#### Create Immediate Workflow

```dart
// Execute workflow immediately for specific subscribers
try {
  await PushFireSDK.instance.createImmediateWorkflowForSubscribers(
    workflowId: 'welcome-series',
    subscriberIds: ['sub1', 'sub2', 'sub3'],
  );
  print('Workflow executed for subscribers');
} catch (e) {
  print('Workflow execution failed: $e');
}

// Execute workflow immediately for segments
try {
  await PushFireSDK.instance.createImmediateWorkflowForSegments(
    workflowId: 'promotion-campaign',
    segmentIds: ['premium-users', 'active-users'],
  );
  print('Workflow executed for segments');
} catch (e) {
  print('Workflow execution failed: $e');
}
```

#### Create Scheduled Workflow

```dart
// Schedule workflow for future execution
final scheduledFor = DateTime.now().add(Duration(hours: 2));

try {
  await PushFireSDK.instance.createScheduledWorkflowForSubscribers(
    workflowId: 'reminder-series',
    subscriberIds: ['sub1', 'sub2'],
    scheduledFor: scheduledFor,
  );
  print('Workflow scheduled for subscribers');
} catch (e) {
  print('Workflow scheduling failed: $e');
}

try {
  await PushFireSDK.instance.createScheduledWorkflowForSegments(
    workflowId: 'weekly-digest',
    segmentIds: ['newsletter-subscribers'],
    scheduledFor: scheduledFor,
  );
  print('Workflow scheduled for segments');
} catch (e) {
  print('Workflow scheduling failed: $e');
}
```

#### Advanced Workflow Execution

```dart
// Create custom workflow execution request
final request = WorkflowExecutionRequest(
  workflowId: 'custom-workflow',
  type: WorkflowExecutionType.scheduled,
  scheduledFor: DateTime.now().add(Duration(days: 1)),
  target: WorkflowTarget(
    type: WorkflowTargetType.subscribers,
    values: ['sub1', 'sub2'],
  ),
);

try {
  await PushFireSDK.instance.createWorkflowExecution(request);
  print('Custom workflow execution created');
} catch (e) {
  print('Custom workflow execution failed: $e');
}
```

### 5. Device Information

```dart
// Get current device
final device = PushFireSDK.instance.currentDevice;
if (device != null) {
  print('Device ID: ${device.id}');
  print('FCM Token: ${device.fcmToken}');
  print('OS: ${device.os} ${device.osVersion}');
}

// Get device ID
final deviceId = await PushFireSDK.instance.getDeviceId();
print('Device ID: $deviceId');

// Get subscriber ID
final subscriberId = await PushFireSDK.instance.getSubscriberId();
print('Subscriber ID: $subscriberId');
```

### 6. Event Streams

Listen to real-time events:

```dart
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription _deviceSubscription;
  late StreamSubscription _subscriberSubscription;
  late StreamSubscription _fcmSubscription;
  
  @override
  void initState() {
    super.initState();
    _setupEventListeners();
  }
  
  void _setupEventListeners() {
    // Listen to device registration events
    _deviceSubscription = PushFireSDK.instance.onDeviceRegistered.listen(
      (device) {
        print('Device registered: ${device.id}');
      },
    );
    
    // Listen to subscriber login events
    _subscriberSubscription = PushFireSDK.instance.onSubscriberLoggedIn.listen(
      (subscriber) {
        print('Subscriber logged in: ${subscriber.name}');
      },
    );
    
    // Listen to FCM token refresh events
    _fcmSubscription = PushFireSDK.instance.onFcmTokenRefresh.listen(
      (token) {
        print('FCM token refreshed: $token');
      },
    );
  }
  
  @override
  void dispose() {
    _deviceSubscription.cancel();
    _subscriberSubscription.cancel();
    _fcmSubscription.cancel();
    super.dispose();
  }
  
  // ... rest of your widget
}
```

### 7. Error Handling

The SDK provides specific exception types for different error scenarios:

```dart
try {
  await PushFireSDK.instance.loginSubscriber(externalId: 'user123');
} on PushFireNotInitializedException {
  print('SDK not initialized');
} on PushFireSubscriberException catch (e) {
  print('Subscriber error: ${e.message}');
} on PushFireApiException catch (e) {
  print('API error: ${e.message} (${e.statusCode})');
} on PushFireNetworkException catch (e) {
  print('Network error: ${e.message}');
} catch (e) {
  print('Unknown error: $e');
}
```

### 8. Advanced Usage

#### Reset SDK

```dart
// Reset SDK and clear all data
await PushFireSDK.instance.reset();
```

#### Dispose SDK

```dart
// Dispose SDK resources (call when app is shutting down)
PushFireSDK.dispose();
```

#### Check Initialization Status

```dart
if (PushFireSDK.isInitialized) {
  print('SDK is ready to use');
} else {
  print('SDK needs to be initialized');
}
```

## Configuration Options

### PushFireConfig

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `apiKey` | String | Yes | - | Your PushFire API key |
| `baseUrl` | String | No | `https://jojnoebcqoqjlshwzmjm.supabase.co/functions/v1/` | API base URL |
| `enableLogging` | bool | No | `false` | Enable debug logging |
| `timeoutSeconds` | int | No | `30` | Request timeout in seconds |
| `authProvider` | AuthProvider | No | `AuthProvider.none` | Authentication provider for automatic subscriber management |

## Error Types

- `PushFireException` - Base exception class
- `PushFireApiException` - API-related errors
- `PushFireNotInitializedException` - SDK not initialized
- `PushFireConfigurationException` - Configuration errors
- `PushFireDeviceException` - Device registration errors
- `PushFireSubscriberException` - Subscriber operation errors
- `PushFireTagException` - Tag operation errors
- `PushFireNetworkException` - Network connectivity errors

## Best Practices

1. **Initialize Early**: Call `PushFireSDK.initialize()` as early as possible in your app lifecycle
2. **Handle Errors**: Always wrap SDK calls in try-catch blocks
3. **Check Status**: Use `isSubscriberLoggedIn()` before performing subscriber operations
4. **Listen to Events**: Use event streams to react to SDK state changes
5. **Dispose Resources**: Call `PushFireSDK.dispose()` when your app shuts down
6. **Enable Logging**: Use `enableLogging: true` during development for debugging

## Troubleshooting

### Common Issues

1. **SDK Not Initialized**
   - Ensure you call `PushFireSDK.initialize()` before using any other methods
   - Check that initialization completes successfully

2. **Device Registration Fails**
   - Verify Firebase setup is correct
   - Check that FCM is properly configured
   - Ensure device has internet connectivity

3. **API Errors**
   - Verify your API key is correct
   - Check that the base URL is accessible
   - Ensure your PushFire account is active

4. **Subscriber Operations Fail**
   - Make sure a subscriber is logged in before performing operations
   - Verify the external ID is valid

### Debug Logging

Enable logging to see detailed information about SDK operations:

```dart
await PushFireSDK.initialize(
  PushFireConfig(
    apiKey: 'your-api-key',
    enableLogging: true, // Enable this for debugging
  ),
);
```

## Support

For issues and questions:

1. Check the [troubleshooting section](#troubleshooting)
2. Review the [API documentation](https://docs.pushfire.com)
3. Contact support at support@pushfire.com

## License

This project is licensed under the MIT License - see the LICENSE file for details.