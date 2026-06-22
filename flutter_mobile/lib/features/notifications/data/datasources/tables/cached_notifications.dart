import 'package:drift/drift.dart';

import '../../../../../core/utils/uuid_generator.dart';

/// Drift table for the on-device notification inbox (Slice 2.3.1).
///
/// **Storage rule**: notifications are non-secret metadata — they live
/// in drift, never in `flutter_secure_storage`. The push token / device
/// registration ID (Slice 2.3.2) is the secret part and stays in
/// secure storage.
///
/// **Categories** are free-form strings (`'invoice'`, `'leave-request'`,
/// `'system'`, …) so the server can introduce new ones without a client
/// schema bump; the UI maps unknown categories to a generic icon.
///
/// **Read state** is encoded as `readAt` nullable — null means unread.
/// A boolean column would lose the "when did the user read this" signal
/// useful for analytics / undo windows.
///
/// **Dismissed** rows are kept (not deleted) so a future "show
/// dismissed" toggle can restore them; the inbox query filters them out.
@DataClassName('CachedNotificationRow')
class CachedNotifications extends Table {
  /// UUIDv4 — generated client-side at insert time when the source
  /// (server / push) didn't provide one. Server-issued ids round-trip
  /// unchanged so dedupe works.
  TextColumn get id => text().clientDefault(newUuid)();

  TextColumn get title => text()();
  TextColumn get body => text()();

  /// Category discriminator — see file-level docs.
  TextColumn get category => text()();

  /// Optional deep-link target: a `go_router` named route. `null` means
  /// "this notification is informational, no navigation".
  TextColumn get routeName => text().nullable()();

  /// JSON-encoded `Map<String, String>` of path parameters for the
  /// deep link. Empty / null when [routeName] is null or paramless.
  TextColumn get routeParamsJson => text().nullable()();

  /// When the server / device first emitted the notification.
  /// Newest-first ordering in the inbox is `ORDER BY received_at DESC`.
  DateTimeColumn get receivedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Null = unread. Set to `now()` when the user opens the row.
  DateTimeColumn get readAt => dateTime().nullable()();

  /// Tombstone — `true` when the user swiped to dismiss. The row is
  /// kept to support an undo window / dismissed view; the inbox
  /// query filters them out.
  BoolColumn get dismissed =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
