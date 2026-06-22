<?php

use Illuminate\Support\Facades\Route;

/*
| This is an API-first backend; there are no server-rendered web routes. The
| Laravel WebSockets dashboard and broadcasting/auth endpoints register their
| own routes. Everything else lives in routes/api.php.
*/

Route::get('/', function () {
    return response()->json(['service' => config('app.name'), 'status' => 'UP']);
});
