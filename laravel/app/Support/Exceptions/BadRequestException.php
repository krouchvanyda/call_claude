<?php

namespace App\Support\Exceptions;

use App\Support\Response\ErrorCodes;

class BadRequestException extends AppException
{
    public function __construct(string $message)
    {
        parent::__construct(400, ErrorCodes::BAD_REQUEST, $message);
    }
}
