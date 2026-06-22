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
@Table(name = "chat_message_reactions")
public class MessageReaction {

    @EmbeddedId
    private MessageReactionId id;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();
}
