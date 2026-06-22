<?php

namespace App\Support\Exceptions;

use App\Support\Response\ErrorCodes;

class UnauthorizedException extends AppException
{
    public function __construct(string $message)
    {
        parent::__construct(401, ErrorCodes::UNAUTHORIZED, $message);
    }
}
