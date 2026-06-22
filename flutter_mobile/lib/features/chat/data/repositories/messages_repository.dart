import 'dart:async';

import '../../entities/chat_message.dart';
import '../chat_dto_mappers.dart';
import '../chat_transport.dart';
import '../chats_remote_data_source.dart';
import '../users_cache.dart';

/// Slice 10.1.2 / 10.1.4 — message store per conversation.
///
/// In-memory cache populated entirely from REST + STOMP — no demo
/// seed. Once [setRemote] has been called by `bootChatTransport`,
/// [loadForConversation] backfills real history from
/// `GET /chats/conversations/{id}/messages` and asks the transport to
/// subscribe to that conversation's `/topic/conversations/{id}` STOMP
/// destination so subsequent live messages flow in via the normal
/// inbound listener.
class MessagesRepository {
  MessagesRepository() {
    // When UsersCache fills in late (e.g. the picker opened AFTER
    // history was loaded), re-resolve every cached message's senderName
    // in place and re-emit so bubble labels refresh from raw ids to
    // real fullNames. The repo is a process-life singleton, so we
    // don't bother holding the subscription.
    UsersCache.instance.changes.listen((_) => _reresolveSenderNames());
  }

  // Starts empty — `loadForConversation(convId)` populates from
  // `GET /chats/conversations/{id}/messages` when the user opens a
  // chat. Inbound STOMP frames append. The old demo seed is gone.
  static final List<ChatMessage> _seed = <ChatMessage>[];

  final StreamController<List<ChatMessage>> _changes =
      StreamController<List<ChatMessage>>.broadcast();

  /// Patch any cached message whose [senderName] doesn't match what
  /// the cache now resolves for its [senderId]. No-op if nothing
  /// changes (keeps demo seed messages with their original names).
  void _reresolveSenderNames() {
    var anyChanged = false;
    for (var i = 0; i < _seed.length; i++) {
      final m = _seed[i];
      final cached = UsersCache.instance.nameOf(m.senderId);
      if (cached == null || cached == m.senderName) continue;
      final cachedAvatar = UsersCache.instance.avatarOf(m.senderId);
      _seed[i] = m.copyWith(
        senderName: cached,
        senderAvatarUrl: cachedAvatar ?? m.senderAvatarUrl,
      );
      anyChanged = true;
    }
    if (anyChanged) _emit();
  }

  /// Optional wire transport — when bound, [send] / [edit] / [softDelete]
  /// / [toggleReaction] publish their mutations to peers. Inbound peer
  /// events are routed via [applyInbound] which mutates local state
  /// without re-broadcasting (would cause an infinite loop).
  ChatTransport? _transport;

  void attachTransport(ChatTransport transport) {
    _transport = transport;
  }

  /// Real-backend data source for history backfill. Bound by
  /// `bootChatTransport`. Null = pre-Prompt-3 demo mode.
  ChatsRemoteDataSource? _remote;

  /// Conversation ids we've already backfilled this session, so the
  /// page can call [loadForConversation] from initState without us
  /// re-fetching every time the user revisits.
  final Set<String> _hydratedConversations = <String>{};

  void setRemote(ChatsRemoteDataSource remote) {
    _remote = remote;
  }

  /// Prompt 3 — pull message history for [conversationId] from the
  /// backend, merge into the local cache (de-duped by id), and ask
  /// the transport to subscribe to live updates for that conv.
  ///
  /// Safe to call multiple times per id — second + later calls are
  /// no-ops thanks to [_hydratedConversations]. Pass `force: true`
  /// to bypass the guard (e.g. pull-to-refresh).
  Future<void> loadForConversation(
    String conversationId, {
    int page = 1,
    int pageSize = 30,
    bool force = false,
  }) async {
    if (conversationId.isEmpty) return;
    _transport?.subscribeConversation(conversationId);
    final remote = _remote;
    if (remote == null) return;
    if (!force && _hydratedConversations.contains(conversationId)) return;
    final asInt = int.tryParse(conversationId);
    if (asInt == null) return; // seed convs (`conv-001`) — skip silently
    try {
      final body = await remote.listMessages(
        asInt,
        page: page,
        pageSize: pageSize,
      );
      final items = body['items'];
      if (items is! List) return;
      final knownIds = {for (final m in _seed) m.id};
      for (final raw in items) {
        if (raw is! Map<String, dynamic>) continue;
        final mapped = messageFromDto(raw);
        if (knownIds.contains(mapped.id)) continue;
        _seed.add(mapped);
        knownIds.add(mapped.id);
      }
      _hydratedConversations.add(conversationId);
      _emit();
    } catch (_) {
      // Same swallow rule as ConversationsRepository.loadInbox — keep
      // whatever cache we had; a retry next time the page opens.
    }
  }

  /// Called by the transport-listener bridge when an inbound event lands.
  /// Mutates local state WITHOUT publishing back — peers already know.
  Future<void> applyInbound(ChatTransportEvent event) async {
    switch (event) {
      case MessageReceivedEvent(message: final m):
        // De-dup 1: by id — covers anything we've already inserted
        // (e.g. a slow peer delivering twice, or a previously-swapped
        // optimistic local now carrying the backend id).
        if (_seed.any((existing) => existing.id == m.id)) return;

        // De-dup 2: own-echo of an optimistic send. When the user
        // sends a message, `send()` inserts a local copy with a
        // client-generated id like `msg-2-1762345678`. The backend
        // persists it under a real numeric id and then broadcasts to
        // `/topic/conversations/{id}` — including back to us, the
        // sender. The echo has a different id, so dedup-by-id above
        // misses it.
        //
        // Backend doesn't carry a clientToken, so match by
        // (senderId + body + type + ~5s window). Only consider
        // UNSWAPPED locals (id doesn't parse as int) so a real second
        // message with the same body sent later isn't lost.
        const echoWindow = Duration(seconds: 5);
        final echoIdx = _seed.indexWhere((existing) =>
            int.tryParse(existing.id) == null && // optimistic only
            existing.senderId == m.senderId &&
            existing.type == m.type &&
            existing.body == m.body &&
            m.sentAt.difference(existing.sentAt).abs() < echoWindow);
        if (echoIdx != -1) {
          // Replace the optimistic copy with the canonical one so the
          // real id, deliveredAt, etc. are in place for future dedup.
          _seed[echoIdx] = m;
          _emit();
          return;
        }

        _seed.add(m);
        _emit();
      case MessageEditedEvent(messageId: final id, newBody: final body):
        await _mutate(
          id,
          (m) => m.copyWith(body: body, editedAt: DateTime.now()),
          publish: false,
        );
      case MessageDeletedEvent(messageId: final id):
        await _mutate(
          id,
          (m) => m.copyWith(
            isDeleted: true,
            body: 'Message deleted',
            reactions: const [],
          ),
          publish: false,
        );
      case ReactionToggledEvent(
          messageId: final id,
          emoji: final emoji,
          employeeId: final empId
        ):
        await _toggleReactionLocal(id, emoji, empId);
      case MessageReadEvent(
          conversationId: final convId,
          userId: final readerId,
          lastReadMessageId: final lastReadStr,
        ):
        // Peer (or our other device) bumped their read cursor. Walk
        // every cached message in that conv with id <= lastRead and
        // add the reader to its `readByUserIds` set. The chat
        // bubble's read-tick re-renders via the watch stream.
        final lastRead = int.tryParse(lastReadStr);
        if (lastRead == null) return; // seed-era non-numeric id
        var changed = false;
        for (var i = 0; i < _seed.length; i++) {
          final m = _seed[i];
          if (m.conversationId != convId) continue;
          if (m.senderId == readerId) continue; // own sender doesn't "read" own msg
          final mid = int.tryParse(m.id);
          if (mid == null || mid > lastRead) continue;
          if (m.readByUserIds.contains(readerId)) continue;
          _seed[i] = m.copyWith(
            readByUserIds: <String>{...m.readByUserIds, readerId},
          );
          changed = true;
        }
        if (changed) _emit();
      // Call signalling envelopes are routed through
      // CallSignalingService; the messages repo ignores them.
      case CallInviteEvent():
      case CallAcceptEvent():
      case CallRejectEvent():
      case CallHangupEvent():
      // Group-creation + rename + user-profile + avatar + remove
      // envelopes are routed through bootChatTransport into
      // ConversationsRepository; nothing for the messages repo.
      case ConversationCreatedEvent():
      case ConversationUpdatedEvent():
      case ProfileUpdatedEvent():
      case ConversationAvatarUpdatedEvent():
      case ConversationRemovedEvent():
      // Presence envelopes are routed through PresenceRepository;
      // the messages repo doesn't care about online/busy/offline.
      case PresenceUpdatedEvent():
        break;
    }
  }

  Future<List<ChatMessage>> getForConversation(String conversationId) async {
    final out = _seed.where((m) => m.conversationId == conversationId).toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return List.unmodifiable(out);
  }

  Stream<List<ChatMessage>> watchForConversation(String conversationId) async* {
    yield await getForConversation(conversationId);
    yield* _changes.stream.map((all) {
      final out = all.where((m) => m.conversationId == conversationId).toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      return List<ChatMessage>.unmodifiable(out);
    });
  }

  Future<List<ChatMessage>> getAll() async => List.unmodifiable(_seed);

  /// Slice 10.1.4 — naive in-memory full-text search. Real impl uses
  /// SQLite FTS5; the query surface here matches what we'd swap in.
  Future<List<ChatMessage>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <ChatMessage>[];
    final out = <ChatMessage>[];
    for (final m in _seed) {
      if (m.isDeleted) continue;
      if (m.type == ChatMessageType.text && (m.body ?? '').toLowerCase().contains(q)) {
        out.add(m);
      } else if (m.type == ChatMessageType.file && (m.fileName ?? '').toLowerCase().contains(q)) {
        out.add(m);
      } else if (m.type == ChatMessageType.image && (m.fileName ?? '').toLowerCase().contains(q)) {
        out.add(m);
      }
    }
    out.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return List.unmodifiable(out);
  }

  /// GET /chats/conversations/{id}/messages/search?q= — server-side
  /// case-insensitive substring search scoped to one conversation.
  /// Falls back to the in-memory [search] when there's no transport
  /// or the conv id isn't numeric (seed demo). Empty query returns
  /// nothing rather than the whole history.
  Future<List<ChatMessage>> searchInConversation(
    String conversationId,
    String query, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const <ChatMessage>[];
    final remote = _remote;
    final convN = int.tryParse(conversationId);
    if (remote == null || convN == null) {
      // Demo / seed conv — filter locally to this conv id.
      final all = await search(q);
      return all.where((m) => m.conversationId == conversationId).toList();
    }
    try {
      final body = await remote.searchMessages(
        convN,
        q,
        page: page,
        pageSize: pageSize,
      );
      final items = body['items'];
      if (items is! List) return const <ChatMessage>[];
      final out = <ChatMessage>[];
      for (final raw in items) {
        if (raw is Map<String, dynamic>) {
          out.add(messageFromDto(raw));
        }
      }
      return out;
    } catch (_) {
      return const <ChatMessage>[];
    }
  }

  Future<ChatMessage?> findById(String id) async {
    for (final m in _seed) {
      if (m.id == id) return m;
    }
    return null;
  }

  Future<ChatMessage> send(
    ChatMessage draft, {
    List<String> targetIds = const <String>[],
  }) async {
    // Embed the sender id in the message id so two peers can't collide
    // on `msg-<microsec>` even if their clocks land in the same tick.
    final tempId = draft.id.isEmpty
        ? 'msg-${draft.senderId}-${DateTime.now().microsecondsSinceEpoch}'
        : draft.id;
    final stamped = draft.copyWith(
      id: tempId,
      deliveredAt: DateTime.now(),
    );
    _seed.add(stamped);
    _emit();

    // POST to backend and wait for the canonical id so we can swap
    // the optimistic local's id BEFORE the STOMP echo arrives. Once
    // swapped, `applyInbound`'s dedup-by-id catches every echo via
    // both `/topic/conversations/{id}` and `/user/queue/inbox`.
    //
    // Without this swap the user sees up to 3 copies of their own
    // message: 1 optimistic + 1 echo from /topic + 1 echo from
    // /user/queue/inbox — because the optimistic id (`msg-…`) never
    // matches the backend id and the (sender+body+time) heuristic in
    // `applyInbound` only catches the first echo at best.
    final canonicalId =
        await _transport?.sendMessage(stamped, targetIds: targetIds);
    if (canonicalId != null && canonicalId.isNotEmpty) {
      final idx = _seed.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        // Belt-and-braces: if a STOMP echo beat us here and inserted
        // a row with `canonicalId` already, drop the optimistic copy
        // instead of swapping (which would create the dup we're
        // trying to prevent).
        final alreadyExists = _seed.any((m) => m.id == canonicalId);
        if (alreadyExists) {
          _seed.removeAt(idx);
        } else {
          _seed[idx] = _seed[idx].copyWith(id: canonicalId);
        }
        _emit();
      }
    }
    return stamped;
  }

  Future<ChatMessage> edit(String id, String newBody) async {
    final next = await _mutate(
      id,
      (m) => m.copyWith(body: newBody, editedAt: DateTime.now()),
      publish: false,
    );
    _transport?.sendEdit(id, newBody);
    return next;
  }

  Future<ChatMessage> softDelete(String id) async {
    final next = await _mutate(
      id,
      (m) => m.copyWith(
        isDeleted: true,
        body: 'Message deleted',
        reactions: const [],
      ),
      publish: false,
    );
    _transport?.sendDelete(id);
    return next;
  }

  Future<ChatMessage> toggleReaction({
    required String messageId,
    required String emoji,
    required String employeeId,
  }) async {
    final next = await _toggleReactionLocal(messageId, emoji, employeeId);
    _transport?.sendReaction(
      messageId: messageId,
      emoji: emoji,
      employeeId: employeeId,
    );
    return next;
  }

  Future<ChatMessage> _toggleReactionLocal(
    String messageId,
    String emoji,
    String employeeId,
  ) {
    return _mutate(
      messageId,
      (m) {
        final next = m.reactions
            .map((r) => r.copyWith(employeeIds: List.of(r.employeeIds)))
            .toList();
        final idx = next.indexWhere((r) => r.emoji == emoji);
        if (idx == -1) {
          next.add(ChatReaction(emoji: emoji, employeeIds: [employeeId]));
        } else {
          final ids = next[idx].employeeIds;
          if (ids.contains(employeeId)) {
            ids.remove(employeeId);
            if (ids.isEmpty) {
              next.removeAt(idx);
            } else {
              next[idx] = next[idx].copyWith(employeeIds: ids);
            }
          } else {
            ids.add(employeeId);
            next[idx] = next[idx].copyWith(employeeIds: ids);
          }
        }
        return m.copyWith(reactions: next);
      },
      publish: false,
    );
  }

  Future<ChatMessage> setPinned(String id, bool pinned) async {
    return _mutate(id, (m) => m.copyWith(isPinned: pinned), publish: false);
  }

  Future<ChatMessage> _mutate(
    String id,
    ChatMessage Function(ChatMessage) f, {
    bool publish = false,
  }) async {
    final idx = _seed.indexWhere((m) => m.id == id);
    if (idx == -1) {
      throw StateError('Message $id not found');
    }
    final next = f(_seed[idx]);
    _seed[idx] = next;
    _emit();
    // `publish` is currently a no-op (each caller decides which wire
    // event to send, since mutations aren't 1:1 with wire messages).
    // The flag is kept on the signature so future callers can opt in
    // without rewiring every callsite.
    if (publish) {
      // intentionally empty — callers do their own _transport?.sendX()
    }
    return next;
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_seed));
  }
}
