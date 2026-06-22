<?php

namespace App\Features\Auth\Console;

use App\Features\Auth\Models\RefreshToken;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

/**
 * Hourly cleanup of expired / revoked refresh tokens — port of
 * RefreshTokenCleanupJob. Rows are purged only after they've been inactive for
 * at least 24h, keeping the table small without losing recent audit value.
 */
class PurgeRefreshTokensCommand extends Command
{
    protected $signature = 'erp:purge-refresh-tokens';

    protected $description = 'Purge expired or revoked refresh tokens older than 24h';

    public function handle(): int
    {
        $cutoff = Carbon::now()->subHours(24);

        $purged = RefreshToken::query()
            ->where('expires_at', '<', $cutoff)
            ->orWhereNotNull('revoked_at')
            ->delete();

        if ($purged > 0) {
            $this->info("Purged {$purged} inactive refresh tokens");
        }

        return self::SUCCESS;
    }
}
