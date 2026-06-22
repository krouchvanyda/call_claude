import '../../features/auth/entities/permission.dart';
import 'route_paths.dart';

/// Static permission requirements for permission-gated routes.
///
/// One central table keeps the authorisation surface auditable: every
/// gated location is listed here, and the route guard in
/// `auth_redirect_policy.dart` reads from this single source. Locations
/// not present in the table are treated as "any authenticated user".
///
/// Wildcard semantics (trailing `*`, mid `*`, bare `*`) are inherited
/// from [Permission.grants] — whoever populates this map writes the
/// strictest token; held permissions decide whether it's satisfied.
abstract final class RouteAccess {
  /// Location → Permission required to enter.
  ///
  /// Slice 1.3.2 seeds only the demo route so the "no access → /forbidden"
  /// branch is exercised end-to-end; feature modules append their own
  /// requirements as they ship.
  static const Map<String, Permission> requirements = {
    RoutePaths.adminDemo: Permission(token: 'admin'),
  };

  /// Returns the permission required for [location], or `null` when the
  /// location has no permission gate (any authenticated user can enter).
  static Permission? requiredFor(String location) => requirements[location];
}
