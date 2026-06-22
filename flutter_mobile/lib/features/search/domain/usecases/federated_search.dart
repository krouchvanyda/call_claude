import '../../../auth/entities/permission.dart';
import '../entities/search_result.dart';
import '../repositories/search_provider.dart';

/// Caller-supplied predicate: "does the signed-in user hold this
/// permission?". A typedef rather than a `PermissionsSnapshot` reference
/// keeps the use case Flutter-free (the snapshot extends `ChangeNotifier`
/// which would drag the broken local SDK into pure-Dart tests).
typedef HoldsPermission = bool Function(Permission required);

/// Fans a query out to every registered [SearchProvider] in parallel
/// and aggregates the per-provider responses (Slice 2.1.3).
///
/// **Permission gate**: providers whose [SearchProvider.requiredPermission]
/// the user can't satisfy are dropped *before* `search()` is called —
/// no wasted network, no leaked information about modules the user
/// can't see.
///
/// **Failure isolation**: a single provider throwing must not poison
/// the whole result set. The use case wraps each call in a try/catch
/// and returns an empty group for that provider; the UI can still
/// render the others.
class FederatedSearchUseCase {
  const FederatedSearchUseCase({
    required List<SearchProvider> providers,
    required HoldsPermission holds,
  })  : _providers = providers,
        _holds = holds;

  final List<SearchProvider> _providers;
  final HoldsPermission _holds;

  Future<List<SearchResultGroup>> call(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final eligible = _providers.where((p) {
      final required = p.requiredPermission;
      return required == null || _holds(required);
    }).toList(growable: false);

    final futures = eligible.map((p) async {
      try {
        final rows = await p.search(trimmed);
        return SearchResultGroup(providerId: p.id, results: rows);
      } catch (_) {
        // Isolate failures — one broken provider must not blank the others.
        return SearchResultGroup(
          providerId: p.id,
          results: const <SearchResult>[],
        );
      }
    });

    final groups = await Future.wait(futures);
    // Drop empty groups so the UI doesn't render bare section headers.
    return groups.where((g) => g.results.isNotEmpty).toList(growable: false);
  }
}
