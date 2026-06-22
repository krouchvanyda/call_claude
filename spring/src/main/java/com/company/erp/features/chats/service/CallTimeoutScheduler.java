package com.company.erp.features.chats.service;

import com.company.erp.features.chats.dto.CallParticipantDto;
import com.company.erp.features.chats.dto.ChatCallDto;
import com.company.erp.features.chats.entity.ChatCall;
import com.company.erp.features.chats.entity.ChatCallParticipant;
import com.company.erp.features.chats.entity.ParticipantStatus;
import com.company.erp.features.chats.ws.ChatBroadcaster;
import com.company.erp.features.devices.entity.Device;
import com.company.erp.features.devices.service.DeviceService;
import com.company.erp.features.devices.service.FcmService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Periodically auto-ends calls that stay in RINGING longer than
 * {@code app.chat.call.ring-timeout-seconds}, and fans the resulting
 * {@code call.hangup} envelope out over STOMP plus a {@code call.cancel}
 * FCM push so backgrounded ringers dismiss too.
 *
 * <p>Runs every 5 seconds. A 5s tick is fine because the timeout is 60s —
 * worst-case extra ring length is 5 seconds past the deadline.</p>
 */
@Component
public class CallTimeoutScheduler {

    private static final Logger log = LoggerFactory.getLogger(CallTimeoutScheduler.class);

    private final ChatCallService callService;
    private final ChatBroadcaster broadcaster;
    private final DeviceService devices;
    private final FcmService fcm;

    public CallTimeoutScheduler(ChatCallService callService,
                                ChatBroadcaster broadcaster,
                                DeviceService devices,
                                FcmService fcm) {
        this.callService = callService;
        this.broadcaster = broadcaster;
        this.devices = devices;
        this.fcm = fcm;
    }

    @Scheduled(fixedDelayString = "${app.chat.call.sweep-interval-ms:5000}")
    @Transactional
    public void sweep() {
        List<ChatCall> ended;
        try {
            ended = callService.sweepStaleRinging();
        } catch (Exception ex) {
            log.warn("[call-sweep] failure during sweepStaleRinging: {}", ex.getMessage());
            return;
        }
        if (ended.isEmpty()) return;
        log.info("[call-sweep] auto-ended {} stale RINGING call(s)", ended.size());

        for (ChatCall c : ended) {
            ChatCallDto dto = toDto(c);

            // STOMP: tell everyone the call is over so caller's "Calling…" page closes
            // and any other connected devices drop the ringer.
            broadcaster.toCall(c.getConversationId(), "call.hangup", Map.of(
                    "callId",         c.getId(),
                    "hangerUpperId",  c.getCallerId(),  // attributed to the caller
                    "reason",         "no_answer",
                    "call",           dto));

            // FCM: tell every participant's backgrounded device to dismiss the ring.
            List<Long> targetUserIds = c.getParticipants().stream()
                    .map(ChatCallParticipant::getUserId)
                    .toList();
            List<String> tokens = devices.listForUsers(targetUserIds).stream()
                    .map(Device::getFcmToken)
                    .toList();
            Map<String, String> data = new HashMap<>();
            data.put("type",   "call.cancel");
            data.put("callId", String.valueOf(c.getId()));
            data.put("reason", "timeout");
            log.info("[fcm] call.cancel (timeout) callId={} → users={} tokens={}",
                    c.getId(), targetUserIds, tokens.size());
            fcm.sendDataToTokens(tokens, data);
        }
    }

    private ChatCallDto toDto(ChatCall c) {
        List<CallParticipantDto> participants = c.getParticipants().stream()
                .filter(p -> p.getStatus() != null)  // defensive
                .map(CallParticipantDto::from).toList();
        return ChatCallDto.from(c, participants);
    }

    @SuppressWarnings("unused") // referenced by Lombok / future use
    private static boolean isStillActive(ChatCallParticipant p) {
        return p.getStatus() == ParticipantStatus.RINGING
                || p.getStatus() == ParticipantStatus.ANSWERED;
    }
}
