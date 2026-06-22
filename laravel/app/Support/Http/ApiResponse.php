<?php

namespace App\Support\Http;

use Illuminate\Http\JsonResponse;

/**
 * Builds the standard response envelope:
 * { success, message, data, errorCode, traceId }.
 *
 * Successful controller responses are wrapped automatically by the
 * WrapInApiEnvelope middleware (the analogue of Spring's
 * ResponseEnvelopeAdvice); these factory methods are used directly for errors
 * and wherever a controller wants explicit control. Every response produced
 * here is tagged with the X-Api-Envelope header so the wrapping middleware
 * never double-wraps it.
 */
final class ApiResponse
{
    /** Header marking a response as already enveloped. */
    const ENVELOPE_HEADER = 'X-Api-Envelope';

    /**
     * @param mixed $data
     */
    public static function ok($data = null, string $message = 'Success', int $status = 200): JsonResponse
    {
        return self::make(true, $message, $data, null, $status);
    }

    public static function empty(string $message = 'Success', int $status = 200): JsonResponse
    {
        return self::make(true, $message, null, null, $status);
    }

    /**
     * @param mixed $data
     */
    public static function error(string $message, string $errorCode, $data = null, int $status = 400): JsonResponse
    {
        return self::make(false, $message, $data, $errorCode, $status);
    }

    /**
     * @param mixed $data
     */
    public static function make(bool $success, string $message, $data, ?string $errorCode, int $status): JsonResponse
    {
        $payload = [
            'success' => $success,
            'message' => $message,
            'data' => $data,
            'errorCode' => $errorCode,
            'traceId' => TraceContext::get(),
        ];

        return (new JsonResponse($payload, $status))
            ->header(self::ENVELOPE_HEADER, '1');
    }
}
