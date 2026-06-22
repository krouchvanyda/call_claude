<?php

return [

    'defaults' => [
        'guard' => 'api',
        'passwords' => 'users',
    ],

    /*
    |--------------------------------------------------------------------------
    | Authentication Guards
    |--------------------------------------------------------------------------
    |
    | The "api" guard is a stateless JWT guard (App\Support\Auth\JwtGuard),
    | registered in App\Providers\AuthServiceProvider. It parses the Bearer
    | access token, validates it via App\Support\Auth\JwtService, and exposes
    | an App\Support\Auth\AuthenticatedUser principal carrying the user id,
    | email, and the permission codes from the token's "pms" claim.
    |
    */

    'guards' => [
        'web' => [
            'driver' => 'session',
            'provider' => 'users',
        ],

        'api' => [
            'driver' => 'jwt',
            'provider' => 'users',
        ],
    ],

    'providers' => [
        'users' => [
            'driver' => 'eloquent',
            'model' => App\Features\Users\Models\User::class,
        ],
    ],

    'passwords' => [
        'users' => [
            'provider' => 'users',
            'table' => 'password_resets',
            'expire' => 60,
            'throttle' => 60,
        ],
    ],

    'password_timeout' => 10800,

];
