<?php

namespace App\Features\Chat\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

/**
 * Broadcast to the public per-conversation channel — the Laravel-WebSockets /
 * Pusher analogue of the Spring STOMP destination /topic/conversations/{id}.
 *
 * Wire envelope is preserved exactly: { "event": "<name>", "payload": <dto> }.
 * Carries events: message.send, message.edit, message.delete, reaction.toggle,
 * message.read, conversation.update.
 */
class ConversationBroadcast implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    /** @var int */
    public $conversationId;

    /** @var string */
    public $event;

    /** @var array<string, mixed> */
    public $payload;

    /**
     * @param array<string, mixed> $payload
     */
    public function __construct(int $conversationId, string $event, array $payload)
    {
        $this->conversationId = $conversationId;
        $this->event = $event;
        $this->payload = $payload;
    }

    /**
     * @return Channel
     */
    public function broadcastOn()
    {
        return new Channel('conversations.'.$this->conversationId);
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
