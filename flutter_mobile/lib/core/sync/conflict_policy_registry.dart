import 'conflict_policy.dart';

/// Maps `entityType` strings (the same identifiers stored in `sync_queue`
/// rows — e.g. `'invoice'`, `'customer'`) to the [ConflictPolicy] that
/// should govern conflicts for that entity.
///
/// One registry instance lives at app scope. Feature modules will register
/// overrides as needed once they wire their sync flow (e.g. an additive
/// timeline might want a merge policy). Lookups that miss return the
/// configured [defaultPolicy] — `ServerWinsPolicy` in production wiring.
class ConflictPolicyRegistry {
  ConflictPolicyRegistry({
    this.defaultPolicy = const ServerWinsPolicy(),
    Map<String, ConflictPolicy> overrides = const <String, ConflictPolicy>{},
  }) : _overrides = Map<String, ConflictPolicy>.unmodifiable(overrides);

  /// Fallback used when no per-entity override is registered.
  final ConflictPolicy defaultPolicy;

  final Map<String, ConflictPolicy> _overrides;

  /// Returns the policy for [entityType], or [defaultPolicy] when unknown.
  ConflictPolicy policyFor(String entityType) =>
      _overrides[entityType] ?? defaultPolicy;

  /// Exposed read-only for diagnostics / testing — callers must not mutate.
  Map<String, ConflictPolicy> get overrides => _overrides;
}
