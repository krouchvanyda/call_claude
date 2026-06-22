<?php

namespace App\Features\Chat\Controllers;

use App\Features\Chat\Dto\MessageDto;
use App\Features\Chat\Dto\ReactionDto;
use App\Features\Chat\Models\ChatMessage;
use App\Features\Chat\Models\ConversationMember;
use App\Features\Chat\Requests\EditMessageRequest;
use App\Features\Chat\Requests\SendMessageRequest;
use App\Features\Chat\Requests\ToggleReactionRequest;
use App\Features\Chat\Services\ChatBroadcaster;
use App\Features\Chat\Services\ConversationService;
use App\Features\Chat\Services\MessageService;
use App\Http\Controllers\Controller;
use App\Support\Exceptions\BadRequestException;
use App\Support\Pagination\PageQuery;
use App\Support\Pagination\PageResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class MessageController extends Controller
{
    /** @var MessageService */
    private $messages;

    /** @var ConversationService */
    private $conversations;

    /** @var ChatBroadcaster */
    private $broadcaster;

    public function __construct(
        MessageService $messages,
        ConversationService $conversations,
        ChatBroadcaster $broadcaster
    ) {
        $this->messages = $messages;
        $this->conversations = $conversations;
        $this->broadcaster = $broadcaster;
    }

    /** Paginated message history for a conversation, newest-first, with read receipts. */
    public function history(int $convId, Request $request)
    {
        $me = (int) Auth::guard('api')->id();
        $memberLastRead = $this->memberLastReadMap($convId);
        // Default pageSize is 30 to match the Spring MessageController (not the
        // global PageQuery default of 20).
        $query = new PageQuery((int) $request->query('page', 1), (int) $request->query('pageSize', 30), null, null);
        $paged = $this->messages->history($convId, $me, $query);

        $self = $this;
        return PageResponse::from($paged, function (ChatMessage $m) use ($memberLastRead, $self) {
            return MessageDto::from($m, $self->reactionDtos((int) $m->id), $self->readByForMessage($m, $memberLastRead));
        });
    }

    /** Case-insensitive substring search on message body within a conversation. */
    public function search(int $convId, Request $request)
    {
        $me = (int) Auth::guard('api')->id();
        $q = $request->query('q');
        if ($q === null) {
            throw new BadRequestException('Query parameter q is required');
        }
        $memberLastRead = $this->memberLastReadMap($convId);
        $query = new PageQuery((int) $request->query('page', 1), (int) $request->query('pageSize', 30), $q, null);
        $paged = $this->messages->search($convId, $me, $q, $query);

        $self = $this;
        return PageResponse::from($paged, function (ChatMessage $m) use ($memberLastRead, $self) {
            return MessageDto::from($m, $self->reactionDtos((int) $m->id), $self->readByForMessage($m, $memberLastRead));
        });
    }

    /** Send a text / image / voice / file message; broadcasts to the conv topic + inbox. */
    public function send(int $convId, SendMessageRequest $request)
    {
        $me = (int) Auth::guard('api')->id();
        $m = $this->messages->send($convId, $me, $request->validated());
        $dto = MessageDto::from($m, []);
        $this->broadcaster->toConversation($convId, 'message.send', $dto);
        $this->broadcaster->toUsers($this->conversations->memberUserIds($convId), 'inbox', 'message.send', $dto);
        return $dto;
    }

    /** Edit own TEXT message within 15 minutes of sending. */
    public function edit(int $id, EditMessageRequest $request)
    {
        $me = (int) Auth::guard('api')->id();
        $m = $this->messages->edit($id, $me, $request->validated());
        $dto = MessageDto::from($m, $this->reactionDtos($id));
        $this->broadcaster->toConversation((int) $m->conversation_id, 'message.edit', $dto);
        return $dto;
    }

    /** Soft-delete a message (sender only); body & attachment fields nulled in responses. */
    public function delete(int $id)
    {
        $me = (int) Auth::guard('api')->id();
        $m = $this->messages->delete($id, $me);
        $dto = MessageDto::from($m, []);
        $this->broadcaster->toConversation((int) $m->conversation_id, 'message.delete', $dto);
        return $dto;
    }

    /** Toggle an emoji reaction on a message; returns the full reactions list afterwards. */
    public function toggleReaction(int $id, ToggleReactionRequest $request)
    {
        $me = (int) Auth::guard('api')->id();
        $data = $request->validated();
        $updated = $this->messages->toggleReaction($id, $me, $data['emoji']);
        $dtos = $updated->map([ReactionDto::class, 'from'])->values()->all();
        $m = $this->messages->getById($id);
        $this->broadcaster->toConversation((int) $m->conversation_id, 'reaction.toggle', [
            'messageId' => $id,
            'reactions' => $dtos,
        ]);
        return $dtos;
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    public function reactionDtos(int $messageId): array
    {
        return $this->messages->reactionsFor($messageId)->map([ReactionDto::class, 'from'])->values()->all();
    }

    /**
     * userId → that member's last-read message id (0 if never read anything).
     *
     * @return array<int, int>
     */
    private function memberLastReadMap(int $convId): array
    {
        $map = [];
        foreach (ConversationMember::query()->where('conversation_id', $convId)->get() as $m) {
            $map[(int) $m->user_id] = $m->last_read_message_id === null ? 0 : (int) $m->last_read_message_id;
        }
        return $map;
    }

    /**
     * All members (excluding sender) whose lastReadMessageId >= this message's id.
     *
     * @param array<int, int> $memberLastRead
     * @return array<int, int>
     */
    public function readByForMessage(ChatMessage $m, array $memberLastRead): array
    {
        $out = [];
        foreach ($memberLastRead as $uid => $lastRead) {
            if ((int) $uid === (int) $m->sender_id) {
                continue;
            }
            if ($lastRead >= (int) $m->id) {
                $out[] = (int) $uid;
            }
        }
        return $out;
    }
}
