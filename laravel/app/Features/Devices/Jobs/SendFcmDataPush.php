<?php

namespace App\Features\Devices\Jobs;

use App\Features\Devices\Services\FcmService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

/**
 * Queued data-only FCM push — the analogue of the Spring @Async send. Dispatch
 * it so a failed/slow push never blocks the REST response. With QUEUE_CONNECTION=sync
 * it runs inline (errors are still swallowed inside FcmService).
 */
class SendFcmDataPush implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    /** @var array<int, string> */
    public $tokens;

    /** @var array<string, string|null> */
    public $data;

    /**
     * @param array<int, string> $tokens
     * @param array<string, string|null> $data
     */
    public function __construct(array $tokens, array $data)
    {
        $this->tokens = $tokens;
        $this->data = $data;
    }

    public function handle(FcmService $fcm): void
    {
        $fcm->sendDataToTokens($this->tokens, $this->data);
    }
}
