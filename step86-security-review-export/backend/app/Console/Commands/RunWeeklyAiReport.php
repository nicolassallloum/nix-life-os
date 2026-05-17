<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Process;

class RunWeeklyAiReport extends Command
{
    protected $signature = 'ai:weekly-report {--user_id=}';

    protected $description = 'Run weekly AI report engine for one user or all users';

    public function handle(): int
    {
        $userId = $this->option('user_id');

        $users = User::query()
            ->when($userId, function ($query) use ($userId) {
                $query->where('id', $userId);
            })
            ->get();

        $pythonPath = base_path('../ai-engine/venv/bin/python');
        $scriptPath = base_path('../ai-engine/run_weekly_report.py');

        foreach ($users as $user) {
            $this->info("Running weekly AI report for user {$user->id}");

            $result = Process::timeout(180)->run([
                $pythonPath,
                $scriptPath,
                '--user-id=' . $user->id,
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