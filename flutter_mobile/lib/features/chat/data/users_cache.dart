import 'dart:async';

/// Tiny in-memory cache of backend users keyed by stringified user id.
///
/// Why this exists: Spring `ConversationDto.members[]` and
/// `MessageDto.senderId` carry only the numeric user id — they do NOT
/// include the user's display name. So when the chat module hydrates
/// a conversation from the backend, it has nothing to render in the
/// inbox tile / chat header / sender label except the raw id.
///
/// This cache is the small store the [chat_dto_mappers] layer
/// consults BEFORE falling back to a `User #<id>` placeholder. It's
/// populated wherever the app already has the name in hand:
///   - `/users` page (admin/staff users via the new-message picker)
///   - `/users/me` (every signed-in user, on app boot)
///
/// **Not persisted.** Lives for one app run; rebuilt on each cold
/// start. That's fine for now — most names are re-fetched in seconds.
/// Persisting to SQLite is a follow-up when we wire the chat module
/// to the database (Slice 10.x).
class UsersCache {
  UsersCache._();
  static final UsersCache instance = UsersCache._();

  final Map<String, _Brief> _byId = {};
  final StreamController<void> _changes =
      StreamController<void>.broadcast();

  /// Stream that fires every time the cache mutates, so the inbox /
  /// conversation pages can rebuild and pick up newly-resolved names.
  Stream<void> get changes => _changes.stream;

  /// Cache the display name + optional avatar for [userId].
  /// Idempotent: re-puts with the same value are no-ops (no event).
  void put({
    required String userId,
    required String name,
    String? avatarUrl,
  }) {
    final existing = _byId[userId];
    if (existing != null &&
        existing.name == name &&
        existing.avatarUrl == avatarUrl) {
      return;
    }
    _byId[userId] = _Brief(name: name, avatarUrl: avatarUrl);
    if (!_changes.isClosed) _changes.add(null);
  }

  /// Bulk-put — used by the new-message picker after a `/users` list
  /// fetch so the entire directory lands in the cache in one shot.
  void putAll(Iterable<({String id, String name, String? avatarUrl})> users) {
    var changed = false;
    for (final u in users) {
      final existing = _byId[u.id];
      if (existing != null &&
          existing.name == u.name &&
          existing.avatarUrl == u.avatarUrl) {
        continue;
      }
      _byId[u.id] = _Brief(name: u.name, avatarUrl: u.avatarUrl);
      changed = true;
    }
    if (changed && !_changes.isClosed) _changes.add(null);
  }

  /// Resolve display name for [userId], or null if unknown OR if
  /// the cached entry is empty/whitespace. Treat empty-string caches
  /// as a miss so mappers can keep falling through to a useful
  /// placeholder instead of rendering "?".
  String? nameOf(String userId) {
    final n = _byId[userId]?.name;
    if (n == null) return null;
    return n.trim().isEmpty ? null : n;
  }

  /// Resolve avatar URL for [userId], or null if unknown / not set.
  String? avatarOf(String userId) => _byId[userId]?.avatarUrl;
}

class _Brief {
  const _Brief({required this.name, this.avatarUrl});
  final String name;
  final String? avatarUrl;
}
