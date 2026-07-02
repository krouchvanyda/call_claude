import 'dart:async';

import 'package:flutter/material.dart';

import '../widgets/call_permission_gate.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_it/get_it.dart';
import 'package:stream_webrtc_flutter/stream_webrtc_flutter.dart' as rtc;

import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../data/call_signaling_service.dart';
import '../../data/lockscreen_return.dart';
import '../../data/repositories/conversations_repository.dart';
import '../../data/stream_call_engine.dart';
import '../../entities/call_log.dart';
import '../../entities/conversation.dart';
import '../widgets/chat_avatar.dart';

/// Slice 10.2.1 (state machine) + Slice 10.2.3 (wire signalling).
///
/// Driven by [CallSignalingService] — when the page mounts:
///   * if [CallSignalingService.current] already has an active call
///     in `connected` (we accepted an invite), we start in the
///     connected state and the timer ticks immediately
///   * otherwise we place a new outgoing invite. The page subscribes
///     to `activeCall` and reacts to peer accept / reject / hangup.
///
/// Still UI-only for media — no actual audio is captured or played.
/// Replacing the connected branch with real WebRTC (offer/answer +
/// ICE via the same transport) is the next step.
class VoiceCallPage extends StatefulWidget {
  const VoiceCallPage({
    super.key,
    required this.conversationId,
    this.isOutgoing = false,
  });

  final String conversationId;

  /// True ONLY when the user explicitly started this call (tapped a call /
  /// redial button). False for every incoming/accept push. The page places an
  /// outgoing invite ONLY when this is true — never merely because there's no
  /// active call. Inferring "outgoing" from the absence of a call was the
  /// cause of the "reopen app after a locked call → it dials the peer back"
  /// bug: a lingering/restored call route re-mounted with no active call and
  /// silently placed a new outgoing call.
  final bool isOutgoing;

  /// Tracks whether a VoiceCallPage is currently mounted, so the
  /// auto-push fallback in IncomingCallOverlay can detect when the
  /// initial push was wiped by go_router's cold-start splash →
  /// dashboard redirect. Single global because we only have one
  /// call at a time. Set in initState / cleared in dispose.
  static bool isMounted = false;

  @override
  State<VoiceCallPage> createState() => _VoiceCallPageState();
}

enum _CallStage { calling, ringing, connected, ended }

class _VoiceCallPageState extends State<VoiceCallPage>
    with WidgetsBindingObserver {
  _CallStage _stage = _CallStage.calling;
  bool _muted = false;
  // Default speaker ON for voice calls so the user can hear without
  // putting the phone to their ear (especially important when testing
  // with the device on a table). Toggle still works via the button.
  bool _speaker = true;
  bool _appliedInitialAudioRoute = false;
  int _elapsedSeconds = 0;
  Timer? _ticker;
  late final CallSignalingService _signaling;
  late final StreamCallEngine _streamEngine;
  bool _placedInvite = false;

  @override
  void initState() {
    super.initState();
    VoiceCallPage.isMounted = true;
    _signaling = GetIt.I<CallSignalingService>();
    _streamEngine = GetIt.I<StreamCallEngine>();
    _signaling.activeCallListenable.addListener(_onActiveCallChanged);
    WidgetsBinding.instance.addObserver(this);
    final existing = _signaling.current;
    // ignore: avoid_print
    print('[VoiceCallPage] 🟢 MOUNTED · conversationId=${widget.conversationId} '
        '· existing=${existing?.callId}/${existing?.state} '
        '· isMounted set to true');
    // If we already have an active call for this conversation we're
    // the callee on an accepted invite — start in connected. Otherwise
    // place an outgoing invite.
    if (existing != null &&
        existing.conversationId == widget.conversationId) {
      if (existing.state == CallSignalState.connected) {
        _stage = _CallStage.connected;
        _startTicker();
      }
    } else if (widget.isOutgoing) {
      _placedInvite = true;
      // Gate the outgoing call on microphone permission (iOS-only — Android
      // unchanged). Without mic the Stream join fails silently and the ring
      // never reaches the peer. Run after first frame so the dialog has a
      // valid Overlay.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_placeOutgoingWithPermission());
      });
    } else {
      // No matching active call AND this wasn't a user-initiated outgoing
      // call — this is a spurious/restored mount (e.g. a lingering call route
      // re-materialised after the previous call ended, or app resume). Do NOT
      // place a call. Give a short grace for a legit incoming `_active` to
      // arrive (accept-path race), then pop if none does — otherwise we'd
      // silently dial the peer back (the reported bug).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future<void>.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;
          final cur = _signaling.current;
          final hasCallForThisConv = cur != null &&
              cur.conversationId == widget.conversationId &&
              cur.state != CallSignalState.ended;
          if (!hasCallForThisConv) {
            // ignore: avoid_print
            print('[VoiceCallPage] spurious mount (no outgoing intent, no '
                'active call for conv=${widget.conversationId}) — popping '
                'instead of placing a call');
            Navigator.of(context).maybePop();
          }
        });
      });
    }
  }

  /// Trigger the native mic prompt (iOS-only) the moment the call page
  /// opens, then place the outgoing invite REGARDLESS of the result. The
  /// ring sent to the callee is a REST invite that doesn't need the mic, so
  /// the other side must always ring; if the user denies the mic, A simply
  /// transmits no audio. (Old behaviour popped the page on denial, so the
  /// callee never rang — that's the bug this fixes.)
  Future<void> _placeOutgoingWithPermission() async {
    await ensureCallPermissions();
    if (!mounted) return;
    _signaling.startOutgoing(
      conversationId: widget.conversationId,
      callType: ChatCallType.voice,
    );
  }

  @override
  void dispose() {
    VoiceCallPage.isMounted = false;
    // ignore: avoid_print
    print('[VoiceCallPage] 🔴 DISPOSED · conversationId=${widget.conversationId} '
        '· final _stage=$_stage · final active=${_signaling.current?.callId}'
        '/${_signaling.current?.state} · isMounted set to false');
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _signaling.activeCallListenable.removeListener(_onActiveCallChanged);
    // If this call was answered over the lock screen, drop the app back
    // behind the keyguard now that it's over — instead of revealing the
    // unlocked dashboard. No-op for calls started inside the unlocked app.
    //
    // CRITICAL: only do this when the call ACTUALLY ENDED. dispose() also
    // fires when go_router's splash→dashboard redirect spuriously WIPES
    // this page mid-call (the IncomingCallOverlay then re-pushes it). If we
    // dropped to the lock screen on that wipe, the user would see the lock
    // screen while the call is still live and connected — the reported
    // "B accept → shows lock screen" bug. A live call leaves `_stage` at
    // `connected`; only a real end sets it to `ended`.
    final callReallyEnded = _stage == _CallStage.ended ||
        _signaling.current == null ||
        _signaling.current?.state == CallSignalState.ended;
    if (callReallyEnded) {
      unawaited(LockScreenReturn.returnToLockScreenIfShownOver());
    } else {
      // ignore: avoid_print
      print('[VoiceCallPage] dispose while still connected (spurious wipe) '
          '— NOT returning to lock screen; overlay will re-push');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ignore: avoid_print
    print('[VoiceCallPage] lifecycle → $state · active=${_signaling.current?.callId}'
        '/${_signaling.current?.state}');
    // GET /chats/calls/{id} — recover canonical state if STOMP missed
    // a `call.accept` / `call.hangup` while we were backgrounded.
    // No-op when the active call doesn't have a backend id yet
    // (the swap from `call-<me>-<ts>` to numeric happens once
    // `sendCallInvite` returns).
    if (state == AppLifecycleState.resumed) {
      // ignore: avoid_print
      print('[VoiceCallPage] resumed → calling signaling.reconcileActive() '
          '(guarded by 5 s grace; backend ENDED in that window will be ignored)');
      unawaited(_signaling.reconcileActive());
      // Re-apply the audio route. Android's audio manager often
      // resets Speakerphone/Earpiece routing when the activity loses
      // focus (minimize, screen-off, switch app). Without this
      // re-apply, the user opens the call back up to silence even
      // though Stream's foreground service kept the call alive — the
      // audio is going to a device that has no output (earpiece on
      // a phone lying on a table).
      if (_stage == _CallStage.connected) {
        unawaited(_applyAudioRoute(_speaker));
        unawaited(_applyMicState(_muted));
      }
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);
    });
  }

  /// Route audio to the loudspeaker or earpiece via the platform
  /// audio manager. Best-effort — swallows errors so a flaky route
  /// switch never crashes the call page.
  Future<void> _applyAudioRoute(bool speaker) async {
    try {
      await rtc.Helper.setSpeakerphoneOn(speaker);
    } catch (_) {/* swallow */}
  }

  /// Toggle the local microphone on the active Stream call. The
  /// engine's `callNotifier` holds the live `Call` ref once joined;
  /// before that there's nothing to mute (the user shouldn't be able
  /// to tap before the page reaches `connected`, but guard anyway).
  Future<void> _applyMicState(bool muted) async {
    final call = _streamEngine.callNotifier.value;
    if (call == null) return;
    try {
      await call.setMicrophoneEnabled(enabled: !muted);
    } catch (_) {/* swallow */}
  }

  void _onActiveCallChanged() {
    final call = _signaling.activeCallListenable.value;
    if (!mounted) return;
    if (call == null) {
      // ignore: avoid_print
      print('[VoiceCallPage] _onActiveCallChanged · call=NULL — '
          'scheduling pop in 200 ms (active was cleared)');
      // Service cleared the active call (other side hung up + grace
      // period elapsed). Close ourselves if not already ending.
      if (_stage != _CallStage.ended) {
        setState(() => _stage = _CallStage.ended);
      }
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && Navigator.canPop(context)) {
          // ignore: avoid_print
          print('[VoiceCallPage] popping route now (after 200 ms grace)');
          Navigator.pop(context);
        }
      });
      return;
    }
    // ignore: avoid_print
    print('[VoiceCallPage] _onActiveCallChanged · ${call.callId}/${call.state} '
        '· endReason=${call.endReason}');
    setState(() {
      _stage = switch (call.state) {
        CallSignalState.outgoingRinging => _CallStage.calling,
        CallSignalState.incomingRinging => _CallStage.ringing,
        CallSignalState.connected => _CallStage.connected,
        CallSignalState.ended => _CallStage.ended,
        CallSignalState.idle => _CallStage.ended,
      };
    });
    if (call.state == CallSignalState.connected && _ticker == null) {
      _startTicker();
    }
    // Apply the default audio route (speaker) the first time we reach
    // connected. The Stream SDK defaults to earpiece for voice calls
    // which is too quiet at arm's length — most users testing a demo
    // expect speaker on. Done once per call so a user-toggle later
    // isn't overridden on every state change.
    if (call.state == CallSignalState.connected &&
        !_appliedInitialAudioRoute) {
      _appliedInitialAudioRoute = true;
      unawaited(_applyAudioRoute(_speaker));
    }
    // Slice 10.2.4 — show a friendly toast when the peer rejected
    // with a known reason. The page is about to pop in ~600ms; the
    // snackbar floats above the next route.
    if (call.state == CallSignalState.ended && call.endReason != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final reason = switch (call.endReason) {
          'busy' => '${call.peerName} is on another call.',
          'declined' => '${call.peerName} declined the call.',
          // `already_in_call` can mean either side has a stale row.
          // Avoid claiming A is the one in another call when it might
          // actually be B — keep the message neutral.
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

  Future<void> _endCall() async {
    _ticker?.cancel();
    await _signaling.hangup();
  }

  String get _statusLabel {
    switch (_stage) {
      case _CallStage.calling:
        return _placedInvite ? 'Calling…' : 'Ringing…';
      case _CallStage.ringing:
        return 'Ringing…';
      case _CallStage.connected:
        final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
        final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
        return '$m:$s';
      case _CallStage.ended:
        return 'Call ended';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: StreamBuilder<ChatConversation?>(
        stream: GetIt.I<ConversationsRepository>()
            .watchById(widget.conversationId),
        builder: (context, snap) {
          final conv = snap.data;
          // Fallback identity for the cold-start / lock-screen accept
          // path: the pushed conversationId may not resolve to a local
          // ChatConversation yet (watchById → null), but the ActiveCall
          // always carries the caller's name + avatar from the push
          // payload. Without this the screen showed only a waveform with
          // no name/avatar.
          final active = _signaling.activeCallListenable.value;
          final displayName = conv?.name ??
              active?.conversationName ??
              active?.peerName ??
              'Unknown';
          final avatarPath =
              conv?.avatarFilePath ?? active?.conversationAvatarFilePath;
          final isGroup = conv?.isGroup ?? active?.isGroup ?? false;
          final hasIdentity = conv != null || active != null;
          return Stack(
            children: [
              // Background gradient.
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0F1117),
                        Color(0xFF1A2035),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: AppLabel(
                        text: 'Voice Call',
                        fontSize: AppFontSize.value12,
                        color: Colors.white.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    if (hasIdentity) ...[
                      _PulsingAvatar(
                        name: displayName,
                        avatarFilePath: avatarPath,
                        isGroup: isGroup,
                        previews: conv?.participantPreviews ?? const [],
                        active: _stage == _CallStage.calling ||
                            _stage == _CallStage.ringing,
                      ),
                      const SizedBox(height: 24),
                      AppLabel(
                        text: displayName,
                        fontSize: AppFontSize.value25,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                      const SizedBox(height: 10),
                      AppLabel(
                        text: _statusLabel,
                        fontSize: AppFontSize.value16,
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ],
                    if (_stage == _CallStage.connected) ...[
                      const SizedBox(height: 20),
                      _Waveform(),
                    ],
                    const Spacer(flex: 2),
                    _ControlsRow(
                      muted: _muted,
                      speaker: _speaker,
                      onMute: () {
                        setState(() => _muted = !_muted);
                        unawaited(_applyMicState(_muted));
                      },
                      onSpeaker: () {
                        setState(() => _speaker = !_speaker);
                        unawaited(_applyAudioRoute(_speaker));
                      },
                      onKeypad: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Keypad UI would open here.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    _EndButton(onTap: _endCall),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PulsingAvatar extends StatelessWidget {
  const _PulsingAvatar({
    required this.name,
    required this.avatarFilePath,
    required this.isGroup,
    required this.previews,
    required this.active,
  });
  final String name;
  final String? avatarFilePath;
  final bool isGroup;
  final List<ChatParticipantPreview> previews;
  final bool active;

  @override
  Widget build(BuildContext context) {
    // Render from PRIMITIVES (not a full ChatConversation) so the call
    // screen still shows the caller's photo/initials on the cold-start /
    // lock-screen accept path, where the local ChatConversation may not
    // resolve yet — the values then come from the ActiveCall payload.
    //
    // Slice 10.2.10 — render the group's photo when one has been set
    // (Slice 10.3.3 stored it on `avatarFilePath`). Falls back to the
    // 3-avatar cluster when no photo exists. Direct calls always use
    // ChatAvatar — same as before.
    final hasPhoto = (avatarFilePath ?? '').isNotEmpty;
    final avatar = isGroup
        ? (hasPhoto
            ? ChatAvatar(
                name: name,
                size: 112,
                avatarFilePath: avatarFilePath,
                showStatus: false,
              )
            : GroupAvatarCluster(
                previews: previews,
                size: 112,
              ))
        : ChatAvatar(
            name: name,
            size: 112,
            avatarFilePath: avatarFilePath,
            showStatus: false,
          );

    final wrapped = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 2,
            ),
          ),
        ),
        avatar,
      ],
    );

    if (!active) return wrapped;
    return wrapped
        .animate(onPlay: (c) => c.repeat())
        .scaleXY(
          begin: 1,
          end: 1.06,
          duration: 1200.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _Waveform extends StatefulWidget {
  @override
  State<_Waveform> createState() => _WaveformState();
}

class _WaveformState extends State<_Waveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  static const int barCount = 20;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 36,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < barCount; i++)
                _bar(i, _ctrl.value),
            ],
          );
        },
      ),
    );
  }

  Widget _bar(int i, double t) {
    final phase = (t + i / barCount) % 1.0;
    final h = 8 + 24 * (1 - (phase * 2 - 1).abs());
    return Container(
      width: 4,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.muted,
    required this.speaker,
    required this.onMute,
    required this.onSpeaker,
    required this.onKeypad,
  });
  final bool muted;
  final bool speaker;
  final VoidCallback onMute;
  final VoidCallback onSpeaker;
  final VoidCallback onKeypad;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CircleButton(
          icon: muted ? Icons.mic_off_rounded : Icons.mic_rounded,
          active: muted,
          activeColor: Colors.red,
          label: muted ? 'Muted' : 'Mute',
          onTap: onMute,
        ),
        _CircleButton(
          icon: Icons.volume_up_rounded,
          active: speaker,
          activeColor: const Color(0xFF6366F1),
          label: speaker ? 'Speaker' : 'Earpiece',
          onTap: onSpeaker,
        ),
        _CircleButton(
          icon: Icons.dialpad_rounded,
          active: false,
          label: 'Keypad',
          onTap: onKeypad,
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
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
        ? (activeColor ?? Colors.white).withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.12);
    final fg = active ? Colors.white : Colors.white.withValues(alpha: 0.9);
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
              width: 64,
              height: 64,
              child: Icon(icon, color: fg, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppLabel(
          text: label,
          fontSize: AppFontSize.value12,
          color: Colors.white.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }
}

class _EndButton extends StatelessWidget {
  const _EndButton({required this.onTap});
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
              width: 72,
              height: 72,
              child: Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        AppLabel(
          text: 'End',
          fontSize: AppFontSize.value12,
          color: Colors.white.withValues(alpha: 0.8),
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }
}
