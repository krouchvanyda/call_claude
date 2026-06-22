# FCM Background Calls — Android Implementation Plan & Test Cases

> Scope: Android only. iOS (CallKit / PushKit) is deferred. Real audio/video
> (WebRTC) is also deferred — this plan only solves "wake the device and
> show a ring screen when a call arrives in the background or killed state".

## 1. Goal

When Vibol calls Pisey, Pisey's phone rings with the existing
`IncomingCallOverlay` sheet whether her app is:

| Pisey's app state | Today | After this plan |
|---|---|---|
| Foreground | ✅ rings instantly via WS | ✅ rings instantly via WS (unchanged) |
| Minimized (backgrounded) | ⚠️ misses after ~30 s | ✅ rings via FCM heads-up notification |
| Killed (swipe-away, OS kill) | ❌ silent forever | ✅ rings via FCM (background isolate cold-starts the app) |

## 2. Architecture (minimum-disruption)

Keep the existing `tools/chat_relay/` WebSocket relay for the foreground
fast path. Add FCM as a parallel channel that only matters for
backgrounded / killed peers. Receivers de-dupe by `callId` so a peer who
is still foregrounded silently drops the FCM copy.

```
                                                ┌─ ChatTransport.sendCallInvite (WS)
Vibol's phone ── tap Call ── CallSignalingService
                                                └─ FcmInviteSender.send (HTTPS callable)
                                                          │
                                                          ▼
                                              Cloud Function `sendCallInvite`
                                                          │
                                            multicast FCM data message, priority=high
                                                          │
                          ┌───────────────────────────────┼───────────────────────────────┐
                          ▼                               ▼                               ▼
                Pisey (foreground)              Pisey (background)                 Pisey (killed)
                got it via WS already           background isolate fires           background isolate cold-starts
                FCM ignored (callId match)      flutter_local_notifications        flutter_local_notifications
                                                heads-up shows Accept/Reject       heads-up shows Accept/Reject
                                                tap Accept → overlay opens         tap Accept → app launches → overlay opens
```

## 3. Components to build

### 3.1 Backend — Firebase Cloud Functions + Firestore

**Firestore collections:**

```
/devices/{deviceId}
  userId      string   chat identity (emp-001 etc.)
  fcmToken    string   FCM registration token, refreshed on rotation
  platform    string   "android" (only one for now)
  updatedAt   timestamp
```

One row per phone; the same user can have multiple devices.

**Two HTTPS callable functions** (`functions/src/index.ts`, ~80 lines TS total):

| Function | Called by | Behaviour |
|---|---|---|
| `registerDevice` | App on startup, on token refresh | Upsert `/devices/{deviceId}` keyed by a stable per-install id |
| `sendCallInvite` | Caller's app from `CallSignalingService.startOutgoing` | Look up `targetIds` → collect tokens from `/devices` → `messaging.sendEachForMulticast(...)` with `android.priority: 'high'` and `data: { type: 'call.invite', callId, conversationId, callerId, callerName, callType, startedAt }`. **No `notification` field** — we render with `flutter_local_notifications` so the UI matches the in-app overlay. |

### 3.2 App — new module `lib/features/chat/data/fcm/`

| File | Purpose | Approx. LoC |
|---|---|---|
| `fcm_service.dart` | Wraps `firebase_messaging`. Gets token on start, listens for `onTokenRefresh`, posts to `registerDevice`. | ~60 |
| `fcm_invite_sender.dart` | Wraps `cloud_functions`. `Future<void> send(...)` hits `sendCallInvite`. Fire-and-forget. | ~30 |
| `fcm_call_handler.dart` | Top-level `@pragma('vm:entry-point')` background handler. Decodes the `call.invite` data message and renders a `flutter_local_notifications` heads-up with Accept/Reject. | ~120 |

### 3.3 App — config + wiring

**`pubspec.yaml`** add:

```yaml
firebase_core: ^3.x
firebase_messaging: ^15.x
cloud_functions: ^5.x
flutter_local_notifications: ^17.x
```

**`android/app/src/main/AndroidManifest.xml`** add:

- `<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />` (Android 13+)
- `<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />` (Android 14+; required for ring-screen behaviour)
- Intent filter on `MainActivity` for a deep-link scheme like `erpcall://chat/incoming/<callId>`
- A notification channel named `calls` with `importance: max` (created from Dart at app start; manifest can't do this on modern Android)

**`lib/main.dart`** add at top of `main()`:

```dart
await Firebase.initializeApp();
FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler); // top-level function
await GetIt.I<FcmService>().start();
```

**`CallSignalingService.startOutgoing`** ([call_signaling_service.dart](../lib/features/chat/data/call_signaling_service.dart#L138)) — one extra line after the existing WS call:

```dart
unawaited(GetIt.I<FcmInviteSender>().send(
  callId: callId,
  conversationId: conversationId,
  callerId: me,
  callerName: myName,
  callType: callType,
  startedAt: now,
  targetIds: targetIds,
));
```

**Everything else stays untouched** — `CallSignalingService` state machine,
`IncomingCallOverlay`, group multi-party logic, busy signal, accept/reject
flow, in-call page, call summary writer.

## 4. Phases

Each phase is independently testable and mergeable.

### Phase 1 — Backend skeleton (~0.5 day)

1. Create Firebase project at <https://console.firebase.google.com>.
2. Add an Android app to it. The `applicationId` must match
   `android/app/build.gradle` (currently `com.example.erp_ai_app` or
   whatever the project uses — confirm before registering).
3. Download `google-services.json` → drop into `android/app/`.
4. Enable Firestore in native mode (any region close to your users).
5. Upgrade to Blaze plan (pay-as-you-go). Stays $0 for demo volume; without
   Blaze, Cloud Functions can't make outbound calls to FCM.
6. Initialise functions: `firebase init functions` (TypeScript).
7. Add `firebase-admin` dependency; write the two functions (~80 LoC).
8. Deploy: `firebase deploy --only functions`.

### Phase 2 — App receives FCM in foreground (~0.5 day)

1. Add the four packages to `pubspec.yaml`; `flutter pub get`.
2. Apply the Google Services Gradle plugin (`android/build.gradle` +
   `android/app/build.gradle`).
3. Create `FcmService.start()` — get token, log it, call `registerDevice`.
4. In foreground, log every `FirebaseMessaging.onMessage` to console.
   No UI yet — we just prove the pipe works.

### Phase 3 — Background notification (~1 day)

1. Implement the top-level `fcmBackgroundHandler(RemoteMessage)`.
2. Initialise `flutter_local_notifications` with a `calls` channel
   (`importance: max`, sound, vibration, full-screen-intent enabled).
3. On `call.invite` data message, render a notification with Accept /
   Reject actions and a deep link payload `{ callId, conversationId, ... }`.
4. Wire the deep link: tapping the notification or Accept action should
   route to `/chat/incoming?callId=...&conversationId=...` and surface
   the existing overlay (use `AppRouter.rootNavigatorKey` from
   Slice 10.2.9 to push from the cold-start path).

### Phase 4 — Wire FCM to existing call signalling (~0.5 day)

1. Add the one-line call to `FcmInviteSender.send(...)` in
   `CallSignalingService.startOutgoing`.
2. Verify de-dupe: foregrounded peer still rings via WS first; FCM arrives
   later and is ignored because `_active?.callId == callId`.
3. Accept from the FCM notification path → existing `acceptIncoming()`
   runs → existing in-call page opens (Slice 10.2.9 root-navigator push).

### Phase 5 — Polish (~0.5 day)

1. Cleanup: if the caller hangs up before the callee answers, the
   ringing notification on the callee's phone should be dismissed.
   Add a `call.hangup` data path that cancels the notification by id.
2. First-launch prompt: ask the user to disable battery optimisation
   for the app (OEM throttling kills background isolates aggressively).
3. Failure logging: if Cloud Function returns non-OK, surface a small
   snackbar on the caller's side so they know the callee may not ring.

**Total estimate: 2.5 – 3 days of focused work.**

## 5. Risks & gotchas

| Issue | Mitigation |
|---|---|
| Android 14 `USE_FULL_SCREEN_INTENT` permission needs Google review for non-call apps | Telegram-style call notification is the legitimate use case; declare correctly in Play Console listing. |
| OEM battery savers (Xiaomi / Huawei / Samsung) aggressively kill background isolates | First-launch prompt to disable battery optimisation. There is no general fix — each OEM has a different settings path. |
| FCM "normal" priority pushes can take minutes | Always set `priority: 'high'` and `android.priority: 'HIGH'` in the Cloud Function. Rate-limited to a few per minute per device — fine for calls. |
| Race: FCM arrives while WS also delivers the same invite | Existing `CallSignalingService._onEvent` de-dupes by `callId`. |
| Cold-start latency ~2–5 s after FCM arrives on killed app | Use the **local notification** as the primary ring UI (drawn by the OS, instant). The app then warms up in the background to handle Accept. |
| Cloud Function cold start adds ~500 ms to first call after idle | Acceptable for demo. Production sets `minInstances: 1` (~$5/mo). |
| FCM tokens are leaky in `/devices` (never cleaned up) | Acceptable for demo. Production needs a token-cleanup function on `messaging.sendEachForMulticast` failures. |

## 6. What this plan does NOT include

- iOS (needs CallKit + PushKit + Apple Developer account)
- Real audio/video (WebRTC — separate epic)
- Replacing the existing WS relay (it stays as the foreground fast path)
- Production-grade token lifecycle / contact presence

---

# 7. Test Cases (Step-by-Step)

Each phase has its own acceptance tests. Run them in order — later phases
assume earlier ones still pass.

## 7.1 Phase 1 — Backend skeleton

### TC-1.1 Cloud Functions deploy successfully

**Pre-conditions:**
- Firebase project created, Blaze plan enabled.
- `firebase login` done, `firebase use <project-id>` set.

**Steps:**
1. From `functions/` run `npm run build` — no TypeScript errors.
2. Run `firebase deploy --only functions`.
3. Open Firebase console → Functions tab.

**Expected:** Both `registerDevice` and `sendCallInvite` listed with
status "Active" and a trigger URL.

**If it fails:** Check `firebase-debug.log`. Most common: missing IAM
roles on the deploy account — re-authenticate with `firebase login --reauth`.

---

### TC-1.2 `registerDevice` writes to Firestore

**Pre-conditions:** TC-1.1 passes.

**Steps:**
1. Firebase console → Functions → `registerDevice` → "Test function" button.
2. Paste JSON body:
   ```json
   { "data": { "userId": "emp-003", "fcmToken": "fake-token-1", "platform": "android" } }
   ```
3. Click Run.

**Expected:**
- Response: `200 OK` with `{ "result": { "ok": true } }`.
- Firestore → `/devices/` collection has a new doc with the fields above.

**If it fails:** Check function logs for write errors (most likely
Firestore security rules — for the demo, open read/write to authenticated
clients only).

---

### TC-1.3 `sendCallInvite` sends FCM to a real device (manual)

**Pre-conditions:** TC-1.2 passes; you have a physical Android device
with Google Play Services installed.

**Steps:**
1. On the test device, build any FCM hello-world (or temporarily use
   Phase 2's `FcmService` and copy the token from `print` output).
2. Call `registerDevice` from the Firebase console with that real token,
   `userId: "emp-test"`.
3. Call `sendCallInvite` from the console with:
   ```json
   { "data": {
       "callId": "test-call-1",
       "conversationId": "conv-test",
       "callerId": "emp-001",
       "callerName": "Demo Approver",
       "callType": "voice",
       "startedAt": "2026-05-22T10:00:00Z",
       "targetIds": ["emp-test"]
   } }
   ```

**Expected:** Device receives the FCM message within ~2 s. Confirm via
`adb logcat | grep FirebaseMessaging`.

**If it fails:**
- Token expired → re-fetch and re-register.
- No Google Play Services on emulator → use a real device or a Play-enabled emulator.
- Cloud Function logs show `messaging/registration-token-not-registered` → token rotation; refresh.

---

## 7.2 Phase 2 — App receives FCM in foreground

### TC-2.1 App fetches FCM token on first launch

**Pre-conditions:** Phase 2 code merged; `google-services.json` in place.

**Steps:**
1. Uninstall the app from the test device.
2. `flutter run --release` (release builds use FCM more realistically;
   debug builds occasionally have timing issues).
3. Open the app, sign in as any chat identity.
4. Check `adb logcat | grep "FCM token"`.

**Expected:** A 100+ character token is logged exactly once at startup.

**If it fails:** Likely missing `google-services.json` or the plugin
isn't applied — check `android/app/build.gradle` has
`apply plugin: 'com.google.gms.google-services'` at the bottom.

---

### TC-2.2 Token registered with backend

**Pre-conditions:** TC-2.1 passes.

**Steps:**
1. After the token is logged, open Firestore console.
2. Look at `/devices/`.

**Expected:** A document exists with `fcmToken` matching what `adb logcat`
printed, `userId` matching the current chat identity, `platform: "android"`,
and a recent `updatedAt`.

**If it fails:** Check `FcmService.start()` log output — `cloud_functions`
errors usually mean Firestore rules block the write or the function URL
mismatch (region mismatch between client and deployed function).

---

### TC-2.3 Foreground FCM message logs to console

**Pre-conditions:** TC-2.2 passes; app is open and visible.

**Steps:**
1. From Firebase console, invoke `sendCallInvite` targeting the device's
   `userId` (same JSON body as TC-1.3).
2. Watch `adb logcat`.

**Expected:** Within ~2 s, the foreground handler logs the full message
payload. No notification appears yet (we're not rendering one in Phase 2).

**If it fails:** Did you initialise Firebase in `main()` before
`runApp`? Did you call `FirebaseMessaging.instance.requestPermission`?

---

## 7.3 Phase 3 — Background notification

### TC-3.1 Notification appears when app is minimized

**Pre-conditions:** Phase 3 code merged; notification channel `calls`
created on first run; user granted notification permission on first
launch.

**Steps:**
1. Open the app, confirm token registered (TC-2.2).
2. Press the home button — app is minimized, not killed.
3. Invoke `sendCallInvite` from Firebase console targeting this device's
   userId, `callType: "voice"`.

**Expected:** Within ~3 s, a heads-up notification slides down with:
- Title: "Incoming voice call"
- Body: caller name
- Two action buttons: Accept (green), Reject (red)
- Sound + vibration

**If it fails:**
- No notification at all → background handler not registered as a
  top-level `@pragma('vm:entry-point')` function.
- Notification appears but no actions → channel `importance` wrong, or
  actions not attached to `NotificationDetails`.
- Notification is silent → channel created with wrong importance; you
  cannot change an existing channel's importance, so bump the channel id
  to `calls_v2` and try again.

---

### TC-3.2 Notification appears when app is killed

**Pre-conditions:** TC-3.1 passes.

**Steps:**
1. Open the app, confirm token registered.
2. Swipe the app off the recents tray (or `adb shell am force-stop <pkg>`).
3. Verify the Dart isolate is dead: `adb shell ps | grep <pkg>` returns nothing.
4. Invoke `sendCallInvite` from Firebase console.

**Expected:** Same notification as TC-3.1 appears within ~3 s, even
though the app process was dead at the time the FCM arrived.

**If it fails:** This is the hardest test. Common causes:
- OEM battery saver (Xiaomi MIUI is notorious) — disable battery
  optimisation for the app in OS settings.
- Background handler not actually top-level — must be declared outside
  any class.
- Firebase not re-initialised inside the background isolate (each
  isolate is a fresh VM, no shared state).

---

### TC-3.3 Tapping Accept opens the in-call screen

**Pre-conditions:** TC-3.2 passes.

**Steps:**
1. Trigger TC-3.2.
2. When the notification appears, tap "Accept".

**Expected:** App cold-starts, the existing `IncomingCallOverlay` does
NOT show (we already accepted from the notification), and the voice/video
call page opens with timer ticking.

**If it fails:** Most likely the deep-link payload isn't being read in
`main()` before the router resolves — `getInitialMessage()` from
`firebase_messaging` must be checked at startup and the router must
defer initial location resolution until that future completes.

---

### TC-3.4 Tapping Reject dismisses with no call

**Pre-conditions:** TC-3.2 passes.

**Steps:**
1. Trigger TC-3.2.
2. Tap "Reject".

**Expected:** Notification dismisses. App does NOT open. The caller's
device receives `call.reject` (via WS if foreground, FCM if not — but
the reject path is currently WS-only; that's an acceptable Phase 5
follow-up).

**If it fails:** The Reject action should call into the background
isolate and post a `call.reject` to your Cloud Function (or, simpler,
just dismiss locally and let the caller's 30 s ring timeout handle it).

---

## 7.4 Phase 4 — Wire FCM to existing call signalling

### TC-4.1 Backgrounded peer rings via FCM, foreground peer via WS

**Pre-conditions:** All Phase 3 tests pass. **Three** physical Android
devices: caller (Demo Approver, foreground), callee A (Pisey, foreground),
callee B (Vibol, **backgrounded**).

**Steps:**
1. All three devices: app open, WS connected, FCM registered.
2. Demo Approver: open the group conversation with Pisey + Vibol.
3. Pisey: app foreground.
4. Vibol: press home — app minimized.
5. Demo Approver: tap voice call button.

**Expected:**
- Pisey's phone: existing `IncomingCallOverlay` appears within
  ~200 ms (WS path).
- Vibol's phone: heads-up notification appears within ~3 s
  (FCM path). When tapped, the in-call page opens.

**If it fails:** Check that the caller is firing BOTH paths.
Add a temporary log line in `CallSignalingService.startOutgoing` after
each transport call to confirm.

---

### TC-4.2 De-dupe — foreground peer ignores duplicate FCM

**Pre-conditions:** TC-4.1 passes.

**Steps:**
1. Same three devices, all foreground this time.
2. Demo Approver calls the group.

**Expected:** Each callee sees the overlay exactly once. Watch `adb
logcat` on Pisey's device — the FCM arrives within ~3 s but is logged
as "duplicate callId, dropping" and no second overlay appears.

**If it fails:** The de-dupe check is missing — verify
`_active?.callId == callId` comparison in the FCM path before calling
`_setActive(...)`.

---

### TC-4.3 Group call multi-party from FCM path

**Pre-conditions:** TC-4.1 + TC-4.2 pass.

**Steps:**
1. Caller (Demo): call group TEST01 (Vibol + Pisey).
2. Both Vibol and Pisey are **backgrounded**.
3. Both see FCM notifications, both tap Accept within 5 s of each other.

**Expected:** Both callees end up in `connected` state; caller's
in-call page shows timer ticking; multi-party hangup rules (Slice 10.2.10
+ 10.2.11) still apply — one callee leaving doesn't kick the other.

**If it fails:** The FCM-acceptance path must call into the existing
`CallSignalingService.acceptIncoming()` (not duplicate the logic) so
that `accepterId` tracking still works.

---

## 7.5 Phase 5 — Polish

### TC-5.1 Notification auto-dismisses when caller hangs up

**Pre-conditions:** All previous tests pass.

**Steps:**
1. Vibol: backgrounded.
2. Demo: places call → Vibol sees notification.
3. Demo: taps End BEFORE Vibol taps Accept.

**Expected:** Vibol's notification disappears within ~3 s (the
`call.hangup` FCM data message arrives and the background handler
cancels notification id = `callId.hashCode`).

**If it fails:** The hangup → FCM path probably isn't wired. Add the
`sendCallHangup` to a second Cloud Function callable, or piggyback on
the existing one.

---

### TC-5.2 Cold-start with invite payload survives

**Pre-conditions:** All previous tests pass.

**Steps:**
1. Force-stop the app (`adb shell am force-stop <pkg>`).
2. Send an invite via the caller.
3. Wait for the notification on the test device, tap Accept.

**Expected:** App cold-starts (~2–5 s splash visible), then jumps
directly to the in-call page for that conversation. The user does NOT
land on the inbox first.

**If it fails:** The router is resolving the initial location BEFORE
the FCM `getInitialMessage()` future completes. Add an `await` for that
future in `main()` before `runApp(MyApp(initialLocation: ...))`.

---

### TC-5.3 OEM battery saver compatibility

**Pre-conditions:** Test on a Xiaomi / Oppo / Huawei device (the most
aggressive killers).

**Steps:**
1. Install the app, complete first-run prompt to disable battery
   optimisation.
2. Force-stop and verify TC-3.2 still works.
3. Without disabling battery optimisation, repeat — expect failure.

**Expected with opt-out:** Same as TC-3.2.
**Expected without opt-out:** Notification may not appear; this is an
OS limitation, not a bug.

---

## 8. Quick smoke-test checklist (post-deploy)

Run these after every backend or app deploy. Should take 5 minutes.

- [ ] Token in `/devices` is fresh (within last few minutes).
- [ ] Foreground call still works on both peers (TC-2.3 path).
- [ ] Minimized call rings via FCM (TC-3.1).
- [ ] Killed call rings via FCM (TC-3.2).
- [ ] Tap Accept from notification opens in-call page (TC-3.3).
- [ ] Group call: one callee in background, one in foreground, both
      get notified appropriately (TC-4.1).

If any of these fail in production, roll back the deploy.
