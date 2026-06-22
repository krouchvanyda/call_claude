/// Wall-clock injection seam.
///
/// Anything that consults `DateTime.now()` directly should depend on this
/// typedef instead, so unit tests can supply a deterministic time. Production
/// wiring assigns `DateTime.now`.
typedef Clock = DateTime Function();
