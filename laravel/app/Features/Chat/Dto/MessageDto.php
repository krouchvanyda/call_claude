<?php

namespace App\Features\Chat\Dto;

use App\Features\Chat\Models\ChatMessage;

/**
 * Port of the Spring MessageDto record.
 *
 * When the message is soft-deleted, body and attachment fields are nulled out
 * (matching the Java DTO). readByUserIds carries the user ids of conversation
 * members (other than the sender) whose lastReadMessageId is >= this message's
 * id — derived at read time, no separate reads table.
 */
final class MessageDto
{
    /**
     * @param array<int, array<string, mixed>> $reactions
     * @param array<int, int> $readByUserIds
     * @return array<string, mixed>
     */
    public static function from(ChatMessage $m, array $reactions = [], array $readByUserIds = []): array
    {
        $deleted = $m->isDeleted();

        return [
            'id' => (int) $m->id,
            'conversationId' => (int) $m->conversation_id,
            'senderId' => $m->sender_id !== null ? (int) $m->sender_id : null,
            'type' => $m->type,
            'body' => $deleted ? null : $m->body,
            'attachmentUrl' => $deleted ? null : $m->attachment_url,
            'attachmentContentType' => $deleted ? null : $m->attachment_content_type,
            'attachmentSizeBytes' => $deleted ? null : ($m->attachment_size_bytes !== null ? (int) $m->attachment_size_bytes : null),
            'durationSeconds' => $deleted ? null : ($m->duration_seconds !== null ? (int) $m->duration_seconds : null),
            'replyToMessageId' => $m->reply_to_message_id !== null ? (int) $m->reply_to_message_id : null,
            'editedAt' => $m->edited_at ? $m->edited_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
            'deleted' => $deleted,
            'reactions' => array_values($reactions),
            'readByUserIds' => array_values(array_map('intval', $readByUserIds)),
            'createdAt' => $m->created_at ? $m->created_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
        ];
    }
}
