<?php

namespace App\Features\Chat\Dto;

use App\Features\Chat\Models\ChatCallParticipant;

/** Port of the Spring CallParticipantDto record. */
final class CallParticipantDto
{
    /**
     * @return array<string, mixed>
     */
    public static function from(ChatCallParticipant $p): array
    {
        return [
            'userId' => (int) $p->user_id,
            'status' => $p->status,
            'joinedAt' => $p->joined_at ? $p->joined_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
            'leftAt' => $p->left_at ? $p->left_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
        ];
    }
}
