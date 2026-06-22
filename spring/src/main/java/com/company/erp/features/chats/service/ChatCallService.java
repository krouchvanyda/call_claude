package com.company.erp.features.chats.service;

import com.company.erp.core.config.AppProperties;
import com.company.erp.core.database.PageQuery;
import com.company.erp.core.exceptions.BadRequestException;
import com.company.erp.core.exceptions.NotFoundException;
import com.company.erp.features.chats.dto.StartCallRequest;
import com.company.erp.features.chats.entity.*;
import com.company.erp.features.chats.presence.PresenceService;
import com.company.erp.features.chats.presence.PresenceStatus;
import com.company.erp.features.chats.repository.ChatCallParticipantRepository;
import com.company.erp.features.chats.repository.ChatCallRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@Transactional
public class ChatCallService {

    private static final Logger log = LoggerFactory.getLogger(ChatCallService.class);

    private static final Set<CallStatus> OPEN_CALL_STATUSES =
            Set.of(CallStatus.RINGING, CallStatus.ANSWERED);
    private static final Set<ParticipantStatus> OPEN_PARTICIPANT_STATUSES =
            Set.of(ParticipantStatus.RINGING, ParticipantStatus.ANSWERED);

    private final ChatCallRepository calls;
    private final ChatCallParticipantRepository participants;
    private final ConversationService conversations;
    private final PresenceService presence;
    private final StreamTokenService streamTokens;
    private final StreamVideoService streamVideo;
    private final AppProperties props;

    public ChatCallService(ChatCallRepository calls,
                           ChatCallParticipantRepository participants,
                           ConversationService conversations,
                           PresenceService presence,
                           StreamTokenService streamTokens,
                           StreamVideoService streamVideo,
                           AppProperties props) {
        this.calls = calls;
        this.participants = participants;
        this.conversations = conversations;
        this.presence = presence;
        this.streamTokens = streamTokens;
        this.streamVideo = streamVideo;
        this.props = props;
    }

    private long ringTimeoutSeconds() {
        return (props.chat() == null || props.chat().call() == null
                || props.chat().call().ringTimeoutSeconds() <= 0)
                ? 60L
                : props.chat().call().ringTimeoutSeconds();
    }

    private long acceptGraceSeconds() {
        return (props.chat() == null || props.chat().call() == null
                || props.chat().call().acceptGraceSeconds() < 0)
                ? 5L
                : props.chat().call().acceptGraceSeconds();
    }

    @Transactional(readOnly = true)
    public ChatCall getById(Long callId) {
        return calls.findWithParticipantsById(callId)
                .orElseThrow(() -> new NotFoundException("Call not found"));
    }

    @Transactional(readOnly = true)
    public Page<ChatCall> historyForUser(Long userId, PageQuery query) {
        return calls.findAllForUser(userId,
                query.toPageable(Set.of("startedAt"), Sort.by(Sort.Direction.DESC, "startedAt")));
    }

    @Transactional(readOnly = true)
    public Page<ChatCall> historyForConversation(Long convId, Long userId, PageQuery query) {
        conversations.requireMember(convId, userId);
        return calls.findByConversationIdOrderByStartedAtDesc(convId,
                query.toPageable(Set.of("startedAt"), Sort.by(Sort.Direction.DESC, "startedAt")));
    }

    public ChatCall start(Long convId, Long callerId, StartCallRequest req) {
        conversations.requireMember(convId, callerId);
        if (calls.existsActiveCallForUser(callerId, OPEN_CALL_STATUSES, OPEN_PARTICIPANT_STATUSES)) {
            throw new BadRequestException("Caller is already in an active call");
        }

        ChatCall c = new ChatCall();
        c.setConversationId(convId);
        c.setCallerId(callerId);
        c.setType(req.type());
        c.setStatus(CallStatus.RINGING);
        c.setStartedAt(Instant.now());
        calls.save(c);
        // Now that the row has an id, stamp the Stream Video CID so every
        // participant joins the same Stream call.
        c.setStreamCallCid(streamTokens.cidForCall(c.getId()));

        Set<Long> memberIds = conversations.memberUserIds(convId);
        for (Long uid : memberIds) {
            ChatCallParticipant p = new ChatCallParticipant();
            p.setId(new ChatCallParticipantId(c.getId(), uid));
            p.setCall(c);
            if (uid.equals(callerId)) {
                p.setStatus(ParticipantStatus.ANSWERED);
                p.setJoinedAt(Instant.now());
            } else {
                p.setStatus(ParticipantStatus.RINGING);
            }
            participants.save(p);
        }
        // Caller is busy from the moment the call starts.
        presence.markBusy(callerId);
        // Ring the callees server-side via Stream's VoIP push (the native
        // CallKit / ConnectionService incoming-call screen) — but ONLY for
        // callees who are OFFLINE: no live STOMP session, which on iOS means
        // the app is backgrounded or killed (the Flutter client drops its
        // WebSocket via `disconnectForBackground` the moment it backgrounds).
        //
        // An ONLINE callee is foreground with the WebSocket up, so it already
        // received the STOMP `call.invite` (broadcast in ChatCallController)
        // and shows the IN-APP incoming-call overlay. Sending that foreground
        // device a VoIP push too is exactly what produced the duplicate native
        // ring header AND the contested audio session (CallKit + WebRTC both
        // grabbing AVAudioSession → mute/unmute yields silence). Gating the
        // ring at the source removes the foreground CallKit ring entirely —
        // no flash — and leaves the foreground audio session to WebRTC alone.
        // OFFLINE callees still get the VoIP push (their only way to ring).
        // Async + exception-swallowing, so a Stream hiccup never breaks
        // call signalling.
        Set<Long> ringTargets = memberIds.stream()
                .filter(uid -> !uid.equals(callerId))
                .filter(uid -> presence.statusOf(uid) == PresenceStatus.OFFLINE)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        if (ringTargets.isEmpty()) {
            log.info("[call] callId={} — all callees ONLINE; skipping Stream VoIP ring "
                    + "(in-app overlay handles foreground, no CallKit)", c.getId());
        } else {
            // Include the caller so Stream makes them the creator (creators are
            // NOT rung); only the OFFLINE callees in this set receive the push.
            Set<Long> ringMembers = new LinkedHashSet<>(ringTargets);
            ringMembers.add(callerId);
            log.info("[call] callId={} — ringing OFFLINE callees via VoIP push: {}",
                    c.getId(), ringTargets);
            streamVideo.ring(c.getStreamCallCid(), callerId, ringMembers);
        }
        // Reload via the EntityGraph so the caller can read c.getParticipants()
        // after the @Transactional boundary closes.
        return calls.findWithParticipantsById(c.getId())
                .orElseThrow(() -> new IllegalStateException("Just-created call not found"));
    }

    public ChatCall accept(Long callId, Long userId) {
        ChatCall c = getById(callId);

        // Grace-window revival — if the sweeper just marked it MISSED but the
        // accept arrives within `acceptGraceSeconds`, restore RINGING and proceed
        // so a late-by-a-few-seconds FCM accept doesn't get rejected.
        if (c.getStatus() == CallStatus.MISSED) {
            long ageSec = Duration.between(c.getStartedAt(), Instant.now()).getSeconds();
            long graceCutoff = ringTimeoutSeconds() + acceptGraceSeconds();
            if (ageSec <= graceCutoff) {
                log.info("[call] REVIVE callId={} accepter user={} ageSec={} graceCutoff={}",
                        callId, userId, ageSec, graceCutoff);
                c.setStatus(CallStatus.RINGING);
                c.setEndedAt(null);
                c.setEndReason(null);
                c.setDurationSeconds(null);
                ChatCallParticipant me = participants.findByCall_IdAndId_UserId(callId, userId)
                        .orElseThrow(() -> new NotFoundException("You are not a participant in this call"));
                if (me.getStatus() == ParticipantStatus.MISSED) {
                    me.setStatus(ParticipantStatus.RINGING);
                    me.setLeftAt(null);
                }
            } else {
                throw new BadRequestException("Call already ended");
            }
        } else if (c.getStatus() != CallStatus.RINGING && c.getStatus() != CallStatus.ANSWERED) {
            throw new BadRequestException("Call already ended");
        }

        ChatCallParticipant p = participants.findByCall_IdAndId_UserId(callId, userId)
                .orElseThrow(() -> new NotFoundException("You are not a participant in this call"));
        if (p.getStatus() != ParticipantStatus.RINGING) {
            return c;
        }
        p.setStatus(ParticipantStatus.ANSWERED);
        p.setJoinedAt(Instant.now());
        if (c.getStatus() == CallStatus.RINGING) {
            c.setStatus(CallStatus.ANSWERED);
            c.setAnsweredAt(Instant.now());
        }
        presence.markBusy(userId);
        return c;
    }

    public ChatCall reject(Long callId, Long userId, String reason) {
        ChatCall c = getById(callId);
        ChatCallParticipant p = participants.findByCall_IdAndId_UserId(callId, userId)
                .orElseThrow(() -> new NotFoundException("You are not a participant in this call"));
        if (p.getStatus() == ParticipantStatus.RINGING) {
            p.setStatus(ParticipantStatus.REJECTED);
            p.setLeftAt(Instant.now());
        }
        // If everyone else has rejected/left, the call ends.
        boolean anyoneActive = c.getParticipants().stream()
                .anyMatch(x -> !x.getUserId().equals(c.getCallerId())
                        && (x.getStatus() == ParticipantStatus.RINGING
                            || x.getStatus() == ParticipantStatus.ANSWERED));
        if (!anyoneActive && c.getStatus() == CallStatus.RINGING) {
            endCallInternal(c, c.getStatus() == CallStatus.RINGING
                    ? CallStatus.REJECTED
                    : CallStatus.ENDED, reason != null ? reason : "rejected");
        }
        return c;
    }

    public ChatCall hangup(Long callId, Long userId) {
        ChatCall c = getById(callId);
        ChatCallParticipant p = participants.findByCall_IdAndId_UserId(callId, userId)
                .orElseThrow(() -> new NotFoundException("You are not a participant in this call"));
        if (p.getStatus() == ParticipantStatus.ANSWERED || p.getStatus() == ParticipantStatus.RINGING) {
            p.setStatus(ParticipantStatus.LEFT);
            p.setLeftAt(Instant.now());
        }

        // Caller leaving ends the call for everyone (Slice 10.2.10 in the guide).
        if (userId.equals(c.getCallerId())) {
            endCallInternal(c, CallStatus.ENDED, "caller_left");
            return c;
        }

        // Otherwise: if no other callee is still in, end it.
        boolean anyoneStillActive = c.getParticipants().stream()
                .filter(x -> !x.getUserId().equals(c.getCallerId()))
                .anyMatch(x -> x.getStatus() == ParticipantStatus.RINGING
                            || x.getStatus() == ParticipantStatus.ANSWERED);
        if (!anyoneStillActive && c.getStatus() != CallStatus.ENDED) {
            endCallInternal(c, CallStatus.ENDED, "all_callees_left");
        } else {
            // Call continues; the user who left is no longer BUSY.
            presence.clearBusy(userId);
        }
        return c;
    }

    /**
     * Sweep every RINGING call older than the configured ring timeout and
     * transition it to MISSED. Called by {@code CallTimeoutScheduler}. Returns
     * the freshly-ended calls so the scheduler can fan out STOMP + FCM
     * notifications to the caller and unanswered callees.
     */
    public List<ChatCall> sweepStaleRinging() {
        Instant cutoff = Instant.now().minus(Duration.ofSeconds(ringTimeoutSeconds()));
        List<ChatCall> stale = calls.findStaleRinging(cutoff);
        List<ChatCall> ended = new ArrayList<>();
        for (ChatCall c : stale) {
            for (ChatCallParticipant p : c.getParticipants()) {
                if (p.getStatus() == ParticipantStatus.RINGING) {
                    p.setStatus(ParticipantStatus.MISSED);
                    p.setLeftAt(Instant.now());
                }
            }
            endCallInternal(c, CallStatus.MISSED, "no_answer");
            ended.add(c);
            log.info("[call] AUTO-MISSED callId={} after {}s (timeout={}s)",
                    c.getId(),
                    Duration.between(c.getStartedAt(), Instant.now()).getSeconds(),
                    ringTimeoutSeconds());
        }
        return ended;
    }

    private void endCallInternal(ChatCall c, CallStatus status, String reason) {
        c.setStatus(status);
        c.setEndedAt(Instant.now());
        c.setEndReason(reason);
        if (c.getAnsweredAt() != null) {
            c.setDurationSeconds((int) Duration.between(c.getAnsweredAt(), c.getEndedAt()).getSeconds());
        } else {
            c.setDurationSeconds(0);
        }
        // Clear BUSY for everyone who was active in this call.
        for (ChatCallParticipant p : c.getParticipants()) {
            if (p.getStatus() == ParticipantStatus.ANSWERED
                    || p.getStatus() == ParticipantStatus.LEFT) {
                presence.clearBusy(p.getUserId());
            }
        }
        // Caller, even if they never "answered", was busy from start.
        presence.clearBusy(c.getCallerId());

        // Cancel the Stream ring for every member. This is the single
        // chokepoint for EVERY terminal end (caller_left, all_callees_left,
        // rejected, no_answer/timeout), so a still-ringing callee that got the
        // ring via Stream's VoIP push — minimized / killed iOS, native CallKit —
        // is told the call is over through the SAME channel that raised it.
        // Without this, a backgrounded callee never learns the call ended
        // (its STOMP + Stream WS are both down) and the CallKit screen lingers
        // until Stream's ~ring-timeout. Async + swallowing; a no-op/404 when
        // the call was never created on Stream (all callees online).
        streamVideo.endCall(c.getStreamCallCid(), c.getCallerId());
    }

}
