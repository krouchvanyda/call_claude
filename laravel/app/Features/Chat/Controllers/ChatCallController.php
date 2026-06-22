<?php

namespace App\Features\Chat\Controllers;

use App\Features\Chat\Dto\CallParticipantDto;
use App\Features\Chat\Dto\ChatCallDto;
use App\Features\Chat\Models\CallStatus;
use App\Features\Chat\Models\ChatCall;
use App\Features\Chat\Models\ParticipantStatus;
use App\Features\Chat\Requests\StartCallRequest;
use App\Features\Chat\Services\ChatBroadcaster;
use App\Features\Chat\Services\ChatCallService;
use App\Features\Chat\Services\StreamTokenService;
use App\Features\Devices\Jobs\SendFcmDataPush;
use App\Features\Devices\Services\DeviceService;
use App\Features\Users\Models\User;
use App\Http\Controllers\Controller;
use App\Support\Pagination\PageQuery;
use App\Support\Pagination\PageResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class ChatCallController extends Controller
{
    /** @var ChatCallService */
    private $calls;

    /** @var ChatBroadcaster */
    private $broadcaster;

    /** @var StreamTokenService */
    private $streamTokens;

    /** @var DeviceService */
    private $devices;

    public function __construct(
        ChatCallService $calls,
        ChatBroadcaster $broadcaster,
        StreamTokenService $streamTokens,
        DeviceService $devices
    ) {
        $this->calls = $calls;
        $this->broadcaster = $broadcaster;
        $this->streamTokens = $streamTokens;
        $this->devices = $devices;
    }

    /** My global call history across every conversation, newest-first. */
    public function myHistory(Request $request)
    {
        $me = (int) Auth::guard('api')->id();
        $paged = $this->calls->historyForUser(
            $me,
            new PageQuery((int) $request->query('page', 1), (int) $request->query('pageSize', 30), null, null)
        );
        $self = $this;
        return PageResponse::from($paged, function (ChatCall $c) use ($self) {
            return $self->toDto($c);
        });
    }

    /** Call history for a single conversation (Chat Info "Recent calls" section). */
    public function conversationHistory(int $convId, Request $request)
    {
        $me = (int) Auth::guard('api')->id();
        $paged = $this->calls->historyForConversation(
            $convId,
            $me,
            new PageQuery((int) $request->query('page', 1), (int) $request->query('pageSize', 30), null, null)
        );
        $self = $this;
        return PageResponse::from($paged, function (ChatCall $c) use ($self) {
            return $self->toDto($c);
        });
    }

    /** Fetch a call's current state for reconciliation after a reconnect. */
    public function show(int $id)
    {
        return $this->toDto($this->calls->getById($id));
    }

    /** Start a voice or video call in a conversation; rings every other member. */
    public function start(int $convId, StartCallRequest $request)
    {
        $me = (int) Auth::guard('api')->id();
        $data = $request->validated();
        Log::info('[call] START requested by user='.$me.' conv='.$convId.' type='.$data['type']);
        $c = $this->calls->start($convId, $me, $data);
        $dto = $this->toDto($c);
        Log::info('[call] START ok callId='.$c->id.' streamCallCid='.$c->stream_call_cid
            .' participants='.count($dto['participants']));

        $this->broadcaster->toCall($convId, 'call.invite', $dto);
        foreach ($c->participants as $p) {
            if ((int) $p->user_id === $me) {
                continue;
            }
            Log::info('[call] INVITE fan-out callId='.$c->id.' → user='.$p->user_id.' (queue/calls)');
            $this->broadcaster->toUser((int) $p->user_id, 'calls', 'call.invite', $dto);
        }
        $this->pushInvite($c, $me);
        return $dto;
    }

    /** Callee accepts a ringing call; flips status to ANSWERED + marks them BUSY. */
    public function accept(int $id)
    {
        $me = (int) Auth::guard('api')->id();
        Log::info('[call] ACCEPT callId='.$id.' by user='.$me);
        $c = $this->calls->accept($id, $me);
        $dto = $this->toDto($c);
        Log::info('[call] ACCEPT ok callId='.$id.' status='.$c->status.' streamCallCid='.$c->stream_call_cid);
        $this->broadcaster->toCall((int) $c->conversation_id, 'call.accept', [
            'callId' => $id,
            'accepterId' => $me,
            'call' => $dto,
        ]);
        // Cancel any leftover ring notification on this user's other devices.
        $this->pushCancelTo([$me], $id, $c->stream_call_cid, 'accepted_elsewhere');
        return $dto;
    }

    /** Callee declines a ringing call with an optional reason (e.g. "busy"). */
    public function reject(int $id, Request $request)
    {
        $me = (int) Auth::guard('api')->id();
        $reason = $request->query('reason');
        Log::info('[call] REJECT callId='.$id.' by user='.$me.' reason='.$reason);
        $c = $this->calls->reject($id, $me, $reason);
        $dto = $this->toDto($c);
        $this->broadcaster->toCall((int) $c->conversation_id, 'call.reject', [
            'callId' => $id,
            'rejecterId' => $me,
            'reason' => $reason === null ? '' : $reason,
            'call' => $dto,
        ]);
        // If the reject ended the whole call (1:1 case), cancel ring on others still pending.
        $this->pushCancelOnTerminal($c, $me, 'rejected');
        return $dto;
    }

    /** Mint a short-lived Stream Video token so the mobile SDK can join the media call. */
    public function streamToken()
    {
        $me = (int) Auth::guard('api')->id();
        Log::info('[stream] TOKEN requested by user='.$me);
        $dto = $this->streamTokens->issueFor($me);
        Log::info('[stream] TOKEN ok user='.$me.' expiresAt='.$dto['expiresAt']);
        return $dto;
    }

    /** Hang up a call. Caller ending = everyone disconnects; last callee ending = caller auto-ends. */
    public function end(int $id)
    {
        $me = (int) Auth::guard('api')->id();
        Log::info('[call] END callId='.$id.' by user='.$me);
        $c = $this->calls->hangup($id, $me);
        $dto = $this->toDto($c);
        Log::info('[call] END ok callId='.$id.' status='.$c->status.' durationSec='.$c->duration_seconds
            .' reason='.$c->end_reason);
        $this->broadcaster->toCall((int) $c->conversation_id, 'call.hangup', [
            'callId' => $id,
            'hangerUpperId' => $me,
            'call' => $dto,
        ]);
        $this->pushCancelOnTerminal($c, $me, 'hangup');
        return $dto;
    }

    /**
     * @return array<string, mixed>
     */
    private function toDto(ChatCall $c): array
    {
        $participants = [];
        foreach ($c->participants as $p) {
            $participants[] = CallParticipantDto::from($p);
        }
        return ChatCallDto::from($c, $participants);
    }

    // ---- FCM helpers -------------------------------------------------------

    /** Data-only call.invite push to every participant except the caller. */
    private function pushInvite(ChatCall $c, int $callerId): void
    {
        $targetIds = [];
        foreach ($c->participants as $p) {
            if ((int) $p->user_id !== $callerId) {
                $targetIds[] = (int) $p->user_id;
            }
        }
        if (empty($targetIds)) {
            return;
        }

        $caller = User::query()->find($callerId);
        $callerName = $caller ? (string) $caller->full_name : '';

        $data = [
            'type' => 'call.invite',
            'callId' => (string) $c->id,
            'conversationId' => (string) $c->conversation_id,
            'callerId' => (string) $callerId,
            'callerName' => $callerName,
            'callType' => strtolower((string) $c->type),
            'startedAt' => $c->started_at ? $c->started_at->utc()->format('Y-m-d\TH:i:s\Z') : '',
            'streamCallCid' => $c->stream_call_cid === null ? '' : $c->stream_call_cid,
        ];

        $tokens = $this->devices->tokensForUsers($targetIds);
        Log::info('[fcm] call.invite callId='.$c->id.' → users=['.implode(',', $targetIds).'] tokens='.count($tokens));
        SendFcmDataPush::dispatch($tokens, $data);
    }

    /** If the call has entered a terminal state, fan a cancel to anyone still RINGING/ANSWERED. */
    private function pushCancelOnTerminal(ChatCall $c, int $actorId, string $reason): void
    {
        if ($c->status === CallStatus::RINGING || $c->status === CallStatus::ANSWERED) {
            return; // call still alive
        }
        $targetIds = [];
        foreach ($c->participants as $p) {
            if ((int) $p->user_id === $actorId) {
                continue;
            }
            if ($p->status === ParticipantStatus::RINGING || $p->status === ParticipantStatus::ANSWERED) {
                $targetIds[] = (int) $p->user_id;
            }
        }
        $this->pushCancelTo($targetIds, (int) $c->id, $c->stream_call_cid, $reason);
    }

    /**
     * @param array<int, int> $targetUserIds
     */
    private function pushCancelTo(array $targetUserIds, int $callId, ?string $streamCallCid, string $reason): void
    {
        if (empty($targetUserIds)) {
            return;
        }
        $data = [
            'type' => 'call.cancel',
            'callId' => (string) $callId,
            // streamCallCid lets the iOS client map the cancel to the exact
            // CallKit entry instead of relying on endAllCalls.
            'streamCallCid' => $streamCallCid === null ? '' : $streamCallCid,
            'reason' => $reason,
        ];
        $tokens = $this->devices->tokensForUsers($targetUserIds);
        Log::info('[fcm] call.cancel callId='.$callId.' cid='.$streamCallCid.' reason='.$reason
            .' → users=['.implode(',', $targetUserIds).'] tokens='.count($tokens));
        SendFcmDataPush::dispatch($tokens, $data);
    }
}
