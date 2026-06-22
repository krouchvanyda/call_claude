<?php

namespace App\Features\Chat\Services;

/**
 * Port of the Spring ChatBroadcaster. Centralises every realtime fan-out:
 * services call these methods and never touch the transport directly.
 *
 * Frames are published to a Redis channel; the STOMP server (erp:stomp-serve)
 * subscribes and fans them out to the matching WebSocket subscriptions. The
 * destinations are the exact Spring SimpleBroker destinations, and the wire
 * envelope { "event": "<name>", "payload": <dto> } is preserved:
 *
 *   /topic/conversations/{id}            message stream
 *   /topic/conversations/{id}/call       call state
 *   /topic/presence                      presence updates
 *   /user/{userId}/queue/inbox           per-user inbox previews
 *   /user/{userId}/queue/calls           per-user incoming-call invites
 *
 * (Clients subscribe to /user/queue/inbox; the server rewrites /user/{id}/...
 * to that client destination, matching Spring's convertAndSendToUser.)
 */
class ChatBroadcaster
{
    /** Public conversation topic — anyone subscribed sees this. */
    public function toConversation(int $conversationId, string $event, array $payload): void
    {
        $this->publish('/topic/conversations/'.$conversationId, $event, $payload);
    }

    /** Per-call topic for ringing → answered → ended state transitions. */
    public function toCall(int $conversationId, string $event, array $payload): void
    {
        $this->publish('/topic/conversations/'.$conversationId.'/call', $event, $payload);
    }

    /** Private fan-out to a single user on one of their per-user destinations. */
    public function toUser(int $userId, string $destination, string $event, array $payload): void
    {
        $this->publish('/user/'.$userId.'/queue/'.$destination, $event, $payload);
    }

    /**
     * Convenience: notify every user in a collection on a private destination.
     *
     * @param iterable<int> $userIds
     */
    public function toUsers($userIds, string $destination, string $event, array $payload): void
    {
        foreach ($userIds as $id) {
            $this->toUser((int) $id, $destination, $event, $payload);
        }
    }

    /** Public presence topic — presence.update for any user's status change. */
    public function presence(array $payload): void
    {
        $this->publish('/topic/presence', 'presence.update', $payload);
    }

    /**
     * @param array<string, mixed> $payload
     */
    /** @var \Predis\Client|null */
    private static $redis = null;

    private function publish(string $destination, string $event, array $payload): void
    {
        $frame = json_encode([
            'destination' => $destination,
            'body' => ['event' => $event, 'payload' => $payload],
        ]);

        try {
            // Raw predis client with NO key prefix — Laravel's Redis facade
            // prefixes pub/sub channel names (erp_database_…), which would not
            // match the STOMP server's unprefixed subscription.
            $this->redis()->publish((string) config('erp.stomp.channel', 'erp.stomp'), $frame);
        } catch (\Throwable $e) {
            // Realtime is best-effort — never let a broadcast failure break the
            // REST request that triggered it (matches the Spring fire-and-forget
            // intent). The STOMP server may simply be down.
            \Illuminate\Support\Facades\Log::warning('[stomp] publish failed: '.$e->getMessage());
        }
    }

    private function redis(): \Predis\Client
    {
        if (self::$redis === null) {
            $host = getenv('REDIS_HOST') ?: config('database.redis.default.host', '127.0.0.1');
            $port = getenv('REDIS_PORT') ?: config('database.redis.default.port', 6379);
            self::$redis = new \Predis\Client([
                'scheme' => 'tcp',
                'host' => $host,
                'port' => (int) $port,
                'database' => (int) config('database.redis.default.database', 0),
            ]);
        }
        return self::$redis;
    }
}
