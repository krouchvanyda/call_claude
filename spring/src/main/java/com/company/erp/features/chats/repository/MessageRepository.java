package com.company.erp.features.chats.repository;

import com.company.erp.features.chats.entity.Message;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface MessageRepository extends JpaRepository<Message, Long> {

    Page<Message> findByConversationIdAndDeletedAtIsNullOrderByCreatedAtDesc(Long conversationId, Pageable pageable);

    @Query("""
           SELECT m FROM Message m
           WHERE m.conversationId = :convId
             AND m.deletedAt IS NULL
             AND LOWER(m.body) LIKE LOWER(CONCAT('%', :q, '%'))
           ORDER BY m.createdAt DESC
           """)
    Page<Message> searchInConversation(@Param("convId") Long convId,
                                       @Param("q") String q,
                                       Pageable pageable);
}
