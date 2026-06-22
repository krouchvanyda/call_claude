import 'dart:async';

import '../../../../core/error/failure.dart';
import '../../entities/api_environment.dart';
import '../../entities/managed_user.dart';
import '../settings_seed.dart';

/// Slice 9.2.1 — admin user management.
class ManagedUsersRepository {
  ManagedUsersRepository();

  static final List<ManagedUser> _seed =
      List<ManagedUser>.of(SettingsSeed.users);

  final StreamController<List<ManagedUser>> _changes =
      StreamController<List<ManagedUser>>.broadcast();

  Future<List<ManagedUser>> getAll() async => List.unmodifiable(_seed);

  Stream<List<ManagedUser>> watchAll() async* {
    yield List.unmodifiable(_seed);
    yield* _changes.stream;
  }

  Future<ManagedUser?> findById(String id) async {
    for (final u in _seed) {
      if (u.id == id) return u;
    }
    return null;
  }

  Future<ManagedUser> create(ManagedUser user) async {
    final id = user.id.isEmpty
        ? 'user-${DateTime.now().microsecondsSinceEpoch}'
        : user.id;
    final stamped = user.copyWith(id: id);
    _seed.insert(0, stamped);
    _emit();
    return stamped;
  }

  Future<ManagedUser> update(ManagedUser user) async {
    final idx = _seed.indexWhere((u) => u.id == user.id);
    if (idx == -1) {
      _seed.insert(0, user);
    } else {
      _seed[idx] = user;
    }
    _emit();
    return user;
  }

  /// Slice 9.2.1 — admin invites a new user.
  ///
  /// Pure-Dart validation only — the repo persists the resulting record.
  /// New users always start in `ManagedUserStatus.invited`; status flips
  /// to `active` when they sign in for the first time (real impl wires
  /// that to the auth session — out of scope for this slice).
  Future<ManagedUser> invite({
    required String email,
    required String name,
    required List<String> roleIds,
    required DateTime now,
  }) async {
    final errors = <String, List<String>>{};
    if (!_emailLooksValid(email)) {
      errors.putIfAbsent('email', () => []).add('Looks invalid');
    }
    if (name.trim().isEmpty) {
      errors.putIfAbsent('name', () => []).add('Required');
    }
    if (roleIds.isEmpty) {
      errors.putIfAbsent('roleIds', () => []).add('Pick at least one role');
    }
    if (errors.isNotEmpty) {
      throw ValidationFailure(fieldErrors: errors);
    }
    final draft = ManagedUser(
      id: '', // assigned by repo
      email: email.trim().toLowerCase(),
      name: name.trim(),
      status: ManagedUserStatus.invited,
      roleIds: List.unmodifiable(roleIds),
      createdAt: now,
    );
    return create(draft);
  }

  /// Slice 9.2.1 — guarded suspend / reactivate.
  ///
  /// The "self-suspend" guard is the safety rail: an admin must not be
  /// able to lock themselves out of the admin console mid-edit. The
  /// caller passes `currentUserId` so we can compare.
  Future<ManagedUser> changeStatus({
    required ManagedUser user,
    required ManagedUserStatus newStatus,
    required String currentUserId,
  }) async {
    if (user.id == currentUserId &&
        newStatus == ManagedUserStatus.suspended) {
      throw ConflictFailure(message: 'You cannot suspend your own account');
    }
    if (user.status == newStatus) return user;
    return update(user.copyWith(status: newStatus));
  }

  /// Slice 9.2.1 — assign / unassign roles. Same self-lock guard:
  /// stripping every role from the current user would lock them out.
  Future<ManagedUser> assignRoles({
    required ManagedUser user,
    required List<String> roleIds,
    required String currentUserId,
  }) async {
    if (user.id == currentUserId && roleIds.isEmpty) {
      throw ConflictFailure(
          message: 'You cannot remove every role from your own account');
    }
    return update(user.copyWith(roleIds: List.unmodifiable(roleIds)));
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
  }
}

bool _emailLooksValid(String email) {
  // Intentionally permissive — full RFC 5322 is the API's job. We just
  // catch obvious typos.
  final trimmed = email.trim();
  if (trimmed.isEmpty) return false;
  final at = trimmed.indexOf('@');
  if (at <= 0 || at == trimmed.length - 1) return false;
  if (trimmed.contains(' ')) return false;
  if (!trimmed.substring(at).contains('.')) return false;
  return true;
}

/// Slice 9.2.2 — role + permission scope editor.
class RolesRepository {
  RolesRepository();

  static final List<Role> _seed = List<Role>.of(SettingsSeed.roles);

  final StreamController<List<Role>> _changes =
      StreamController<List<Role>>.broadcast();

  Future<List<Role>> getAll() async => List.unmodifiable(_seed);

  Stream<List<Role>> watchAll() async* {
    yield List.unmodifiable(_seed);
    yield* _changes.stream;
  }

  Future<Role?> findById(String id) async {
    for (final r in _seed) {
      if (r.id == id) return r;
    }
    return null;
  }

  Future<Role> create(Role role) async {
    final id = role.id.isEmpty
        ? 'role-${DateTime.now().microsecondsSinceEpoch}'
        : role.id;
    final stamped = role.copyWith(id: id);
    _seed.insert(0, stamped);
    _emit();
    return stamped;
  }

  Future<Role> update(Role role) async {
    final idx = _seed.indexWhere((r) => r.id == role.id);
    if (idx == -1) {
      _seed.insert(0, role);
    } else {
      _seed[idx] = role;
    }
    _emit();
    return role;
  }

  Future<void> delete(String roleId) async {
    _seed.removeWhere((r) => r.id == roleId);
    _emit();
  }

  /// Slice 9.2.2 — create a custom role from the editor.
  Future<Role> createFromInput({
    required String name,
    required String description,
    required List<String> permissionTokens,
  }) async {
    final errors = <String, List<String>>{};
    if (name.trim().isEmpty) {
      errors.putIfAbsent('name', () => []).add('Required');
    }
    if (permissionTokens.isEmpty) {
      errors.putIfAbsent('permissionTokens', () => [])
          .add('Pick at least one scope');
    }
    if (errors.isNotEmpty) {
      throw ValidationFailure(fieldErrors: errors);
    }
    final draft = Role(
      id: '', // assigned by repo
      name: name.trim(),
      description: description.trim(),
      permissionTokens: List.unmodifiable(permissionTokens),
    );
    return create(draft);
  }

  /// Slice 9.2.2 — replace the permission set on an existing role.
  ///
  /// **Why the guard**: built-in roles (`admin`, `viewer`) are seeded by
  /// the API. Letting the editor mutate them would create configuration
  /// drift between the app and server snapshots. Mark them with
  /// `isSystem: true` and refuse mutations here.
  Future<Role> updatePermissions({
    required Role role,
    required List<String> permissionTokens,
  }) async {
    if (role.isSystem) {
      throw ConflictFailure(message: 'Built-in roles cannot be edited');
    }
    if (permissionTokens.isEmpty) {
      throw ValidationFailure(fieldErrors: {
        'permissionTokens': ['Pick at least one scope'],
      });
    }
    return update(
      role.copyWith(permissionTokens: List.unmodifiable(permissionTokens)),
    );
  }

  /// Slice 9.2.2 — guarded delete.
  ///
  /// Two refusal cases:
  /// - **System role**: same drift-prevention reason as above.
  /// - **Role still in use**: prevents orphaning users whose only role
  ///   is about to vanish. Caller passes the current user list so the
  ///   check is online (no extra repo round-trip).
  Future<void> deleteGuarded({
    required Role role,
    required List<ManagedUser> currentUsers,
  }) async {
    if (role.isSystem) {
      throw ConflictFailure(message: 'Built-in roles cannot be deleted');
    }
    final inUse = currentUsers.any((u) => u.roleIds.contains(role.id));
    if (inUse) {
      throw ConflictFailure(
          message: 'Role is still assigned to one or more users');
    }
    await delete(role.id);
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
  }
}

/// Slice 9.2.3 — API endpoint config (multi-tenant / multi-env).
class ApiEnvironmentsRepository {
  ApiEnvironmentsRepository();

  static final List<ApiEnvironment> _seed =
      List<ApiEnvironment>.of(SettingsSeed.environments);

  static String _currentId = SettingsSeed.defaultEnvironmentId;

  final StreamController<List<ApiEnvironment>> _changes =
      StreamController<List<ApiEnvironment>>.broadcast();
  final StreamController<String> _currentChanges =
      StreamController<String>.broadcast();

  Future<List<ApiEnvironment>> getAll() async => List.unmodifiable(_seed);

  Stream<List<ApiEnvironment>> watchAll() async* {
    yield List.unmodifiable(_seed);
    yield* _changes.stream;
  }

  Future<String> getCurrentId() async => _currentId;

  Stream<String> watchCurrentId() async* {
    yield _currentId;
    yield* _currentChanges.stream;
  }

  Future<void> setCurrent(String environmentId) async {
    _currentId = environmentId;
    if (!_currentChanges.isClosed) _currentChanges.add(_currentId);
  }

  Future<ApiEnvironment> create(ApiEnvironment env) async {
    final id = env.id.isEmpty
        ? 'env-${DateTime.now().microsecondsSinceEpoch}'
        : env.id;
    final stamped = env.copyWith(id: id);
    _seed.add(stamped);
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
    return stamped;
  }

  Future<void> delete(String environmentId) async {
    _seed.removeWhere((e) => e.id == environmentId);
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
  }

  /// Slice 9.2.3 — validate a new custom environment before persisting.
  Future<ApiEnvironment> createFromInput({
    required String name,
    required String baseUrl,
  }) async {
    final errors = <String, List<String>>{};
    if (name.trim().isEmpty) {
      errors.putIfAbsent('name', () => []).add('Required');
    }
    final url = baseUrl.trim();
    if (url.isEmpty) {
      errors.putIfAbsent('baseUrl', () => []).add('Required');
    } else {
      final uri = Uri.tryParse(url);
      final hasScheme =
          uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
      if (!hasScheme || uri.host.isEmpty) {
        errors.putIfAbsent('baseUrl', () => [])
            .add('Must be an http(s) URL');
      }
    }
    if (errors.isNotEmpty) {
      throw ValidationFailure(fieldErrors: errors);
    }
    final draft = ApiEnvironment(
      id: '', // assigned by repo
      name: name.trim(),
      baseUrl: url,
      isBuiltIn: false,
    );
    return create(draft);
  }

  /// Slice 9.2.3 — refuse to delete a built-in env or the currently
  /// selected one.
  Future<void> deleteGuarded({
    required ApiEnvironment env,
    required String currentEnvironmentId,
  }) async {
    if (env.isBuiltIn) {
      throw ConflictFailure(
          message: 'Built-in environments cannot be deleted');
    }
    if (env.id == currentEnvironmentId) {
      throw ConflictFailure(
          message: 'Switch to another environment before deleting this one');
    }
    await delete(env.id);
  }
}
