package com.company.erp.features.chats.controller;

import com.company.erp.core.database.PageQuery;
import com.company.erp.core.response.PageResponse;
import com.company.erp.core.security.AuthenticatedUser;
import com.company.erp.features.chats.dto.CallParticipantDto;
import com.company.erp.features.chats.dto.ChatCallDto;
import com.company.erp.features.chats.dto.StartCallRequest;
import com.company.erp.features.chats.dto.StreamTokenDto;
import com.company.erp.features.chats.entity.CallStatus;
import com.company.erp.features.chats.entity.ChatCall;
import com.company.erp.features.chats.entity.ChatCallParticipant;
import com.company.erp.features.chats.entity.ParticipantStatus;
import com.company.erp.features.chats.service.ChatCallService;
import com.company.erp.features.chats.service.ConversationService;
import com.company.erp.features.chats.service.StreamTokenService;
import com.company.erp.features.chats.ws.ChatBroadcaster;
import com.company.erp.features.devices.entity.Device;
import com.company.erp.features.devices.service.DeviceService;
import com.company.erp.features.devices.service.FcmService;
import com.company.erp.features.users.entity.User;
import com.company.erp.features.users.repository.UserRepository;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/chats")
public class ChatCallController {

    private static final Logger log = LoggerFactory.getLogger(ChatCallController.class);

    private final ChatCallService calls;
    private final ConversationService conversations;
    private final ChatBroadcaster broadcaster;
    private final StreamTokenService streamTokens;
    private final DeviceService deviceService;
    private final FcmService fcm;
    private final UserRepository users;

    public ChatCallController(ChatCallService calls,
                              ConversationService conversations,
                              ChatBroadcaster broadcaster,
                              StreamTokenService streamTokens,
                              DeviceService deviceService,
                              FcmService fcm,
                              UserRepository users) {
        this.calls = calls;
        this.conversations = conversations;
        this.broadcaster = broadcaster;
        this.streamTokens = streamTokens;
        this.deviceService = deviceService;
        this.fcm = fcm;
        this.users = users;
    }

    /** My global call history across every conversation, newest-first. */
    @GetMapping("/calls")
    public PageResponse<ChatCallDto> myHistory(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "30") int pageSize) {
        Long me = AuthenticatedUser.require().userId();
        return PageResponse.from(
                calls.historyForUser(me, new PageQuery(page, pageSize, null, null)),
                this::toDto);
    }

    /** Call history for a single conversation (Chat Info "Recent calls" section). */
    @GetMapping("/conversations/{convId}/calls")
    public PageResponse<ChatCallDto> conversationHistory(
            @PathVariable Long convId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "30") int pageSize) {
        Long me = AuthenticatedUser.require().userId();
        return PageResponse.from(
                calls.historyForConversation(convId, me, new PageQuery(page, pageSize, null, null)),
                this::toDto);
    }

    /** Fetch a call's current state for reconciliation after a reconnect. */
    @GetMapping("/calls/{id}")
    public ChatCallDto get(@PathVariable Long id) {
        AuthenticatedUser.require();
        return toDto(calls.getById(id));
    }

    /** Start a voice or video call in a conversation; rings every other member. */
    @PostMapping("/conversations/{convId}/calls")
    public ChatCallDto start(@PathVariable Long convId, @Valid @RequestBody StartCallRequest body) {
        Long me = AuthenticatedUser.require().userId();
        log.info("[call] START requested by user={} conv={} type={}", me, convId, body.type());
        ChatCall c = calls.start(convId, me, body);
        ChatCallDto dto = toDto(c);
        log.info("[call] START ok callId={} streamCallCid={} participants={}",
                c.getId(), c.getStreamCallCid(), dto.participants().size());
        broadcaster.toCall(convId, "call.invite", dto);
        c.getParticipants().stream()
                .filter(p -> !p.getUserId().equals(me))
                .forEach(p -> {
                    log.info("[call] INVITE fan-out callId={} → user={} (queue/calls)", c.getId(), p.getUserId());
                    broadcaster.toUser(p.getUserId(), "calls", "call.invite", dto);
                });
        pushInvite(c, me);
        return dto;
    }

    /** Callee accepts a ringing call; flips status to ANSWERED + marks them BUSY. */
    @PostMapping("/calls/{id}/accept")
    public ChatCallDto accept(@PathVariable Long id) {
        Long me = AuthenticatedUser.require().userId();
        log.info("[call] ACCEPT callId={} by user={}", id, me);
        ChatCall c = calls.accept(id, me);
        ChatCallDto dto = toDto(c);
        log.info("[call] ACCEPT ok callId={} status={} streamCallCid={}",
                id, c.getStatus(), c.getStreamCallCid());
        broadcaster.toCall(c.getConversationId(), "call.accept",
                Map.of("callId", id, "accepterId", me, "call", dto));
        // Cancel any leftover ring notification on this user's other devices.
        pushCancelTo(List.of(me), id, c.getStreamCallCid(), "accepted_elsewhere");
        return dto;
    }

    /** Callee declines a ringing call with an optional reason (e.g. "busy"). */
    @PostMapping("/calls/{id}/reject")
    public ChatCallDto reject(@PathVariable Long id,
                              @RequestParam(required = false) String reason) {
        Long me = AuthenticatedUser.require().userId();
        log.info("[call] REJECT callId={} by user={} reason={}", id, me, reason);
        ChatCall c = calls.reject(id, me, reason);
        ChatCallDto dto = toDto(c);
        broadcaster.toCall(c.getConversationId(), "call.reject",
                Map.of("callId", id, "rejecterId", me, "reason", reason == null ? "" : reason, "call", dto));
        // If the reject ended the whole call (1:1 case), cancel ring on others still pending.
        pushCancelOnTerminal(c, me, "rejected");
        return dto;
    }

    /** Mint a short-lived Stream Video token so the mobile SDK can join the media call. */
    @GetMapping("/calls/stream-token")
    public StreamTokenDto streamToken() {
        Long me = AuthenticatedUser.require().userId();
        log.info("[stream] TOKEN requested by user={}", me);
        StreamTokenDto dto = streamTokens.issueFor(me);
        log.info("[stream] TOKEN ok user={} expiresAt={}", me, dto.expiresAt());
        return dto;
    }

    /** Hang up a call. Caller ending = everyone disconnects; last callee ending = caller auto-ends. */
    @PostMapping("/calls/{id}/end")
    public ChatCallDto end(@PathVariable Long id) {
        Long me = AuthenticatedUser.require().userId();
        log.info("[call] END callId={} by user={}", id, me);
        ChatCall c = calls.hangup(id, me);
        ChatCallDto dto = toDto(c);
        log.info("[call] END ok callId={} status={} durationSec={} reason={}",
                id, c.getStatus(), c.getDurationSeconds(), c.getEndReason());
        broadcaster.toCall(c.getConversationId(), "call.hangup",
                Map.of("callId", id, "hangerUpperId", me, "call", dto));
        pushCancelOnTerminal(c, me, "hangup");
        return dto;
    }

    private ChatCallDto toDto(ChatCall c) {
        List<CallParticipantDto> participants = c.getParticipants().stream()
                .map(CallParticipantDto::from).toList();
        return ChatCallDto.from(c, participants);
    }

    // ---- FCM helpers -------------------------------------------------------

    /** Data-only call.invite push to every participant except the caller. */
    private void pushInvite(ChatCall c, Long callerId) {
        List<Long> targetIds = c.getParticipants().stream()
                .filter(p -> !p.getUserId().equals(callerId))
                .map(ChatCallParticipant::getUserId)
                .toList();
        if (targetIds.isEmpty()) return;

        String callerName = users.findById(callerId).map(User::getFullName).orElse("");
        Map<String, String> data = new HashMap<>();
        data.put("type",           "call.invite");
        data.put("callId",         String.valueOf(c.getId()));
        data.put("conversationId", String.valueOf(c.getConversationId()));
        data.put("callerId",       String.valueOf(callerId));
        data.put("callerName",     callerName);
        data.put("callType",       c.getType().name().toLowerCase());
        data.put("startedAt",      c.getStartedAt().toString());
        data.put("streamCallCid",  c.getStreamCallCid() == null ? "" : c.getStreamCallCid());

        List<String> tokens = tokensFor(targetIds);
        log.info("[fcm] call.invite callId={} → users={} tokens={}", c.getId(), targetIds, tokens.size());
        fcm.sendDataToTokens(tokens, data);
    }

    /** If the call has entered a terminal state, fan a cancel to anyone still RINGING. */
    private void pushCancelOnTerminal(ChatCall c, Long actorId, String reason) {
        if (c.getStatus() == CallStatus.RINGING || c.getStatus() == CallStatus.ANSWERED) {
            return; // call still alive
        }
        List<Long> targetIds = c.getParticipants().stream()
                .filter(p -> !p.getUserId().equals(actorId))
                .filter(p -> p.getStatus() == ParticipantStatus.RINGING
                          || p.getStatus() == ParticipantStatus.ANSWERED)
                .map(ChatCallParticipant::getUserId)
                .toList();
        pushCancelTo(targetIds, c.getId(), c.getStreamCallCid(), reason);
    }

    private void pushCancelTo(List<Long> targetUserIds, Long callId, String streamCallCid, String reason) {
        if (targetUserIds.isEmpty()) return;
        Map<String, String> data = new HashMap<>();
        data.put("type",   "call.cancel");
        data.put("callId", String.valueOf(callId));
        // streamCallCid lets the iOS client map the cancel to the exact CallKit
        // entry (callkitIdForCid) instead of relying on endAllCalls.
        data.put("streamCallCid", streamCallCid == null ? "" : streamCallCid);
        data.put("reason", reason);
        List<String> tokens = tokensFor(targetUserIds);
        log.info("[fcm] call.cancel callId={} cid={} reason={} → users={} tokens={}",
                callId, streamCallCid, reason, targetUserIds, tokens.size());
        fcm.sendDataToTokens(tokens, data);
    }

    private List<String> tokensFor(List<Long> userIds) {
        return deviceService.listForUsers(userIds).stream()
                .map(Device::getFcmToken)
                .toList();
    }
}
