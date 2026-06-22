<?php

namespace App\Features\Auth\Models;

use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Model;

/**
 * Server-side record of an issued refresh token, identified by its jti claim.
 * A non-null revoked_at invalidates the token; rotation on /auth/refresh
 * revokes the old row and creates a new one. Port of the Spring RefreshToken
 * entity (no created/updated audit columns — its own issued_at/expires_at
 * carry the lifecycle).
 *
 * @property int $id
 * @property int $user_id
 * @property string $jti
 * @property \Illuminate\Support\Carbon $issued_at
 * @property \Illuminate\Support\Carbon $expires_at
 * @property \Illuminate\Support\Carbon|null $revoked_at
 */
class RefreshToken extends Model
{
    public $timestamps = false;

    protected $table = 'refresh_tokens';

    protected $fillable = ['user_id', 'jti', 'issued_at', 'expires_at', 'revoked_at'];

    protected $casts = [
        'issued_at' => 'datetime',
        'expires_at' => 'datetime',
        'revoked_at' => 'datetime',
    ];

    public function isActive(CarbonInterface $now): bool
    {
        return $this->revoked_at === null && $this->expires_at->greaterThan($now);
    }
}
