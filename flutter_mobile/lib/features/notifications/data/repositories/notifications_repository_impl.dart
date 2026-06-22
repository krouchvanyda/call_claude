import '../../domain/entities/notification.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_dao.dart';

/// Drift-backed [NotificationsRepository] (Slice 2.3.1).
///
/// Currently a thin pass-through to [NotificationsDao] — the indirection
/// earns its keep when Slice 2.3.2 plugs in the push / pull remote
/// sources, at which point this class fans writes through to both
/// drift and the network.
class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl({required NotificationsDao dao}) : _dao = dao;

  final NotificationsDao _dao;

  @override
  Stream<List<AppNotification>> watchInbox() => _dao.watchInbox();

  @override
  Future<List<AppNotification>> getInbox() => _dao.getInbox();

  @override
  Stream<int> watchUnreadCount() => _dao.watchUnreadCount();

  @override
  Future<void> upsert(AppNotification notification) =>
      _dao.upsert(notification);

  @override
  Future<void> markRead(String id) async {
    await _dao.markRead(id);
  }

  @override
  Future<void> markAllRead() async {
    await _dao.markAllRead();
  }

  @override
  Future<void> dismiss(String id) async {
    await _dao.dismiss(id);
  }

  @override
  Future<void> wipeAll() => _dao.wipeAll();
}
