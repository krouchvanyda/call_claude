import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:erp_mobile/core/database/app_database.dart';
import 'package:erp_mobile/core/database/app_metadata_dao.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late AppMetadataDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = db.appMetadataDao;
  });

  tearDown(() => db.close());

  group('BaseDao primitives via AppMetadataDao', () {
    test('findAll on an empty table returns []', () async {
      expect(await dao.findAll(), isEmpty);
    });

    test('count is 0 on empty, then matches inserts', () async {
      expect(await dao.count(), 0);
      expect(await dao.exists(), isFalse);

      await dao.putValue('a', '1');
      await dao.putValue('b', '2');

      expect(await dao.count(), 2);
      expect(await dao.exists(), isTrue);
    });

    test('findAll returns every inserted row', () async {
      await dao.putValue('a', '1');
      await dao.putValue('b', '2');

      final rows = await dao.findAll();
      expect(rows.map((r) => r.key).toSet(), {'a', 'b'});
    });

    test('watchAll emits a fresh snapshot on every write', () async {
      final emitted = <int>[];
      final sub = dao.watchAll().listen((rows) => emitted.add(rows.length));

      // Initial empty snapshot.
      await pumpEventQueue();
      await dao.putValue('a', '1');
      await pumpEventQueue();
      await dao.putValue('b', '2');
      await pumpEventQueue();
      await dao.remove('a');
      await pumpEventQueue();

      await sub.cancel();
      // Must observe both growth and shrinkage; trailing snapshots may
      // collapse, so assert progression rather than exact length.
      expect(emitted.first, 0);
      expect(emitted, contains(2));
      expect(emitted.last, 1);
    });

    test('deleteAll wipes the table', () async {
      await dao.bulkInsertOrReplace(const [
        AppMetadataCompanion(
          key: Value('a'),
          value: Value('1'),
        ),
        AppMetadataCompanion(
          key: Value('b'),
          value: Value('2'),
        ),
      ]);
      expect(await dao.count(), 2);

      final removed = await dao.deleteAll();
      expect(removed, 2);
      expect(await dao.findAll(), isEmpty);
    });

    test('bulkInsertOrReplace upserts in a single batch', () async {
      // Seed a row, then bulk-upsert one matching key + one new key.
      await dao.putValue('a', 'original');
      await dao.bulkInsertOrReplace(const [
        AppMetadataCompanion(
          key: Value('a'),
          value: Value('overwritten'),
        ),
        AppMetadataCompanion(
          key: Value('c'),
          value: Value('new'),
        ),
      ]);

      expect(await dao.count(), 2);
      expect(await dao.getValue('a'), 'overwritten');
      expect(await dao.getValue('c'), 'new');
    });
  });

  group('AppMetadataDao — domain helpers', () {
    test('getValue returns null for an unset key', () async {
      expect(await dao.getValue('missing'), isNull);
    });

    test('putValue + getValue round-trip', () async {
      await dao.putValue('lastSync.invoices', '2026-05-12T10:00:00Z');
      expect(await dao.getValue('lastSync.invoices'), '2026-05-12T10:00:00Z');
    });

    test('putValue overwrites existing value (insert-or-replace)', () async {
      await dao.putValue('k', 'first');
      await dao.putValue('k', 'second');
      expect(await dao.getValue('k'), 'second');
      expect(await dao.count(), 1, reason: 'single row, not duplicates');
    });

    test('watchValue emits null then the latest value', () async {
      final values = <String?>[];
      final sub = dao.watchValue('feature.flag').listen(values.add);

      await pumpEventQueue();
      await dao.putValue('feature.flag', 'on');
      await pumpEventQueue();
      await dao.putValue('feature.flag', 'off');
      await pumpEventQueue();
      await sub.cancel();

      expect(values.first, isNull);
      expect(values, contains('on'));
      expect(values.last, 'off');
    });

    test('remove() deletes only the targeted key', () async {
      await dao.putValue('a', '1');
      await dao.putValue('b', '2');

      final removed = await dao.remove('a');
      expect(removed, 1);
      expect(await dao.getValue('a'), isNull);
      expect(await dao.getValue('b'), '2');
    });

    test('remove() on a missing key is a no-op', () async {
      final removed = await dao.remove('never-set');
      expect(removed, 0);
    });
  });
}
