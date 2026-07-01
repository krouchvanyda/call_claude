import 'dart:async';
import 'dart:io' show Platform;

import 'package:erp_callkit/erp_callkit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter/widgets.dart' show WidgetsBinding, AppLifecycleState;
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart' show Call;

import 'users_cache.dart';

import '../entities/call_log.dart';
import 'callkit_call_id.dart';
import 'chat_settings.dart';
import 'chat_transport.dart';
import 'chats_remote_data_source.dart';
import 'repositories/call_log_repository.dart';
import 'repositories/conversations_repository.dart';
import 'stream_call_engine.dart';

/// Slice 10.2.3 — local state of an active or incoming call.
enum CallSignalState {
  idle,

  /// We pressed Call — waiting for the peer to accept.
  outgoingRinging,

  /// Peer pressed Call — waiting for us to accept/reject.
  incomingRinging,

  /// Either we accepted their invite or they accepted ours.
  connected,

  /// Either side hung up, or the invite was rejected / timed out.
  ended,
}

/// Snapshot of the currently-active call, surfaced to the UI.
class ActiveCall {
  const ActiveCall({
    required this.callId,
    required this.conversationId,
    required this.peerId,
    required this.peerName,
    required this.callType,
    required this.state,
    required this.startedAt,
    required this.callerId,
    this.connectedAt,
    this.endReason,
    this.conversationName,
    this.isGroup = false,
    this.conversationAvatarFilePath,
    this.streamCallCid,
  });

  final String callId;
  final String conversationId;

  /// The OTHER party — for outgoing calls this is the callee, for
  /// incoming this is the caller. Always "the person on the other end
  /// of this connection".
  final String peerId;
  final String peerName;

  final ChatCallType callType;
  final CallSignalState state;
  final DateTime startedAt;
  final DateTime? connectedAt;

  /// Slice 10.2.10 — userId of whoever ORIGINATED the call (the
  /// outgoing-invite sender). For outgoing this equals `settings.userId`;
  /// for incoming this equals `event.callerId`. Used on hangup events
  /// for group calls: only the caller's hangup ends the call for
  /// everyone — a callee tapping End in a group just leaves their own
  /// client (multi-party semantics, mirrors Telegram group calls).
  final String callerId;

  /// Why the call ended — populated only when [state] is
  /// [CallSignalState.ended]. Drives the snackbar / label on the
  /// caller's screen ("X is on another call" vs generic "Call ended").
  /// Values: `'busy'`, `'declined'`, `'hangup'`, or `null` when not
  /// applicable yet.
  final String? endReason;

  /// Slice 10.2.9 — name of the conversation the call belongs to.
  /// For direct calls this equals [peerName] (so the sheet behaves the
  /// same as before); for group calls this is the GROUP name so the
  /// incoming sheet on Pisey / Channary's phone shows "TEST01" with
  /// "Vibol is calling" as a subtitle, instead of just "Vibol".
  final String? conversationName;

  /// Slice 10.2.9 — true if the underlying conversation is a group.
  /// Drives the incoming-sheet header layout (group avatar cluster +
  /// "Group call" label).
  final bool isGroup;

  /// Slice 10.2.11 — local file path of the conversation's photo (set
  /// via Slice 10.3.3 / 10.3.5). Surfaced on the incoming-call sheet
  /// + call page hero so a group call to TEST01 with a custom photo
  /// shows that photo instead of just an icon.
  final String? conversationAvatarFilePath;

  /// Stream Video call CID (e.g. `default:abc123`) — opaque to the
  /// signalling layer, fed straight into `StreamCallEngine.join(...)`
  /// once both sides have accepted. Null when the backend hasn't
  /// shipped Stream integration yet — call stays signalling-only.
  final String? streamCallCid;

  ActiveCall copyWith({
    String? callId,
    CallSignalState? state,
    DateTime? connectedAt,
    String? endReason,
    String? streamCallCid,
  }) =>
      ActiveCall(
        callId: callId ?? this.callId,
        conversationId: conversationId,
        peerId: peerId,
        peerName: peerName,
        callType: callType,
        state: state ?? this.state,
        startedAt: startedAt,
        callerId: callerId,
        connectedAt: connectedAt ?? this.connectedAt,
        endReason: endReason ?? this.endReason,
        conversationName: conversationName,
        isGroup: isGroup,
        conversationAvatarFilePath: conversationAvatarFilePath,
        streamCallCid: streamCallCid ?? this.streamCallCid,
      );
}

/// Singleton coordinator that turns [ChatTransport] envelopes into
/// typed [ActiveCall] state transitions, and exposes the helpers the
/// call pages call (`startOutgoing`, `acceptIncoming`, `hangup`,
/// `reject`).
///
/// Demo-grade: there's no real media — once both sides reach
/// [CallSignalState.connected] the pages just show the in-call UI
/// and tick a timer. Real WebRTC would slot in here (offer/answer +
/// ICE candidates flowing through the same transport).
class CallSignalingService {
  CallSignalingService({
    required this.transport,
    required this.settings,
    required this.conversations,
    required this.callLog,
    required this.remote,
    required this.streamEngine,
  }) {
    _sub = transport.events.listen(_onEvent);
    // Bridge Stream's live incoming-call channel (foreground path)
    // into the same handler the FCM-push path uses. Without this, a
    // foregrounded callee whose Stream WebSocket received a `ring=true`
    // call would silently join in the background and the in-app
    // IncomingCallOverlay would never light up — the user only sees
    // the Stream "Call in progress" persistent notification.
    _streamIncomingSub = streamEngine.onStreamIncomingCall.listen(
      _handleStreamIncomingCall,
    );
    // When Stream signals the active call has ended (caller hung up
    // before callee answered, peer disconnected, etc.) tear down the
    // local state so the overlay / call page pops on its own. Without
    // this, B's incoming-call overlay stayed up forever after A hit
    // End — the chat-ceremony backend wasn't sending hangup events
    // for Stream-originated calls, and Stream's WS signal had nowhere
    // to land.
    _streamEndedSub = streamEngine.onStreamCallEnded.listen((reason) {
      _handleStreamCallEnded(reason);
    });
    // Stream's media-layer "peer joined" signal — used as a fallback
    // for A's UI when the chat-ceremony backend never broadcasts
    // `call.accept` to A. Symptom this fixes: A stays on "Calling…"
    // even after B has accepted and is already in the audio call,
    // because the backend's own ring timer fired and it never sent
    // the canonical accept STOMP frame to A.
    _streamPeerJoinedSub = streamEngine.onStreamPeerJoined.listen((_) {
      _handleStreamPeerJoined();
    });
  }

  final ChatTransport transport;
  final ChatSettings settings;
  final ConversationsRepository conversations;
  final CallLogRepository callLog;
  final ChatsRemoteDataSource remote;
  final StreamCallEngine streamEngine;

  StreamSubscription<ChatTransportEvent>? _sub;
  StreamSubscription<Call>? _streamIncomingSub;
  StreamSubscription<StreamCallEndReason>? _streamEndedSub;
  StreamSubscription<void>? _streamPeerJoinedSub;
  ActiveCall? _active;
  // Maps callId → callLog entry id so we can update on accept / end.
  final Map<String, String> _logIdByCallId = {};

  /// Slice 10.2.11 — caller-only set of group callees currently joined
  /// to the active call. Populated when we (the caller) receive a
  /// CallAcceptEvent with an accepterId, drained as those callees
  /// later send CallHangupEvent. When the set drains to empty in a
  /// group call we auto-hangup so the caller isn't left alone with a
  /// running timer after everyone else has bowed out (Telegram model:
  /// last-person-out closes the call). Direct 1:1 calls ignore this
  /// — there are only two parties and either side ending is already
  /// canonical (Slice 10.2.10).
  final Set<String> _activeCallees = {};

  /// Reactive view of the active call. Null = no call in flight.
  ///
  /// Backed by a [ValueNotifier] instead of a Stream so the overlay
  /// and call pages can never miss an update between rebuilds — the
  /// notifier always replays its current value to any new listener.
  /// The previous `async*` getter created a fresh stream per access
  /// and could drop events during the resubscribe window, which made
  /// stuck `incomingRinging` states (incoming-call sheet never showing,
  /// repeat invites auto-rejected) really easy to hit.
  final ValueNotifier<ActiveCall?> activeCallListenable =
      ValueNotifier<ActiveCall?>(null);

  ActiveCall? get current => _active;

  Timer? _ringTimeout;

  /// Periodic poll that resolves a `call.hangup` deferred inside the
  /// just-connected grace window (see [_scheduleDeferredHangupRecheck]).
  Timer? _deferredHangupTimer;

  /// Heartbeat that polls the backend's canonical call status while we are
  /// `connected`, so the call tears down even when BOTH push end-signals
  /// fail (STOMP `call.hangup` never delivered + Stream remote-left never
  /// fires because we joined the media after the peer already left). See
  /// [_startConnectedHeartbeat] — this is the fix for the "B stuck
  /// Connected forever" bug.
  Timer? _connectedHeartbeat;

  /// iOS-only caller-side heartbeat that polls the backend while we are
  /// `outgoingRinging`. Maps a backend `ANSWERED` onto a local
  /// `connected` so the CALLER stops ringing within one interval of the
  /// backend recording the callee's accept — even when the STOMP
  /// `call.accept` broadcast is lost (e.g. the callee accepted from a
  /// killed/locked cold-start whose POST raced the broadcast, or the
  /// caller momentarily missed the frame). See [_startRingingHeartbeat].
  Timer? _ringingHeartbeat;

  /// The call id the ring heartbeat is currently polling. The caller's
  /// id swaps mid-ring from a placeholder (`call-<me>-<ts>`) to the
  /// backend numeric id, and only the numeric id is pollable — so we
  /// restart the heartbeat whenever this changes.
  String? _ringingHeartbeatCallId;

  Future<void> dispose() async {
    await _sub?.cancel();
    await _streamIncomingSub?.cancel();
    await _streamEndedSub?.cancel();
    await _streamPeerJoinedSub?.cancel();
    _ringTimeout?.cancel();
    _deferredHangupTimer?.cancel();
    _connectedHeartbeat?.cancel();
    _ringingHeartbeat?.cancel();
    activeCallListenable.dispose();
  }

  /// iOS cold-start safety net used by [CallkitEventHandler] when the
  /// callee accepts from a killed/locked app. Tells the BACKEND we
  /// accepted as early as possible — independent of the full
  /// [acceptIncoming] flow (which needs `_active` seeded, joins the
  /// Stream media leg, and pushes the call page, ANY of which can be
  /// slow or get suspended on a locked cold-start). The backend
  /// re-broadcasts `call.accept` over STOMP so the CALLER stops ringing
  /// immediately. Fire-and-forget + idempotent (a second `/accept` is a
  /// no-op / harmless 400 on the server). iOS-only by caller; Android
  /// keeps the existing single accept inside [acceptIncoming].
  Future<void> notifyBackendAcceptEarly(String numericCallId) async {
    if (int.tryParse(numericCallId) == null) return;
    // ignore: avoid_print
    print('[CallSignaling] notifyBackendAcceptEarly → '
        'POST /chats/calls/$numericCallId/accept (early, decoupled)');
    try {
      await transport.sendCallAccept(numericCallId, accepterId: settings.userId);
    } catch (_) {/* best-effort — acceptIncoming retries the real POST */}
  }

  /// Slice 10.2.10 — Telegram-style call summary written to the conv's
  /// `lastMessage` so the inbox tile shows recent call history inline
  /// (no separate Calls tab required to know "Vibol called you 5 min
  /// ago"). Hooked into every end path: local hangup, peer hangup, and
  /// reject (both directions).
  Future<void> _writeCallSummary(
    ActiveCall active, {
    required ChatCallStatus finalStatus,
    required int durationSeconds,
  }) async {
    final isVideo = active.callType == ChatCallType.video;
    final emoji = isVideo ? '📹' : '📞';
    final kind = isVideo ? 'video' : 'voice';
    String body;
    switch (finalStatus) {
      case ChatCallStatus.answered:
        final m = (durationSeconds ~/ 60).toString().padLeft(1, '0');
        final s = (durationSeconds % 60).toString().padLeft(2, '0');
        body = '$emoji ${isVideo ? "Video" : "Voice"} call · $m:$s';
      case ChatCallStatus.missed:
      case ChatCallStatus.noAnswer:
        body = '$emoji Missed $kind call';
      case ChatCallStatus.rejected:
        body = '$emoji Declined $kind call';
    }
    // Slice 10.2.11 — for DIRECT calls, redirect the summary to our
    // own local direct conv with the peer (mirrors Slice 10.1.8 for
    // messages). The seed reuses ids like conv-005 across devices, so
    // writing the summary to active.conversationId on the callee
    // would land it in the WRONG local tile. For groups the conv id
    // is shared (via Slice 10.1.7 broadcast) and works as-is.
    String targetConvId = active.conversationId;
    if (!active.isGroup) {
      final me = settings.userId;
      // Find the OTHER party in this 1:1 call.
      final otherId =
          active.callerId == me ? active.peerId : active.callerId;
      final localConv = await conversations.findDirectWith(otherId);
      if (localConv != null) {
        targetConvId = localConv.id;
      }
    }
    try {
      // Use `callerId` as senderId so the inbox renders "You: 📞 …"
      // for the caller and the bare preview for the callee.
      await conversations.updateLastMessage(
        id: targetConvId,
        body: body,
        senderId: active.callerId,
        senderName: active.peerName,
        type: 'system',
        at: DateTime.now(),
      );
    } catch (_) {
      // Conv may not exist locally (e.g. seeded mismatch); swallow.
    }
  }

  /// Dismiss the CallKit-side notification for this call. Without
  /// this, the ongoing-call heads-up + tray entry that
  /// `_showStreamCallkitRinger` posted from the FCM BG handler stays
  /// visible after the call has ended — and on some OEMs that
  /// notification is what's keeping the foreground service alive,
  /// which in turn holds the mic open. The user perceives this as
  /// "still running in the background after the call ended."
  ///
  /// Best-effort: swallow errors (the entry may already be gone if
  /// the user tapped Hang Up on the notification itself, or the
  /// plugin's native side may not have a record of this id).
  Future<void> _dismissCallkitForActive(ActiveCall? active) async {
    final ids = <String>{};
    final cid = active?.streamCallCid;
    if (cid != null && cid.isNotEmpty) ids.add(cid);
    // The plugin uses the CID verbatim as the notification id (see
    // _showStreamCallkitRinger in firebase_notification_provider).
    for (final id in ids) {
      try {
        // iOS CallKit needs a UUID; `callkitIdForCid` maps the CID to the
        // same deterministic UUID the show path used (no-op on Android).
        final callkitId = callkitIdForCid(id);
        // ignore: avoid_print
        print('[CallSignaling] dismissing CallKit notification id=$id '
            '(callkitId=$callkitId)');
        await FlutterCallkitIncoming.endCall(callkitId);
      } catch (e) {
        // ignore: avoid_print
        print('[CallSignaling] endCall($id) failed (likely already '
            'gone): $e');
      }
    }
    // Belt-and-suspenders: also nuke any other lingering CallKit
    // entries for this app. Cheap and reliable; the user can only
    // ever be in one call at a time in our flow.
    try {
      await FlutterCallkitIncoming.endAllCalls();
    } catch (_) {/* swallow */}
  }

  // ── Outbound (this device is the caller) ─────────────────────

  /// Place a new call. Pre-creates a local `chat_call_log` entry
  /// (status: `noAnswer`) and broadcasts a `call.invite` envelope to
  /// the peer. Returns the new `callId` so the calling page can wait
  /// on state changes via [activeCall].
  Future<ActiveCall> startOutgoing({
    required String conversationId,
    required ChatCallType callType,
  }) async {
    // iOS: kick off the Stream client connect immediately so it runs in
    // parallel with the POST /calls round-trip below, instead of cold-
    // starting inside `join()` after the POST returns. Shaves the
    // token-fetch + WS-connect time off the tap→audio latency.
    // iOS-only; Android keeps its existing timing.
    if (Platform.isIOS) unawaited(streamEngine.warmUp());
    final conv = await conversations.findById(conversationId);
    final me = settings.userId;
    final myName = settings.userName;
    // Slice 10.2.7 — targeted call routing. Build the recipient list
    // from the conversation's participants so the relay only rings the
    // intended callee(s):
    //   * direct conv → the single other person (seeded in
    //     participantPreviews now that 10.2.7 needs that id)
    //   * group conv → every member except us
    // Empty list falls back to "ring everyone" so legacy convs that
    // never got a participantPreviews backfill still work.
    final targetIds = conv == null
        ? const <String>[]
        : conv.participantPreviews
            .where((p) => p.employeeId != me)
            .map((p) => p.employeeId)
            .toList(growable: false);

    // Peer hint for the local UI ("calling X…"). Direct convs use
    // the first (and only) participant; group convs fall back to the
    // conversation name.
    final peer = (conv != null &&
            !conv.isGroup &&
            conv.participantPreviews.isNotEmpty)
        ? _PeerHint(
            id: conv.participantPreviews.first.employeeId,
            name: conv.participantPreviews.first.name,
          )
        : (conv != null && conv.isGroup
            ? conv.participantPreviews
                .where((p) => p.employeeId != me)
                .map((p) => _PeerHint(id: p.employeeId, name: p.name))
                .firstOrNull
            : null);

    final now = DateTime.now();
    final callId = 'call-$me-${now.microsecondsSinceEpoch}';
    final logged = await callLog.logStart(
      conversationId: conversationId,
      callerId: me,
      callerName: myName,
      callType: callType,
      at: now,
    );
    _logIdByCallId[callId] = logged.id;

    final active = ActiveCall(
      callId: callId,
      conversationId: conversationId,
      peerId: peer?.id ?? 'peer-unknown',
      peerName: peer?.name ?? conv?.name ?? 'Unknown',
      callType: callType,
      state: CallSignalState.outgoingRinging,
      startedAt: now,
      callerId: me,
      conversationName: conv?.name,
      isGroup: conv?.isGroup ?? false,
      conversationAvatarFilePath: conv?.avatarFilePath,
    );
    // Slice 10.2.11 — fresh outgoing call, reset the joined-callees
    // set so leftovers from a prior call can't confuse the auto-end.
    _activeCallees.clear();
    _setActive(active);
    // Subscribe to the per-call topic so we (the caller) see every
    // callee's accept / reject / hangup. Idempotent.
    transport.subscribeConversation(conversationId);

    // POST /chats/conversations/{id}/calls and await the canonical
    // backend call id — then swap it in. The local placeholder
    // `call-<me>-<ts>` is a UUID stand-in for the period BETWEEN our
    // tap and the backend acknowledging; without the swap, the
    // caller's Accept/Reject/End buttons would call REST endpoints
    // with a non-numeric id and silently no-op (transport's
    // `int.tryParse` would fail). Fire-and-forget so the call page
    // can render the ringing UI immediately.
    unawaited(() async {
      Map<String, dynamic>? response;
      Object? lastError;
      try {
        response = await transport.sendCallInvite(
          callId: callId,
          conversationId: conversationId,
          callerId: me,
          callerName: myName,
          callType: callType,
          startedAt: now,
          targetIds: targetIds,
        );
      } catch (e) {
        lastError = e;
        // Auto-recover from stale RINGING/ANSWERED rows. Cause: a
        // previous call timed out / failed without the server-side
        // row being cleaned up (backend's own ring timer leaves rows
        // in inconsistent states, or B's app was force-killed
        // mid-call). We list the user's recent calls, end anything
        // still RINGING/ANSWERED, then retry the invite once.
        //
        // The backend can phrase this rejection a few different ways
        // depending on whether A or B has the stale row:
        //   * "already in an active call"        — A's row
        //   * "user is already in an active call" — B's row
        //   * "receiver is in another call"      — B's row, variant
        //   * "is on another call"               — generic variant
        // Match permissively on a small set of substrings — if the
        // message looks anything like a stale-call collision, run
        // the cleanup.
        final message = _extractBackendMessage(e);
        final isStaleCallError = message != null &&
            (() {
              final m = message.toLowerCase();
              return m.contains('already in an active call') ||
                  m.contains('already in a call') ||
                  m.contains('in another call') ||
                  m.contains('is in a call') ||
                  m.contains('on another call') ||
                  m.contains('busy');
            })();
        if (isStaleCallError) {
          // ignore: avoid_print
          print('[CallSignaling] stale-call rejection from backend '
              '("$message") — running auto-cleanup');
          final cleaned = await _endStaleActiveCalls();
          // ignore: avoid_print
          print('[CallSignaling] auto-cleanup ended $cleaned stale '
              'call row(s)');
          if (cleaned > 0) {
            try {
              response = await transport.sendCallInvite(
                callId: callId,
                conversationId: conversationId,
                callerId: me,
                callerName: myName,
                callType: callType,
                startedAt: now,
                targetIds: targetIds,
              );
              lastError = null;
              // ignore: avoid_print
              print('[CallSignaling] retry after cleanup succeeded');
            } catch (e2) {
              lastError = e2;
              // ignore: avoid_print
              print('[CallSignaling] retry after cleanup ALSO failed: '
                  '${_extractBackendMessage(e2) ?? e2}');
            }
          }
        }
      }

      // Failure path: roll back outgoingRinging → ended so the call
      // page pops itself.
      if (response == null) {
        final cur = _active;
        if (cur == null || cur.callId != callId) return;
        final message =
            lastError == null ? null : _extractBackendMessage(lastError);
        // Match the same set of "stale call" phrasings used above so
        // the snackbar tells the user the truth ("X is in another
        // call") even when the cleanup-and-retry path didn't recover.
        final reason = (message != null && (() {
          final m = message.toLowerCase();
          return m.contains('already in an active call') ||
              m.contains('already in a call') ||
              m.contains('in another call') ||
              m.contains('is in a call') ||
              m.contains('on another call') ||
              m.contains('busy');
        })())
            ? 'already_in_call'
            : 'failed';
        _setActive(cur.copyWith(
          state: CallSignalState.ended,
          endReason: reason,
        ));
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_active?.callId == callId &&
              _active?.state == CallSignalState.ended) {
            _setActive(null);
          }
        });
        return;
      }

      // Success path: swap the local placeholder callId for the
      // backend's canonical id, then bring the Stream media leg up.
      final backendCallId = response['id']?.toString() ?? '';
      final streamCallCid = response['streamCallCid'] as String?;
      if (backendCallId.isEmpty) return;
      final cur = _active;
      if (cur == null || cur.callId != callId) return;
      final logId = _logIdByCallId.remove(callId);
      if (logId != null) _logIdByCallId[backendCallId] = logId;
      _setActive(cur.copyWith(
        callId: backendCallId,
        streamCallCid: streamCallCid,
      ));
      if (streamCallCid != null && streamCallCid.isNotEmpty) {
        // The Stream call members MUST include the callee(s) — otherwise
        // Stream rejects their `call.accept()` with "Only members can
        // reject or accept a call" (HTTP 400) and the media leg never
        // comes up (symptom: call connects in the UI but there's no
        // audio). The local `targetIds` (from the conversation's
        // `participantPreviews`) is empty for backend conversations whose
        // previews weren't hydrated, so on iOS we prefer the BACKEND's
        // authoritative participant list from the invite response
        // (`[{userId: 9}, {userId: 10}]`), excluding ourselves. Falls
        // back to `targetIds` when the response carries no participants.
        // iOS-only — Android's working member list is left as-is.
        var streamMemberIds = targetIds;
        if (Platform.isIOS) {
          final parts = response['participants'];
          if (parts is List) {
            final ids = parts
                .whereType<Map>()
                .map((p) => p['userId']?.toString() ?? '')
                .where((id) => id.isNotEmpty && id != me)
                .toList(growable: false);
            if (ids.isNotEmpty) streamMemberIds = ids;
          }
          // ignore: avoid_print
          print('[CallSignaling] Stream members (iOS) → $streamMemberIds '
              '(targetIds was $targetIds)');
        }
        // The RING (the VoIP push that lights the native CallKit incoming
        // screen on a minimized/killed callee) is fired SERVER-SIDE by our
        // backend now: `POST /chats/conversations/{id}/calls` does a Stream
        // `getOrCreate(ring: true, members: [...])`. So the mobile client
        // must NOT ring again — it only JOINS the already-created call for
        // media.
        //
        // iOS (`shouldRing: false`): a client-side `ringing:true` puts the
        // caller's `call.join()` into the "ringing flow", which WAITS for
        // the accept and then cancels itself (`VideoError{connect
        // cancelled}`) → caller never enters the SFU → no audio. Joining
        // ring-free avoids that AND avoids double-ringing the callee on top
        // of the backend push. `getOrCreate(ringing:false)` here is a plain
        // GET of the existing backend-created call — it does NOT cancel the
        // server-side ring (ring is a one-shot at create; a later get with
        // ringing:false doesn't tear down members already in `ringing`).
        //
        // Android now ALSO joins ring-free. With the backend firing the
        // Stream ring (`getOrCreate(ring:true, members)`) for every member,
        // the client-side `ringing:true` was redundant AND actively broke
        // the caller's audio: device logs showed the Android caller's
        // `call.join()` cancelling itself with `VideoError{connect
        // cancelled}` (the same "ringing flow" race iOS already avoided) —
        // so the caller never entered the SFU and the callee heard silence.
        // Hardcoding `false` switches Android off too; iOS already resolved
        // `!Platform.isIOS` to false, so this is an Android-only change with
        // no iOS impact.
        //
        // `isOutgoing:true` keeps the caller's peer-joined fallback listener
        // attached despite shouldRing:false.
        unawaited(streamEngine.join(
          streamCallCid: streamCallCid,
          isVideo: callType == ChatCallType.video,
          calleeUserIds: streamMemberIds,
          shouldRing: false,
          isOutgoing: true,
        ));
      }
    }());
    return active;
  }

  /// Bridge from Stream's `state.incomingCall` (foreground WebSocket
  /// ring path) into the same handler the FCM-push (background path)
  /// uses. Reformats the Stream [Call] into the canonical map shape
  /// `handleIncomingFromPush` expects.
  ///
  /// The caller's display name comes from Stream's `createdBy` field
  /// (populated when the caller's app built its `StreamVideo` client
  /// with `User.regular(name: …)` — that's why we wired display names
  /// through earlier).
  ///
  /// `conversationId` is best-effort: pulled from Stream's `custom`
  /// map if the caller's `getOrCreate` included it, else falls back
  /// to the call's CID id so the existing overlay at least renders.
  /// Fired when Stream's WS signals the active call has ended — peer
  /// hung up, caller withdrew before we answered, network dropped on
  /// the far side. Mirrors the local hangup path so the overlay /
  /// call page pops without waiting for the user.
  ///
  /// Idempotent — guarded on whether we still have an `_active` call
  /// (the local end path may have already torn it down).
  /// Fallback path for A's UI: Stream's media layer has just observed
  /// a remote participant joining our call. That means B accepted on
  /// their device (either through the chat ceremony or via the
  /// Stream-only fallback in [acceptIncoming]). Flip our local state
  /// from `outgoingRinging` → `connected` so the call page replaces
  /// "Calling…" with the timer + waveform — without waiting for the
  /// chat backend's `call.accept` STOMP broadcast, which may never
  /// arrive if the backend's own ring timer fired first.
  void _handleStreamPeerJoined() {
    final active = _active;
    if (active == null) return;
    // Only act on the caller-side ringing transition. If we're already
    // connected, idle, or in some other state, this event is either
    // late or stale and should be ignored.
    if (active.state != CallSignalState.outgoingRinging) return;
    if (kDebugMode) {
      debugPrint('[CallSignaling] Stream peer joined — flipping '
          '${active.callId} from outgoingRinging → connected');
    }
    final connectedAt = DateTime.now();
    final logId = _logIdByCallId[active.callId];
    if (logId != null) unawaited(callLog.logAnswered(logId));
    _setActive(active.copyWith(
      state: CallSignalState.connected,
      connectedAt: connectedAt,
    ));
  }

  void _handleStreamCallEnded(StreamCallEndReason reason) {
    final active = _active;
    // ignore: avoid_print
    print('[CallSignaling] _handleStreamCallEnded called — reason=$reason '
        'active=${active?.callId} state=${active?.state} '
        'connectedAt=${active?.connectedAt} '
        'age=${active?.connectedAt == null ? "n/a" : "${DateTime.now().difference(active!.connectedAt!).inMilliseconds}ms"}');
    // Guard against spurious "ended" events firing within the first
    // 2 seconds of a freshly-connected call. Stream's SDK sometimes
    // emits a transient Disconnected status during initial media
    // setup (PeerConnection negotiation, ICE candidate exchange) that
    // self-recovers — if we react to it we tear the call down within
    // milliseconds of the user successfully tapping Accept, and they
    // see the call page mount and immediately pop.
    //
    // CRITICAL: the settle window applies ONLY to the possibly-transient
    // `disconnected` reason. The DEFINITIVE reasons (a remote peer truly
    // left, reconnection permanently failed, the caller withdrew the
    // ring) never self-recover and must tear the call down immediately —
    // even inside the 2 s window. Blanket-guarding all reasons was the
    // LOCK-SCREEN bug: B accepts from the lock screen, A hangs up within
    // the settle window, Stream fires a definitive `remoteLeft`, and the
    // guard wrongly swallowed it → B stuck on Connected. When the STOMP
    // `call.hangup` was missed (socket torn down while locked) this was
    // the only end-signal left, so swallowing it stranded B forever.
    if (reason == StreamCallEndReason.disconnected &&
        active != null &&
        active.state == CallSignalState.connected &&
        active.connectedAt != null) {
      final ageMs =
          DateTime.now().difference(active.connectedAt!).inMilliseconds;
      if (ageMs < 2000) {
        // ignore: avoid_print
        print('[CallSignaling] _handleStreamCallEnded IGNORED — call '
            'is only ${ageMs}ms old (under 2 s settle window) and reason '
            'is transient `disconnected`; not a real hangup');
        return;
      }
    }
    // CRITICAL: also tear down the engine's _activeCall so its
    // `hasPendingIncoming` / active-call guard doesn't leak into the
    // next call. Symptom of the leak: minimize after a call would log
    // "disconnectForBackground: skipped (active call in flight)" even
    // though no call was actually live → Stream's WS stayed up →
    // Stream treated B as online → next ring went over WS (where the
    // overlay can't render while backgrounded) → A's call timed out
    // as a "missed call".
    // Use endActiveCall (bumps _callSeq) not leave — a terminal end must
    // ABORT any in-flight acceptByCid retry loop, otherwise that loop can
    // re-join the media AFTER teardown and create a ghost Stream call with
    // no signaling state (the second "stuck Connected" we hit).
    unawaited(streamEngine.endActiveCall());

    if (active == null) return;
    // Sweep ALL call notifications — Stream just tore the media leg down,
    // so its ongoing-call notification (and any leftover ring) must go too
    // or it lingers as a phantom "Connected" on the lock screen.
    _clearNativeIncoming(active.callId);
    _clearAllCallNotifications();
    // Flip to "ended" so listening UI pops. The voice/video pages
    // already watch this transition (Slice 10.2.4 — endReason).
    _setActive(active.copyWith(
      state: CallSignalState.ended,
      endReason: 'hangup',
    ));
    // Clear after a short delay so the snackbar / page-pop animation
    // gets a chance to run, same pattern as the local hangup path.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_active?.callId == active.callId &&
          _active?.state == CallSignalState.ended) {
        _setActive(null);
      }
    });
    // Drop the call-log mapping so the next call doesn't inherit it.
    final logId = _logIdByCallId.remove(active.callId);
    if (logId != null) {
      unawaited(callLog.logEnded(
        id: logId,
        durationSeconds: active.connectedAt == null
            ? 0
            : DateTime.now().difference(active.connectedAt!).inSeconds,
        finalStatus: active.connectedAt == null
            ? ChatCallStatus.missed
            : ChatCallStatus.answered,
      ));
    }
    // CRITICAL (case #4: "after an ANSWERED call ends, the next call to a
    // killed+locked callee shows no ring"). When B accepts from a locked
    // screen the accept connected B's Stream WS on demand (via _ensureClient)
    // — and when B was locked the STOMP socket was down, so the ONLY signal
    // that A hung up is Stream's remote-left, which lands HERE. The peer-
    // hangup path (`_finishPeerHangup`) already re-arms the apn ring route,
    // but this Stream-side teardown did NOT — so B was left ONLINE to Stream
    // and the NEXT call rang over the (invisible-while-backgrounded) WS
    // instead of the VoIP push. Re-arm here too: drop the Stream WS + STOMP +
    // report OFFLINE so the next call rings via apn. No-op when foreground or
    // still connected (see goOfflineForPushIfBackground).
    unawaited(goOfflineForPushIfBackground());
  }

  Future<void> _handleStreamIncomingCall(Call call) async {
    final state = call.state.valueOrNull;
    final createdBy = state?.createdByUser;
    final callerId = createdBy?.id ?? '';

    // ── Caller display name resolution ───────────────────────────
    // Prefer Stream's createdByUser.name (set when the caller's
    // StreamVideo client was built with User.regular(name: …)). If
    // empty (race: A's UsersCache wasn't populated when A's client
    // was built), fall back to OUR local UsersCache which was
    // hydrated by /users on this device. Last resort: use the id.
    String callerName = (createdBy != null && createdBy.name.isNotEmpty)
        ? createdBy.name
        : '';
    if (callerName.isEmpty) {
      callerName = UsersCache.instance.nameOf(callerId) ?? callerId;
    }

    // ── Backend call id resolution ───────────────────────────────
    // The Accept / Reject buttons POST to `/chats/calls/{id}/{action}`
    // which expects the BACKEND's numeric call id (e.g. "42"), NOT
    // Stream's call id (e.g. "erp-call-42"). Three paths, first wins:
    //   1. custom['backendCallId'] — caller-set, cleanest.
    //   2. Parse "erp-call-<digits>" prefix off call.id.
    //   3. Fall back to call.id verbatim (will 404 but the call ends
    //      cleanly via the existing failure path).
    final custom = state?.custom ?? const <String, Object?>{};
    String backendCallId = custom['backendCallId']?.toString() ?? '';
    if (backendCallId.isEmpty) {
      final match = RegExp(r'^(?:erp-call-)?(\d+)').firstMatch(call.id);
      backendCallId = match?.group(1) ?? call.id;
    }

    // ── Conversation id resolution ───────────────────────────────
    // The call page renders peer name + avatar from the LOCAL
    // conversation entity (`ConversationsRepository.watchById`). So
    // the payload's `conversationId` must be a real LOCAL conv id,
    // otherwise the lookup misses and the page shows nothing.
    //
    // Priority:
    //   1. custom['conversationId'] — backend-set (correct).
    //   2. Look up the direct conv with the caller by userId — this
    //      handles every 1:1 call even when the backend didn't set
    //      custom data.
    //   3. Fall back to call.id (broken but at least the call
    //      ceremony works).
    String conversationId = custom['conversationId']?.toString() ?? '';
    if (conversationId.isEmpty) {
      final directConv = await conversations.findDirectWith(callerId);
      if (directConv != null) {
        conversationId = directConv.id;
      }
    }
    if (conversationId.isEmpty) {
      conversationId = call.id;
    }

    final isVideo = state?.callType.value == 'video';
    final payload = <String, dynamic>{
      'type': 'call.invite',
      'callId': backendCallId,
      'conversationId': conversationId,
      'callerId': callerId,
      'callerName': callerName,
      'callType': isVideo ? 'video' : 'voice',
      'startedAt': DateTime.now().toUtc().toIso8601String(),
      'streamCallCid': call.callCid.value,
    };
    if (kDebugMode) {
      debugPrint('[CallSignaling] Stream incoming bridged → '
          'caller="$callerName" ($callerId) · '
          'backendCallId=$backendCallId · '
          'convId=$conversationId (resolved from ${call.id})');
    }
    await handleIncomingFromPush(payload);
  }

  /// Seed `_active` from an FCM `call.invite` push payload — used when
  /// the app was minimized or killed and missed the matching STOMP
  /// envelope. Once `_active` is set to `incomingRinging`, the existing
  /// [acceptIncoming] / [rejectIncoming] paths and the in-app
  /// `IncomingCallOverlay` all work identically to the WS path.
  ///
  /// Expected payload (matches `docs/FCM_BACKGROUND_CALLS_PLAN.md`):
  /// ```json
  /// { "type": "call.invite",
  ///   "callId": "...",
  ///   "conversationId": "...",
  ///   "callerId": "...",
  ///   "callerName": "...",
  ///   "callType": "voice" | "video",
  ///   "startedAt": "<ISO-8601>",
  ///   "streamCallCid": "default:..." }
  /// ```
  ///
  /// Idempotent: if `_active` is already set to the same callId (the
  /// WS event raced ahead of the push), this is a no-op so the user
  /// doesn't see the incoming sheet flash twice.
  Future<void> handleIncomingFromPush(Map<String, dynamic> data) async {
    if (data['type'] != 'call.invite') return;
    final callId = data['callId']?.toString();
    final conversationId = data['conversationId']?.toString();
    final callerId = data['callerId']?.toString();
    final callerName = data['callerName']?.toString() ?? 'Unknown';
    if (callId == null || conversationId == null || callerId == null) return;

    _diagCallkitRegistry('push-invite-$callId');

    // Race-window dedupe — WS may have already delivered the same
    // invite by the time the user taps the notification.
    if (_active?.callId == callId) return;

    // Busy: already in a non-pending call. Surface the busy reason to
    // the caller; do NOT replace our own state.
    if (_active != null &&
        _active!.state != CallSignalState.incomingRinging &&
        _active!.state != CallSignalState.ended) {
      transport.sendCallReject(callId, reason: 'busy');
      return;
    }

    final callType = data['callType']?.toString() == 'video'
        ? ChatCallType.video
        : ChatCallType.voice;
    final startedAt =
        DateTime.tryParse(data['startedAt']?.toString() ?? '')?.toUtc() ??
            DateTime.now().toUtc();
    final streamCallCid = data['streamCallCid']?.toString();

    // Log a missed-by-default row so the inbox tile / call history
    // reflects the call attempt even if the user never opens it.
    final logged = await callLog.logStart(
      conversationId: conversationId,
      callerId: callerId,
      callerName: callerName,
      callType: callType,
      at: startedAt,
    );
    _logIdByCallId[callId] = logged.id;

    final conv = await conversations.findById(conversationId);
    _setActive(ActiveCall(
      callId: callId,
      conversationId: conversationId,
      peerId: callerId,
      peerName: callerName,
      callType: callType,
      state: CallSignalState.incomingRinging,
      startedAt: startedAt,
      callerId: callerId,
      conversationName: conv?.name,
      isGroup: conv?.isGroup ?? false,
      conversationAvatarFilePath: conv?.avatarFilePath,
      streamCallCid: streamCallCid,
    ));
    // Subscribe so the matching `call.hangup` / `call.accept` frames
    // that arrive AFTER reconnect land on this service instead of
    // disappearing into the void.
    transport.subscribeConversation(conversationId);
    // iOS: pre-connect the Stream client AND pre-`getOrCreate` the call
    // WHILE the phone is ringing, so neither the WS connect nor the
    // coordinator round-trip sits on the accept→audio critical path —
    // only the final SFU media connect happens on accept. Idempotent &
    // best-effort; Android keeps its existing timing.
    if (Platform.isIOS) {
      unawaited(streamEngine.warmUp());
      unawaited(_prepareIncomingStream(callId, callType));
      // If we're foreground, kill the native CallKit screen Stream's VoIP
      // push raises (the in-app overlay is the ring here). No-op if bg.
      _suppressForegroundCallkit(callId);
    }
  }

  /// iOS-only: while an incoming call is ringing, pre-establish its
  /// Stream media leg so the accept→audio path only has to do the final
  /// SFU connect. The `call.invite` arrives with `streamCallCid == null`,
  /// so we fetch the canonical call (`GET /chats/calls/{id}`) to learn
  /// the cid, stamp it onto `_active` (so accept can use it directly),
  /// then ask the engine to `getOrCreate` it without joining. Entirely
  /// best-effort — any failure just falls back to the normal accept path.
  Future<void> _prepareIncomingStream(String callId, ChatCallType type) async {
    if (!Platform.isIOS) return;
    final n = int.tryParse(callId);
    if (n == null) return;
    String? cid;
    try {
      final dto = await remote.getCall(n);
      cid = dto['streamCallCid'] as String?;
    } catch (_) {
      return;
    }
    if (cid == null || cid.isEmpty) return;
    // Stamp the cid onto the active call so [acceptIncoming] uses it
    // straight away (it was null on the invite).
    final cur = _active;
    if (cur != null && cur.callId == callId && cur.streamCallCid == null) {
      _setActive(cur.copyWith(streamCallCid: cid));
    }
    await streamEngine.prepareIncoming(
      streamCallCid: cid,
      isVideo: type == ChatCallType.video,
    );
  }

  /// Best-effort cleanup of stale `RINGING` / `ANSWERED` call rows on
  /// the server for the current user. Called automatically when
  /// `startOutgoing` catches "already in an active call" — most of
  /// the time those rows are orphans from a previous test where the
  /// backend's ring timer left the row in an inconsistent state.
  ///
  /// Lists the user's most recent calls (page 1, up to 20), POSTs
  /// `endCall` on anything still RINGING/ANSWERED, and returns the
  /// number of rows successfully ended. Failures per-row are
  /// swallowed so a single 404 doesn't block the rest. Returns 0
  /// when the list endpoint itself fails — the caller will treat
  /// that as "nothing to recover" and surface the original error.
  Future<int> _endStaleActiveCalls() async {
    final Map<String, dynamic> page;
    try {
      page = await remote.listCalls(page: 1, pageSize: 20);
    } catch (e) {
      // ignore: avoid_print
      print('[CallSignaling] _endStaleActiveCalls listCalls failed: $e');
      return 0;
    }
    // The backend's pagination envelope can nest the array under
    // different keys depending on the endpoint version. Try the most
    // common shapes in order:
    //   * { items: [...] }    — Spring data page wrapper
    //   * { content: [...] }  — Spring data page (Pageable)
    //   * { data: [...] }     — ApiEnvelope wrapper kept literal
    //   * [...] directly      — when ApiEnvelope unwrapped already
    List? items;
    for (final key in ['items', 'content', 'data', 'rows', 'results']) {
      final v = page[key];
      if (v is List) {
        items = v;
        break;
      }
    }
    // ignore: avoid_print
    print('[CallSignaling] listCalls response keys=${page.keys.toList()} · '
        'resolved items=${items?.length ?? "none"}');
    if (items == null || items.isEmpty) return 0;
    int ended = 0;
    for (final item in items) {
      if (item is! Map) continue;
      final status = (item['status']?.toString() ?? '').toUpperCase();
      if (status != 'RINGING' && status != 'ANSWERED') continue;
      final id = int.tryParse(item['id']?.toString() ?? '');
      if (id == null) continue;
      try {
        await remote.endCall(id);
        ended++;
        // ignore: avoid_print
        print('[CallSignaling] auto-ended stale call $id (was $status)');
      } catch (e) {
        // ignore: avoid_print
        print('[CallSignaling] failed to end stale call $id: $e');
      }
    }
    return ended;
  }

  /// Recover the REAL currently-ringing call for THIS user from the backend.
  ///
  /// Used by the locked/killed accept path when the native CallKit payload is
  /// UUID-only — Stream's VoIP push presents the CallKit call, so no
  /// `extra.callCid` reaches us, and parsing the bare UUID would mis-read its
  /// leading hex as a stale numeric call id (POST /accept to a long-dead call
  /// → caller stuck "Calling…"). This asks the authoritative backend instead:
  /// list the recent calls, pick the newest RINGING one whose caller isn't us,
  /// and return its real `{callId, streamCallCid}`. Returns null if nothing is
  /// ringing (a stale CallKit notification) so the caller can abort safely.
  Future<({String callId, String? streamCallCid})?>
      recoverRingingInviteFromBackend() async {
    final Map<String, dynamic> page;
    try {
      page = await remote.listCalls(page: 1, pageSize: 20);
    } catch (e) {
      // ignore: avoid_print
      print('[CallSignaling] recoverRingingInvite · listCalls failed: $e');
      return null;
    }
    List? items;
    for (final key in ['items', 'content', 'data', 'rows', 'results']) {
      final v = page[key];
      if (v is List) {
        items = v;
        break;
      }
    }
    if (items == null || items.isEmpty) return null;
    Map? best;
    DateTime? bestAt;
    for (final item in items) {
      if (item is! Map) continue;
      if ((item['status']?.toString() ?? '').toUpperCase() != 'RINGING') {
        continue;
      }
      // Skip our OWN outgoing call — we want the one someone is calling US on.
      if ((item['callerId']?.toString() ?? '') == settings.userId) continue;
      final started = DateTime.tryParse(item['startedAt']?.toString() ?? '');
      if (bestAt == null ||
          (started != null && started.isAfter(bestAt))) {
        best = item;
        bestAt = started ?? DateTime.now();
      }
    }
    if (best == null) {
      // ignore: avoid_print
      print('[CallSignaling] recoverRingingInvite · no RINGING call for me '
          '(stale CallKit notification)');
      return null;
    }
    final id = best['id']?.toString() ?? '';
    if (id.isEmpty) return null;
    final cid = best['streamCallCid']?.toString();
    // ignore: avoid_print
    print('[CallSignaling] recoverRingingInvite · found ringing call id=$id '
        'cid=$cid');
    return (
      callId: id,
      streamCallCid: (cid == null || cid.isEmpty) ? null : cid,
    );
  }

  /// Pull the human-readable `message` out of a DioException body
  /// (the backend's standard envelope is `{success, message, …}`).
  /// Returns null if the error isn't a DioException with a JSON body.
  static String? _extractBackendMessage(Object e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['message'] is String) return data['message'] as String;
    } catch (_) {}
    return null;
  }

  /// Outgoing call: peer either rejected or we cancelled before they
  /// answered. Send hangup, log as `rejected`/`noAnswer`, drop state.
  /// Same call used by both sides when they tap End — the canonical
  /// "this call is over now".
  Future<void> hangup({
    ChatCallStatus finalStatus = ChatCallStatus.answered,
  }) async {
    final active = _active;
    if (active == null) return;
    final endedAt = DateTime.now();
    // iOS: when WE abandon an UNANSWERED outgoing call, cancel the Stream
    // ring for EVERYONE so the callee's device is actually told the call is
    // over. A plain leave() only drops our own leg — a callee that is
    // minimized / killed and ringing via native CallKit has its STOMP +
    // Stream WS down, so it never sees our `call.hangup` and the ring
    // lingers until Stream's ~30 s timeout (the reported "D's ring won't
    // end" bug). reject(cancel) makes Stream's coordinator broadcast the
    // cancellation, which dismisses the callee's CallKit with no extra
    // push. Only for a still-ringing outgoing call; answered / connected
    // calls keep the normal teardown (the peer is genuinely in the media
    // leg). iOS-only, additive — Android's path is unchanged.
    if (Platform.isIOS &&
        active.state == CallSignalState.outgoingRinging) {
      unawaited(streamEngine.cancelOutgoingRing());
    }
    // Slice 10.2.10 — tag the hangup with our own id so group-call
    // peers can tell whether to end the call for everyone (caller
    // bowed out) or just ignore (one of N callees left, group call
    // continues).
    transport.sendCallHangup(
      active.callId,
      hangerUpperId: settings.userId,
    );
    final duration = active.connectedAt == null
        ? 0
        : endedAt.difference(active.connectedAt!).inSeconds;
    final logId = _logIdByCallId.remove(active.callId);
    final resolvedStatus =
        duration > 0 ? ChatCallStatus.answered : finalStatus;
    if (logId != null) {
      await callLog.logEnded(
        id: logId,
        durationSeconds: duration,
        finalStatus: resolvedStatus,
      );
    }
    // Slice 10.2.10 — surface the call summary on the inbox tile.
    unawaited(_writeCallSummary(
      active,
      finalStatus: resolvedStatus,
      durationSeconds: duration,
    ));
    // The call is over — sweep our ring + Stream's ongoing-call
    // notification so neither lingers as a phantom "Connected" on the
    // lock screen.
    _clearNativeIncoming(active.callId);
    _clearAllCallNotifications();
    _setActive(active.copyWith(state: CallSignalState.ended));
    // DIAGNOSTIC: confirm the registry is empty after the clears so a
    // following call #2 can ring. If call #1's entry lingers here it's the
    // "second call shows no ring (minimized)" suspect.
    Future.delayed(const Duration(milliseconds: 400),
        () => _diagCallkitRegistry('after-hangup-${active.callId}'));
    // Drop the active reference after a brief delay so the call page
    // can render the "ended" state before it pops itself.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_active?.callId == active.callId &&
          _active?.state == CallSignalState.ended) {
        _setActive(null);
      }
    });
    // We ended an answered/outgoing call while possibly backgrounded (e.g. B
    // tapped End on the native CallKit screen from a locked phone). The accept
    // had connected the Stream WS on demand, so re-arm the apn ring route for
    // the NEXT call — same fix as the peer-hangup + Stream-ended paths. No-op
    // when foreground or while a call is still connected.
    unawaited(goOfflineForPushIfBackground());
  }

  /// Clear any native incoming-call heads-up showing on THIS device for
  /// [callId]. Covers our own `erp_callkit` notification (the Android
  /// killed/background ring shown from the FCM isolate) AND any
  /// flutter_callkit_incoming ringer. Safe no-op when nothing is
  /// showing — used when a peer hang-up / reject means an unanswered
  /// ring on this device must disappear (fixes: A ends the call but B's
  /// heads-up stays on screen).
  /// Native bridge to forcibly dismiss the iOS CallKit incoming screen via
  /// `CXProvider.reportCall(with:endedAt:reason:)`. `flutter_callkit_incoming`
  /// only exposes `endCall`/`endAllCalls`, which issue a `CXEndCallAction`
  /// transaction — and that does NOT tear down a PushKit-reported incoming
  /// call's UI (verified on-device: the transaction "succeeds" but the ring
  /// header stays). `reportCall(endedAt:)` does. Implemented in
  /// `ios/Runner/AppDelegate.swift`.
  static const MethodChannel _iosCallkit = MethodChannel('erp/ios_callkit');

  /// When WE last programmatically dismissed the native CallKit screen
  /// (`_clearNativeIncoming` → `reportCall(endedAt:)`). That dismiss makes the
  /// iOS `CXCall` transition to `hasEnded` — the SAME signal the native End
  /// bridge (AppDelegate → `incomingCallEnded`) uses to detect a user tapping
  /// End. Without distinguishing them, dismissing the native screen in the
  /// foreground/unlocked case (to reveal the in-app UI) would be mistaken for
  /// a hang-up and tear the live call down. `_handleNativeCallEnded` consults
  /// [recentlyDismissedNativeCallkit] to ignore that self-induced end. iOS-only.
  DateTime? _lastNativeDismissAt;

  /// True if we dismissed the native CallKit ourselves within the last few
  /// seconds (so a resulting `hasEnded` is OUR dismiss, not a user End tap).
  bool recentlyDismissedNativeCallkit() {
    final t = _lastNativeDismissAt;
    return t != null &&
        DateTime.now().difference(t) < const Duration(seconds: 4);
  }

  void _clearNativeIncoming(String callId) {
    _lastNativeDismissAt = DateTime.now();
    if (callId.isNotEmpty) {
      unawaited(ErpCallKit.dismiss(callId).catchError((Object _) {}));
    }
    unawaited(Future(() async {
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (_) {/* swallow */}
    }));
    // iOS: endAllCalls (CXEndCallAction) can't dismiss a PushKit incoming
    // screen — go through reportCall(endedAt:) in native code.
    if (Platform.isIOS) {
      unawaited(
        _iosCallkit
            .invokeMethod<dynamic>('dismissIncoming')
            .catchError((Object _) => null),
      );
    }
  }

  /// Public hook for the foreground in-app `IncomingCallOverlay`: when the
  /// full-screen incoming sheet takes over a ringing call, clear the
  /// native heads-up notification for the same call so the user doesn't
  /// see BOTH the notification header AND the full-screen sheet at once.
  void clearNativeIncoming(String callId) => _clearNativeIncoming(callId);

  /// Lock-aware variant of [clearNativeIncoming] for the in-app
  /// `IncomingCallOverlay`. The overlay's "sheet takes over → hide the
  /// native ring" only makes sense when the in-app sheet is actually
  /// VISIBLE — i.e. the device is UNLOCKED. On a LOCKED screen the in-app
  /// sheet is hidden behind the keyguard and the native CallKit screen is
  /// the ONLY call UI iOS permits there; dismissing it drops the user to the
  /// bare lock wallpaper while the call connects (the reported
  /// "killed+locked accept → lock wallpaper" bug). So when locked we KEEP
  /// the native CallKit. Mirrors the lock gate already used by
  /// [_suppressForegroundCallkit]. On Android / unlocked iOS this behaves
  /// exactly like [clearNativeIncoming] (`_deviceUnlocked` returns true).
  Future<void> clearNativeIncomingIfUnlocked(String callId) async {
    // Android (and any non-iOS): no lock-screen CallKit concept here — the
    // in-app sheet always replaces the native ring, exactly as the old
    // unconditional `clearNativeIncoming` did. Dismiss immediately.
    if (!Platform.isIOS) {
      _clearNativeIncoming(callId);
      return;
    }
    // iOS: dismiss ONLY when the app is genuinely FOREGROUND — i.e. the in-app
    // sheet is actually visible and should replace the native ring. Every
    // not-foreground accept keeps the native CallKit screen, which is the
    // call UI the user sees there:
    //   • killed + not locked (case 1) → keep native screen,
    //   • killed + locked (case 2)     → keep native screen,
    //   • minimized (alive, bg)        → keep native; the app resumes and the
    //     in-app screen shows over it (native becomes the green pill).
    // Foreground is the reliable signal (native `isAppForeground`, set only on
    // a real didBecomeActive) — lock state was only ever a proxy for it and
    // misread during the cold-start launch transient. Poll briefly: if iOS
    // does bring the app forward, the flag flips true and we dismiss then;
    // otherwise we never dismiss and the native screen stays. Unknown/channel-
    // not-ready ⇒ NOT foreground ⇒ keep native (safe). 20 × 150 ms ≈ 3 s.
    for (var i = 0; i < 20; i++) {
      if (await _appForeground()) {
        _clearNativeIncoming(callId);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    // ignore: avoid_print
    print('[CallSignaling] clearNativeIncomingIfUnlocked · app never came to '
        'foreground in the poll window — keeping native CallKit screen · '
        'callId=$callId');
  }

  /// iOS foreground-only: aggressively dismiss any native CallKit incoming
  /// screen for [callId]. On iOS the CallKit screen for a foreground call
  /// is shown by Stream's VoIP-push manager via `reportNewIncomingCall`
  /// — which does NOT emit `flutter_callkit_incoming`'s `actionCallIncoming`
  /// event, so the handler-side suppression never sees it — AND it arrives
  /// asynchronously, a beat after we set up the in-app overlay (worst on
  /// the FIRST call). A single dismiss races and misses it. So we sweep a
  /// handful of times over ~3 s to catch the late screen. No-op when the
  /// app is backgrounded/killed (there the native ring is exactly what we
  /// want). The resulting CallKit end events are ignored by
  /// `CallkitEventHandler` while foreground, so this can't reject the call.
  void _suppressForegroundCallkit(String callId) {
    if (!Platform.isIOS) return;
    // Keep dismissing the native CallKit incoming screen for as long as the
    // call is STILL ringing AND we're STILL foreground — not just a fixed
    // short burst. The screen is raised by Stream's server-side VoIP push,
    // which arrives over APNs — a SEPARATE channel from the STOMP invite
    // that triggers this call — so it can land several seconds late, after
    // any fixed-length sweep would have given up (that's the "foreground
    // still shows the header" bug once the backend started ringing every
    // member). Looping until the ring resolves guarantees a late header is
    // cleared within one tick.
    //
    // Stop conditions (re-checked every tick):
    //   • app backgrounded → STOP; there the native ring is exactly what we
    //     want (minimized/killed ring path).
    //   • call left `incomingRinging` (accepted / ended / replaced) → STOP;
    //     after connect we must not keep nuking CallKit (it would also kill
    //     a legit ongoing-call notification).
    //   • hard cap (~35 s, just past the ring timeout) → STOP, never loops
    //     forever.
    // `endAllCalls()` inside `_clearNativeIncoming` only touches native
    // CallKit, never the Flutter in-app overlay, so this is safe to repeat.
    const tick = Duration(milliseconds: 120);
    const maxTicks = 300; // ~36 s
    var n = 0;
    Future<void> sweep() async {
      final lc = WidgetsBinding.instance.lifecycleState;
      final backgrounded = lc == AppLifecycleState.paused ||
          lc == AppLifecycleState.hidden ||
          lc == AppLifecycleState.detached;
      final stillRinging = _active?.callId == callId &&
          _active?.state == CallSignalState.incomingRinging;
      // Unchanged baseline stop conditions — minimized (paused/hidden/
      // detached) keeps the native ring, and we stop once the ring resolves
      // or the cap is hit.
      if (backgrounded || !stillRinging || n >= maxTicks) return;
      n++;
      // Dismiss the native CallKit ONLY when the app is genuinely FOREGROUND
      // (native `isAppForeground`). The Flutter lifecycle above does NOT read
      // `paused` on a killed/locked VoIP cold-launch (it reads
      // inactive/resumed/null), so it can't be trusted to detect "not on
      // screen" — and dismissing there drops the user to a bare lock/home
      // screen with no in-app UI. The native foreground flag is the truth:
      // killed/locked/minimized all read false → we KEEP the native screen
      // (the only call UI the user sees there); a real foreground call reads
      // true → we dismiss so the in-app sheet replaces the native ring.
      final foreground = await _appForeground();
      if (foreground) {
        _clearNativeIncoming(callId);
      }
      Future.delayed(tick, sweep);
    }

    unawaited(sweep());
  }

  /// iOS genuine-foreground probe (native `isAppForeground` flag in
  /// AppDelegate). True ONLY when the app is really on screen (a real
  /// `didBecomeActive`), false for a killed/minimized/locked accept. We
  /// dismiss the native CallKit ONLY when this is true — i.e. when the in-app
  /// sheet is actually visible and should replace the native ring. Defaults to
  /// FALSE on non-iOS-error/channel-not-ready (the safe "keep native" answer:
  /// when we can't confirm we're on screen, leave the native call UI alone so
  /// a killed/locked accept never loses its only visible call screen).
  Future<bool> _appForeground() async {
    if (!Platform.isIOS) return true;
    try {
      final v = await _iosCallkit.invokeMethod<bool>('isAppForeground');
      return v ?? false;
    } catch (_) {
      return false;
    }
  }

  /// iOS device-unlock probe (native `isDeviceUnlocked` →
  /// `UIApplication.isProtectedDataAvailable` in AppDelegate). True when the
  /// device is unlocked, false once it locks. Used alongside [_appForeground]
  /// to decide whether the in-app overlay can actually be shown: after a
  /// lock-screen CallKit accept the app reads "foreground" yet the user can
  /// see nothing but the native call UI, so a still-LOCKED device must be
  /// treated as background for the "go offline for push" decision (case #4).
  /// Defaults to FALSE on channel error (the safe "treat as locked → go
  /// offline so the next call still rings via push" answer). Non-iOS → true.
  Future<bool> _deviceUnlocked() async {
    if (!Platform.isIOS) return true;
    try {
      final v = await _iosCallkit.invokeMethod<bool>('isDeviceUnlocked');
      return v ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Public trigger for the foreground CallKit-dismiss loop, callable from
  /// `CallkitEventHandler` when it sees the native incoming screen actually
  /// appear (`Event.actionCallIncoming`) — the one moment we KNOW CallKit is
  /// on screen, regardless of whether the STOMP/WS invite path already
  /// kicked the loop off.
  void suppressForegroundCallkitFor(String callId) =>
      _suppressForegroundCallkit(callId);

  /// iOS-only: deterministic fallback that dismisses the native CallKit ring
  /// when the CALLER cancels while THIS device is minimized.
  ///
  /// While minimized the device has NO live push channel to learn the call
  /// ended: STOMP and the Stream WebSocket are both disconnected, the `apn`
  /// VoIP route may be unregistered, and FCM may be off. But the app is still
  /// ALIVE (iOS background execution), so it can still hit the REST API. So we
  /// poll `GET /chats/calls/{id}` and, the moment the backend reports a
  /// terminal status (the caller's `/end` flips it to ENDED), dismiss the ring
  /// via the reliable native `reportCall(endedAt:)` path inside
  /// [_clearNativeIncoming]. Self-stopping: terminal status, the call resolving
  /// locally (accepted/ended), foregrounding, or a ~36 s cap (just past the
  /// ring timeout). Called by `CallkitEventHandler` when a native ring appears
  /// while backgrounded. iOS-only; never runs on Android.
  void watchBackgroundRingForCancel(String callId) {
    if (!Platform.isIOS) return;
    final n = int.tryParse(callId);
    if (n == null) return;
    const tick = Duration(seconds: 3);
    const maxTicks = 12; // ~36 s, just past the ring timeout
    var i = 0;
    Future<void> poll() async {
      if (i >= maxTicks) return;
      i++;
      // Stop once a foreground in-app call owns this (the overlay/STOMP path
      // took over) or the call already left ringing locally.
      final cur = _active;
      if (cur != null &&
          cur.callId == callId &&
          cur.state != CallSignalState.incomingRinging) {
        return;
      }
      String status = '';
      try {
        final dto = await remote.getCall(n);
        status = (dto['status'] ?? '').toString().toUpperCase();
      } catch (e) {
        // ignore: avoid_print
        print('[CallSignaling] bg-ring poll error for $callId: $e');
      }
      if (status == 'ENDED' ||
          status == 'MISSED' ||
          status == 'REJECTED' ||
          status == 'CANCELLED') {
        // ignore: avoid_print
        print('[CallSignaling] bg-ring poll: call $callId is $status — '
            'dismissing native CallKit ring');
        _clearNativeIncoming(callId);
        _clearAllCallNotifications();
        // Caller cancelled while we're backgrounded → re-arm the apn ring path
        // for the next call (esp. the killed-app cold-start case where STOMP +
        // the Stream WS came up). No-op when foreground.
        unawaited(goOfflineForPushIfBackground());
        if (_active?.callId == callId) {
          _setActive(_active!.copyWith(state: CallSignalState.ended));
          Future.delayed(const Duration(milliseconds: 600), () {
            if (_active?.callId == callId &&
                _active?.state == CallSignalState.ended) {
              _setActive(null);
            }
          });
        }
        return;
      }
      Future.delayed(tick, poll);
    }

    // ignore: avoid_print
    print('[CallSignaling] watchBackgroundRingForCancel($callId) — polling '
        'backend for caller-cancel while minimized');
    unawaited(poll());
  }

  /// TERMINAL-only notification sweep: the call is genuinely over, so wipe
  /// EVERY call notification off the screen — our own `erp_incoming_calls`
  /// ring AND the Stream SDK's `stream_call_*` ongoing-call notification.
  ///
  /// Distinct from [_clearNativeIncoming], which only cancels a single
  /// ringing call id and is also used MID-flow (overlay takeover). This
  /// must run ONLY when the call has ended — otherwise it would nuke the
  /// legitimate in-call notification of a live call.
  ///
  /// Fixes the reported "B still Connected" bug: on Samsung One UI a plain
  /// per-id cancel leaves the ongoing CallStyle / Stream notification
  /// pinned on the lock screen long after the call ended, so the user sees
  /// a phantom call. The native `dismissAllCalls` enumerates the app's own
  /// call notifications, demotes the sticky ongoing flag, and cancels them.
  void _clearAllCallNotifications() {
    unawaited(ErpCallKit.dismissAllCalls().catchError((Object _) {}));
    unawaited(Future(() async {
      try {
        await FlutterCallkitIncoming.endAllCalls();
      } catch (_) {/* swallow */}
    }));
  }

  /// DIAGNOSTIC (iOS only): dump the live CallKit registry. The leading
  /// suspect for "second call shows no ring (app minimized)" is a leftover
  /// CallKit entry from call #1 that was never released — iOS then refuses
  /// (or silently drops) the ring for call #2. Log this when an invite
  /// arrives (to see if call #1 is still present) and right after every end
  /// path (to see if our clears actually emptied the registry). Pure
  /// logging — no behaviour change. Remove once the cause is confirmed.
  void _diagCallkitRegistry(String tag) {
    if (!Platform.isIOS) return;
    unawaited(Future(() async {
      try {
        final calls = await FlutterCallkitIncoming.activeCalls();
        final list = calls is List ? calls : const <dynamic>[];
        final ids = list.map((c) {
          if (c is Map) {
            final extra = c['extra'];
            final cid = extra is Map ? extra['call_cid'] : '?';
            return '${c['id']}·cid=$cid·acc=${c['isAccepted']}';
          }
          return c.toString();
        }).toList();
        // ignore: avoid_print
        print('[CallkitRegistry/$tag] activeCalls=${list.length} · $ids');
      } catch (e) {
        // ignore: avoid_print
        print('[CallkitRegistry/$tag] activeCalls() threw: $e');
      }
    }));
  }

  /// GET /chats/calls/{id} — recover the canonical call state from
  /// the backend. Used when the app resumes from background and
  /// might have missed `call.accept` / `call.hangup` STOMP frames
  /// while disconnected (Slice 10.2.6 — `ChatLifecycleBridge` doesn't
  /// cover call-state recovery on its own).
  ///
  /// Applies whatever the server says onto our local [_active]:
  ///   * `status: ANSWERED`     → connected (start the timer)
  ///   * `status: REJECTED`     → ended with the server's `endReason`
  ///   * `status: ENDED`        → ended (closes the page)
  ///   * `status: MISSED`/`NO_ANSWER` → ended (closes the page)
  ///   * `status: RINGING`      → leave the local state alone — the
  ///     STOMP path will catch up; we don't downgrade `connected` back
  ///     to ringing.
  ///
  /// No-op when there's no active call, when the active call's id
  /// isn't a backend id (still local placeholder pre-`sendCallInvite`
  /// response), or when the GET fails.
  Future<void> reconcileActive() async {
    final active = _active;
    if (active == null) return;
    final n = int.tryParse(active.callId);
    if (n == null) return;
    Map<String, dynamic> dto;
    try {
      dto = await remote.getCall(n);
    } catch (_) {
      return;
    }
    final status = (dto['status'] as String? ?? '').toUpperCase();
    // Just-accepted grace: if our local state shows the call freshly
    // connected (< 5 s) but the backend says ENDED/MISSED/REJECTED,
    // trust our local state and the Stream media leg over the
    // backend's stale verdict. The chat backend's ring timer can
    // fire during a slow cold-start accept (Stream + WS handshake +
    // accept POST = 5–10 s), marking the row ENDED before our accept
    // lands. reconcileActive would then re-import that stale ENDED
    // status and pop our just-mounted call page. Skip in that
    // window if Stream media is alive — the call is real.
    final isTerminal = status == 'ENDED' ||
        status == 'MISSED' ||
        status == 'NO_ANSWER' ||
        status == 'REJECTED';
    if (isTerminal &&
        active.state == CallSignalState.connected &&
        active.connectedAt != null) {
      final connectedMs =
          DateTime.now().difference(active.connectedAt!).inMilliseconds;
      final streamMediaAlive = streamEngine.callNotifier.value != null;
      if (connectedMs < 5000 && streamMediaAlive) {
        // ignore: avoid_print
        print('[CallSignaling] reconcileActive IGNORED backend $status — '
            'call only ${connectedMs}ms old, Stream media is alive — '
            'trusting local connected state over stale backend verdict');
        return;
      }
    }
    switch (status) {
      case 'ANSWERED':
        // Already connected locally? leave the timer running.
        if (active.state == CallSignalState.connected) return;
        final answeredAt = DateTime.tryParse(
                dto['answeredAt'] as String? ?? '') ??
            DateTime.now();
        _setActive(active.copyWith(
          state: CallSignalState.connected,
          connectedAt: answeredAt,
        ));
      case 'REJECTED':
        final reason = dto['endReason'] as String? ?? 'declined';
        // Full teardown — the backend says this call is over, so release
        // the media leg + sweep call notifications (the heartbeat path
        // relies on this to actually end a stuck call, not just flip the
        // local flag).
        unawaited(streamEngine.endActiveCall());
        _clearNativeIncoming(active.callId);
        _clearAllCallNotifications();
        _setActive(active.copyWith(
          state: CallSignalState.ended,
          endReason: reason,
        ));
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_active?.callId == active.callId &&
              _active?.state == CallSignalState.ended) {
            _setActive(null);
          }
        });
      case 'ENDED':
      case 'MISSED':
      case 'NO_ANSWER':
        // Same full teardown as REJECTED — see above.
        unawaited(streamEngine.endActiveCall());
        _clearNativeIncoming(active.callId);
        _clearAllCallNotifications();
        _setActive(active.copyWith(state: CallSignalState.ended));
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_active?.callId == active.callId &&
              _active?.state == CallSignalState.ended) {
            _setActive(null);
          }
        });
      default:
        // RINGING / unknown — keep local state, STOMP will reconcile.
        return;
    }
  }

  // ── Incoming (peer is the caller, we're the callee) ──────────

  /// Callee tapped Accept on the incoming sheet.
  Future<void> acceptIncoming() async {
    // ignore: avoid_print
    print('[CallSignaling] acceptIncoming ENTER · active=${_active?.callId} '
        'state=${_active?.state} streamCid=${_active?.streamCallCid}');
    final active = _active;
    if (active == null || active.state != CallSignalState.incomingRinging) {
      // ignore: avoid_print
      print('[CallSignaling] acceptIncoming BAIL · '
          'no active call or wrong state (need incomingRinging)');
      return;
    }
    // ignore: avoid_print
    print('[CallSignaling] acceptIncoming → POST /chats/calls/${active.callId}/accept');
    final response = await transport.sendCallAccept(
      active.callId,
      accepterId: settings.userId,
    );
    // ignore: avoid_print
    print('[CallSignaling] acceptIncoming · chat-backend response='
        '${response == null ? "NULL (POST failed — likely 400)" : "OK id=${response['id']} streamCid=${response['streamCallCid']}"}');
    if (response == null) {
      // The chat-ceremony POST failed (most commonly 400 "Call already
      // ended" because the backend's own ring timer fired before the
      // user tapped Accept on the CallKit notification). DO NOT give
      // up yet: Stream and the chat backend run independent timers,
      // and Stream's call may still be live. Try Stream's accept path
      // directly — if it succeeds, media flows and the user can talk,
      // even though the chat_call_log row will be wrong. Only when
      // Stream also bails do we treat this as a true missed call.
      final fallbackCid = active.streamCallCid;
      // ignore: avoid_print
      print('[CallSignaling] chat accept failed — '
          'fallbackCid=$fallbackCid hasPendingIncoming='
          '${streamEngine.hasPendingIncoming}');
      if (fallbackCid != null && fallbackCid.isNotEmpty) {
        // iOS: configure the audio session for record BEFORE the
        // connected transition (see the success-path note above).
        await streamEngine.configureIosCallAudio(
          isVideo: active.callType == ChatCallType.video,
        );
        // Optimistically flip to connected so the in-call page mounts
        // and the user gets the "Connecting…" UI instead of an instant
        // "Call ended". If Stream rejects we roll back below.
        _setActive(active.copyWith(
          state: CallSignalState.connected,
          connectedAt: DateTime.now(),
          streamCallCid: fallbackCid,
        ));
        try {
          if (streamEngine.hasPendingIncoming) {
            // ignore: avoid_print
            print('[CallSignaling] → streamEngine.acceptPendingIncoming(cid=$fallbackCid)');
            final ok = await streamEngine.acceptPendingIncoming(
              isVideo: active.callType == ChatCallType.video,
              expectedCid: fallbackCid,
            );
            if (!ok) {
              // ignore: avoid_print
              print('[CallSignaling] acceptPendingIncoming bailed '
                  '(CID mismatch or threw) — falling through to acceptByCid');
              await streamEngine.acceptByCid(
                callCid: fallbackCid,
                isVideo: active.callType == ChatCallType.video,
              );
            }
          } else {
            // ignore: avoid_print
            print('[CallSignaling] → streamEngine.acceptByCid(cid=$fallbackCid)');
            await streamEngine.acceptByCid(
              callCid: fallbackCid,
              isVideo: active.callType == ChatCallType.video,
            );
          }
          // ignore: avoid_print
          print('[CallSignaling] Stream accept SUCCEEDED — media leg '
              'should be up. Final state=${_active?.state}');
          // Stream accept didn't throw — best-effort log the answered
          // state on the local row so the call history reflects it
          // even though the backend ceremony missed the accept.
          final logId = _logIdByCallId[active.callId];
          if (logId != null) await callLog.logAnswered(logId);
          return;
        } catch (e, st) {
          // ignore: avoid_print
          print('[CallSignaling] Stream-only accept THREW: $e\n$st');
          // Fall through to the missed-call cleanup below.
        }
      }
      // ignore: avoid_print
      print('[CallSignaling] BOTH chat AND Stream accept failed — '
          'marking as missed (page will pop)');
      // Stream had no live call either — treat as a true missed call:
      // close the call_log row, write the inbox preview, and let the
      // page pop itself.
      final logId = _logIdByCallId.remove(active.callId);
      if (logId != null) {
        await callLog.logEnded(
          id: logId,
          durationSeconds: 0,
          finalStatus: ChatCallStatus.missed,
        );
      }
      unawaited(_writeCallSummary(
        active,
        finalStatus: ChatCallStatus.missed,
        durationSeconds: 0,
      ));
      _setActive(active.copyWith(
        state: CallSignalState.ended,
        endReason: 'no_answer',
      ));
      Future.delayed(const Duration(milliseconds: 600), () {
        if (_active?.callId == active.callId &&
            _active?.state == CallSignalState.ended) {
          _setActive(null);
        }
      });
      return;
    }
    final connectedAt = DateTime.now();
    final logId = _logIdByCallId[active.callId];
    if (logId != null) await callLog.logAnswered(logId);
    // Use the cid from the response if present; otherwise stick
    // with whatever the invite carried.
    final streamCallCid = (response['streamCallCid'] as String?) ??
        active.streamCallCid;
    // iOS: put the AVAudioSession into playAndRecord BEFORE flipping to
    // connected. The connected transition synchronously notifies the
    // call page, which immediately sets the speaker route — and that
    // (plus the Stream mic unit that join starts next) crashes natively
    // if the session is still `playback`. Must precede `_setActive`.
    await streamEngine.configureIosCallAudio(
      isVideo: active.callType == ChatCallType.video,
    );
    _setActive(
      active.copyWith(
        state: CallSignalState.connected,
        connectedAt: connectedAt,
        streamCallCid: streamCallCid,
      ),
    );
    // ignore: avoid_print
    print('[CallSignaling] chat accept SUCCEEDED — '
        'state flipped to connected. Bringing Stream media up next.');
    // Bring the media leg up — audio + (for video calls) camera.
    //
    // We MUST call `acceptPendingIncoming` (not `join`) when the
    // ringing came from Stream's WebSocket. Stream's flow for a
    // ringing call is `.accept()` → `.join()` on the SAME Call
    // reference that fired in `state.incomingCall`. Creating a fresh
    // Call via `client.makeCall(id)` and calling `getOrCreate` +
    // `join` bypasses ringing acceptance — audio doesn't flow.
    //
    // Fallback to plain `join(shouldRing: false)` for the case where
    // the engine never saw a pending incoming Call (e.g. FCM-push
    // path on a backgrounded device that's coming back to foreground
    // for the first time, and the in-app overlay fired off of
    // handleIncomingFromPush rather than the Stream WS stream).
    if (streamCallCid != null && streamCallCid.isNotEmpty) {
      // Try the WS-pending path first (uses the SAME Call ref Stream
      // pushed via state.incomingCall — required for Stream's ring-
      // acceptance flow to register the answer). If the pending ref
      // is stale (different CID — happens after prior call cleared
      // partially), it self-clears and we fall through to
      // `acceptByCid` which makes a fresh Call ref with the right CID.
      unawaited(() async {
        if (streamEngine.hasPendingIncoming) {
          final ok = await streamEngine.acceptPendingIncoming(
            isVideo: active.callType == ChatCallType.video,
            expectedCid: streamCallCid,
          );
          // Only fall back to acceptByCid when the pending accept
          // actually bailed (CID mismatch or threw). If it succeeded,
          // running acceptByCid would call leave() on the now-active
          // call and tear down the working media leg.
          if (!ok) {
            await streamEngine.acceptByCid(
              callCid: streamCallCid,
              isVideo: active.callType == ChatCallType.video,
            );
          }
        } else if (Platform.isIOS) {
          // iOS: no Stream ring ref arrived (the APN call-push isn't
          // delivered in this setup), so `acceptByCid` falls back to
          // `consumeIncomingCall` + `call.accept()` — which Stream
          // rejects with "Only members can reject or accept a call"
          // because the backend created the Stream call without adding
          // the callee to its member list. accept()/reject() are
          // member-only RING operations; `join()` is governed by the
          // broader join-call permission. Since the backend already
          // recorded our accept (POST /accept → 200), we don't need
          // Stream's ring-accept ceremony at all — just JOIN the call
          // as a media participant so audio flows. shouldRing:false and
          // no callee ids (we're not ringing anyone, we're answering).
          await streamEngine.join(
            streamCallCid: streamCallCid,
            isVideo: active.callType == ChatCallType.video,
            calleeUserIds: const <String>[],
            shouldRing: false,
          );
        } else {
          // Android keeps the existing accept-by-cid path unchanged.
          await streamEngine.acceptByCid(
            callCid: streamCallCid,
            isVideo: active.callType == ChatCallType.video,
          );
        }
      }());
    }
  }

  /// Callee tapped Reject — tell the caller, log as rejected, drop.
  /// iOS-only. After a backgrounded/killed incoming call resolves (declined,
  /// cancelled, missed) WITHOUT the user foregrounding the app, force this
  /// device fully "offline for push" so the NEXT call rings via the apn/VoIP
  /// push (native CallKit) again.
  ///
  /// Why this is needed (the "2nd call: no ring" bug on killed apps): a killed
  /// app woken by a call push cold-starts the full session — it reconnects
  /// STOMP (→ backend presence ONLINE) and the Stream WebSocket. With presence
  /// ONLINE the backend SKIPS the apn ring (the presence gate only rings
  /// OFFLINE callees), and with the Stream WS up Stream would deliver the ring
  /// over the WS — so a 2nd call to the still-backgrounded device shows no
  /// native ring. Dropping STOMP + the Stream WS and reporting OFFLINE restores
  /// the apn ring path for the next call.
  ///
  /// Gated so it can't hurt other cases:
  ///   • genuinely FOREGROUND (native `isAppForeground`) → skip; the in-app
  ///     overlay owns the next ring there.
  ///   • a call is still CONNECTED → skip; never tear down a live call.
  /// iOS-only; Android keeps its own lifecycle background path.
  Future<void> goOfflineForPushIfBackground() async {
    if (!Platform.isIOS) return;
    if (_active?.state == CallSignalState.connected) return;
    // Genuinely foreground right now → the in-app overlay owns the next ring,
    // skip; presence is owned by `ChatLifecycleBridge` (resume→foreground,
    // pause→background). When backgrounded/killed we go offline IMMEDIATELY so
    // the very next call (even an instant redial) rings via apn, not a warm WS
    // in-app invite — the reported "C calls D again, no native ring, only shows
    // when the app is opened" bug. Do NOT delay/poll here: keeping the WS warm
    // even briefly lets a quick 2nd call route over STOMP as an (invisible-
    // while-backgrounded) in-app overlay instead of the native CallKit ring.
    final fg = await _appForeground();
    final unlocked = await _deviceUnlocked();
    // ignore: avoid_print
    print('[CallSignaling] goOfflineForPushIfBackground: isAppForeground=$fg '
        'deviceUnlocked=$unlocked');
    // Stay online ONLY when the app is genuinely on screen AND the device is
    // UNLOCKED — i.e. when the in-app overlay can actually be shown for the
    // next call. CRITICAL (case #4): after B ACCEPTS a call from the LOCK
    // SCREEN, CallKit activates the app process, so `isAppForeground` reads
    // true even though the user never unlocked. If we stayed online there, the
    // accept-time Stream WS stays up and the NEXT call rings over the
    // (invisible-on-a-locked-device) WS instead of the native VoIP push — so
    // B never sees the 2nd ring. A locked device can't show the in-app overlay
    // anyway, so we must always go offline-for-push there.
    if (fg && unlocked) return;
    // ignore: avoid_print
    print('[CallSignaling] backgrounded/locked ring resolved → going offline '
        'for push (drop STOMP + Stream WS + report OFFLINE) so the next call '
        'rings via apn, not the warm WS');
    unawaited(transport.pause());
    unawaited(streamEngine.disconnectForBackground(force: true));
    unawaited(remote.reportBackground().catchError((Object _) {}));
  }

  Future<void> rejectIncoming() async {
    final active = _active;
    if (active == null) return;
    transport.sendCallReject(active.callId, reason: 'declined');
    final logId = _logIdByCallId.remove(active.callId);
    if (logId != null) {
      await callLog.logEnded(
        id: logId,
        durationSeconds: 0,
        finalStatus: ChatCallStatus.rejected,
      );
    }
    // Slice 10.2.10 — leave a "📞 Missed/Declined call" tile preview.
    unawaited(_writeCallSummary(
      active,
      finalStatus: ChatCallStatus.rejected,
      durationSeconds: 0,
    ));
    // We declined — clear the ring + any Stream notification so nothing
    // lingers on the lock screen.
    _clearNativeIncoming(active.callId);
    _clearAllCallNotifications();
    // Drop the iOS warm-up call we may have pre-established during ringing
    // (it was getOrCreate'd but never joined).
    if (Platform.isIOS) unawaited(streamEngine.discardPrepared());
    _setActive(null);
    // If we declined while backgrounded/killed, make sure the NEXT call still
    // rings via apn (drop STOMP + Stream WS + report OFFLINE). No-op when
    // foreground. See goOfflineForPushIfBackground for the why.
    unawaited(goOfflineForPushIfBackground());
    // DIAGNOSTIC: give the fire-and-forget clears a beat, then dump the
    // registry — if call #1's entry survives here, it's the "no ring on
    // call #2" suspect.
    Future.delayed(const Duration(milliseconds: 400),
        () => _diagCallkitRegistry('after-reject-${active.callId}'));
  }

  // ── Inbound transport events ─────────────────────────────────

  Future<void> _onEvent(ChatTransportEvent event) async {
    // Diagnostic: log every chat-transport event that touches the
    // call signaling layer. Helps trace what's coming in from the
    // backend (call.invite, call.accept, call.reject, call.hangup)
    // — especially useful when A's UI suddenly closes mid-call to
    // see if the backend sent an unexpected hangup.
    if (event is CallInviteEvent ||
        event is CallAcceptEvent ||
        event is CallRejectEvent ||
        event is CallHangupEvent) {
      // ignore: avoid_print
      print('[CallSignaling] inbound transport event: '
          '${event.runtimeType} · current=${_active?.callId}/${_active?.state}');
    }
    switch (event) {
      case CallInviteEvent(:final callId, :final conversationId, :final callerId, :final callerName, :final callType, :final startedAt, :final targetIds):
        // Ignore self-echo if it ever happens.
        if (callerId == settings.userId) return;
        _diagCallkitRegistry('ws-invite-$callId');
        // Routing note: with the real backend, invites land on
        // `/user/queue/calls` — a per-user channel. If a frame
        // arrives here it's already addressed to us, so we must NOT
        // client-side-filter by `targetIds` (decoded from
        // ChatCallDto.participants). The participants array at
        // invite time can lag (callees not yet marshalled), which
        // would falsely drop the invite. `targetIds` is kept on the
        // event for the legacy LAN-relay broadcast path only.
        // ignore: unused_local_variable
        final _ = targetIds; // intentionally unused on the real backend
        // A new invite while we're in another non-pending call (in an
        // ongoing connected call, or our own outgoing invite) → busy
        // signal back. Replace stale `incomingRinging`/`ended` states
        // instead of auto-rejecting forever so the next attempt from
        // the same caller actually rings through.
        final prior = _active;
        if (prior != null &&
            prior.state != CallSignalState.incomingRinging &&
            prior.state != CallSignalState.ended) {
          // Slice 10.2.4 — explicit busy reason so the caller can show
          // "X is on another call" instead of a generic "Call ended".
          transport.sendCallReject(callId, reason: 'busy');
          return;
        }
        if (prior != null) {
          // Drop the prior log row so we don't leak entries.
          _logIdByCallId.remove(prior.callId);
        }
        // NATIVE-ONLY when off-screen. If the app is NOT genuinely
        // foreground+unlocked, do NOT seed the in-app `incomingRinging`
        // overlay from this STOMP invite. The two sockets drop independently
        // on background: when only the Stream WS is down (and STOMP briefly
        // lingers), the call is ALREADY ringing on the native CallKit screen
        // (Stream's VoIP push) AND this STOMP `CallInviteEvent` fires too —
        // seeding an invisible in-app overlay creates a second, conflicting
        // call leg, and when the native screen is dismissed its end event
        // auto-declines that overlay call (the reported "minimize → call gets
        // declined" bug). Off-screen the NATIVE path owns everything: the ring
        // (Stream push → CallKit), accept (CallkitEventHandler →
        // handleIncomingFromPush), decline, and caller-cancel dismissal
        // (watchBackgroundRingForCancel) — exactly as on a killed app, which
        // never processes a STOMP invite at all. We also re-arm offline so the
        // lingering STOMP/Stream WS can't route a follow-up call as an
        // (invisible) in-app invite either. iOS-only; Android keeps seeding
        // (its background call UX differs and is validated separately).
        if (Platform.isIOS &&
            !(await _appForeground() && await _deviceUnlocked())) {
          // ignore: avoid_print
          print('[CallSignaling] CallInviteEvent $callId arrived while '
              'off-screen (background/locked) — NOT seeding in-app overlay; '
              'native CallKit owns the ring (native-only)');
          unawaited(goOfflineForPushIfBackground());
          return;
        }
        final logged = await callLog.logStart(
          conversationId: conversationId,
          callerId: callerId,
          callerName: callerName,
          callType: callType,
          at: startedAt,
        );
        _logIdByCallId[callId] = logged.id;
        // Slice 10.2.9 — look up the local conv so the incoming sheet
        // can show the GROUP name (e.g. "TEST01") with "Vibol is
        // calling" as a subtitle, instead of just "Vibol". Direct
        // calls keep showing the caller's name as the header.
        final conv = await conversations.findById(conversationId);
        _setActive(ActiveCall(
          callId: callId,
          conversationId: conversationId,
          peerId: callerId,
          peerName: callerName,
          callType: callType,
          state: CallSignalState.incomingRinging,
          startedAt: startedAt,
          callerId: callerId,
          conversationName: conv?.name,
          isGroup: conv?.isGroup ?? false,
          conversationAvatarFilePath: conv?.avatarFilePath,
        ));
        // Subscribe to `/topic/conversations/{convId}/call` so the
        // accept / reject / hangup frames that come AFTER the invite
        // land here — without this, the per-call topic is only
        // attached when the user opens the chat page, which may not
        // happen before the call wraps up. Idempotent: no-op if
        // already subscribed.
        transport.subscribeConversation(conversationId);
        // iOS: pre-connect the client AND pre-`getOrCreate` the call
        // while ringing so only the SFU media connect is left for accept
        // (see handleIncomingFromPush). iOS-only; Android unchanged.
        if (Platform.isIOS) {
          unawaited(streamEngine.warmUp());
          unawaited(_prepareIncomingStream(callId, callType));
          // Foreground: dismiss the native CallKit screen Stream's VoIP
          // push raises so only the in-app overlay rings. No-op if bg.
          _suppressForegroundCallkit(callId);
        }
      case CallAcceptEvent(:final callId, :final accepterId):
        // Peer accepted our outgoing invite — transition to connected.
        final active = _active;
        if (active == null || active.callId != callId) return;
        // Slice 10.2.8 — only the original caller should react to an
        // accept event. In a group call every callee shares the same
        // callId, so without this guard one callee tapping Accept
        // would yank every OTHER callee straight from incomingRinging
        // into connected, closing their incoming sheet without them
        // ever choosing. Each callee gets to accept independently.
        // Slice 10.2.11 extends this: once we (the caller) are in
        // `connected`, subsequent group accepts still need to count
        // toward the active-callee set so we know when the last
        // callee leaves and can auto-end.
        if (active.state != CallSignalState.outgoingRinging &&
            active.state != CallSignalState.connected) {
          return;
        }
        if (accepterId != null) _activeCallees.add(accepterId);
        if (active.state == CallSignalState.connected) {
          // Already connected (another callee joined first). Nothing
          // to transition — the joiner is now tracked.
          return;
        }
        final connectedAt = DateTime.now();
        final logId = _logIdByCallId[callId];
        if (logId != null) await callLog.logAnswered(logId);
        _setActive(active.copyWith(
          state: CallSignalState.connected,
          connectedAt: connectedAt,
        ));
      case CallRejectEvent(:final callId, :final reason):
        final active = _active;
        if (active == null || active.callId != callId) {
          // A reject for a call this device isn't actively tracking
          // (e.g. another of our devices declined) — clear any native
          // ring still showing here.
          _clearNativeIncoming(callId);
          return;
        }
        final logId = _logIdByCallId.remove(callId);
        if (logId != null) {
          await callLog.logEnded(
            id: logId,
            durationSeconds: 0,
            finalStatus: ChatCallStatus.rejected,
          );
        }
        // Slice 10.2.10 — caller-side summary on the inbox tile.
        unawaited(_writeCallSummary(
          active,
          finalStatus: ChatCallStatus.rejected,
          durationSeconds: 0,
        ));
        _clearNativeIncoming(active.callId);
        _clearAllCallNotifications();
        _setActive(active.copyWith(
          state: CallSignalState.ended,
          endReason: reason ?? 'declined',
        ));
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_active?.callId == active.callId &&
              _active?.state == CallSignalState.ended) {
            _setActive(null);
          }
        });
      case CallHangupEvent(:final callId, :final hangerUpperId):
        final active = _active;
        if (active == null || active.callId != callId) {
          // No in-app active call to match (the FCM background isolate
          // showed the native ring without our main isolate ever
          // processing the invite). A hangup means the caller withdrew
          // — clear the lingering native heads-up for this call id.
          _clearNativeIncoming(callId);
          return;
        }
        // Just-accepted grace period. When B's cold-start accept took
        // longer than the chat backend's ring timeout (~30 s by default),
        // the backend has already broadcast a CallHangupEvent by the
        // time B's POST /accept lands. B's app then receives BOTH the
        // 200 OK on the accept AND the stale hangup — and the hangup
        // arrives microseconds after our state flipped to connected,
        // killing the call page right when it just mounted.
        //
        // Only the FRESHLY-connected window is ambiguous: a hangup here
        // could be the caller's real End, OR a stale backend ring-timer
        // hangup that raced our just-landed accept. We CANNOT tell them
        // apart by `hangerUpperId` — the transport falls back to the
        // caller id when no explicit hanger is set, so a timer hangup
        // looks identical to a deliberate End.
        //
        // The reliable tell is whether the caller is still in the MEDIA
        // call: a real End leaves the Stream session (no remote
        // participant), whereas a stale timer hangup fires while the
        // caller is still sitting in the call (remote participant
        // present). Using `callNotifier.value != null` here was the bug —
        // that only checks whether OUR OWN call object exists (always
        // true once connected), so it swallowed the caller's real hangup
        // for the whole 5 s window and B stayed stuck forever.
        if (active.state == CallSignalState.connected &&
            active.connectedAt != null) {
          final connectedMs =
              DateTime.now().difference(active.connectedAt!).inMilliseconds;
          if (connectedMs < 5000 && streamEngine.hasRemoteParticipant) {
            // Caller still in the media call → treat as a stale-backend
            // hangup and ignore *for now*. But STOMP can beat Stream's
            // participant-left propagation, so we must re-check: if the
            // caller has since left, honour the hangup we deferred —
            // otherwise B hangs on a call the caller already ended inside
            // the grace window (the reported bug).
            //
            // A SINGLE one-shot re-check (the previous implementation)
            // fired too early. When B accepted from a KILLED app, the
            // cold-start Stream resync makes participant-left propagation
            // lag several seconds, so the 1.5 s check still saw the caller
            // "present", gave up forever, and B stayed stuck on Connected.
            // Poll instead: honour the hangup the instant the caller
            // leaves, and only discard it as a stale timer if the caller
            // stays for the whole window.
            // ignore: avoid_print
            print('[CallSignaling] CallHangupEvent deferred — call only '
                '${connectedMs}ms old, caller still in media call; '
                'polling for caller-left');
            _scheduleDeferredHangupRecheck(callId);
            return;
          }
        }
        // Slice 10.2.10 — multi-party group call semantics. When the
        // hangup is from one of the OTHER callees in a group call
        // (not the caller, not us), it means that one peer just left.
        // The rest of us stay connected — the call continues, our
        // timer keeps ticking. Only the caller's hangup ends the call
        // for everyone. Direct calls (1:1) keep the old "either side
        // ends it" behaviour because there's nobody else to stay
        // connected with. Pre-10.2.10 clients on the wire don't send
        // hangerUpperId, so null falls back to the old behaviour.
        if (active.isGroup &&
            hangerUpperId != null &&
            hangerUpperId != active.callerId &&
            hangerUpperId != settings.userId) {
          // Slice 10.2.11 — if WE are the caller, the callee that
          // just left was tracked in `_activeCallees`; drain them.
          // When the set hits empty the call has no remaining
          // participants and we auto-hangup so the caller isn't left
          // alone with a running timer (mirrors Telegram's
          // last-person-out behaviour for group calls).
          final iAmCaller = active.callerId == settings.userId;
          if (iAmCaller) {
            _activeCallees.remove(hangerUpperId);
            if (_activeCallees.isEmpty) {
              unawaited(hangup(finalStatus: ChatCallStatus.answered));
            }
          }
          return;
        }
        await _finishPeerHangup(active);
      default:
        // Chat-message + conversation-create events handled elsewhere.
        break;
    }
  }

  /// Tear down the local call after the PEER hung up (or after a deferred
  /// hangup re-check confirms the caller left the media session): log the
  /// end, write the inbox summary, clear any native ring, flip to `ended`,
  /// then drop the active reference so the call page pops itself. Shared
  /// by the immediate `CallHangupEvent` path and the grace-window deferred
  /// re-check so both end the call identically.
  Future<void> _finishPeerHangup(ActiveCall active) async {
    final endedAt = DateTime.now();
    final duration = active.connectedAt == null
        ? 0
        : endedAt.difference(active.connectedAt!).inSeconds;
    final logId = _logIdByCallId.remove(active.callId);
    final resolvedStatus =
        duration > 0 ? ChatCallStatus.answered : ChatCallStatus.noAnswer;
    if (logId != null) {
      await callLog.logEnded(
        id: logId,
        durationSeconds: duration,
        finalStatus: resolvedStatus,
      );
    }
    // Slice 10.2.10 — surface the call summary on the inbox tile.
    unawaited(_writeCallSummary(
      active,
      finalStatus: resolvedStatus,
      durationSeconds: duration,
    ));
    // The call ended for us — tear down the Stream media leg (endActiveCall
    // bumps _callSeq so any in-flight acceptByCid retry aborts instead of
    // re-joining a dead call), clear the native heads-up, then sweep ALL
    // call notifications so nothing lingers as a phantom "Connected".
    unawaited(streamEngine.endActiveCall());
    _clearNativeIncoming(active.callId);
    _clearAllCallNotifications();
    _setActive(active.copyWith(state: CallSignalState.ended));
    Future.delayed(const Duration(milliseconds: 600), () {
      if (_active?.callId == active.callId &&
          _active?.state == CallSignalState.ended) {
        _setActive(null);
      }
    });
    // Peer hung up while we were backgrounded → re-arm the apn ring path for
    // the next call. No-op when foreground / still connected.
    unawaited(goOfflineForPushIfBackground());
  }

  /// Resolve a `call.hangup` that arrived inside the just-connected grace
  /// window while the caller was still present in the Stream media
  /// session. The hangup is ambiguous there — it can be the caller's real
  /// End racing our just-landed accept, OR a stale backend ring-timer
  /// hangup — and the envelope can't tell them apart. The reliable tell is
  /// whether the caller actually LEAVES the media session: a real End
  /// drops the remote participant; a stale timer fires while the caller is
  /// still sitting in the call.
  ///
  /// So we POLL [StreamCallEngine.hasRemoteParticipant] rather than check
  /// once. The previous one-shot re-check fired at a fixed 1.5 s and gave
  /// up forever — but when B accepted from a KILLED app, the cold-start
  /// Stream resync makes participant-left propagation lag well past 1.5 s,
  /// so that single check saw the caller "still present" and B stayed
  /// stuck on Connected (the reported bug). Polling honours the hangup the
  /// instant the caller leaves, and only discards it (keeps the call) if
  /// the caller stays for the whole window.
  void _scheduleDeferredHangupRecheck(String callId) {
    _deferredHangupTimer?.cancel();
    const interval = Duration(milliseconds: 750);
    const maxChecks = 12; // ~9 s — well past Stream's cold-start lag
    var checks = 0;
    _deferredHangupTimer = Timer.periodic(interval, (timer) {
      checks++;
      final cur = _active;
      // The call changed or was torn down by another path → stop polling.
      if (cur == null ||
          cur.callId != callId ||
          cur.state != CallSignalState.connected) {
        timer.cancel();
        return;
      }
      if (!streamEngine.hasRemoteParticipant) {
        // Caller has left the media session → the deferred hangup was a
        // real End. Honour it now.
        timer.cancel();
        // ignore: avoid_print
        print('[CallSignaling] deferred hangup confirmed — caller left the '
            'media call after ${checks * interval.inMilliseconds}ms → '
            'ending now');
        unawaited(_finishPeerHangup(cur));
        return;
      }
      if (checks >= maxChecks) {
        // Caller stayed in the media call for the whole window → treat the
        // hangup as a stale backend ring-timer event and keep the call.
        timer.cancel();
        // ignore: avoid_print
        print('[CallSignaling] deferred hangup discarded — caller still in '
            'media call after full grace window; treating as stale timer');
      }
    });
  }

  /// Start polling the backend's canonical call status every few seconds
  /// while we're `connected`. This is the safety net for the "B stuck
  /// Connected forever" bug: when the peer hangs up, A's `hangup()` hits
  /// `POST /chats/calls/{id}/end` so the BACKEND records the call as
  /// ENDED — but B can miss BOTH push paths that would normally tell it:
  ///   * the STOMP `call.hangup` frame (cold-start accept subscribes to
  ///     the call topic too late, so the broadcast is gone), AND
  ///   * Stream's remote-left event (B joined the media leg AFTER the peer
  ///     already left, so it never "saw" a remote to detect leaving).
  /// With both push paths silent, B would sit on Connected indefinitely.
  ///
  /// [reconcileActive] already maps a backend `ENDED`/`MISSED`/`NO_ANSWER`/
  /// `REJECTED` onto a local teardown (and guards the just-connected window
  /// so a stale ring-timer verdict can't pop a fresh call). Polling it on a
  /// heartbeat means the call always closes within one interval of the peer
  /// hanging up, regardless of push delivery.
  void _startConnectedHeartbeat(String callId) {
    // Already polling this call → leave it running.
    if (_connectedHeartbeat?.isActive ?? false) return;
    const interval = Duration(seconds: 4);
    _connectedHeartbeat = Timer.periodic(interval, (timer) {
      final cur = _active;
      if (cur == null || cur.state != CallSignalState.connected) {
        timer.cancel();
        return;
      }
      // reconcileActive is a no-op for non-numeric ids and self-guards the
      // just-connected grace window; safe to call repeatedly.
      unawaited(reconcileActive());
    });
  }

  void _stopConnectedHeartbeat() {
    _connectedHeartbeat?.cancel();
    _connectedHeartbeat = null;
  }

  /// iOS-only caller-side ring heartbeat. While we sit in
  /// `outgoingRinging`, the ONLY signals that flip us to `connected` are
  /// the STOMP `call.accept` broadcast and Stream's peer-joined fallback
  /// — and BOTH can miss when the callee accepts from a killed/locked
  /// cold-start (the broadcast can be gone before we subscribe, and the
  /// callee may not have joined the Stream SFU yet). The result is the
  /// reported bug: the callee is in the call but the caller is stuck on
  /// "Calling…".
  ///
  /// This poll closes that gap from the caller side: every 3 s it calls
  /// [reconcileActive], which maps a backend `ANSWERED` onto a local
  /// `connected`. So the moment the backend has RECORDED the callee's
  /// accept — regardless of whether any push reached us — we connect
  /// within one interval. [reconcileActive] only acts on a numeric id
  /// (`int.tryParse` guard) and self-guards the just-connected window,
  /// so this is safe to call repeatedly.
  ///
  /// iOS-only (honours the no-Android-impact rule); the caller's id swaps
  /// mid-ring (placeholder → backend numeric), and `_setActive` re-fires
  /// on that swap, so we restart on a changed id.
  void _startRingingHeartbeat(String callId) {
    if (!Platform.isIOS) return;
    // Only a backend-numeric id is pollable. The placeholder
    // (`call-<me>-<ts>`) isn't — wait for the swap (which re-enters
    // _setActive → here again with the numeric id).
    if (int.tryParse(callId) == null) {
      _stopRingingHeartbeat();
      return;
    }
    // Already polling THIS id → leave it running.
    if ((_ringingHeartbeat?.isActive ?? false) &&
        _ringingHeartbeatCallId == callId) {
      return;
    }
    _stopRingingHeartbeat();
    _ringingHeartbeatCallId = callId;
    const interval = Duration(seconds: 3);
    _ringingHeartbeat = Timer.periodic(interval, (timer) {
      final cur = _active;
      if (cur == null ||
          cur.callId != callId ||
          cur.state != CallSignalState.outgoingRinging) {
        // Left outgoingRinging (connected / ended / new call) → stop.
        timer.cancel();
        if (_ringingHeartbeatCallId == callId) _ringingHeartbeatCallId = null;
        return;
      }
      // Maps backend ANSWERED → connected; once that lands the state
      // leaves outgoingRinging and the guard above cancels us.
      unawaited(reconcileActive());
    });
  }

  void _stopRingingHeartbeat() {
    _ringingHeartbeat?.cancel();
    _ringingHeartbeat = null;
    _ringingHeartbeatCallId = null;
  }

  void _setActive(ActiveCall? next) {
    final prev = _active;
    _active = next;
    activeCallListenable.value = next;
    // Diagnostic: log EVERY state transition so we can trace which
    // path tore down the call. Grep for "STATE TRANSITION" to see
    // the full lifecycle. Includes stack-trace-style hint via the
    // current async invocation — Dart doesn't give us callers but
    // the surrounding logs will identify the trigger.
    if (prev?.callId != next?.callId || prev?.state != next?.state) {
      // ignore: avoid_print
      print('[CallSignaling] STATE TRANSITION · '
          '${prev?.callId ?? "none"}/${prev?.state ?? "none"} '
          '→ ${next?.callId ?? "none"}/${next?.state ?? "none"} '
          '· endReason=${next?.endReason}');
    }
    // Backend heartbeat: run ONLY while connected. It's the safety net
    // that catches a peer hangup when neither push path delivered it.
    if (next != null && next.state == CallSignalState.connected) {
      _startConnectedHeartbeat(next.callId);
    } else {
      _stopConnectedHeartbeat();
    }
    // Caller-side ring heartbeat (iOS): run ONLY while outgoingRinging.
    // Polls the backend so the caller connects the moment the callee's
    // accept is recorded server-side, even if the STOMP `call.accept`
    // broadcast is lost (killed/locked callee cold-start). Self-restarts
    // on the placeholder→numeric id swap; no-op until the id is numeric.
    if (next != null && next.state == CallSignalState.outgoingRinging) {
      _startRingingHeartbeat(next.callId);
    } else {
      _stopRingingHeartbeat();
    }
    // (Re)start the 30s safety timeout whenever we enter
    // incomingRinging, so a stuck invite (sheet never shown, peer
    // never answered) eventually clears itself and stops auto-
    // rejecting follow-up invites.
    _ringTimeout?.cancel();
    if (next != null && next.state == CallSignalState.incomingRinging) {
      // 60 s matches Stream's overridden ring timeout (see
      // StreamCallEngine.join). Earlier value (30 s) would auto-reject
      // local invites halfway through the server-side ring, killing
      // perfectly valid late accepts.
      _ringTimeout = Timer(const Duration(seconds: 60), () {
        if (_active?.callId == next.callId &&
            _active?.state == CallSignalState.incomingRinging) {
          unawaited(rejectIncoming());
        }
      });
    } else if (next != null && next.state == CallSignalState.outgoingRinging) {
      // Backstop for the caller side. Stream's ring timeout (now
      // overridden to 60 s server-side via StreamRingSettings — see
      // StreamCallEngine.join) is supposed to broadcast a `call.ended`
      // event over the WS once the callee fails to answer in time —
      // but when B accepts too late and the backend rejects the accept
      // with 400 "Call already ended", no such event reaches A, and
      // A's call page would stay on "Calling…" forever. 65 s is
      // intentionally a touch longer than Stream's 60 s so the WS
      // path still wins on the happy path; this only fires when the
      // WS event is lost.
      _ringTimeout = Timer(const Duration(seconds: 65), () {
        final cur = _active;
        if (cur == null ||
            cur.callId != next.callId ||
            cur.state != CallSignalState.outgoingRinging) {
          return;
        }
        if (kDebugMode) {
          debugPrint('[CallSignaling] outgoing ring timeout (35s) — '
              'forcing call ${cur.callId} to ended (no_answer)');
        }
        // Log as missed so the inbox/Calls tab reflects the attempt.
        final logId = _logIdByCallId.remove(cur.callId);
        if (logId != null) {
          unawaited(callLog.logEnded(
            id: logId,
            durationSeconds: 0,
            finalStatus: ChatCallStatus.noAnswer,
          ));
        }
        unawaited(_writeCallSummary(
          cur,
          finalStatus: ChatCallStatus.noAnswer,
          durationSeconds: 0,
        ));
        // Best-effort: also tell the backend / peer so any straggling
        // CallKit ringer on B can be dismissed. Fire-and-forget — if
        // the call row is already CANCELLED on the server this is a
        // no-op, and we don't want to block the local state cleanup.
        try {
          transport.sendCallHangup(
            cur.callId,
            hangerUpperId: settings.userId,
          );
        } catch (_) {}
        // Tear down Stream's media leg too — without this, A's
        // StreamVideo client keeps the call object alive and
        // disconnectForBackground sees a stale activeCall on resume.
        unawaited(streamEngine.endActiveCall());
        _setActive(cur.copyWith(
          state: CallSignalState.ended,
          endReason: 'no_answer',
        ));
        Future.delayed(const Duration(milliseconds: 600), () {
          if (_active?.callId == next.callId &&
              _active?.state == CallSignalState.ended) {
            _setActive(null);
          }
        });
      });
    }

    // Tear down the Stream media leg the moment the call leaves ANY
    // live state (connected OR either ringing state) for a terminal
    // one (ended / idle / cleared). Covers every termination path —
    // local End, peer hangup, busy, missed, accept-failed, AND the
    // caller's `outgoingRinging → ended` on a reject/no-answer.
    //
    // CRITICAL: `outgoingRinging` MUST count as live. The caller's
    // Stream join (and its "Call in progress / Connecting…" foreground-
    // service notification) is already up while A is ringing B — B
    // hasn't answered, so A never reached `connected`. If we only tore
    // down from `connected`, a reject while ringing would leave A's
    // Stream join (and that persistent notification) alive forever.
    //
    // Use endActiveCall() (NOT leave()) so a still-in-flight join /
    // accept (caller's outgoing connect, or a slow minimized cold-
    // reconnect) is cancelled too — otherwise it finishes AFTER this
    // teardown, (re)starts the foreground service / re-publishes the
    // mic, and nothing is left to end it.
    bool isLive(CallSignalState? s) =>
        s == CallSignalState.connected ||
        s == CallSignalState.outgoingRinging ||
        s == CallSignalState.incomingRinging;
    final wasLive = isLive(prev?.state);
    final stillLive = isLive(next?.state);
    if (wasLive && !stillLive) {
      if (Platform.isIOS) {
        // iOS "second call shows no ring (callee minimized)" fix.
        //
        // A minimized iOS callee only gets a native CallKit header when
        // Stream's coordinator delivers the incoming-call event via an
        // APNs VoIP push — which it does ONLY when the callee's Stream
        // WebSocket is disconnected. `ChatLifecycleBridge` drops that WS
        // on minimize, but ONLY on the `paused` transition.
        //
        // Across a call the Stream WS is necessarily up (it's the media
        // leg; the accept/resume warm-up reconnects it, and
        // `disconnectForBackground` no-ops while a call is active). When
        // THIS call ends while the app is STILL backgrounded (peer
        // hangup / missed / declined-from-CallKit / remote-end mid-call),
        // there's no fresh `paused` event to drop the WS again — so the
        // NEXT incoming call rings over the still-warm WS, which a
        // backgrounded app can't render → no header (the reported bug).
        //
        // So after the terminal teardown, if we're backgrounded, re-drop
        // the Stream WS so Stream falls back to APNs for call #2. When the
        // call ended in the FOREGROUND (user tapped End on the in-call
        // page) we skip — the eventual minimize fires `paused` and the
        // bridge handles it normally. iOS-only; Android keeps its exact
        // prior behaviour (the `else` branch below).
        unawaited(streamEngine.endActiveCall().then((_) {
          final lc = WidgetsBinding.instance.lifecycleState;
          final backgrounded = lc == AppLifecycleState.paused ||
              lc == AppLifecycleState.hidden ||
              lc == AppLifecycleState.detached;
          if (backgrounded) {
            // ignore: avoid_print
            print('[CallSignaling] call ended while backgrounded (iOS) — '
                're-dropping Stream WS so the next call rings via APNs');
            return streamEngine.disconnectForBackground(force: true);
          }
          return null;
        }));
      } else {
        unawaited(streamEngine.endActiveCall());
      }
    }

    // Dismiss the CallKit notification (ongoing-call heads-up + tray
    // entry) whenever the call leaves any LIVE state. Catches every
    // end path through a single chokepoint: local hangup, peer
    // hangup, decline, reject, missed, accept-failed, lifecycle
    // detach. Without this the notification stays visible after the
    // call has ended, and on some OEMs it keeps a foreground service
    // alive which holds the mic open — the user perceives this as
    // "call still running in the background after end".
    final wasActive = prev != null &&
        (prev.state == CallSignalState.connected ||
            prev.state == CallSignalState.outgoingRinging ||
            prev.state == CallSignalState.incomingRinging);
    final stillActive = next != null &&
        (next.state == CallSignalState.connected ||
            next.state == CallSignalState.outgoingRinging ||
            next.state == CallSignalState.incomingRinging);
    if (wasActive && !stillActive) {
      unawaited(_dismissCallkitForActive(prev));
    }
  }
}

class _PeerHint {
  const _PeerHint({required this.id, required this.name});
  final String id;
  final String name;
}
