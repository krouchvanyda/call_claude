import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/network/token_storage.dart';
import '../entities/call_log.dart';
import '../entities/chat_message.dart';
import 'chat_dto_mappers.dart';
import 'chats_remote_data_source.dart';
import 'users_cache.dart';

/// Connection status surfaced to the UI (banner / status dot).
enum ChatTransportStatus { disconnected, connecting, connected, error }

/// Inbound event the transport hands off to the repositories.
sealed class ChatTransportEvent {
  const ChatTransportEvent();
}

/// Peer sent a new message — add to local seed without re-broadcasting.
///
/// [targetIds] used to drive client-side routing in the relay era
/// (Slice 10.1.8). With the real backend, STOMP topics already route
/// by membership — every member of `/topic/conversations/{convId}`
/// gets the frame and no one else does. We still populate the field
/// (with the conversation member list when available) so the
/// existing `bootChatTransport` filter stays a no-op rather than a
/// regression risk.
class MessageReceivedEvent extends ChatTransportEvent {
  const MessageReceivedEvent(this.message, {this.targetIds = const <String>[]});
  final ChatMessage message;
  final List<String> targetIds;
}

/// Peer edited a message they previously sent.
class MessageEditedEvent extends ChatTransportEvent {
  const MessageEditedEvent({required this.messageId, required this.newBody});
  final String messageId;
  final String newBody;
}

/// Peer soft-deleted a message.
class MessageDeletedEvent extends ChatTransportEvent {
  const MessageDeletedEvent(this.messageId);
  final String messageId;
}

/// `message.read` — a member just told the server they've read up to
/// [lastReadMessageId] in [conversationId]. Server fans this out on
/// `/topic/conversations/{convId}` so other members can flip their
/// own outgoing bubbles to "read" ticks. Carries the reader's user
/// id (NOT the sender of the messages) so the repo can patch
/// `readByUserIds` on every cached message at or below that id.
class MessageReadEvent extends ChatTransportEvent {
  const MessageReadEvent({
    required this.conversationId,
    required this.userId,
    required this.lastReadMessageId,
  });
  final String conversationId;
  final String userId;
  final String lastReadMessageId;
}

/// `presence.update` — backend pushed a status change for [userId].
/// Carries the raw payload through to `PresenceRepository` which
/// builds the `Presence` model and fires its revision notifier.
class PresenceUpdatedEvent extends ChatTransportEvent {
  const PresenceUpdatedEvent(this.payload);
  final Map<String, dynamic> payload;
}

/// `conversation.remove` — fanned out on the removed user's
/// `/user/queue/inbox` when an admin kicks them OR when they leave
/// a group themselves. The receiver drops the conv from their
/// local cache so the inbox tile disappears.
class ConversationRemovedEvent extends ChatTransportEvent {
  const ConversationRemovedEvent(this.conversationId);
  final String conversationId;
}

/// Peer toggled a reaction on a message. Backend ships the full
/// reaction list per toggle, but the existing repo expects a single
/// `(emoji, employeeId)` pair — we synthesise one event per delta so
/// the repo math (add when missing, remove when present) still works.
class ReactionToggledEvent extends ChatTransportEvent {
  const ReactionToggledEvent({
    required this.messageId,
    required this.emoji,
    required this.employeeId,
  });
  final String messageId;
  final String emoji;
  final String employeeId;
}

/// Caller pressed Call → callee's overlay should show an incoming
/// call sheet. [targetIds] populated from the call's participant list
/// so legacy client-side filters keep working.
class CallInviteEvent extends ChatTransportEvent {
  const CallInviteEvent({
    required this.callId,
    required this.conversationId,
    required this.callerId,
    required this.callerName,
    required this.callType,
    required this.startedAt,
    this.targetIds = const <String>[],
    this.streamCallCid,
  });
  final String callId;
  final String conversationId;
  final String callerId;
  final String callerName;
  final ChatCallType callType;
  final DateTime startedAt;
  final List<String> targetIds;

  /// Stream Video call CID (e.g. `default:abc123`) — opaque to the
  /// signalling layer, fed straight into `StreamCallEngine.join(...)`.
  /// Null when the backend hasn't shipped Stream integration yet
  /// (legacy demo, or a backend that returns ChatCallDto without
  /// the field); callers then fall back to signalling-only mode.
  final String? streamCallCid;
}

class CallAcceptEvent extends ChatTransportEvent {
  const CallAcceptEvent({required this.callId, this.accepterId});
  final String callId;
  final String? accepterId;
}

class CallRejectEvent extends ChatTransportEvent {
  const CallRejectEvent({required this.callId, this.reason});
  final String callId;
  final String? reason;
}

class CallHangupEvent extends ChatTransportEvent {
  const CallHangupEvent({required this.callId, this.hangerUpperId});
  final String callId;
  final String? hangerUpperId;
}

class ConversationCreatedEvent extends ChatTransportEvent {
  const ConversationCreatedEvent({
    required this.conversationId,
    required this.name,
    required this.isGroup,
    required this.creatorId,
    required this.creatorName,
    required this.participantIds,
    required this.createdAt,
  });
  final String conversationId;
  final String name;
  final bool isGroup;
  final String creatorId;
  final String creatorName;
  final List<String> participantIds;
  final DateTime createdAt;
}

class ConversationUpdatedEvent extends ChatTransportEvent {
  const ConversationUpdatedEvent({
    required this.conversationId,
    required this.name,
    required this.participantIds,
  });
  final String conversationId;
  final String name;
  final List<String> participantIds;
}

class ProfileUpdatedEvent extends ChatTransportEvent {
  const ProfileUpdatedEvent({required this.userId, required this.newName});
  final String userId;
  final String newName;
}

class ConversationAvatarUpdatedEvent extends ChatTransportEvent {
  const ConversationAvatarUpdatedEvent({
    required this.conversationId,
    required this.participantIds,
    this.avatarBase64,
    this.fileExtension,
  });
  final String conversationId;
  final List<String> participantIds;

  /// Legacy relay carried raw bytes in this field. With the real
  /// backend the avatar lives at [ConversationAvatarUpdatedEvent.avatarUrl] —
  /// kept for back-compat with code that still reads `avatarBase64`.
  final String? avatarBase64;
  final String? fileExtension;
}

/// ────────────────────────────────────────────────────────────────────
/// ChatTransport — STOMP edition.
///
/// Public API kept byte-for-byte identical to the relay-era version
/// so repositories don't need to change (per Prompt 1 of
/// `CHAT_MODULE_BACKEND_INTEGRATIONGUIDE.md`).
///
/// **Internals replaced**:
///   - WS connection → `StompClient` against `<apiBaseUrl>/ws`
///   - Outbound `sendXxx(...)` → REST calls via [ChatsRemoteDataSource]
///   - Inbound `_onData(...)` → STOMP frame handlers per topic/queue
///     dispatching on the `ChatEvent.event` envelope name and parsing
///     the matching DTO from `ChatEvent.payload`
///
/// **STOMP destinations subscribed**:
///   - `/user/queue/inbox` — inbox preview + conversation events
///   - `/user/queue/calls` — incoming call invites
///   - `/topic/conversations/{id}` and `/topic/conversations/{id}/call` —
///     per active conversation, managed via
///     [subscribeConversation] / [unsubscribeConversation]
///
/// **Auth**: the CONNECT frame carries `Authorization: Bearer <access>`
/// from [TokenStorage]. A 401-style STOMP ERROR triggers a reconnect
/// chain that will pick up a refreshed token on the next attempt
/// (the dio-layer interceptor refreshes it under the hood when any
/// REST call hits 401 first).
/// ────────────────────────────────────────────────────────────────────
class ChatTransport {
  ChatTransport({
    required ChatsRemoteDataSource remote,
    required TokenStorage tokens,
  })  : _remote = remote,
        _tokens = tokens;

  // ── deps ─────────────────────────────────────────────────────
  final ChatsRemoteDataSource _remote;
  final TokenStorage _tokens;

  // ── current configuration ────────────────────────────────────
  // [_url] now holds an HTTP base URL like `http://10.0.2.2:8080`.
  // We append `/ws` for the STOMP socket. The previous relay
  // `ws://host:port` form is detected + adapted in [_buildStompUrl]
  // so a mid-migration device that still has the old URL in prefs
  // doesn't crash on launch.
  String _url = '';
  String _userId = '';
  String _userName = '';

  // ── connection state ─────────────────────────────────────────
  StompClient? _client;
  ChatTransportStatus _status = ChatTransportStatus.disconnected;
  bool _disposed = false;

  /// Active per-conv subscription handles, keyed by `convId#kind`
  /// where kind is `'msg'` or `'call'`. We don't expose the kind
  /// to callers — [subscribeConversation] adds both, and
  /// [unsubscribeConversation] removes both.
  final Map<String, StompUnsubscribe> _convSubs = <String, StompUnsubscribe>{};

  /// Conv ids we've been asked to subscribe to. Re-applied on
  /// reconnect so the page doesn't have to re-call after a network
  /// blip.
  final Set<String> _wantConvSubs = <String>{};

  /// Conv ids we want the CALL topic (`…/call`) for, independent of
  /// whether the chat page is open. Populated at boot from the inbox
  /// (see [subscribeCallTopics]) so an incoming `call.invite` broadcast
  /// on `/topic/conversations/{id}/call` lights up the in-app overlay on
  /// ANY screen — not just while the user is sitting on that
  /// conversation. Re-applied on reconnect like [_wantConvSubs].
  final Set<String> _wantCallSubs = <String>{};

  /// Message ids the backend has just confirmed for us — populated
  /// inside [sendMessage] from the POST response. When the matching
  /// `/topic/conversations/{id}` echo arrives we drop it before
  /// emitting a [MessageReceivedEvent], so the repo's optimistic
  /// row never gets visually duplicated.
  ///
  /// Entries auto-prune after 30 s to keep the set small — by then
  /// the echo has either arrived or been lost; either way we're done
  /// caring about this id.
  final Set<String> _ourRecentSends = <String>{};

  // Global subscriptions (inbox + calls). Cleared on disconnect.
  StompUnsubscribe? _inboxSub;
  StompUnsubscribe? _callsSub;
  StompUnsubscribe? _presenceSub;

  final StreamController<ChatTransportEvent> _events =
      StreamController<ChatTransportEvent>.broadcast();
  final StreamController<ChatTransportStatus> _statusEvents =
      StreamController<ChatTransportStatus>.broadcast();

  Stream<ChatTransportEvent> get events => _events.stream;
  Stream<ChatTransportStatus> get status async* {
    yield _status;
    yield* _statusEvents.stream;
  }

  ChatTransportStatus get currentStatus => _status;

  // ── lifecycle ────────────────────────────────────────────────

  /// Start (or restart) with a new URL + identity.
  Future<void> updateConfig({
    required String url,
    required String userId,
    required String userName,
  }) async {
    final urlChanged = url != _url;
    final identityChanged = userId != _userId || userName != _userName;
    _url = url;
    _userId = userId;
    _userName = userName;
    if (urlChanged || identityChanged) {
      await _close();
      unawaited(_maybeConnect());
    }
  }

  /// Initial start — alias for [updateConfig] kept for clarity at
  /// boot sites.
  Future<void> start({
    required String url,
    required String userId,
    required String userName,
  }) =>
      updateConfig(url: url, userId: userId, userName: userName);

  Future<void> dispose() async {
    _disposed = true;
    await _close();
    await _events.close();
    await _statusEvents.close();
  }

  Future<void> _maybeConnect() async {
    if (_disposed) return;
    if (_url.isEmpty) {
      _setStatus(ChatTransportStatus.disconnected);
      return;
    }
    final wsUrl = _buildStompUrl(_url);
    if (wsUrl == null) {
      _setStatus(ChatTransportStatus.error);
      return;
    }
    final accessToken = (await _tokens.read())?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      // No session yet — splash will eventually wake us via
      // updateConfig once the user signs in. Stay disconnected
      // rather than spinning on rejected CONNECT frames.
      _setStatus(ChatTransportStatus.disconnected);
      return;
    }
    _setStatus(ChatTransportStatus.connecting);

    final client = StompClient(
      config: StompConfig(
        url: wsUrl,
        // `Authorization` and `accept-version` go on the CONNECT frame.
        // Spring Security's STOMP interceptor reads the token from the
        // CONNECT headers (Spring Boot's WebSocket security samples).
        stompConnectHeaders: <String, String>{
          'Authorization': 'Bearer $accessToken',
        },
        webSocketConnectHeaders: <String, String>{
          'Authorization': 'Bearer $accessToken',
        },
        // stomp_dart_client handles backoff internally — capped at
        // 30s per Prompt 1.
        reconnectDelay: const Duration(seconds: 2),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),
        onConnect: _onStompConnect,
        onWebSocketError: (e) {
          if (kDebugMode) developer.log('chat: ws error → $e', name: 'chat');
          _setStatus(ChatTransportStatus.error);
        },
        onStompError: (frame) {
          if (kDebugMode) {
            developer.log('chat: STOMP error frame ${frame.body}',
                name: 'chat');
          }
          _setStatus(ChatTransportStatus.error);
        },
        onDisconnect: (_) => _setStatus(ChatTransportStatus.disconnected),
      ),
    );
    _client = client;
    client.activate();
  }

  void _onStompConnect(StompFrame _) {
    _setStatus(ChatTransportStatus.connected);

    // Inbox queue — conversation create / update + new-message
    // previews + read-state updates. Per-user queue: only we get
    // these, so no client-side targetIds filtering needed.
    _inboxSub = _client?.subscribe(
      destination: '/user/queue/inbox',
      callback: (frame) => _handleEnvelope(frame, source: 'inbox'),
    );

    // Calls queue — incoming `call.invite` for any conversation we're
    // a member of. The per-conv `/topic/.../call` subscription below
    // covers accept/reject/hangup during an active call.
    _callsSub = _client?.subscribe(
      destination: '/user/queue/calls',
      callback: (frame) => _handleEnvelope(frame, source: 'calls'),
    );

    // Global presence channel — every user's status change for the
    // whole org lands here. PresenceRepository de-dupes by user id
    // so the volume is bounded by user count, not message rate.
    _presenceSub = _client?.subscribe(
      destination: '/topic/presence',
      callback: (frame) => _handleEnvelope(frame, source: 'presence'),
    );

    // Re-apply any per-conv subscriptions requested before this
    // reconnect (page opened a chat, network blipped, etc.). Idempotent.
    for (final id in _wantConvSubs.toList()) {
      _attachConvSubs(id);
    }
    // Re-apply the boot-time call-topic subscriptions too so incoming
    // invites keep landing on any screen after a reconnect.
    for (final id in _wantCallSubs.toList()) {
      _attachCallSub(id);
    }
  }

  // ── conversation topic subscription management ──────────────
  //
  // The previous transport had a single LAN broadcast — no per-conv
  // routing. STOMP needs an explicit subscribe for each
  // `/topic/conversations/{id}` we want messages from. Pages call
  // these from `initState` / `dispose` of the chat page so we don't
  // subscribe to every conv the user has ever opened.

  /// Subscribe to message + call topics for [conversationId]. Safe to
  /// call multiple times — the second call no-ops.
  void subscribeConversation(String conversationId) {
    if (conversationId.isEmpty) return;
    _wantConvSubs.add(conversationId);
    if (_status == ChatTransportStatus.connected) {
      _attachConvSubs(conversationId);
    }
  }

  /// Subscribe to ONLY the call topic (`…/call`) for each id in
  /// [conversationIds], without the message topic. Call this at boot
  /// with every conversation the user belongs to so an incoming
  /// `call.invite` broadcast on `/topic/conversations/{id}/call` shows
  /// the in-app incoming-call overlay on ANY screen — not just while
  /// the chat page is open. (The message topic is left to
  /// [subscribeConversation], which the open chat page manages, so we
  /// don't double-process messages for every conversation.) Idempotent.
  void subscribeCallTopics(Iterable<String> conversationIds) {
    for (final id in conversationIds) {
      if (id.isEmpty) continue;
      _wantCallSubs.add(id);
      if (_status == ChatTransportStatus.connected) {
        _attachCallSub(id);
      }
    }
  }

  /// Drop both subscriptions for [conversationId]. Idempotent.
  ///
  /// The call topic is preserved when the conversation is in
  /// [_wantCallSubs] (a boot-time subscription) so closing the chat
  /// page doesn't stop incoming invites for that conversation from
  /// reaching the global overlay.
  void unsubscribeConversation(String conversationId) {
    _wantConvSubs.remove(conversationId);
    _convSubs.remove('$conversationId#msg')?.call();
    if (!_wantCallSubs.contains(conversationId)) {
      _convSubs.remove('$conversationId#call')?.call();
    }
  }

  void _attachConvSubs(String conversationId) {
    final msgKey = '$conversationId#msg';
    final client = _client;
    if (client == null) return;
    if (!_convSubs.containsKey(msgKey)) {
      final msgUnsub = client.subscribe(
        destination: '/topic/conversations/$conversationId',
        callback: (frame) => _handleEnvelope(frame, source: 'conv'),
      );
      _convSubs[msgKey] = msgUnsub;
    }
    // The call topic may already be attached by a boot-time
    // [subscribeCallTopics]; guard it independently so we don't leak a
    // second subscription (and overwrite the unsub handle).
    _attachCallSub(conversationId);
  }

  /// Attach the call topic for [conversationId] if not already attached.
  void _attachCallSub(String conversationId) {
    final callKey = '$conversationId#call';
    if (_convSubs.containsKey(callKey)) return; // already subscribed
    final client = _client;
    if (client == null) return;
    final callUnsub = client.subscribe(
      destination: '/topic/conversations/$conversationId/call',
      callback: (frame) => _handleEnvelope(frame, source: 'convCall'),
    );
    _convSubs[callKey] = callUnsub;
  }

  // ── inbound frame handling ──────────────────────────────────

  void _handleEnvelope(StompFrame frame, {required String source}) {
    final body = frame.body;
    if (body == null || body.isEmpty) return;
    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        developer.log('chat: bad envelope from $source → $body', name: 'chat');
      }
      return;
    }
    final eventName = envelope['event'] as String? ?? '';
    final payload = envelope['payload'];
    if (payload is! Map<String, dynamic>) return;

    final ev = _decode(eventName, payload);
    if (ev == null) return;

    // Fan out one event per `ReactionToggledEvent` delta — the backend
    // ships the full reaction list per toggle, but the repo expects a
    // single (emoji, employeeId) delta. We compute the delta from the
    // existing local state OR emit one per current reaction; the repo
    // will reconcile either way because toggling twice is a no-op.
    if (ev is List<ChatTransportEvent>) {
      for (final e in ev.cast<ChatTransportEvent>()) {
        if (!_events.isClosed) _events.add(e);
      }
    } else if (ev is ChatTransportEvent && !_events.isClosed) {
      _events.add(ev);
    }
  }

  /// Decode by event name. The map keys mirror `ChatEvent.event`
  /// strings used in Section 7 of the integration guide.
  dynamic _decode(String name, Map<String, dynamic> payload) {
    switch (name) {
      case 'message.send':
        // Drop self-echoes — backend fans every message back through
        // `/topic/conversations/{id}` including to the original
        // sender, but the repo's `send()` has already inserted the
        // bubble optimistically. Letting the echo through always
        // produced a brief duplicate while id-swap or heuristic
        // dedup raced the STOMP frame.
        //
        // Two-layer check:
        //   1. Id-based — set by `sendMessage` once REST returns the
        //      canonical id. Catches the case where echo arrives
        //      after the POST response.
        //   2. SenderId-based — catches the inverted race where the
        //      echo arrives BEFORE the POST response, so the id-set
        //      is still empty. Compares against the current
        //      [_userId] (configured via `updateConfig`/`start`).
        //
        // Multi-device caveat: if the same account is signed in on
        // two devices, the OTHER device's messages would also have
        // matching `senderId` and get dropped on this device's
        // STOMP echo channel. They'll still appear on the next
        // `loadForConversation` / `loadInbox`, but no real-time
        // live update across-devices. Acceptable trade-off for the
        // single-device case which is the overwhelming majority.
        final selfId = payload['id']?.toString();
        if (selfId != null && _ourRecentSends.remove(selfId)) {
          return null;
        }
        final senderId = payload['senderId']?.toString();
        if (senderId != null &&
            _userId.isNotEmpty &&
            senderId == _userId) {
          return null;
        }
        return MessageReceivedEvent(messageFromDto(payload));
      case 'message.edit':
        // Server may send the full MessageDto or a `{messageId, newBody}`
        // delta — handle both. Edit always carries a non-null body.
        if (payload.containsKey('id')) {
          final dto = messageFromDto(payload);
          return MessageEditedEvent(
            messageId: dto.id,
            newBody: dto.body ?? '',
          );
        }
        return MessageEditedEvent(
          messageId: payload['messageId'].toString(),
          newBody: payload['newBody'] as String? ?? '',
        );
      case 'message.delete':
        if (payload.containsKey('id')) {
          return MessageDeletedEvent(payload['id'].toString());
        }
        return MessageDeletedEvent(payload['messageId'].toString());
      case 'message.read':
        // `{ conversationId, userId, lastReadMessageId }` — peer
        // (or our other device) just bumped their read cursor.
        return MessageReadEvent(
          conversationId: payload['conversationId'].toString(),
          userId: payload['userId'].toString(),
          lastReadMessageId: payload['lastReadMessageId'].toString(),
        );
      case 'presence.update':
        // `{ userId, status, lastSeenAt? }` — repo decodes the
        // payload into a typed Presence in its inbound handler.
        return PresenceUpdatedEvent(payload);
      case 'conversation.remove':
        // `{ conversationId }` — backend kicked us OR we left.
        // Tolerant of both shapes: `id` (full DTO) and the dedicated
        // `conversationId` key.
        final id = (payload['conversationId'] ?? payload['id'])?.toString();
        if (id == null || id.isEmpty) return null;
        return ConversationRemovedEvent(id);
      case 'reaction.toggle':
        return _reactionEventsFromPayload(payload);
      case 'call.invite':
        return _callInviteFromDto(payload);
      case 'call.accept':
        return CallAcceptEvent(
          callId: (payload['id'] ?? payload['callId']).toString(),
          accepterId: _pickAccepterId(payload),
        );
      case 'call.reject':
        return CallRejectEvent(
          callId: (payload['id'] ?? payload['callId']).toString(),
          reason: (payload['reason'] ?? payload['endReason']) as String?,
        );
      case 'call.hangup':
      case 'call.end':
        return CallHangupEvent(
          callId: (payload['id'] ?? payload['callId']).toString(),
          hangerUpperId: _pickHangerUpperId(payload),
        );
      case 'conversation.create':
        return _conversationCreatedFromDto(payload);
      case 'conversation.update':
        return _conversationUpdatedFromDto(payload);
      case 'conversation.avatar.update':
        return ConversationAvatarUpdatedEvent(
          conversationId: (payload['id'] ?? payload['conversationId']).toString(),
          participantIds: _membersAsStringIds(payload),
          // Real backend uses URL-only — `avatarBase64` stays null;
          // the URL flows in via `conversation.update` instead.
          avatarBase64: payload['avatarBase64'] as String?,
          fileExtension: payload['fileExtension'] as String?,
        );
      case 'profile.update':
        return ProfileUpdatedEvent(
          userId: (payload['userId'] ?? payload['id']).toString(),
          newName: (payload['newName'] ?? payload['fullName']) as String? ?? '',
        );
      default:
        if (kDebugMode) {
          developer.log('chat: unknown event "$name"', name: 'chat');
        }
        return null;
    }
  }

  // ── DTO → entity mappers ────────────────────────────────────
  //
  // `messageFromDto` now lives in `chat_dto_mappers.dart` so the
  // transport (decoding STOMP frames) and the repos (decoding REST
  // responses) agree on field aliases + seed-driven sender lookup.
  // The remaining mappers below are transport-only (call invite +
  // conversation create/update envelopes).

  /// Map an incoming `ChatCallDto` onto the existing [CallInviteEvent].
  CallInviteEvent _callInviteFromDto(Map<String, dynamic> json) {
    final callType = (json['type'] as String? ?? 'VOICE').toUpperCase();
    final callerId = json['callerId'].toString();
    // ChatCallDto doesn't ship a caller name — resolve it via the
    // shared [UsersCache] (populated by `bootChatTransport`'s
    // /users + /users/me hydration). Falls back to a `User #<id>`
    // placeholder so the incoming-call sheet never renders "?"
    // initials for someone we *do* know the id of.
    final cachedName = UsersCache.instance.nameOf(callerId);
    final callerName = (cachedName != null && cachedName.trim().isNotEmpty)
        ? cachedName
        : 'User #$callerId';
    return CallInviteEvent(
      callId: json['id'].toString(),
      conversationId: json['conversationId'].toString(),
      callerId: callerId,
      callerName: callerName,
      callType: callType == 'VIDEO' ? ChatCallType.video : ChatCallType.voice,
      startedAt: _parseInstant(json['startedAt']) ?? DateTime.now(),
      targetIds: _participantIdsAsStrings(json['participants']),
      streamCallCid: json['streamCallCid'] as String?,
    );
  }

  /// Map an incoming `ConversationDto` onto the existing
  /// [ConversationCreatedEvent].
  ConversationCreatedEvent _conversationCreatedFromDto(
      Map<String, dynamic> json) {
    final type = (json['type'] as String? ?? 'DIRECT').toUpperCase();
    return ConversationCreatedEvent(
      conversationId: json['id'].toString(),
      name: (json['name'] as String?) ?? '',
      isGroup: type == 'GROUP',
      // Creator id/name not surfaced on ConversationDto directly —
      // the page layer can read it from the first member with
      // ADMIN role. For now, blank.
      creatorId: '',
      creatorName: '',
      participantIds: _membersAsStringIds(json),
      createdAt: _parseInstant(json['createdAt']) ?? DateTime.now(),
    );
  }

  ConversationUpdatedEvent _conversationUpdatedFromDto(
      Map<String, dynamic> json) {
    return ConversationUpdatedEvent(
      conversationId: json['id'].toString(),
      name: (json['name'] as String?) ?? '',
      participantIds: _membersAsStringIds(json),
    );
  }

  /// Collapse a reactions payload into one or more
  /// [ReactionToggledEvent]s.
  List<ChatTransportEvent> _reactionEventsFromPayload(
      Map<String, dynamic> payload) {
    // Two shapes possible:
    //   1. `{messageId, reactions: [{userId, emoji}, ...]}`
    //      (server pushes the full list after a toggle)
    //   2. `{messageId, emoji, userId}` (server pushes just the delta)
    final messageId =
        (payload['id'] ?? payload['messageId']).toString();
    final reactionsRaw = payload['reactions'];
    if (reactionsRaw is List) {
      return [
        for (final r in reactionsRaw)
          if (r is Map &&
              r['emoji'] is String &&
              r['userId'] != null)
            ReactionToggledEvent(
              messageId: messageId,
              emoji: r['emoji'] as String,
              employeeId: r['userId'].toString(),
            ),
      ];
    }
    final emoji = payload['emoji'] as String? ?? '';
    final uid = (payload['userId'] ?? payload['employeeId'])?.toString();
    if (emoji.isEmpty || uid == null) return const <ChatTransportEvent>[];
    return [
      ReactionToggledEvent(
        messageId: messageId,
        emoji: emoji,
        employeeId: uid,
      ),
    ];
  }

  // Helpers extracting lists of stringified user ids from DTO shapes.
  List<String> _membersAsStringIds(Map<String, dynamic> json) {
    final raw = json['members'] ?? json['participantIds'];
    if (raw is! List) return const <String>[];
    return raw.map<String?>((m) {
      if (m == null) return null;
      if (m is Map) return m['userId']?.toString();
      return m.toString();
    }).whereType<String>().toList(growable: false);
  }

  List<String> _participantIdsAsStrings(Object? participants) {
    if (participants is! List) return const <String>[];
    return participants
        .map<String?>((p) => p is Map ? p['userId']?.toString() : null)
        .whereType<String>()
        .toList(growable: false);
  }

  String? _pickAccepterId(Map<String, dynamic> payload) {
    final direct = payload['accepterId'];
    if (direct != null) return direct.toString();
    // ChatCallDto echo — the accepter is the participant with
    // status=ANSWERED whose joinedAt is the latest.
    final parts = payload['participants'];
    if (parts is List) {
      Map<String, dynamic>? best;
      for (final p in parts) {
        if (p is Map &&
            (p['status'] as String?)?.toUpperCase() == 'ANSWERED') {
          if (best == null) {
            best = Map<String, dynamic>.from(p);
          } else {
            final a = _parseInstant(p['joinedAt']);
            final b = _parseInstant(best['joinedAt']);
            if (a != null && (b == null || a.isAfter(b))) {
              best = Map<String, dynamic>.from(p);
            }
          }
        }
      }
      return best?['userId']?.toString();
    }
    return null;
  }

  String? _pickHangerUpperId(Map<String, dynamic> payload) {
    final direct = payload['hangerUpperId'] ?? payload['endedById'];
    if (direct != null) return direct.toString();
    // Fall back to caller id when end is server-emitted (e.g.
    // all-callees-left auto-end → caller is the canonical ender).
    return payload['callerId']?.toString();
  }

  DateTime? _parseInstant(Object? v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  // ── lifecycle (app foreground / background) ──────────────────
  //
  // The OS often keeps a backgrounded app's TCP socket alive for
  // minutes — long enough that the backend doesn't see us as
  // "disconnected" and never broadcasts `presence.update OFFLINE`.
  // Peers then keep seeing us as green-dot Online even though we've
  // minimised. To make the "Away" / "Last seen X" surfaces work
  // promptly, the lifecycle bridge calls [pause] on background
  // (closing the STOMP socket so the server's heartbeat detects the
  // disconnect immediately) and [resume] on foreground (reopens the
  // socket so we get back online without a config change).

  /// Close the STOMP socket without forgetting our config — so a
  /// subsequent [resume] can rebuild against the same URL/identity.
  /// Safe to call when already closed.
  Future<void> pause() async {
    await _close();
    _setStatus(ChatTransportStatus.disconnected);
  }

  /// Re-open the STOMP socket using the current config. Safe to call
  /// when already connected (the underlying [_maybeConnect] short-
  /// circuits because [_client] is non-null after [pause] only when
  /// [_close] is still in flight).
  Future<void> resume() async {
    if (_url.isEmpty) return;
    unawaited(_maybeConnect());
  }

  // ── disconnect / cleanup ────────────────────────────────────

  Future<void> _close() async {
    _inboxSub?.call();
    _inboxSub = null;
    _callsSub?.call();
    _callsSub = null;
    _presenceSub?.call();
    _presenceSub = null;
    for (final unsub in _convSubs.values) {
      try {
        unsub();
      } catch (_) {}
    }
    _convSubs.clear();
    try {
      _client?.deactivate();
    } catch (_) {}
    _client = null;
  }

  void _setStatus(ChatTransportStatus s) {
    if (_status == s) return;
    _status = s;
    if (!_statusEvents.isClosed) _statusEvents.add(s);
  }

  // ── outbound (REST, fire-and-forget) ─────────────────────────
  //
  // Public signatures match the legacy WS-era transport so repos
  // and the call-signalling service don't need to change. Internals
  // route through [ChatsRemoteDataSource] — STOMP echo handles the
  // UI update via the subscriptions above.
  //
  // Errors are swallowed and a debug log emitted (matching the
  // legacy behaviour where a send to a dead socket was also silent).
  // Real error surfacing belongs to Prompt 4 when the optimistic
  // local insert + reconciliation lands.

  /// POST the message to the backend and return the canonical backend
  /// id (stringified Long) so the caller can swap its optimistic local
  /// id with the real one — that swap is what makes the inbound
  /// STOMP echo dedup correctly. Returns `null` if the conversation
  /// id isn't a backend id (seed conv) or the POST failed.
  Future<String?> sendMessage(
    ChatMessage message, {
    List<String> targetIds = const <String>[],
  }) async {
    final convId = int.tryParse(message.conversationId);
    if (convId == null) {
      _logBadId('sendMessage', message.conversationId);
      return null;
    }
    final type = switch (message.type) {
      ChatMessageType.image => WireMessageType.image,
      ChatMessageType.voice => WireMessageType.voice,
      ChatMessageType.file => WireMessageType.file,
      ChatMessageType.system => WireMessageType.system,
      _ => WireMessageType.text,
    };
    try {
      final response = await _remote.sendMessage(
        convId,
        type: type,
        body: message.body,
        attachmentUrl: message.fileUrl ?? message.voiceUrl,
        attachmentSizeBytes: message.fileSizeBytes,
        durationSeconds: message.voiceDurationSeconds,
        replyToMessageId: int.tryParse(message.replyToId ?? ''),
      );
      final id = response['id']?.toString();
      if (id != null && id.isNotEmpty) {
        // Mark this id as "ours" so the matching STOMP echo gets
        // dropped at [_decode] instead of producing a duplicate
        // bubble while the repo's id-swap is still in flight.
        _ourRecentSends.add(id);
        Timer(const Duration(seconds: 30), () => _ourRecentSends.remove(id));
      }
      return id;
    } catch (e, s) {
      _swallow('sendMessage')(e, s);
      return null;
    }
  }

  void sendEdit(String messageId, String newBody) {
    final id = int.tryParse(messageId);
    if (id == null) {
      _logBadId('sendEdit', messageId);
      return;
    }
    unawaited(_remote.editMessage(id, newBody).catchError(_swallow('sendEdit')));
  }

  void sendDelete(String messageId) {
    final id = int.tryParse(messageId);
    if (id == null) {
      _logBadId('sendDelete', messageId);
      return;
    }
    unawaited(_remote.deleteMessage(id).catchError(_swallow('sendDelete')));
  }

  void sendReaction({
    required String messageId,
    required String emoji,
    required String employeeId,
  }) {
    final id = int.tryParse(messageId);
    if (id == null) {
      _logBadId('sendReaction', messageId);
      return;
    }
    unawaited(_remote.toggleReaction(id, emoji).catchError(_swallow('sendReaction')));
  }

  // ── Call signalling ─────────────────────────────────────────

  /// POST /chats/conversations/{id}/calls. Returns the full backend
  /// response so the caller's side can pick up:
  ///   * the canonical numeric `id` (replaces the local placeholder)
  ///   * the `streamCallCid` for the media leg
  ///   * any other fields the page wants to surface
  /// Returns `null` if the conv id isn't numeric or the POST failed.
  Future<Map<String, dynamic>?> sendCallInvite({
    required String callId, // local placeholder — backend assigns the real id
    required String conversationId,
    required String callerId,
    required String callerName,
    required ChatCallType callType,
    required DateTime startedAt,
    List<String> targetIds = const <String>[],
  }) async {
    final convId = int.tryParse(conversationId);
    if (convId == null) {
      _logBadId('sendCallInvite', conversationId);
      return null;
    }
    final type = callType == ChatCallType.video
        ? WireCallType.video
        : WireCallType.voice;
    try {
      return await _remote.startCall(convId, type: type);
    } catch (e, s) {
      // Log here so the failure shows up in the chat trace, but
      // rethrow so [CallSignalingService.startOutgoing]'s
      // `.catchError(...)` can roll the local "Calling…" state back
      // to ENDED and surface a snackbar (e.g. "You're already in
      // another call" for the 400 the backend throws when a stale
      // call row is still RINGING).
      _swallow('sendCallInvite')(e, s);
      rethrow;
    }
  }

  /// POST /chats/calls/{id}/accept. Returns the full ChatCallDto
  /// response so the callee can pick up `streamCallCid` and bring
  /// up the media leg only after the REST acknowledged the accept
  /// (avoids joining Stream for a call the server says already
  /// ended). Returns `null` on bad-id / network failure.
  Future<Map<String, dynamic>?> sendCallAccept(
    String callId, {
    String? accepterId,
  }) async {
    final id = int.tryParse(callId);
    if (id == null) {
      _logBadId('sendCallAccept', callId);
      return null;
    }
    try {
      // Hard 8 s ceiling. The chat backend usually answers in <500 ms,
      // but on a cold-start (app launched by CallKit Accept) the auth
      // interceptor or dio client can take a beat to be ready and the
      // POST can hang indefinitely waiting on token hydration. If it
      // hangs the call page sits on "Connecting…" forever — better to
      // bail out and fall through to the Stream-only accept path so
      // audio at least flows.
      return await _remote.acceptCall(id).timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          // ignore: avoid_print
          print('[ChatTransport] sendCallAccept TIMEOUT after 8s on '
              'callId=$callId — returning null so caller falls back '
              'to Stream-only accept');
          return <String, dynamic>{};
        },
      ).then((v) => v.isEmpty ? null : v);
    } catch (e, s) {
      _swallow('sendCallAccept')(e, s);
      return null;
    }
  }

  void sendCallReject(String callId, {String? reason}) {
    final id = int.tryParse(callId);
    if (id == null) {
      _logBadId('sendCallReject', callId);
      return;
    }
    unawaited(
        _remote.rejectCall(id, reason: reason).catchError(_swallow('sendCallReject')));
  }

  void sendCallHangup(String callId, {String? hangerUpperId}) {
    final id = int.tryParse(callId);
    if (id == null) {
      _logBadId('sendCallHangup', callId);
      return;
    }
    unawaited(_remote.endCall(id).catchError(_swallow('sendCallHangup')));
  }

  // ── Conversation management ─────────────────────────────────

  /// Server creates the conversation and fans `conversation.create`
  /// to every member's `/user/queue/inbox`. The local sender also
  /// receives that fan-out so the existing inbound handler in
  /// `bootChatTransport` hydrates the cache on every device.
  ///
  /// [conversationId] from the legacy API is ignored — the server
  /// assigns the real id. Pages that need it should consume the
  /// inbound `ConversationCreatedEvent` rather than the param they
  /// passed in.
  void sendConversationCreate({
    required String conversationId,
    required String name,
    required bool isGroup,
    required String creatorId,
    required String creatorName,
    required List<String> participantIds,
    required DateTime createdAt,
  }) {
    final ids = <int>{};
    for (final p in participantIds) {
      final n = int.tryParse(p);
      if (n != null) ids.add(n);
    }
    if (ids.isEmpty) {
      _logBadId('sendConversationCreate', participantIds.join(','));
      return;
    }
    unawaited(_remote
        .createConversation(
          type: isGroup ? 'GROUP' : 'DIRECT',
          memberIds: ids,
          name: isGroup ? name : null,
        )
        .catchError(_swallow('sendConversationCreate')));
  }

  void sendConversationUpdate({
    required String conversationId,
    required String name,
    required List<String> participantIds, // ignored — backend authoritative
  }) {
    final id = int.tryParse(conversationId);
    if (id == null) {
      _logBadId('sendConversationUpdate', conversationId);
      return;
    }
    unawaited(_remote
        .updateConversation(id, name: name)
        .catchError(_swallow('sendConversationUpdate')));
  }

  /// Backend doesn't have a chat-specific profile-rename endpoint —
  /// the canonical user/employee record is updated via the employee
  /// PATCH, and the backend re-broadcasts `profile.update` to every
  /// peer's `/user/queue/inbox`. Nothing for the transport to do
  /// here; the method stays as a no-op so existing call sites in
  /// `ChatSettings.setIdentity` still compile.
  void sendProfileUpdate({
    required String userId,
    required String newName,
  }) {
    // intentional no-op — see doc above
  }

  /// Avatar updates go through the same `PATCH /conversations/{id}`
  /// endpoint as renames; only `avatarUrl` is touched. The legacy
  /// base64-broadcast flow is gone — when the URL upload endpoint
  /// lands (Prompt 5 territory), wire it here. For now:
  ///   - `avatarBase64 == null` → PATCH `avatarUrl=""` ("remove photo")
  ///   - `avatarBase64 != null` → no-op (no URL to send yet)
  void sendConversationAvatar({
    required String conversationId,
    required List<String> participantIds, // ignored — backend authoritative
    required String? avatarBase64,
    required String? fileExtension,
  }) {
    if (avatarBase64 != null) {
      // Upload endpoint TBD — see doc above.
      return;
    }
    final id = int.tryParse(conversationId);
    if (id == null) {
      _logBadId('sendConversationAvatar', conversationId);
      return;
    }
    unawaited(_remote
        .updateConversation(id, avatarUrl: '')
        .catchError(_swallow('sendConversationAvatar')));
  }

  // ── misc ────────────────────────────────────────────────────

  Function _swallow(String op) => (Object e, StackTrace? s) {
        if (kDebugMode) {
          developer.log('chat: $op failed → $e', name: 'chat');
        }
      };

  void _logBadId(String op, String id) {
    if (kDebugMode) {
      developer.log('chat: $op skipped — non-numeric id "$id"', name: 'chat');
    }
  }

  /// Adapt the configured base URL to a STOMP-compatible URL.
  /// Accepts:
  ///   `http://host:port`  →  `ws://host:port/ws`
  ///   `https://host:port` →  `wss://host:port/ws`
  ///   `ws://host:port`    →  `ws://host:port/ws` (legacy relay URL)
  ///   `ws://host:port/ws` →  unchanged
  String? _buildStompUrl(String base) {
    final trimmed = base.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return null;
    final scheme = switch (uri.scheme) {
      'http' => 'ws',
      'https' => 'wss',
      'ws' => 'ws',
      'wss' => 'wss',
      _ => 'ws',
    };
    final port = uri.hasPort ? ':${uri.port}' : '';
    final path = uri.path.isEmpty || uri.path == '/' ? '/ws' : uri.path;
    return '$scheme://${uri.host}$port$path';
  }
}
