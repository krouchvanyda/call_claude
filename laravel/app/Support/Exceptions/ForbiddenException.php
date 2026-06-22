<?php

namespace App\Support\Exceptions;

use App\Support\Response\ErrorCodes;

class ForbiddenException extends AppException
{
    public function __construct(string $message)
    {
        parent::__construct(403, ErrorCodes::FORBIDDEN, $message);
    }
}
