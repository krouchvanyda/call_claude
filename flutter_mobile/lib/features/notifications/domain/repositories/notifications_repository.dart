import '../entities/notification.dart';

/// Domain contract for the notification inbox (Slice 2.3.1).
///
/// **Source-of-truth split**: drift is the local cache of record; the
/// remote (push / pull) sources land in Slice 2.3.2 and write *through*
/// the repository so the bloc keeps watching one stream regardless of
/// where the row originated.
///
/// **Why a single watch stream, not separate watch + getCount**: the
/// bloc derives the unread count from the inbox snapshot — keeping the
/// two as one query avoids the inbox view and the AppBar badge ever
/// disagreeing during a transient race.
abstract class NotificationsRepository {
  /// Reactive inbox — emits a fresh list on every insert / update /
  /// dismiss / mark-read. Newest-first; dismissed rows are excluded.
  Stream<List<AppNotification>> watchInbox();

  /// One-shot snapshot of the same query [watchInbox] streams.
  Future<List<AppNotification>> getInbox();

  /// Reactive unread count. Backed by a `COUNT(*)` query so the AppBar
  /// badge doesn't pay the cost of materialising the inbox just to
  /// know "is there a number to show".
  Stream<int> watchUnreadCount();

  /// Insert or replace a notification. The push handler (2.3.2) calls
  /// this when a new payload arrives.
  Future<void> upsert(AppNotification notification);

  /// Mark a single notification as read.
  Future<void> markRead(String id);

  /// Mark every unread, non-dismissed notification as read.
  Future<void> markAllRead();

  /// Tombstone a single notification — flips `dismissed` to true,
  /// keeping the row for a possible undo / restore flow.
  Future<void> dismiss(String id);

  /// Hard-delete every row — sign-out / cache-wipe path.
  Future<void> wipeAll();
}
