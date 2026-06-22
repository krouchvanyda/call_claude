import 'package:injectable/injectable.dart';

import '../entities/user.dart';
import 'datasources/cached_user_dao.dart';

/// Seeds a demo user + permission set into drift so the
/// [`StubAuthSession.simulateSignIn`] flow has a real signed-in identity
/// for use cases that consult [`PermissionsSnapshot.currentUserId`] —
/// notably the Slice 3.2.4 approve/reject UseCases.
///
/// **Demo only**: real sign-in lives in `AuthRepositoryImpl`. This
/// service exists so the no-backend developer flow ("simulated login"
/// from `LoginPage`) lands in a state that's structurally identical to
/// a real session — same drift rows, same permissions snapshot.
@lazySingleton
class DemoSignInService {
  DemoSignInService(this._dao);

  final CachedUserDao _dao;

  /// Permissions handed to the demo user. Includes `finance.approve`
  /// (Slice 3.2.4) and a wildcard so future scopes don't require
  /// touching this seed.
  static const Set<String> demoRoles = {
    'finance.approve',
    'finance.*',
    // Module 4 — surfaces the procurement tile on the Modules grid.
    'procurement.*',
    // Module 5 — surfaces the inventory tile on the Modules grid
    // (Slice 2.1.2 is permission-filtered).
    'inventory.*',
    // Module 6 — same for the sales tile.
    'sales.*',
    // Module 7 — same for the HR tile.
    'hr.*',
    // Module 8 — same for the Projects tile.
    'projects.*',
  };

  static const String demoUserId = 'user-demo';

  Future<void> seed() async {
    await _dao.cacheUser(const User(
      id: demoUserId,
      email: 'demo@erp.example',
      displayName: 'Demo Approver',
      roles: demoRoles,
    ));
  }
}
