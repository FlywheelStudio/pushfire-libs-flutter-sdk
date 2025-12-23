# PushFire SDK Integration Guide for Dreamflow AI

This guide helps developers using **Dreamflow AI** to seamlessly integrate PushFire push notification SDK into their Flutter applications.

---

## Overview

**Dreamflow AI** is an AI-powered app builder that generates complete Flutter applications from natural language prompts. Since Dreamflow generates real, editable Flutter code, you can integrate PushFire SDK in two ways:

1. **AI-Assisted**: Prompt Dreamflow to include PushFire integration during app generation
2. **Manual Post-Export**: Add PushFire to your exported project manually

> [!IMPORTANT]
> **PushFire SDK requires a real device or emulator to function.** The SDK uses Firebase Cloud Messaging (FCM) for push notifications, which does not work in Dreamflow's browser preview. You must export your project and run it on an Android emulator, iOS simulator, or physical device to test push notification functionality.

---

## Prerequisites: Firebase Setup

The PushFire SDK uses **Firebase Cloud Messaging (FCM)** as its backbone to deliver notifications. Before integrating PushFire, you must set up Firebase in your Dreamflow project.

### Step 1: Create a Firebase Project

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter a name for your project (e.g., "MyDreamFlowApp")
4. Follow the on-screen steps — it's recommended to enable Google Analytics
5. Once created, you'll be taken to the project dashboard
6. **Keep this browser tab open** — you'll need it for the next step

### Step 2: Connect Firebase in Dreamflow

Dreamflow has a built-in Firebase integration that makes connecting simple and automatic.

> [!NOTE]
> You must be the **owner** of the Dreamflow project to connect Firebase.

1. In your Dreamflow project sidebar, select **Firebase**
2. Click the **"Connect"** button to link your Firebase account
3. A pop-up will appear — select your Google account
4. Select the Firebase project you just created from the dropdown list
5. Click **"Continue"**

⏱️ **This process may take 2-5 minutes.**

Once complete, you'll see a confirmation message. Click on **"Configure Firebase"**.

Dreamflow will automatically:
- ✅ Add Android and iOS apps to your Firebase project
- ✅ Use your DreamFlow app's Package Name and Bundle ID
- ✅ Generate and link the necessary configuration files:
  - `google-services.json` (Android)
  - `GoogleService-Info.plist` (iOS)

### Step 3: Verify Firebase Connection

After configuration, verify that Firebase is properly connected:

1. In the Firebase Console, go to **Project Settings** → **Your apps**
2. You should see both Android and iOS apps listed
3. In Dreamflow, the Firebase section should show a green "Connected" status

---

## Two Integration Approaches

- **AI-Assisted** — Best for new projects and rapid prototyping (⭐ Low effort)
- **Manual Post-Export** — Best for existing projects and fine-tuned control (⭐⭐ Medium effort)

---

## Approach 1: AI-Assisted Integration (Recommended)

### Step 1: Add Context File to Your Project

Before prompting Dreamflow, add the `llms.txt` context file to your project. This file helps the AI understand how to properly integrate PushFire SDK.

1. Download [`llms.txt`](https://github.com/FlywheelStudio/pushfire_sdk/blob/main/llms.txt) from the PushFire SDK repository
2. Place it in your project's root directory
3. Dreamflow will automatically read it for context

### Step 2: Use These Prompts with Dreamflow

#### 🚀 Basic Integration Prompt

Copy and use this prompt when building your app with Dreamflow:

```
I want to add push notification functionality to my app using PushFire SDK.

Please integrate PushFire SDK with these requirements:
- Package: pushfire_sdk (version ^0.1.3)
- Initialize the SDK in main.dart with my API key
- Set authProvider to AuthProvider.firebase (the SDK internally handles subscriber syncing)
- Set enableLogging to true for debugging

My PushFire API key is: YOUR_API_KEY_HERE

Follow these initialization steps:
1. Import 'package:pushfire_sdk/pushfire_sdk.dart'
2. Call PushFireSDK.initialize() in main() after WidgetsFlutterBinding.ensureInitialized()
3. Configure with PushFireConfig(apiKey: 'key', authProvider: AuthProvider.firebase, enableLogging: true)

iOS Configuration (in ios/Runner.xcodeproj/project.pbxproj):
- Add Push Notifications capability
- Add Background Modes capability with "remote-notification" enabled

IMPORTANT:
- Do NOT create custom Firebase Auth listeners - the SDK handles this automatically
- Do NOT manually request notification permissions - the SDK handles this automatically during initialization
```

#### 🔐 Supabase Auth Integration Prompt

If your app uses Supabase instead of Firebase:

```
Add PushFire push notifications with Supabase authentication:

- Package: pushfire_sdk: ^0.1.3
- Set authProvider to AuthProvider.supabase (the SDK internally handles subscriber syncing)
- Initialize after Supabase.initialize()

Example initialization:
```dart
await Supabase.initialize(url: 'YOUR_URL', anonKey: 'YOUR_KEY');
await PushFireSDK.initialize(
  PushFireConfig(
    apiKey: 'YOUR_PUSHFIRE_KEY',
    authProvider: AuthProvider.supabase,
    enableLogging: true,
  ),
);
```

iOS Configuration (in ios/Runner.xcodeproj/project.pbxproj):
- Add Push Notifications capability
- Add Background Modes capability with "remote-notification" enabled

IMPORTANT:
- Do NOT create custom Supabase Auth listeners - the SDK handles this automatically
- Do NOT manually request notification permissions - the SDK handles this automatically during initialization


### Step 3: Review Generated Code

After Dreamflow generates the code, verify these key elements:

#### ✅ Check `pubspec.yaml`

```yaml
dependencies:
  pushfire_sdk: ^0.1.3
  firebase_core: ^3.14.0
  firebase_messaging: ^15.1.0
```

#### ✅ Check `main.dart`

```dart
import 'package:pushfire_sdk/pushfire_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase initialization (if using Firebase)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // PushFire initialization
  await PushFireSDK.initialize(
    PushFireConfig(
      apiKey: 'your-api-key',
      authProvider: AuthProvider.firebase, // or AuthProvider.supabase
      enableLogging: true,
    ),
  );
  
  runApp(MyApp());
}
```

### Step 4: Verify iOS Configuration

After Dreamflow generates the code, verify that the iOS capabilities were added correctly:

1. Check `ios/Runner.xcodeproj/project.pbxproj` contains:
   - Push Notifications capability
   - Background Modes with "remote-notification"

2. If testing on a real iOS device, open `ios/Runner.xcworkspace` in Xcode and verify:
   - **Signing & Capabilities** shows "Push Notifications"
   - **Background Modes** shows "Remote notifications" enabled

---

## Approach 2: Manual Post-Export Integration

If you've already generated your app with Dreamflow and want to add PushFire afterwards:

### Step 1: Export Your Dreamflow Project

1. In Dreamflow, click **Export** → **Download Flutter Project**
2. Extract the project to your development folder
3. Open the project in VS Code or your preferred IDE

### Step 2: Add PushFire SDK

#### Add to `pubspec.yaml`

```yaml
dependencies:
  pushfire_sdk: ^0.1.3
```

#### Run dependency installation

```bash
flutter pub get
```

### Step 3: Configure Firebase (If Not Already Done)

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

### Step 4: Initialize PushFire SDK

Edit your `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pushfire_sdk/pushfire_sdk.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize PushFire SDK
  await PushFireSDK.initialize(
    PushFireConfig(
      apiKey: 'your-api-key-here',
      authProvider: AuthProvider.firebase,
      enableLogging: true,
    ),
  );
  
  runApp(MyApp());
}
```

### Step 5: iOS Configuration

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your project target → **Signing & Capabilities**
3. Add **Push Notifications** capability
4. Add **Background Modes** → Enable "Background processing" and "Remote notifications"

---

## Notification Permissions

The PushFire SDK handles notification permissions automatically, but you should understand how it works for each platform.

### Default Behavior

By default, the SDK **automatically requests notification permissions** during initialization. This is controlled by the `requestNotificationPermission` config option (defaults to `true`).

```dart
PushFireConfig(
  apiKey: 'your-key',
  requestNotificationPermission: true, // Default - auto-requests permissions
)
```

### Manual Permission Request

If you want to control when permissions are requested (for better UX), disable auto-request and call manually:

```dart
// Initialize without auto-requesting
await PushFireSDK.initialize(
  PushFireConfig(
    apiKey: 'your-key',
    requestNotificationPermission: false, // Disable auto-request
  ),
);

// Later, when appropriate (e.g., after onboarding)
bool granted = await PushFireSDK.requestNotificationPermission();
```

### Platform-Specific Notes

**iOS:**
- Requires Push Notifications capability in Xcode (see Step 5 above)
- Permission dialog appears when first requested
- Users can enable/disable in Settings → Your App → Notifications

**Android:**
- For **Android 13+ (API 33+)**: Runtime permission is required — the SDK handles this automatically
- For **Android 12 and below**: No runtime permission needed, notifications work by default
- Users can manage in Settings → Apps → Your App → Notifications

## Verification Steps

After integration, verify everything works:

### 1. Check Initialization Logs

Run your app with `flutter run` and look for:

```
[PushFire] SDK initialized successfully
[PushFire] Device registered: <device-id>
```

### 2. Test Subscriber Login

If using Firebase Auth, sign in a user and verify:

```
[PushFire] Subscriber logged in: <user-name>
```

### 3. Verify in PushFire Dashboard

Log into your PushFire dashboard and confirm:
- Device appears in registered devices
- Subscriber shows up after login

---

## Troubleshooting

### Common Issues

- **`PushFireNotInitializedException`** — Ensure `PushFireSDK.initialize()` is called before any other SDK methods
- **Device not registering** — Check Firebase setup and FCM configuration
- **Subscriber not auto-syncing** — Verify `authProvider` matches your auth system (Firebase/Supabase)
- **API errors** — Confirm your API key is valid and account is active

### Debug Mode

Enable logging for detailed diagnostics:

```dart
PushFireConfig(
  apiKey: 'your-key',
  enableLogging: true, // Enable this!
)
```

---

## Quick Reference

### Essential Code Snippets

```dart
// Initialize SDK
await PushFireSDK.initialize(PushFireConfig(apiKey: 'key'));

// Check subscriber status
bool isLoggedIn = await PushFireSDK.instance.isSubscriberLoggedIn();

// Get current subscriber
Subscriber? subscriber = await PushFireSDK.instance.getCurrentSubscriber();

// Add tags
await PushFireSDK.instance.addTag('plan', 'premium');

// Listen to events
PushFireSDK.instance.onDeviceRegistered.listen((device) {
  print('Device: ${device.id}');
});
```
---

> **Note**: This guide is designed for Dreamflow AI users.
