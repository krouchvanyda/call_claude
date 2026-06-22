package com.company.erp.features.chats.service;

import com.company.erp.core.database.PageQuery;
import com.company.erp.core.exceptions.BadRequestException;
import com.company.erp.core.exceptions.ForbiddenException;
import com.company.erp.core.exceptions.NotFoundException;
import com.company.erp.features.chats.dto.EditMessageRequest;
import com.company.erp.features.chats.dto.SendMessageRequest;
import com.company.erp.features.chats.entity.Conversation;
import com.company.erp.features.chats.entity.Message;
import com.company.erp.features.chats.entity.MessageReaction;
import com.company.erp.features.chats.entity.MessageReactionId;
import com.company.erp.features.chats.entity.MessageType;
import com.company.erp.features.chats.repository.ConversationRepository;
import com.company.erp.features.chats.repository.MessageReactionRepository;
import com.company.erp.features.chats.repository.MessageRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Set;

@Service
@Transactional
public class MessageService {

    /** Edit window mirrors the mobile guide (Slice 4.8 — 15 minutes). */
    private static final Duration EDIT_WINDOW = Duration.ofMinutes(15);

    private final MessageRepository messages;
    private final MessageReactionRepository reactions;
    private final ConversationRepository conversations;
    private final ConversationService conversationService;

    public MessageService(MessageRepository messages,
                          MessageReactionRepository reactions,
                          ConversationRepository conversations,
                          ConversationService conversationService) {
        this.messages = messages;
        this.reactions = reactions;
        this.conversations = conversations;
        this.conversationService = conversationService;
    }

    @Transactional(readOnly = true)
    public Page<Message> history(Long convId, Long userId, PageQuery query) {
        conversationService.requireMember(convId, userId);
        return messages.findByConversationIdAndDeletedAtIsNullOrderByCreatedAtDesc(convId,
                query.toPageable(Set.of("createdAt"), Sort.by(Sort.Direction.DESC, "createdAt")));
    }

    @Transactional(readOnly = true)
    public Page<Message> search(Long convId, Long userId, String q, PageQuery query) {
        conversationService.requireMember(convId, userId);
        if (q == null || q.isBlank()) {
            return Page.empty(query.toPageable(Set.of("createdAt"),
                    Sort.by(Sort.Direction.DESC, "createdAt")));
        }
        return messages.searchInConversation(convId, q,
                query.toPageable(Set.of("createdAt"), Sort.by(Sort.Direction.DESC, "createdAt")));
    }

    @Transactional(readOnly = true)
    public Message getById(Long messageId) {
        return messages.findById(messageId)
                .orElseThrow(() -> new NotFoundException("Message not found"));
    }

    public Message send(Long convId, Long senderId, SendMessageRequest req) {
        conversationService.requireMember(convId, senderId);
        validateBody(req);

        Message m = new Message();
        m.setConversationId(convId);
        m.setSenderId(senderId);
        m.setType(req.type());
        m.setBody(req.body());
        m.setAttachmentUrl(req.attachmentUrl());
        m.setAttachmentContentType(req.attachmentContentType());
        m.setAttachmentSizeBytes(req.attachmentSizeBytes());
        m.setDurationSeconds(req.durationSeconds());
        if (req.replyToMessageId() != null) {
            Message parent = messages.findById(req.replyToMessageId())
                    .orElseThrow(() -> new NotFoundException("Reply target not found"));
            if (!parent.getConversationId().equals(convId)) {
                throw new BadRequestException("Reply must reference a message in the same conversation");
            }
            m.setReplyToMessageId(parent.getId());
        }
        messages.save(m);

        Conversation c = conversations.findById(convId).orElseThrow();
        c.setLastMessageId(m.getId());
        c.setLastMessageAt(m.getCreatedAt());
        return m;
    }

    public Message edit(Long messageId, Long actorId, EditMessageRequest req) {
        Message m = getById(messageId);
        if (!m.getSenderId().equals(actorId)) throw new ForbiddenException("Can only edit own messages");
        if (m.isDeleted())                    throw new BadRequestException("Cannot edit a deleted message");
        if (m.getType() != MessageType.TEXT)  throw new BadRequestException("Only TEXT messages are editable");
        if (Duration.between(m.getCreatedAt(), Instant.now()).compareTo(EDIT_WINDOW) > 0) {
            throw new BadRequestException("Edit window has expired");
        }
        m.setBody(req.body());
        m.setEditedAt(Instant.now());
        return m;
    }

    public Message delete(Long messageId, Long actorId) {
        Message m = getById(messageId);
        if (!m.getSenderId().equals(actorId)) throw new ForbiddenException("Can only delete own messages");
        if (m.isDeleted()) return m;
        m.setDeletedAt(Instant.now());
        return m;
    }

    /** Toggle a single emoji for the user on a message. Returns the resulting list. */
    public List<MessageReaction> toggleReaction(Long messageId, Long userId, String emoji) {
        Message m = getById(messageId);
        if (m.isDeleted()) throw new BadRequestException("Cannot react to a deleted message");
        conversationService.requireMember(m.getConversationId(), userId);

        boolean has = reactions.existsById_MessageIdAndId_UserIdAndId_Emoji(messageId, userId, emoji);
        if (has) {
            reactions.deleteById_MessageIdAndId_UserIdAndId_Emoji(messageId, userId, emoji);
        } else {
            MessageReaction r = new MessageReaction();
            r.setId(new MessageReactionId(messageId, userId, emoji));
            reactions.save(r);
        }
        return reactions.findById_MessageId(messageId);
    }

    public List<MessageReaction> reactionsFor(Long messageId) {
        return reactions.findById_MessageId(messageId);
    }

    private static void validateBody(SendMessageRequest req) {
        switch (req.type()) {
            case TEXT -> {
                if (req.body() == null || req.body().isBlank()) {
                    throw new BadRequestException("TEXT message requires non-empty body");
                }
            }
            case IMAGE, FILE -> {
                if (req.attachmentUrl() == null || req.attachmentUrl().isBlank()) {
                    throw new BadRequestException(req.type() + " message requires attachmentUrl");
                }
            }
            case VOICE -> {
                if (req.attachmentUrl() == null || req.durationSeconds() == null) {
                    throw new BadRequestException("VOICE message requires attachmentUrl and durationSeconds");
                }
            }
        }
    }
}
