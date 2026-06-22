package com.company.erp.features.chats.repository;

import com.company.erp.features.chats.entity.MessageReaction;
import com.company.erp.features.chats.entity.MessageReactionId;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MessageReactionRepository extends JpaRepository<MessageReaction, MessageReactionId> {

    List<MessageReaction> findById_MessageId(Long messageId);

    void deleteById_MessageIdAndId_UserIdAndId_Emoji(Long messageId, Long userId, String emoji);

    boolean existsById_MessageIdAndId_UserIdAndId_Emoji(Long messageId, Long userId, String emoji);
}
