package com.company.erp.features.chats.controller;

import com.company.erp.core.database.PageQuery;
import com.company.erp.core.response.PageResponse;
import com.company.erp.core.security.AuthenticatedUser;
import com.company.erp.features.chats.dto.*;
import com.company.erp.features.chats.entity.Conversation;
import com.company.erp.features.chats.entity.ConversationMember;
import com.company.erp.features.chats.entity.Message;
import com.company.erp.features.chats.repository.ConversationMemberRepository;
import com.company.erp.features.chats.repository.MessageRepository;
import com.company.erp.features.chats.service.ConversationService;
import com.company.erp.features.chats.ws.ChatBroadcaster;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/chats/conversations")
public class ConversationController {

    private final ConversationService conversations;
    private final ConversationMemberRepository members;
    private final MessageRepository messages;
    private final ChatBroadcaster broadcaster;

    public ConversationController(ConversationService conversations,
                                  ConversationMemberRepository members,
                                  MessageRepository messages,
                                  ChatBroadcaster broadcaster) {
        this.conversations = conversations;
        this.members = members;
        this.messages = messages;
        this.broadcaster = broadcaster;
    }

    /** List all my conversations (inbox), paginated, newest-first. */
    @GetMapping
    public PageResponse<ConversationDto> list(
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int pageSize,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String sort) {
        Long me = AuthenticatedUser.require().userId();
        var paged = conversations.listForUser(me, new PageQuery(page, pageSize, search, sort));

        // Batch-fetch the last message of every conv in the page so we don't N+1.
        Set<Long> lastIds = paged.getContent().stream()
                .map(Conversation::getLastMessageId)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());
        Map<Long, Message> byId = lastIds.isEmpty() ? Map.of()
                : messages.findAllById(lastIds).stream()
                        .collect(Collectors.toMap(Message::getId, m -> m));

        return PageResponse.from(paged, c -> toDto(c, me,
                c.getLastMessageId() == null ? null : byId.get(c.getLastMessageId())));
    }

    /** Get one conversation with members + unread count + last message. */
    @GetMapping("/{id}")
    public ConversationDto get(@PathVariable Long id) {
        Long me = AuthenticatedUser.require().userId();
        return toDtoWithLastMessage(conversations.getForUser(id, me), me);
    }

    /** Create a direct (1:1) or group conversation; direct is auto-deduped. */
    @PostMapping
    public ConversationDto create(@Valid @RequestBody CreateConversationRequest body) {
        Long me = AuthenticatedUser.require().userId();
        Conversation c = conversations.create(me, body);
        ConversationDto dto = toDtoWithLastMessage(c, me);
        broadcaster.toUsers(memberIds(c), "inbox", "conversation.create", dto);
        return dto;
    }

    /** Rename a group or change its avatar URL (admin only). */
    @PatchMapping("/{id}")
    public ConversationDto update(@PathVariable Long id, @Valid @RequestBody UpdateConversationRequest body) {
        Long me = AuthenticatedUser.require().userId();
        Conversation c = conversations.update(id, me, body);
        ConversationDto dto = toDtoWithLastMessage(c, me);
        broadcaster.toConversation(id, "conversation.update", dto);
        broadcaster.toUsers(memberIds(c), "inbox", "conversation.update", dto);
        return dto;
    }

    /** Add new members to a group (admin only). */
    @PostMapping("/{id}/members")
    public ConversationDto addMembers(@PathVariable Long id, @Valid @RequestBody AddMembersRequest body) {
        Long me = AuthenticatedUser.require().userId();
        Conversation c = conversations.addMembers(id, me, body);
        ConversationDto dto = toDtoWithLastMessage(c, me);
        broadcaster.toConversation(id, "conversation.update", dto);
        broadcaster.toUsers(memberIds(c), "inbox", "conversation.update", dto);
        return dto;
    }

    /** Kick a member from a group (admin), or leave yourself ({userId} = me). */
    @DeleteMapping("/{id}/members/{userId}")
    public ConversationDto removeMember(@PathVariable Long id, @PathVariable Long userId) {
        Long me = AuthenticatedUser.require().userId();
        Conversation c = conversations.removeMember(id, me, userId);
        ConversationDto dto = toDtoWithLastMessage(c, me);
        broadcaster.toConversation(id, "conversation.update", dto);
        broadcaster.toUser(userId, "inbox", "conversation.remove", dto);
        return dto;
    }

    /** Delete the whole conversation (GROUP: admin only, DIRECT: either party). */
    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {
        Long me = AuthenticatedUser.require().userId();
        Set<Long> formerMembers = conversations.delete(id, me);
        for (Long uid : formerMembers) {
            broadcaster.toUser(uid, "inbox", "conversation.remove",
                    Map.of("conversationId", id));
        }
    }

    /** Mark messages as read up to the given id; clears unread + broadcasts message.read. */
    @PostMapping("/{id}/read")
    public ConversationDto markRead(@PathVariable Long id, @Valid @RequestBody MarkReadRequest body) {
        Long me = AuthenticatedUser.require().userId();
        conversations.markRead(id, me, body.lastReadMessageId());
        Conversation c = conversations.getForUser(id, me);
        ConversationDto dto = toDtoWithLastMessage(c, me);

        // Tell everyone in the conv that `me` has read up to lastReadMessageId
        // so their rendered messages can flip the read tick.
        Map<String, Object> readPayload = Map.of(
                "conversationId", id,
                "userId", me,
                "lastReadMessageId", body.lastReadMessageId());
        broadcaster.toConversation(id, "message.read", readPayload);

        // Tell my other devices to clear the unread badge live.
        broadcaster.toUser(me, "inbox", "conversation.update", dto);
        return dto;
    }

    private Set<Long> memberIds(Conversation c) {
        return conversations.memberUserIds(c.getId());
    }

    /** Convenience used by single-conv endpoints that don't batch. */
    private ConversationDto toDtoWithLastMessage(Conversation c, Long viewerId) {
        Message lastMessage = c.getLastMessageId() == null ? null
                : messages.findById(c.getLastMessageId()).orElse(null);
        return toDto(c, viewerId, lastMessage);
    }

    private ConversationDto toDto(Conversation c, Long viewerId, Message lastMessage) {
        List<MemberDto> mDtos = c.getMembers().stream().map(MemberDto::from).toList();
        ConversationMember mine = c.getMembers().stream()
                .filter(x -> x.getUserId().equals(viewerId))
                .findFirst().orElse(null);
        long unread = mine == null ? 0
                : members.countUnread(c.getId(), viewerId, mine.getLastReadMessageId());

        MessageDto lastMessageDto = lastMessage == null ? null
                : MessageDto.from(lastMessage, List.of(), readByForLastMessage(c, lastMessage));

        return ConversationDto.from(c, mDtos, lastMessageDto, unread);
    }

    /** Compute readByUserIds for a single message using the conv's loaded members. */
    private Set<Long> readByForLastMessage(Conversation c, Message m) {
        Map<Long, Long> map = new HashMap<>();
        for (ConversationMember x : c.getMembers()) {
            map.put(x.getUserId(), x.getLastReadMessageId() == null ? 0L : x.getLastReadMessageId());
        }
        return map.entrySet().stream()
                .filter(e -> !e.getKey().equals(m.getSenderId()))
                .filter(e -> e.getValue() >= m.getId())
                .map(Map.Entry::getKey)
                .collect(Collectors.toSet());
    }
}
