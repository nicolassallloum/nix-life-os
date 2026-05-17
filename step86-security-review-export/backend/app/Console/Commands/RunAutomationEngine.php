<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Services\AutomationEngineService;
use Illuminate\Console\Command;

class RunAutomationEngine extends Command
{
    protected $signature = 'automation:run {--user_id=}';

    protected $description = 'Run automation engine for all users or a specific user';

    public function handle(AutomationEngineService $service): int
    {
        $userId = $this->option('user_id');

        if ($userId) {
            $results = $service->runForUser($userId);

            $this->info('Automation engine executed for user: ' . $userId);
            $this->line(json_encode($results, JSON_PRETTY_PRINT));

            return self::SUCCESS;
        }

        User::query()
            ->select('id')
            ->chunk(100, function ($users) use ($service) {
                foreach ($users as $user) {
                    $service->runForUser($user->id);
                    $this->info('Executed automation for user: ' . $user->id);
                }
            });

        $this->info('Automation engine executed for all users.');

        return self::SUCCESS;
    }
}
