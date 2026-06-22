import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/app_font_size.dart';
import '../../../../core/theme/app_label.dart';
import '../../data/call_signaling_service.dart';
import '../../data/lockscreen_return.dart';
import '../../entities/call_log.dart';
import '../pages/video_call_page.dart';
import '../pages/voice_call_page.dart';
import 'call_permission_gate.dart';

/// Slice 10.2.3 — root-level overlay that listens to
/// [CallSignalingService.activeCall] and shows a full-screen incoming-
/// call sheet the moment a peer fires `call.invite`. Sits inside
/// [MaterialApp.builder] so it can paint over every route (including
/// modal sheets) regardless of where the user is when the call lands.
class IncomingCallOverlay extends StatefulWidget {
  const IncomingCallOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<IncomingCallOverlay> createState() => _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends State<IncomingCallOverlay> {
  CallSignalingService? _signaling;
  String? _displayedCallId;

  /// Listener installed on `activeCallListenable` to auto-push the
  /// in-call page when state transitions to connected. Without this,
  /// the cold-start kill→accept path can silently lose the
  /// `_handleAccept` push (it happens while go_router is still
  /// transitioning splash → dashboard, and the pushed route gets
  /// replaced when the redirect lands).
  /// True while go_router is still resolving the cold-start splash
  /// (`/`) — pushing the call page now would be wiped the instant the
  /// splash→dashboard redirect lands (the "call page → dashboard flash →
  /// call page" bug). We defer the push until the router settles on a
  /// real destination. Returns true on any read failure (treat unknown
  /// as not-yet-settled → keep waiting).
  bool _onSplashOrUnknown() {
    try {
      final path = GetIt.I<AppRouter>()
          .config
          .routerDelegate
          .currentConfiguration
          .uri
          .path;
      return path.isEmpty || path == RoutePaths.splash;
    } catch (_) {
      return true;
    }
  }

  void _autoPushOnConnected() {
    final call = _signaling?.activeCallListenable.value;
    if (call == null) return;
    if (call.state != CallSignalState.connected) return;
    // Kick off the retry loop. It self-cancels when the page sticks
    // (isMounted=true) OR when the call ends (state != connected)
    // OR after the max attempts run out.
    _ensureCallPagePushedWithRetry(call);
  }

  /// Tracks whether a retry loop is already running for the current
  /// call, so we don't stack overlapping loops if the state listener
  /// fires multiple times (e.g. participant updates emit while
  /// connected).
  String? _activeRetryLoopCallId;

  /// Push the call page repeatedly during the 6 s WATCH WINDOW after
  /// state→connected. On cold-start, go_router's splash → dashboard
  /// `context.go()` REPLACES the route stack — wiping any route we
  /// pushed before the redirect completed. The wipe can happen AFTER
  /// our initial push succeeded (so the simple "already mounted →
  /// done" check exits the loop prematurely, then the wipe happens
  /// later with no one watching).
  ///
  /// To handle that: we KEEP CHECKING for the full 6 s. Each tick:
  ///   * if the call is gone → cancel
  ///   * if the page is mounted → don't push, but DO continue
  ///     watching (in case a later redirect wipes it)
  ///   * if the page is NOT mounted → push it
  void _ensureCallPagePushedWithRetry(ActiveCall call) {
    // Don't stack loops — if one is already running for this call,
    // it'll handle subsequent wipes too.
    if (_activeRetryLoopCallId == call.callId) {
      return;
    }
    _activeRetryLoopCallId = call.callId;

    const maxTicks = 12; // 12 × 500 ms = 6 s watch window
    var tickCount = 0;
    // Has the call page EVER mounted during this watch window? Once it
    // has, a later not-mounted reading means go_router wiped it → re-push
    // is correct. But BEFORE it has ever mounted, a not-mounted reading
    // just means our (single) push is still landing on a busy cold-start
    // engine — re-pushing there stacks a second page (the 2-page bug).
    var everMounted = false;
    // Have we already issued a push that's still pending its first mount?
    var pushPending = false;
    // Bounded poll count while the router is still on the splash, so a
    // genuinely stuck splash can't loop forever (40 × 300 ms = 12 s).
    var splashPolls = 0;
    void tick() {
      // Bail FIRST so we stop even while parked waiting for the splash
      // redirect to settle.
      final current = _signaling?.activeCallListenable.value;
      if (current == null ||
          current.callId != call.callId ||
          current.state != CallSignalState.connected) {
        // ignore: avoid_print
        print('[IncomingCallOverlay] auto-push: cancelling watch loop '
            '(tick $tickCount) — call ${call.callId} no longer '
            'connected (state=${current?.state})');
        _activeRetryLoopCallId = null;
        return;
      }
      // Splash gate: while go_router is still resolving the cold-start
      // splash→dashboard redirect, ANY push lands on a stack that's
      // about to be replaced → it gets wiped and the user sees the
      // dashboard flash before the page re-appears. Park here (polling
      // every 300 ms) WITHOUT burning the post-splash watch budget until
      // the router settles, then push exactly once.
      if (_onSplashOrUnknown() && splashPolls < 40) {
        splashPolls++;
        // ignore: avoid_print
        print('[IncomingCallOverlay] auto-push: router still on splash '
            '(poll $splashPolls) — deferring push for callId=${call.callId}');
        Future.delayed(const Duration(milliseconds: 300), tick);
        return;
      }
      tickCount++;
      final isVideo = call.callType == ChatCallType.video;
      final alreadyMounted = isVideo
          ? VideoCallPage.isMounted
          : VoiceCallPage.isMounted;
      if (alreadyMounted) {
        // The page is up — our pending push (if any) landed.
        everMounted = true;
        pushPending = false;
      } else {
        // Push ONLY when this is the first attempt, or when the page had
        // mounted and then got wiped (go_router redirect). Do NOT push
        // again merely because a prior push hasn't mounted yet — that is
        // what stacked the page twice on a slow cold start.
        final shouldPush = (!pushPending && !everMounted) || everMounted;
        if (shouldPush) {
          final navigator = AppRouter.rootNavigatorKey.currentState;
          if (navigator != null) {
            // ignore: avoid_print
            print('[IncomingCallOverlay] auto-push tick $tickCount/$maxTicks '
                '· pushing ${isVideo ? "VideoCallPage" : "VoiceCallPage"} '
                'for callId=${call.callId} '
                '(${everMounted ? "page was wiped — re-pushing" : "first push"})');
            navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => isVideo
                    ? VideoCallPage(conversationId: call.conversationId)
                    : VoiceCallPage(conversationId: call.conversationId),
                fullscreenDialog: true,
              ),
            );
            pushPending = true;
            everMounted = false; // wait for THIS push to mount
          }
        }
      }
      // Continue watching even if mounted — a later redirect could
      // still wipe the page. Stop only after the full watch window.
      if (tickCount < maxTicks) {
        Future.delayed(const Duration(milliseconds: 500), tick);
      } else {
        // ignore: avoid_print
        print('[IncomingCallOverlay] auto-push: watch window closed '
            '($maxTicks × 500 ms) for callId=${call.callId} · '
            'finalMounted=$alreadyMounted');
        _activeRetryLoopCallId = null;
      }
    }
    tick();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Resolve via GetIt lazily — the service is registered after
    // configureDependencies() in main.dart, so the very first build
    // could fall through if we resolved in initState.
    if (_signaling == null) {
      _signaling = GetIt.I<CallSignalingService>();
      _signaling!.activeCallListenable.addListener(_autoPushOnConnected);
    }
  }

  @override
  void dispose() {
    _signaling?.activeCallListenable.removeListener(_autoPushOnConnected);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ValueListenableBuilder<ActiveCall?>(
          valueListenable: _signaling!.activeCallListenable,
          builder: (context, call, _) {
            // Show the full-screen incoming sheet only for calls that
            // landed from a peer and are still in the ringing state.
            // Outgoing-ringing / connected / ended states are handled
            // by the call page itself.
            final shouldShow = call != null &&
                call.state == CallSignalState.incomingRinging;
            if (shouldShow && call.callId != _displayedCallId) {
              _displayedCallId = call.callId;
              HapticFeedback.heavyImpact();
              // The in-app full-screen sheet is now taking over this
              // ringing call. Tear down any native heads-up notification
              // for it (the `erp_callkit` CallStyle ring / CallKit ringer)
              // so the user doesn't see BOTH the notification header AND
              // this sheet stacked for the same call.
              //
              // Lock-aware: only dismiss the native CallKit when the device
              // is UNLOCKED (where this sheet is actually visible and should
              // replace it). On a LOCKED screen this sheet is hidden behind
              // the keyguard, and the native CallKit screen is the only call
              // UI iOS allows there — dismissing it would drop the user to
              // the bare lock wallpaper on a killed+locked accept. So keep
              // it. (Android / unlocked iOS: same as before.)
              unawaited(
                _signaling?.clearNativeIncomingIfUnlocked(call.callId) ??
                    Future<void>.value(),
              );
            } else if (!shouldShow) {
              _displayedCallId = null;
            }
            if (!shouldShow) return const SizedBox.shrink();
            return _IncomingCallSheet(call: call);
          },
        ),
      ],
    );
  }
}

class _IncomingCallSheet extends StatefulWidget {
  const _IncomingCallSheet({required this.call});
  final ActiveCall call;

  @override
  State<_IncomingCallSheet> createState() => _IncomingCallSheetState();
}

class _IncomingCallSheetState extends State<_IncomingCallSheet>
    with SingleTickerProviderStateMixin {
  /// Soft pulse driving the avatar glow ring — a calm "this is ringing"
  /// cue, in keeping with the design guide's biometric/ring pulse rule
  /// (scale 1.0→~1.18, 1.4 s, repeat-reverse). Lives here, not on the
  /// avatar, so the avatar widget stays a dumb renderer.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  ActiveCall get call => widget.call;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        // Polished dialer backdrop — vertical gradient instead of a flat
        // black wash, so the hero + buttons read as a deliberate call
        // screen rather than a dimmed sheet.
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1A2238),
                Color(0xFF0B0D14),
                Color(0xFF000000),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                // Slice 10.2.9 — surface "Incoming group voice/video
                // call" for group calls so the recipient knows it's not
                // a 1:1 invite.
                AppLabel(
                  text: _typeLabel(call),
                  fontSize: AppFontSize.value13,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
                const Spacer(),
                // Pulsing glow ring behind the avatar hero.
                SizedBox(
                  width: 196,
                  height: 196,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) {
                          final scale = 1.0 + 0.20 * _pulse.value;
                          final alpha = 0.30 * (1 - _pulse.value);
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.greenAccent
                                    .withValues(alpha: alpha),
                              ),
                            ),
                          );
                        },
                      ),
                      _IncomingAvatar(call: call),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // For groups the title is the GROUP name (e.g. "TEST01").
                // For direct calls it stays the caller's name.
                AppLabel(
                  text: call.isGroup
                      ? (call.conversationName ?? 'Group call')
                      : call.peerName,
                  fontSize: AppFontSize.value25,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Callee-side status line. "Ringing…" was wrong here —
                // that's the CALLER's wording. The callee is RECEIVING
                // the call, so phrase it as the caller calling them.
                AppLabel(
                  text: '${call.peerName} is calling…',
                  fontSize: AppFontSize.value16,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _BigCircleButton(
                      icon: Icons.call_end_rounded,
                      label: 'Decline',
                      color: Colors.red.shade600,
                      onTap: () {
                        GetIt.I<CallSignalingService>().rejectIncoming();
                        // Declined from the lock screen → drop back behind
                        // the keyguard instead of revealing the dashboard.
                        unawaited(
                          LockScreenReturn.returnToLockScreenIfShownOver(),
                        );
                      },
                    ),
                    _BigCircleButton(
                      icon: call.callType == ChatCallType.video
                          ? Icons.videocam_rounded
                          : Icons.call_rounded,
                      label: 'Accept',
                      color: Colors.green.shade600,
                      onTap: () async {
                        final signaling = GetIt.I<CallSignalingService>();
                        // Slice 10.2.9 — push via the root navigator's
                        // GlobalKey, NOT `Navigator.of(context)`. The
                        // overlay is mounted via `MaterialApp.builder` so
                        // the GoRouter's Navigator is a SIBLING (inside
                        // `child` in the Stack), not an ancestor of this
                        // sheet — `Navigator.of(context)` would walk up
                        // and find no Navigator at all, silently dropping
                        // the push. That was the "accept just closes" bug
                        // that survived Slice 10.2.8.
                        final navigator =
                            AppRouter.rootNavigatorKey.currentState;
                        if (navigator == null) {
                          // Should never happen in practice — the router
                          // owns the key for the whole app lifetime — but
                          // bail rather than crash if the gate's somehow
                          // not yet mounted.
                          return;
                        }
                        // Show the callee's native mic (+ camera for video)
                        // prompt the moment they accept (iOS-only; Android
                        // unchanged). We DON'T block the call on the result —
                        // accept regardless so the call still connects; a
                        // denied mic just means the callee transmits no audio.
                        await ensureCallPermissions(
                          needCamera: call.callType == ChatCallType.video,
                        );
                        navigator.push(
                          MaterialPageRoute(
                            builder: (_) => call.callType == ChatCallType.video
                                ? VideoCallPage(
                                    conversationId: call.conversationId)
                                : VoiceCallPage(
                                    conversationId: call.conversationId),
                            fullscreenDialog: true,
                          ),
                        );
                        // Fire-and-forget — the call page subscribes to
                        // the service and reacts to the connected state
                        // transition on its own.
                        signaling.acceptIncoming();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Slice 10.2.9 — top-bar label distinguishing group from direct
  /// incoming calls.
  static String _typeLabel(ActiveCall call) {
    final isVideo = call.callType == ChatCallType.video;
    if (call.isGroup) {
      return isVideo
          ? 'INCOMING GROUP VIDEO CALL'
          : 'INCOMING GROUP VOICE CALL';
    }
    return isVideo ? 'INCOMING VIDEO CALL' : 'INCOMING VOICE CALL';
  }
}

/// Slice 10.2.11 — incoming-sheet hero avatar. Prefers a user-set photo
/// (groups: Slice 10.3.3 / direct: Slice 10.3.5) when present; falls
/// back to a group icon for groups, or caller initials for direct
/// calls.
class _IncomingAvatar extends StatelessWidget {
  const _IncomingAvatar({required this.call});
  final ActiveCall call;

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        (call.conversationAvatarFilePath ?? '').isNotEmpty;
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 2,
        ),
        image: hasPhoto
            ? DecorationImage(
                image: FileImage(File(call.conversationAvatarFilePath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : (call.isGroup
              ? const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 56,
                )
              : AppLabel(
                  text: _initialsFor(call.peerName),
                  fontSize: AppFontSize.value40,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                )),
    );
  }

  static String _initialsFor(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _BigCircleButton extends StatelessWidget {
  const _BigCircleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 8,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 72,
              height: 72,
              child: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AppLabel(
          text: label,
          fontSize: AppFontSize.value13,
          color: Colors.white.withValues(alpha: 0.85),
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }
}
