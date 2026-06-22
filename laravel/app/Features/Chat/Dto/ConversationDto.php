<?php

namespace App\Features\Chat\Dto;

use App\Features\Chat\Models\ChatConversation;

/** Port of the Spring ConversationDto record. */
final class ConversationDto
{
    /**
     * @param array<int, array<string, mixed>> $members
     * @param array<string, mixed>|null $lastMessage
     * @return array<string, mixed>
     */
    public static function from(ChatConversation $c, array $members, ?array $lastMessage, int $unreadCount): array
    {
        return [
            'id' => (int) $c->id,
            'type' => $c->type,
            'name' => $c->name,
            'avatarUrl' => $c->avatar_url,
            'members' => array_values($members),
            'lastMessage' => $lastMessage,
            'lastMessageAt' => $c->last_message_at ? $c->last_message_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
            'unreadCount' => $unreadCount,
            'createdAt' => $c->created_at ? $c->created_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
        ];
    }
}
