<?php

namespace App\Features\Chat\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Port of the Spring ConversationMember entity — a composite-key
 * (conversation_id, user_id) join row. No auto-increment id, no Eloquent
 * timestamps (the table carries only joined_at).
 *
 * @property int $conversation_id
 * @property int $user_id
 * @property string $role
 * @property \Illuminate\Support\Carbon $joined_at
 * @property int|null $last_read_message_id
 * @property bool $muted
 */
class ConversationMember extends Model
{
    protected $table = 'chat_conversation_members';

    public $incrementing = false;

    public $timestamps = false;

    protected $primaryKey = null;

    protected $fillable = [
        'conversation_id', 'user_id', 'role', 'joined_at', 'last_read_message_id', 'muted',
    ];

    protected $casts = [
        'conversation_id' => 'integer',
        'user_id' => 'integer',
        'last_read_message_id' => 'integer',
        'muted' => 'boolean',
        'joined_at' => 'datetime',
    ];
}
