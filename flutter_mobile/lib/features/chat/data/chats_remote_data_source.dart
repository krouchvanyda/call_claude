import 'package:dio/dio.dart';

import '../../../core/network/api_envelope.dart';

/// Wire enum for `SendMessageRequest.type` — values match the Spring
/// `MessageType` enum exactly (TEXT / IMAGE / VOICE / FILE / SYSTEM).
/// SYSTEM is server-emitted only; clients send the other four.
enum WireMessageType { text, image, voice, file, system }

extension on WireMessageType {
  String get wireValue => name.toUpperCase();
}

/// Wire enum for `StartCallRequest.type` — mirrors Spring `CallType`.
enum WireCallType { voice, video }

extension on WireCallType {
  String get wireValue => name.toUpperCase();
}

/// REST surface for the chat module — every "send" / "do" operation
/// that used to push a JSON frame down the LAN-relay WebSocket now
/// POSTs / PATCHes / DELETEs through this class against the real
/// Spring backend at `/api/v1/chats/*`.
///
/// **Routing**: paths follow `CHAT_MODULE_BACKEND_INTEGRATIONGUIDE.md`
/// Section 7 verbatim. Request bodies mirror the Java DTOs under
/// `dto/` byte-exact (field names matter — Jackson silently drops
/// anything the record doesn't declare).
///
/// **Auth**: the injected [Dio] already carries the `AuthInterceptor`,
/// so every call gets `Authorization: Bearer …` for free and the
/// `401 → refresh → retry` flow works the same as the rest of the
/// project's data sources.
///
/// **No reactive side effects**: every method just performs the HTTP
/// op and returns. The real-time fan-out comes from STOMP subscriptions
/// in `ChatTransport` — see Prompt 1 of the integration guide. This
/// keeps each layer doing one thing.
abstract class ChatsRemoteDataSource {
  // ── Conversations ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> listConversations({
    int page = 1,
    int pageSize = 50,
  });
  Future<Map<String, dynamic>> getConversation(int id);
  Future<Map<String, dynamic>> createConversation({
    required String type,
    required Set<int> memberIds,
    String? name,
    String? avatarUrl,
  });
  Future<Map<String, dynamic>> updateConversation(
    int id, {
    String? name,
    String? avatarUrl,
  });
  /// `DELETE /chats/conversations/{id}` — admin only for groups,
  /// either-party for direct convs (backend enforces).
  Future<void> deleteConversation(int id);
  Future<void> addMembers(int conversationId, Set<int> memberIds);
  Future<void> removeMember(int conversationId, int userId);
  Future<Map<String, dynamic>> markRead(int conversationId, int lastReadMessageId);

  // ── Messages ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> listMessages(
    int conversationId, {
    int page = 1,
    int pageSize = 30,
  });
  /// `GET /chats/conversations/{id}/messages/search?q=&page=&pageSize=`
  /// — server-side case-insensitive substring over message bodies.
  /// Returns the same paginated envelope shape as [listMessages].
  Future<Map<String, dynamic>> searchMessages(
    int conversationId,
    String query, {
    int page = 1,
    int pageSize = 30,
  });
  Future<Map<String, dynamic>> sendMessage(
    int conversationId, {
    required WireMessageType type,
    String? body,
    String? attachmentUrl,
    String? attachmentContentType,
    int? attachmentSizeBytes,
    int? durationSeconds,
    int? replyToMessageId,
  });
  Future<Map<String, dynamic>> editMessage(int messageId, String body);
  Future<void> deleteMessage(int messageId);
  Future<List<dynamic>> toggleReaction(int messageId, String emoji);

  // ── Calls ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> startCall(
    int conversationId, {
    required WireCallType type,
  });
  Future<Map<String, dynamic>> acceptCall(int callId);
  Future<Map<String, dynamic>> rejectCall(int callId, {String? reason});
  Future<Map<String, dynamic>> endCall(int callId);
  /// `GET /chats/calls/{id}` — reconcile a call's state after a STOMP
  /// dropout or a cold start. Returns the canonical [ChatCallDto].
  Future<Map<String, dynamic>> getCall(int callId);
  Future<Map<String, dynamic>> listCalls({int page = 1, int pageSize = 50});
  Future<Map<String, dynamic>> listConversationCalls(
    int conversationId, {
    int page = 1,
    int pageSize = 6,
  });

  /// `GET /chats/calls/stream-token` — issue a short-lived JWT for the
  /// Stream Video SDK. The response carries everything the mobile
  /// needs to bring up the `StreamVideo` client:
  ///   `{ token: <jwt>, apiKey: <stream-api-key>, userId: <our-id> }`
  /// Refresh by re-calling this endpoint when the token expires.
  Future<Map<String, dynamic>> getStreamToken();

  // ── Presence ──────────────────────────────────────────────────────
  /// `GET /chats/presence` — full snapshot of every user the server
  /// has tracked. Used on app boot + on every successful reconnect
  /// to recover state the broker may have advanced while we were
  /// disconnected.
  Future<List<dynamic>> listPresence();

  /// `GET /chats/presence?ids=1,4,7` — batch hydrate just the users
  /// on screen (group members, chat-info participants, etc.).
  Future<List<dynamic>> listPresenceForIds(Iterable<int> userIds);

  /// `POST /chats/presence/background` — lifecycle beacon telling the
  /// server we minimized, so it flips us OFFLINE immediately (instead of
  /// waiting ~20-30s for the STOMP heartbeat to notice the suspended
  /// socket). That instant-OFFLINE is what makes a just-minimized callee
  /// receive the VoIP/CallKit ring (the backend rings only OFFLINE callees).
  Future<void> reportBackground();

  /// `POST /chats/presence/foreground` — lifecycle beacon telling the
  /// server we're back in the foreground (so calls use the in-app overlay,
  /// not CallKit).
  Future<void> reportForeground();
}

/// `dio`-backed implementation. Resolves paths against
/// `dio.options.baseUrl` (e.g. `http://10.0.2.2:8080/api/v1`).
class DioChatsRemoteDataSource implements ChatsRemoteDataSource {
  DioChatsRemoteDataSource({required Dio dio}) : _dio = dio;

  // Path constants kept in one place so future renames are one edit.
  // `/api/v1` prefix is part of `dio.options.baseUrl`.
  static const String _conversationsPath = '/chats/conversations';
  static const String _messagesPath = '/chats/messages';
  static const String _callsPath = '/chats/calls';
  static const String _presencePath = '/chats/presence';

  final Dio _dio;

  // ── Conversations ─────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> listConversations({
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      _conversationsPath,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> getConversation(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('$_conversationsPath/$id');
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> createConversation({
    required String type,
    required Set<int> memberIds,
    String? name,
    String? avatarUrl,
  }) async {
    // Body mirrors CreateConversationRequest.java:
    //   { type: "DIRECT"|"GROUP", memberIds: [Long, ...], name?, avatarUrl? }
    final body = <String, dynamic>{
      'type': type,
      'memberIds': memberIds.toList(),
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      if (avatarUrl != null && avatarUrl.trim().isNotEmpty)
        'avatarUrl': avatarUrl.trim(),
    };
    final res = await _dio.post<Map<String, dynamic>>(
      _conversationsPath,
      data: body,
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> updateConversation(
    int id, {
    String? name,
    String? avatarUrl,
  }) async {
    // Body mirrors UpdateConversationRequest.java — both fields
    // optional; null means "leave untouched", empty string means
    // "clear" (server-side decides).
    final body = <String, dynamic>{};
    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl.trim();
    final res = await _dio.patch<Map<String, dynamic>>(
      '$_conversationsPath/$id',
      data: body,
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<void> deleteConversation(int id) async {
    // Backend enforces auth: group → admin only; direct → either party.
    // 403 surfaces through Dio as a `DioException`.
    await _dio.delete<dynamic>('$_conversationsPath/$id');
  }

  @override
  Future<void> addMembers(int conversationId, Set<int> memberIds) async {
    // Body mirrors AddMembersRequest.java: { memberIds: [Long, ...] }.
    await _dio.post<dynamic>(
      '$_conversationsPath/$conversationId/members',
      data: {'memberIds': memberIds.toList()},
    );
  }

  @override
  Future<void> removeMember(int conversationId, int userId) async {
    await _dio.delete<dynamic>(
      '$_conversationsPath/$conversationId/members/$userId',
    );
  }

  @override
  Future<Map<String, dynamic>> markRead(
    int conversationId,
    int lastReadMessageId,
  ) async {
    // Body mirrors MarkReadRequest.java: { lastReadMessageId: Long }.
    final res = await _dio.post<Map<String, dynamic>>(
      '$_conversationsPath/$conversationId/read',
      data: {'lastReadMessageId': lastReadMessageId},
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  // ── Messages ──────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> listMessages(
    int conversationId, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_conversationsPath/$conversationId/messages',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> searchMessages(
    int conversationId,
    String query, {
    int page = 1,
    int pageSize = 30,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_conversationsPath/$conversationId/messages/search',
      queryParameters: <String, dynamic>{
        'q': query,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> sendMessage(
    int conversationId, {
    required WireMessageType type,
    String? body,
    String? attachmentUrl,
    String? attachmentContentType,
    int? attachmentSizeBytes,
    int? durationSeconds,
    int? replyToMessageId,
  }) async {
    // Body mirrors SendMessageRequest.java byte-exact — type is
    // required, every other field is optional.
    final reqBody = <String, dynamic>{
      'type': type.wireValue,
      if (body != null && body.isNotEmpty) 'body': body,
      if (attachmentUrl != null && attachmentUrl.isNotEmpty)
        'attachmentUrl': attachmentUrl,
      if (attachmentContentType != null && attachmentContentType.isNotEmpty)
        'attachmentContentType': attachmentContentType,
      if (attachmentSizeBytes != null)
        'attachmentSizeBytes': attachmentSizeBytes,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
    };
    final res = await _dio.post<Map<String, dynamic>>(
      '$_conversationsPath/$conversationId/messages',
      data: reqBody,
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> editMessage(int messageId, String body) async {
    // Body mirrors EditMessageRequest.java: { body: String (NotBlank) }.
    // Server enforces the 15-min edit window — returns 400 if past it.
    final res = await _dio.patch<Map<String, dynamic>>(
      '$_messagesPath/$messageId',
      data: {'body': body},
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<void> deleteMessage(int messageId) async {
    await _dio.delete<dynamic>('$_messagesPath/$messageId');
  }

  @override
  Future<List<dynamic>> toggleReaction(int messageId, String emoji) async {
    // Body mirrors ToggleReactionRequest.java: { emoji: String }.
    // Response is the updated `List<ReactionDto>` for the message.
    final res = await _dio.post<Map<String, dynamic>>(
      '$_messagesPath/$messageId/reactions',
      data: {'emoji': emoji},
    );
    return ApiEnvelope.parseList<dynamic>(res.data!, (d) => d);
  }

  // ── Calls ─────────────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> startCall(
    int conversationId, {
    required WireCallType type,
  }) async {
    // Body mirrors StartCallRequest.java: { type: "VOICE"|"VIDEO" }.
    final res = await _dio.post<Map<String, dynamic>>(
      '$_conversationsPath/$conversationId/calls',
      data: {'type': type.wireValue},
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> acceptCall(int callId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_callsPath/$callId/accept',
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> rejectCall(int callId, {String? reason}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_callsPath/$callId/reject',
      queryParameters: <String, dynamic>{
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      },
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> endCall(int callId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_callsPath/$callId/end',
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> getStreamToken() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_callsPath/stream-token',
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> getCall(int callId) async {
    // Used to reconcile a call's state after a missed STOMP event
    // (network blip mid-call, cold start while a call is in flight).
    final res = await _dio.get<Map<String, dynamic>>('$_callsPath/$callId');
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> listCalls({
    int page = 1,
    int pageSize = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      _callsPath,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  @override
  Future<Map<String, dynamic>> listConversationCalls(
    int conversationId, {
    int page = 1,
    int pageSize = 6,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_conversationsPath/$conversationId/calls',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return ApiEnvelope.parse<Map<String, dynamic>>(res.data!, (d) => d);
  }

  // ── Presence ──────────────────────────────────────────────────────

  @override
  Future<List<dynamic>> listPresence() async {
    // Tolerant of both shapes:
    //   `{success:true, data:[...]}` — standard envelope
    //   `[...]`                      — bare array (rare; some
    //                                    presence endpoints skip the
    //                                    wrapper for cache reasons)
    final res = await _dio.get<dynamic>(_presencePath);
    final body = res.data;
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      return ApiEnvelope.parseList<dynamic>(body, (d) => d);
    }
    return const <dynamic>[];
  }

  @override
  Future<List<dynamic>> listPresenceForIds(Iterable<int> userIds) async {
    if (userIds.isEmpty) return const <dynamic>[];
    final res = await _dio.get<dynamic>(
      _presencePath,
      queryParameters: {'ids': userIds.join(',')},
    );
    final body = res.data;
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      return ApiEnvelope.parseList<dynamic>(body, (d) => d);
    }
    return const <dynamic>[];
  }

  @override
  Future<void> reportBackground() async {
    await _dio.post<dynamic>('$_presencePath/background');
  }

  @override
  Future<void> reportForeground() async {
    await _dio.post<dynamic>('$_presencePath/foreground');
  }
}
