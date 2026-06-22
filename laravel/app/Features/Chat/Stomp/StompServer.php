<?php

namespace App\Features\Chat\Stomp;

use App\Features\Chat\Services\PresenceService;
use App\Support\Auth\JwtService;
use App\Support\Exceptions\UnauthorizedException;
use Ratchet\ConnectionInterface;
use Ratchet\MessageComponentInterface;
use Throwable;

/**
 * STOMP-over-WebSocket server — a faithful reimplementation of the Spring
 * SimpleBroker contract so the existing Flutter STOMP client connects to /ws
 * unchanged.
 *
 * - CONNECT carries `Authorization: Bearer <accessToken>`; the JWT is validated
 *   and the user id becomes the session principal.
 * - SUBSCRIBE to `/topic/...` (broadcast) and `/user/queue/...` (per-principal).
 * - Server pushes MESSAGE frames with `{ "event", "payload" }` JSON bodies.
 * - 10s/10s heartbeats; a dead socket flips the user OFFLINE via PresenceService.
 *
 * Inbound application frames (SEND to /app/...) are accepted but ignored — the
 * Spring app has no @MessageMapping handlers; clients perform every action over
 * REST. Outbound frames are fed in via Redis pub/sub (see deliver()).
 */
/**
 * NOTE: this component intentionally does NOT implement WsServerInterface.
 * Ratchet 0.4 applies a *strict* subprotocol check when subprotocols are
 * advertised, which 426-rejects clients that open a plain WebSocket without a
 * Sec-WebSocket-Protocol header (the common Flutter STOMP case). Spring's
 * endpoint accepted those, so we accept any WebSocket and negotiate STOMP at
 * the frame layer.
 */
class StompServer implements MessageComponentInterface
{
    const SERVER_HEARTBEAT_MS = 10000;

    /** @var \SplObjectStorage<ConnectionInterface, \stdClass> */
    private $clients;

    /** @var JwtService */
    private $jwt;

    /** @var PresenceService */
    private $presence;

    /** @var callable|null logger(string) */
    private $log;

    /** @var int */
    private $messageSeq = 0;

    public function __construct(JwtService $jwt, PresenceService $presence, ?callable $log = null)
    {
        $this->clients = new \SplObjectStorage();
        $this->jwt = $jwt;
        $this->presence = $presence;
        $this->log = $log;
    }

    public function onOpen(ConnectionInterface $conn): void
    {
        $state = new \stdClass();
        $state->userId = null;
        $state->sessionId = (string) (isset($conn->resourceId) ? $conn->resourceId : spl_object_id($conn));
        $state->subs = [];          // subId => destination
        $state->buffer = '';
        $state->connected = false;
        $state->lastRx = $this->now();
        $state->lastTx = $this->now();
        $state->outHb = 0;          // ms; 0 = none
        $state->inHb = 0;           // ms; 0 = none
        $this->clients->attach($conn, $state);
    }

    public function onMessage(ConnectionInterface $conn, $data): void
    {
        if (! $this->clients->contains($conn)) {
            return;
        }
        $state = $this->clients[$conn];
        $state->lastRx = $this->now();
        $state->buffer .= $data;

        // Extract complete (NUL-terminated) frames.
        while (($pos = strpos($state->buffer, "\x00")) !== false) {
            $chunk = substr($state->buffer, 0, $pos);
            $state->buffer = substr($state->buffer, $pos + 1);

            $frame = StompFrame::parse($chunk);
            if ($frame === null) {
                continue; // heartbeat / blank
            }
            try {
                $this->handleFrame($conn, $state, $frame);
            } catch (Throwable $e) {
                $this->sendError($conn, $e->getMessage());
                $conn->close();
                return;
            }
        }

        // Whatever's left with no NUL is either a partial frame or heartbeat
        // newlines. Drop pure-EOL leftovers so they don't accumulate.
        if ($state->buffer !== '' && trim($state->buffer, "\r\n") === '') {
            $state->buffer = '';
        }
    }

    public function onClose(ConnectionInterface $conn): void
    {
        if (! $this->clients->contains($conn)) {
            return;
        }
        $state = $this->clients[$conn];
        $this->clients->detach($conn);

        if ($state->userId !== null) {
            try {
                $this->presence->disconnect($state->sessionId);
            } catch (Throwable $e) {
                $this->logLine('[stomp] presence disconnect error: '.$e->getMessage());
            }
        }
    }

    public function onError(ConnectionInterface $conn, Throwable $e): void
    {
        $this->logLine('[stomp] socket error: '.$e->getMessage());
        $conn->close();
    }

    // --- frame handlers -----------------------------------------------------

    private function handleFrame(ConnectionInterface $conn, \stdClass $state, StompFrame $frame): void
    {
        switch ($frame->command) {
            case 'CONNECT':
            case 'STOMP':
                $this->handleConnect($conn, $state, $frame);
                break;
            case 'SUBSCRIBE':
                $this->handleSubscribe($state, $frame);
                $this->maybeReceipt($conn, $frame);
                break;
            case 'UNSUBSCRIBE':
                $id = $frame->header('id');
                if ($id !== null) {
                    unset($state->subs[$id]);
                }
                $this->maybeReceipt($conn, $frame);
                break;
            case 'SEND':
                // No server-side @MessageMapping handlers; actions go via REST.
                $this->maybeReceipt($conn, $frame);
                break;
            case 'DISCONNECT':
                $this->maybeReceipt($conn, $frame);
                $conn->close();
                break;
            default:
                // ACK/NACK/BEGIN/COMMIT/ABORT — not used by this contract.
                $this->maybeReceipt($conn, $frame);
                break;
        }
    }

    private function handleConnect(ConnectionInterface $conn, \stdClass $state, StompFrame $frame): void
    {
        $auth = $frame->header('Authorization');
        if ($auth === null) {
            $auth = $frame->header('authorization');
        }
        if ($auth !== null && strpos($auth, 'Bearer ') === 0) {
            $token = trim(substr($auth, 7));
            try {
                $principal = $this->jwt->parseAccess($token);
                $state->userId = $principal->userId;
            } catch (UnauthorizedException $e) {
                // Anonymous connect (matches Spring: subscribes to /user/* simply
                // never receive anything). Public /topic still works.
                $state->userId = null;
            }
        }

        $this->negotiateHeartbeat($state, $frame->header('heart-beat', '0,0'));

        $connected = new StompFrame('CONNECTED', [
            'version' => '1.2',
            'heart-beat' => self::SERVER_HEARTBEAT_MS.','.self::SERVER_HEARTBEAT_MS,
            'session' => $state->sessionId,
            'server' => 'erp-stomp/1.0',
        ]);
        if ($state->userId !== null) {
            $connected->headers['user-name'] = (string) $state->userId;
        }
        $this->sendFrame($conn, $state, $connected);
        $state->connected = true;

        if ($state->userId !== null) {
            try {
                $this->presence->connect((int) $state->userId, $state->sessionId);
            } catch (Throwable $e) {
                $this->logLine('[stomp] presence connect error: '.$e->getMessage());
            }
            $this->logLine('[stomp] CONNECT user='.$state->userId.' session='.$state->sessionId);
        } else {
            $this->logLine('[stomp] CONNECT anonymous session='.$state->sessionId);
        }
    }

    private function handleSubscribe(\stdClass $state, StompFrame $frame): void
    {
        $id = $frame->header('id');
        $destination = $frame->header('destination');
        if ($id === null || $destination === null) {
            return;
        }
        $state->subs[$id] = $destination;
        $this->logLine('[stomp] SUBSCRIBE user='.($state->userId ?? 'anon').' dest='.$destination);
    }

    // --- outbound delivery (called from the Redis subscriber) ---------------

    /**
     * Fan a frame body out to every subscription that matches the destination.
     *
     *   /topic/...                  → all sessions subscribed to that exact dest
     *   /user/{userId}/queue/{x}    → sessions of that user subscribed to /user/queue/{x}
     *
     * @param string $destination broker destination from the publisher
     * @param string $body        already-encoded JSON ({event,payload})
     */
    public function deliver(string $destination, string $body): void
    {
        $targetUserId = null;
        $clientDest = $destination;

        if (strpos($destination, '/user/') === 0) {
            // /user/{userId}/queue/inbox  ->  userId + /user/queue/inbox
            $rest = substr($destination, strlen('/user/'));
            $slash = strpos($rest, '/');
            if ($slash === false) {
                return;
            }
            $targetUserId = (int) substr($rest, 0, $slash);
            $clientDest = '/user'.substr($rest, $slash); // /user/queue/inbox
        }

        $delivered = 0;
        foreach ($this->clients as $conn) {
            $state = $this->clients[$conn];
            if ($targetUserId !== null && (int) $state->userId !== $targetUserId) {
                continue;
            }
            foreach ($state->subs as $subId => $dest) {
                if ($dest === $clientDest) {
                    $this->sendMessage($conn, $state, $subId, $clientDest, $body);
                    $delivered++;
                }
            }
        }
        $this->logLine('[stomp] deliver dest='.$destination.' clientDest='.$clientDest.' -> '.$delivered.' subscriber(s)');
    }

    // --- heartbeat tick (called periodically by the loop) -------------------

    public function tick(): void
    {
        $now = $this->now();
        $stale = [];
        foreach ($this->clients as $conn) {
            $state = $this->clients[$conn];
            // Send server heartbeat if due.
            if ($state->outHb > 0 && ($now - $state->lastTx) >= $state->outHb) {
                $conn->send("\n");
                $state->lastTx = $now;
            }
            // Drop the socket if the client's heartbeats stopped (2.5x grace).
            if ($state->inHb > 0 && ($now - $state->lastRx) > ($state->inHb * 2.5)) {
                $stale[] = $conn;
            }
        }
        foreach ($stale as $conn) {
            $this->logLine('[stomp] heartbeat timeout, closing session '.$this->clients[$conn]->sessionId);
            $conn->close();
        }
    }

    // --- helpers ------------------------------------------------------------

    private function negotiateHeartbeat(\stdClass $state, ?string $header): void
    {
        $cx = 0;
        $cy = 0;
        if ($header !== null && strpos($header, ',') !== false) {
            [$cx, $cy] = array_map('intval', explode(',', $header, 2));
        }
        // Server guarantees it can send/receive every SERVER_HEARTBEAT_MS.
        $sx = self::SERVER_HEARTBEAT_MS; // server can send
        $sy = self::SERVER_HEARTBEAT_MS; // server wants to receive
        $state->outHb = ($sx === 0 || $cy === 0) ? 0 : max($sx, $cy);
        $state->inHb = ($sy === 0 || $cx === 0) ? 0 : max($sy, $cx);
    }

    private function sendMessage(ConnectionInterface $conn, \stdClass $state, string $subId, string $destination, string $body): void
    {
        $frame = new StompFrame('MESSAGE', [
            'subscription' => $subId,
            'message-id' => $state->sessionId.'-'.(++$this->messageSeq),
            'destination' => $destination,
            'content-type' => 'application/json',
            'content-length' => (string) strlen($body),
        ], $body);
        $this->sendFrame($conn, $state, $frame);
    }

    private function maybeReceipt(ConnectionInterface $conn, StompFrame $frame): void
    {
        $receipt = $frame->header('receipt');
        if ($receipt !== null && $this->clients->contains($conn)) {
            $this->sendFrame($conn, $this->clients[$conn], new StompFrame('RECEIPT', ['receipt-id' => $receipt]));
        }
    }

    private function sendError(ConnectionInterface $conn, string $message): void
    {
        $conn->send((new StompFrame('ERROR', ['message' => $message], $message))->toString());
    }

    private function sendFrame(ConnectionInterface $conn, \stdClass $state, StompFrame $frame): void
    {
        $conn->send($frame->toString());
        $state->lastTx = $this->now();
    }

    private function now(): float
    {
        return microtime(true) * 1000.0;
    }

    private function logLine(string $line): void
    {
        if ($this->log !== null) {
            ($this->log)($line);
        }
    }
}
