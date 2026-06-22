import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../features/auth/data/datasources/cached_user_dao.dart';
import '../../features/auth/data/repositories/permissions_repository.dart';
import '../../features/auth/entities/permission.dart';
import '../../features/auth/entities/user.dart';
import '../../features/auth/permission_gate.dart';

/// In-memory mirror of the signed-in user's permission set, updated
/// reactively from drift.
///
/// **Why this exists**: GoRouter's `redirect` callback is *synchronous* —
/// it can't `await` a drift query for every navigation tick. The router
/// calls [holds] from inside its redirect, so the verdict has to be
/// available synchronously. This class keeps a fresh copy in memory and
/// notifies listeners whenever the underlying drift rows change, which
/// (combined with the router's `refreshListenable`) re-evaluates the
/// guard the moment a permission is granted or revoked.
///
/// **Source of truth is still drift** — this class never writes; it only
/// reads. Sign-out / wipe paths clear drift, which propagates through
/// `watchCurrentUser` and empties the snapshot here.
@lazySingleton
class PermissionsSnapshot extends ChangeNotifier implements PermissionGate {
  PermissionsSnapshot({
    required CachedUserDao cachedUserDao,
    required PermissionsRepository permissionsRepository,
  })  : _cachedUserDao = cachedUserDao,
        _permissionsRepository = permissionsRepository {
    _userSub = _cachedUserDao.watchCurrentUser().listen(_onUserChanged);
  }

  final CachedUserDao _cachedUserDao;
  final PermissionsRepository _permissionsRepository;

  StreamSubscription<User?>? _userSub;
  StreamSubscription<Set<Permission>>? _permsSub;

  String? _currentUserId;
  Set<Permission> _permissions = const {};

  /// Synchronous read for the router's redirect callback. Returns `true`
  /// when the snapshot's currently-cached set satisfies [required] under
  /// the wildcard rules in [Permission.grants].
  ///
  /// Returns `false` when no user is loaded yet (treat as "no privileges").
  @override
  bool holds(Permission required) => _permissions.grant(required);

  /// Snapshot of the current permission set — useful for diagnostics and
  /// tests. The returned set is a defensive copy.
  Set<Permission> get permissions => Set<Permission>.unmodifiable(_permissions);

  /// User id whose permissions are mirrored, or `null` when no user is
  /// signed in. Public so non-router callers can disambiguate
  /// "no permissions yet" from "no user".
  @override
  String? get currentUserId => _currentUserId;

  void _onUserChanged(User? user) {
    final newUserId = user?.id;
    if (newUserId == _currentUserId) return;

    _currentUserId = newUserId;
    _permsSub?.cancel();
    _permsSub = null;

    if (newUserId == null) {
      if (_permissions.isNotEmpty) {
        _permissions = const {};
        notifyListeners();
      }
      return;
    }

    _permsSub = _permissionsRepository
        .watchPermissions(newUserId)
        .listen(_onPermissionsChanged);
  }

  void _onPermissionsChanged(Set<Permission> next) {
    if (setEquals(_permissions, next)) return;
    _permissions = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _permsSub?.cancel();
    super.dispose();
  }
}
