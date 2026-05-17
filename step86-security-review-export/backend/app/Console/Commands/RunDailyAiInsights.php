<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Process;

class RunDailyAiInsights extends Command
{
    protected $signature = 'ai:daily-insights {--user_id=} {--date=}';

    protected $description = 'Run daily AI insights engine for one user or all users';

    public function handle(): int
    {
        $userId = $this->option('user_id');
        $date = $this->option('date') ?: now()->toDateString();

        $users = User::query()
            ->when($userId, function ($query) use ($userId) {
                $query->where('id', $userId);
            })
            ->get();

        $pythonPath = base_path('../ai-engine/venv/bin/python');
        $scriptPath = base_path('../ai-engine/run_daily_insights.py');

        foreach ($users as $user) {
            $this->info("Running daily AI insights for user {$user->id}");

            $result = Process::timeout(120)->run([
                $pythonPath,
                $scriptPath,
                '--user-id=' . $user->id,
                '--date=' . $date,
            ]);

            if (!$result->successful()) {
                $this->error($result->errorOutput());
                continue;
            }

            $this->info($result->output());
        }

        return self::SUCCESS;
    }
}