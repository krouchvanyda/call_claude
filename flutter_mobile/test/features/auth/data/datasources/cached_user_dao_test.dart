import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/features/auth/data/datasources/cached_user_dao.dart';
import 'package:erp_mobile/features/auth/entities/user.dart';
import 'package:test/test.dart';

const _alice = User(
  id: 'u-1',
  email: 'alice@example.com',
  displayName: 'Alice',
  roles: {'admin', 'finance.invoice.create'},
);

void main() {
  late AppDatabase db;
  late CachedUserDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.cachedUserDao;
  });

  tearDown(() => db.close());

  group('cacheUser', () {
    test('round-trips the profile and permission set', () async {
      await dao.cacheUser(_alice);

      final read = await dao.getUser('u-1');
      expect(read, isNotNull);
      expect(read!.id, 'u-1');
      expect(read.email, 'alice@example.com');
      expect(read.displayName, 'Alice');
      expect(read.roles, {'admin', 'finance.invoice.create'});
    });

    test('caches a user with no permissions cleanly', () async {
      const u = User(id: 'u-2', email: 'b@c.io', displayName: 'B');
      await dao.cacheUser(u);

      final read = await dao.getUser('u-2');
      expect(read?.roles, isEmpty);
    });

    test('re-cache replaces the permission set atomically (no ghosts)',
        () async {
      await dao.cacheUser(_alice);
      // Server downgrades the user — 'admin' is removed, a new role added.
      await dao.cacheUser(_alice.copyWith(
        roles: {'finance.invoice.create', 'hr.payroll.read'},
      ));

      final read = await dao.getUser('u-1');
      expect(read?.roles,
          {'finance.invoice.create', 'hr.payroll.read'});
    });

    test('re-cache updates profile fields without duplicating the row',
        () async {
      await dao.cacheUser(_alice);
      await dao.cacheUser(_alice.copyWith(displayName: 'Alice Smith'));

      final read = await dao.getUser('u-1');
      expect(read?.displayName, 'Alice Smith');
      // Verify there's still exactly one row in cached_user.
      final all = await db.select(db.cachedUser).get();
      expect(all, hasLength(1));
    });
  });

  group('getUser', () {
    test('returns null for an unknown id', () async {
      expect(await dao.getUser('phantom'), isNull);
    });
  });

  group('getCurrentUser / watchCurrentUser', () {
    test('returns null when no user is cached', () async {
      expect(await dao.getCurrentUser(), isNull);
    });

    test('returns the most-recently-cached user', () async {
      // Drift stores DateTime as Unix-epoch seconds, so two cacheUser()
      // calls inside the same second would tie on cachedAt and the
      // ORDER BY would be non-deterministic. Insert "Old" with an
      // explicit, clearly older timestamp so the assertion is robust
      // without burning a real-time delay in the test.
      await db.into(db.cachedUser).insert(
            CachedUserCompanion.insert(
              id: 'u-old',
              email: 'old@example.com',
              displayName: 'Old',
              cachedAt: Value(DateTime.utc(2020)),
            ),
          );
      await dao.cacheUser(_alice);

      final current = await dao.getCurrentUser();
      expect(current?.id, 'u-1');
    });

    test('watchCurrentUser emits as the cache evolves', () async {
      final emitted = <String?>[];
      final sub = dao
          .watchCurrentUser()
          .listen((u) => emitted.add(u?.displayName));

      // Initial: null (no user cached yet).
      await pumpEventQueue();
      await dao.cacheUser(_alice);
      await pumpEventQueue();
      await dao.cacheUser(_alice.copyWith(displayName: 'Alice Smith'));
      await pumpEventQueue();
      await dao.deleteUser('u-1');
      await pumpEventQueue();

      await sub.cancel();

      expect(emitted.first, isNull);
      expect(emitted, contains('Alice'));
      expect(emitted, contains('Alice Smith'));
      expect(emitted.last, isNull);
    });
  });

  group('getPermissions / hasPermission', () {
    test('getPermissions returns the cached set', () async {
      await dao.cacheUser(_alice);
      expect(await dao.getPermissions('u-1'),
          {'admin', 'finance.invoice.create'});
    });

    test('getPermissions returns empty for unknown user', () async {
      expect(await dao.getPermissions('phantom'), isEmpty);
    });

    test('hasPermission true for granted role', () async {
      await dao.cacheUser(_alice);
      expect(await dao.hasPermission('u-1', 'admin'), isTrue);
    });

    test('hasPermission false for unheld role', () async {
      await dao.cacheUser(_alice);
      expect(await dao.hasPermission('u-1', 'hr.payroll.read'), isFalse);
    });

    test('hasPermission false for unknown user', () async {
      expect(await dao.hasPermission('phantom', 'admin'), isFalse);
    });
  });

  group('deleteUser — ON DELETE CASCADE', () {
    test('removes the profile and cascades to permissions', () async {
      await dao.cacheUser(_alice);
      // Sanity — permissions exist.
      expect(await dao.getPermissions('u-1'), isNotEmpty);

      final removed = await dao.deleteUser('u-1');
      expect(removed, 1);

      expect(await dao.getUser('u-1'), isNull);
      expect(
        await dao.getPermissions('u-1'),
        isEmpty,
        reason: 'ON DELETE CASCADE must have wiped the rows',
      );

      // Confirm at the SQL level: zero rows in user_permissions for that id.
      final orphans = await (db.select(db.userPermissions)
            ..where((r) => r.userId.equals('u-1')))
          .get();
      expect(orphans, isEmpty);
    });

    test('returns 0 when the id is absent', () async {
      expect(await dao.deleteUser('phantom'), 0);
    });

    test('does not touch other users\' permissions', () async {
      await dao.cacheUser(_alice);
      const bob = User(
        id: 'u-2',
        email: 'bob@example.com',
        displayName: 'Bob',
        roles: {'sales.read'},
      );
      await dao.cacheUser(bob);

      await dao.deleteUser('u-1');

      expect(await dao.getUser('u-2'), isNotNull);
      expect(await dao.getPermissions('u-2'), {'sales.read'});
    });
  });

  group('deletePermissions (Slice 1.1.4)', () {
    test('removes every permission for a user but keeps the profile',
        () async {
      await dao.cacheUser(_alice);

      final removed = await dao.deletePermissions('u-1');
      expect(removed, 2);
      expect(await dao.getPermissions('u-1'), isEmpty);

      final read = await dao.getUser('u-1');
      expect(read, isNotNull);
      expect(read!.roles, isEmpty);
    });

    test('returns 0 when the user has no permissions cached', () async {
      const u = User(id: 'u-2', email: 'b@c.io', displayName: 'B');
      await dao.cacheUser(u);
      expect(await dao.deletePermissions('u-2'), 0);
    });

    test("does not touch other users' permissions", () async {
      await dao.cacheUser(_alice);
      const bob = User(
        id: 'u-2',
        email: 'bob@example.com',
        displayName: 'Bob',
        roles: {'sales.read'},
      );
      await dao.cacheUser(bob);

      await dao.deletePermissions('u-1');

      expect(await dao.getPermissions('u-2'), {'sales.read'});
    });
  });

  group('replacePermissions (Slice 1.3.1)', () {
    test('atomically replaces the permission set without touching profile',
        () async {
      await dao.cacheUser(_alice);
      await dao.replacePermissions('u-1', {
        'finance.invoice.read',
        'inventory.stock.read',
      });

      // Permissions are exactly the new set.
      expect(await dao.getPermissions('u-1'), {
        'finance.invoice.read',
        'inventory.stock.read',
      });
      // Profile fields untouched.
      final user = await dao.getUser('u-1');
      expect(user?.email, _alice.email);
      expect(user?.displayName, _alice.displayName);
    });

    test('writing an empty set wipes all permissions', () async {
      await dao.cacheUser(_alice);
      await dao.replacePermissions('u-1', const <String>{});
      expect(await dao.getPermissions('u-1'), isEmpty);
    });

    test("does not touch other users' permissions", () async {
      await dao.cacheUser(_alice);
      const bob = User(
        id: 'u-2',
        email: 'bob@example.com',
        displayName: 'Bob',
        roles: {'sales.read'},
      );
      await dao.cacheUser(bob);

      await dao.replacePermissions('u-1', {'admin'});

      expect(await dao.getPermissions('u-2'), {'sales.read'});
      expect(await dao.getPermissions('u-1'), {'admin'});
    });
  });

  group('watchPermissionsFor (Slice 1.3.1)', () {
    test('emits as the row set evolves', () async {
      await dao.cacheUser(_alice);

      final emitted = <Set<String>>[];
      final sub = dao.watchPermissionsFor('u-1').listen(emitted.add);

      await pumpEventQueue();
      await dao.replacePermissions('u-1', {'a'});
      await pumpEventQueue();
      await dao.replacePermissions('u-1', {'a', 'b'});
      await pumpEventQueue();
      await dao.replacePermissions('u-1', const <String>{});
      await pumpEventQueue();

      await sub.cancel();

      // Initial snapshot may be empty (no rows pre-write) OR `_alice`'s
      // existing role set, depending on what was seeded above. Assert
      // progression rather than exact list.
      // `contains` does reference-equality on Sets, so wrap with `equals`
      // to get content equality.
      expect(emitted, contains(equals({'a'})));
      expect(emitted, contains(equals({'a', 'b'})));
      expect(emitted.last, isEmpty);
    });
  });

  group('wipeAll (logout)', () {
    test('clears every cached user and every permission row', () async {
      await dao.cacheUser(_alice);
      await dao.cacheUser(const User(
        id: 'u-2',
        email: 'b@c.io',
        displayName: 'B',
        roles: {'sales.read'},
      ));

      await dao.wipeAll();

      expect(await db.select(db.cachedUser).get(), isEmpty);
      expect(await db.select(db.userPermissions).get(), isEmpty);
      expect(await dao.getCurrentUser(), isNull);
    });

    test('no-op on an empty cache', () async {
      await dao.wipeAll();
      expect(await dao.getCurrentUser(), isNull);
    });
  });
}
