<?php

namespace App\Features\Chat\Stomp;

/**
 * Minimal STOMP 1.2 frame codec.
 *
 * Frame wire format:
 *   COMMAND\n
 *   header:value\n
 *   header:value\n
 *   \n
 *   body^@            (^@ = NUL terminator, stripped before parse())
 */
final class StompFrame
{
    /** @var string */
    public $command;

    /** @var array<string, string> */
    public $headers;

    /** @var string */
    public $body;

    /**
     * @param array<string, string> $headers
     */
    public function __construct(string $command, array $headers = [], string $body = '')
    {
        $this->command = $command;
        $this->headers = $headers;
        $this->body = $body;
    }

    public function header(string $name, ?string $default = null): ?string
    {
        return array_key_exists($name, $this->headers) ? $this->headers[$name] : $default;
    }

    /**
     * Parse one frame (NUL terminator already removed). Returns null if the
     * chunk isn't a well-formed frame (e.g. a heartbeat newline).
     */
    public static function parse(string $raw): ?self
    {
        // Strip a single leading EOL left over from the previous frame / heartbeats.
        $raw = preg_replace('/^(\r?\n)+/', '', $raw);
        if ($raw === '' ) {
            return null;
        }

        $sep = strpos($raw, "\n\n");
        $headerPart = $sep === false ? $raw : substr($raw, 0, $sep);
        $body = $sep === false ? '' : substr($raw, $sep + 2);

        $lines = explode("\n", $headerPart);
        $command = trim(array_shift($lines));
        if ($command === '') {
            return null;
        }

        $headers = [];
        foreach ($lines as $line) {
            $line = rtrim($line, "\r");
            if ($line === '') {
                continue;
            }
            $pos = strpos($line, ':');
            if ($pos === false) {
                continue;
            }
            $key = self::unescape(substr($line, 0, $pos));
            $val = self::unescape(substr($line, $pos + 1));
            // First occurrence wins (STOMP semantics).
            if (! array_key_exists($key, $headers)) {
                $headers[$key] = $val;
            }
        }

        // Trim a trailing NUL or EOLs if a caller left them on.
        $body = rtrim($body, "\x00");

        return new self($command, $headers, $body);
    }

    /**
     * Serialize this frame to the wire (with NUL terminator).
     */
    public function toString(): string
    {
        $out = $this->command."\n";
        foreach ($this->headers as $k => $v) {
            $out .= self::escape((string) $k).':'.self::escape((string) $v)."\n";
        }
        $out .= "\n".$this->body."\x00";
        return $out;
    }

    private static function escape(string $v): string
    {
        return str_replace(["\\", "\r", "\n", ':'], ["\\\\", "\\r", "\\n", "\\c"], $v);
    }

    private static function unescape(string $v): string
    {
        return str_replace(["\\r", "\\n", "\\c", "\\\\"], ["\r", "\n", ':', "\\"], $v);
    }
}
