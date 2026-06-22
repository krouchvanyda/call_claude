<?php

namespace App\Providers;

use App\Support\Auth\JwtService;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->singleton(JwtService::class, function () {
            return new JwtService();
        });
    }

    public function boot(): void
    {
        //
    }
}
