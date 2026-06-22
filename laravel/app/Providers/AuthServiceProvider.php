<?php

namespace App\Providers;

use App\Support\Auth\JwtGuard;
use App\Support\Auth\JwtService;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Auth;

class AuthServiceProvider extends ServiceProvider
{
    /**
     * @var array<class-string, class-string>
     */
    protected $policies = [];

    public function boot(): void
    {
        $this->registerPolicies();

        // Stateless JWT guard backing the "api" guard (config/auth.php).
        Auth::extend('jwt', function ($app, $name, $config) {
            $guard = new JwtGuard($app->make(JwtService::class), $app->make('request'));

            // Keep the guard's request in sync as the container rebinds it.
            $app->refresh('request', $guard, 'setRequest');

            return $guard;
        });
    }
}
