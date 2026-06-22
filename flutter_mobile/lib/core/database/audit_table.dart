import 'package:drift/drift.dart';

import '../utils/uuid_generator.dart';

/// Standard audit columns shared by every business-entity table.
///
/// Mix into a feature table with `class Foo extends Table with AuditedTable`
/// to get a UUID primary key plus `createdAt` / `updatedAt` timestamps for
/// free. Server-side IDs simply replace the client-generated UUID at sync
/// time — the column type and meaning don't change.
mixin AuditedTable on Table {
  TextColumn get id => text().clientDefault(newUuid)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
