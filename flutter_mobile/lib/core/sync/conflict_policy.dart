import 'conflict.dart';

/// Strategy for picking a winner when local and server state diverge.
///
/// The interface is method-generic so a single policy instance can resolve
/// conflicts for any entity type. Per-entity overrides live in
/// [ConflictPolicyRegistry] — bind a different policy by `entityType`
/// when an entity needs special handling (e.g. additive lists).
abstract class ConflictPolicy {
  const ConflictPolicy();
  T resolve<T>(Conflict<T> conflict);
}

/// Server is always the source of truth. Picked as the framework default
/// because it's the safest choice for an ERP: local optimistic edits get
/// rolled back if the back office made a competing change.
class ServerWinsPolicy extends ConflictPolicy {
  const ServerWinsPolicy();

  @override
  T resolve<T>(Conflict<T> conflict) => conflict.server;
}

/// Local wins. Use sparingly — appropriate for free-form notes or per-user
/// preferences where the device is the canonical owner.
class ClientWinsPolicy extends ConflictPolicy {
  const ClientWinsPolicy();

  @override
  T resolve<T>(Conflict<T> conflict) => conflict.local;
}

/// Whichever side carries the newer `updatedAt` wins.
///
/// When either timestamp is missing or the two are equal, falls back to
/// [tiebreaker] (defaulting to [ServerWinsPolicy] — the conservative choice).
class LastWriteWinsPolicy extends ConflictPolicy {
  const LastWriteWinsPolicy({
    this.tiebreaker = const ServerWinsPolicy(),
  });

  final ConflictPolicy tiebreaker;

  @override
  T resolve<T>(Conflict<T> conflict) {
    final localAt = conflict.localUpdatedAt;
    final serverAt = conflict.serverUpdatedAt;
    if (localAt == null || serverAt == null) {
      return tiebreaker.resolve(conflict);
    }
    if (localAt.isAfter(serverAt)) return conflict.local;
    if (serverAt.isAfter(localAt)) return conflict.server;
    return tiebreaker.resolve(conflict);
  }
}
