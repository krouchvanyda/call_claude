import '../../../../core/shortcuts/module_shortcut.dart';
import '../../../../core/shortcuts/module_shortcut_catalog.dart';
import '../../../auth/entities/permission.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/repositories/search_provider.dart';

/// Seed [SearchProvider] (Slice 2.1.3) — searches the in-memory
/// [ModuleShortcutCatalog] by tile label so the global search bar has
/// something useful to surface before any feature module ships its own
/// provider.
///
/// **No permission gate at the provider level**: per-tile permissions are
/// already enforced by the catalog's `requiredPermission` field; this
/// provider just defers to that. (Tiles the user can't see never appear.)
///
/// **Flutter-aware via closure**: the [labelOf] callback is supplied by
/// the widget that constructs the provider, so the provider stays free
/// of `AppLocalizations` imports while still matching localised labels.
class ModuleShortcutSearchProvider implements SearchProvider {
  const ModuleShortcutSearchProvider({
    required this.labelOf,
    this.shortcutHeld,
  });

  /// Resolves the on-screen label for a shortcut. The widget passes
  /// `(s) => s.labelOf(AppLocalizations.of(context))` at construction.
  final String Function(ModuleShortcut) labelOf;

  /// Optional permission predicate — when supplied, only tiles the user
  /// can see appear in results. The widget wires this to
  /// `(perm) => permissionsSnapshot.holds(perm)` so revoking a role
  /// drops the tile from search results immediately. Tests pass `null`
  /// (or a stub) to skip the gate.
  final bool Function(Permission required)? shortcutHeld;

  @override
  String get id => 'modules';

  /// The seed provider has no per-provider gate — invocation cost is
  /// near-zero (in-memory walk) and per-tile gating already filters.
  @override
  Permission? get requiredPermission => null;

  @override
  Future<List<SearchResult>> search(String query) async {
    final lower = query.toLowerCase();
    final visible = ModuleShortcutCatalog.all.where((s) {
      final required = s.requiredPermission;
      if (required != null && shortcutHeld != null) {
        if (!shortcutHeld!(required)) return false;
      }
      // Match localised label OR stable id (latter helps power-users
      // type 'admin-demo' without knowing the localised label).
      final label = labelOf(s).toLowerCase();
      return label.contains(lower) || s.id.toLowerCase().contains(lower);
    });

    return visible
        .map((s) => SearchResult(
              id: s.id,
              title: labelOf(s),
              providerId: id,
            ))
        .toList(growable: false);
  }
}
