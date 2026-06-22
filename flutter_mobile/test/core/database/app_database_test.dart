import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:test/test.dart';

void main() {
  group('AppDatabase — schema', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion is 9 (Slice 5.3.1 added cached_inventory_items + movements)',
        () {
      expect(db.schemaVersion, 9);
    });

    test('appMetadata table is created and accepts inserts', () async {
      // Force the connection to open and run onCreate.
      await db
          .into(db.appMetadata)
          .insert(AppMetadataCompanion.insert(key: 'k', value: 'v'));

      final rows = await db.select(db.appMetadata).get();
      expect(rows, hasLength(1));
      expect(rows.single.key, 'k');
      expect(rows.single.value, 'v');
      expect(rows.single.updatedAt, isNotNull);
    });

    test('primary key on `key` enforces uniqueness', () async {
      await db
          .into(db.appMetadata)
          .insert(AppMetadataCompanion.insert(key: 'k', value: 'first'));

      // Second insert on the same key must throw without `mode:`.
      expect(
        () => db
            .into(db.appMetadata)
            .insert(AppMetadataCompanion.insert(key: 'k', value: 'second')),
        throwsA(isA<SqliteException>()),
      );

      // `insertOrReplace` must overwrite cleanly.
      await db.into(db.appMetadata).insert(
            AppMetadataCompanion.insert(key: 'k', value: 'second'),
            mode: InsertMode.insertOrReplace,
          );
      final stored = await (db.select(db.appMetadata)
            ..where((r) => r.key.equals('k')))
          .getSingle();
      expect(stored.value, 'second');
    });

    test('beforeOpen enables PRAGMA foreign_keys', () async {
      // Trigger connection open via any query.
      await db.customSelect('SELECT 1').get();
      final result = await db.customSelect('PRAGMA foreign_keys').getSingle();
      expect(result.data.values.first, 1);
    });
  });

  group('AppDatabase — migrations', () {
    test(
      'onUpgrade throws a guidance error when no step is registered',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);

        // Run the migrator manually with a hypothetical bumped target so we
        // exercise the "no migration registered" guard without bumping the
        // real schemaVersion. Start from the *current* schemaVersion so the
        // already-applied v2 step doesn't try to re-create its table.
        await expectLater(
          () => db.transaction(() async {
            await db.migration.onUpgrade(Migrator(db), 5, 99);
          }),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('No migration registered'),
            ),
          ),
        );
      },
      // SQLite will roll the failed transaction back; the guidance message
      // is the contract under test.
    );
  });
}
