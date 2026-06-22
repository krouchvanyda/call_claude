<?php

namespace App\Features\Chat\Controllers;

use App\Features\Chat\Dto\ConversationDto;
use App\Features\Chat\Dto\MemberDto;
use App\Features\Chat\Dto\MessageDto;
use App\Features\Chat\Models\ChatConversation;
use App\Features\Chat\Models\ChatMessage;
use App\Features\Chat\Requests\AddMembersRequest;
use App\Features\Chat\Requests\CreateConversationRequest;
use App\Features\Chat\Requests\MarkReadRequest;
use App\Features\Chat\Requests\UpdateConversationRequest;
use App\Features\Chat\Services\ChatBroadcaster;
use App\Features\Chat\Services\ConversationService;
use App\Http\Controllers\Controller;
use App\Support\Pagination\PageQuery;
use App\Support\Pagination\PageResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ConversationController extends Controller
{
    /** @var ConversationService */
    private $conversations;

    /** @var ChatBroadcaster */
    private $broadcaster;

    public function __construct(ConversationService $conversations, ChatBroadcaster $broadcaster)
    {
        $this->conversations = $conversations;
        $this->broadcaster = $broadcaster;
    }

    /** List all my conversations (inbox), paginated, newest-first. */
    public function index(Request $request)
    {
        $me = (int) Auth::guard('api')->id();
        $paged = $this->conversations->listForUser($me, PageQuery::fromRequest($request));

        // Batch-fetch the last message of every conv in the page to avoid N+1.
        $lastIds = [];
        foreach ($paged->items() as $c) {
            if ($c->last_message_id !== null) {
                $lastIds[(int) $c->last_message_id] = true;
            }
        }
        $byId = [];
        if (! empty($lastIds)) {
            foreach (ChatMessage::query()->whereIn('id', array_keys($lastIds))->get() as $m) {
                $byId[(int) $m->id] = $m;
            }
        }

        $self = $this;
        return PageResponse::from($paged, function (ChatConversation $c) use ($me, $byId, $self) {
            $last = $c->last_message_id !== null && isset($byId[(int) $c->last_message_id])
                ? $byId[(int) $c->last_message_id]
                : null;
            return $self->toDto($c, $me, $last);
        });
    }

    /** Get one conversation with members + unread count + last message. */
    public function show(int $id)
    {
        $me = (int) Auth::guard('api')->id();
        return $this->toDtoWithLastMessage($this->conversations->getForUser($id, $me), $me);
    }

    /** Create a direct (1:1) or group conversation; direct is auto-deduped. */
    public function store(CreateConversationRequest $request)
    {
        $me = (int) Auth::guard('api')->id();
        $c = $this->conversations->create($me, $request->validated());
        $dto = $this->toDtoWithLastMessage($c, $me);
        $this->broadcaster->toUsers($this->memberIds($c), 'inbox', 'conversation.create', $dto);
        return $dto;
    }

    /** Rename a group or change its avatar URL (admin only). */
    public function update(int $id, UpdateConversationRequest $request)
    {
        $me = (int) Auth::guard('api')->id();
        $c = $this->conversations->update($id, $me, $request->validated());
        $dto = $this->toDtoWithLastMessage($c, $me);
        $this->broadcaster->toConversation($id, 'conversation.update', $dto);
        $this->broadcaster->toUsers($this->memberIds($c), 'inbox', 'conversation.update', $dto);
        return $dto;
    }

    /** Add new members to a group (admin only). */
    public function addMembers(int $id, AddMembersRequest $request)
    {
        $me = (int) Auth::guard('api')->id();
        $data = $request->validated();
        $c = $this->conversations->addMembers($id, $me, $data['memberIds']);
        $dto = $this->toDtoWithLastMessage($c, $me);
        $this->broadcaster->toConversation($id, 'conversation.update', $dto);
        $this->broadcaster->toUsers($this->memberIds($c), 'inbox', 'conversation.update', $dto);
        return $dto;
    }

    /** Kick a member from a group (admin), or leave yourself ({userId} = me). */
    public function removeMember(int $id, int $userId)
    {
        $me = (int) Auth::guard('api')->id();
        $c = $this->conversations->removeMember($id, $me, $userId);
        $dto = $this->toDtoWithLastMessage($c, $me);
        $this->broadcaster->toConversation($id, 'conversation.update', $dto);
        $this->broadcaster->toUser($userId, 'inbox', 'conversation.remove', $dto);
        return $dto;
    }

    /** Delete the whole conversation (GROUP: admin only, DIRECT: either party). */
    public function destroy(int $id)
    {
        $me = (int) Auth::guard('api')->id();
        $formerMembers = $this->conversations->delete($id, $me);
        foreach ($formerMembers as $uid) {
            $this->broadcaster->toUser((int) $uid, 'inbox', 'conversation.remove', ['conversationId' => $id]);
        }
        return null;
    }

    /** Mark messages as read up to the given id; clears unread + broadcasts message.read. */
    public function markRead(int $id, MarkReadRequest $request)
    {
        $me = (int) Auth::guard('api')->id();
        $data = $request->validated();
        $lastReadMessageId = (int) $data['lastReadMessageId'];
        $this->conversations->markRead($id, $me, $lastReadMessageId);
        $c = $this->conversations->getForUser($id, $me);
        $dto = $this->toDtoWithLastMessage($c, $me);

        // Tell everyone in the conv that `me` has read up to lastReadMessageId.
        $this->broadcaster->toConversation($id, 'message.read', [
            'conversationId' => $id,
            'userId' => $me,
            'lastReadMessageId' => $lastReadMessageId,
        ]);

        // Tell my other devices to clear the unread badge live.
        $this->broadcaster->toUser($me, 'inbox', 'conversation.update', $dto);
        return $dto;
    }

    /**
     * @return array<int, int>
     */
    private function memberIds(ChatConversation $c): array
    {
        return $this->conversations->memberUserIds((int) $c->id);
    }

    /**
     * @return array<string, mixed>
     */
    private function toDtoWithLastMessage(ChatConversation $c, int $viewerId): array
    {
        $lastMessage = $c->last_message_id === null
            ? null
            : ChatMessage::query()->find($c->last_message_id);
        return $this->toDto($c, $viewerId, $lastMessage);
    }

    /**
     * @return array<string, mixed>
     */
    private function toDto(ChatConversation $c, int $viewerId, ?ChatMessage $lastMessage): array
    {
        $memberDtos = [];
        $mine = null;
        foreach ($c->members as $m) {
            $memberDtos[] = MemberDto::from($m);
            if ((int) $m->user_id === $viewerId) {
                $mine = $m;
            }
        }

        $unread = $mine === null
            ? 0
            : $this->conversations->countUnread((int) $c->id, $viewerId, $mine->last_read_message_id !== null ? (int) $mine->last_read_message_id : null);

        $lastMessageDto = $lastMessage === null
            ? null
            : MessageDto::from($lastMessage, [], $this->readByForLastMessage($c, $lastMessage));

        return ConversationDto::from($c, $memberDtos, $lastMessageDto, $unread);
    }

    /**
     * readByUserIds for a single message using the conv's loaded members.
     *
     * @return array<int, int>
     */
    private function readByForLastMessage(ChatConversation $c, ChatMessage $m): array
    {
        $out = [];
        foreach ($c->members as $member) {
            $uid = (int) $member->user_id;
            if ($uid === (int) $m->sender_id) {
                continue;
            }
            $lastRead = $member->last_read_message_id === null ? 0 : (int) $member->last_read_message_id;
            if ($lastRead >= (int) $m->id) {
                $out[] = $uid;
            }
        }
        return $out;
    }
}
