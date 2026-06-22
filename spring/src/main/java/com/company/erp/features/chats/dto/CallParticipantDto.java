package com.company.erp.features.chats.dto;

import com.company.erp.features.chats.entity.ChatCallParticipant;
import com.company.erp.features.chats.entity.ParticipantStatus;

import java.time.Instant;

public record CallParticipantDto(
        Long userId,
        ParticipantStatus status,
        Instant joinedAt,
        Instant leftAt
) {
    public static CallParticipantDto from(ChatCallParticipant p) {
        return new CallParticipantDto(p.getUserId(), p.getStatus(), p.getJoinedAt(), p.getLeftAt());
    }
}
