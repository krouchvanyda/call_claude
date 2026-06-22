<?php

namespace App\Features\Chat\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Port of the Spring MessageReaction entity — a composite-key
 * (message_id, user_id, emoji) row. The table carries only created_at, so
 * Eloquent's updated_at handling is disabled.
 *
 * @property int $message_id
 * @property int $user_id
 * @property string $emoji
 * @property \Illuminate\Support\Carbon $created_at
 */
class MessageReaction extends Model
{
    protected $table = 'chat_message_reactions';

    public $incrementing = false;

    public $timestamps = false;

    protected $primaryKey = null;

    protected $fillable = ['message_id', 'user_id', 'emoji', 'created_at'];

    protected $casts = [
        'message_id' => 'integer',
        'user_id' => 'integer',
        'created_at' => 'datetime',
    ];
}
