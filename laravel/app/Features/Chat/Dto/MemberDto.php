<?php

namespace App\Features\Chat\Dto;

use App\Features\Chat\Models\ConversationMember;

/** Port of the Spring MemberDto record. */
final class MemberDto
{
    /**
     * @return array<string, mixed>
     */
    public static function from(ConversationMember $m): array
    {
        return [
            'userId' => (int) $m->user_id,
            'role' => $m->role,
            'muted' => (bool) $m->muted,
            'lastReadMessageId' => $m->last_read_message_id !== null ? (int) $m->last_read_message_id : null,
        ];
    }
}
