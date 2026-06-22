<?php

namespace App\Support\Response;

/** Stable machine-readable error codes returned in the envelope's `errorCode`. */
final class ErrorCodes
{
    const VALIDATION_FAILED  = 'VALIDATION_FAILED';
    const UNAUTHORIZED       = 'UNAUTHORIZED';
    const FORBIDDEN          = 'FORBIDDEN';
    const NOT_FOUND          = 'NOT_FOUND';
    const CONFLICT           = 'CONFLICT';
    const BAD_REQUEST        = 'BAD_REQUEST';
    const RATE_LIMITED       = 'RATE_LIMITED';
    const UNSUPPORTED_MEDIA  = 'UNSUPPORTED_MEDIA_TYPE';
    const METHOD_NOT_ALLOWED = 'METHOD_NOT_ALLOWED';
    const INTERNAL_ERROR     = 'INTERNAL_ERROR';

    private function __construct()
    {
    }
}
