import 'route_paths.dart';

/// Pure auth + RBAC redirection policy — no Flutter imports.
///
/// Owns the *decision* "given a target location, an auth state, and the
/// caller's permission verdict, should the router redirect, and where to?".
/// Kept Flutter-free so the rule set can be unit-tested cheaply and audited
/// in one place.
///
/// Intentionally a function, not a class: the policy is stateless and the
/// inputs are explicit, which makes the rules easy to reason about and to
/// extend (route-level RBAC arrived in Slice 1.3.2 via [hasRouteAccess]).
///
/// **Order of checks** matters:
/// 1. Unauthenticated + non-public path → `/login` (auth wins; the
///    permission verdict is moot when there's no session).
/// 2. Authenticated user landing on `/splash` or `/login` → `/dashboard`.
/// 3. Authenticated + lacks the route's required permission → `/forbidden`.
/// 4. Otherwise → no redirect.
String? resolveAuthRedirect({
  required String matchedLocation,
  required bool isAuthenticated,
  bool hasRouteAccess = true,
}) {
  final isPublic = RoutePaths.publicLocations.contains(matchedLocation);

  if (!isAuthenticated && !isPublic) {
    return RoutePaths.login;
  }
  if (isAuthenticated &&
      (matchedLocation == RoutePaths.login ||
          matchedLocation == RoutePaths.splash)) {
    return RoutePaths.dashboard;
  }
  // Permission gate — only meaningful for authenticated users on
  // non-public paths. The `/forbidden` page itself is exempt so the
  // bounce target doesn't recursively trigger another redirect.
  if (isAuthenticated &&
      !hasRouteAccess &&
      matchedLocation != RoutePaths.forbidden) {
    return RoutePaths.forbidden;
  }
  return null;
}
