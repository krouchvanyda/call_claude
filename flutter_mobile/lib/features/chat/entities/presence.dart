import 'conversation.dart';

/// Live presence snapshot for a single user, as returned by
/// `GET /api/v1/chats/presence*` and pushed via `/topic/presence`.
class Presence {
  const Presence({
    required this.userId,
    required this.status,
    this.lastSeenAt,
  });

  /// Stringified Long — matches how every other id in the chat module
  /// is carried (so look-ups can use the same `String` ids the rest
  /// of the codebase passes around).
  final String userId;
  final PresenceStatus status;

  /// Only populated when `status == offline`. Drives the "Last seen X
  /// minutes ago" subtitle on the direct-conversation header.
  final DateTime? lastSeenAt;

  /// Convenience for a missing-from-cache lookup — defaults to
  /// `offline` with no last-seen so the UI hides the dot gracefully.
  factory Presence.offline(String userId) =>
      Presence(userId: userId, status: PresenceStatus.offline);

  /// How long after an OFFLINE update we treat the user as "Away"
  /// instead of truly offline. Picked to match the typical
  /// background-then-foreground rhythm — a user who minimised the
  /// app to glance at something else shows as Away (amber dot) for
  /// a few minutes before fading to fully offline (no dot).
  static const Duration _awayWindow = Duration(minutes: 5);

  /// What the UI should actually render. Maps a fresh-OFFLINE
  /// presence (server saw the socket drop within the last few
  /// minutes) to AWAY so the dot stays amber instead of disappearing
  /// the instant the user backgrounds the app. Older offlines keep
  /// the real OFFLINE status so the dot truly hides.
  ///
  /// Online / busy / explicit away pass through unchanged.
  PresenceStatus get effectiveStatus {
    if (status != PresenceStatus.offline) return status;
    final seen = lastSeenAt;
    if (seen == null) return PresenceStatus.offline;
    final diff = DateTime.now().difference(seen);
    return diff < _awayWindow
        ? PresenceStatus.away
        : PresenceStatus.offline;
  }

  factory Presence.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] as String? ?? 'OFFLINE').toUpperCase();
    final status = switch (statusRaw) {
      'ONLINE' => PresenceStatus.online,
      'BUSY' => PresenceStatus.busy,
      'AWAY' => PresenceStatus.away,
      _ => PresenceStatus.offline,
    };
    final lastSeenRaw = json['lastSeenAt'];
    final lastSeen = lastSeenRaw is String && lastSeenRaw.isNotEmpty
        ? DateTime.tryParse(lastSeenRaw)
        : null;
    return Presence(
      userId: json['userId'].toString(),
      status: status,
      lastSeenAt: lastSeen,
    );
  }
}
