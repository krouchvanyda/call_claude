<?php

namespace App\Features\Chat\Services;

use App\Features\Chat\Models\ChatConversation;
use App\Features\Chat\Models\ChatMessage;
use App\Features\Chat\Models\ConversationMember;
use App\Features\Chat\Models\ConversationType;
use App\Features\Chat\Models\MemberRole;
use App\Features\Users\Models\User;
use App\Support\Exceptions\BadRequestException;
use App\Support\Exceptions\ForbiddenException;
use App\Support\Exceptions\NotFoundException;
use App\Support\Pagination\PageQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Port of the Spring ConversationService. Membership is enforced here (chat is
 * open to any authenticated user, so authorisation lives in the service, not
 * route middleware). Multi-write operations run in DB transactions, mirroring
 * the @Transactional service.
 */
class ConversationService
{
    /**
     * List the conversations the user belongs to, newest-first by
     * COALESCE(last_message_at, created_at).
     */
    public function listForUser(int $userId, PageQuery $query): LengthAwarePaginator
    {
        return ChatConversation::query()
            ->whereIn('id', function ($q) use ($userId) {
                $q->select('conversation_id')
                    ->from('chat_conversation_members')
                    ->where('user_id', $userId);
            })
            ->with('members')
            ->orderByRaw('COALESCE(last_message_at, created_at) DESC')
            ->paginate($query->pageSize, ['*'], 'page', $query->page);
    }

    public function getForUser(int $convId, int $userId): ChatConversation
    {
        $c = ChatConversation::query()->with('members')->find($convId);
        if (! $c) {
            throw new NotFoundException('Conversation not found');
        }
        $this->requireMember($convId, $userId);
        return $c;
    }

    /**
     * @param array<string, mixed> $data  type, memberIds, name, avatarUrl
     */
    public function create(int $actorId, array $data): ChatConversation
    {
        $type = $data['type'];

        // Ensure caller is in the member set (preserve insertion order, dedupe).
        $memberIds = [];
        foreach ($data['memberIds'] as $uid) {
            $memberIds[(int) $uid] = true;
        }
        $memberIds[$actorId] = true;
        $memberIds = array_keys($memberIds);

        // Validate every user exists.
        foreach ($memberIds as $uid) {
            if (! User::query()->whereKey($uid)->exists()) {
                throw new NotFoundException('User not found: '.$uid);
            }
        }

        if ($type === ConversationType::DIRECT) {
            if (count($memberIds) !== 2) {
                throw new BadRequestException('DIRECT conversations need exactly 2 members');
            }
            $existing = $this->findDirectBetween($memberIds[0], $memberIds[1]);
            if ($existing !== null) {
                return $existing;
            }
        } elseif (count($memberIds) < 2) {
            throw new BadRequestException('GROUP conversations need at least 2 members');
        }

        return DB::transaction(function () use ($type, $data, $memberIds, $actorId) {
            $c = new ChatConversation();
            $c->type = $type;
            $c->name = $type === ConversationType::GROUP ? ($data['name'] ?? null) : null;
            $c->avatar_url = $data['avatarUrl'] ?? null;
            $c->save();

            foreach ($memberIds as $uid) {
                $m = new ConversationMember();
                $m->conversation_id = $c->id;
                $m->user_id = $uid;
                $m->role = $uid === $actorId ? MemberRole::ADMIN : MemberRole::MEMBER;
                $m->joined_at = Carbon::now();
                $m->muted = false;
                $m->save();
            }

            return $c->fresh('members');
        });
    }

    /**
     * @param array<string, mixed> $data  name, avatarUrl (partial)
     */
    public function update(int $convId, int $actorId, array $data): ChatConversation
    {
        return DB::transaction(function () use ($convId, $actorId, $data) {
            $c = $this->getForUser($convId, $actorId);
            $this->requireAdmin($c, $actorId);
            if (array_key_exists('name', $data) && $data['name'] !== null) {
                $c->name = $data['name'];
            }
            if (array_key_exists('avatarUrl', $data) && $data['avatarUrl'] !== null) {
                $c->avatar_url = $data['avatarUrl'];
            }
            $c->save();
            return $c->fresh('members');
        });
    }

    /**
     * @param array<int, int> $memberIds
     */
    public function addMembers(int $convId, int $actorId, array $memberIds): ChatConversation
    {
        return DB::transaction(function () use ($convId, $actorId, $memberIds) {
            $c = $this->getForUser($convId, $actorId);
            $this->requireAdmin($c, $actorId);
            if ($c->type === ConversationType::DIRECT) {
                throw new BadRequestException('Cannot add members to a DIRECT conversation');
            }
            foreach ($memberIds as $uid) {
                $uid = (int) $uid;
                if (ConversationMember::query()
                    ->where('conversation_id', $convId)->where('user_id', $uid)->exists()) {
                    continue;
                }
                if (! User::query()->whereKey($uid)->exists()) {
                    throw new NotFoundException('User not found: '.$uid);
                }
                $m = new ConversationMember();
                $m->conversation_id = $convId;
                $m->user_id = $uid;
                $m->role = MemberRole::MEMBER;
                $m->joined_at = Carbon::now();
                $m->muted = false;
                $m->save();
            }
            return $c->fresh('members');
        });
    }

    public function removeMember(int $convId, int $actorId, int $targetUserId): ChatConversation
    {
        return DB::transaction(function () use ($convId, $actorId, $targetUserId) {
            $c = $this->getForUser($convId, $actorId);
            // A user can remove themselves; otherwise admin only.
            if ($actorId !== $targetUserId) {
                $this->requireAdmin($c, $actorId);
            }
            if ($c->type === ConversationType::DIRECT) {
                throw new BadRequestException('Cannot remove members from a DIRECT conversation');
            }
            $m = ConversationMember::query()
                ->where('conversation_id', $convId)->where('user_id', $targetUserId)->first();
            if (! $m) {
                throw new NotFoundException('Member not in conversation');
            }
            $m->delete();
            return $c->fresh('members');
        });
    }

    /**
     * Hard-delete a conversation (and, via DB ON DELETE CASCADE, its messages,
     * members, reactions, calls and call participants). GROUP: admin only.
     * DIRECT: either participant. Returns the member ids at deletion time so the
     * controller can fan a conversation.remove envelope to each.
     *
     * @return array<int, int>
     */
    public function delete(int $convId, int $actorId): array
    {
        return DB::transaction(function () use ($convId, $actorId) {
            $c = $this->getForUser($convId, $actorId);
            if ($c->type === ConversationType::GROUP) {
                $this->requireAdmin($c, $actorId);
            }
            // Snapshot member ids BEFORE the cascade wipes the join table.
            $formerMembers = $this->memberUserIds($convId);
            $c->delete();
            return $formerMembers;
        });
    }

    public function markRead(int $convId, int $userId, int $lastReadMessageId): ConversationMember
    {
        return DB::transaction(function () use ($convId, $userId, $lastReadMessageId) {
            $m = $this->requireMember($convId, $userId);
            $m->last_read_message_id = $lastReadMessageId;
            $m->save();
            return $m;
        });
    }

    public function requireMember(int $convId, int $userId): ConversationMember
    {
        $m = ConversationMember::query()
            ->where('conversation_id', $convId)->where('user_id', $userId)->first();
        if (! $m) {
            throw new ForbiddenException('Not a member of this conversation');
        }
        return $m;
    }

    /**
     * @return array<int, int>
     */
    public function memberUserIds(int $convId): array
    {
        return ConversationMember::query()
            ->where('conversation_id', $convId)
            ->pluck('user_id')
            ->map(function ($v) {
                return (int) $v;
            })
            ->all();
    }

    /**
     * Count of messages in the conversation, not deleted, not sent by the user,
     * with id greater than lastReadMessageId (or all when never read).
     */
    public function countUnread(int $convId, int $userId, ?int $lastReadMessageId): int
    {
        $q = ChatMessage::query()
            ->where('conversation_id', $convId)
            ->whereNull('deleted_at')
            ->where('sender_id', '<>', $userId);
        if ($lastReadMessageId !== null) {
            $q->where('id', '>', $lastReadMessageId);
        }
        return (int) $q->count();
    }

    /** The DIRECT conversation containing exactly the two given users, if any. */
    private function findDirectBetween(int $userA, int $userB): ?ChatConversation
    {
        return ChatConversation::query()
            ->where('type', ConversationType::DIRECT)
            ->whereRaw('(SELECT COUNT(*) FROM chat_conversation_members m WHERE m.conversation_id = chat_conversations.id) = 2')
            ->whereExists(function ($q) use ($userA) {
                $q->selectRaw('1')->from('chat_conversation_members as ma')
                    ->whereColumn('ma.conversation_id', 'chat_conversations.id')
                    ->where('ma.user_id', $userA);
            })
            ->whereExists(function ($q) use ($userB) {
                $q->selectRaw('1')->from('chat_conversation_members as mb')
                    ->whereColumn('mb.conversation_id', 'chat_conversations.id')
                    ->where('mb.user_id', $userB);
            })
            ->with('members')
            ->first();
    }

    private function requireAdmin(ChatConversation $c, int $userId): void
    {
        $m = ConversationMember::query()
            ->where('conversation_id', $c->id)->where('user_id', $userId)->first();
        if (! $m) {
            throw new ForbiddenException('Not a member of this conversation');
        }
        if ($m->role !== MemberRole::ADMIN) {
            throw new ForbiddenException('Admin role required');
        }
    }
}
