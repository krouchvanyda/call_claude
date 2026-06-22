<?php

namespace App\Exceptions;

use App\Support\Exceptions\AppException;
use App\Support\Http\ApiResponse;
use App\Support\Response\ErrorCodes;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\UnsupportedMediaTypeHttpException;
use Throwable;

/**
 * Translates every thrown exception into the standard
 * { success, message, data, errorCode, traceId } envelope — the Laravel
 * equivalent of the Spring GlobalExceptionHandler + the security
 * entry-point / access-denied handlers.
 */
class Handler extends ExceptionHandler
{
    /**
     * @var array<int, class-string<Throwable>>
     */
    protected $dontReport = [];

    /**
     * @var array<int, string>
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    public function register(): void
    {
        //
    }

    /**
     * Always render API responses as the standard envelope.
     */
    public function render($request, Throwable $e)
    {
        return $this->renderEnvelope($e);
    }

    protected function renderEnvelope(Throwable $e)
    {
        // Application exceptions carry their own status + stable error code.
        if ($e instanceof AppException) {
            return ApiResponse::error($e->getMessage(), $e->errorCode(), null, $e->status());
        }

        // Bean-validation equivalent: per-field details under data.fieldErrors.
        if ($e instanceof ValidationException) {
            $fieldErrors = [];
            foreach ($e->errors() as $field => $messages) {
                $fieldErrors[] = [
                    'field' => $field,
                    'message' => is_array($messages) ? ($messages[0] ?? '') : (string) $messages,
                ];
            }
            return ApiResponse::error('Validation failed', ErrorCodes::VALIDATION_FAILED, [
                'fieldErrors' => $fieldErrors,
            ], 400);
        }

        if ($e instanceof AuthenticationException) {
            return ApiResponse::error('Authentication required', ErrorCodes::UNAUTHORIZED, null, 401);
        }

        if ($e instanceof AuthorizationException || $e instanceof AccessDeniedHttpException) {
            return ApiResponse::error('Forbidden', ErrorCodes::FORBIDDEN, null, 403);
        }

        if ($e instanceof ModelNotFoundException || $e instanceof NotFoundHttpException) {
            return ApiResponse::error('Endpoint not found', ErrorCodes::NOT_FOUND, null, 404);
        }

        if ($e instanceof MethodNotAllowedHttpException) {
            return ApiResponse::error($e->getMessage(), ErrorCodes::METHOD_NOT_ALLOWED, null, 405);
        }

        if ($e instanceof UnsupportedMediaTypeHttpException) {
            return ApiResponse::error($e->getMessage(), ErrorCodes::UNSUPPORTED_MEDIA, null, 415);
        }

        // Payload too large (multipart upload over the configured limit).
        if ($e instanceof HttpExceptionInterface && $e->getStatusCode() === 413) {
            return ApiResponse::error('Uploaded file is too large', ErrorCodes::BAD_REQUEST, null, 413);
        }

        if ($e instanceof HttpExceptionInterface) {
            $status = $e->getStatusCode();
            $message = $e->getMessage() !== '' ? $e->getMessage() : 'Request failed';
            return ApiResponse::error($message, ErrorCodes::BAD_REQUEST, null, $status);
        }

        // Fallback — never leak internals.
        \Illuminate\Support\Facades\Log::error('Unhandled exception', ['exception' => $e]);

        $message = config('app.debug') ? $e->getMessage() : 'Internal server error';
        return ApiResponse::error($message, ErrorCodes::INTERNAL_ERROR, null, 500);
    }

    protected function unauthenticated($request, AuthenticationException $exception)
    {
        return ApiResponse::error('Authentication required', ErrorCodes::UNAUTHORIZED, null, 401);
    }
}
