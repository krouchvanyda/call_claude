/// Lifecycle of a single realtime connection (Slice 2.2.4).
///
/// **State machine** (transitions documented in [RealtimeService]):
///
/// ```
/// disconnected ──connect──▶ connecting ──ws.ready──▶ connected
///        ▲                       │                      │
///        │                       │                      │
///        │            ws.error / cancel        ws.done / ws.error
///        │                       │                      │
///        │                       ▼                      ▼
///        └──────────── reconnecting ◀──────────────────┘
///                       (backoff timer)
///                              │
///                          retries hit cap
///                              ▼
///                        disconnected
/// ```
///
/// Pure-Dart enum (no Flutter) so the bloc/widget that surfaces this
/// can map straight to UI without leaking the realtime layer's types.
enum RealtimeConnectionState {
  /// Idle — service hasn't been started, or `disconnect()` was called,
  /// or reconnect attempts have been exhausted.
  disconnected,

  /// First-attempt handshake in flight.
  connecting,

  /// WebSocket is open and pumping messages.
  connected,

  /// Connection dropped; sleeping a backoff window before the next
  /// `connecting` attempt. The UI should surface this distinctly from
  /// `disconnected` — "we'll retry" vs. "we gave up".
  reconnecting,
}
