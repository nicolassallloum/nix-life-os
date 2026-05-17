<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\User;
use App\Services\Health\HealthAlertEngineService;

class RunHealthAlertsEngine extends Command
{
    protected $signature = 'health:generate-alerts {--user_id=} {--date=}';

    protected $description = 'Generate health alerts for users';

    public function handle(HealthAlertEngineService $engine): int
    {
        $userId = $this->option('user_id');
        $date = $this->option('date') ?? now()->toDateString();

        $users = $userId
            ? User::where('id', $userId)->get()
            : User::query()->get();

        foreach ($users as $user) {
            $alerts = $engine->runForUser($user->id, $date);

            $this->info("User {$user->id}: " . count($alerts) . " alert(s) generated.");
        }

        return self::SUCCESS;
    }
}