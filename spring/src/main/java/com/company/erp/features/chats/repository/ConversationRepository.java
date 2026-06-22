package com.company.erp.features.chats.repository;

import com.company.erp.features.chats.entity.Conversation;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ConversationRepository extends JpaRepository<Conversation, Long> {

    @EntityGraph(attributePaths = {"members"})
    Optional<Conversation> findWithMembersById(Long id);

    @EntityGraph(attributePaths = {"members"})
    @Query("""
            SELECT c FROM Conversation c
            JOIN c.members m
            WHERE m.id.userId = :userId
            ORDER BY COALESCE(c.lastMessageAt, c.createdAt) DESC
           """)
    Page<Conversation> findAllForUser(@Param("userId") Long userId, Pageable pageable);

    /** Returns the DIRECT conversation that contains exactly the two given users, if any. */
    @EntityGraph(attributePaths = {"members"})
    @Query("""
            SELECT c FROM Conversation c
            WHERE c.type = com.company.erp.features.chats.entity.ConversationType.DIRECT
              AND (SELECT COUNT(m) FROM ConversationMember m WHERE m.conversation = c) = 2
              AND EXISTS (SELECT 1 FROM ConversationMember m WHERE m.conversation = c AND m.id.userId = :a)
              AND EXISTS (SELECT 1 FROM ConversationMember m WHERE m.conversation = c AND m.id.userId = :b)
           """)
    Optional<Conversation> findDirectBetween(@Param("a") Long userA, @Param("b") Long userB);

    @Query("SELECT m.id.userId FROM ConversationMember m WHERE m.conversation.id = :convId")
    List<Long> findMemberUserIds(@Param("convId") Long convId);
}
