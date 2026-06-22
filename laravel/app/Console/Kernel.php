<?php

namespace App\Console;

use App\Features\Auth\Console\PurgeRefreshTokensCommand;
use App\Features\Chat\Console\StompServeCommand;
use App\Features\Chat\Console\SweepCallTimeoutsCommand;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * The Artisan commands provided by your application.
     *
     * @var array
     */
    protected $commands = [
        PurgeRefreshTokensCommand::class,
        SweepCallTimeoutsCommand::class,
        StompServeCommand::class,
    ];

    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // Port of RefreshTokenCleanupJob (@Scheduled fixedDelay PT1H).
        $schedule->command('erp:purge-refresh-tokens')->hourly();

        // Port of CallTimeoutScheduler (sweeps every 5s). Laravel 8's scheduler
        // has minute granularity, so the command loops internally for ~60s,
        // sweeping every CHAT_CALL_SWEEP_INTERVAL_MS. withoutOverlapping keeps a
        // single sweeper alive.
        $schedule->command('erp:sweep-call-timeouts')
            ->everyMinute()
            ->withoutOverlapping();
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__.'/Commands');

        require base_path('routes/console.php');
    }
}
