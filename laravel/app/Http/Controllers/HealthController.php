<?php

namespace App\Http\Controllers;

/** Liveness probe — GET /health. Wrapped into the standard envelope. */
class HealthController extends Controller
{
    public function health(): array
    {
        return ['status' => 'UP'];
    }
}
