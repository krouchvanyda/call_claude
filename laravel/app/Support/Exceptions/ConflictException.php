<?php

namespace App\Support\Exceptions;

use App\Support\Response\ErrorCodes;

class ConflictException extends AppException
{
    public function __construct(string $message)
    {
        parent::__construct(409, ErrorCodes::CONFLICT, $message);
    }
}
