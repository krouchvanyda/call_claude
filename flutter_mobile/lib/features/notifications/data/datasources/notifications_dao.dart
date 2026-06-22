import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/notification.dart' as domain;
import 'tables/cached_notifications.dart';

part 'notifications_dao.g.dart';

/// Drift-backed DAO for the notification inbox (Slice 2.3.1).
///
/// Handles the row ↔ domain entity mapping at the boundary so the rest
/// of the codebase works with the typed [domain.AppNotification] and
/// never sees drift's row classes.
///
/// **Why a single dao for the whole feature**: notifications are a thin
/// table — splitting reads / writes across multiple daos would only add
/// ceremony. Future per-channel daos (push, email, in-app) live next to
/// their respective tables when they ship.
@DriftAccessor(tables: [CachedNotifications])
class NotificationsDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationsDaoMixin {
  NotificationsDao(super.db);

  // ── Writes ───────────────────────────────────────────────────

  /// Inserts (or replaces by id) a notification. The DAO never deletes
  /// on dismiss — see the table's tombstone comment.
  Future<void> upsert(domain.AppNotification n) {
    return into(cachedNotifications).insert(
      _toCompanion(n),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Bulk insert — used by the push slice (2.3.2) to drain a batch of
  /// queued notifications in a single transaction.
  Future<void> upsertAll(Iterable<domain.AppNotification> all) {
    return batch((b) {
      for (final n in all) {
        b.insert(
          cachedNotifications,
          _toCompanion(n),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  /// Marks a single row as read (sets `read_at` to [now]). Returns the
  /// number of rows affected — `0` when the id is absent.
  Future<int> markRead(String id, {DateTime? now}) {
    return (update(cachedNotifications)..where((r) => r.id.equals(id))).write(
      CachedNotificationsCompanion(
        readAt: Value(now ?? DateTime.now().toUtc()),
      ),
    );
  }

  /// Marks every unread, non-dismissed row as read in one statement.
  /// Returns the number of rows touched.
  Future<int> markAllRead({DateTime? now}) {
    return (update(cachedNotifications)
          ..where((r) => r.readAt.isNull() & r.dismissed.equals(false)))
        .write(
      CachedNotificationsCompanion(
        readAt: Value(now ?? DateTime.now().toUtc()),
      ),
    );
  }

  /// Tombstones a row — flips `dismissed` true. The row stays so a
  /// future "show dismissed" toggle can restore it.
  Future<int> dismiss(String id) {
    return (update(cachedNotifications)..where((r) => r.id.equals(id)))
        .write(const CachedNotificationsCompanion(dismissed: Value(true)));
  }

  /// Hard-delete every row — called on sign-out / cache wipe so the
  /// next user doesn't inherit the previous identity's inbox.
  Future<void> wipeAll() async {
    await delete(cachedNotifications).go();
  }

  // ── Reads ────────────────────────────────────────────────────

  /// Inbox query — newest-first, dismissed rows excluded.
  Future<List<domain.AppNotification>> getInbox() async {
    final rows = await (select(cachedNotifications)
          ..where((r) => r.dismissed.equals(false))
          ..orderBy([(r) => OrderingTerm.desc(r.receivedAt)]))
        .get();
    return rows.map(_fromRow).toList(growable: false);
  }

  /// Reactive inbox — emits a fresh snapshot whenever any
  /// `cached_notifications` row changes (insert / update / delete).
  /// Drives the inbox bloc and the AppBar's unread-count badge.
  Stream<List<domain.AppNotification>> watchInbox() {
    final query = select(cachedNotifications)
      ..where((r) => r.dismissed.equals(false))
      ..orderBy([(r) => OrderingTerm.desc(r.receivedAt)]);
    return query.watch().map(
          (rows) => rows.map(_fromRow).toList(growable: false),
        );
  }

  /// Cheap unread-count query — uses `COUNT(*)` server-side rather
  /// than materialising rows. The watch variant feeds the AppBar
  /// badge without the inbox having to be open.
  Stream<int> watchUnreadCount() {
    final count = countAll();
    final query = selectOnly(cachedNotifications)
      ..addColumns([count])
      ..where(cachedNotifications.readAt.isNull() &
          cachedNotifications.dismissed.equals(false));
    return query.map((row) => row.read(count) ?? 0).watchSingle();
  }

  // ── Mapping ──────────────────────────────────────────────────

  static CachedNotificationsCompanion _toCompanion(
    domain.AppNotification n,
  ) {
    return CachedNotificationsCompanion(
      id: Value(n.id),
      title: Value(n.title),
      body: Value(n.body),
      category: Value(n.category),
      routeName: Value(n.routeName),
      routeParamsJson: Value(
        n.pathParameters.isEmpty ? null : jsonEncode(n.pathParameters),
      ),
      receivedAt: Value(n.receivedAt),
      readAt: Value(n.readAt),
      dismissed: Value(n.dismissed),
    );
  }

  static domain.AppNotification _fromRow(CachedNotificationRow r) {
    final params = r.routeParamsJson;
    return domain.AppNotification(
      id: r.id,
      title: r.title,
      body: r.body,
      category: r.category,
      routeName: r.routeName,
      pathParameters: params == null
          ? const <String, String>{}
          : Map<String, String>.from(
              jsonDecode(params) as Map<String, dynamic>,
            ),
      receivedAt: r.receivedAt,
      readAt: r.readAt,
      dismissed: r.dismissed,
    );
  }
}
