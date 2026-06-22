<?php

namespace App\Features\Chat\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcast to the public presence channel — the analogue of the Spring STOMP
 * destination /topic/presence. Carries the presence.update event.
 *
 * Wire envelope: { "event": "presence.update", "payload": <PresenceDto> }.
 */
class PresenceBroadcast implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /** @var array<string, mixed> */
    public $payload;

    /**
     * @param array<string, mixed> $payload
     */
    public function __construct(array $payload)
    {
        $this->payload = $payload;
    }

    /**
     * @return Channel
     */
    public function broadcastOn()
    {
        return new Channel('presence');
    }

    public function broadcastAs(): string
    {
        return 'presence.update';
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return ['event' => 'presence.update', 'payload' => $this->payload];
    }
}
