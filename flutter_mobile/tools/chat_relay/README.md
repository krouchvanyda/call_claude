# Chat Relay — Module 10 demo bridge

Tiny WebSocket fan-out server so two app instances can actually exchange
messages without a real backend. Each message arriving on the socket is
broadcast to every **other** connected client; no auth, no persistence,
no history replay.

## Run the relay

```bash
cd tools/chat_relay
dart pub get               # once
dart run bin/server.dart   # listens on 0.0.0.0:7777
# dart run bin/server.dart --port 9000 --verbose
```

You should see something like:

```
[14:01:02] relay listening on ws://0.0.0.0:7777
[14:01:02] LAN: connect phones with ws://<your-PC-IP>:7777
[14:01:02] emulator: ws://10.0.2.2:7777   simulator: ws://127.0.0.1:7777
[14:01:02] Press Ctrl+C to stop.
```

Find your PC's LAN IP (Windows: `ipconfig` → IPv4 under your Wi-Fi
adapter). Both phones need to be on the same Wi-Fi as the PC. If
Windows Firewall prompts the first time you start the server, allow
**Private** networks.

## Wire the apps

On **both** devices, in the chat module:

1. Open the **Messages** page → tap the **⋮** menu → **Sign in as…**
   - Device A: pick `Demo Approver`
   - Device B: pick any other person (e.g. `Channary Pich`)
2. Same menu → **Relay URL…** → enter the URL:
   - Real phone on same Wi-Fi: `ws://<your-PC-IP>:7777`
   - Android emulator on the PC: `ws://10.0.2.2:7777`
   - iOS simulator on the PC: `ws://127.0.0.1:7777`
   - (The sheet has preset chips for the two emulator/simulator cases.)

The pill just under the AppBar flips to **Live · <host>:7777** in
green once the connection is up. If it stays amber or shows an error,
double-check the IP and firewall.

## Try it

- Send a text message on Device A → it appears on Device B as an
  incoming bubble within ~100ms.
- Reactions, edits, and deletes mirror both ways.
- Voice / image / file metadata syncs too, but the underlying media
  URLs are demo stubs (`demo://...`) — playback / preview won't work
  across devices because no actual binary is transferred.

## What gets mirrored

| Event | Synced? |
|-------|---------|
| Send text message | ✅ |
| Send voice / image / file (metadata only) | ✅ |
| Edit message | ✅ |
| Soft-delete message | ✅ |
| Toggle reaction | ✅ |
| Conversation create / rename / pin | ❌ (in-memory seed, identical on both sides) |
| Typing indicator / presence | ❌ |
| Voice / video call signalling | ❌ (no WebRTC) |

## Wire format

UTF-8 JSON envelopes, one per WebSocket frame:

```json
{ "type": "hello",        "from": "user-demo", "payload": {"name":"Demo Approver"} }
{ "type": "message.send", "from": "user-demo", "payload": { ...ChatMessage... } }
{ "type": "message.edit", "from": "user-demo", "payload": {"messageId":"…","newBody":"…"} }
{ "type": "message.delete","from":"user-demo", "payload": {"messageId":"…"} }
{ "type": "reaction.toggle","from":"user-demo","payload":{"messageId":"…","emoji":"👍","employeeId":"user-demo"} }
```

The relay does not interpret `payload` — it just rebroadcasts the raw
frame to every other client. Server-side identity comes from the
WebSocket itself (the "originating socket" the relay won't echo to);
the `from` field is metadata for logging.

## Safety notes

- **No auth, no encryption.** Anyone on your LAN with the URL can
  send and receive. Don't expose port 7777 to the public internet.
- **No persistence.** Restarting the relay drops every message that
  was in flight; new clients don't get history.
- **In-memory client state.** The app's seeded conversation list lives
  in-memory; clearing app data on either device resets it.
