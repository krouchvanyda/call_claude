# ERP Mobile Chat Module — Full Process Guide & Test Cases

> Covers **Module 10 (Chat & Voice / Video)** end-to-end as built across
> slices 10.1.1 → 10.3.6. Use this as the functional reference + manual
> QA script. Implementation history lives in [`CLAUDE.md`](../CLAUDE.md);
> the FCM background-call plan lives in
> [`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md).

## Table of Contents

1. [Overview](#1-overview)
2. [Quick start — 3-device demo setup](#2-quick-start--3-device-demo-setup)
3. [Architecture at a glance](#3-architecture-at-a-glance)
4. [Feature areas & test cases](#4-feature-areas--test-cases)
   - [4.1 Setup & connection](#41-setup--connection)
   - [4.2 Identity & profile](#42-identity--profile)
   - [4.3 Inbox (conversation list)](#43-inbox-conversation-list)
   - [4.4 Direct messaging](#44-direct-messaging)
   - [4.5 Group messaging](#45-group-messaging)
   - [4.6 Real-time sync (preview & unread)](#46-real-time-sync-preview--unread)
   - [4.7 Message search](#47-message-search)
   - [4.8 Reactions, replies, edits, deletes](#48-reactions-replies-edits-deletes)
   - [4.9 Image upload & viewer](#49-image-upload--viewer)
   - [4.10 Voice messages](#410-voice-messages)
   - [4.11 Group create & management](#411-group-create--management)
   - [4.12 Group profile sync (name + avatar)](#412-group-profile-sync-name--avatar)
   - [4.13 Profile rename sync](#413-profile-rename-sync)
   - [4.14 Voice calls (direct)](#414-voice-calls-direct)
   - [4.15 Video calls (direct)](#415-video-calls-direct)
   - [4.16 Group calls — multi-party](#416-group-calls--multi-party)
   - [4.17 Call history](#417-call-history)
   - [4.18 Busy signal](#418-busy-signal)
   - [4.19 App lifecycle](#419-app-lifecycle)
5. [Known limitations](#5-known-limitations)
6. [Smoke-test checklist](#6-smoke-test-checklist)

---

## 1. Overview

Module 10 is a Telegram-style chat + voice/video stack built on a
WebSocket signalling relay. **No real backend, no SQLite, no WebRTC** —
the demo runs entirely on a LAN-local relay with in-memory state, but
the wire protocol, repository contracts, and UI surfaces match what a
production drift + FCM + WebRTC build would expose.

### What's real

| Capability | State |
|---|---|
| Chat inbox, conversations, search | ✅ in-memory, fully reactive |
| Send text / image / voice / file messages | ✅ wire-synced via WS |
| Reactions, replies, edits, soft delete | ✅ wire-synced |
| Group create, add members, rename, photo | ✅ wire-synced across devices |
| Direct contact photo | ✅ local only (per-device) |
| Voice + video call signalling | ✅ ceremony state machine over WS |
| Group call multi-party (independent accept, last-callee-out) | ✅ |
| Call history (inbox, chat timeline, Chat Info section, Calls tab) | ✅ |
| Profile rename sync | ✅ wire-synced |
| App lifecycle reconnect | ✅ on `AppLifecycleState.resumed` |

### What's stubbed / deferred

| Capability | Why |
|---|---|
| Real audio/video in calls | No WebRTC — the call page is signalling-only, no media flows. The timer ticks on both ends but there's no sound. |
| Backgrounded / killed-app call ringing | No FCM/APNs. See [`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md). |
| Image / voice / file binary transfer | Only the metadata syncs over WS. Local file paths don't exist on peer devices. |
| Persistent storage | Everything is in-memory; relaunching the app reloads the seed. |
| Auth, encryption, rate limiting | None — LAN demo only. |

---

## 2. Quick start — 3-device demo setup

Three physical Android devices on the same Wi-Fi network as your dev
machine. Two will work for direct-chat tests; three are required for
group calls / leakage tests.

### 2.1 Start the relay (one-time per session)

```bash
cd tools/chat_relay
dart pub get               # first time only
dart run bin/server.dart
```

The relay prints its address:

```
[14:01:02] relay listening on ws://0.0.0.0:7777
[14:01:02] LAN: connect phones with ws://<your-PC-IP>:7777
```

Find your PC's LAN IP (`ipconfig` on Windows, `ifconfig` / `ip addr` on
Linux/macOS). All three phones use that IP.

If Windows Firewall prompts, allow **Private** networks.

### 2.2 Build and install the app

```bash
flutter run --release -d <device-id>
# or
flutter install --release -d <device-id>
```

Repeat on each device. Release mode avoids dev-tool socket noise.

### 2.3 Wire each device's identity + relay

On every device:

1. Open the **Messages** tab.
2. Tap the **⋮** overflow menu → **Sign in as…** → pick a distinct
   identity per device. Suggested for 3-device testing:
   - Device A: `Demo Approver`
   - Device B: `Channary Pich`
   - Device C: `Vibol Sok`
3. Same menu → **Relay URL…** → enter:
   - Real phone on LAN: `ws://<your-PC-IP>:7777`
   - Android emulator: `ws://10.0.2.2:7777`
   - iOS simulator: `ws://127.0.0.1:7777`

### 2.4 Confirm connection

Look at the pill just below the AppBar on each device:

| Pill | Meaning |
|---|---|
| `Live · <host>:7777` (green) | Connected, ready |
| `Connecting…` (amber) | Trying to reach the relay |
| `Offline · check URL` (red) | Wrong URL, firewall, or relay not running |

The relay terminal also prints `+ client connected (from=emp-001)` for
each successful connection. All three must show green before running
any test.

---

## 3. Architecture at a glance

```
┌─────────────────────── per device ───────────────────────┐
│                                                          │
│   Pages (Inbox, Conversation, Chat Info, Calls)          │
│       │   reactive Stream / ValueNotifier subscriptions  │
│       ▼                                                  │
│   Repositories                                           │
│      ConversationsRepository — list + per-id watch       │
│      MessagesRepository      — per-conv messages         │
│      CallLogRepository       — chat_call_log timeline    │
│      ChatSettings            — identity + relay URL      │
│      ActiveConversationTracker — "which chat is open"    │
│       │                                                  │
│       ▼                                                  │
│   CallSignalingService (one-call-at-a-time state machine)│
│       │                                                  │
│       ▼                                                  │
│   ChatTransport (single WebSocket)                       │
│       ├── send envelopes (message / call / conv updates) │
│       └── receive → fan out to repos via bootChatTransport│
│                                                          │
└──────────────────────────────┬───────────────────────────┘
                               │  WebSocket frames
                               ▼
                  tools/chat_relay/bin/server.dart
                  (broadcasts each frame to every OTHER
                   connected socket — no identity, no auth)
```

### Wire envelopes (all in [`chat_transport.dart`](../lib/features/chat/data/chat_transport.dart))

| Envelope | Purpose | Slice |
|---|---|---|
| `hello` | Tag the socket with our identity for logging | 10.2.3 |
| `message.send` (with `targetIds`) | Text/image/voice/file message | 10.1.2 / 10.1.8 |
| `message.edit` | Edit an existing message | 10.1.2 |
| `message.delete` | Soft-delete a message | 10.1.2 |
| `reaction.toggle` | Toggle an emoji reaction | 10.1.2 |
| `conversation.create` | Broadcast a new group to its members | 10.1.7 |
| `conversation.update` | Group rename | 10.3.4 |
| `conversation.avatar.update` | Group photo (base64 bytes) | 10.3.6 |
| `profile.update` | User changed their display name | 10.3.4 |
| `call.invite` (with `targetIds`) | Place a call | 10.2.3 / 10.2.7 |
| `call.accept` (with `accepterId`) | Callee joins | 10.2.3 / 10.2.11 |
| `call.reject` (with `reason`) | Callee declines or busy | 10.2.3 / 10.2.4 |
| `call.hangup` (with `hangerUpperId`) | Either side leaves | 10.2.3 / 10.2.10 |

---

## 4. Feature areas & test cases

Each test follows the same shape:
- **Pre-conditions** — system state required before running
- **Steps** — numbered mechanical actions
- **Expected** — what should happen, with timing where relevant
- **If it fails** — most likely root cause

### 4.1 Setup & connection

#### TC-S.1 Relay reachable from all devices

**Pre-conditions:** Relay running; all devices configured (Section 2.3).

**Steps:**
1. Look at the connection pill under the AppBar on each device.
2. Look at the relay terminal output.

**Expected:**
- All three pills show green `Live · …`.
- Relay terminal lists three connected clients with distinct `from` tags.

**If it fails:**
- Pill amber/red → wrong URL or different Wi-Fi.
- Two on, one off → that device probably hasn't connected to the same
  Wi-Fi as the PC. Phones on cellular data **cannot** reach a LAN relay.
- Windows blocked: allow port 7777 on Private networks.

---

### 4.2 Identity & profile

#### TC-ID.1 Identity switch refreshes the chat

**Pre-conditions:** Device B currently signed in as Channary.

**Steps:**
1. Open **Messages** → ⋮ → **Sign in as…** → pick Vibol Sok.
2. Wait 1 second.

**Expected:**
- Connection pill briefly amber, then back to green (transport reconnects
  with new identity).
- Any open chat page rebuilds — bubbles you sent as Channary now show
  as "other person" left-aligned bubbles, because you're Vibol now.
- Relay terminal shows `+ disconnected (was emp-007)` then
  `+ connected (from=emp-006)`.

---

#### TC-ID.2 Profile rename propagates to peers

**Pre-conditions:** Device A signed in as Demo Approver. Device B signed
in as Channary. Device A has an existing direct conversation with
Channary.

**Steps:**
1. On Device A, go to **Settings → My Profile**.
2. Tap **Edit**, change the name from "Demo Approver" to "Demo Boss",
   tap **Save**.
3. On Device B, look at the inbox tile "Demo Approver" and the
   conversation AppBar if open.

**Expected:**
- Device B's inbox tile renames to "Demo Boss" within ~1 second.
- If Device B had the chat open, the AppBar updates live too.

**If it fails:**
- `ProfileUpdatedEvent` not firing → check that the name actually
  changed (no broadcast when name is unchanged).
- Peers don't update → confirm `bootChatTransport` is wiring
  `_applyInboundProfileUpdate` (Slice 10.3.4).

---

### 4.3 Inbox (conversation list)

#### TC-INB.1 Tabs filter correctly

**Steps:**
1. Open Messages.
2. Tap **All** / **Unread** / **Groups** / **Calls** tabs.

**Expected:**
- **All** shows every conversation.
- **Unread** only shows convs with `unreadCount > 0`.
- **Groups** filters to `isGroup == true`.
- **Calls** shows the global `chat_call_log` newest-first (Slice 10.2.5).

---

#### TC-INB.2 Search filters live

**Steps:**
1. Tap the search bar above the tile list.
2. Type a fragment of a contact's name (e.g. "vib").

**Expected:** Tiles filter as you type. Hitting × clears.

---

#### TC-INB.3 Swipe actions

**Steps:**
1. Swipe a tile **right** → tap the mute action.
2. Swipe a tile **left** → tap delete, confirm.

**Expected:**
- Mute toggles a bell-off icon on the tile.
- Delete removes the tile (only for the local device; doesn't broadcast).

---

### 4.4 Direct messaging

#### TC-DM.1 Send text — basic round-trip

**Pre-conditions:** Device A = Demo Approver. Device B = Channary. Both
green-connected.

**Steps:**
1. Device A: open the conversation with Channary Pich.
2. Type "hello" and tap send.

**Expected:**
- Device A: bubble appears right-aligned immediately, single grey check
  → upgrades to double check on relay echo.
- Device B's **inbox**: "Demo Approver" tile preview becomes `hello`
  with an unread badge (if not currently in that chat).
- Device B opens the chat: bubble appears left-aligned. Inbox unread
  badge clears on entry.

**If it fails:**
- Device B sees nothing → check `targetIds` are being included (Slice
  10.1.8). Without them, the message would be broadcast but the
  receiver may also be dropping based on conv-id mismatch.

---

#### TC-DM.2 Bug-fix verification: Vibol → Pisey does NOT leak to Channary

**Pre-conditions:** Device A = Vibol, Device B = Pisey, Device C = Channary.
All three connected.

**Steps:**
1. Device A (Vibol): open conv "Pisey Chhan", send "secret".

**Expected:**
- Device B (Pisey): inbox tile **"Vibol Sok"** preview updates to
  `secret`, unread badge +1.
- Device C (Channary): inbox **unchanged**. No tile updated, no
  unread badge bumped.

**Why it works:** The wire envelope's `targetIds = [emp-003]` (Pisey
only). Channary's transport drops the envelope before touching local
state (Slice 10.1.8 Bug A).

**If Channary's inbox DOES update** → `targetIds` filter regressed.

---

#### TC-DM.3 Bug-fix verification: Vibol → Pisey lands in Pisey's "Vibol Sok" tile

**Pre-conditions:** Same as TC-DM.2.

**Steps:**
1. Repeat TC-DM.2.

**Expected:** On Device B, the new preview lands in the **"Vibol Sok"**
tile — NOT in Pisey's "Pisey Chhan" self-direct slot.

**Why it works:** The receive handler calls `findDirectWith(senderId)`
and rewrites `m.conversationId` to the local conv with that sender
(Slice 10.1.8 Bug B).

---

#### TC-DM.4 "You:" prefix shows once, not twice

**Steps:**
1. Send any text/image/voice as Device A.
2. Look at Device A's own inbox tile preview.

**Expected:** Preview reads `You: hello` — never `You: You: hello`
(Slice 10.1.8 Bug C).

---

### 4.5 Group messaging

#### TC-GM.1 Group create propagates to all members

**Pre-conditions:** Device A = Demo, Device B = Channary, Device C = Vibol.

**Steps:**
1. Device A: Messages → **+ compose** → **Group** tab.
2. Select Channary + Vibol → tap **Create Group**.
3. Sheet asks for the group name → enter `TEST01`.
4. Watch all three devices.

**Expected:**
- Device A: jumps into the TEST01 chat.
- Device B (Channary) and Device C (Vibol) inboxes both show `TEST01`
  appear within ~1 second, **without** them needing to re-open the
  inbox.

**Why it works:** `conversation.create` envelope with `participantIds`
(Slice 10.1.7).

---

#### TC-GM.2 Group message reaches every member (and only them)

**Pre-conditions:** TC-GM.1 passes; fourth device D = Pisey (not in group).

**Steps:**
1. Device A sends "team meeting in 5" to TEST01.

**Expected:**
- Devices A, B, C all see the message bubble in TEST01.
- Device D's inbox is **unchanged**.

---

### 4.6 Real-time sync (preview & unread)

#### TC-RS.1 Inbox preview updates without re-opening

**Pre-conditions:** Device A + Device B, direct conv. Device B's
Messages tab is open.

**Steps:**
1. Device A sends 3 messages: "one", "two", "three" — wait ~1 s between.

**Expected:** On Device B, the conv's tile preview changes through
`one` → `two` → `three` live, **without** the user tapping anything.
The unread badge ticks 1 → 2 → 3.

**Why it works:** Slice 10.1.6 — `bootChatTransport` calls
`updateLastMessage` + `bumpUnread` on every inbound message.

---

#### TC-RS.2 Unread does NOT bump while user is reading

**Pre-conditions:** Device B has the direct chat with Device A **open**
(on the conversation page, not the inbox).

**Steps:**
1. Device A sends a message.

**Expected:** Device B sees the bubble appear in the chat; tile preview
in the inbox updates BUT unread badge does NOT increment (because
`ActiveConversationTracker.isActive(convId) == true`).

---

#### TC-RS.3 Image preview shows on inbox tile

**Steps:**
1. Device A sends an image via the attachment sheet (Camera or Gallery).

**Expected:**
- Device A's tile preview: `You: 📷 Photo` (single "You:" prefix).
- Device B's tile preview: `📷 Photo` (no "You:" prefix because they're
  not the sender).

---

### 4.7 Message search

#### TC-MS.1 Per-conversation search jumps to result

**Pre-conditions:** A conv with at least one text message containing
the word "jitter".

**Steps:**
1. Open the conv → tap the **⋮** menu → **Search messages**.
2. Type `jitter`.
3. Tap a result.

**Expected:** Conv re-opens scrolled to the matched message; that
message gets a 400 ms highlight pulse.

---

### 4.8 Reactions, replies, edits, deletes

#### TC-REA.1 Reaction toggles both sides

**Steps:**
1. Device A: long-press a bubble → tap 👍 from the emoji quick-bar.
2. Watch Device B.

**Expected:**
- Both devices show the reaction chip `👍 1` under the bubble.
- Device A tapping again removes their reaction → both sides see chip
  disappear.

---

#### TC-REP.1 Reply quote renders both sides

**Steps:**
1. Device A: long-press a bubble → **Reply** → type "agreed" → send.

**Expected:** Both devices show the new bubble with a quoted preview
of the parent bubble above it. Tapping the quote scrolls to + highlights
the original.

---

#### TC-EDT.1 Edit propagates

**Steps:**
1. Device A: long-press an own text bubble (within 15 min) → **Edit**
   → change text → tap save.

**Expected:** Both devices see the bubble update; small `(edited)`
label appears in the footer.

---

#### TC-DEL.1 Delete soft-deletes on both sides

**Steps:**
1. Device A: long-press an own bubble → **Delete for everyone**.

**Expected:** Bubble replaced with italic `Message deleted` on both
devices; no reactions, no reply affordance.

---

### 4.9 Image upload & viewer

#### TC-IMG.1 Send image from gallery

**Steps:**
1. Device A: in a conv, tap 📎 → **Gallery**.
2. Pick an image.

**Expected:**
- Bubble appears with the image rendered via `Image.file()` on
  Device A. Tap → opens full-screen `ImageViewerPage` (pinch-zoom,
  drag-down-to-dismiss).
- Device B: bubble appears too, but tapping shows a placeholder
  ("Image not available on this device") because only metadata syncs
  over the wire (the actual bytes never transferred).

---

#### TC-IMG.2 Inbox tile reflects image send

**Steps:** Continue from TC-IMG.1.

**Expected:** Both inboxes update the conv preview to `📷 Photo`
(Device A sees `You: 📷 Photo`).

---

### 4.10 Voice messages

#### TC-VM.1 Send voice clip

**Steps:**
1. Device A: in a conv, tap 📎 → **Voice** → confirm.

**Expected:**
- Bubble appears showing the voice play UI with `0:03` duration.
- Both inboxes update to `🎤 Voice message · 0:03`.
- Tapping play on Device A toggles a play indicator (no actual audio —
  Slice 10.1.5 is metadata-only).

---

### 4.11 Group create & management

#### TC-GMG.1 Add members (admin)

**Pre-conditions:** Existing group TEST01 with Demo + Channary + Vibol.
Pisey is NOT a member. Device A is the admin (creator).

**Steps:**
1. Device A: open TEST01 → AppBar tap (or ⋮) → **Chat Info** →
   tap **Add members**.
2. Multi-select Pisey → confirm.

**Expected:**
- Device A: members section + AppBar member count update.
- Device D (Pisey): TEST01 appears in her inbox.

> ⚠️ Add-members broadcast is currently only documented in Slice 10.3.2
> as a local-only operation. Cross-device sync of add-members may need
> the same envelope pattern as `conversation.create` if not yet wired.

---

#### TC-GMG.2 Rename group propagates

**Steps:**
1. Device A: TEST01 Chat Info → tap the group name → enter `RENAMED01`
   → Save.

**Expected:** All members' inbox tiles + AppBars update to `RENAMED01`
live (Slice 10.3.4 — `conversation.update` envelope).

---

### 4.12 Group profile sync (name + avatar)

#### TC-GP.1 Group avatar set syncs to all members

**Pre-conditions:** Same group, Device A is admin.

**Steps:**
1. Device A: TEST01 Chat Info → tap the group avatar in the hero.
2. Choose **Gallery** → pick any image.

**Expected:**
- Device A: hero + AppBar + inbox tile all show the new photo.
- Devices B, C, D (members): same — their inbox tile, AppBar, and Chat
  Info hero all show the photo within ~1–2 s after the picker closes.
- Relay terminal shows a `conversation.avatar.update` envelope being
  forwarded (~50–200 KB base64 payload).

**Why it works:** Slice 10.3.6 — the bytes are base64-encoded and
broadcast; each receiver writes them to
`getApplicationCacheDirectory()/chat_avatar_<convId>.<ext>` and updates
`avatarFilePath`.

**If it fails on a peer:**
- Cache directory write failed → check `path_provider` permissions.
- Avatar shown only on sender → broadcast path missing the
  `sendConversationAvatar` call from `_pickGroupPhoto`.

---

#### TC-GP.2 Remove group photo clears on all members

**Steps:**
1. Device A: TEST01 Chat Info → tap hero → **Remove photo**.

**Expected:** All members revert to the 3-avatar cluster fallback
within ~1 s.

---

#### TC-GP.3 Direct contact photo is per-device only

**Steps:**
1. Device A: open the direct conv with Vibol → AppBar → Chat Info
   → tap hero → pick a photo.

**Expected:**
- Device A: hero + AppBar + inbox tile show the photo.
- Device C (Vibol): nothing changes on his side.

**Why:** Direct photos are explicitly NOT broadcast (Slice 10.3.5) —
they're personal "set contact photo" overrides.

---

### 4.13 Profile rename sync

Already covered by [TC-ID.2](#tc-id2-profile-rename-propagates-to-peers).

---

### 4.14 Voice calls (direct)

#### TC-VC.1 Direct voice call — happy path

**Pre-conditions:** Device A = Demo, Device B = Channary. Both green.

**Steps:**
1. Device A: open the direct conv with Channary → tap the 📞 voice
   call icon.
2. Device B's screen: full-screen incoming sheet appears within ~500 ms.
3. Device B: tap **Accept**.

**Expected:**
- Device B's call page opens within ~300 ms of tapping Accept.
- Both devices show the connected state with a ticking timer.
- A `chat_call_log` row is written on both sides with
  `status: answered`.

**If Accept "just closes":** Slice 10.2.9 fix is regressed. The push
must use `AppRouter.rootNavigatorKey.currentState!.push(...)`, not
`Navigator.of(context)` from inside the overlay context.

---

#### TC-VC.2 Bug-fix verification: only the targeted callee rings

**Pre-conditions:** Device A = Demo, Device B = Channary, Device C = Vibol.

**Steps:**
1. Device A calls Channary directly (NOT a group).

**Expected:** Only Device B rings. Device C's screen stays silent.

**Why:** `targetIds = [emp-007]` in the `call.invite` envelope
(Slice 10.2.7). Without this, every connected client would ring.

---

#### TC-VC.3 End-call writes inbox summary

**Steps:**
1. Continue from TC-VC.1 → either side taps End after the call is
   connected for 5+ seconds.

**Expected:**
- Both devices' inbox tile for the direct conv now reads
  `📞 Voice call · 0:05` (caller sees `You: 📞 …`).
- On Device A, the sender's tile points to **their** "Channary Pich"
  conv; on Device B, the summary lands in **her** "Demo Approver" tile
  (Slice 10.2.11 Bug C — redirected via `findDirectWith`).

---

#### TC-VC.4 Reject writes "Declined"

**Steps:**
1. Device A calls Channary; Device B taps **Reject**.

**Expected:** Both inboxes show `📞 Declined voice call` for the
direct conv.

---

#### TC-VC.5 Missed call writes "Missed"

**Steps:**
1. Device A calls; let it ring 30+ seconds without Device B answering.

**Expected:** The 30 s ring timeout fires, both sides show `📞 Missed
voice call` on the inbox tile.

---

### 4.15 Video calls (direct)

Same patterns as voice. Differences:

| Aspect | Voice | Video |
|---|---|---|
| Tap to start | 📞 icon | 🎥 icon |
| Permissions requested | microphone | mic + camera |
| In-call page | Avatar + waveform | Black bg + camera placeholder |
| Inbox summary | `📞 Voice call · …` | `📹 Video call · …` |

#### TC-VID.1 Video call happy path

Same steps as TC-VC.1 with the 🎥 icon. Expected: in-call page shows
the video placeholders; summary on end is `📹 Video call · 0:05`.

---

### 4.16 Group calls — multi-party

#### TC-GC.1 Group call — basic 3-party connect

**Pre-conditions:** Group TEST01 with Demo + Channary + Vibol. All three
devices connected.

**Steps:**
1. Device A (Demo): open TEST01 → tap 📞.
2. Devices B + C: both see the incoming sheet showing **"TEST01"** as
   the title (NOT "Demo Approver") with subtitle `Demo Approver is
   calling…` and the group icon (or group photo if set —
   Slices 10.2.9 / 10.2.11).
3. Both tap Accept.

**Expected:** All three call pages connected, timer ticking on each.

---

#### TC-GC.2 Independent accept — one callee rings while the other is still ringing

**Steps:**
1. Device A starts a group call.
2. Device B taps Accept immediately.
3. Device C's sheet is **still showing** with the Accept/Reject buttons
   active.
4. Device C taps Accept ~10 s later.

**Expected:** All three end up connected. Device C's sheet was not
prematurely closed by Device B's acceptance (Slice 10.2.8 Bug B).

**If Device C's sheet disappears when Device B accepts** → regression.
The fix is the `state != outgoingRinging` early-return in
`CallAcceptEvent` handler.

---

#### TC-GC.3 Non-caller hangup doesn't kill the group

**Pre-conditions:** TC-GC.1 connected; all three in the call.

**Steps:**
1. Device B (Channary, a callee) taps End.

**Expected:**
- Device B's call page closes.
- Devices A (caller) and C (Vibol) **stay connected**; their timers
  keep ticking.
- Slice 10.2.10 in action — `hangerUpperId` is not the caller's id,
  so other devices drop the event.

---

#### TC-GC.4 Last callee leaves → caller auto-ends

**Pre-conditions:** Continue from TC-GC.3. Demo + Vibol are still in
the call.

**Steps:**
1. Device C (Vibol, last remaining callee) taps End.

**Expected:**
- Device C's call page closes.
- Device A's call page **automatically ends** within ~1 s (Slice 10.2.11
  Bug A — `_activeCallees` set drained to empty triggers the caller's
  own `hangup(...)`).

**If Device A is left alone with a running timer** → regression. Check
that `CallAcceptEvent` populates `_activeCallees` and that
`CallHangupEvent` removes from it.

---

#### TC-GC.5 Caller End kills the call for everyone

**Pre-conditions:** Group call connected, all three in.

**Steps:**
1. Device A (caller) taps End.

**Expected:** All three call pages close within ~1 s. Inbox tile on all
three shows `📞 Voice call · <duration>`.

---

### 4.17 Call history

#### TC-CH.1 Inbox tile shows call summary (Slice 10.2.10)

Already covered by [TC-VC.3 / VC.4 / VC.5](#414-voice-calls-direct).

---

#### TC-CH.2 Calls tab in the inbox

**Steps:**
1. Make a few calls (mix of answered, missed, declined).
2. Open Messages → **Calls** tab.

**Expected:** List of call entries newest-first, each with:
- Direction badge on the avatar (call_made / call_received / call_missed)
- Caller/peer name
- Type icon (📞 / 📹) and duration or "Missed"
- Relative timestamp
- Tap → re-opens the matching voice/video page (1-tap redial)

---

#### TC-CH.3 Chat Info — per-conversation call history (Slice 10.2.5)

**Steps:**
1. Open a conv with call history → AppBar → Chat Info.
2. Scroll to the **Recent calls** section.

**Expected:** Last 6 entries listed with direction icons, missed in
red, duration, timestamp. Tap an entry to redial.

---

#### TC-CH.4 Inline call history in the chat (Slice 10.1.9)

**Pre-conditions:** A conv with both messages and at least one call log
entry.

**Steps:**
1. Open the conversation page.

**Expected:**
- Messages and call entries appear interleaved by time on the timeline.
- Call entries render as compact bubbles:
  - Direction icon (call_made for own outgoing, call_received for
    incoming, call_missed for missed/no-answer)
  - Title ("Voice call" / "Missed video call" / "Declined voice call")
  - Duration or HH:MM stamp
  - Tap → redials (opens the matching voice/video page)
- Date separators still render correctly; sender groupings reset after a
  call entry so the next message re-prints its header.

---

#### TC-CH.5 AppBar avatar reflects user-set photo (Slice 10.1.9)

**Pre-conditions:** A group with a custom photo (after TC-GP.1) or a
direct conv with a contact photo (after TC-GP.3).

**Steps:**
1. Open that conv.

**Expected:** AppBar avatar shows the photo, not the cluster (for
groups) or initials (for direct).

---

### 4.18 Busy signal

#### TC-BSY.1 Second incoming call while mid-call

**Pre-conditions:** Devices A, B, C. A is in an active 1:1 call with B.

**Steps:**
1. Device C tries to call Device A (direct).

**Expected:**
- Device A's call with B continues unaffected.
- Device C's call page shows:
  - Status text: **Busy** instead of "Call ended"
  - A floating snackbar: `"<Name> is on another call."`
- A `chat_call_log` row is written on Device C with `status: rejected`,
  reason `'busy'`.

**Why:** Slice 10.2.4 — `CallSignalingService` auto-rejects with
`reason: 'busy'` when an invite arrives while `_active` is in
`outgoingRinging` or `connected` (and not in `incomingRinging`/`ended`).

---

### 4.19 App lifecycle

#### TC-LC.1 Foreground resume re-validates the socket

**Pre-conditions:** Device A connected (green).

**Steps:**
1. Disable Wi-Fi briefly (5 s) → pill flips amber/red.
2. Press home → app backgrounded.
3. Re-enable Wi-Fi.
4. Tap the app icon to return.

**Expected:** Pill flips back to green within a few seconds. Any messages
that were sent to Device A by peers while disconnected will NOT replay
(the relay has no history — Slice 10.2.6 honest limitation).

---

#### TC-LC.2 Backgrounded call → MISSED

**Pre-conditions:** Device A foreground, Device B backgrounded (home
pressed, screen off OK).

**Steps:**
1. Device A calls Device B.
2. Wait 30+ seconds without bringing Device B back to foreground.

**Expected:**
- Device B's ring timeout fires; no incoming sheet ever shows.
- Device A sees the timeout and the call ends as `Missed`.
- Both inboxes show `📞 Missed voice call`.

**This is the limitation that FCM would fix** — see
[`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md).

---

## 5. Known limitations

| Limitation | Why | Mitigation |
|---|---|---|
| Backgrounded / killed-app calls show as missed | No FCM / push wake-up | Implement FCM ([`FCM_BACKGROUND_CALLS_PLAN.md`](./FCM_BACKGROUND_CALLS_PLAN.md)) |
| No actual audio/video in calls | No WebRTC | Add `flutter_webrtc` + SDP exchange over the existing transport (see Slice 10.2.3 comment) |
| Image/voice/file binaries don't transfer | Only metadata in the wire envelope | Add a multipart upload endpoint + URL in the message payload |
| Relay has no history | In-memory only | Add SQLite-backed message store on the relay side, or pivot to Firestore |
| Direct contact photo is per-device | Avatar broadcast would need an upload endpoint | Add image upload to a server; broadcast URL instead of base64 |
| No auth / no encryption | LAN demo | Out of scope |
| OEM battery saver kills background isolates | Android-vendor specific | First-launch prompt to disable optimization (per-app) |

---

## 6. Smoke-test checklist

Run this 5-minute sweep after every chat-related change. If any item
fails, do not ship.

- [ ] All 3 phones connect, pill green
- [ ] Direct chat round-trip (TC-DM.1)
- [ ] No cross-user leakage (TC-DM.2)
- [ ] Inbox preview + unread bump live (TC-RS.1)
- [ ] Group create propagates to all members (TC-GM.1)
- [ ] Group rename propagates (TC-GMG.2)
- [ ] Group avatar set propagates (TC-GP.1)
- [ ] Direct voice call accept → in-call page opens (TC-VC.1)
- [ ] Targeted call routing — third phone stays silent (TC-VC.2)
- [ ] Group call: callee End doesn't kill the group (TC-GC.3)
- [ ] Group call: last callee End auto-ends caller (TC-GC.4)
- [ ] Call summary appears on inbox tile after End (TC-VC.3)
- [ ] Inline call entries in the chat timeline (TC-CH.4)
- [ ] AppBar avatar reflects user-set photo (TC-CH.5)
