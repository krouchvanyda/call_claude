<?php

namespace App\Features\Chat\Models;

use App\Support\Database\BlamesUser;
use Illuminate\Database\Eloquent\Model;

/**
 * Port of the Spring Conversation entity. DIRECT (1:1) or GROUP. The
 * denormalised last_message_id / last_message_at point at the most recent
 * message for cheap inbox rendering.
 *
 * @property int $id
 * @property string $type
 * @property string|null $name
 * @property string|null $avatar_url
 * @property int|null $last_message_id
 * @property \Illuminate\Support\Carbon|null $last_message_at
 * @property \Illuminate\Support\Carbon $created_at
 * @property \Illuminate\Support\Carbon $updated_at
 */
class ChatConversation extends Model
{
    use BlamesUser;

    protected $table = 'chat_conversations';

    protected $fillable = [
        'type', 'name', 'avatar_url', 'last_message_id', 'last_message_at',
    ];

    protected $casts = [
        'last_message_at' => 'datetime',
    ];

    /**
     * @return \Illuminate\Database\Eloquent\Relations\HasMany
     */
    public function members()
    {
        return $this->hasMany(ConversationMember::class, 'conversation_id', 'id');
    }
}
