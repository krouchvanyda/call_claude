package com.company.erp.features.chats.controller;

import com.company.erp.core.database.PageQuery;
import com.company.erp.core.response.PageResponse;
import com.company.erp.core.security.AuthenticatedUser;
import com.company.erp.features.chats.dto.*;
import com.company.erp.features.chats.entity.ConversationMember;
import com.company.erp.features.chats.entity.Message;
import com.company.erp.features.chats.entity.MessageReaction;
import com.company.erp.features.chats.repository.ConversationMemberRepository;
import com.company.erp.features.chats.service.ConversationService;
import com.company.erp.features.chats.service.MessageService;
import com.company.erp.features.chats.ws.ChatBroadcaster;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/v1/chats")
public class MessageController {

    private final MessageService messages;
    private final ConversationService conversations;
    private final ConversationMemberRepository members;
    private final ChatBroadcaster broadcaster;

    public MessageController(MessageService messages,
                             ConversationService conversations,
                             ConversationMemberRepository members,
                             ChatBroadcaster broadcaster) {
        this.messages = messages;
        this.conversations = conversations;
        this.members = members;
        this.broadcaster = broadcaster;
    }

    /** Paginated message history for a conversation, newest-first, with read receipts. */
    @GetMapping("/conversations/{convId}/messages")
    public PageResponse<MessageDto> history(
            @PathVariable Long convId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "30") int pageSize,
            @RequestParam(required = false) String sort) {
        Long me = AuthenticatedUser.require().userId();
        Map<Long, Long> memberLastRead = memberLastReadMap(convId);
        return PageResponse.from(
                messages.history(convId, me, new PageQuery(page, pageSize, null, sort)),
                m -> MessageDto.from(m, reactionDtos(m.getId()),
                        readByForMessage(m, memberLastRead)));
    }

    /** Case-insensitive substring search on message body within a conversation. */
    @GetMapping("/conversations/{convId}/messages/search")
    public PageResponse<MessageDto> search(
            @PathVariable Long convId,
            @RequestParam String q,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "30") int pageSize) {
        Long me = AuthenticatedUser.require().userId();
        Map<Long, Long> memberLastRead = memberLastReadMap(convId);
        return PageResponse.from(
                messages.search(convId, me, q, new PageQuery(page, pageSize, q, null)),
                m -> MessageDto.from(m, reactionDtos(m.getId()),
                        readByForMessage(m, memberLastRead)));
    }

    /** Send a text / image / voice / file message; broadcasts to the conv topic + inbox. */
    @PostMapping("/conversations/{convId}/messages")
    public MessageDto send(@PathVariable Long convId, @Valid @RequestBody SendMessageRequest body) {
        Long me = AuthenticatedUser.require().userId();
        Message m = messages.send(convId, me, body);
        MessageDto dto = MessageDto.from(m, List.of());
        broadcaster.toConversation(convId, "message.send", dto);
        broadcaster.toUsers(conversations.memberUserIds(convId), "inbox", "message.send", dto);
        return dto;
    }

    /** Edit own TEXT message within 15 minutes of sending. */
    @PatchMapping("/messages/{id}")
    public MessageDto edit(@PathVariable Long id, @Valid @RequestBody EditMessageRequest body) {
        Long me = AuthenticatedUser.require().userId();
        Message m = messages.edit(id, me, body);
        MessageDto dto = MessageDto.from(m, reactionDtos(id));
        broadcaster.toConversation(m.getConversationId(), "message.edit", dto);
        return dto;
    }

    /** Soft-delete a message (sender only); body & attachment fields nulled in responses. */
    @DeleteMapping("/messages/{id}")
    public MessageDto delete(@PathVariable Long id) {
        Long me = AuthenticatedUser.require().userId();
        Message m = messages.delete(id, me);
        MessageDto dto = MessageDto.from(m, List.of());
        broadcaster.toConversation(m.getConversationId(), "message.delete", dto);
        return dto;
    }

    /** Toggle an emoji reaction on a message; returns the full reactions list afterwards. */
    @PostMapping("/messages/{id}/reactions")
    public List<ReactionDto> toggleReaction(@PathVariable Long id,
                                            @Valid @RequestBody ToggleReactionRequest body) {
        Long me = AuthenticatedUser.require().userId();
        List<MessageReaction> updated = messages.toggleReaction(id, me, body.emoji());
        List<ReactionDto> dtos = updated.stream().map(ReactionDto::from).toList();
        Message m = messages.getById(id);
        broadcaster.toConversation(m.getConversationId(), "reaction.toggle",
                Map.of("messageId", id, "reactions", dtos));
        return dtos;
    }

    private List<ReactionDto> reactionDtos(Long messageId) {
        return messages.reactionsFor(messageId).stream().map(ReactionDto::from).toList();
    }

    /** userId → that member's last-read message id (0 if never read anything). */
    private Map<Long, Long> memberLastReadMap(Long convId) {
        Map<Long, Long> map = new HashMap<>();
        for (ConversationMember m : members.findByConversation_Id(convId)) {
            map.put(m.getUserId(), m.getLastReadMessageId() == null ? 0L : m.getLastReadMessageId());
        }
        return map;
    }

    /** All members (excluding sender) whose lastReadMessageId >= this message's id. */
    private Set<Long> readByForMessage(Message m, Map<Long, Long> memberLastRead) {
        return memberLastRead.entrySet().stream()
                .filter(e -> !e.getKey().equals(m.getSenderId()))
                .filter(e -> e.getValue() >= m.getId())
                .map(Map.Entry::getKey)
                .collect(Collectors.toSet());
    }
}
