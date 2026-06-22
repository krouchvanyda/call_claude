<?php

namespace App\Support\Exceptions;

use App\Support\Response\ErrorCodes;

class NotFoundException extends AppException
{
    public function __construct(string $message)
    {
        parent::__construct(404, ErrorCodes::NOT_FOUND, $message);
    }
}
