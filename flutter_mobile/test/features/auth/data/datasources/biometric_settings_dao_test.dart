import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/features/auth/data/datasources/biometric_settings_dao.dart';
import 'package:erp_mobile/features/auth/data/datasources/cached_user_dao.dart';
import 'package:erp_mobile/features/auth/entities/user.dart';
import 'package:test/test.dart';

const _alice = User(
  id: 'u-1',
  email: 'alice@example.com',
  displayName: 'Alice',
);

void main() {
  late AppDatabase db;
  late BiometricSettingsDao dao;
  late CachedUserDao users;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.biometricSettingsDao;
    users = db.cachedUserDao;
    // FK requires the user to exist first.
    await users.cacheUser(_alice);
  });

  tearDown(() => db.close());

  group('BiometricSettingsDao — defaults', () {
    test('isEnabledFor on a never-enrolled user returns false', () async {
      expect(await dao.isEnabledFor('u-1'), isFalse);
    });

    test('isEnabledFor on an unknown user returns false (no row)', () async {
      expect(await dao.isEnabledFor('phantom'), isFalse);
    });
  });

  group('BiometricSettingsDao — setEnabledFor', () {
    test('enabling captures enrolledAt automatically', () async {
      final before = DateTime.now();
      await dao.setEnabledFor('u-1', enabled: true);
      final after = DateTime.now();

      expect(await dao.isEnabledFor('u-1'), isTrue);

      final row = await (db.select(db.biometricSettings)
            ..where((r) => r.userId.equals('u-1')))
          .getSingle();
      expect(row.enabled, isTrue);
      // Allow second-precision wiggle since drift may round.
      expect(
        row.enrolledAt!.isBefore(after.add(const Duration(seconds: 1))) &&
            row.enrolledAt!.isAfter(
              before.subtract(const Duration(seconds: 1)),
            ),
        isTrue,
      );
    });

    test('honours an explicit enrolledAt', () async {
      final ts = DateTime.utc(2026, 5, 12, 10);
      await dao.setEnabledFor('u-1', enabled: true, enrolledAt: ts);

      final row = await (db.select(db.biometricSettings)
            ..where((r) => r.userId.equals('u-1')))
          .getSingle();
      // Stored as Unix seconds — match by epoch second.
      expect(
        row.enrolledAt!.millisecondsSinceEpoch ~/ 1000,
        ts.millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('disabling clears enrolledAt', () async {
      await dao.setEnabledFor('u-1', enabled: true);
      await dao.setEnabledFor('u-1', enabled: false);

      final row = await (db.select(db.biometricSettings)
            ..where((r) => r.userId.equals('u-1')))
          .getSingle();
      expect(row.enabled, isFalse);
      expect(row.enrolledAt, isNull);
    });

    test('toggle is idempotent (single row per user)', () async {
      await dao.setEnabledFor('u-1', enabled: true);
      await dao.setEnabledFor('u-1', enabled: true);
      await dao.setEnabledFor('u-1', enabled: false);

      final rows = await db.select(db.biometricSettings).get();
      expect(rows, hasLength(1));
    });
  });

  group('BiometricSettingsDao — watchEnabledFor', () {
    test('emits as the preference toggles', () async {
      final emitted = <bool>[];
      final sub = dao.watchEnabledFor('u-1').listen(emitted.add);

      await pumpEventQueue();
      await dao.setEnabledFor('u-1', enabled: true);
      await pumpEventQueue();
      await dao.setEnabledFor('u-1', enabled: false);
      await pumpEventQueue();

      await sub.cancel();

      // Initial: false (no row). Then true. Then false again.
      expect(emitted.first, isFalse);
      expect(emitted, contains(true));
      expect(emitted.last, isFalse);
    });
  });

  group('BiometricSettingsDao — deleteFor', () {
    test('removes the row and returns 1', () async {
      await dao.setEnabledFor('u-1', enabled: true);
      expect(await dao.deleteFor('u-1'), 1);
      expect(await dao.isEnabledFor('u-1'), isFalse);
    });

    test('returns 0 when no row exists', () async {
      expect(await dao.deleteFor('u-1'), 0);
    });
  });

  group('BiometricSettingsDao — FK cascade with cached_user', () {
    test('deleting the cached user wipes the biometric pref too', () async {
      await dao.setEnabledFor('u-1', enabled: true);
      expect(await dao.isEnabledFor('u-1'), isTrue);

      await users.deleteUser('u-1');

      // CASCADE clears the row.
      final rows = await (db.select(db.biometricSettings)
            ..where((r) => r.userId.equals('u-1')))
          .get();
      expect(rows, isEmpty);
    });
  });
}
