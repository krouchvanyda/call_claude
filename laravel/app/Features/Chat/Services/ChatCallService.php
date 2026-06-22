<?php

namespace App\Features\Chat\Services;

use App\Features\Chat\Models\CallStatus;
use App\Features\Chat\Models\ChatCall;
use App\Features\Chat\Models\ChatCallParticipant;
use App\Features\Chat\Models\ParticipantStatus;
use App\Features\Chat\Models\PresenceStatus;
use App\Support\Exceptions\BadRequestException;
use App\Support\Exceptions\NotFoundException;
use App\Support\Pagination\PageQuery;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Port of the Spring ChatCallService. Owns the call state machine
 * (RINGING → ANSWERED → ENDED/MISSED/REJECTED), the busy-signal gate, the
 * Stream VoIP ring/cancel side-effects, and presence BUSY toggling.
 */
class ChatCallService
{
    /** @var array<int, string> */
    private const OPEN_CALL_STATUSES = [CallStatus::RINGING, CallStatus::ANSWERED];

    /** @var array<int, string> */
    private const OPEN_PARTICIPANT_STATUSES = [ParticipantStatus::RINGING, ParticipantStatus::ANSWERED];

    /** @var ConversationService */
    private $conversations;

    /** @var PresenceService */
    private $presence;

    /** @var StreamTokenService */
    private $streamTokens;

    /** @var StreamVideoService */
    private $streamVideo;

    public function __construct(
        ConversationService $conversations,
        PresenceService $presence,
        StreamTokenService $streamTokens,
        StreamVideoService $streamVideo
    ) {
        $this->conversations = $conversations;
        $this->presence = $presence;
        $this->streamTokens = $streamTokens;
        $this->streamVideo = $streamVideo;
    }

    private function ringTimeoutSeconds(): int
    {
        $v = (int) config('erp.chat.call.ring_timeout_seconds');
        return $v <= 0 ? 60 : $v;
    }

    private function acceptGraceSeconds(): int
    {
        $v = (int) config('erp.chat.call.accept_grace_seconds');
        return $v < 0 ? 5 : $v;
    }

    public function getById(int $callId): ChatCall
    {
        $c = ChatCall::query()->with('participants')->find($callId);
        if (! $c) {
            throw new NotFoundException('Call not found');
        }
        return $c;
    }

    public function historyForUser(int $userId, PageQuery $query): LengthAwarePaginator
    {
        return ChatCall::query()
            ->whereIn('id', function ($q) use ($userId) {
                $q->select('call_id')->from('chat_call_participants')->where('user_id', $userId);
            })
            ->with('participants')
            ->orderBy('started_at', 'desc')
            ->paginate($query->pageSize, ['*'], 'page', $query->page);
    }

    public function historyForConversation(int $convId, int $userId, PageQuery $query): LengthAwarePaginator
    {
        $this->conversations->requireMember($convId, $userId);
        return ChatCall::query()
            ->where('conversation_id', $convId)
            ->with('participants')
            ->orderBy('started_at', 'desc')
            ->paginate($query->pageSize, ['*'], 'page', $query->page);
    }

    /**
     * @param array<string, mixed> $data  type
     */
    public function start(int $convId, int $callerId, array $data): ChatCall
    {
        $this->conversations->requireMember($convId, $callerId);
        if ($this->existsActiveCallForUser($callerId)) {
            throw new BadRequestException('Caller is already in an active call');
        }

        $call = DB::transaction(function () use ($convId, $callerId, $data) {
            $c = new ChatCall();
            $c->conversation_id = $convId;
            $c->caller_id = $callerId;
            $c->type = $data['type'];
            $c->status = CallStatus::RINGING;
            $c->started_at = Carbon::now();
            $c->save();

            // Now that the row has an id, stamp the Stream Video CID so every
            // participant joins the same Stream call.
            $c->stream_call_cid = $this->streamTokens->cidForCall((int) $c->id);
            $c->save();

            $memberIds = $this->conversations->memberUserIds($convId);
            foreach ($memberIds as $uid) {
                $uid = (int) $uid;
                $p = new ChatCallParticipant();
                $p->call_id = $c->id;
                $p->user_id = $uid;
                if ($uid === $callerId) {
                    $p->status = ParticipantStatus::ANSWERED;
                    $p->joined_at = Carbon::now();
                } else {
                    $p->status = ParticipantStatus::RINGING;
                }
                $p->save();
            }

            return $c;
        });

        $memberIds = $this->conversations->memberUserIds($convId);

        // Caller is busy from the moment the call starts.
        $this->presence->markBusy($callerId);

        // Ring the callees server-side via Stream's VoIP push — but ONLY for
        // callees who are OFFLINE (no live session, i.e. backgrounded/killed).
        // ONLINE callees already got the in-app overlay from the STOMP/WS
        // call.invite, so re-ringing them via VoIP would double-ring and
        // contest the audio session. OFFLINE callees still get the VoIP push.
        $ringTargets = [];
        foreach ($memberIds as $uid) {
            $uid = (int) $uid;
            if ($uid === $callerId) {
                continue;
            }
            if ($this->presence->statusOf($uid) === PresenceStatus::OFFLINE) {
                $ringTargets[] = $uid;
            }
        }
        if (empty($ringTargets)) {
            Log::info('[call] callId='.$call->id.' — all callees ONLINE; skipping Stream VoIP ring '
                .'(in-app overlay handles foreground, no CallKit)');
        } else {
            // Include the caller so Stream makes them the creator (creators are
            // NOT rung); only the OFFLINE callees in this set receive the push.
            $ringMembers = $ringTargets;
            $ringMembers[] = $callerId;
            Log::info('[call] callId='.$call->id.' — ringing OFFLINE callees via VoIP push: ['
                .implode(',', $ringTargets).']');
            $this->streamVideo->ring($call->stream_call_cid, $callerId, $ringMembers);
        }

        return $this->getById((int) $call->id);
    }

    public function accept(int $callId, int $userId): ChatCall
    {
        return DB::transaction(function () use ($callId, $userId) {
            $c = $this->getById($callId);

            // Grace-window revival — if the sweeper just marked it MISSED but the
            // accept arrives within acceptGraceSeconds, restore RINGING and proceed.
            if ($c->status === CallStatus::MISSED) {
                $ageSec = $c->started_at->diffInSeconds(Carbon::now());
                $graceCutoff = $this->ringTimeoutSeconds() + $this->acceptGraceSeconds();
                if ($ageSec <= $graceCutoff) {
                    Log::info('[call] REVIVE callId='.$callId.' accepter user='.$userId
                        .' ageSec='.$ageSec.' graceCutoff='.$graceCutoff);
                    $c->status = CallStatus::RINGING;
                    $c->ended_at = null;
                    $c->end_reason = null;
                    $c->duration_seconds = null;
                    $c->save();
                    $me = $this->participant($callId, $userId);
                    if ($me->status === ParticipantStatus::MISSED) {
                        $me->status = ParticipantStatus::RINGING;
                        $me->left_at = null;
                        $me->save();
                    }
                } else {
                    throw new BadRequestException('Call already ended');
                }
            } elseif ($c->status !== CallStatus::RINGING && $c->status !== CallStatus::ANSWERED) {
                throw new BadRequestException('Call already ended');
            }

            $p = $this->participant($callId, $userId);
            if ($p->status !== ParticipantStatus::RINGING) {
                return $this->getById($callId);
            }
            $p->status = ParticipantStatus::ANSWERED;
            $p->joined_at = Carbon::now();
            $p->save();

            if ($c->status === CallStatus::RINGING) {
                $c->status = CallStatus::ANSWERED;
                $c->answered_at = Carbon::now();
                $c->save();
            }
            $this->presence->markBusy($userId);

            return $this->getById($callId);
        });
    }

    public function reject(int $callId, int $userId, ?string $reason): ChatCall
    {
        return DB::transaction(function () use ($callId, $userId, $reason) {
            $c = $this->getById($callId);
            $p = $this->participant($callId, $userId);
            if ($p->status === ParticipantStatus::RINGING) {
                $p->status = ParticipantStatus::REJECTED;
                $p->left_at = Carbon::now();
                $p->save();
            }
            // If everyone else (other than caller) has rejected/left, the call ends.
            $anyoneActive = $c->participants()
                ->where('user_id', '<>', $c->caller_id)
                ->whereIn('status', [ParticipantStatus::RINGING, ParticipantStatus::ANSWERED])
                ->exists();
            if (! $anyoneActive && $c->status === CallStatus::RINGING) {
                $this->endCallInternal(
                    $c,
                    $c->status === CallStatus::RINGING ? CallStatus::REJECTED : CallStatus::ENDED,
                    $reason !== null ? $reason : 'rejected'
                );
            }
            return $this->getById($callId);
        });
    }

    public function hangup(int $callId, int $userId): ChatCall
    {
        return DB::transaction(function () use ($callId, $userId) {
            $c = $this->getById($callId);
            $p = $this->participant($callId, $userId);
            if ($p->status === ParticipantStatus::ANSWERED || $p->status === ParticipantStatus::RINGING) {
                $p->status = ParticipantStatus::LEFT;
                $p->left_at = Carbon::now();
                $p->save();
            }

            // Caller leaving ends the call for everyone.
            if ($userId === (int) $c->caller_id) {
                $this->endCallInternal($c, CallStatus::ENDED, 'caller_left');
                return $this->getById($callId);
            }

            // Otherwise: if no other callee is still in, end it.
            $anyoneStillActive = $c->participants()
                ->where('user_id', '<>', $c->caller_id)
                ->whereIn('status', [ParticipantStatus::RINGING, ParticipantStatus::ANSWERED])
                ->exists();
            if (! $anyoneStillActive && $c->status !== CallStatus::ENDED) {
                $this->endCallInternal($c, CallStatus::ENDED, 'all_callees_left');
            } else {
                // Call continues; the user who left is no longer BUSY.
                $this->presence->clearBusy($userId);
            }
            return $this->getById($callId);
        });
    }

    /**
     * Sweep every RINGING call older than the configured ring timeout and
     * transition it to MISSED. Returns the freshly-ended calls (reloaded with
     * participants) so the caller can fan out STOMP + FCM notifications.
     *
     * @return array<int, ChatCall>
     */
    public function sweepStaleRinging(): array
    {
        $cutoff = Carbon::now()->subSeconds($this->ringTimeoutSeconds());

        $staleIds = ChatCall::query()
            ->where('status', CallStatus::RINGING)
            ->where('started_at', '<', $cutoff)
            ->pluck('id')
            ->all();

        $ended = [];
        foreach ($staleIds as $id) {
            $id = (int) $id;
            DB::transaction(function () use ($id) {
                $c = $this->getById($id);
                if ($c->status !== CallStatus::RINGING) {
                    return;
                }
                foreach ($c->participants as $p) {
                    if ($p->status === ParticipantStatus::RINGING) {
                        $p->status = ParticipantStatus::MISSED;
                        $p->left_at = Carbon::now();
                        $p->save();
                    }
                }
                $this->endCallInternal($c, CallStatus::MISSED, 'no_answer');
                Log::info('[call] AUTO-MISSED callId='.$c->id.' (timeout='.$this->ringTimeoutSeconds().'s)');
            });
            $ended[] = $this->getById($id);
        }
        return $ended;
    }

    private function endCallInternal(ChatCall $c, string $status, string $reason): void
    {
        $c->status = $status;
        $c->ended_at = Carbon::now();
        $c->end_reason = $reason;
        if ($c->answered_at !== null) {
            $c->duration_seconds = (int) $c->answered_at->diffInSeconds($c->ended_at);
        } else {
            $c->duration_seconds = 0;
        }
        $c->save();

        // Clear BUSY for everyone who was active in this call. Read fresh from
        // the DB so any participant status mutated earlier in this same flow
        // (e.g. the caller flipped to LEFT in hangup) is reflected.
        foreach ($c->participants()->get() as $p) {
            if ($p->status === ParticipantStatus::ANSWERED || $p->status === ParticipantStatus::LEFT) {
                $this->presence->clearBusy((int) $p->user_id);
            }
        }
        // Caller, even if they never "answered", was busy from start.
        if ($c->caller_id !== null) {
            $this->presence->clearBusy((int) $c->caller_id);
        }

        // Cancel the Stream ring for every member — the single chokepoint for
        // every terminal end, so a still-ringing (backgrounded/killed) callee is
        // told the call is over through the same VoIP channel that raised it.
        $this->streamVideo->endCall($c->stream_call_cid, $c->caller_id !== null ? (int) $c->caller_id : 0);
    }

    private function participant(int $callId, int $userId): ChatCallParticipant
    {
        $p = ChatCallParticipant::query()
            ->where('call_id', $callId)->where('user_id', $userId)->first();
        if (! $p) {
            throw new NotFoundException('You are not a participant in this call');
        }
        return $p;
    }

    /** Busy-signal check: is this user mid-call right now? */
    private function existsActiveCallForUser(int $userId): bool
    {
        return ChatCall::query()
            ->whereIn('status', self::OPEN_CALL_STATUSES)
            ->whereExists(function ($q) use ($userId) {
                $q->selectRaw('1')->from('chat_call_participants as p')
                    ->whereColumn('p.call_id', 'chat_calls.id')
                    ->where('p.user_id', $userId)
                    ->whereIn('p.status', self::OPEN_PARTICIPANT_STATUSES);
            })
            ->exists();
    }
}
