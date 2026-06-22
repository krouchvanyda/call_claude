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
@Table(name = "chat_conversations")
public class Conversation extends BaseEntity {

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ConversationType type;

    /** Group name. Null for DIRECT. */
    @Column
    private String name;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @Column(name = "last_message_id")
    private Long lastMessageId;

    @Column(name = "last_message_at")
    private Instant lastMessageAt;

    @OneToMany(mappedBy = "conversation", fetch = FetchType.LAZY)
    private Set<ConversationMember> members = new HashSet<>();
}
