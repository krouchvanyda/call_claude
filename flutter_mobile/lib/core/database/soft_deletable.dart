import 'package:drift/drift.dart';

/// Adds a soft-delete pair (`isDeleted`, `deletedAt`) to a table.
///
/// Use when you need tombstones for offline conflict resolution or when an
/// entity must remain referenceable from historical data even after the user
/// deletes it (audit logs). DAOs filtering against `isDeleted = false` is
/// the responsibility of the per-feature DAO — the mixin only declares the
/// columns.
mixin SoftDeletable on Table {
  BoolColumn get isDeleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}
