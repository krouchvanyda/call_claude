import 'dart:async';

import '../widgets/call_permission_gate.dart';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_video_flutter/stream_video_flutter.dart';

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../data/call_signaling_service.dart';
import '../../data/lockscreen_return.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../data/stream_call_engine.dart';
import '../../entities/call_log.dart';
import '../../entities/conversation.dart';
import '../widgets/chat_avatar.dart';

/// Slice 10.2.2 (UI shell) + Slice 10.2.3 (wire signalling).
///
/// Same shape as [VoiceCallPage] — page mounts, kicks off either an
/// outgoing invite or matches a connected accept, listens to
/// [CallSignalingService.activeCall], and closes when the peer hangs
/// up. Media streams are still placeholders; replacing them with
/// `RTCVideoRenderer` is the next step.
class VideoCallPage extends StatefulWidget {
  const VideoCallPage({
    super.key,
    required this.conversationId,
    this.isOutgoing = false,
  });

  final String conversationId;

  /// True ONLY when the user explicitly started this call (tapped a call /
  /// redial button). False for every incoming/accept push. The page places an
  /// outgoing invite ONLY when this is true — never merely because there's no
  /// active call (that inference caused the "reopen app → dials the peer back"
  /// bug when a lingering call route re-mounted).
  final bool isOutgoing;

  /// Tracks whether a VideoCallPage is currently mounted. Used by
  /// IncomingCallOverlay's auto-push fallback to detect whether the
  /// _handleAccept initial push was wiped by go_router's cold-start
  /// splash → dashboard redirect. Single global because only one
  /// call at a time. Set in initState / cleared in dispose.
  static bool isMounted = false;

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage>
    with WidgetsBindingObserver {
  bool _muted = false;
  bool _cameraOn = true;
  bool _frontCamera = true;
  bool _speaker = true;
  bool _controlsVisible = true;
  bool _remoteVideoOn = true;
  int _elapsedSeconds = 0;
  Offset _pipPosition = const Offset(16, 80);
  Timer? _hideTimer;
  Timer? _ticker;
  late final CallSignalingService _signaling;
  late final StreamCallEngine _engine;
  bool _connected = false;
  String _status = 'Connecting…';

  @override
  void initState() {
    super.initState();
    VideoCallPage.isMounted = true;
    _signaling = GetIt.I<CallSignalingService>();
    _engine = GetIt.I<StreamCallEngine>();
    _signaling.activeCallListenable.addListener(_onActiveCallChanged);
    WidgetsBinding.instance.addObserver(this);
    final existing = _signaling.current;
    final matchesActive =
        existing != null && existing.conversationId == widget.conversationId;
    if (matchesActive && existing.state == CallSignalState.connected) {
      _connected = true;
      _startTicker();
    } else if (matchesActive) {
      // Existing incoming/connecting call for this conversation — attach.
      _status = 'Ringing…';
    } else if (widget.isOutgoing) {
      // Place a new outgoing video invite — gated on mic + camera
      // permission (iOS-only; Android unchanged). Without them the Stream
      // join fails silently and the ring never reaches the peer.
      _status = 'Calling…';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_placeOutgoingWithPermission());
      });
    } else {
      // No matching active call AND not a user-initiated outgoing call — a
      // spurious/restored mount. Do NOT dial. Grace for a legit incoming
      // `_active`, then pop if none arrives (see VoiceCallPage for the bug).
      _status = 'Ringing…';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          final cur = _signaling.current;
          final hasCallForThisConv = cur != null &&
              cur.conversationId == widget.conversationId &&
              cur.state != CallSignalState.ended;
          if (!hasCallForThisConv) {
            // ignore: avoid_print
            print('[VideoCallPage] spurious mount (no outgoing intent, no '
                'active call for conv=${widget.conversationId}) — popping '
                'instead of placing a call');
            Navigator.of(context).maybePop();
          }
        });
      });
    }
    _resetHideTimer();
  }

  /// Trigger the native mic + camera prompt (iOS-only) the moment the call
  /// page opens, then place the outgoing invite REGARDLESS of the result.
  /// The ring sent to the callee is a REST invite that doesn't need the
  /// mic/camera, so the other side must always ring; if the user denies, A
  /// simply transmits no audio/video. (Old behaviour popped the page on
  /// denial, so the callee never rang — that's the bug this fixes.)
  Future<void> _placeOutgoingWithPermission() async {
    await ensureCallPermissions(needCamera: true);
    if (!mounted) return;
    _signaling.startOutgoing(
      conversationId: widget.conversationId,
      callType: ChatCallType.video,
    );
  }

  @override
  void dispose() {
    VideoCallPage.isMounted = false;
    _hideTimer?.cancel();
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _signaling.activeCallListenable.removeListener(_onActiveCallChanged);
    // If this call was answered over the lock screen, drop the app back
    // behind the keyguard now that it's over — instead of revealing the
    // unlocked dashboard. No-op for calls started inside the unlocked app.
    //
    // CRITICAL: only when the call ACTUALLY ENDED. dispose() also fires
    // when go_router's splash→dashboard redirect spuriously WIPES this page
    // mid-call (the IncomingCallOverlay then re-pushes it). Dropping to the
    // lock screen on that wipe would hide a still-live call behind the
    // keyguard — the reported "accept → shows lock screen" bug.
    final callReallyEnded = _signaling.current == null ||
        _signaling.current?.state == CallSignalState.ended;
    if (callReallyEnded) {
      unawaited(LockScreenReturn.returnToLockScreenIfShownOver());
    } else {
      // ignore: avoid_print
      print('[VideoCallPage] dispose while still connected (spurious wipe) '
          '— NOT returning to lock screen; overlay will re-push');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // GET /chats/calls/{id} — recover canonical call state if STOMP
    // missed a `call.accept` / `call.hangup` while we were
    // backgrounded. No-op when the active call doesn't have a
    // backend id yet.
    if (state == AppLifecycleState.resumed) {
      unawaited(_signaling.reconcileActive());
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  void _onActiveCallChanged() {
    final call = _signaling.activeCallListenable.value;
    if (!mounted) return;
    if (call == null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      });
      return;
    }
    setState(() {
      switch (call.state) {
        case CallSignalState.outgoingRinging:
          _status = 'Calling…';
        case CallSignalState.incomingRinging:
          _status = 'Ringing…';
        case CallSignalState.connected:
          _connected = true;
          if (_ticker == null) _startTicker();
        case CallSignalState.ended:
          // Slice 10.2.4 — reflect the reason in the top-bar label so
          // the user sees WHY before the page pops.
          _status = switch (call.endReason) {
            'busy' => 'Busy',
            'declined' => 'Declined',
            'no_answer' => 'No answer',
            _ => 'Call ended',
          };
        case CallSignalState.idle:
          break;
      }
    });
    if (call.state == CallSignalState.ended && call.endReason != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final reason = switch (call.endReason) {
          'busy' => '${call.peerName} is on another call.',
          'declined' => '${call.peerName} declined the call.',
          'already_in_call' =>
            '${call.peerName} is in another call. Try again in a moment.',
          'failed' => 'Could not start the call. Try again.',
          'no_answer' => '${call.peerName} didn\'t answer.',
          _ => null,
        };
        if (reason != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(reason),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    }
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _resetHideTimer();
  }

  Future<void> _endCall() async {
    _hideTimer?.cancel();
    _ticker?.cancel();
    await _signaling.hangup();
  }

  Future<void> _toggleMute() async {
    final next = !_muted;
    setState(() => _muted = next);
    _resetHideTimer();
    final call = _engine.callNotifier.value;
    await call?.setMicrophoneEnabled(enabled: !next);
  }

  Future<void> _toggleCamera() async {
    final next = !_cameraOn;
    setState(() => _cameraOn = next);
    _resetHideTimer();
    final call = _engine.callNotifier.value;
    await call?.setCameraEnabled(enabled: next);
  }

  Future<void> _flipCamera() async {
    setState(() => _frontCamera = !_frontCamera);
    _resetHideTimer();
    final call = _engine.callNotifier.value;
    await call?.flipCamera();
  }

  Future<void> _toggleSpeaker() async {
    final next = !_speaker;
    setState(() => _speaker = next);
    _resetHideTimer();
    // Stream routes speakerphone via setAudioOutputDevice with a
    // speaker-capable RtcMediaDevice. We keep the UI toggle for now;
    // the audio routing helper is wired in a follow-up.
  }

  String get _timerLabel {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds ~/ 60) % 60;
    final s = _elapsedSeconds % 60;
    final ss = s.toString().padLeft(2, '0');
    final mm = m.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: StreamBuilder<ChatConversation?>(
          stream: GetIt.I<ConversationsRepository>()
              .watchById(widget.conversationId),
          builder: (context, snap) {
            final conv = snap.data;
            // Fallback identity for the cold-start / lock-screen accept
            // path: watchById may return null before the local conv
            // resolves, but the ActiveCall always carries the caller's
            // name + avatar from the push payload.
            final active = _signaling.activeCallListenable.value;
            final displayName = conv?.name ??
                active?.conversationName ??
                active?.peerName;
            final avatarPath =
                conv?.avatarFilePath ?? active?.conversationAvatarFilePath;
            return Stack(
              children: [
                // Remote video — real Stream tracks when the SDK has
                // joined AND at least one remote peer is in the call.
                // The ValueListenableBuilder reacts to join/leave; the
                // inner StreamBuilder reacts to participant arrival.
                // We gate on remote count because the SDK's spotlight
                // layout does `participants.first` and throws on an
                // empty list — which is exactly what we'd hand it if
                // we mounted the widget before the peer joined.
                Positioned.fill(
                  child: ValueListenableBuilder<Call?>(
                    valueListenable: _engine.callNotifier,
                    builder: (context, call, _) {
                      Widget placeholder() => _remoteVideoOn
                          ? _RemoteVideoPlaceholder(
                              name: displayName, avatarFilePath: avatarPath)
                          : _RemoteOffPlaceholder(
                              name: displayName, avatarFilePath: avatarPath);
                      if (call == null || !_remoteVideoOn) {
                        return placeholder();
                      }
                      return StreamBuilder<CallState>(
                        stream: call.state.valueStream,
                        initialData: call.state.value,
                        builder: (context, snap) {
                          final remotes = snap.data?.callParticipants
                                  .where((p) => !p.isLocal)
                                  .toList() ??
                              const <CallParticipantState>[];
                          if (remotes.isEmpty) return placeholder();
                          return StreamCallParticipants(
                            call: call,
                            layoutMode: ParticipantLayoutMode.spotlight,
                            // Pre-filtered to remotes so the SDK's
                            // 1-on-1 spotlight path always has at
                            // least one element to pick.
                            participants: remotes,
                          );
                        },
                      );
                    },
                  ),
                ),
                // Top bar.
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _controlsVisible ? 1 : 0,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          AppLabel(
                            text: 'Video Call',
                            fontSize: AppFontSize.value12,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                          const Spacer(),
                          // Slice 10.2.3 — before the peer accepts we
                          // show the live status (Calling… / Ringing…);
                          // once connected the elapsed-time timer
                          // takes over.
                          AppLabel(
                            text: _connected ? _timerLabel : _status,
                            fontSize: AppFontSize.value13,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Local PiP — real camera feed once Stream has the
                // local participant, otherwise the icon placeholder.
                Positioned(
                  left: _pipPosition.dx,
                  top: _pipPosition.dy,
                  child: ValueListenableBuilder<Call?>(
                    valueListenable: _engine.callNotifier,
                    builder: (context, call, _) {
                      Widget buildPip(CallParticipantState? local) {
                        final pipChild = (call != null && local != null && _cameraOn)
                            ? _LiveLocalPip(
                                call: call,
                                participant: local,
                                mirror: _frontCamera,
                              )
                            : _LocalPip(cameraOn: _cameraOn, mirror: _frontCamera);
                        return Draggable(
                          feedback: pipChild,
                          childWhenDragging: const SizedBox(width: 120, height: 160),
                          onDragEnd: (details) {
                            final media = MediaQuery.of(context);
                            final maxX = media.size.width - 120 - 12;
                            final maxY = media.size.height - 160 - 12;
                            final clamped = Offset(
                              details.offset.dx.clamp(12.0, maxX),
                              details.offset.dy.clamp(48.0, maxY),
                            );
                            setState(() => _pipPosition = clamped);
                          },
                          child: pipChild,
                        );
                      }
                      if (call == null) return buildPip(null);
                      // Local participant arrives a beat after join — rebuild
                      // the PiP the moment Stream surfaces the track.
                      return StreamBuilder<CallState>(
                        stream: call.state.valueStream,
                        initialData: call.state.value,
                        builder: (context, snap) {
                          return buildPip(snap.data?.localParticipant);
                        },
                      );
                    },
                  ),
                ),
                // Bottom controls.
                Align(
                  alignment: Alignment.bottomCenter,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _controlsVisible ? 1 : 0,
                    child: IgnorePointer(
                      ignoring: !_controlsVisible,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 32, 16, 48),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xCC000000),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _CtrlButton(
                              icon: _muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                              active: _muted,
                              activeColor: Colors.red,
                              label: 'Mute',
                              onTap: _toggleMute,
                            ),
                            _CtrlButton(
                              icon: _cameraOn ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                              active: !_cameraOn,
                              activeColor: Colors.white24,
                              label: 'Camera',
                              onTap: _toggleCamera,
                            ),
                            _CtrlButton(
                              icon: Icons.cameraswitch_rounded,
                              active: false,
                              label: 'Flip',
                              onTap: _flipCamera,
                            ),
                            _CtrlButton(
                              icon: _speaker ? Icons.volume_up_rounded : Icons.hearing_rounded,
                              active: _speaker,
                              activeColor: const Color(0xFF6366F1),
                              label: 'Speaker',
                              onTap: _toggleSpeaker,
                            ),
                            _EndCtrl(onTap: _endCall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RemoteVideoPlaceholder extends StatelessWidget {
  const _RemoteVideoPlaceholder({
    required this.name,
    required this.avatarFilePath,
  });

  /// Caller/peer display name. Comes from the local ChatConversation
  /// when it resolves, else from the ActiveCall push payload — so the
  /// cold-start / lock-screen accept path still shows WHO is calling
  /// instead of a blank screen.
  final String? name;
  final String? avatarFilePath;

  @override
  Widget build(BuildContext context) {
    final hasName = (name ?? '').isNotEmpty;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasName) ...[
              ChatAvatar(
                name: name!,
                size: 132,
                // Slice 10.2.10 — show the group photo if one is set.
                avatarFilePath: avatarFilePath,
                showStatus: false,
              ),
              const SizedBox(height: 16),
              AppLabel(
                text: name!,
                fontSize: AppFontSize.value24,
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
              const SizedBox(height: 6),
              AppLabel(
                text: 'Video preview',
                fontSize: AppFontSize.value13,
                color: Colors.white60,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RemoteOffPlaceholder extends StatelessWidget {
  const _RemoteOffPlaceholder({
    required this.name,
    required this.avatarFilePath,
  });
  final String? name;
  final String? avatarFilePath;

  @override
  Widget build(BuildContext context) {
    final hasName = (name ?? '').isNotEmpty;
    return Container(
      color: const Color(0xFF111827),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasName)
            ChatAvatar(
              name: name!,
              size: 96,
              avatarFilePath: avatarFilePath,
              showStatus: false,
            ),
          const SizedBox(height: 16),
          const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 28),
          const SizedBox(height: 8),
          AppLabel(
            text: 'Camera off',
            fontSize: AppFontSize.value14,
            color: Colors.white.withValues(alpha: 0.65),
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}

class _LocalPip extends StatelessWidget {
  const _LocalPip({
    required this.cameraOn,
    required this.mirror,
  });
  final bool cameraOn;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cameraOn ? const Color(0xFF334155) : const Color(0xFF1F2937),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: cameraOn
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.person_rounded, color: Colors.white70, size: 40),
                SizedBox(height: 6),
                AppLabel(
                  text: 'You',
                  fontSize: AppFontSize.value14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w800,
                ),
              ],
            )
          : const Icon(Icons.videocam_off_rounded, color: Colors.white38),
    );
    if (mirror) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(-1, 1, 1),
          child: child,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: child,
    );
  }
}

/// PiP that renders the local participant's real camera track via the
/// Stream SDK. Front camera is mirrored to match the FaceTime
/// convention (so the on-screen image moves the same way the user
/// does).
class _LiveLocalPip extends StatelessWidget {
  const _LiveLocalPip({
    required this.call,
    required this.participant,
    required this.mirror,
  });
  final Call call;
  final CallParticipantState participant;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final inner = SizedBox(
      width: 120,
      height: 160,
      child: StreamCallParticipant(
        call: call,
        participant: participant,
        showParticipantLabel: false,
        showConnectionQualityIndicator: false,
        showSpeakerBorder: false,
      ),
    );
    final framed = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: mirror
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.diagonal3Values(-1, 1, 1),
                child: inner,
              )
            : inner,
      ),
    );
    return framed;
  }
}

class _CtrlButton extends StatelessWidget {
  const _CtrlButton({
    required this.icon,
    required this.active,
    required this.label,
    required this.onTap,
    this.activeColor,
  });
  final IconData icon;
  final bool active;
  final String label;
  final VoidCallback onTap;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final bg = active
        ? (activeColor ?? Colors.white).withValues(alpha: 0.95)
        : Colors.white.withValues(alpha: 0.18);
    final fg = active ? Colors.white : Colors.white;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bg,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: fg, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AppLabel(
          text: label,
          fontSize: AppFontSize.value11,
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }
}

class _EndCtrl extends StatelessWidget {
  const _EndCtrl({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.red.shade600,
          shape: const CircleBorder(),
          elevation: 6,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: const SizedBox(
              width: 64,
              height: 64,
              child: Icon(Icons.call_end_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 6),
        AppLabel(
          text: 'End',
          fontSize: AppFontSize.value11,
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }
}
