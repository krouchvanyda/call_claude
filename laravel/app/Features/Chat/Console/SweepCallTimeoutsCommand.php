<?php

namespace App\Features\Chat\Console;

use App\Features\Chat\Dto\CallParticipantDto;
use App\Features\Chat\Dto\ChatCallDto;
use App\Features\Chat\Models\ChatCall;
use App\Features\Chat\Services\ChatBroadcaster;
use App\Features\Chat\Services\ChatCallService;
use App\Features\Devices\Jobs\SendFcmDataPush;
use App\Features\Devices\Services\DeviceService;
use Illuminate\Console\Command;
use Throwable;

/**
 * Port of the Spring CallTimeoutScheduler. Auto-ends calls that stay in RINGING
 * longer than the configured ring timeout, then fans out a call.hangup
 * broadcast plus a call.cancel FCM push (reason "timeout") so backgrounded
 * ringers dismiss too.
 *
 * Laravel 8's scheduler is minute-granular, so the Console Kernel runs this
 * everyMinute withoutOverlapping and the command loops internally for ~55s,
 * sweeping every CHAT_CALL_SWEEP_INTERVAL_MS milliseconds (usleep).
 */
class SweepCallTimeoutsCommand extends Command
{
    protected $signature = 'erp:sweep-call-timeouts';

    protected $description = 'Auto-end stale RINGING calls and notify caller + unanswered callees';

    /** Total wall-clock budget per invocation (~55s, leaving headroom in the minute). */
    private const RUN_FOR_SECONDS = 55;

    public function handle(ChatCallService $callService, ChatBroadcaster $broadcaster, DeviceService $devices): int
    {
        $intervalMs = (int) config('erp.chat.call.sweep_interval_ms');
        if ($intervalMs <= 0) {
            $intervalMs = 5000;
        }

        $deadline = microtime(true) + self::RUN_FOR_SECONDS;

        do {
            $this->sweepOnce($callService, $broadcaster, $devices);

            // Sleep the interval, but never overshoot the deadline.
            $remaining = $deadline - microtime(true);
            if ($remaining <= 0) {
                break;
            }
            $sleepMs = min($intervalMs, (int) ($remaining * 1000));
            if ($sleepMs > 0) {
                usleep($sleepMs * 1000);
            }
        } while (microtime(true) < $deadline);

        return self::SUCCESS;
    }

    private function sweepOnce(ChatCallService $callService, ChatBroadcaster $broadcaster, DeviceService $devices): void
    {
        try {
            $ended = $callService->sweepStaleRinging();
        } catch (Throwable $ex) {
            $this->warn('[call-sweep] failure during sweepStaleRinging: '.$ex->getMessage());
            return;
        }
        if (empty($ended)) {
            return;
        }
        $this->info('[call-sweep] auto-ended '.count($ended).' stale RINGING call(s)');

        foreach ($ended as $c) {
            $dto = $this->toDto($c);

            // Broadcast: tell everyone the call is over so the caller's "Calling…"
            // page closes and any other connected devices drop the ringer.
            $broadcaster->toCall((int) $c->conversation_id, 'call.hangup', [
                'callId' => (int) $c->id,
                'hangerUpperId' => $c->caller_id !== null ? (int) $c->caller_id : null, // attributed to the caller
                'reason' => 'no_answer',
                'call' => $dto,
            ]);

            // FCM: tell every participant's backgrounded device to dismiss the ring.
            $targetUserIds = [];
            foreach ($c->participants as $p) {
                $targetUserIds[] = (int) $p->user_id;
            }
            $tokens = $devices->tokensForUsers($targetUserIds);
            $data = [
                'type' => 'call.cancel',
                'callId' => (string) $c->id,
                'reason' => 'timeout',
            ];
            $this->info('[fcm] call.cancel (timeout) callId='.$c->id.' → users=['
                .implode(',', $targetUserIds).'] tokens='.count($tokens));
            SendFcmDataPush::dispatch($tokens, $data);
        }
    }

    /**
     * @return array<string, mixed>
     */
    private function toDto(ChatCall $c): array
    {
        $participants = [];
        foreach ($c->participants as $p) {
            if ($p->status !== null) { // defensive
                $participants[] = CallParticipantDto::from($p);
            }
        }
        return ChatCallDto::from($c, $participants);
    }
}
