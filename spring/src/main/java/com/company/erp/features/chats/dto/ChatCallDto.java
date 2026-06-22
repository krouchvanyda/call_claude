package com.company.erp.features.chats.dto;

import com.company.erp.features.chats.entity.CallStatus;
import com.company.erp.features.chats.entity.CallType;
import com.company.erp.features.chats.entity.ChatCall;

import java.time.Instant;
import java.util.List;

public record ChatCallDto(
        Long id,
        Long conversationId,
        Long callerId,
        CallType type,
        CallStatus status,
        Instant startedAt,
        Instant answeredAt,
        Instant endedAt,
        Integer durationSeconds,
        String endReason,
        /** Stream Video call CID — clients fetch a token and join this call for media. */
        String streamCallCid,
        List<CallParticipantDto> participants
) {
    public static ChatCallDto from(ChatCall c, List<CallParticipantDto> participants) {
        return new ChatCallDto(
                c.getId(),
                c.getConversationId(),
                c.getCallerId(),
                c.getType(),
                c.getStatus(),
                c.getStartedAt(),
                c.getAnsweredAt(),
                c.getEndedAt(),
                c.getDurationSeconds(),
                c.getEndReason(),
                c.getStreamCallCid(),
                participants);
    }
}
