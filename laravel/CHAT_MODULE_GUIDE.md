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

---

## 7. Backend integration prompts

These prompts migrate the Flutter app from the LAN-only `tools/chat_relay`
to the **real ERP backend** (`features/chats/` — STOMP over WebSocket +
REST, JWT-authenticated). They're meant to be **pasted one at a time** into
Claude / Cursor / your AI of choice. Each one is self-contained: it lists
the files to read, the goal, the wire contracts, and the acceptance
criteria.

### Backend reference (read first, every time)

| Surface       | URL                                                              |
|---------------|------------------------------------------------------------------|
| Login         | `POST   /api/v1/auth/login`                                       |
| Refresh       | `POST   /api/v1/auth/refresh`                                     |
| Conversations | `GET|POST /api/v1/chats/conversations`, `GET|PATCH /…/{id}`       |
| Members       | `POST /…/{id}/members`, `DELETE /…/{id}/members/{userId}`        |
| Mark read     | `POST /…/{id}/read`                                              |
| Messages      | `GET|POST /…/{id}/messages`, `PATCH|DELETE /api/v1/chats/messages/{id}` |
| Reactions     | `POST /api/v1/chats/messages/{id}/reactions`                     |
| Calls         | `POST /…/{id}/calls`, `POST /api/v1/chats/calls/{id}/accept|reject|end` |
| Call history  | `GET /api/v1/chats/calls`, `GET /…/{id}/calls`                   |
| STOMP         | `ws://<host>/ws`  (header `Authorization: Bearer <accessToken>` on CONNECT) |

STOMP destinations + envelope shape:

```
/topic/conversations/{convId}        — public message + conversation events
/topic/conversations/{convId}/call   — public call state transitions
/user/queue/inbox                    — per-user inbox previews
/user/queue/calls                    — per-user incoming-call invites

Every frame is wrapped:
{ "event": "<wire-name>", "payload": { …concrete DTO… } }
```

Event names match the originals in Section 3 (`message.send`,
`message.edit`, `message.delete`, `reaction.toggle`,
`conversation.create`, `conversation.update`, `call.invite`,
`call.accept`, `call.reject`, `call.hangup`).

---

### Prompt 0 — Project bootstrap, deps, token storage

```
You are extending an existing Flutter app at `lib/features/chat/`.
Today the chat talks to a LAN-local relay over a custom JSON-over-WebSocket
protocol (see `lib/features/chat/data/chat_transport.dart` and
`tools/chat_relay/bin/server.dart`). It must now talk to the real ERP
backend instead.

Read first:
- `lib/features/chat/data/chat_transport.dart`
- `lib/features/chat/data/chat_settings.dart`
- Section "7. Backend integration prompts" of `CHAT_MODULE_GUIDE.md`

Goal: lay down the HTTP + auth foundation BEFORE touching repositories.

Tasks:
1. Add dependencies to `pubspec.yaml`:
   - `dio: ^5`
   - `stomp_dart_client: ^2` (or current latest)
   - `flutter_secure_storage: ^9`
2. Create `lib/core/network/api_client.dart`:
   - Wraps Dio
   - Reads base URL from `ChatSettings.apiBaseUrl` (add this field —
     replaces `relayUrl`). Default e.g. `http://10.0.2.2:8080` for emulator.
   - Injects `Authorization: Bearer <access>` on every request
   - On 401 → calls `AuthRepository.tryRefresh()` once, retries; if refresh
     fails, emits a `loggedOut` stream that the UI subscribes to
3. Create `lib/features/auth/data/auth_repository.dart`:
   - `Future<void> login(String email, String password)` →
     POST /api/v1/auth/login, stores access + refresh in
     flutter_secure_storage under `auth.access` / `auth.refresh`
   - `Future<bool> tryRefresh()` → POST /api/v1/auth/refresh with the stored
     refresh token; rotates both tokens
   - `Future<void> logout()` → POST /api/v1/auth/logout + clear storage
   - Stream<AuthState>: `unknown | loggedIn | loggedOut`
4. Add a `LoginPage` reachable when AuthState is `loggedOut`.

Acceptance:
- App boots → if no stored token, shows login.
- Successful login transitions to the Messages tab.
- Killing the app and relaunching keeps you logged in.
- Manually delete the access token from storage → next API call hits 401,
  silently refreshes, and the user stays in.
- Set refresh token to garbage → next 401 triggers logout to the login page.

Don't:
- Don't touch chat_transport.dart, repositories, or pages yet.
- Don't store tokens in SharedPreferences (must be flutter_secure_storage).
```

---

### Prompt 1 — Replace `chat_transport.dart` with a STOMP client

```
Goal: swap the relay-protocol WebSocket in `chat_transport.dart` for a
real STOMP client against the ERP backend at `ws://<host>/ws`. Keep the
public API stable so repositories don't need to change yet.

Read first:
- `lib/features/chat/data/chat_transport.dart` — the current public surface
  (sendMessage, sendReaction, sendCallInvite, …)
- The backend reference in Section 7 of CHAT_MODULE_GUIDE.md

Tasks:
1. Replace the relay socket with `StompClient` (stomp_dart_client).
   - `connect`: open `ws://<host>/ws`, set CONNECT header
     `Authorization: Bearer <accessToken>` from AuthRepository
   - On `onConnect`:
       * subscribe `/user/queue/inbox`
       * subscribe `/user/queue/calls`
       * subscribe `/topic/conversations/{id}` and
         `/topic/conversations/{id}/call` per ACTIVE conversation
         (manage subscriptions as conversations are opened / closed)
   - Auto-reconnect with exponential backoff capped at 30s
   - On disconnect, flip a `connectionState` ValueNotifier the AppBar pill
     reads (Live / Connecting / Offline) — replaces the current relay pill
2. Every inbound frame body is JSON:
   `{ "event": "<name>", "payload": { … } }`
   - Dispatch by `event` to the existing inbound handlers
     (`_applyInboundMessage`, `_applyInboundReaction`,
     `_applyInboundCallInvite`, etc.). Keep handler signatures —
     only the parsing changes.
3. Outbound `sendXxx(...)` methods now POST to REST endpoints instead of
   pushing WS frames. Map each:
   - `sendMessage(...)`        → POST /api/v1/chats/conversations/{id}/messages
   - `editMessage(...)`        → PATCH /api/v1/chats/messages/{id}
   - `deleteMessage(...)`      → DELETE /api/v1/chats/messages/{id}
   - `toggleReaction(...)`     → POST /api/v1/chats/messages/{id}/reactions
   - `sendConversationCreate`  → POST /api/v1/chats/conversations
   - `sendConversationUpdate`  → PATCH /api/v1/chats/conversations/{id}
   - `sendConversationAvatar`  → PATCH /api/v1/chats/conversations/{id}
     (avatarUrl only — upload bytes endpoint is out of scope; see Prompt 5)
   - `sendCallInvite`          → POST /api/v1/chats/conversations/{id}/calls
   - `sendCallAccept`          → POST /api/v1/chats/calls/{id}/accept
   - `sendCallReject(reason)`  → POST /api/v1/chats/calls/{id}/reject?reason=…
   - `sendCallHangup`          → POST /api/v1/chats/calls/{id}/end
   - The reactive update no longer comes from the local outbound — wait for
     the STOMP fan-out instead. Drop optimistic-local writes for now (we'll
     re-introduce them in Prompt 4).

Acceptance:
- App connects on first foreground; pill goes green.
- Background → resume reconnects without app restart.
- Two devices, A sends a text — B's `/topic/conversations/{id}` subscription
  fires `_applyInboundMessage` and the bubble appears.

Don't:
- Don't touch the `chat_relay` folder yet (will delete in the final prompt).
- Don't break the in-conv state machine of CallSignalingService — only the
  transport layer underneath it should change.
```

---

### Prompt 2 — Conversations repository (REST list + STOMP inbox)

```
Goal: rewrite `ConversationsRepository` so the inbox is sourced from the
backend instead of the seed file.

Read first:
- `lib/features/chat/data/conversations_repository.dart`
- The `ConversationDto` shape returned by GET /api/v1/chats/conversations:
  { id, type (DIRECT|GROUP), name, avatarUrl, members[],
    lastMessage, lastMessageAt, unreadCount, createdAt }

Tasks:
1. `Future<void> loadInbox()` — GET /api/v1/chats/conversations?page=1&pageSize=50
   - Hydrate the local cache (Map<Long, ConversationModel>)
   - Notify subscribers
2. Subscribe to `/user/queue/inbox` (already wired in Prompt 1). Handle
   inbound events:
   - `conversation.create` → upsert
   - `conversation.update` → patch fields (name, avatarUrl, lastMessage…)
   - `conversation.remove` → remove from cache (you were removed as a member)
   - `message.send` (inbox channel) → bump preview + unreadCount if the
     conv isn't active per `ActiveConversationTracker`
3. `Future<ConversationModel> createDirect(int otherUserId)` →
   POST /api/v1/chats/conversations { "type":"DIRECT", "memberIds":[otherUserId] }
4. `Future<ConversationModel> createGroup(String name, Set<int> memberIds)` →
   POST /api/v1/chats/conversations { "type":"GROUP", "name":…, "memberIds":[…] }
5. `findDirectWith(senderId)` — return the local model that matches
   type=DIRECT and members contain (me + senderId). Used by inbound
   redirection.

Acceptance:
- Cold start with empty seed shows the user's actual inbox from the server.
- TC-DM.1 (direct send) still works end-to-end with the real server.
- TC-GM.1 (group create propagates) still works — the second device receives
  `conversation.create` over `/user/queue/inbox` and the tile appears
  without re-opening the inbox.

Don't:
- Don't store conversations to local SQLite yet — keep in-memory cache.
  (Persistence is a future slice.)
- Don't filter by `targetIds` on the client anymore — the backend already
  routes by membership.
```

---

### Prompt 3 — Messages repository (history + send + topic)

```
Goal: messages now come from REST history + STOMP topic, not the seed.

Read first:
- `lib/features/chat/data/messages_repository.dart`
- `MessageDto` shape from GET /api/v1/chats/conversations/{id}/messages:
  { id, conversationId, senderId, type, body, attachmentUrl,
    attachmentContentType, attachmentSizeBytes, durationSeconds,
    replyToMessageId, editedAt, deleted, reactions[], createdAt }
- The `PageResponse<T>` envelope: { items[], page, pageSize, totalItems, totalPages }

Tasks:
1. `Stream<List<MessageModel>> watch(int convId)` — backed by an in-memory
   list + a StreamController. Initial load: GET /…/messages?page=1&pageSize=30.
2. Subscribe `/topic/conversations/{convId}` on `watch(...)`. Inbound events
   → mutate the list:
   - `message.send`     → append (skip if id already exists — own send echo)
   - `message.edit`     → replace by id
   - `message.delete`   → mark deleted in place (body=null, deleted=true)
   - `reaction.toggle`  → replace `reactions` on the message id from payload
3. `Future<MessageModel> send(int convId, SendMessageRequest req)` →
   POST /…/{convId}/messages. Return the created DTO; don't insert manually —
   the STOMP echo will deliver it. (If the round-trip pause is jarring,
   insert a temp model with a client-side uuid and reconcile on echo by
   `replyToMessageId`+`createdAt` — only do this if UX testing demands it.)
4. Add a 30-line page-up loader on scroll → `?page=N` for older history.

Acceptance:
- Open a conv with existing history → the most recent 30 messages render.
- Scroll up → next page loads.
- TC-EDT.1: edit on Device A → Device B sees the bubble change live.
- TC-DEL.1: delete on Device A → Device B sees "Message deleted" italic.

Don't:
- Don't try to download image / voice bytes — `attachmentUrl` is a relative
  URL; tap → open with `url_launcher` or render via `Image.network` once an
  upload endpoint exists (out of scope here).
- Don't reimplement the 15-min edit window in the client — the server
  enforces it (returns 400 BAD_REQUEST). Surface that error in a snackbar.
```

---

### Prompt 4 — Reactions, replies, optimistic updates

```
Goal: the reaction quick-bar, reply quoting, and an *optional* optimistic
local insert when sending text.

Read first:
- Prompt 3 result + reaction UI in `lib/features/chat/ui/message_bubble.dart`
- `MessageDto.reactions[]` shape: [{ userId, emoji }, …]

Tasks:
1. Reaction toggle:
   - Tap the 👍 quick-bar → call MessagesRepository.toggleReaction(messageId, emoji).
     That POSTs /api/v1/chats/messages/{id}/reactions and returns the new
     reactions list — STOMP echo will also fire for everyone (including the
     sender), so don't insert locally; just wait for echo.
2. Reply:
   - Long-press → "Reply" sets a `replyTo` model on the composer state.
   - Send → SendMessageRequest.replyToMessageId = parent.id.
   - Render: load `replyToMessageId` from the local list to draw the quote
     preview. If the parent isn't loaded yet (older than the loaded page),
     fall back to "Message" and lazy-load by id (GET single message endpoint
     does not exist server-side — keep the fallback simple, or extend the
     backend with `GET /api/v1/chats/messages/{id}` later).
3. Optional optimistic local insert for TEXT messages only:
   - On send, push a temp model with `id = -clientLocalNonce` (negative) and
     `status = sending`. When the STOMP echo arrives with a real id and the
     same `body + sender + within 5s`, reconcile by replacing the temp.

Acceptance:
- TC-REA.1: tap 👍 → chip appears on both sides; tap again → disappears.
- TC-REP.1: reply renders quote on both sides; tap quote scrolls to parent.
- Optimistic mode: typing & sending feels instant; no duplicate bubbles
  appear after the echo arrives.

Don't:
- Don't allow reactions on deleted messages — disable the long-press menu
  when `model.deleted == true`.
```

---

### Prompt 5 — Group management (members + rename + avatar URL)

```
Goal: Chat Info → add members / rename / set avatar work against the real
server.

Read first:
- `lib/features/chat/ui/chat_info_page.dart`
- Backend: POST /…/{id}/members (admin), DELETE /…/{id}/members/{userId},
  PATCH /…/{id} (name + avatarUrl).
- Members must come from the User module: extend
  `lib/features/users/data/users_repository.dart` with a paginated
  GET /api/v1/users?page=&pageSize=&search= so the "Add members" sheet can
  pick from real users instead of the seed.

Tasks:
1. Replace the local-seed member picker with the paginated users endpoint.
2. Wire Add Members → POST /…/{id}/members { memberIds: [...] }.
3. Wire "Leave group" (own row) → DELETE /…/{id}/members/{me}.
4. Wire Remove Member (admin row) → DELETE /…/{id}/members/{userId}.
5. Wire Rename → PATCH /…/{id} { name: "..." }.
6. Avatar (URL only for now):
   - The server stores `avatarUrl` as a plain string.
   - Add a text input that accepts a URL (e.g. uploaded elsewhere) and
     PATCH it. The "pick from gallery → base64 broadcast" path from the
     dev relay is gone; that flow needs a backend upload endpoint
     (analogous to the employees-avatar upload), which is out of scope.

Acceptance:
- TC-GMG.1: Add Members on Device A → the new member's inbox tile appears
  on Device D within ~1s (via `conversation.update` on `/user/queue/inbox`).
- TC-GMG.2: Rename → AppBars + inbox tiles update live on all members.
- Removing yourself takes you back to the inbox; the tile disappears.

Don't:
- Don't broadcast member-list deltas from the client — the server is the
  single source of truth, and a `conversation.update` envelope already fans
  the new state out.
```

---

### Prompt 6 — Mark-as-read + unread counter

```
Goal: opening a conversation marks it read on the server; unread badges
reflect the server count.

Read first:
- `ConversationDto.unreadCount` (server-computed from lastReadMessageId)
- `ActiveConversationTracker` — already tracks "which conv is open"

Tasks:
1. When the conv page opens AND messages load, send the newest visible
   message id to POST /…/{convId}/read { lastReadMessageId: <max id> }.
2. Debounce: only POST once per 1-second window of scrolling activity, and
   always send the maximum-seen id.
3. The response is the updated ConversationDto with unreadCount=0 — patch
   the local cache. The server also fans `conversation.update` to other
   sessions of the same user via `/user/queue/inbox` — handle in the inbox
   subscription so a second device sees the badge clear in real time.

Acceptance:
- TC-RS.2: open a chat that's receiving messages → unread badge stays 0,
  messages render in the chat as they arrive.
- Open the same chat on a second logged-in session of the same user →
  unread clears on the other session too.

Don't:
- Don't decrement unread locally; always rely on the server-emitted count.
```

---

### Prompt 7 — Voice / video call ceremony

```
Goal: wire the existing `CallSignalingService` state machine to the real
backend. Media (WebRTC) is out of scope — the call page stays
signalling-only (timer ticks, no audio).

Read first:
- `lib/features/chat/data/call_signaling_service.dart`
- `lib/features/chat/data/call_log_repository.dart`
- Backend: POST /…/{convId}/calls, POST /api/v1/chats/calls/{id}/accept,
  /reject, /end; GET /api/v1/chats/calls (paginated); GET /…/{convId}/calls.
- STOMP destinations: `/user/queue/calls` (incoming invites) and
  `/topic/conversations/{convId}/call` (state transitions).

Tasks:
1. Start a call → POST /…/{convId}/calls { type: "VOICE" | "VIDEO" }.
   The response is a `ChatCallDto`. Store it as `_active` in the
   signalling service.
2. Subscribe `/user/queue/calls` globally (wired in Prompt 1). When a
   `call.invite` arrives:
   - If `_active` is RINGING or CONNECTED → server already auto-rejected
     with reason=busy; nothing to do client-side.
   - Else: open the incoming-call sheet (root-navigator push, per Slice
     10.2.9). The payload has the full ChatCallDto including
     `conversationId` so you can title the sheet correctly.
3. Subscribe `/topic/conversations/{convId}/call` for the active conv.
   Inbound events:
   - `call.accept`  → if accepterId is one of the callees, move state to
     CONNECTED. Maintain a local `Set<int> activeCallees` from
     ChatCallDto.participants where status=ANSWERED.
   - `call.reject`  → drop callee from set; surface "Declined" if it was
     the only callee (1:1 case).
   - `call.hangup`  → if hangerUpperId == callerId → close call page for
     everyone (Slice 10.2.10). Else drop from `activeCallees`; if empty,
     auto-end (Slice 10.2.11).
4. Reject / Accept / End buttons → corresponding REST POSTs. Drop the
   "broadcast my decision over WS" path entirely.
5. Call history:
   - Inbox "Calls" tab → GET /api/v1/chats/calls?page=1&pageSize=50.
   - Chat Info "Recent calls" → GET /…/{convId}/calls?page=1&pageSize=6.
   - Inline call entries on the chat timeline (TC-CH.4): merge the
     conversation's call list with the message stream by createdAt. Render
     a compact "call bubble" widget identical to today.

Acceptance:
- TC-VC.1: Device A calls B → B sees the sheet within ~500ms; Accept opens
  the in-call page; both timers tick.
- TC-VC.4: Reject writes "📞 Declined voice call" on both inbox tiles.
- TC-GC.3: callee End leaves caller + remaining callee connected.
- TC-GC.4: last callee End auto-ends caller (the server emits a final
  `call.hangup` with hangerUpperId == callerId via the all_callees_left
  path).
- TC-BSY.1: second incoming call while A is in a call → C sees status
  "Busy" with snackbar; A's call is unaffected.

Don't:
- Don't try to detect "stale ringing" client-side — the server's
  `markMissedIfStaleRinging` (when scheduled) emits a hangup with
  reason=no_answer.
- Don't implement WebRTC. The in-call page is signalling+timer only until
  a media SFU lands.
```

---

### Prompt 8 — Connectivity, auth refresh, and lifecycle

```
Goal: graceful behavior when the network dies, the access token expires
mid-session, or the app is backgrounded.

Read first:
- The reconnect logic added in Prompt 1
- AuthRepository.tryRefresh() from Prompt 0
- `AppLifecycleState.resumed` hook already in the chat module

Tasks:
1. On `WidgetsBindingObserver.didChangeAppLifecycleState(resumed)`:
   - Call `stompClient.activate()` if disconnected.
   - Re-issue `loadInbox()` so the server is the source of truth.
2. On STOMP disconnect with no obvious cause:
   - Wait `min(2 * attempt, 30)` seconds, then reconnect.
   - If reconnect's CONNECT frame gets ERROR (typically expired token),
     call AuthRepository.tryRefresh() → rebuild the STOMP client with the
     new access token in the CONNECT header.
3. On REST 401 anywhere:
   - The Dio interceptor from Prompt 0 already refreshes once.
   - On a second 401 immediately after refresh → kick to login.
4. AppBar pill (replaces the relay pill from Section 2.4):
   - Green `Live`         → STOMP connected
   - Amber `Connecting…`  → backoff retry in flight
   - Red `Offline`        → reconnect failed > 3 times OR no internet (use
     `connectivity_plus`)
   - Tap pill → quick "Retry now" action.

Acceptance:
- TC-LC.1 with the new backend: turn Wi-Fi off → pill amber/red within 5s;
  turn back on → green within ~5s; the inbox auto-refreshes.
- Wait for access token to expire (PT15M by default) → next REST call still
  succeeds (auto-refresh under the hood). STOMP reconnect also succeeds with
  the refreshed token.
- Delete refresh token mid-session → app drops to login on next 401.

Don't:
- Don't ping the server on a timer to keep the token alive — let the natural
  401 + refresh flow handle it.
```

---

### Prompt 9 — Cleanup: delete the dev relay

```
Goal: remove the LAN-only relay infrastructure now that everything talks
to the real backend.

Tasks:
1. Delete `tools/chat_relay/` entirely.
2. Remove `ChatSettings.relayUrl` (renamed/replaced by `apiBaseUrl` in
   Prompt 0). Drop the "Relay URL…" menu item under the ⋮ overflow.
3. Drop the "Sign in as…" identity switcher — identity now comes from the
   logged-in user. The menu item can be replaced with "Log out".
4. Remove the dev-only seed JSON loads from `ConversationsRepository` and
   `MessagesRepository` — the real inbox load (Prompt 2) replaces them.
5. Update Section 2 of CHAT_MODULE_GUIDE.md ("Quick start — 3-device demo
   setup") to use the real backend: each device logs in with a distinct
   user via `POST /api/v1/auth/login` instead of "Sign in as…".

Acceptance:
- A fresh clone + flutter run only needs the backend running on the LAN.
- No dart relay required. No "Sign in as…" menu.
- The smoke-test checklist in Section 6 still passes end-to-end against
  the real backend.

Don't:
- Don't delete the chat module's repositories / pages — only the relay
  scaffolding and the seed identity machinery go.
```

---

### Quick smoke test (backend only, before Prompt 0)

Run this against a freshly-booted backend to confirm the chat module is
healthy **before** starting any Flutter work. Substitute
`172.20.17.31:8080` for your server's host:port. Uses `jq` for token
extraction — install or paste the token by hand if you don't have it.

```bash
HOST=http://172.20.17.31:8080

# 1. Log in as two distinct users (admin + a second user you have on hand).
TOK_A=$(curl -s -X POST $HOST/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@company.local","password":"Admin@12345"}' \
  | jq -r .data.accessToken)

TOK_B=$(curl -s -X POST $HOST/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"<second-user-email>","password":"<their-password>"}' \
  | jq -r .data.accessToken)

# 2. Find your peer's user id (search by email or fullName).
curl -s "$HOST/api/v1/users?search=<peer-name-fragment>" \
  -H "Authorization: Bearer $TOK_A" | jq '.data.items[] | {id, email, fullName}'
PEER_ID=4   # <-- paste the id from above

# 3. Create a DIRECT conversation. (If one already exists between you, the
#    server returns the existing row — idempotent.)
CONV=$(curl -s -X POST $HOST/api/v1/chats/conversations \
  -H "Authorization: Bearer $TOK_A" -H "Content-Type: application/json" \
  -d "{\"type\":\"DIRECT\",\"memberIds\":[$PEER_ID]}" | jq -r .data.id)
echo "conversation id = $CONV"

# 4. Send a text message as user A.
MSG=$(curl -s -X POST $HOST/api/v1/chats/conversations/$CONV/messages \
  -H "Authorization: Bearer $TOK_A" -H "Content-Type: application/json" \
  -d '{"type":"TEXT","body":"smoke test"}' | jq -r .data.id)
echo "message id = $MSG"

# 5. Read history as user B — should see the message in items[].
curl -s "$HOST/api/v1/chats/conversations/$CONV/messages" \
  -H "Authorization: Bearer $TOK_B" | jq '.data.items[] | {id, body, senderId}'

# 6. Toggle a 👍 reaction from user B.
curl -s -X POST $HOST/api/v1/chats/messages/$MSG/reactions \
  -H "Authorization: Bearer $TOK_B" -H "Content-Type: application/json" \
  -d '{"emoji":"👍"}' | jq

# 7. Edit the message as the original sender (within 15 min).
curl -s -X PATCH $HOST/api/v1/chats/messages/$MSG \
  -H "Authorization: Bearer $TOK_A" -H "Content-Type: application/json" \
  -d '{"body":"smoke test (edited)"}' | jq '.data | {id, body, editedAt}'

# 8. Mark-read as user B → unreadCount should drop to 0.
curl -s -X POST $HOST/api/v1/chats/conversations/$CONV/read \
  -H "Authorization: Bearer $TOK_B" -H "Content-Type: application/json" \
  -d "{\"lastReadMessageId\": $MSG}" | jq '.data | {id, unreadCount}'

# 9. Start a voice call as A.
CALL=$(curl -s -X POST $HOST/api/v1/chats/conversations/$CONV/calls \
  -H "Authorization: Bearer $TOK_A" -H "Content-Type: application/json" \
  -d '{"type":"VOICE"}' | jq -r .data.id)
echo "call id = $CALL"

# 10. Accept as B, then end as A.
curl -s -X POST $HOST/api/v1/chats/calls/$CALL/accept \
  -H "Authorization: Bearer $TOK_B" | jq '.data | {id, status, answeredAt}'
curl -s -X POST $HOST/api/v1/chats/calls/$CALL/end \
  -H "Authorization: Bearer $TOK_A" | jq '.data | {id, status, durationSeconds, endReason}'

# 11. Call history shows the closed call.
curl -s "$HOST/api/v1/chats/calls?page=1&pageSize=5" \
  -H "Authorization: Bearer $TOK_A" \
  | jq '.data.items[] | {id, status, type, durationSeconds, startedAt}'
```

#### Expected results

| Step | Pass criterion |
|---|---|
| 3 | `data.id` is a positive integer; subsequent calls reuse it |
| 4 | response contains `data.id`, `data.body == "smoke test"`, `data.type == "TEXT"` |
| 5 | user B sees the message via the GET — proves cross-user routing + membership |
| 6 | response is an array containing `{ userId: <B>, emoji: "👍" }` |
| 7 | response shows the new body and a non-null `editedAt` timestamp |
| 8 | `unreadCount: 0` in the response |
| 9 | response has `status: "RINGING"`, `type: "VOICE"`, B in `participants[]` with `status: "RINGING"` |
| 10 | accept flips status to `ANSWERED`; end flips it to `ENDED` with `durationSeconds >= 0` |
| 11 | the just-ended call appears at the top of the list |

#### Probing STOMP from the command line

```bash
# Connect with wscat (npm install -g wscat) — replace TOKEN with $TOK_B.
wscat -c ws://172.20.17.31:8080/ws
> CONNECT
  Authorization:Bearer <TOKEN>
  accept-version:1.2
  host:localhost

# After the CONNECTED frame, subscribe to your inbox:
> SUBSCRIBE
  id:sub-0
  destination:/user/queue/inbox

# Then re-run step 4 in another terminal. You should see a MESSAGE frame
# arrive on this socket with body { "event": "message.send", "payload": …}.
```

If steps 1-11 all return the expected shapes AND the STOMP MESSAGE frame
fires when step 4 reruns, the backend is healthy and Prompt 0 can begin.
If anything fails, fix the backend first — chasing the failure inside
Flutter is wasted time.

---

### How to drive these prompts

Sequential is safest:

1. Run Prompt 0 → verify login works.
2. Run Prompt 1 → verify a single text message round-trips via STOMP.
3. Run Prompts 2 → 8 in order — each prompt's "Acceptance" gates the next.
4. Run Prompt 9 only after the smoke-test checklist passes on the real
   backend.

Each prompt is meant to land in one PR. Don't merge a prompt's changes
until its acceptance criteria pass on at least two physical devices —
chat regressions are easy to miss with a single client.
