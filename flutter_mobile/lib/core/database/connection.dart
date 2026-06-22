import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Filename used for the on-device sqlite database. Centralised so tests and
/// migration helpers don't drift apart from the production location.
const String kAppDatabaseFile = 'erp_mobile.sqlite';

/// Opens the production sqlite database file under the app's documents
/// directory.
///
/// Returned as a [LazyDatabase] so the actual file open is deferred until the
/// first query — keeps DI registration synchronous and side-effect free.
LazyDatabase openAppDatabase() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, kAppDatabaseFile));
    return NativeDatabase.createInBackground(file);
  });
}
