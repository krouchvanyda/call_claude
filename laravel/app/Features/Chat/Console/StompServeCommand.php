<?php

namespace App\Features\Chat\Console;

use App\Features\Chat\Services\PresenceService;
use App\Features\Chat\Stomp\StompServer;
use App\Support\Auth\JwtService;
use Clue\React\Redis\Factory as RedisFactory;
use Illuminate\Console\Command;
use Ratchet\Http\HttpServer;
use Ratchet\Server\IoServer;
use Ratchet\WebSocket\WsServer;
use React\EventLoop\Factory as LoopFactory;

/**
 * Runs the STOMP-over-WebSocket server (the Spring SimpleBroker replacement).
 *
 *   php artisan erp:stomp-serve
 *
 * Listens for raw WebSocket connections (nginx proxies /ws and /ws-sockjs here)
 * and speaks STOMP. Outbound frames arrive over Redis pub/sub from the REST app
 * (see ChatBroadcaster); inbound CONNECT/SUBSCRIBE/heartbeats are handled by
 * StompServer.
 */
class StompServeCommand extends Command
{
    protected $signature = 'erp:stomp-serve {--host=0.0.0.0} {--port=8090}';

    protected $description = 'Run the STOMP-over-WebSocket server for chat/call/presence realtime';

    public function handle(JwtService $jwt, PresenceService $presence): int
    {
        $host = (string) $this->option('host');
        $port = (int) $this->option('port');
        $channel = (string) config('erp.stomp.channel', 'erp.stomp');

        $loop = LoopFactory::create();

        $logger = function (string $line) {
            $this->line('['.gmdate('H:i:s').'] '.$line);
        };
        $server = new StompServer($jwt, $presence, $logger);

        // WebSocket transport (Ratchet) sharing our loop.
        $socket = $this->makeSocket($host.':'.$port, $loop);
        new IoServer(new HttpServer(new WsServer($server)), $socket, $loop);

        // 10s/10s heartbeats + dead-socket sweep.
        $loop->addPeriodicTimer(2.0, function () use ($server) {
            $server->tick();
        });

        // Outbound bridge: REST app publishes {destination, body} frames here.
        // Read the host straight from env so a stale cached config can't point
        // us at the wrong Redis.
        $redisHost = getenv('REDIS_HOST') ?: config('database.redis.default.host', '127.0.0.1');
        $redisPort = getenv('REDIS_PORT') ?: config('database.redis.default.port', 6379);
        $redisUri = 'redis://'.$redisHost.':'.$redisPort;
        $factory = new RedisFactory($loop);

        $connect = function () use (&$connect, $factory, $redisUri, $server, $channel, $logger, $loop) {
            $factory->createClient($redisUri)->then(
                function ($client) use ($server, $channel, $logger, $loop, &$connect) {
                    $client->subscribe($channel);
                    $client->on('message', function ($ch, $payload) use ($server) {
                        $msg = json_decode($payload, true);
                        if (is_array($msg) && isset($msg['destination'])) {
                            $body = isset($msg['body']) ? json_encode($msg['body']) : '{}';
                            $server->deliver((string) $msg['destination'], $body);
                        }
                    });
                    $client->on('close', function () use ($logger, $loop, $connect) {
                        $logger('[stomp] redis connection closed; reconnecting in 2s');
                        $loop->addTimer(2.0, $connect);
                    });
                    $logger('[stomp] subscribed to redis channel "'.$channel.'"');
                },
                function (\Throwable $e) use ($logger, $loop, $connect) {
                    $logger('[stomp] redis connect failed ('.$e->getMessage().'); retrying in 2s');
                    $loop->addTimer(2.0, $connect);
                }
            );
        };
        $connect();

        $this->info("STOMP server listening on ws://{$host}:{$port}  (redis channel: {$channel})");
        $loop->run();

        return self::SUCCESS;
    }

    /**
     * react/socket renamed Server → SocketServer in 1.9; support both.
     *
     * @return \React\Socket\ServerInterface
     */
    private function makeSocket(string $uri, $loop)
    {
        if (class_exists(\React\Socket\SocketServer::class)) {
            return new \React\Socket\SocketServer($uri, [], $loop);
        }
        return new \React\Socket\Server($uri, $loop);
    }
}
