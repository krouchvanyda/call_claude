import '../../entities/pkce_challenge.dart';

/// In-memory holder for the **single in-flight OAuth authorization
/// flow**.
///
/// **Memory-only** (per CLAUDE.md Slice 1.2.2): the verifier and the
/// CSRF state nonce live in this object's instance fields and nowhere
/// else. Process kill / app restart drops them, which is exactly what
/// you want — a half-completed flow shouldn't survive a relaunch.
///
/// One flow at a time. Calling [begin] while another flow is active
/// silently replaces it (the previous attempt is forgotten).
///
/// State machine:
/// ```
///   (none) ──begin─▶ active ──consumeVerifier(matching state)─▶ (none, returns verifier)
///                       │
///                       ├──consumeVerifier(state mismatch)──▶ (none, returns null)
///                       └──clear()──▶ (none)
/// ```
class OAuthFlowSession {
  OAuthFlowSession();

  PkceChallenge? _challenge;
  String? _state;

  /// `true` when an authorization request has been started but the code
  /// hasn't been exchanged yet. Mainly useful for diagnostics.
  bool get hasActiveFlow => _challenge != null;

  /// Read-only view for diagnostics / tests. Production callers go
  /// through [consumeVerifier].
  PkceChallenge? get pendingChallenge => _challenge;
  String? get pendingState => _state;

  /// Records the verifier+challenge AND a CSRF state nonce for the
  /// in-progress flow. Replaces any previous in-flight flow.
  void begin({
    required PkceChallenge challenge,
    required String state,
  }) {
    _challenge = challenge;
    _state = state;
  }

  /// Returns the verifier if [state] matches the recorded nonce, else
  /// `null`. **Always wipes the session**, regardless of result — a
  /// failed attempt can't be replayed with the same nonce, and a
  /// successful exchange clears its proof material immediately.
  String? consumeVerifier({required String state}) {
    final stored = _challenge;
    final matches = stored != null && _state == state;
    _challenge = null;
    _state = null;
    return matches ? stored.verifier : null;
  }

  /// Force-clear the session — used when the user cancels the flow or
  /// the OS-level browser tab is dismissed before completion.
  void clear() {
    _challenge = null;
    _state = null;
  }
}
