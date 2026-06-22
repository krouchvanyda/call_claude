import 'package:erp_mobile/core/error/failure.dart';
import 'package:erp_mobile/features/settings/data/repositories/admin_repositories.dart';
import 'package:erp_mobile/features/settings/entities/api_environment.dart';
import 'package:erp_mobile/features/settings/entities/managed_user.dart';
import 'package:test/test.dart';

ManagedUser _u({
  String id = 'u',
  ManagedUserStatus status = ManagedUserStatus.active,
  List<String> roleIds = const ['role-viewer'],
}) =>
    ManagedUser(
      id: id,
      email: 'u@erp.example',
      name: 'U',
      status: status,
      roleIds: roleIds,
      createdAt: DateTime.utc(2026, 1, 1),
    );

Role _role({
  String id = 'r',
  bool isSystem = false,
  List<String> tokens = const ['finance.read'],
}) =>
    Role(
      id: id,
      name: 'Test',
      description: 'd',
      permissionTokens: tokens,
      isSystem: isSystem,
    );

void main() {
  group('ManagedUsersRepository.invite', () {
    final now = DateTime.utc(2026, 5, 15);

    test('accepts a well-formed invite', () async {
      final repo = ManagedUsersRepository();
      final u = await repo.invite(
        email: '  Foo@Bar.com ',
        name: '  Foo  ',
        roleIds: ['role-viewer'],
        now: now,
      );
      // Email lowercased + trimmed.
      expect(u.email, 'foo@bar.com');
      expect(u.name, 'Foo');
      expect(u.status, ManagedUserStatus.invited);
      // Repo assigns a non-empty id when persisting.
      expect(u.id, isNotEmpty);
    });

    test('rejects malformed email', () {
      final repo = ManagedUsersRepository();
      expect(
        () => repo.invite(
          email: 'no-at-sign',
          name: 'X',
          roleIds: ['role-viewer'],
          now: now,
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.fieldErrors,
          'fieldErrors',
          containsPair('email', isNotEmpty),
        )),
      );
    });

    test('rejects empty name and missing roles', () {
      final repo = ManagedUsersRepository();
      expect(
        () => repo.invite(
          email: 'ok@ok.com',
          name: '   ',
          roleIds: const [],
          now: now,
        ),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.fieldErrors,
          'fieldErrors',
          allOf(
            containsPair('name', isNotEmpty),
            containsPair('roleIds', isNotEmpty),
          ),
        )),
      );
    });
  });

  group('ManagedUsersRepository.changeStatus', () {
    test('flips status when not self', () async {
      final repo = ManagedUsersRepository();
      // Seed the user first so update() finds it.
      final created = await repo.create(_u(id: 'other'));
      final out = await repo.changeStatus(
        user: created,
        newStatus: ManagedUserStatus.suspended,
        currentUserId: 'me',
      );
      expect(out.status, ManagedUserStatus.suspended);
    });

    test('refuses to suspend self', () {
      final repo = ManagedUsersRepository();
      expect(
        () => repo.changeStatus(
          user: _u(id: 'me'),
          newStatus: ManagedUserStatus.suspended,
          currentUserId: 'me',
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('no-op when status unchanged', () async {
      final repo = ManagedUsersRepository();
      final u = _u(id: 'other', status: ManagedUserStatus.active);
      final out = await repo.changeStatus(
        user: u,
        newStatus: ManagedUserStatus.active,
        currentUserId: 'me',
      );
      expect(out, same(u));
    });
  });

  group('ManagedUsersRepository.assignRoles', () {
    test('refuses to remove every role from self', () {
      final repo = ManagedUsersRepository();
      expect(
        () => repo.assignRoles(
          user: _u(id: 'me'),
          roleIds: const [],
          currentUserId: 'me',
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('allows removing all roles from another user', () async {
      final repo = ManagedUsersRepository();
      final created = await repo.create(_u(id: 'other'));
      final out = await repo.assignRoles(
        user: created,
        roleIds: const [],
        currentUserId: 'me',
      );
      expect(out.roleIds, isEmpty);
    });
  });

  group('RolesRepository.createFromInput', () {
    test('accepts well-formed input', () async {
      final repo = RolesRepository();
      final r = await repo.createFromInput(
        name: '  Finance Manager  ',
        description: 'd',
        permissionTokens: ['finance.*'],
      );
      expect(r.name, 'Finance Manager');
      expect(r.permissionTokens, ['finance.*']);
      expect(r.isSystem, isFalse);
    });

    test('rejects empty name', () {
      final repo = RolesRepository();
      expect(
        () => repo.createFromInput(
          name: '',
          description: 'd',
          permissionTokens: ['finance.*'],
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('rejects empty permission set', () {
      final repo = RolesRepository();
      expect(
        () => repo.createFromInput(
          name: 'X',
          description: 'd',
          permissionTokens: const [],
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('RolesRepository.updatePermissions', () {
    test('refuses to mutate built-in roles', () {
      final repo = RolesRepository();
      expect(
        () => repo.updatePermissions(
          role: _role(isSystem: true),
          permissionTokens: ['admin'],
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('refuses empty permission set on update', () {
      final repo = RolesRepository();
      expect(
        () => repo.updatePermissions(
          role: _role(),
          permissionTokens: const [],
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });

    test('returns updated role on success', () async {
      final repo = RolesRepository();
      final created = await repo.create(_role(id: 'role-up'));
      final out = await repo.updatePermissions(
        role: created,
        permissionTokens: ['inventory.read', 'sales.read'],
      );
      expect(out.permissionTokens, ['inventory.read', 'sales.read']);
    });
  });

  group('RolesRepository.deleteGuarded', () {
    test('refuses built-in', () {
      final repo = RolesRepository();
      expect(
        () => repo.deleteGuarded(
          role: _role(isSystem: true),
          currentUsers: const [],
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('refuses if any user holds the role', () {
      final repo = RolesRepository();
      expect(
        () => repo.deleteGuarded(
          role: _role(id: 'role-x'),
          currentUsers: [_u(id: 'u1', roleIds: ['role-x'])],
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('passes when role is unused and not built-in', () async {
      final repo = RolesRepository();
      await repo.deleteGuarded(
        role: _role(id: 'role-x'),
        currentUsers: [_u(id: 'u1', roleIds: ['role-y'])],
      );
    });
  });

  group('ApiEnvironmentsRepository.createFromInput', () {
    test('accepts a https URL', () async {
      final repo = ApiEnvironmentsRepository();
      final env = await repo.createFromInput(
        name: 'Tenant A',
        baseUrl: 'https://api.tenant-a.example',
      );
      expect(env.name, 'Tenant A');
      expect(env.baseUrl, 'https://api.tenant-a.example');
      expect(env.isBuiltIn, isFalse);
    });

    test('accepts an http URL (e.g. local dev)', () async {
      final repo = ApiEnvironmentsRepository();
      final env = await repo.createFromInput(
        name: 'Local',
        baseUrl: 'http://localhost:8080',
      );
      expect(env.baseUrl, 'http://localhost:8080');
    });

    test('rejects empty name', () {
      final repo = ApiEnvironmentsRepository();
      expect(
        () => repo.createFromInput(
            name: '', baseUrl: 'https://x.example'),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.fieldErrors,
          'fieldErrors',
          containsPair('name', isNotEmpty),
        )),
      );
    });

    test('rejects non-http(s) scheme', () {
      final repo = ApiEnvironmentsRepository();
      expect(
        () => repo.createFromInput(
            name: 'X', baseUrl: 'ftp://files.example'),
        throwsA(isA<ValidationFailure>().having(
          (f) => f.fieldErrors,
          'fieldErrors',
          containsPair('baseUrl', isNotEmpty),
        )),
      );
    });

    test('rejects URL with no host', () {
      final repo = ApiEnvironmentsRepository();
      expect(
        () => repo.createFromInput(name: 'X', baseUrl: 'https://'),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('ApiEnvironmentsRepository.deleteGuarded', () {
    final builtIn = ApiEnvironment(
      id: 'env-prod',
      name: 'Prod',
      baseUrl: 'https://api.example',
      isBuiltIn: true,
    );
    final custom = ApiEnvironment(
      id: 'env-tenant',
      name: 'Tenant',
      baseUrl: 'https://tenant.example',
    );

    test('refuses built-in', () {
      final repo = ApiEnvironmentsRepository();
      expect(
        () => repo.deleteGuarded(
          env: builtIn,
          currentEnvironmentId: 'env-other',
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('refuses currently selected env', () {
      final repo = ApiEnvironmentsRepository();
      expect(
        () => repo.deleteGuarded(
          env: custom,
          currentEnvironmentId: 'env-tenant',
        ),
        throwsA(isA<ConflictFailure>()),
      );
    });

    test('passes for an inactive custom env', () async {
      final repo = ApiEnvironmentsRepository();
      await repo.deleteGuarded(
        env: custom,
        currentEnvironmentId: 'env-prod',
      );
    });
  });
}
