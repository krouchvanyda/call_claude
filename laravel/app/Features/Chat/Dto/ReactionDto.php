<?php

namespace App\Features\Chat\Dto;

use App\Features\Chat\Models\MessageReaction;

/** Port of the Spring ReactionDto record. */
final class ReactionDto
{
    /**
     * @return array<string, mixed>
     */
    public static function from(MessageReaction $r): array
    {
        return [
            'userId' => (int) $r->user_id,
            'emoji' => $r->emoji,
        ];
    }
}
