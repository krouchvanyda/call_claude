<?php

namespace App\Support\Exceptions;

use RuntimeException;

/**
 * Base class for application-level exceptions with a known HTTP status + stable
 * error code. Throw subclasses freely from services and controllers; the
 * exception handler translates them into the standard envelope.
 */
class AppException extends RuntimeException
{
    /** @var int */
    private $status;

    /** @var string */
    private $errorCode;

    public function __construct(int $status, string $errorCode, string $message)
    {
        parent::__construct($message);
        $this->status = $status;
        $this->errorCode = $errorCode;
    }

    public function status(): int
    {
        return $this->status;
    }

    public function errorCode(): string
    {
        return $this->errorCode;
    }
}
