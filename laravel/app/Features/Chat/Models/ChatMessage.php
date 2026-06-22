<?php

namespace App\Features\Chat\Models;

use App\Support\Database\BlamesUser;
use Illuminate\Database\Eloquent\Model;

/**
 * Port of the Spring Message entity. Soft-deleted via the deleted_at column
 * (handled manually — Spring stamped it directly, not via Laravel SoftDeletes,
 * so we keep the same explicit behaviour).
 *
 * @property int $id
 * @property int $conversation_id
 * @property int|null $sender_id
 * @property string $type
 * @property string|null $body
 * @property string|null $attachment_url
 * @property string|null $attachment_content_type
 * @property int|null $attachment_size_bytes
 * @property int|null $duration_seconds
 * @property int|null $reply_to_message_id
 * @property \Illuminate\Support\Carbon|null $edited_at
 * @property \Illuminate\Support\Carbon|null $deleted_at
 * @property \Illuminate\Support\Carbon $created_at
 * @property \Illuminate\Support\Carbon $updated_at
 */
class ChatMessage extends Model
{
    use BlamesUser;

    protected $table = 'chat_messages';

    protected $fillable = [
        'conversation_id', 'sender_id', 'type', 'body', 'attachment_url',
        'attachment_content_type', 'attachment_size_bytes', 'duration_seconds',
        'reply_to_message_id', 'edited_at', 'deleted_at',
    ];

    protected $casts = [
        'conversation_id' => 'integer',
        'sender_id' => 'integer',
        'attachment_size_bytes' => 'integer',
        'duration_seconds' => 'integer',
        'reply_to_message_id' => 'integer',
        'edited_at' => 'datetime',
        'deleted_at' => 'datetime',
    ];

    public function isDeleted(): bool
    {
        return $this->deleted_at !== null;
    }
}
