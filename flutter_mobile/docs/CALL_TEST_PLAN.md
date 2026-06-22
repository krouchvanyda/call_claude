# Call Test Plan — A ↔ B (two physical devices)

Manual verification checklist for the Chat call flows (Module 10).
Run each row on **real** devices (call push + the native incoming-call screen
do **not** work on a simulator/emulator).

Mark each sub-case: ✅ pass · ❌ fail · ⬜ not run yet.
For any ❌, save the log from **both** A and B around that moment.

This plan is split by platform — the **flows are the same**, but the push
transport and the confirming log lines differ:

| | iOS | Android |
|---|---|---|
| Call push | VoIP / PushKit → APNs (`apn`) | FCM high-priority data message |
| Incoming UI | native CallKit screen | `flutter_callkit_incoming` full-screen call notification |
| Killed/locked accept path | native CXCallObserver bridge (`AppDelegate`) | plugin `onEvent` (`Event.actionCall*`) |
| Capture killed/locked logs | **Console.app** (filter by app process) | **`adb logcat`** (filter the app) |
| `detached` on swipe-kill | unreliable (often skipped) | reliable task-removal → bridge hangs up active call |

> Keep each case a **separate single call**. Do not chain a 2nd call onto a
> just-declined B — that 2nd-call-to-killed-B path is a known backend
> presence-staleness issue tracked separately, not part of these flows.

---

# Part A — iOS

## Case 1 — A calls B · both **in-app (foreground)**

| Step | Expected (PASS) | Confirm — B | Confirm — A | Result |
|---|---|---|---|---|
| A calls B | B shows the **in-app** overlay (not native CallKit) | overlay "… is calling" | "Calling…" screen | ⬜ |
| B accepts | both land on the call page, timer runs both sides | `status=Connected` | `status=Connected` | ⬜ |
| A ends **or** B ends | **both** call pages close | call page pops | call page pops | ⬜ |

---

## Case 2 — A calls B · B **minimized**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | B gets the **native CallKit** ring | CallKit screen shows | ⬜ |
| B accepts | both connect, timer runs | `status=Connected` both sides | ⬜ |
| After accept, **B ends** | A ends too | A: `call.hangup` → page pops | ⬜ |
| (Re-test) A or B **rejects** | call ends both sides | reject → `POST /reject OK`, A stops ringing | ⬜ |

---

## Case 3 — A calls B · B **killed**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | B gets native CallKit ring (app cold-starts) | CallKit screen | ⬜ |
| B accepts | both connect | B: `notifyIncomingCallAnswered` → `POST /accept`; both `status=Connected` | ⬜ |
| After accept, **B ends** | A ends too | A: page pops | ⬜ |
| (Re-test) **reject** | A stops ringing | B: `native End … direct reject POST … /reject OK` | ⬜ |

---

## Case 4 — A calls B · B **killed + screen locked**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | native CallKit ring on the lock screen | ring on locked screen | ⬜ |
| B accepts | both connect (native screen; no in-app UI on lock) | `status=Connected` both sides | ⬜ |
| After accept, **B ends** | A ends too | A: page pops | ⬜ |
| (Re-test) **reject** | A stops ringing | B: `direct reject POST … /reject OK` | ⬜ |

---

## Case 5 — A calls B · B **doesn't answer → timeout**

Nobody taps End. Both sides auto-close **together at ~60 s**, server-driven.

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls, B ignores | at ~60 s **both** A and B close at the same time; logged as missed | A: "Calling…" closes; B: ring clears; call status `MISSED` / `NO_ANSWER` both sides | ⬜ |

**How the 60 s works (for reference):**
- Stream server ring settings = 60 s (`autoCancelTimeout` / `autoRejectTimeout`
  / `missedCallTimeout`) in `stream_call_engine.dart` → at 60 s Stream
  broadcasts `call.ended` to **both** devices simultaneously.
- Local backup timers (only fire if the server event is lost):
  B (callee) 60 s, A (caller) 65 s — A is intentionally 5 s longer so the
  server's 60 s event wins on the normal path.

---

# Part B — Android

> Android delivers the call via an **FCM high-priority data message**;
> `flutter_callkit_incoming` renders the full-screen incoming-call
> notification. Accept / Decline / End come through the plugin's `onEvent`
> (`Event.actionCallAccept` / `actionCallDecline` / `actionCallEnded`) →
> `_handleAccept` / `_handleDecline` / `_handleHangup`. There is **no** iOS
> CXCallObserver / `direct reject` native bridge on Android.
> Capture killed/locked logs with **`adb logcat`** (filter the app).

## Case 1 — A calls B · both **in-app (foreground)**

| Step | Expected (PASS) | Confirm — B | Confirm — A | Result |
|---|---|---|---|---|
| A calls B | B shows the **in-app** overlay | overlay "… is calling" | "Calling…" screen | ⬜ |
| B accepts | both land on the call page, timer runs | `status=Connected` | `status=Connected` | ⬜ |
| A ends **or** B ends | **both** call pages close | call page pops | call page pops | ⬜ |

## Case 2 — A calls B · B **minimized**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | B gets the full-screen **call notification** | notification ring shows | ⬜ |
| B accepts | both connect, timer runs | B: `event=Event.actionCallAccept` → `_handleAccept`; both `status=Connected` | ⬜ |
| After accept, **B ends** | A ends too | B: `event=Event.actionCallEnded`; A: `call.hangup` → page pops | ⬜ |
| (Re-test) A or B **rejects** | call ends both sides | B: `event=Event.actionCallDecline` → `POST /reject OK`; A stops ringing | ⬜ |

## Case 3 — A calls B · B **killed**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | FCM wakes app → full-screen call notification | notification ring (app cold-starts) | ⬜ |
| B accepts | both connect | B: `_handleAccept` → `POST /accept`; both `status=Connected` | ⬜ |
| After accept, **B ends** | A ends too | A: page pops | ⬜ |
| (Re-test) **reject** | A stops ringing | B: `_handleDecline` → `POST /reject OK` | ⬜ |

## Case 4 — A calls B · B **killed + screen locked**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | full-screen call notification over the lock screen | ring on locked screen | ⬜ |
| B accepts | both connect | B: `_handleAccept`; both `status=Connected` | ⬜ |
| After accept, **B ends** | A ends too | A: page pops | ⬜ |
| (Re-test) **reject** | A stops ringing | B: `_handleDecline` → `POST /reject OK` | ⬜ |

## Case 5 — A calls B · B **doesn't answer → timeout**

Nobody taps End. Both sides auto-close **together at ~60 s**, server-driven
(same Stream ring settings as iOS — see the iOS Case 5 reference above).

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls, B ignores | at ~60 s **both** A and B close at the same time; logged as missed | A: "Calling…" closes; B: ring clears; call status `MISSED` / `NO_ANSWER` both sides | ⬜ |

---

# Cross-platform calls (the important ones)

The call has **two independent legs**:

- **Caller leg** — decided by the *caller's* platform. Both platforms now place the
  call **ring-free** (`getOrCreate(ring:false)`); the backend fires the actual ring.
  The caller just shows "Calling…" and joins the Stream SFU for media.
- **Callee leg** — decided by the *callee's* platform & state:
  - **iOS callee** → ring delivered by **APNs/PushKit** → **native CallKit** screen;
    accept via the `AppDelegate` CXCallObserver bridge.
  - **Android callee** → ring delivered by **FCM high-priority** → `flutter_callkit_incoming`
    full-screen notification; accept/decline via the plugin `onEvent`.
  - **Foreground callee (either platform)** → no push; the WS/STOMP invite paints the
    **in-app overlay** and the inbound FCM/APN is ignored (callId already matched).
- **Media leg** — Stream SFU, **platform-agnostic** (same `status=Connected` on both).

> So a cross-platform call = caller rows from one Part + callee rows from the other.
> ⚠ The callee device must be able to receive its platform's push — e.g. an Android
> device **without real Google Play Services** (Huawei/GBox/microG) cannot get the FCM
> ring when minimized/killed; test Android callees on a GMS device.

---

# Part C — iOS → Android  (caller = iOS · callee = Android)

## Case 1 — both **in-app (foreground)**

| Step | Expected (PASS) | Confirm — B (Android) | Confirm — A (iOS) | Result |
|---|---|---|---|---|
| A calls B | B shows the **in-app** overlay (not the FCM notification) | overlay "… is calling" | "Calling…" screen | ⬜ |
| B accepts | both land on the call page, timer runs both sides | `status=Connected` | `status=Connected` | ⬜ |
| A ends **or** B ends | **both** call pages close | call page pops | call page pops | ⬜ |

## Case 2 — B (Android) **minimized**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | B gets the full-screen **FCM call notification** | B: `[FCM-BG] call.ring → showIncomingCall`; notification ring shows | ⬜ |
| B accepts | both connect, timer runs | B: `Event.actionCallAccept` → `_handleAccept` → `POST /accept`; both `status=Connected` | ⬜ |
| After accept, **B ends** | A ends too | B: `Event.actionCallEnded`; A: `call.hangup` → page pops | ⬜ |
| (Re-test) **reject** | call ends both sides | B: `Event.actionCallDecline` → `POST /reject OK`; A stops ringing | ⬜ |

## Case 3 — B (Android) **killed**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | FCM cold-starts B → full-screen call notification | B: notification ring (app cold-starts) | ⬜ |
| B accepts | both connect | B: `_handleAccept` → `POST /accept`; both `status=Connected` | ⬜ |
| After accept, **B ends** | A ends too | A: page pops | ⬜ |
| (Re-test) **reject** | A stops ringing | B: `_handleDecline` → `POST /reject OK` (killed-app native reject) | ⬜ |

## Case 4 — B (Android) **killed + screen locked**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | full-screen call notification over the lock screen | ring on locked screen | ⬜ |
| B accepts | both connect | B: `_handleAccept`; both `status=Connected` | ⬜ |
| After accept, **B ends** | A ends too | A: page pops | ⬜ |
| (Re-test) **reject** | A stops ringing | B: `_handleDecline` → `POST /reject OK` | ⬜ |

## Case 5 — B **doesn't answer → timeout**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls, B ignores | at ~60 s **both** close together; logged as missed | A: "Calling…" closes; B: notification clears; status `MISSED`/`NO_ANSWER` both sides | ⬜ |

---

# Part D — Android → iOS  (caller = Android · callee = iOS)

## Case 1 — both **in-app (foreground)**

| Step | Expected (PASS) | Confirm — B (iOS) | Confirm — A (Android) | Result |
|---|---|---|---|---|
| A calls B | B shows the **in-app** overlay (not native CallKit) | overlay "… is calling" | "Calling…" screen | ⬜ |
| B accepts | both land on the call page, timer runs both sides | `status=Connected` | `status=Connected` | ⬜ |
| A ends **or** B ends | **both** call pages close | call page pops | call page pops | ⬜ |

## Case 2 — B (iOS) **minimized**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | B gets the **native CallKit** ring | B: CallKit screen shows | ⬜ |
| B accepts | both connect, timer runs | B: `notifyIncomingCallAnswered` → `POST /accept`; both `status=Connected` | ⬜ |
| After accept, **B ends** | A ends too | A: `call.hangup` → page pops | ⬜ |
| (Re-test) **reject** | call ends both sides | B: `POST /reject OK`; A stops ringing | ⬜ |

## Case 3 — B (iOS) **killed**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | B gets native CallKit ring (PushKit cold-starts the app) | B: CallKit screen | ⬜ |
| B accepts | both connect | B: `notifyIncomingCallAnswered` → `POST /accept`; both `status=Connected` | ⬜ |
| After accept, **B ends** | A ends too | A: page pops | ⬜ |
| (Re-test) **reject** | A stops ringing | B: `native End … direct reject POST … /reject OK` | ⬜ |

## Case 4 — B (iOS) **killed + screen locked**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls B | native CallKit ring on the lock screen | ring on locked screen | ⬜ |
| B accepts | both connect (native screen; no in-app UI on lock) | `status=Connected` both sides | ⬜ |
| After accept, **B ends** | A ends too | A: page pops | ⬜ |
| (Re-test) **reject** | A stops ringing | B: `direct reject POST … /reject OK` | ⬜ |

## Case 5 — B **doesn't answer → timeout**

| Step | Expected (PASS) | Confirm | Result |
|---|---|---|---|
| A calls, B ignores | at ~60 s **both** close together; logged as missed | A: "Calling…" closes; B: ring clears; status `MISSED`/`NO_ANSWER` both sides | ⬜ |

---

## Notes / capture tips
- iOS killed / locked B logs → **Console.app**, filter by app process.
- Android killed / locked B logs → **`adb logcat`**, filter the app.
- For ❌ rows, paste **both** A and B logs around the failing moment.
- The call **timeout (Case 5)** is server-driven for both platforms — 60 s
  Stream ring settings end A and B together.
- Known separate issue (NOT in this plan): a 2nd call to a **killed B**
  right after B declined call 1 — backend presence staleness; B is still
  treated ONLINE so call 2 routes as an in-app STOMP invite instead of an
  apn/FCM ring. Fix is server-side.

---

# Call-invite delivery flow (FCM)

End-to-end path for an outgoing call invite, and how the callee receives it
in each app state (foreground / background / killed):

```
Vibol's phone ── tap Call ── CallSignalingService
                                                └─ FcmInviteSender.send (HTTPS callable)
                                                          │
                                                          ▼
                                              Cloud Function `sendCallInvite`
                                                          │
                                            multicast FCM data message, priority=high
                                                          │
            ┌─────────────────────────┬─────────────────────────┬─────────────────────────┬─────────────────────────┐
            ▼                         ▼                         ▼                         ▼
   Pisey (foreground)        Pisey (background)         Pisey (killed)            Pisey (killed + locked)
   got it via WS already     background isolate fires   background isolate         background isolate cold-starts
   FCM ignored (callId       flutter_local_            cold-starts                full-screen-intent notif
   match)                    notifications             flutter_local_            (USE_FULL_SCREEN_INTENT +
                             heads-up shows            notifications              TURN_SCREEN_ON) wakes the
                             Accept/Reject             heads-up shows             screen, shows OVER lock
                             tap Accept →              Accept/Reject              Accept/Reject
                             overlay opens             tap Accept → app           tap Accept → device unlock
                                                       launches → overlay         prompt → app launches →
                                                       opens                      overlay opens
```

> **Killed + locked screen (Android):** the same FCM high-priority data message
> cold-starts the background isolate, but the notification is posted as a
> **full-screen intent** (manifest perms `USE_FULL_SCREEN_INTENT` +
> `TURN_SCREEN_ON`) so it **turns the screen on and shows over the lock
> screen**. Tapping **Accept** triggers the keyguard unlock prompt, then
> launches the app and opens the in-call overlay. **Reject** runs in the
> native receiver without unlocking (killed-app path → `POST /reject`).
