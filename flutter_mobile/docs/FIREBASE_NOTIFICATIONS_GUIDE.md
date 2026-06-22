# Firebase Notifications — Setup + Testing Guide

> End-to-end guide for getting Firebase Cloud Messaging (FCM) working
> on this project for both **Android** and **iOS**, and how to send
> test pushes from the Firebase Console.
>
> Use this in tandem with the existing code in:
> - [`lib/shared/firebase_option/firebase_options.dart`](../lib/shared/firebase_option/firebase_options.dart) — project credentials
> - [`lib/shared/firebase_services/firebase_notification_provider.dart`](../lib/shared/firebase_services/firebase_notification_provider.dart) — FCM singleton
> - [`lib/shared/firebase_services/local_notification_provider.dart`](../lib/shared/firebase_services/local_notification_provider.dart) — local-display plugin
> - [`lib/main.dart`](../lib/main.dart) — bootstrap (Firebase init + bg handler + permissions + token)
> - [`lib/app.dart`](../lib/app.dart) — listener attachment

---

## Table of contents

1. [Overview — how the pieces fit](#1-overview--how-the-pieces-fit)
2. [Prerequisites](#2-prerequisites)
3. [Firebase Console — project + apps](#3-firebase-console--project--apps)
4. [Android setup](#4-android-setup)
5. [iOS setup](#5-ios-setup)
6. [Flutter wiring (already done)](#6-flutter-wiring-already-done)
7. [How to test from the Firebase Console](#7-how-to-test-from-the-firebase-console)
8. [Reading the debug logs (the 4 state labels)](#8-reading-the-debug-logs-the-4-state-labels)
9. [Payload shapes — `notification` vs `data` vs both](#9-payload-shapes--notification-vs-data-vs-both)
10. [Common errors and fixes](#10-common-errors-and-fixes)
11. [Production checklist](#11-production-checklist)

---

## 1. Overview — how the pieces fit

```
   ┌──────────────────────┐         ┌──────────────────────┐
   │ Firebase Console     │  push   │  FCM backend         │
   │ (or your server)     ├────────►│  (Google Cloud)      │
   └──────────────────────┘         └──────────┬───────────┘
                                               │
                       APNS (iOS) / FCM (Android)
                                               │
                                               ▼
   ┌─────────────────────────────────────────────────────────┐
   │ Device                                                  │
   │ ┌─────────────────────────────────────────────────────┐ │
   │ │ Flutter app                                         │ │
   │ │                                                     │ │
   │ │  IN APP       firebase_messaging.onMessage          │ │
   │ │  ──────►      → initOnMessageListener (foreground)  │ │
   │ │                                                     │ │
   │ │  MINI/KILLED  @pragma('vm:entry-point')             │ │
   │ │  ──────►      firebaseMessagingBackgroundHandler    │ │
   │ │               (separate isolate)                    │ │
   │ │                                                     │ │
   │ │  TAP from MINI    onMessageOpenedApp                │ │
   │ │  ─────────►       initOnMessageOpenedApp            │ │
   │ │                                                     │ │
   │ │  TAP from KILLED  getInitialMessage                 │ │
   │ │  ─────────►       handleInitialMessage              │ │
   │ │                                                     │ │
   │ │  ──► LocalNotificationProvider.sendNotification    │ │
   │ │       (for data-only / Android foreground)          │ │
   │ └─────────────────────────────────────────────────────┘ │
   └─────────────────────────────────────────────────────────┘
```

**Two notification renderers coexist on purpose:**

| Renderer | Used when |
|---|---|
| **OS auto-display** (system tray) | Payload contains a `notification` block AND app is background/killed (both platforms) OR foreground on iOS (because we set `alert: true`) |
| **`flutter_local_notifications`** | Payload is data-only (no `notification` block) OR foreground on Android (OS never auto-shows there) |

The de-dup logic that picks between them lives in `firebase_notification_provider.dart`. See §9 for the payload-shape decision table.

---

## 2. Prerequisites

| Tool | Why | Install |
|---|---|---|
| Firebase account | Owns the project + APNS keys | https://console.firebase.google.com |
| FlutterFire CLI | Regenerates `firebase_options.dart` so iOS + Android point at the same project | `dart pub global activate flutterfire_cli` |
| Android Studio | For `google-services.json` placement + Gradle sync | https://developer.android.com/studio |
| Xcode 15+ | For iOS capability + APNS key wiring | Mac App Store |
| Apple Developer account | Required to create APNS auth keys (not just a free Apple ID) | https://developer.apple.com — needs paid membership |
| Physical iOS device for testing | iOS simulator does NOT receive APNS pushes | — |
| Physical or emulator Android | Both work for FCM | — |

The pubspec dependencies are already in place:

```yaml
firebase_core: ^x.y.z
firebase_messaging: ^x.y.z
flutter_local_notifications: ^x.y.z
permission_handler: ^x.y.z
```

If any are missing, add them and run `flutter pub get`.

---

## 3. Firebase Console — project + apps

### 3.1 Create (or reuse) the project

1. Go to https://console.firebase.google.com → **Add project** (or open an existing one).
2. Name it something memorable — this project ID lives in `firebase_options.dart` forever after.
3. Disable Analytics if you don't need it; the wiring still works.

### 3.2 Register the Android app

1. Project home → **Add app** → **Android**.
2. **Android package name** — must match `android/app/build.gradle`'s `applicationId` (currently `com.company.erp` or similar — check the file).
3. **App nickname** — optional.
4. **Debug signing certificate SHA-1** — required for Dynamic Links and some auth flows; **NOT required for FCM**. Skip for now.
5. Download **`google-services.json`** → place at `android/app/google-services.json`.
6. Continue and skip the rest of the in-console steps (the Gradle plugin instructions are covered in §4 below).

### 3.3 Register the iOS app

1. Project home → **Add app** → **iOS+**.
2. **Apple bundle ID** — must match `ios/Runner/Info.plist` → `CFBundleIdentifier` AND your Xcode signing.
3. **App nickname** — optional.
4. **App Store ID** — leave blank for dev.
5. Download **`GoogleService-Info.plist`** → drag into Xcode under `Runner/Runner/` (NOT just the filesystem — Xcode must add it to the target).

> **⚠️ Critical**: both apps MUST sit under the **same Firebase project**. If
> Android and iOS land in different projects, server-side topic sends and
> any cross-platform analytics will silently fail to reach one side.
> Today's [`firebase_options.dart`](../lib/shared/firebase_option/firebase_options.dart)
> has this exact bug — Android = `erp-project-ba24f`, iOS = `e-customer-dev`.
> Fix by running `flutterfire configure --project=<canonical-id>` (see §4.5).

### 3.4 Upload the APNS Authentication Key (iOS only)

iOS pushes flow Firebase → APNS → device. Without the APNS key, Firebase has no way to talk to APNS.

1. Go to https://developer.apple.com/account → **Certificates, Identifiers & Profiles** → **Keys** → **+** to create a new key.
2. Name it (e.g. `Firebase APNS`), check **Apple Push Notifications service (APNs)**, click **Continue** → **Register** → **Download** the `.p8` file (one-time download — save it).
3. Note the **Key ID** (10 chars) and your **Team ID** (10 chars, top-right of dev portal).
4. Firebase Console → ⚙ **Project settings** → **Cloud Messaging** tab → under **Apple app configuration** → **APNs Authentication Key** → **Upload**.
5. Paste the `.p8`, the Key ID, and the Team ID. Save.

This single APNS key works for both dev and prod builds.

---

## 4. Android setup

### 4.1 Place `google-services.json`

```
android/
└── app/
    └── google-services.json   ← downloaded in §3.2
```

### 4.2 Gradle wiring

**`android/build.gradle`** (project-level) — add the classpath:

```groovy
buildscript {
    dependencies {
        // … existing …
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

**`android/app/build.gradle`** (module-level) — apply at the BOTTOM:

```groovy
// Bottom of the file
apply plugin: 'com.google.gms.google-services'
```

Confirm `minSdkVersion >= 19` (firebase_messaging requirement). Currently the project should already meet this.

### 4.3 `AndroidManifest.xml` — notification icon + channel id

`android/app/src/main/AndroidManifest.xml` inside `<application>`:

```xml
<!-- Default notification icon for incoming FCM pushes -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@mipmap/launcher_icon" />

<!-- Default notification color (status bar tint) -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/colorAccent" />

<!-- Default channel id — MUST match `_channelId` in
     LocalNotificationProvider so OS-displayed and locally-displayed
     pushes use the same channel and the same user-controlled settings -->
<meta-data
    android:name="com.google.firebase.messaging.default_notification_channel_id"
    android:value="high_channel" />
```

### 4.4 Notification icon asset

Provide a **monochrome white** PNG (Android tints it):

```
android/app/src/main/res/
├── mipmap-mdpi/launcher_icon.png      (24×24)
├── mipmap-hdpi/launcher_icon.png      (36×36)
├── mipmap-xhdpi/launcher_icon.png     (48×48)
├── mipmap-xxhdpi/launcher_icon.png    (72×72)
└── mipmap-xxxhdpi/launcher_icon.png   (96×96)
```

If you skip this, Android shows a generic grey square in the status bar (a known cause of "my notifications look broken" reports).

### 4.5 Regenerate `firebase_options.dart` (recommended)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=erp-project-ba24f
```

The CLI auto-detects your Android + iOS targets and writes the correct credentials for BOTH platforms pointing at the same project — fixing the Android/iOS mismatch documented in the current file.

### 4.6 Android 13+ runtime permission

Already handled in [`firebase_notification_provider.dart`](../lib/shared/firebase_services/firebase_notification_provider.dart):

```dart
if (Platform.isAndroid) {
  await Permission.notification.request();
}
```

You don't need to add anything; Android 13 prompts on first launch, Android 12 and below treat it as auto-granted.

### 4.7 ProGuard / R8 (release builds only)

Add to `android/app/proguard-rules.pro` (create if missing):

```proguard
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.dexterous.** { *; }   # flutter_local_notifications
```

---

## 5. iOS setup

### 5.1 Drag `GoogleService-Info.plist` into Xcode

Open `ios/Runner.xcworkspace` (NOT `.xcodeproj`) → drag the `.plist` into the `Runner` folder under the project navigator → in the dialog:

- ✅ **Copy items if needed**
- ✅ **Add to target: Runner**

(If you only drop it in Finder, Xcode won't bundle it — Firebase fails at runtime with "Default FirebaseApp is not initialized".)

### 5.2 Enable Push Notifications capability

Xcode → **Runner** target → **Signing & Capabilities** tab → **+ Capability** → **Push Notifications**.

This injects the `aps-environment` entitlement (`development` for debug, `production` for release/TestFlight).

### 5.3 Enable Background Modes → Remote notifications

Same screen → **+ Capability** → **Background Modes** → check:

- ✅ **Remote notifications**

Without this, iOS will NEVER wake the app for a data-only push (`content-available: 1`), and your `firebaseMessagingBackgroundHandler` never runs while killed/backgrounded.

### 5.4 `AppDelegate.swift` — Firebase init + APNS registration

`ios/Runner/AppDelegate.swift`:

```swift
import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions:
      [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    // Required so iOS hands us the APNS token, which firebase_messaging
    // converts into an FCM token. Without this call `getToken()` will
    // return nil forever on iOS.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    application.registerForRemoteNotifications()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 5.5 `Info.plist` — optional foreground UI tweak

If you want notification banners while the app is foreground on iOS (in addition to playing sound), the Dart side already handles this via `setForegroundNotificationPresentationOptions(alert: true, …)`. No `Info.plist` change needed.

### 5.6 Build settings

iOS deployment target ≥ 13.0 (firebase_messaging requirement). Bump in `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

Then:

```bash
cd ios && pod install --repo-update && cd ..
```

### 5.7 Provisioning + signing

For **debug** on a physical device:
1. Xcode → Runner target → **Signing & Capabilities** → check **Automatically manage signing** → choose your Apple Developer team.
2. Plug in iPhone, build & run.

For **TestFlight / App Store**:
- Use a distribution provisioning profile that includes the **APNS** entitlement.
- Build mode `production` for `aps-environment`.

---

## 6. Flutter wiring (already done)

The four-file wiring is in place — listed here so you know what to expect after a clean clone:

### `main.dart`

```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions().currentPlatform);
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
await LocalNotificationProvider().initialize();   // creates Android channel
await FirebaseNotificationProvider.instance.requestNotificationPermissions();
unawaited(_persistAndWatchPushToken(getIt<PushTokenStorage>()));
```

### `app.dart`

```dart
FirebaseNotificationProvider.instance.getFirebaseToken();   // logs token in debug
FirebaseNotificationProvider.instance.initOnMessageListener(getData: …);
FirebaseNotificationProvider.instance.initOnMessageOpenedApp(getData: …);
FirebaseNotificationProvider.instance.handleInitialMessage(getData: …);
```

### `firebase_notification_provider.dart`

- Singleton `.instance`
- De-dup logic so FCM auto-display + our local renderer don't double-fire
- 4 labelled state logs (see §8)
- Subscription tracking for clean dispose on logout

### `local_notification_provider.dart`

- `initialize()` creates the Android notification channel (`high_channel`)
- `sendNotification()` renders to the OS tray
- Stable ID helper so re-deliveries collapse and restarts don't overwrite

---

## 7. How to test from the Firebase Console

### 7.1 Get a target token

Run the app on a real device, watch the console for:

```
FCM Token: dM4_…long_string_…XYZ
```

Copy the whole token. (On iOS, you'll also see `APNs Token: …` — that's a different token; FCM Console uses the FCM one.)

### 7.2 Send a "Notification" composer test (easiest)

1. Firebase Console → **Engage** → **Messaging** (formerly "Cloud Messaging").
2. **Create your first campaign** → **Firebase Notification messages** → **Create**.
3. **Notification title** + **Notification text** — fill in.
4. **Send test message** (top right) → paste the FCM token from §7.1 → **Test**.

Within seconds you should see a tray notification.

### 7.3 Send a full campaign (notification block)

Same flow as 7.2 but skip "Send test" and use the **Next** button to walk through the wizard:

1. **Target** → app
2. **Scheduling** → "Now"
3. **Conversion events** → skip
4. **Additional options** (optional):
   - **Custom data** — key/value pairs added to `message.data`. Useful for routing the tap (e.g. `route=/chat/123`).
   - **Sound** — `default` or a custom file in the iOS bundle / Android `res/raw/`.
   - **Android Notification Channel ID** — set to `high_channel` to match our local channel. Otherwise Android falls back to its default channel with no high-importance heads-up.
5. **Review** → **Publish**.

### 7.4 Test data-only payloads (advanced)

The Console composer always sends a `notification` block. To test data-only pushes (the only path our `LocalNotificationProvider` handles in foreground/background), use the **HTTP v1 API** with `curl`:

```bash
# Get an OAuth2 access token (rotate every hour; service account JSON key needed)
# https://firebase.google.com/docs/cloud-messaging/auth-server

ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  https://fcm.googleapis.com/v1/projects/erp-project-ba24f/messages:send \
  -d '{
    "message": {
      "token": "dM4_...long_string_...XYZ",
      "data": {
        "type": "chat",
        "conversationId": "123",
        "title": "Hello from data-only",
        "body": "Custom-rendered by the app"
      },
      "android": { "priority": "HIGH" },
      "apns": {
        "headers": { "apns-priority": "5" },
        "payload": { "aps": { "content-available": 1 } }
      }
    }
  }'
```

This bypasses the OS auto-display and forces our `LocalNotificationProvider.sendNotification(...)` to render it — which is the only path that respects in-app customisation (sound choice, channel, deep-link route).

### 7.5 Topic subscriptions (optional)

To target a group of users without managing tokens individually:

**On the device** (add to Dart):

```dart
await FirebaseMessaging.instance.subscribeToTopic('all-staff');
```

**In the Console** → composer → **Target** → **Topic** → enter `all-staff` → continue.

Every device subscribed to `all-staff` receives the push.

### 7.6 Scheduled sends

Same composer → **Scheduling** → **Send at a specific time** (in user's local time or a fixed UTC time). Useful for daily-digest pushes without backend cron.

---

## 8. Reading the debug logs (the 4 state labels)

Every push prints one of four labels so you know exactly which lifecycle state the app was in when it arrived:

| Console prefix | When |
|---|---|
| **🟢 IN APP** | App was open + visible (`onMessage`) |
| **🟡 MINI / KILLED** | App was minimised OR killed, push arrived in tray (`firebaseMessagingBackgroundHandler`) |
| **🔵 TAP from MINI** | User tapped tray entry while app was minimised (`onMessageOpenedApp`) |
| **🔴 TAP from KILLED** | User tapped tray entry to launch the killed app (`getInitialMessage`) |

Each line follows the same format:

```
🟢 IN APP · id=0:171...% · title=… · body=… · data={...}
```

Logs are gated on `kDebugMode` — release builds don't leak the title/body into logcat or Crashlytics breadcrumbs.

### Recommended test matrix

| Step | Expected log(s) |
|---|---|
| App foreground, send Console test | `🟢 IN APP` |
| Home-button to minimise, send Console test, do NOT tap | `🟡 MINI / KILLED` |
| Same as above, then tap the tray entry | `🟡 MINI / KILLED` then `🔵 TAP from MINI` |
| Swipe app from recents (kill it), send Console test, do NOT tap | `🟡 MINI / KILLED` (in the bg isolate's log) |
| Same as above, then tap the tray entry to launch | `🟡 MINI / KILLED` (when it arrived) then `🔴 TAP from KILLED` (after app launches) |

---

## 9. Payload shapes — `notification` vs `data` vs both

FCM payloads have two parts: `notification` (handed to the OS) and `data` (handed to the app). What the user sees depends on which one(s) you send AND the app's lifecycle state.

### Shapes you can send

**Notification-only** (Firebase Console default):
```json
{
  "message": {
    "token": "...",
    "notification": { "title": "...", "body": "..." }
  }
}
```

**Data-only** (silent / custom-rendered):
```json
{
  "message": {
    "token": "...",
    "data": { "type": "chat", "conversationId": "123", "title": "...", "body": "..." }
  }
}
```

**Both** (Console "Additional options → Custom data"):
```json
{
  "message": {
    "token": "...",
    "notification": { "title": "...", "body": "..." },
    "data": { "route": "/chat/123" }
  }
}
```

### Decision table (what the user sees)

| Payload shape | App state | OS auto-displays? | Our local renderer fires? | User sees |
|---|---|---|---|---|
| Notification or both | Foreground (Android) | ❌ no | ✅ yes | 1 entry (local) |
| Notification or both | Foreground (iOS, with `alert: true`) | ✅ yes | ❌ skipped by de-dup | 1 entry (OS) |
| Notification or both | Background / killed (either platform) | ✅ yes | ❌ skipped by de-dup | 1 entry (OS) |
| Data-only | Foreground (either platform) | ❌ no | ✅ yes | 1 entry (local) |
| Data-only | Background / killed | ❌ no | ✅ yes (via bg isolate handler) | 1 entry (local) |

**Rule of thumb for your backend**: pick **data-only** if you want the app to fully control rendering (custom sound per category, deep-link routing on tap, mute by user preference). Pick **notification** if you just want the default OS banner with no app logic.

---

## 10. Common errors and fixes

| Symptom | Likely cause | Fix |
|---|---|---|
| **Android: no notifications appear at all** | Notification channel `high_channel` doesn't exist on the device | Make sure `LocalNotificationProvider.initialize()` runs before any push. It calls `createNotificationChannel(_channel)` — already wired in `main.dart`. |
| **Android: foreground works, background doesn't** | Missing `default_notification_channel_id` meta-data in `AndroidManifest.xml` | Add the meta-data in §4.3. |
| **iOS: `getToken()` returns null** | APNS token not ready yet OR `registerForRemoteNotifications()` not called in AppDelegate | Confirm §5.4 wiring; on simulator, FCM tokens are NOT issued — use a real device. |
| **iOS: pushes work but only when app is open** | Background Modes → Remote notifications NOT checked OR APNS auth key missing in Firebase Console | Re-check §5.3 + §3.4. |
| **iOS: "Default FirebaseApp is not initialized"** | `GoogleService-Info.plist` not added to the Xcode target (filesystem-only is not enough) | Drag it via Xcode UI (§5.1), confirm it shows under Runner in the project navigator. |
| **Notifications appear twice** | OS auto-display + our local renderer fired for the same push | Should NOT happen with current code — de-dup is in place. If it still does, check that you're not calling `initOnMessageListener` from multiple places (only `app.dart` should). |
| **Android 13: permission prompt never shows** | `permission_handler` plugin not registered correctly OR you opened the app once and dismissed; reset via app info → permissions → notifications | Uninstall + reinstall to reset the permission flag. |
| **Topic send doesn't reach the user** | Device subscribed in dev token but APNS key uploaded to a different Firebase project | Confirm Android + iOS apps are under the SAME Firebase project (§3.3 warning). |
| **`flutterfire configure` overwrites my custom-edited file** | Expected — the CLI is the authoritative source | After regenerating, restore any custom comments via git diff. |
| **APNS push delivered but no banner / no sound** | Foreground presentation options set to `alert: false` | Already corrected in current code: `setForegroundNotificationPresentationOptions(alert: true, badge: true, sound: true)`. |

---

## 11. Production checklist

Before shipping a release build:

- [ ] **`flutterfire configure --project=<canonical-id>` ran** so Android + iOS point at the same Firebase project (today's `firebase_options.dart` has the mismatch bug — fix this first).
- [ ] **APNS Authentication Key** uploaded in Firebase Console (Cloud Messaging tab) under the SAME project the apps target.
- [ ] **`google-services.json`** present at `android/app/google-services.json` and committed.
- [ ] **`GoogleService-Info.plist`** present in `ios/Runner/` and added to the Runner target in Xcode.
- [ ] **Notification icon** present in all `mipmap-*` densities — monochrome white PNG.
- [ ] **AndroidManifest.xml** meta-data for default icon + channel id (`high_channel`) in place.
- [ ] **Xcode capability: Push Notifications** enabled.
- [ ] **Xcode capability: Background Modes → Remote notifications** enabled.
- [ ] **iOS distribution provisioning profile** includes APNS entitlement.
- [ ] **`aps-environment`** = `production` in the entitlements for App Store builds.
- [ ] **Test on a real device** of each platform — neither iOS nor Android emulators are reliable for APNS path testing.
- [ ] **Token-registration with backend** wired (currently a TODO in `main.dart`).
- [ ] **`deleteFirebaseToken()` called on logout** so the next user on the device doesn't inherit pushes.
- [ ] **`kDebugMode` log gating verified** — release build doesn't print FCM tokens or notification bodies to logcat.

---

## Appendix — quick reference snippets

### Top-level background handler (cannot reference app singletons)

```dart
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // …
}
```

Registered in `main.dart` BEFORE `runApp(...)`:

```dart
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```

### Token + token-refresh persistence

```dart
final token = await FirebaseMessaging.instance.getToken();
if (token != null) await tokenStorage.saveToken(token);
FirebaseMessaging.instance.onTokenRefresh.listen(tokenStorage.saveToken);
```

### Subscribe / unsubscribe to a topic

```dart
await FirebaseMessaging.instance.subscribeToTopic('all-staff');
await FirebaseMessaging.instance.unsubscribeFromTopic('all-staff');
```

### Manual reset (when permission was denied once)

```dart
import 'package:permission_handler/permission_handler.dart';
await openAppSettings(); // user must re-enable manually
```

There's no API to re-prompt — by design.

---

## See also

- [`docs/CODE_GENERATION_PROMPTS_BLOC.md`](CODE_GENERATION_PROMPTS_BLOC.md) — prompt template for new features (notifications consumers slot in via the BLoC layer)
- [`lib/core/push/`](../lib/core/push/) — the alternative push stack (currently parallel to `shared/firebase_services/`); pick one canonical path before production
- FirebaseMessaging docs — https://firebase.flutter.dev/docs/messaging/overview
- flutter_local_notifications docs — https://pub.dev/packages/flutter_local_notifications
