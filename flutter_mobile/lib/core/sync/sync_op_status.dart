/// Lifecycle of a queued sync operation.
///
/// State transitions (driven by [SyncQueueDao]):
///
/// ```
///                 enqueue                claim
///   (none) ─────────────────▶ pending ──────────▶ inFlight
///                                ▲                    │
///                                │                    │ success
///                                │ failure            ▼
///                                └─────────────── (deleted)
/// ```
///
/// `failed` is reserved for the future "give-up after N retries" path
/// (Slice 0.4.3); for now ops bounce between `pending` ↔ `inFlight`.
enum SyncOpStatus { pending, inFlight, failed }
