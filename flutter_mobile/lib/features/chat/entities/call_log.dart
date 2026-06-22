/// Slice 10.2.x — voice vs. video.
enum ChatCallType { voice, video }

/// Outcome of the call attempt.
enum ChatCallStatus { missed, answered, rejected, noAnswer }

/// Slice 10.2.x — `chat_call_log` projection.
class ChatCallLog {
  const ChatCallLog({
    required this.id,
    required this.conversationId,
    required this.callerId,
    required this.callerName,
    required this.callType,
    required this.status,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.callerAvatarUrl,
  });

  final String id;
  final String conversationId;
  final String callerId;
  final String callerName;
  final String? callerAvatarUrl;
  final ChatCallType callType;
  final ChatCallStatus status;
  final DateTime startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int durationSeconds;

  /// "5:23" or "1:02:14". Pure formatting helper.
  String formattedDuration() {
    if (durationSeconds <= 0) return '0:00';
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    final ss = s.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(h > 0 ? 2 : 1, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  ChatCallLog copyWith({
    String? id,
    String? conversationId,
    String? callerId,
    String? callerName,
    String? callerAvatarUrl,
    ChatCallType? callType,
    ChatCallStatus? status,
    DateTime? startedAt,
    DateTime? answeredAt,
    DateTime? endedAt,
    int? durationSeconds,
  }) =>
      ChatCallLog(
        id: id ?? this.id,
        conversationId: conversationId ?? this.conversationId,
        callerId: callerId ?? this.callerId,
        callerName: callerName ?? this.callerName,
        callerAvatarUrl: callerAvatarUrl ?? this.callerAvatarUrl,
        callType: callType ?? this.callType,
        status: status ?? this.status,
        startedAt: startedAt ?? this.startedAt,
        answeredAt: answeredAt ?? this.answeredAt,
        endedAt: endedAt ?? this.endedAt,
        durationSeconds: durationSeconds ?? this.durationSeconds,
      );
}
