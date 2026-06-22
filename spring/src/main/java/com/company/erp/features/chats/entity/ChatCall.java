package com.company.erp.features.chats.entity;

import com.company.erp.core.database.BaseEntity;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

import java.time.Instant;
import java.util.HashSet;
import java.util.Set;

@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "chat_calls")
public class ChatCall extends BaseEntity {

    @Column(name = "conversation_id", nullable = false)
    private Long conversationId;

    @Column(name = "caller_id", nullable = false)
    private Long callerId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CallType type;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private CallStatus status = CallStatus.RINGING;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt = Instant.now();

    @Column(name = "answered_at")
    private Instant answeredAt;

    @Column(name = "ended_at")
    private Instant endedAt;

    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @Column(name = "end_reason")
    private String endReason;

    /** Stream Video call id (e.g. "default:erp-call-42") — null until start completes. */
    @Column(name = "stream_call_cid")
    private String streamCallCid;

    @OneToMany(mappedBy = "call", fetch = FetchType.LAZY)
    private Set<ChatCallParticipant> participants = new HashSet<>();
}
