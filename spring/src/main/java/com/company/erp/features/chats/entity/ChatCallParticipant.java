package com.company.erp.features.chats.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "chat_call_participants")
public class ChatCallParticipant {

    @EmbeddedId
    private ChatCallParticipantId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("callId")
    @JoinColumn(name = "call_id")
    private ChatCall call;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ParticipantStatus status = ParticipantStatus.RINGING;

    @Column(name = "joined_at")
    private Instant joinedAt;

    @Column(name = "left_at")
    private Instant leftAt;

    /** Convenience accessor — userId lives on the embedded id. */
    public Long getUserId() {
        return id == null ? null : id.getUserId();
    }
}
