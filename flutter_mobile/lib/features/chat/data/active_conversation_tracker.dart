/// Slice 10.1.6 — singleton that holds the conversation id the user
/// is currently looking at (or `null` when they're elsewhere).
///
/// **Why this exists**: when an incoming peer message lands while the
/// user is sitting on that conversation's page, the `unreadCount`
/// shouldn't tick up — the user is reading it in real time. The
/// transport-event listener in `bootChatTransport` consults this
/// tracker so its bumpUnread call is conditional.
///
/// `ChatConversationPage` registers itself in `initState` and clears
/// in `dispose`. There's only ever one chat page in the route stack
/// at a time, so a plain field is enough — no stream / notifier
/// needed.
class ActiveConversationTracker {
  ActiveConversationTracker._();
  static final ActiveConversationTracker instance =
      ActiveConversationTracker._();

  String? _activeConversationId;

  String? get activeConversationId => _activeConversationId;

  /// True when the currently-open conversation page matches [id] —
  /// callers use this to skip the unread-count bump for messages the
  /// user is actively reading.
  bool isActive(String id) => _activeConversationId == id;

  void enter(String id) {
    _activeConversationId = id;
  }

  void leave(String id) {
    // Only clear if it matches — guards against an out-of-order
    // dispose racing a fresh enter (rare in practice but cheap).
    if (_activeConversationId == id) {
      _activeConversationId = null;
    }
  }
}
