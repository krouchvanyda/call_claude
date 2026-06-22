import 'dart:async';

import 'package:dio/dio.dart';

import '../../entities/conversation.dart';
import '../chat_dto_mappers.dart';
import '../chats_remote_data_source.dart';
import '../users_cache.dart';

/// Slice 10.1.1 / 10.1.3 / 10.3.1 — conversations store.
///
/// Backed by an in-memory cache populated entirely from REST +
/// STOMP — no more demo seed. Once [setRemote] has been called by
/// `bootChatTransport`, [loadInbox] replaces that seed with real
/// `GET /api/v1/chats/conversations` rows mapped via
/// [conversationFromDto]. The seed remains as a fallback so the demo
/// keeps running if the backend isn't reachable.
///
/// Exposes a `watchAll` stream, per-id lookup, and the
/// mute / delete / pin / rename / avatar mutations the inbox + info
/// pages need.
class ConversationsRepository {
  ConversationsRepository() {
    // When UsersCache fills in late (e.g. the picker opened AFTER the
    // inbox already rendered with raw ids), re-resolve every cached
    // conversation's participant names + last-sender name in place and
    // re-emit so the inbox tiles refresh. The repo is a process-life
    // singleton, so we don't bother holding the subscription.
    UsersCache.instance.changes.listen((_) => _reresolveNames());
  }

  // Starts empty — `loadInbox()` populates from
  // `GET /chats/conversations` at boot and after every reconnect.
  // Backend is the source of truth; no local seed.
  static final List<ChatConversation> _seed = <ChatConversation>[];

  final StreamController<List<ChatConversation>> _changes =
      StreamController<List<ChatConversation>>.broadcast();

  /// Walk the in-memory list and patch any name fields that the
  /// [UsersCache] can now resolve. No-op if nothing changes.
  void _reresolveNames() {
    var anyChanged = false;
    for (var i = 0; i < _seed.length; i++) {
      final c = _seed[i];

      // Patch each participant preview if a fresher name is cached.
      var previewsChanged = false;
      final nextPreviews = <ChatParticipantPreview>[];
      for (final p in c.participantPreviews) {
        final cachedName = UsersCache.instance.nameOf(p.employeeId);
        if (cachedName != null && cachedName != p.name) {
          nextPreviews.add(ChatParticipantPreview(
            employeeId: p.employeeId,
            name: cachedName,
            avatarUrl:
                UsersCache.instance.avatarOf(p.employeeId) ?? p.avatarUrl,
            presence: p.presence,
          ));
          previewsChanged = true;
        } else {
          nextPreviews.add(p);
        }
      }

      // Direct conversations show the OTHER participant's name as the
      // conversation title — keep that in sync with the cache.
      String? nextName;
      if (!c.isGroup && nextPreviews.isNotEmpty) {
        final cached = UsersCache.instance.nameOf(nextPreviews.first.employeeId);
        if (cached != null && cached != c.name) nextName = cached;
      }

      // Last-message sender name for the inbox preview row.
      String? nextLastSenderName;
      if (c.lastMessageSenderId != null) {
        final cached = UsersCache.instance.nameOf(c.lastMessageSenderId!);
        if (cached != null && cached != c.lastMessageSenderName) {
          nextLastSenderName = cached;
        }
      }

      if (previewsChanged || nextName != null || nextLastSenderName != null) {
        _seed[i] = c.copyWith(
          name: nextName ?? c.name,
          participantPreviews: previewsChanged ? nextPreviews : null,
          lastMessageSenderName:
              nextLastSenderName ?? c.lastMessageSenderName,
        );
        anyChanged = true;
      }
    }
    if (anyChanged) _emit();
  }

  /// Real-backend data source. Bound by `bootChatTransport` once
  /// settings are loaded so we know which user id to compute display
  /// names against. Null = pre-Prompt-2 demo mode.
  ChatsRemoteDataSource? _remote;
  String? _currentUserId;

  void setRemote(
    ChatsRemoteDataSource remote, {
    required String currentUserId,
  }) {
    _remote = remote;
    _currentUserId = currentUserId;
  }

  /// Prompt 2 — pull the inbox from `GET /chats/conversations` and
  /// replace the in-memory cache with the result.
  ///
  /// Each row goes through [conversationFromDto] so the page layer
  /// keeps reading the same [ChatConversation] shape it always has —
  /// no widget changes needed. The response envelope from
  /// `ChatsRemoteDataSource.listConversations` is the unwrapped `data`
  /// payload: `{items: [...], page, pageSize, total}`.
  ///
  /// No-op when [setRemote] hasn't been called yet (demo mode).
  /// Errors are swallowed so a flaky backend doesn't take the UI down
  /// — the seed stays in place and the next call retries.
  Future<void> loadInbox({int page = 1, int pageSize = 50}) async {
    final remote = _remote;
    final userId = _currentUserId;
    if (remote == null || userId == null) return;
    try {
      final body = await remote.listConversations(page: page, pageSize: pageSize);
      final items = body['items'];
      if (items is! List) return;
      final next = <ChatConversation>[];
      for (final raw in items) {
        if (raw is Map<String, dynamic>) {
          next.add(conversationFromDto(raw, currentUserId: userId));
        }
      }
      _seed
        ..clear()
        ..addAll(next);
      await _emit();
    } catch (_) {
      // Backend down or auth not ready — keep whatever cache we had.
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Section 7 ops 2 / 5 / 6 / 7 / 8 / 9 — REST-backed wrappers.
  //
  // Each helper POSTs/PATCHes/DELETEs to the backend, then updates
  // the local cache from the returned ConversationDto so the inbox
  // reflects the new state without waiting for the STOMP fan-out
  // (which still arrives a fraction of a second later and is
  // idempotent — `_upsert` is by id).
  //
  // All take backend-style ids (numeric strings like "5"). Seed
  // conv ids like "conv-001" short-circuit silently — they're demo
  // rows that don't exist on the backend.
  // ──────────────────────────────────────────────────────────────

  /// Op #2 — GET /chats/conversations/{id}. Re-fetches a single
  /// conversation and upserts it into the cache. Use after a known
  /// mutation that the local response doesn't already cover.
  Future<void> refreshOne(String id) async {
    final remote = _remote;
    final userId = _currentUserId;
    if (remote == null || userId == null) return;
    final n = int.tryParse(id);
    if (n == null) return;
    try {
      final dto = await remote.getConversation(n);
      _upsert(conversationFromDto(dto, currentUserId: userId));
    } catch (_) {/* swallow */}
  }

  /// Op #5 — PATCH /chats/conversations/{id} { name }. Admin-only on
  /// the backend (server returns 403 otherwise).
  Future<void> renameRemote(String id, String name) async {
    final remote = _remote;
    final userId = _currentUserId;
    if (remote == null || userId == null) return;
    final n = int.tryParse(id);
    if (n == null) {
      // Seed conv — keep the local-only behaviour for demo continuity.
      await rename(id, name);
      return;
    }
    final dto = await remote.updateConversation(n, name: name);
    _upsert(conversationFromDto(dto, currentUserId: userId));
  }

  /// Op #5 (avatar URL) — PATCH /chats/conversations/{id} { avatarUrl }.
  /// The backend stores the URL as-is; binary upload is a separate
  /// endpoint (out of scope here). Pass an empty string to clear.
  Future<void> setAvatarUrlRemote(String id, String url) async {
    final remote = _remote;
    final userId = _currentUserId;
    if (remote == null || userId == null) return;
    final n = int.tryParse(id);
    if (n == null) return;
    final dto = await remote.updateConversation(n, avatarUrl: url);
    _upsert(conversationFromDto(dto, currentUserId: userId));
  }

  /// Op #6 — POST /chats/conversations/{id}/members { memberIds }.
  /// Admin-only. Backend fans `conversation.update` to every
  /// member's `/user/queue/inbox`, so peers update via STOMP — we
  /// also refresh locally so the actor sees the new state on the
  /// next frame.
  Future<void> addMembersRemote(String id, Set<int> memberIds) async {
    final remote = _remote;
    if (remote == null) return;
    final n = int.tryParse(id);
    if (n == null) return;
    if (memberIds.isEmpty) return;
    await remote.addMembers(n, memberIds);
    await refreshOne(id);
  }

  /// Op #7 — DELETE /chats/conversations/{id}/members/{userId}.
  /// Admin-only when removing someone else; member-self when leaving
  /// (op #8 uses the same endpoint with the caller's id).
  Future<void> removeMemberRemote(String id, int userId) async {
    final remote = _remote;
    if (remote == null) return;
    final n = int.tryParse(id);
    if (n == null) return;
    await remote.removeMember(n, userId);
    await refreshOne(id);
  }

  /// Op #8 — Leaving a group: caller deletes themselves from the
  /// member list. After success the conv is removed locally because
  /// we're no longer a member of it.
  Future<void> leaveGroupRemote(String id) async {
    final remote = _remote;
    final userId = _currentUserId;
    if (remote == null || userId == null) return;
    final n = int.tryParse(id);
    final selfId = int.tryParse(userId);
    if (n == null || selfId == null) return;
    await remote.removeMember(n, selfId);
    // Drop the conv from the local cache — `refreshOne` would 403
    // (we're no longer a member) so just delete locally.
    _seed.removeWhere((c) => c.id == id);
    await _emit();
  }

  /// DELETE /chats/conversations/{id} — backend enforces auth (group
  /// → admin only; direct → either party). On success we also clear
  /// the local row so the inbox tile vanishes without waiting for
  /// the STOMP `conversation.remove` echo.
  ///
  /// **Non-admin fallback for groups:** if the user swipes a group
  /// they don't own, the backend returns 403. From the user's POV
  /// "remove this chat from my inbox" is the same intent whether
  /// they're an admin (real delete for everyone) or a member (leave
  /// the group, conv stays for the rest). So a 403 on a group falls
  /// through to [leaveGroupRemote]. Direct convs bubble the 403 up
  /// because that case isn't supposed to happen and the caller
  /// should know.
  Future<void> deleteRemote(String id) async {
    final remote = _remote;
    if (remote == null) {
      // Seed/demo mode — keep legacy local-only behaviour.
      await delete(id);
      return;
    }
    final n = int.tryParse(id);
    if (n == null) {
      await delete(id);
      return;
    }
    try {
      await remote.deleteConversation(n);
      _seed.removeWhere((c) => c.id == id);
      await _emit();
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) {
        final existing = await findById(id);
        if (existing != null && existing.isGroup) {
          await leaveGroupRemote(id);
          return;
        }
      }
      rethrow;
    }
  }

  /// Op #9 — POST /chats/conversations/{id}/read { lastReadMessageId }.
  /// Server clears unread, returns the updated ConversationDto, and
  /// fans `conversation.update` to other sessions of the same user.
  Future<void> markReadRemote(String id, int lastReadMessageId) async {
    final remote = _remote;
    final userId = _currentUserId;
    if (remote == null || userId == null) return;
    final n = int.tryParse(id);
    if (n == null) {
      // Seed conv — local-only clear.
      try {
        await markRead(id);
      } catch (_) {}
      return;
    }
    try {
      final dto = await remote.markRead(n, lastReadMessageId);
      _upsert(conversationFromDto(dto, currentUserId: userId));
    } catch (_) {/* swallow — next loadInbox will reconcile */}
  }

  /// Inbound `message.read` (from `/topic/conversations/{id}`) →
  /// bump the matching member's [ChatParticipantPreview.lastReadMessageId]
  /// in place. Pairs with the message-side patch in
  /// `MessagesRepository.applyInbound` (which adds the reader to
  /// each msg's `readByUserIds`) — together they keep the read
  /// cursor consistent across both data axes.
  ///
  /// No-op when the conv isn't in our cache, the reader isn't a
  /// known member, or the new id isn't actually higher than what we
  /// already have.
  void applyInboundRead({
    required String conversationId,
    required String userId,
    required String lastReadMessageId,
  }) {
    final idx = _seed.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;
    final c = _seed[idx];
    final memberIdx =
        c.participantPreviews.indexWhere((p) => p.employeeId == userId);
    if (memberIdx == -1) return;
    final current = c.participantPreviews[memberIdx];
    // Only bump forward — protects against out-of-order delivery
    // (older read frame arrives after a newer one).
    final newId = int.tryParse(lastReadMessageId);
    final oldId = int.tryParse(current.lastReadMessageId ?? '');
    if (newId != null && oldId != null && newId <= oldId) return;
    final nextPreviews =
        List<ChatParticipantPreview>.of(c.participantPreviews);
    nextPreviews[memberIdx] =
        current.copyWith(lastReadMessageId: lastReadMessageId);
    _seed[idx] = c.copyWith(participantPreviews: nextPreviews);
    _emit();
  }

  /// Insert-or-replace by id, then re-emit. Used by the REST
  /// wrappers above to keep the local cache in sync without
  /// rebuilding the whole inbox.
  void _upsert(ChatConversation c) {
    final idx = _seed.indexWhere((existing) => existing.id == c.id);
    if (idx == -1) {
      _seed.insert(0, c);
    } else {
      _seed[idx] = c;
    }
    _emit();
  }

  Future<List<ChatConversation>> getAll() async {
    final out = List<ChatConversation>.of(_seed)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List.unmodifiable(out);
  }

  Stream<List<ChatConversation>> watchAll() async* {
    yield await getAll();
    yield* _changes.stream;
  }

  Future<ChatConversation?> findById(String id) async {
    for (final c in _seed) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Slice 10.1.8 — return the local direct conversation whose other
  /// participant is [employeeId], or null if no such conv exists.
  ///
  /// Used by `bootChatTransport` to redirect inbound direct messages
  /// to the right local conv on the receiver's device. Without this,
  /// a message Vibol sends in HIS conv-005 ("Pisey direct" on Vibol's
  /// seed) would land in Pisey's conv-005 — which is *her* own
  /// self-direct seed slot, not her chat with Vibol. By looking up
  /// "my direct conv whose other participant is `senderId`" we land
  /// the message in Pisey's conv-003 ("Vibol Sok") instead.
  Future<ChatConversation?> findDirectWith(String employeeId) async {
    for (final c in _seed) {
      if (c.isGroup) continue;
      for (final p in c.participantPreviews) {
        if (p.employeeId == employeeId) return c;
      }
    }
    return null;
  }

  Stream<ChatConversation?> watchById(String id) async* {
    yield await findById(id);
    yield* _changes.stream.map((all) {
      for (final c in all) {
        if (c.id == id) return c;
      }
      return null;
    });
  }

  Future<ChatConversation> setMuted(String id, bool muted) async {
    return _mutate(id, (c) => c.copyWith(isMuted: muted));
  }

  Future<void> delete(String id) async {
    _seed.removeWhere((c) => c.id == id);
    await _emit();
  }

  Future<ChatConversation> markRead(String id) async {
    return _mutate(id, (c) => c.copyWith(unreadCount: 0));
  }

  Future<ChatConversation> bumpUnread(String id) async {
    return _mutate(id, (c) => c.copyWith(unreadCount: c.unreadCount + 1));
  }

  /// Inbound message arrived from the WebSocket — refresh the
  /// last-message fields + timestamp so the inbox preview updates.
  Future<ChatConversation> updateLastMessage({
    required String id,
    required String body,
    required String senderId,
    required String senderName,
    required DateTime at,
    String type = 'text',
  }) async {
    return _mutate(
      id,
      (c) => c.copyWith(
        lastMessageBody: body,
        lastMessageSenderId: senderId,
        lastMessageSenderName: senderName,
        lastMessageAt: at,
        lastMessageType: type,
        updatedAt: at,
      ),
    );
  }

  Future<ChatConversation> rename(String id, String name) async {
    return _mutate(id, (c) => c.copyWith(name: name));
  }

  /// Slice 10.3.3 — admin set the group photo from a local file
  /// (typically the `image_picker` result). Pass `null` to clear.
  Future<ChatConversation> setAvatarPath(String id, String? path) async {
    return _mutate(
      id,
      (c) => c.copyWith(
        avatarFilePath: path,
        clearAvatarFilePath: path == null,
      ),
    );
  }

  /// Slice 10.3.2 — admin adds new members to an existing group.
  ///
  /// De-duplicates against current `participantPreviews` so re-adding
  /// someone is a no-op. Updates `totalMembers` + `onlineCount`
  /// accordingly so the AppBar subtitle stays in sync.
  Future<ChatConversation> addMembers({
    required String id,
    required List<ChatParticipantPreview> people,
  }) async {
    if (people.isEmpty) return (await findById(id))!;
    return _mutate(id, (c) {
      final existing = {for (final p in c.participantPreviews) p.employeeId};
      final additions =
          people.where((p) => !existing.contains(p.employeeId)).toList();
      if (additions.isEmpty) return c;
      final nextPreviews =
          List<ChatParticipantPreview>.of(c.participantPreviews)
            ..addAll(additions);
      final addedOnline = additions
          .where((p) => p.presence == PresenceStatus.online)
          .length;
      return c.copyWith(
        participantPreviews: nextPreviews,
        totalMembers: c.totalMembers + additions.length,
        onlineCount: c.onlineCount + addedOnline,
        updatedAt: DateTime.now(),
      );
    });
  }

  Future<ChatConversation> setPinnedMessage(String id, String? messageId) async {
    return _mutate(
      id,
      (c) => c.copyWith(
        pinnedMessageId: messageId,
        clearPinnedMessage: messageId == null,
      ),
    );
  }

  /// Slice 10.1.3 — insert a brand new conversation.
  Future<ChatConversation> create(ChatConversation draft) async {
    final id = draft.id.isEmpty
        ? 'conv-${DateTime.now().microsecondsSinceEpoch}'
        : draft.id;
    final stamped = draft.copyWith(id: id);
    _seed.insert(0, stamped);
    await _emit();
    return stamped;
  }

  Future<ChatConversation> _mutate(
    String id,
    ChatConversation Function(ChatConversation) f,
  ) async {
    final idx = _seed.indexWhere((c) => c.id == id);
    if (idx == -1) {
      throw StateError('Conversation $id not found');
    }
    final next = f(_seed[idx]);
    _seed[idx] = next;
    await _emit();
    return next;
  }

  Future<void> _emit() async {
    if (!_changes.isClosed) _changes.add(await getAll());
  }
}
