<?php

namespace App\Features\Chat\Services;

use App\Features\Chat\Models\ChatConversation;
use App\Features\Chat\Models\ChatMessage;
use App\Features\Chat\Models\MessageReaction;
use App\Features\Chat\Models\MessageType;
use App\Support\Exceptions\BadRequestException;
use App\Support\Exceptions\ForbiddenException;
use App\Support\Exceptions\NotFoundException;
use App\Support\Pagination\PageQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Port of the Spring MessageService.
 */
class MessageService
{
    /** Edit window mirrors the mobile guide (Slice 4.8 — 15 minutes). */
    private const EDIT_WINDOW_SECONDS = 900;

    /** @var ConversationService */
    private $conversations;

    public function __construct(ConversationService $conversations)
    {
        $this->conversations = $conversations;
    }

    public function history(int $convId, int $userId, PageQuery $query): LengthAwarePaginator
    {
        $this->conversations->requireMember($convId, $userId);
        return ChatMessage::query()
            ->where('conversation_id', $convId)
            ->whereNull('deleted_at')
            ->orderBy('created_at', 'desc')
            ->orderBy('id', 'desc')
            ->paginate($query->pageSize, ['*'], 'page', $query->page);
    }

    public function search(int $convId, int $userId, ?string $q, PageQuery $query): LengthAwarePaginator
    {
        $this->conversations->requireMember($convId, $userId);

        $builder = ChatMessage::query()
            ->where('conversation_id', $convId)
            ->whereNull('deleted_at');

        if ($q === null || trim($q) === '') {
            // Match Spring's Page.empty(): a query that returns nothing.
            $builder->whereRaw('1 = 0');
        } else {
            $like = '%'.strtolower($q).'%';
            $builder->whereRaw('LOWER(body) LIKE ?', [$like]);
        }

        return $builder
            ->orderBy('created_at', 'desc')
            ->orderBy('id', 'desc')
            ->paginate($query->pageSize, ['*'], 'page', $query->page);
    }

    public function getById(int $messageId): ChatMessage
    {
        $m = ChatMessage::query()->find($messageId);
        if (! $m) {
            throw new NotFoundException('Message not found');
        }
        return $m;
    }

    /**
     * @param array<string, mixed> $data
     */
    public function send(int $convId, int $senderId, array $data): ChatMessage
    {
        $this->conversations->requireMember($convId, $senderId);
        $this->validateBody($data);

        return DB::transaction(function () use ($convId, $senderId, $data) {
            $m = new ChatMessage();
            $m->conversation_id = $convId;
            $m->sender_id = $senderId;
            $m->type = $data['type'];
            $m->body = $data['body'] ?? null;
            $m->attachment_url = $data['attachmentUrl'] ?? null;
            $m->attachment_content_type = $data['attachmentContentType'] ?? null;
            $m->attachment_size_bytes = $data['attachmentSizeBytes'] ?? null;
            $m->duration_seconds = $data['durationSeconds'] ?? null;

            if (! empty($data['replyToMessageId'])) {
                $parent = ChatMessage::query()->find($data['replyToMessageId']);
                if (! $parent) {
                    throw new NotFoundException('Reply target not found');
                }
                if ((int) $parent->conversation_id !== $convId) {
                    throw new BadRequestException('Reply must reference a message in the same conversation');
                }
                $m->reply_to_message_id = $parent->id;
            }
            $m->save();

            $c = ChatConversation::query()->find($convId);
            if ($c) {
                $c->last_message_id = $m->id;
                $c->last_message_at = $m->created_at;
                $c->save();
            }

            return $m;
        });
    }

    /**
     * @param array<string, mixed> $data  body
     */
    public function edit(int $messageId, int $actorId, array $data): ChatMessage
    {
        return DB::transaction(function () use ($messageId, $actorId, $data) {
            $m = $this->getById($messageId);
            if ((int) $m->sender_id !== $actorId) {
                throw new ForbiddenException('Can only edit own messages');
            }
            if ($m->isDeleted()) {
                throw new BadRequestException('Cannot edit a deleted message');
            }
            if ($m->type !== MessageType::TEXT) {
                throw new BadRequestException('Only TEXT messages are editable');
            }
            if ($m->created_at !== null && $m->created_at->diffInSeconds(Carbon::now()) > self::EDIT_WINDOW_SECONDS) {
                throw new BadRequestException('Edit window has expired');
            }
            $m->body = $data['body'];
            $m->edited_at = Carbon::now();
            $m->save();
            return $m;
        });
    }

    public function delete(int $messageId, int $actorId): ChatMessage
    {
        return DB::transaction(function () use ($messageId, $actorId) {
            $m = $this->getById($messageId);
            if ((int) $m->sender_id !== $actorId) {
                throw new ForbiddenException('Can only delete own messages');
            }
            if ($m->isDeleted()) {
                return $m;
            }
            $m->deleted_at = Carbon::now();
            $m->save();
            return $m;
        });
    }

    /**
     * Toggle a single emoji for the user on a message. Returns the resulting list.
     *
     * @return Collection<int, MessageReaction>
     */
    public function toggleReaction(int $messageId, int $userId, string $emoji): Collection
    {
        return DB::transaction(function () use ($messageId, $userId, $emoji) {
            $m = $this->getById($messageId);
            if ($m->isDeleted()) {
                throw new BadRequestException('Cannot react to a deleted message');
            }
            $this->conversations->requireMember((int) $m->conversation_id, $userId);

            $exists = MessageReaction::query()
                ->where('message_id', $messageId)
                ->where('user_id', $userId)
                ->where('emoji', $emoji)
                ->exists();

            if ($exists) {
                MessageReaction::query()
                    ->where('message_id', $messageId)
                    ->where('user_id', $userId)
                    ->where('emoji', $emoji)
                    ->delete();
            } else {
                $r = new MessageReaction();
                $r->message_id = $messageId;
                $r->user_id = $userId;
                $r->emoji = $emoji;
                $r->created_at = Carbon::now();
                $r->save();
            }

            return $this->reactionsFor($messageId);
        });
    }

    /**
     * @return Collection<int, MessageReaction>
     */
    public function reactionsFor(int $messageId): Collection
    {
        return MessageReaction::query()->where('message_id', $messageId)->get();
    }

    /**
     * @param array<string, mixed> $data
     */
    private function validateBody(array $data): void
    {
        $type = $data['type'];
        $body = $data['body'] ?? null;
        $attachmentUrl = $data['attachmentUrl'] ?? null;
        $durationSeconds = $data['durationSeconds'] ?? null;

        if ($type === MessageType::TEXT) {
            if ($body === null || trim($body) === '') {
                throw new BadRequestException('TEXT message requires non-empty body');
            }
        } elseif ($type === MessageType::IMAGE || $type === MessageType::FILE) {
            if ($attachmentUrl === null || trim($attachmentUrl) === '') {
                throw new BadRequestException($type.' message requires attachmentUrl');
            }
        } elseif ($type === MessageType::VOICE) {
            if ($attachmentUrl === null || $durationSeconds === null) {
                throw new BadRequestException('VOICE message requires attachmentUrl and durationSeconds');
            }
        }
    }
}
