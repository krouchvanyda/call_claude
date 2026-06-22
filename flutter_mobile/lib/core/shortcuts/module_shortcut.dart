import 'package:flutter/widgets.dart';

import '../../features/auth/entities/permission.dart';
import '../../l10n/app_localizations.dart';

/// One tile in the Modules grid (Slice 2.1.2).
///
/// Const-constructable so the [catalog] is a single, audit-friendly literal.
/// Flutter-tied (because of [icon]) — the filtering logic that decides
/// which tiles are visible lives in `permission_filter.dart`, which is
/// pure Dart and unit-testable.
@immutable
class ModuleShortcut {
  const ModuleShortcut({
    required this.id,
    required this.icon,
    required this.labelOf,
    required this.builder,
    this.requiredPermission,
  });

  /// Stable analytics / test key. Never localised.
  final String id;

  /// Material icon shown above the label.
  final IconData icon;

  /// Translation lookup — a callback rather than a raw string so the tile
  /// re-localises on `Locale` changes without rebuilding the catalog.
  final String Function(AppLocalizations l10n) labelOf;

  /// Builds the page widget that the tile pushes via `ConfigRouter`. A
  /// callback (rather than a stored Widget) so each tile re-instantiates
  /// the page on tap and the catalog stays const-friendly via static
  /// function tear-offs.
  final Widget Function() builder;

  /// Permission required to see + tap this tile. `null` means ungated
  /// (always visible to any signed-in user).
  ///
  /// Wildcard semantics are inherited from [Permission.grants] — the
  /// catalog can declare e.g. `finance.*` and a held `finance.invoice.read`
  /// will satisfy it.
  final Permission? requiredPermission;
}
