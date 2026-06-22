<?php

namespace App\Features\Chat\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Private fan-out to a single user — the analogue of the Spring STOMP
 * convertAndSendToUser(userId, "/queue/<destination>", …). The destination is
 * one of:
 *   - "inbox" → private channel user.{userId}.inbox  (/user/queue/inbox)
 *   - "calls" → private channel user.{userId}.calls  (/user/queue/calls)
 *
 * Wire envelope: { "event": "<name>", "payload": <dto> }.
 */
class UserBroadcast implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /** @var int */
    public $userId;

    /** @var string */
    public $destination;

    /** @var string */
    public $event;

    /** @var array<string, mixed> */
    public $payload;

    /**
     * @param array<string, mixed> $payload
     */
    public function __construct(int $userId, string $destination, string $event, array $payload)
    {
        $this->userId = $userId;
        $this->destination = $destination;
        $this->event = $event;
        $this->payload = $payload;
    }

    /**
     * @return PrivateChannel
     */
    public function broadcastOn()
    {
        return new PrivateChannel('user.'.$this->userId.'.'.$this->destination);
    }

    public function broadcastAs(): string
    {
        return $this->event;
    }

    /**
     * @return array<string, mixed>
     */
    public function broadcastWith(): array
    {
        return ['event' => $this->event, 'payload' => $this->payload];
    }
}
