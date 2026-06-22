/// Coarse-grained status for the sync engine, suitable for badges/banners.
///
/// Folded down from the granular `SyncEvent` stream by [SyncBloc] — the UI
/// rarely cares about per-op events, only "are we mid-sync?" / "did
/// anything fail?".
enum SyncStatus { idle, syncing, error }
