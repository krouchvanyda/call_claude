import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/features/auth/data/repositories/permissions_repository.dart';
import 'package:erp_mobile/features/auth/entities/permission.dart';
import 'package:erp_mobile/features/auth/entities/user.dart';
import 'package:test/test.dart';

const _alice = User(
  id: 'u-1',
  email: 'alice@example.com',
  displayName: 'Alice',
);

void main() {
  late AppDatabase db;
  late PermissionsRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = PermissionsRepository(cachedUserDao: db.cachedUserDao);
    // FK requires the user to exist before we can write permissions.
    await db.cachedUserDao.cacheUser(_alice);
  });

  tearDown(() => db.close());

  group('getPermissions', () {
    test('returns empty set when no permissions cached', () async {
      // Re-cache without any roles.
      await db.cachedUserDao.cacheUser(_alice);
      expect(await repo.getPermissions('u-1'), isEmpty);
    });

    test('maps each row to a Permission value object', () async {
      await db.cachedUserDao.cacheUser(_alice.copyWith(
        roles: {'finance.invoice.create', 'admin'},
      ));
      final perms = await repo.getPermissions('u-1');
      expect(perms, {
        const Permission(token: 'finance.invoice.create'),
        const Permission(token: 'admin'),
      });
    });

    test('returns empty for an unknown user', () async {
      expect(await repo.getPermissions('phantom'), isEmpty);
    });
  });

  group('cachePermissions (atomic replace)', () {
    test('replaces an existing permission set wholesale (no ghosts)',
        () async {
      await db.cachedUserDao.cacheUser(_alice.copyWith(
        roles: {'finance.invoice.create', 'admin'},
      ));
      // Server downgrades — `admin` removed, new permission added.
      await repo.cachePermissions('u-1', {
        const Permission(token: 'finance.invoice.read'),
        const Permission(token: 'inventory.stock.read'),
      });

      expect(await repo.getPermissions('u-1'), {
        const Permission(token: 'finance.invoice.read'),
        const Permission(token: 'inventory.stock.read'),
      });
    });

    test('writing an empty set wipes all permissions for the user',
        () async {
      await db.cachedUserDao.cacheUser(_alice.copyWith(roles: {'admin'}));
      await repo.cachePermissions('u-1', const <Permission>{});
      expect(await repo.getPermissions('u-1'), isEmpty);
    });

    test('does not touch other users\' permissions', () async {
      const bob = User(id: 'u-2', email: 'b@c.io', displayName: 'B');
      await db.cachedUserDao.cacheUser(bob.copyWith(roles: {'sales.read'}));

      await repo.cachePermissions('u-1', {
        const Permission(token: 'finance.invoice.read'),
      });

      expect(await repo.getPermissions('u-2'),
          {const Permission(token: 'sales.read')});
    });
  });

  group('hasPermission', () {
    test('exact-match wins', () async {
      await db.cachedUserDao.cacheUser(_alice.copyWith(
        roles: {'finance.invoice.create'},
      ));
      expect(
        await repo.hasPermission(
          'u-1',
          const Permission(token: 'finance.invoice.create'),
        ),
        isTrue,
      );
    });

    test('wildcard held permission grants the request', () async {
      await db.cachedUserDao.cacheUser(_alice.copyWith(
        roles: {'finance.*'},
      ));
      expect(
        await repo.hasPermission(
          'u-1',
          const Permission(token: 'finance.invoice.create'),
        ),
        isTrue,
      );
    });

    test('returns false when no held permission satisfies', () async {
      await db.cachedUserDao.cacheUser(_alice.copyWith(
        roles: {'inventory.stock.read'},
      ));
      expect(
        await repo.hasPermission(
          'u-1',
          const Permission(token: 'finance.invoice.create'),
        ),
        isFalse,
      );
    });

    test('returns false for an unknown user', () async {
      expect(
        await repo.hasPermission(
          'phantom',
          const Permission(token: 'admin'),
        ),
        isFalse,
      );
    });
  });

  group('watchPermissions', () {
    test('emits as cachePermissions writes', () async {
      final emitted = <Set<Permission>>[];
      final sub = repo.watchPermissions('u-1').listen(emitted.add);

      await pumpEventQueue();
      await repo.cachePermissions('u-1', {
        const Permission(token: 'a'),
      });
      await pumpEventQueue();
      await repo.cachePermissions('u-1', {
        const Permission(token: 'a'),
        const Permission(token: 'b'),
      });
      await pumpEventQueue();
      await sub.cancel();

      // Initial empty set, then `{a}`, then `{a, b}` — final state is
      // the right invariant; intermediate emissions may collapse.
      // `contains`/`equals` for Sets need content equality (Set.== is
      // reference-equal), so wrap with `equals(...)`.
      expect(emitted.first, isEmpty);
      expect(
        emitted,
        contains(equals({const Permission(token: 'a')})),
      );
      expect(
        emitted.last,
        equals({
          const Permission(token: 'a'),
          const Permission(token: 'b'),
        }),
      );
    });
  });
}
