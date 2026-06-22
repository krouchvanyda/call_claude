<?php

namespace App\Features\Chat\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Port of the Spring ChatCallParticipant entity — a composite-key
 * (call_id, user_id) row tracking each member's per-call state. No
 * auto-increment id, no Eloquent timestamps.
 *
 * @property int $call_id
 * @property int $user_id
 * @property string $status
 * @property \Illuminate\Support\Carbon|null $joined_at
 * @property \Illuminate\Support\Carbon|null $left_at
 */
class ChatCallParticipant extends Model
{
    protected $table = 'chat_call_participants';

    public $incrementing = false;

    public $timestamps = false;

    protected $primaryKey = null;

    protected $fillable = ['call_id', 'user_id', 'status', 'joined_at', 'left_at'];

    protected $casts = [
        'call_id' => 'integer',
        'user_id' => 'integer',
        'joined_at' => 'datetime',
        'left_at' => 'datetime',
    ];
}
