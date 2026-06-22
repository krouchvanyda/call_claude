/// Network reachability surface used by the sync engine and any feature that
/// wants to skip a remote call when the device is offline.
///
/// Implementations must be cheap to read — the checker is consulted on every
/// outbound mutation by the offline queue. Implementations are also expected
/// to *normalise* the OS's noisy multi-result connectivity events into a
/// single boolean ("am I online or not?") because consumers don't care
/// whether the device is on Wi-Fi vs 5G — only whether they should bother
/// trying.
///
/// Kept Flutter-free so the sync engine and other consumers stay
/// unit-testable. The concrete `connectivity_plus`-backed implementation
/// lives in [`connectivity_plus_checker.dart`](connectivity_plus_checker.dart).
abstract class ConnectivityChecker {
  /// Snapshot of the current online state.
  Future<bool> get isOnline;

  /// Distinct stream of online/offline transitions.
  ///
  /// Does **not** replay the last value to late subscribers — call [isOnline]
  /// first if you need the current state, then `listen` to keep up with
  /// transitions.
  Stream<bool> get onlineChanges;
}
