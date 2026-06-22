package com.company.erp.features.chats.repository;

import com.company.erp.features.chats.entity.ConversationMember;
import com.company.erp.features.chats.entity.ConversationMemberId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ConversationMemberRepository extends JpaRepository<ConversationMember, ConversationMemberId> {

    Optional<ConversationMember> findByConversation_IdAndId_UserId(Long conversationId, Long userId);

    boolean existsByConversation_IdAndId_UserId(Long conversationId, Long userId);

    List<ConversationMember> findByConversation_Id(Long conversationId);

    @Query("""
           SELECT COUNT(msg) FROM Message msg
           WHERE msg.conversationId = :convId
             AND msg.deletedAt IS NULL
             AND msg.senderId <> :userId
             AND (:lastReadMessageId IS NULL OR msg.id > :lastReadMessageId)
           """)
    long countUnread(@Param("convId") Long convId,
                     @Param("userId") Long userId,
                     @Param("lastReadMessageId") Long lastReadMessageId);
}
