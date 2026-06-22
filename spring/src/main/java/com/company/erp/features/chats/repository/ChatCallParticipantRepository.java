package com.company.erp.features.chats.repository;

import com.company.erp.features.chats.entity.ChatCallParticipant;
import com.company.erp.features.chats.entity.ChatCallParticipantId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ChatCallParticipantRepository extends JpaRepository<ChatCallParticipant, ChatCallParticipantId> {

    Optional<ChatCallParticipant> findByCall_IdAndId_UserId(Long callId, Long userId);
}
