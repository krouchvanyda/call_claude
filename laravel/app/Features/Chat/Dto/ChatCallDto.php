<?php

namespace App\Features\Chat\Dto;

use App\Features\Chat\Models\ChatCall;

/** Port of the Spring ChatCallDto record. */
final class ChatCallDto
{
    /**
     * @param array<int, array<string, mixed>> $participants
     * @return array<string, mixed>
     */
    public static function from(ChatCall $c, array $participants): array
    {
        return [
            'id' => (int) $c->id,
            'conversationId' => (int) $c->conversation_id,
            'callerId' => $c->caller_id !== null ? (int) $c->caller_id : null,
            'type' => $c->type,
            'status' => $c->status,
            'startedAt' => $c->started_at ? $c->started_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
            'answeredAt' => $c->answered_at ? $c->answered_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
            'endedAt' => $c->ended_at ? $c->ended_at->utc()->format('Y-m-d\TH:i:s\Z') : null,
            'durationSeconds' => $c->duration_seconds !== null ? (int) $c->duration_seconds : null,
            'endReason' => $c->end_reason,
            'streamCallCid' => $c->stream_call_cid,
            'participants' => array_values($participants),
        ];
    }
}
