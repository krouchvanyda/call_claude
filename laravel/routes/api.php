<?php

use App\Features\Auth\Controllers\AuthController;
use App\Features\Devices\Controllers\DeviceController;
use App\Features\Employees\Controllers\EmployeeController;
use App\Features\Users\Controllers\RoleController;
use App\Features\Users\Controllers\UserController;
use App\Http\Controllers\HealthController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API routes
|--------------------------------------------------------------------------
| No global prefix is applied (see RouteServiceProvider) — paths are declared
| explicitly here to match the original Spring mappings (/api/v1/… + /health).
*/

// Liveness — public.
Route::get('/health', [HealthController::class, 'health']);

Route::prefix('api/v1')->group(function () {

    // ---- auth (public) ----------------------------------------------------
    Route::post('auth/login', [AuthController::class, 'login']);
    Route::post('auth/register', [AuthController::class, 'register']);
    Route::post('auth/refresh', [AuthController::class, 'refresh']);

    // ---- authenticated ----------------------------------------------------
    Route::middleware('auth')->group(function () {

        // logout requires a valid access token (matches the original SecurityConfig)
        Route::post('auth/logout', [AuthController::class, 'logout']);

        // ---- users (read is open to any authenticated user) ---------------
        Route::get('users/me', [UserController::class, 'me']);
        Route::get('users', [UserController::class, 'index']);
        Route::post('users/assign-roles', [UserController::class, 'assignRoles'])
            ->middleware('permission:user:write');
        Route::post('users', [UserController::class, 'store'])
            ->middleware('permission:user:write');
        Route::get('users/{id}', [UserController::class, 'show'])->whereNumber('id');
        Route::patch('users/{id}', [UserController::class, 'update'])
            ->whereNumber('id')->middleware('permission:user:write');
        Route::delete('users/{id}', [UserController::class, 'destroy'])
            ->whereNumber('id')->middleware('permission:user:write');

        // ---- roles --------------------------------------------------------
        Route::get('roles', [RoleController::class, 'index'])
            ->middleware('permission:role:read');
        Route::get('roles/permissions', [RoleController::class, 'permissions'])
            ->middleware('permission:role:read');
        Route::get('roles/{id}', [RoleController::class, 'show'])
            ->whereNumber('id')->middleware('permission:role:read');
        Route::post('roles', [RoleController::class, 'store'])
            ->middleware('permission:role:write');
        Route::patch('roles/{id}', [RoleController::class, 'update'])
            ->whereNumber('id')->middleware('permission:role:write');
        Route::delete('roles/{id}', [RoleController::class, 'destroy'])
            ->whereNumber('id')->middleware('permission:role:write');

        // ---- employees ----------------------------------------------------
        Route::get('employees/me', [EmployeeController::class, 'me']);
        Route::post('employees/me/avatar', [EmployeeController::class, 'uploadMyAvatar']);
        Route::delete('employees/me/avatar', [EmployeeController::class, 'deleteMyAvatar']);

        Route::get('employees', [EmployeeController::class, 'index'])
            ->middleware('permission:employee:read');
        Route::get('employees/{id}', [EmployeeController::class, 'show'])
            ->whereNumber('id')->middleware('permission:employee:read');
        Route::post('employees', [EmployeeController::class, 'store'])
            ->middleware('permission:employee:write');
        Route::patch('employees/{id}', [EmployeeController::class, 'update'])
            ->whereNumber('id')->middleware('permission:employee:write');
        Route::delete('employees/{id}', [EmployeeController::class, 'destroy'])
            ->whereNumber('id')->middleware('permission:employee:write');
        Route::post('employees/{id}/avatar', [EmployeeController::class, 'uploadAvatar'])
            ->whereNumber('id')->middleware('permission:employee:write');
        Route::delete('employees/{id}/avatar', [EmployeeController::class, 'deleteAvatar'])
            ->whereNumber('id')->middleware('permission:employee:write');

        // ---- devices (FCM tokens) -----------------------------------------
        Route::get('me/devices', [DeviceController::class, 'index']);
        Route::post('me/devices', [DeviceController::class, 'register']);
        Route::delete('me/devices/{deviceId}', [DeviceController::class, 'destroy']);

        // ---- chat / calls / presence (defined in routes/api_chat.php) -----
        require __DIR__.'/api_chat.php';
    });
});
