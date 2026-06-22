import '../../../auth/entities/permission.dart';
import '../entities/search_result.dart';

/// Contract every searchable feature module implements (Slice 2.1.3).
///
/// One provider per module — Finance returns invoices, Inventory returns
/// items, etc. The federated search use case fans out to all providers
/// in parallel, dropping any whose [requiredPermission] the signed-in
/// user can't satisfy *before* hitting the network.
///
/// **Implementations live in the data layer** (or in the feature module
/// itself) and are registered into the [SearchProviderRegistry] at DI
/// time so adding a new module is a one-line wiring change.
abstract class SearchProvider {
  /// Stable identity — used for grouping rows in the UI, for analytics,
  /// and for the `providerId` field on returned [SearchResult]s.
  String get id;

  /// Permission required to invoke this provider. `null` means "any
  /// signed-in user can search this module" (e.g. notifications, help).
  /// Wildcards inherited from [Permission.grants].
  Permission? get requiredPermission;

  /// Run the query. Implementations should:
  /// - return early on empty / whitespace-only [query] (the use case
  ///   already short-circuits this, but defensive),
  /// - tolerate cancellation by checking `query` is still relevant on
  ///   their own (the bloc uses `switchMap` to drop stale responses),
  /// - throw on transport / parse errors — the use case wraps them.
  Future<List<SearchResult>> search(String query);
}
