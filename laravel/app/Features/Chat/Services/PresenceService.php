<?php

namespace App\Features\Chat\Services;

use App\Features\Chat\Dto\PresenceDto;
use App\Features\Chat\Models\PresenceStatus;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\Cache;

/**
 * Cache-backed presence tracker — port of the Spring in-memory PresenceService.
 *
 * Status resolution (identical to the Java code):
 *   - BUSY    if the user is flagged in-call (set/cleared by ChatCallService).
 *   - OFFLINE if the user sent an explicit "backgrounded" beacon.
 *   - ONLINE  if the user has at least one active session.
 *   - OFFLINE otherwise.
 *
 * The Spring service drove ONLINE/OFFLINE off STOMP CONNECT/DISCONNECT frames.
 * In this Laravel-WebSockets port the same session lifecycle is fed by
 * presence-channel membership webhooks / a client heartbeat: the websocket
 * server (or a heartbeat endpoint) calls {@link connect()} on join and
 * {@link disconnect()} on leave. Those wiring hooks are out of scope here, but
 * the service API below is complete and the BUSY logic is fully functional and
 * invoked from ChatCallService.
 *
 * State lives in the cache so it survives across worker processes. A single
 * application instance is the current scope (matching the Spring note about
 * needing Redis pub/sub for multi-instance fan-out).
 */
class PresenceService
{
    /** Cache key prefixes. */
    private const K_SESSIONS = 'chat:presence:sessions:';      // userId -> set of session ids (json array)
    private const K_SESSION_USER = 'chat:presence:sessionuser:'; // sessionId -> userId
    private const K_LAST_SEEN = 'chat:presence:lastseen:';     // userId -> epoch seconds
    private const K_BUSY = 'chat:presence:busy:';              // userId -> 1
    private const K_BACKGROUNDED = 'chat:presence:bg:';        // userId -> 1
    private const K_KNOWN = 'chat:presence:known';             // set of every userId ever seen (json array)

    /** Long TTL so presence keys effectively persist for the process lifetime. */
    private const TTL = 86400;

    /** @var ChatBroadcaster */
    private $broadcaster;

    public function __construct(ChatBroadcaster $broadcaster)
    {
        $this->broadcaster = $broadcaster;
    }

    /**
     * Register a session for a user (analogue of STOMP CONNECT).
     *
     * NOTE: like the Java code, this deliberately does NOT clear the
     * `backgrounded` override — a reconnect is not proof of foreground (a
     * killed iOS app woken by a VoIP push reconnects while still backgrounded).
     * Only an explicit foreground beacon clears it.
     */
    public function connect(int $userId, string $sessionId): void
    {
        $before = $this->statusOf($userId);

        $sessions = $this->sessions($userId);
        $sessions[$sessionId] = true;
        $this->putSessions($userId, $sessions);
        Cache::put(self::K_SESSION_USER.$sessionId, $userId, self::TTL);
        $this->remember($userId);

        $after = $this->statusOf($userId);
        if ($before !== $after) {
            $this->emit($userId, $after);
        }
    }

    /** Remove a session (analogue of STOMP DISCONNECT). */
    public function disconnect(string $sessionId): void
    {
        $userId = Cache::get(self::K_SESSION_USER.$sessionId);
        if ($userId === null) {
            return;
        }
        $userId = (int) $userId;
        Cache::forget(self::K_SESSION_USER.$sessionId);

        $sessions = $this->sessions($userId);
        unset($sessions[$sessionId]);
        if (empty($sessions)) {
            Cache::forget(self::K_SESSIONS.$userId);
            Cache::put(self::K_LAST_SEEN.$userId, CarbonImmutable::now('UTC')->getTimestamp(), self::TTL);
        } else {
            $this->putSessions($userId, $sessions);
        }

        // Always emit on disconnect: status may have flipped to OFFLINE, or
        // stayed ONLINE/BUSY because other sessions are still up.
        $this->emit($userId, $this->statusOf($userId));
    }

    /** Flag the user as in an active call (BUSY wins over ONLINE/OFFLINE). */
    public function markBusy(int $userId): void
    {
        if (Cache::has(self::K_BUSY.$userId)) {
            return;
        }
        Cache::put(self::K_BUSY.$userId, 1, self::TTL);
        $this->remember($userId);
        $this->emit($userId, $this->statusOf($userId));
    }

    /** Clear the user's in-call flag. */
    public function clearBusy(int $userId): void
    {
        if (! Cache::has(self::K_BUSY.$userId)) {
            return;
        }
        Cache::forget(self::K_BUSY.$userId);
        $this->emit($userId, $this->statusOf($userId));
    }

    public function statusOf(int $userId): string
    {
        if (Cache::has(self::K_BUSY.$userId)) {
            return PresenceStatus::BUSY;
        }
        if (Cache::has(self::K_BACKGROUNDED.$userId)) {
            return PresenceStatus::OFFLINE;
        }
        return ! empty($this->sessions($userId))
            ? PresenceStatus::ONLINE
            : PresenceStatus::OFFLINE;
    }

    /**
     * App-lifecycle beacon: the user minimized. Flip them OFFLINE now for
     * call-routing instead of waiting for a heartbeat to time out the suspended
     * socket. Idempotent.
     */
    public function markBackgrounded(int $userId): void
    {
        $before = $this->statusOf($userId);
        Cache::put(self::K_BACKGROUNDED.$userId, 1, self::TTL);
        $this->remember($userId);
        $after = $this->statusOf($userId);
        if ($before !== $after) {
            Cache::put(self::K_LAST_SEEN.$userId, CarbonImmutable::now('UTC')->getTimestamp(), self::TTL);
            $this->emit($userId, $after);
        }
    }

    /** App-lifecycle beacon: the user returned to the foreground. */
    public function clearBackgrounded(int $userId): void
    {
        $before = $this->statusOf($userId);
        if (Cache::has(self::K_BACKGROUNDED.$userId)) {
            Cache::forget(self::K_BACKGROUNDED.$userId);
            $after = $this->statusOf($userId);
            if ($before !== $after) {
                $this->emit($userId, $after);
            }
        }
    }

    /**
     * @return array<string, mixed>
     */
    public function dtoOf(int $userId): array
    {
        $status = $this->statusOf($userId);
        $seen = $status === PresenceStatus::OFFLINE ? $this->lastSeen($userId) : null;
        return PresenceDto::from($userId, $status, $seen);
    }

    /**
     * Snapshot of every user the service has ever seen (online or offline).
     *
     * @return array<int, array<string, mixed>>
     */
    public function snapshot(): array
    {
        $out = [];
        foreach ($this->known() as $userId) {
            $out[] = $this->dtoOf((int) $userId);
        }
        return $out;
    }

    /**
     * @param array<int, int> $userIds
     * @return array<int, array<string, mixed>>
     */
    public function dtosFor(array $userIds): array
    {
        $out = [];
        foreach ($userIds as $userId) {
            $out[] = $this->dtoOf((int) $userId);
        }
        return $out;
    }

    // --- internals ----------------------------------------------------------

    private function emit(int $userId, string $status): void
    {
        $seen = $status === PresenceStatus::OFFLINE ? $this->lastSeen($userId) : null;
        $this->broadcaster->presence(PresenceDto::from($userId, $status, $seen));
    }

    private function lastSeen(int $userId): ?CarbonImmutable
    {
        $ts = Cache::get(self::K_LAST_SEEN.$userId);
        return $ts === null ? null : CarbonImmutable::createFromTimestampUTC((int) $ts);
    }

    /**
     * @return array<string, bool>
     */
    private function sessions(int $userId): array
    {
        $raw = Cache::get(self::K_SESSIONS.$userId);
        return is_array($raw) ? $raw : [];
    }

    /**
     * @param array<string, bool> $sessions
     */
    private function putSessions(int $userId, array $sessions): void
    {
        Cache::put(self::K_SESSIONS.$userId, $sessions, self::TTL);
    }

    private function remember(int $userId): void
    {
        $known = $this->known();
        if (! in_array($userId, $known, true)) {
            $known[] = $userId;
            Cache::put(self::K_KNOWN, $known, self::TTL);
        }
    }

    /**
     * @return array<int, int>
     */
    private function known(): array
    {
        $raw = Cache::get(self::K_KNOWN);
        return is_array($raw) ? array_map('intval', $raw) : [];
    }
}
