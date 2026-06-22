import 'package:erp_mobile/core/router/auth_redirect_policy.dart';
import 'package:erp_mobile/core/router/route_paths.dart';
import 'package:test/test.dart';

void main() {
  group('resolveAuthRedirect — signed-out user', () {
    test('reaches splash without redirect', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.splash,
          isAuthenticated: false,
        ),
        isNull,
      );
    });

    test('reaches login without redirect', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.login,
          isAuthenticated: false,
        ),
        isNull,
      );
    });

    test('is bounced from a protected route to /login', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.dashboard,
          isAuthenticated: false,
        ),
        RoutePaths.login,
      );
    });

    test('is bounced from an unknown protected path to /login', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: '/finance/invoices/42',
          isAuthenticated: false,
        ),
        RoutePaths.login,
      );
    });

    test(
        'auth check wins over permission check: missing access on a protected '
        'path still routes to /login (not /forbidden) — no session, no '
        'meaningful permission verdict', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.adminDemo,
          isAuthenticated: false,
          hasRouteAccess: false,
        ),
        RoutePaths.login,
      );
    });
  });

  group('resolveAuthRedirect — signed-in user', () {
    test('hitting /splash is forwarded to /dashboard', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.splash,
          isAuthenticated: true,
        ),
        RoutePaths.dashboard,
      );
    });

    test('hitting /login is forwarded to /dashboard (no double-login)', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.login,
          isAuthenticated: true,
        ),
        RoutePaths.dashboard,
      );
    });

    test('reaches /dashboard without redirect', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.dashboard,
          isAuthenticated: true,
        ),
        isNull,
      );
    });

    test('reaches a deep protected path without redirect', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: '/finance/invoices/42',
          isAuthenticated: true,
        ),
        isNull,
      );
    });
  });

  group('resolveAuthRedirect — RBAC gate (Slice 1.3.2)', () {
    test('default hasRouteAccess=true does not change behaviour', () {
      // Sanity — the default arg keeps every pre-1.3.2 call site working.
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.dashboard,
          isAuthenticated: true,
        ),
        isNull,
      );
    });

    test('authenticated + has access → no redirect', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.adminDemo,
          isAuthenticated: true,
          hasRouteAccess: true,
        ),
        isNull,
      );
    });

    test('authenticated + lacks access → /forbidden', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.adminDemo,
          isAuthenticated: true,
          hasRouteAccess: false,
        ),
        RoutePaths.forbidden,
      );
    });

    test(
        '/forbidden itself is exempt from the permission gate so the bounce '
        'target does not recursively redirect', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.forbidden,
          isAuthenticated: true,
          hasRouteAccess: false,
        ),
        isNull,
      );
    });

    test(
        'login bounce wins over permission gate when an authenticated user '
        'lands on /login (no chance to be "forbidden" from the login page)',
        () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.login,
          isAuthenticated: true,
          hasRouteAccess: false,
        ),
        RoutePaths.dashboard,
      );
    });

    test(
        'splash bounce wins over permission gate when an authenticated user '
        'lands on /splash', () {
      expect(
        resolveAuthRedirect(
          matchedLocation: RoutePaths.splash,
          isAuthenticated: true,
          hasRouteAccess: false,
        ),
        RoutePaths.dashboard,
      );
    });
  });
}
