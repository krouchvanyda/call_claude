import 'entities/permission.dart';

/// Pure-Dart seam for runtime permission checks (Slice 3.2.4).
///
/// **Why this exists**: domain UseCases need to verify the signed-in
/// user holds a permission before mutating state, but they must stay
/// Flutter-free. The production implementation is the
/// [`PermissionsSnapshot`] in `core/router/` — which extends
/// `ChangeNotifier` because the router needs to listen to it — but the
/// UseCases only need the two read methods. This interface captures
/// just that subset so tests can mock it without dragging in Flutter,
/// and so the dependency direction stays `domain ⇐ core/presentation`
/// (never the other way around).
abstract class PermissionGate {
  /// `User.id` of the signed-in user, or `null` when nobody is
  /// authenticated yet.
  String? get currentUserId;

  /// Does the current user hold (or inherit, via wildcard) [required]?
  bool holds(Permission required);
}
