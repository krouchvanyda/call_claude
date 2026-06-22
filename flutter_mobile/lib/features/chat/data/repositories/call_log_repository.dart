import 'dart:async';

import '../../entities/call_log.dart';

/// Slice 10.2.x — in-memory call log. Page-level state machines
/// (voice / video) call into this on every initiate / answer / end
/// transition. The history view can hydrate from
/// `GET /chats/calls` when needed; the old demo seed is gone.
class CallLogRepository {
  CallLogRepository();

  static final List<ChatCallLog> _seed = <ChatCallLog>[];

  final StreamController<List<ChatCallLog>> _changes =
      StreamController<List<ChatCallLog>>.broadcast();

  Future<List<ChatCallLog>> getAll() async {
    final out = List<ChatCallLog>.of(_seed)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(out);
  }

  Stream<List<ChatCallLog>> watchAll() async* {
    yield await getAll();
    yield* _changes.stream;
  }

  Future<List<ChatCallLog>> getForConversation(String conversationId) async {
    final out = _seed.where((c) => c.conversationId == conversationId).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(out);
  }

  Future<ChatCallLog> logStart({
    required String conversationId,
    required String callerId,
    required String callerName,
    required ChatCallType callType,
    DateTime? at,
  }) async {
    final stamp = at ?? DateTime.now();
    final entry = ChatCallLog(
      id: 'call-${stamp.microsecondsSinceEpoch}',
      conversationId: conversationId,
      callerId: callerId,
      callerName: callerName,
      callType: callType,
      status: ChatCallStatus.noAnswer,
      startedAt: stamp,
    );
    _seed.add(entry);
    _emit();
    return entry;
  }

  Future<ChatCallLog> logAnswered(String id) async {
    return _mutate(
      id,
      (c) => c.copyWith(
        status: ChatCallStatus.answered,
        answeredAt: DateTime.now(),
      ),
    );
  }

  Future<ChatCallLog> logEnded({
    required String id,
    required int durationSeconds,
    ChatCallStatus? finalStatus,
  }) async {
    return _mutate(
      id,
      (c) => c.copyWith(
        status: finalStatus ?? c.status,
        endedAt: DateTime.now(),
        durationSeconds: durationSeconds,
      ),
    );
  }

  Future<ChatCallLog> _mutate(
    String id,
    ChatCallLog Function(ChatCallLog) f,
  ) async {
    final idx = _seed.indexWhere((c) => c.id == id);
    if (idx == -1) {
      throw StateError('Call log $id not found');
    }
    final next = f(_seed[idx]);
    _seed[idx] = next;
    _emit();
    return next;
  }

  void _emit() {
    if (!_changes.isClosed) _changes.add(_seed);
  }
}
