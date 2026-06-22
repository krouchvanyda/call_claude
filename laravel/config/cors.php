<?php

/*
| Mirrors the Spring CorsConfigurationSource: allowed hosts/methods/headers are
| driven by env (CORS_ALLOWED_HOSTS etc.), credentials are allowed, and the
| X-Request-Id trace header is exposed back to the client.
*/

$split = function (?string $value, array $default) {
    if ($value === null || trim($value) === '') {
        return $default;
    }
    return array_values(array_filter(array_map('trim', explode(',', $value)), function ($s) {
        return $s !== '';
    }));
};

return [

    'paths' => ['*'],

    'allowed_methods' => $split(env('CORS_ALLOWED_METHODS'), ['*']),

    'allowed_origins' => env('CORS_ALLOWED_HOSTS', '*') === '*' ? ['*'] : [],

    'allowed_origins_patterns' => env('CORS_ALLOWED_HOSTS', '*') === '*'
        ? []
        : $split(env('CORS_ALLOWED_HOSTS'), []),

    'allowed_headers' => $split(env('CORS_ALLOWED_HEADERS'), ['*']),

    'exposed_headers' => ['X-Request-Id'],

    'max_age' => 0,

    'supports_credentials' => true,

];
