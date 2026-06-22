<?php

namespace App\Features\Chat\Models;

use App\Support\Database\BlamesUser;
use Illuminate\Database\Eloquent\Model;

/**
 * Port of the Spring ChatCall entity. A voice/video call placed in a
 * conversation; participants live in chat_call_participants.
 *
 * @property int $id
 * @property int $conversation_id
 * @property int|null $caller_id
 * @property string $type
 * @property string $status
 * @property \Illuminate\Support\Carbon $started_at
 * @property \Illuminate\Support\Carbon|null $answered_at
 * @property \Illuminate\Support\Carbon|null $ended_at
 * @property int|null $duration_seconds
 * @property string|null $end_reason
 * @property string|null $stream_call_cid
 * @property \Illuminate\Support\Carbon $created_at
 * @property \Illuminate\Support\Carbon $updated_at
 */
class ChatCall extends Model
{
    use BlamesUser;

    protected $table = 'chat_calls';

    protected $fillable = [
        'conversation_id', 'caller_id', 'type', 'status', 'started_at',
        'answered_at', 'ended_at', 'duration_seconds', 'end_reason', 'stream_call_cid',
    ];

    protected $casts = [
        'conversation_id' => 'integer',
        'caller_id' => 'integer',
        'duration_seconds' => 'integer',
        'started_at' => 'datetime',
        'answered_at' => 'datetime',
        'ended_at' => 'datetime',
    ];

    /**
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function participants()
    {
        return $this->hasMany(ChatCallParticipant::class, 'call_id', 'id');
    }
}
