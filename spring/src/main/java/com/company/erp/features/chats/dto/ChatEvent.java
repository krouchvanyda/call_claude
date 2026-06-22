package com.company.erp.features.chats.dto;

/**
 * Generic envelope pushed over STOMP. {@code event} mirrors the wire envelope
 * names from CHAT_MODULE_GUIDE.md (e.g. {@code message.send},
 * {@code reaction.toggle}, {@code call.invite}). {@code payload} is the
 * concrete DTO (MessageDto, ReactionDto, ChatCallDto, ConversationDto …).
 */
public record ChatEvent(String event, Object payload) {
    public static ChatEvent of(String event, Object payload) {
        return new ChatEvent(event, payload);
    }
}
